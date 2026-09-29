--!strict
-- Pad face colors / billboard / press on Cube.001 + Cube.002.

local TweenService = game:GetService("TweenService")

local Constants = require(game:GetService("ReplicatedStorage").shared.data.Constants)
local IconCatalog = require(game:GetService("ReplicatedStorage").shared.data.IconCatalog)
local PadSummonProgress = require(script.Parent.PadSummonProgress)

export type BuyTone = "green" | "red"
export type MergeTone = "orange" | "gray"
export type UpgradeTone = "green" | "gray"

local COLOR_FACE = "Cube.001"
local PRESS_PARTS = { "Cube.001", "Cube.002" }

local COLOR = {
    green = Color3.fromRGB(0, 152, 0),
    red = Color3.fromRGB(200, 40, 40),
    orange = Color3.fromRGB(255, 140, 20),
    gray = Color3.fromRGB(85, 85, 127),
}

-- Subtle brighten on press (not full white).
local HIGHLIGHT_BLEND = 0.42

local restFace: { [BasePart]: CFrame } = {}
local pressing: { [Instance]: boolean } = {}
local faceTweens: { [Instance]: Tween } = {}
-- Face color before press highlight; restored if no tone update arrives mid-press.
local flashRestore: { [Instance]: Color3 } = {}
-- Tone color queued while pressing (refreshLabels must not kill the flash).
local pendingFaceColor: { [Instance]: Color3 } = {}

local PadVisuals = {}

local function colorFace(model: Instance): BasePart?
    local face = model:FindFirstChild(COLOR_FACE)
    if face and face:IsA("BasePart") then
        return face
    end
    return nil
end

local function pressParts(model: Instance): { BasePart }
    local parts: { BasePart } = {}
    for _, name in PRESS_PARTS do
        local part = model:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            table.insert(parts, part)
        end
    end
    return parts
end

local function setFaceColor(model: Instance, color: Color3)
    if pressing[model] then
        pendingFaceColor[model] = color
        return
    end
    local face = colorFace(model)
    if face then
        face.Color = color
    end
end

local function setBillboardEnabled(model: Instance, enabled: boolean)
    for _, inst in model:GetDescendants() do
        if inst:IsA("BillboardGui") then
            inst.Enabled = enabled
        end
    end
end

local function rememberRest(parts: { BasePart })
    for _, part in parts do
        if restFace[part] == nil then
            restFace[part] = part.CFrame
        end
    end
end

local function restoreParts(parts: { BasePart })
    for _, part in parts do
        local rest = restFace[part]
        if rest and part.Parent then
            part.CFrame = rest
        end
    end
end

local function cancelFaceTween(model: Instance)
    local tween = faceTweens[model]
    if tween then
        tween:Cancel()
        faceTweens[model] = nil
    end
end

local function highlightColor(base: Color3): Color3
    return base:Lerp(Color3.new(1, 1, 1), HIGHLIGHT_BLEND)
end

local function tweenFaceColor(
    model: Instance,
    face: BasePart,
    targetColor: Color3,
    duration: number,
    easingDirection: Enum.EasingDirection
)
    cancelFaceTween(model)
    local tween = TweenService:Create(
        face,
        TweenInfo.new(duration, Enum.EasingStyle.Sine, easingDirection),
        { Color = targetColor }
    )
    faceTweens[model] = tween
    tween:Play()
    tween.Completed:Once(function()
        if faceTweens[model] == tween then
            faceTweens[model] = nil
        end
    end)
end

local function restoreFaceAfterPress(model: Instance)
    local face = colorFace(model)
    if face == nil then
        flashRestore[model] = nil
        pendingFaceColor[model] = nil
        return
    end
    local nextColor = pendingFaceColor[model] or flashRestore[model]
    if nextColor then
        face.Color = nextColor
    end
    flashRestore[model] = nil
    pendingFaceColor[model] = nil
end

local function finishPress(
    model: Instance,
    parts: { BasePart },
    state: { done: boolean },
    onDone: (() -> ())?
)
    if state.done then
        return
    end
    state.done = true
    pressing[model] = nil
    model:SetAttribute("PadPressing", false)
    cancelFaceTween(model)
    restoreParts(parts)
    restoreFaceAfterPress(model)
    if onDone then
        onDone()
    end
end

function PadVisuals.setBuyTone(model: Instance?, tone: BuyTone)
    if model == nil then
        return
    end
    setFaceColor(model, COLOR[tone])
end

function PadVisuals.setMergeTone(model: Instance?, tone: MergeTone)
    if model == nil then
        return
    end
    setFaceColor(model, COLOR[tone])
    setBillboardEnabled(model, tone == "orange")
end

function PadVisuals.setUpgradeTone(model: Instance?, tone: UpgradeTone)
    if model == nil then
        return
    end
    setFaceColor(model, COLOR[tone])
end

function PadVisuals.isPressing(model: Instance): boolean
    return pressing[model] == true
end

function PadVisuals.playPress(model: Instance, onDone: (() -> ())?)
    if pressing[model] then
        return
    end

    local parts = pressParts(model)
    if #parts == 0 then
        if onDone then
            onDone()
        end
        return
    end

    rememberRest(parts)
    pressing[model] = true
    model:SetAttribute("PadPressing", true)

    local face = colorFace(model)
    local pressBaseColor: Color3? = nil
    if face then
        pressBaseColor = face.Color
        flashRestore[model] = pressBaseColor
        tweenFaceColor(
            model,
            face,
            highlightColor(pressBaseColor),
            Constants.PAD_PRESS_DOWN_SEC,
            Enum.EasingDirection.Out
        )
    end

    local state = { done = false }
    local downInfo =
        TweenInfo.new(Constants.PAD_PRESS_DOWN_SEC, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local upInfo =
        TweenInfo.new(Constants.PAD_PRESS_UP_SEC, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local pendingDown = #parts
    local pendingUp = #parts

    local function playUp()
        if face and pressBaseColor then
            local restoreColor = pendingFaceColor[model] or flashRestore[model] or pressBaseColor
            tweenFaceColor(
                model,
                face,
                restoreColor,
                Constants.PAD_PRESS_UP_SEC,
                Enum.EasingDirection.In
            )
        end
        for _, part in parts do
            local rest = restFace[part]
            if rest == nil or part.Parent == nil then
                finishPress(model, parts, state, onDone)
                return
            end
            local tweenUp = TweenService:Create(part, upInfo, { CFrame = rest })
            tweenUp:Play()
            tweenUp.Completed:Once(function()
                pendingUp -= 1
                if pendingUp <= 0 then
                    finishPress(model, parts, state, onDone)
                end
            end)
        end
    end

    for _, part in parts do
        part.Anchored = true
        local rest = restFace[part]
        local down = rest * CFrame.new(0, -Constants.PAD_PRESS_DEPTH, 0)
        local tweenDown = TweenService:Create(part, downInfo, { CFrame = down })
        tweenDown:Play()
        tweenDown.Completed:Once(function(playbackState)
            if state.done then
                return
            end
            if playbackState ~= Enum.PlaybackState.Completed or part.Parent == nil then
                finishPress(model, parts, state, onDone)
                return
            end
            pendingDown -= 1
            if pendingDown <= 0 then
                playUp()
            end
        end)
    end
end

function PadVisuals.clearCache(model: Instance?)
    if model == nil then
        return
    end
    local parts = pressParts(model)
    restoreParts(parts)
    for _, part in parts do
        restFace[part] = nil
    end
    pressing[model] = nil
    cancelFaceTween(model)
    flashRestore[model] = nil
    pendingFaceColor[model] = nil
    model:SetAttribute("PadPressing", false)
end

function PadVisuals.snapshotPads(pads: { [string]: Instance })
    for _, model in pads do
        rememberRest(pressParts(model))
    end
end

local function findPriceLabel(model: Instance): TextLabel?
    for _, inst in model:GetDescendants() do
        if inst:IsA("TextLabel") and inst.Name == "Price" then
            return inst
        end
    end
    return nil
end

local function ensureAspect(icon: ImageLabel): UIAspectRatioConstraint
    local aspect = icon:FindFirstChildOfClass("UIAspectRatioConstraint")
    if aspect == nil then
        aspect = Instance.new("UIAspectRatioConstraint")
        aspect.Parent = icon
    end
    aspect.AspectRatio = 1
    -- Width 0 + DominantAxis Width → 0×0 on BillboardGui (icon vanishes at Play).
    aspect.DominantAxis = Enum.DominantAxis.Height
    return aspect
end

local function ensureRobuxPriceRow(price: TextLabel): (Frame, ImageLabel)
    local parent = price.Parent
    if parent and parent:IsA("Frame") and parent.Name == "PriceRow" then
        local icon = parent:FindFirstChild("RobuxIcon")
        if icon and icon:IsA("ImageLabel") then
            return parent, icon
        end
    end

    local row = Instance.new("Frame")
    row.Name = "PriceRow"
    row.BackgroundTransparency = 1
    row.BorderSizePixel = 0
    row.Size = UDim2.fromScale(1, 1)
    row.LayoutOrder = price.LayoutOrder
    row.Parent = price.Parent

    local list = Instance.new("UIListLayout")
    list.FillDirection = Enum.FillDirection.Horizontal
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center
    list.VerticalAlignment = Enum.VerticalAlignment.Center
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0.01, 0)
    list.Parent = row

    local icon = Instance.new("ImageLabel")
    icon.Name = "RobuxIcon"
    icon.BackgroundTransparency = 1
    icon.BorderSizePixel = 0
    icon.Image = IconCatalog.Robux
    icon.ImageColor3 = Color3.new(1, 1, 1)
    icon.ScaleType = Enum.ScaleType.Fit
    icon.Size = UDim2.fromScale(0.3, 1)
    icon.LayoutOrder = 1
    icon.Parent = row
    ensureAspect(icon)

    price.Position = UDim2.fromScale(0, 0)
    price.AnchorPoint = Vector2.new(0, 0)
    price.LayoutOrder = 2
    price.Parent = row

    return row, icon
end

local function layoutRobuxPrice(row: Frame, price: TextLabel, icon: ImageLabel, owned: boolean)
    local list = row:FindFirstChildOfClass("UIListLayout")
    if list then
        list.Padding = UDim.new(0.01, 0)
        list.HorizontalAlignment = Enum.HorizontalAlignment.Center
        list.VerticalAlignment = Enum.VerticalAlignment.Center
    end
    if owned then
        price.TextXAlignment = Enum.TextXAlignment.Center
        price.Size = UDim2.fromScale(1, 1)
        icon.Visible = false
        return
    end
    ensureAspect(icon)
    icon.Image = IconCatalog.Robux
    -- Match PadBillboard.story: non-zero width. Size(0, …) collapses on BillboardGui.
    icon.Size = UDim2.fromScale(0.3, 1)
    icon.Visible = true
    price.TextXAlignment = Enum.TextXAlignment.Left
    price.Size = UDim2.fromScale(0.22, 0.92)
end

function PadVisuals.setPadRobuxPrice(model: Instance?, robux: number, owned: boolean)
    if model == nil then
        return
    end
    local price = findPriceLabel(model)
    if price == nil then
        return
    end
    local row, icon = ensureRobuxPriceRow(price)
    if owned then
        price.Text = "OWNED"
    else
        price.Text = tostring(robux)
    end
    layoutRobuxPrice(row, price, icon, owned)
end

function PadVisuals.setPadSummonProgress(
    model: Instance?,
    fraction: number,
    label: string,
    visible: boolean?
)
    PadSummonProgress.apply(model, fraction, label, visible)
end

return PadVisuals
