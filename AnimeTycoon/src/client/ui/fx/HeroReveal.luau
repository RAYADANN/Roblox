--!strict
-- Fullscreen hero reveal on container unpack (local owner only).
-- Spin small → zoom in facing camera → gentle idle turn.

local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local FxOverlay = require(script.Parent.FxOverlay)
local HeroModel = require(script.Parent.Parent.Parent.core.HeroModel)
local MutationFxAttach = require(script.Parent.Parent.Parent.core.MutationFxAttach)
local WorldBillboard = require(script.Parent.Parent.Parent.core.WorldBillboard)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HeroScaleLogic = require(ReplicatedStorage.shared.util.HeroScaleLogic)

export type RevealPayload = {
    heroId: string,
    displayName: string,
    rarity: string,
    mutations: { string }?,
    mutationLabel: string?,
    incomeRate: number?,
}

local HeroReveal = {}

local _busy = false
local AUTO_CLOSE_SEC = 5.0

local SPIN_SEC = 0.75
local ZOOM_SEC = 0.65
local IDLE_SWAY_DEG = 10
local IDLE_SWAY_SPEED = 1.1
local BACKDROP_IMAGE = "rbxassetid://101824724626288"
local BACKDROP_SPIN_DEG_PER_SEC = 28
local BLUR_NAME = "HeroRevealBlur"
local BLUR_SIZE = 22

local function smoothstep(t: number): number
    local x = math.clamp(t, 0, 1)
    return x * x * (3 - 2 * x)
end

--[[
  Reveal framing: stand every hero on the same origin/feet baseline.
  (Visual-center framing sank models whose WorldPivot≠mesh center.)
  Returns faceYaw + feetY (world Y of pivot in the viewport WorldModel).
]]
local function setupHeroShot(hero: Model, viewport: ViewportFrame): (number, number)
    return HeroModel.frameInViewport(hero, viewport)
end

local function setHeroYaw(hero: Model, feetY: number, yaw: number)
    hero:PivotTo(CFrame.new(0, feetY, 0) * CFrame.Angles(0, yaw, 0))
    MutationFxAttach.recenter(hero)
end

local function ensureBlur(): BlurEffect
    local found = Lighting:FindFirstChild(BLUR_NAME)
    if found and found:IsA("BlurEffect") then
        return found
    end
    local created = Instance.new("BlurEffect")
    created.Name = BLUR_NAME
    created.Size = 0
    created.Enabled = false
    created.Parent = Lighting
    return created
end

local function tweenBlur(size: number, info: TweenInfo, disableWhenZero: boolean?)
    local blur = ensureBlur()
    blur.Enabled = true
    local tw = TweenService:Create(blur, info, { Size = size })
    tw:Play()
    if disableWhenZero and size <= 0 then
        tw.Completed:Connect(function()
            if blur.Parent and blur.Size <= 0.05 then
                blur.Enabled = false
            end
        end)
    end
end

function HeroReveal.show(payload: RevealPayload)
    if _busy then
        return
    end
    _busy = true

    local layer = FxOverlay.getLayer()

    local root = Instance.new("Frame")
    root.Name = "HeroReveal"
    root.BackgroundColor3 = Color3.fromRGB(8, 6, 18)
    root.BackgroundTransparency = 1
    root.Size = UDim2.fromScale(1, 1)
    root.BorderSizePixel = 0
    root.ZIndex = 50
    root.Parent = layer

    local dim = Instance.new("TextButton")
    dim.Name = "Dim"
    dim.Text = ""
    dim.AutoButtonColor = false
    dim.BackgroundColor3 = Color3.fromRGB(8, 6, 18)
    dim.BackgroundTransparency = 1
    dim.Size = UDim2.fromScale(1, 1)
    dim.BorderSizePixel = 0
    dim.ZIndex = 50
    dim.Parent = root

    -- Rear screen image: no solid label background, only the asset.
    local backdrop = Instance.new("ImageLabel")
    backdrop.Name = "Backdrop"
    backdrop.AnchorPoint = Vector2.new(0.5, 0.5)
    backdrop.Position = UDim2.fromScale(0.5, 0.42)
    backdrop.Size = UDim2.fromOffset(80, 80)
    backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
    backdrop.BackgroundTransparency = 1
    backdrop.BorderSizePixel = 0
    backdrop.Image = BACKDROP_IMAGE
    backdrop.ImageColor3 = Color3.new(1, 1, 1)
    backdrop.ImageTransparency = 1
    backdrop.ScaleType = Enum.ScaleType.Fit
    backdrop.ZIndex = 51
    backdrop.Parent = root

    local viewport = Instance.new("ViewportFrame")
    viewport.Name = "HeroViewport"
    viewport.AnchorPoint = Vector2.new(0.5, 0.5)
    viewport.Position = UDim2.fromScale(0.5, 0.42)
    viewport.Size = UDim2.fromScale(0.28, 0.34)
    viewport.BackgroundTransparency = 1
    viewport.BorderSizePixel = 0
    viewport.Ambient = Color3.fromRGB(180, 180, 200)
    viewport.LightColor = Color3.fromRGB(255, 255, 255)
    viewport.LightDirection = Vector3.new(-0.35, -1, -0.45)
    viewport.ZIndex = 52
    viewport.Parent = root

    local hero = HeroModel.clone(payload.heroId, nil, {
        rarity = payload.rarity,
        mutations = payload.mutations,
        mutationLabel = payload.mutationLabel,
        viewportSafe = true,
        targetHeight = HeroScaleLogic.REVEAL_HEIGHT,
        maxExtent = HeroScaleLogic.REVEAL_MAX_EXTENT,
        deferMutationFx = true,
    })
    local faceYaw = 0
    local feetY = 0
    if hero then
        faceYaw, feetY = setupHeroShot(hero, viewport)
        HeroModel.applyMutationFx(hero, nil, true)
    end

    -- Same visual language as world BillboardGui (fonts / strokes / gradients).
    local panel = WorldBillboard.clonePanel(root, "RevealPanel")
    local panelLabels: { TextLabel } = {}
    if panel then
        panel.AnchorPoint = Vector2.new(0.5, 0)
        panel.Position = UDim2.fromScale(0.5, 0.66)
        panel.Size = UDim2.fromScale(0.42, 0.22)
        panel.BackgroundTransparency = 1
        panel.ZIndex = 53
        local priceText: string? = nil
        if typeof(payload.incomeRate) == "number" and (payload.incomeRate :: number) > 0 then
            priceText = WorldBillboard.shortMoney(payload.incomeRate :: number) .. "/trip"
        end
        WorldBillboard.set(panel, {
            displayName = payload.displayName,
            rarity = payload.rarity,
            mutationText = payload.mutationLabel,
            priceText = priceText,
        })
        for _, d in panel:GetDescendants() do
            if d:IsA("GuiObject") then
                d.ZIndex = math.max(d.ZIndex, 54)
            end
        end
        for _, name in { "NameLabel", "Rare", "Mutation", "Price" } do
            local label = WorldBillboard.findLabel(panel, name)
            if label then
                label.TextTransparency = 1
                local stroke = label:FindFirstChildWhichIsA("UIStroke")
                if stroke then
                    stroke.Transparency = 1
                end
                table.insert(panelLabels, label)
            end
        end
    end

    local hint = Instance.new("TextLabel")
    hint.Name = "Hint"
    hint.AnchorPoint = Vector2.new(0.5, 1)
    hint.Position = UDim2.new(0.5, 0, 1, -28)
    hint.Size = UDim2.new(0.6, 0, 0, 22)
    hint.BackgroundTransparency = 1
    hint.Font = Enum.Font.Gotham
    hint.TextSize = 16
    hint.TextColor3 = Color3.fromRGB(200, 200, 220)
    hint.Text = "Tap to continue"
    hint.TextTransparency = 1
    hint.ZIndex = 53
    hint.Parent = root

    local closed = false
    local function close()
        if closed then
            return
        end
        closed = true
        tweenBlur(0, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), true)
        TweenService:Create(dim, TweenInfo.new(0.22), { BackgroundTransparency = 1 }):Play()
        TweenService:Create(viewport, TweenInfo.new(0.22), {
            Size = UDim2.fromScale(0.16, 0.2),
        }):Play()
        TweenService:Create(backdrop, TweenInfo.new(0.22), {
            Size = UDim2.fromOffset(40, 40),
            ImageTransparency = 1,
        }):Play()
        task.delay(0.25, function()
            if root.Parent then
                root:Destroy()
            end
            _busy = false
        end)
    end

    dim.MouseButton1Click:Connect(close)
    local inputConn = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then
            return
        end
        if
            input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
            or input.KeyCode == Enum.KeyCode.Space
            or input.KeyCode == Enum.KeyCode.Return
        then
            close()
        end
    end)
    local spinConn = RunService.RenderStepped:Connect(function(dt)
        if closed or not backdrop.Parent then
            return
        end
        backdrop.Rotation += BACKDROP_SPIN_DEG_PER_SEC * dt
    end)
    root.Destroying:Connect(function()
        inputConn:Disconnect()
        spinConn:Disconnect()
        -- Safety: clear blur if destroyed without close().
        if not closed then
            tweenBlur(0, TweenInfo.new(0.15), true)
        end
    end)

    tweenBlur(
        BLUR_SIZE,
        TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        false
    )
    TweenService
        :Create(dim, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.35,
        })
        :Play()
    TweenService
        :Create(backdrop, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(1120, 1120),
            ImageTransparency = 0,
        })
        :Play()

    -- Hero motion: fast spin (small) → zoom to face → idle sway facing camera.
    if hero then
        task.spawn(function()
            local t0 = os.clock()
            -- Phase 1: tiny + rapid spin (several full turns)
            while root.Parent and not closed and os.clock() - t0 < SPIN_SEC do
                local a = (os.clock() - t0) / SPIN_SEC
                local spins = 3.0 * a -- 3 full turns during spin phase
                setHeroYaw(hero, feetY, faceYaw + math.rad(360 * spins))
                task.wait()
            end
            if not root.Parent or closed then
                return
            end

            -- Phase 2: grow viewport while finishing to exact faceYaw
            local zoomTween = TweenService:Create(
                viewport,
                TweenInfo.new(ZOOM_SEC, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                { Size = UDim2.fromScale(0.52, 0.62) }
            )
            zoomTween:Play()
            local tZoom = os.clock()
            local startYaw = faceYaw + math.rad(360 * 3)
            while root.Parent and not closed and os.clock() - tZoom < ZOOM_SEC do
                local a = smoothstep((os.clock() - tZoom) / ZOOM_SEC)
                local yaw = startYaw + (faceYaw - startYaw) * a
                setHeroYaw(hero, feetY, yaw)
                task.wait()
            end
            if not root.Parent or closed then
                return
            end
            setHeroYaw(hero, feetY, faceYaw)

            -- Labels after zoom (billboard style panel)
            local textInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            for _, label in panelLabels do
                TweenService:Create(label, textInfo, { TextTransparency = 0 }):Play()
                local stroke = label:FindFirstChildWhichIsA("UIStroke")
                if stroke then
                    TweenService:Create(stroke, textInfo, { Transparency = 0 }):Play()
                end
            end
            TweenService
                :Create(
                    hint,
                    TweenInfo.new(
                        0.4,
                        Enum.EasingStyle.Quad,
                        Enum.EasingDirection.Out,
                        0,
                        false,
                        0.35
                    ),
                    {
                        TextTransparency = 0.25,
                    }
                )
                :Play()

            -- Phase 3: idle, face camera, slight sway
            local tIdle = os.clock()
            while root.Parent and not closed do
                local sway = math.sin((os.clock() - tIdle) * IDLE_SWAY_SPEED)
                    * math.rad(IDLE_SWAY_DEG)
                setHeroYaw(hero, feetY, faceYaw + sway)
                task.wait()
            end
        end)
    else
        TweenService:Create(
            viewport,
            TweenInfo.new(ZOOM_SEC, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {
                Size = UDim2.fromScale(0.46, 0.56),
            }
        ):Play()
    end

    Debris:AddItem(root, AUTO_CLOSE_SEC + 1)
    task.delay(AUTO_CLOSE_SEC, close)
end

function HeroReveal.showFromNotifyPayload(payloadJson: string)
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(payloadJson)
    end)
    if not ok or typeof(decoded) ~= "table" then
        return
    end
    local row = decoded :: any
    HeroReveal.show({
        heroId = tostring(row.heroId or ""),
        displayName = tostring(row.displayName or "Hero"),
        rarity = tostring(row.rarity or "common"),
        mutations = if typeof(row.mutations) == "table" then row.mutations :: { string } else nil,
        mutationLabel = if typeof(row.mutationLabel) == "string" then row.mutationLabel else nil,
        incomeRate = if typeof(row.incomeRate) == "number" then row.incomeRate else nil,
    })
end

--- Studio/debug: H → reveal a random catalog hero.
function HeroReveal.bindDebugHotkey()
    local HeroCatalog = require(ReplicatedStorage.shared.data.HeroCatalog)
    local MutationLogic = require(ReplicatedStorage.shared.util.MutationLogic)
    local RarityDatabase = require(ReplicatedStorage.shared.data.RarityDatabase)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end
        if input.KeyCode ~= Enum.KeyCode.H then
            return
        end
        if _busy then
            return
        end
        local rarities = RarityDatabase.ordered()
        local rarity = rarities[math.random(1, #rarities)]
        local pool = HeroCatalog.pool(rarity)
        if #pool == 0 then
            return
        end
        local heroId = pool[math.random(1, #pool)]
        local mutations = MutationLogic.rollOfferMutations(rarity, math.random(), math.random())
        HeroReveal.show({
            heroId = heroId,
            displayName = HeroCatalog.displayName(heroId),
            rarity = rarity,
            mutations = mutations,
            mutationLabel = MutationLogic.formatLabel(mutations),
            incomeRate = 12,
        })
    end)
end

return HeroReveal
