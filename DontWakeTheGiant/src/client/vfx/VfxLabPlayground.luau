--!strict
-- VfxLab Playground: intensity/tier controls, replay, budget HUD, camera modes.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local FxKit = require(script.Parent.Parent.ui.fx.FxKit)
local SettingsManager = require(script.Parent.Parent.core.SettingsManager)
local VfxController = require(script.Parent.Parent.core.VfxController)
local theme = require(script.Parent.Parent.ui.theme)

local Playground = {}

local TIERS = { "Auto", "Low", "Medium", "High", "Ultra" }

local function ensureLab(): Folder
    local existing = Workspace:FindFirstChild("VfxLab")
    if existing and existing:IsA("Folder") and existing:FindFirstChild("CenterBurst") then
        return existing
    end
    if existing then
        existing:Destroy()
    end

    local lab = Instance.new("Folder")
    lab.Name = "VfxLab"
    lab.Parent = Workspace

    local function makePart(name: string, cframe: CFrame, color: Color3, size: Vector3?): BasePart
        local part = Instance.new("Part")
        part.Name = name
        part.Anchored = true
        part.CanCollide = false
        part.Material = Enum.Material.Neon
        part.Color = color
        part.Size = size or Vector3.new(1.5, 1.5, 1.5)
        part.CFrame = cframe
        part.Parent = lab

        local bb = Instance.new("BillboardGui")
        bb.Name = "Tag"
        bb.Size = UDim2.fromOffset(120, 26)
        bb.StudsOffset = Vector3.new(0, 2.6, 0)
        bb.AlwaysOnTop = true
        bb.Parent = part
        local t = Instance.new("TextLabel")
        t.BackgroundTransparency = 1
        t.Size = UDim2.fromScale(1, 1)
        t.Font = Enum.Font.GothamBold
        t.TextScaled = true
        t.TextColor3 = Color3.new(1, 1, 1)
        t.TextStrokeTransparency = 0.4
        t.Text = name
        t.Parent = bb
        return part
    end

    local origin = Vector3.new(0, 6, 0)
    makePart("CenterBurst", CFrame.new(origin), Color3.fromRGB(120, 220, 255))
    makePart("CastBurst", CFrame.new(origin + Vector3.new(-12, 0, 0)), Color3.fromRGB(255, 210, 80))
    makePart(
        "FlipbookBurst",
        CFrame.new(origin + Vector3.new(12, 0, 0)),
        Color3.fromRGB(255, 90, 220)
    )
    makePart(
        "AuraAnchor",
        CFrame.new(origin + Vector3.new(0, 0, 12)),
        Color3.fromRGB(180, 100, 255),
        Vector3.new(2, 2, 2)
    )
    makePart(
        "HandGlowAnchor",
        CFrame.new(origin + Vector3.new(0, 0, -12)),
        Color3.fromRGB(100, 255, 160),
        Vector3.new(1.2, 2.4, 1.2)
    )
    makePart(
        "ProjectileStart",
        CFrame.new(origin + Vector3.new(-18, 0, -10)),
        Color3.fromRGB(90, 180, 255),
        Vector3.new(1, 1, 1)
    )
    makePart(
        "ProjectileEnd",
        CFrame.new(origin + Vector3.new(18, 0, -10)),
        Color3.fromRGB(255, 90, 180),
        Vector3.new(1, 1, 1)
    )
    makePart(
        "HitDummy",
        CFrame.new(origin + Vector3.new(0, 0, 22)),
        Color3.fromRGB(255, 255, 255),
        Vector3.new(3, 4, 1.5)
    )

    local floor = Instance.new("Part")
    floor.Name = "Floor"
    floor.Anchored = true
    floor.Material = Enum.Material.SmoothPlastic
    floor.Color = Color3.fromRGB(20, 22, 30)
    floor.Size = Vector3.new(48, 1, 48)
    floor.CFrame = CFrame.new(origin + Vector3.new(0, -2.5, 0))
    floor.Parent = lab

    local neonDecal = Instance.new("Decal")
    neonDecal.Name = "AtlasPreview"
    neonDecal.Face = Enum.NormalId.Front
    neonDecal.Texture = "rbxassetid://117687641569968"
    neonDecal.Parent = lab.FlipbookBurst

    local smokeDecal = Instance.new("Decal")
    smokeDecal.Name = "AtlasPreview"
    smokeDecal.Face = Enum.NormalId.Front
    smokeDecal.Texture = "rbxassetid://131840252392616"
    smokeDecal.Parent = lab.CastBurst

    lab.FlipbookBurst.Tag.TextLabel.Text = "NEON"
    lab.CastBurst.Tag.TextLabel.Text = "SMOKE"
    lab.CenterBurst.Tag.TextLabel.Text = "IMPACT"
    lab.AuraAnchor.Tag.TextLabel.Text = "AURA"
    lab.HandGlowAnchor.Tag.TextLabel.Text = "HAND"
    lab.ProjectileStart.Tag.TextLabel.Text = "FROM"
    lab.ProjectileEnd.Tag.TextLabel.Text = "TO"
    lab.HitDummy.Tag.TextLabel.Text = "HIT"

    return lab
end

local function getPart(name: string): BasePart
    local lab = ensureLab()
    local part = lab:WaitForChild(name, 5)
    assert(part, `missing {name}`)
    return part :: BasePart
end

function Playground.start()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    local okStart, errStart = pcall(function()
        VfxController.start({ cameraMode = "HumanoidOffset" })
    end)
    if not okStart then
        warn("[VfxLab] VfxController.start failed:", errStart)
    end

    ensureLab()

    local center = getPart("CenterBurst")
    local cast = getPart("CastBurst")
    local flipbook = getPart("FlipbookBurst")
    local auraAnchor = getPart("AuraAnchor")
    local handGlowAnchor = getPart("HandGlowAnchor")
    local projectileStart = getPart("ProjectileStart")
    local projectileEnd = getPart("ProjectileEnd")
    local hitDummy = getPart("HitDummy")

    local auraHandle = VfxController.play("PowerAura", {
        cframe = auraAnchor.CFrame,
        color = auraAnchor.Color,
        intensity = 0.85,
    })
    local handHandle = VfxController.play("HandGlow", {
        cframe = handGlowAnchor.CFrame,
        target = handGlowAnchor,
        color = handGlowAnchor.Color,
        intensity = 0.85,
    })

    local autoPlay = true
    local stressMode = false
    local cameraMode = "HumanoidOffset"
    local intensity = 1.15
    local tierIndex = 1 -- Auto
    local lastReplay: (() -> ())? = nil
    local chargeHandle: any = nil

    local gui = Instance.new("ScreenGui")
    gui.Name = "VfxLabUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 80
    gui.Parent = playerGui

    local panel = Instance.new("ScrollingFrame")
    panel.Name = "Panel"
    panel.AnchorPoint = Vector2.new(1, 0)
    panel.Position = UDim2.new(1, -16, 0, 72)
    panel.Size = UDim2.fromOffset(248, 520)
    panel.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
    panel.BackgroundTransparency = 0.18
    panel.BorderSizePixel = 0
    panel.ScrollBarThickness = 4
    panel.CanvasSize = UDim2.fromOffset(0, 1100)
    panel.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = panel

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.PaddingLeft = UDim.new(0, 8)
    pad.PaddingRight = UDim.new(0, 8)
    pad.Parent = panel

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 6)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = panel

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 24)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = Color3.fromRGB(240, 245, 255)
    title.Text = "VFX LAB"
    title.LayoutOrder = 0
    title.Parent = panel

    local budgetHud = Instance.new("TextLabel")
    budgetHud.Name = "BudgetHud"
    budgetHud.Size = UDim2.new(1, 0, 0, 48)
    budgetHud.BackgroundTransparency = 1
    budgetHud.Font = Enum.Font.Gotham
    budgetHud.TextSize = 12
    budgetHud.TextWrapped = true
    budgetHud.TextXAlignment = Enum.TextXAlignment.Left
    budgetHud.TextYAlignment = Enum.TextYAlignment.Top
    budgetHud.TextColor3 = Color3.fromRGB(140, 210, 170)
    budgetHud.Text = "Budget…"
    budgetHud.LayoutOrder = 1
    budgetHud.Parent = panel

    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Size = UDim2.new(1, 0, 0, 32)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.Gotham
    status.TextSize = 12
    status.TextWrapped = true
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextYAlignment = Enum.TextYAlignment.Top
    status.TextColor3 = Color3.fromRGB(160, 190, 220)
    status.Text = "Auto ON · Cam Humanoid"
    status.LayoutOrder = 2
    status.Parent = panel

    local intensityLabel = Instance.new("TextLabel")
    intensityLabel.Size = UDim2.new(1, 0, 0, 18)
    intensityLabel.BackgroundTransparency = 1
    intensityLabel.Font = Enum.Font.GothamMedium
    intensityLabel.TextSize = 12
    intensityLabel.TextXAlignment = Enum.TextXAlignment.Left
    intensityLabel.TextColor3 = Color3.fromRGB(200, 210, 230)
    intensityLabel.Text = `Intensity {string.format("%.2f", intensity)}`
    intensityLabel.LayoutOrder = 3
    intensityLabel.Parent = panel

    local function setStatus(msg: string)
        status.Text = msg
    end

    local function applyTier()
        local name = TIERS[tierIndex]
        if name == "Auto" then
            VfxController.setTierOverride(nil)
        else
            VfxController.setTierOverride(name)
        end
        setStatus(`Tier {name} · intensity {string.format("%.2f", intensity)}`)
    end

    local function makeButton(label: string, order: number, onClick: () -> ())
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 28)
        btn.BackgroundColor3 = Color3.fromRGB(28, 36, 52)
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 13
        btn.TextColor3 = Color3.fromRGB(230, 240, 255)
        btn.Text = label
        btn.LayoutOrder = order
        btn.AutoButtonColor = true
        btn.Parent = panel
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = btn
        btn.MouseButton1Click:Connect(function()
            local ok, err = pcall(onClick)
            if not ok then
                setStatus(`ERR: {err}`)
                warn("[VfxLab]", err)
            end
        end)
        return btn
    end

    local function playWithReplay(label: string, fn: () -> ())
        lastReplay = fn
        fn()
        setStatus(label)
    end

    makeButton("Intensity −", 4, function()
        intensity = math.clamp(intensity - 0.15, 0.25, 2.5)
        intensityLabel.Text = `Intensity {string.format("%.2f", intensity)}`
        setStatus(intensityLabel.Text)
    end)
    makeButton("Intensity +", 5, function()
        intensity = math.clamp(intensity + 0.15, 0.25, 2.5)
        intensityLabel.Text = `Intensity {string.format("%.2f", intensity)}`
        setStatus(intensityLabel.Text)
    end)
    makeButton("Cycle Tier", 6, function()
        tierIndex = tierIndex % #TIERS + 1
        applyTier()
    end)
    makeButton("Replay Last", 7, function()
        if lastReplay then
            lastReplay()
            setStatus("Replay")
        else
            setStatus("Nothing to replay")
        end
    end)

    makeButton("★★★ CINEMA CATACLYSM", 8, function()
        playWithReplay("CinemaCataclysm", function()
            VfxController.play("CinemaCataclysm", {
                cframe = center.CFrame,
                color = Color3.fromRGB(255, 70, 30),
                intensity = math.max(intensity, 1.4),
            })
        end)
    end)
    makeButton("★★ MEGUMIN BLAST", 9, function()
        playWithReplay("MeguminBlast", function()
            VfxController.play("MeguminBlast", {
                cframe = center.CFrame,
                color = Color3.fromRGB(255, 90, 20),
                intensity = math.max(intensity, 1.35),
            })
        end)
    end)
    makeButton("★ METEOR STRIKE", 10, function()
        playWithReplay("MeteorStrike", function()
            VfxController.play("MeteorStrike", {
                cframe = center.CFrame,
                color = Color3.fromRGB(255, 120, 40),
                intensity = math.max(intensity, 1.2),
            })
        end)
    end)
    makeButton("Ore Shatter", 91, function()
        playWithReplay("OreShatter", function()
            VfxController.play("OreShatter", {
                cframe = center.CFrame,
                color = Color3.fromRGB(180, 140, 90),
                intensity = intensity,
            })
        end)
    end)
    makeButton("Pet Appear", 92, function()
        playWithReplay("PetAppear", function()
            VfxController.play("PetAppear", {
                cframe = auraAnchor.CFrame,
                target = auraAnchor,
                color = Color3.fromRGB(255, 140, 220),
                intensity = intensity,
            })
        end)
    end)
    makeButton("Egg Hatch", 93, function()
        playWithReplay("EggHatch", function()
            VfxController.play("EggHatch", {
                cframe = hitDummy.CFrame,
                target = hitDummy,
                color = Color3.fromRGB(255, 210, 90),
                intensity = math.max(intensity, 1.1),
            })
        end)
    end)
    makeButton("Neon Impact", 11, function()
        playWithReplay("NeonImpact", function()
            VfxController.play("NeonImpact", {
                cframe = flipbook.CFrame,
                color = Color3.fromRGB(90, 230, 255),
                intensity = intensity,
            })
        end)
    end)
    makeButton("Smoke Dash", 11, function()
        playWithReplay("SmokeDash", function()
            VfxController.play("SmokeDash", {
                cframe = cast.CFrame,
                color = Color3.fromRGB(90, 95, 110),
                intensity = intensity,
            })
        end)
    end)
    makeButton("Impact Burst", 12, function()
        playWithReplay("ImpactBurst", function()
            VfxController.play("ImpactBurst", {
                cframe = center.CFrame,
                color = center.Color,
                intensity = intensity,
            })
        end)
    end)
    makeButton("Cast Burst", 13, function()
        playWithReplay("CastBurst", function()
            VfxController.play("CastBurst", {
                cframe = cast.CFrame,
                color = cast.Color,
                intensity = intensity,
            })
        end)
    end)
    makeButton("Neon Bolt", 14, function()
        playWithReplay("NeonBolt", function()
            VfxController.play("NeonBolt", {
                from = projectileStart.CFrame,
                to = projectileEnd.CFrame,
                color = Color3.fromRGB(120, 220, 255),
                intensity = intensity,
            })
        end)
    end)
    makeButton("Hit Confirm", 15, function()
        playWithReplay("HitConfirm", function()
            VfxController.play("HitConfirm", {
                cframe = hitDummy.CFrame,
                target = hitDummy,
                color = Color3.fromRGB(255, 255, 255),
                intensity = intensity,
            })
        end)
    end)
    makeButton("Crit Impact", 16, function()
        playWithReplay("CritImpact", function()
            VfxController.play("CritImpact", {
                cframe = flipbook.CFrame,
                color = Color3.fromRGB(255, 70, 120),
                intensity = intensity,
            })
        end)
    end)
    makeButton("Ground Slam", 17, function()
        playWithReplay("GroundSlam", function()
            VfxController.play("GroundSlam", {
                cframe = center.CFrame,
                color = Color3.fromRGB(255, 160, 80),
                intensity = intensity,
            })
        end)
    end)
    makeButton("Heal Pulse", 18, function()
        playWithReplay("HealPulse", function()
            VfxController.play("HealPulse", {
                cframe = handGlowAnchor.CFrame,
                color = Color3.fromRGB(90, 255, 170),
                intensity = intensity,
            })
        end)
    end)
    makeButton("Chain Strike", 19, function()
        playWithReplay("ChainStrike", function()
            VfxController.play("ChainStrike", {
                from = projectileStart.CFrame,
                to = projectileEnd.CFrame,
                color = Color3.fromRGB(255, 230, 140),
                intensity = intensity,
            })
        end)
    end)
    makeButton("Ultimate Charge", 20, function()
        if chargeHandle and chargeHandle:isPlaying() then
            chargeHandle:stop()
            chargeHandle = nil
            setStatus("Charge stopped")
            return
        end
        chargeHandle = VfxController.play("UltimateCharge", {
            cframe = auraAnchor.CFrame,
            color = Color3.fromRGB(180, 100, 255),
            intensity = intensity,
        })
        setStatus("Charge ON · click again to stop")
    end)
    makeButton("Damage Flash", 21, function()
        playWithReplay("DamageFlash", function()
            VfxController.play("DamageFlash", { intensity = intensity * 0.7 })
        end)
    end)
    makeButton("UI FloatText", 211, function()
        local FxKit = require(script.Parent.Parent.ui.fx.FxKit)
        local cam = Workspace.CurrentCamera
        local vp = if cam then cam.ViewportSize else Vector2.new(1280, 720)
        FxKit.floatText.play({
            text = "+1,250",
            position = Vector2.new(vp.X * 0.5, vp.Y * 0.42),
            color = Color3.fromRGB(255, 220, 80),
        })
        setStatus("UI FloatText")
    end)
    makeButton("UI CoinRain", 212, function()
        local FxKit = require(script.Parent.Parent.ui.fx.FxKit)
        local cam = Workspace.CurrentCamera
        local vp = if cam then cam.ViewportSize else Vector2.new(1280, 720)
        local from = Vector2.new(vp.X * 0.5, vp.Y * 0.55)
        local to = Vector2.new(vp.X * 0.88, vp.Y * 0.08)
        FxKit.coinRain.play({ from = from, to = to, count = 16 })
        FxKit.floatText.play({
            text = "loot!",
            position = from,
            color = Color3.fromRGB(255, 212, 38),
            duration = 0.7,
        })
        setStatus("UI CoinRain → top-right (skin per game)")
    end)
    makeButton("UI Shockwave", 213, function()
        local FxKit = require(script.Parent.Parent.ui.fx.FxKit)
        local layer = FxKit.overlay.getLayer()
        local host = Instance.new("Frame")
        host.BackgroundTransparency = 1
        host.Size = UDim2.fromScale(1, 1)
        host.Parent = layer
        FxKit.shockwave(host, Color3.fromRGB(120, 200, 255), 220, 0.45)
        task.delay(0.6, function()
            host:Destroy()
        end)
        setStatus("UI Shockwave")
    end)
    makeButton("UI FloatText", 211, function()
        local cam = Workspace.CurrentCamera
        local vp = if cam then cam.ViewportSize else Vector2.new(1280, 720)
        FxKit.FloatText.play({
            text = "+1,250",
            position = Vector2.new(vp.X * 0.5, vp.Y * 0.42),
            color = theme.Colors.gold,
        })
        setStatus("UI FX · FloatText (skin text/color per game)")
    end)
    makeButton("UI FlyBurst", 212, function()
        local cam = Workspace.CurrentCamera
        local vp = if cam then cam.ViewportSize else Vector2.new(1280, 720)
        local from = Vector2.new(vp.X * 0.5, vp.Y * 0.55)
        local to = Vector2.new(vp.X * 0.88, vp.Y * 0.12)
        FxKit.FlyBurst.play({
            from = from,
            to = to,
            count = math.floor(10 + intensity * 8),
            color = theme.Colors.gold,
            sizePx = 16,
        })
        FxKit.shockwaveAt(to, theme.Colors.goldHi, 64, 0.35)
        setStatus("UI FX · FlyBurst A→B (coins/gems = your texture)")
    end)
    makeButton("Toggle Auto", 22, function()
        autoPlay = not autoPlay
        setStatus(`Auto {if autoPlay then "ON" else "OFF"} · Cam {cameraMode}`)
    end)
    makeButton("Stress Mode", 23, function()
        stressMode = not stressMode
        autoPlay = stressMode
        if stressMode then
            VfxController.setTierOverride("Low")
            tierIndex = 2
            setStatus("STRESS ON · forced Low tier flood")
        else
            VfxController.setTierOverride(nil)
            tierIndex = 1
            setStatus("Stress OFF · Auto tier")
        end
    end)
    makeButton("Cam: Humanoid", 24, function()
        cameraMode = "HumanoidOffset"
        VfxController.setCameraMode("HumanoidOffset")
        setStatus("Cam HumanoidOffset")
    end)
    makeButton("Cam: ShakeBus", 25, function()
        cameraMode = "ShakeBus"
        VfxController.setCameraMode("ShakeBus", function(offset)
            local cam = Workspace.CurrentCamera
            if cam then
                cam.CFrame = cam.CFrame * CFrame.new(offset * 0.35)
            end
        end)
        setStatus("Cam ShakeBus")
    end)
    makeButton("Cam: Noop", 26, function()
        cameraMode = "Noop"
        VfxController.setCameraMode("Noop")
        setStatus("Cam Noop")
    end)
    makeButton("Toggle ReduceMotion", 27, function()
        SettingsManager.setReduceMotion(not SettingsManager.isReduceMotion())
        setStatus(`reduceMotion={SettingsManager.isReduceMotion()}`)
    end)
    makeButton("Stop All", 28, function()
        VfxController.stopAll()
        chargeHandle = nil
        auraHandle = VfxController.play("PowerAura", {
            cframe = auraAnchor.CFrame,
            color = auraAnchor.Color,
            intensity = 0.85,
        })
        handHandle = VfxController.play("HandGlow", {
            cframe = handGlowAnchor.CFrame,
            target = handGlowAnchor,
            color = handGlowAnchor.Color,
            intensity = 0.85,
        })
        setStatus("Stopped · loops restarted")
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then
            return
        end
        if input.KeyCode == Enum.KeyCode.One then
            VfxController.play("NeonImpact", {
                cframe = flipbook.CFrame,
                color = Color3.fromRGB(90, 230, 255),
                intensity = intensity,
            })
        elseif input.KeyCode == Enum.KeyCode.Two then
            VfxController.play("SmokeDash", {
                cframe = cast.CFrame,
                color = Color3.fromRGB(90, 95, 110),
                intensity = intensity,
            })
        elseif input.KeyCode == Enum.KeyCode.Three then
            VfxController.play("NeonBolt", {
                from = projectileStart.CFrame,
                to = projectileEnd.CFrame,
                color = Color3.fromRGB(120, 220, 255),
                intensity = intensity,
            })
        elseif input.KeyCode == Enum.KeyCode.Four then
            autoPlay = not autoPlay
            setStatus(`Auto {if autoPlay then "ON" else "OFF"} · Cam {cameraMode}`)
        elseif input.KeyCode == Enum.KeyCode.Five then
            VfxController.play("CinemaCataclysm", {
                cframe = center.CFrame,
                color = Color3.fromRGB(255, 70, 30),
                intensity = math.max(intensity, 1.4),
            })
            setStatus("★★★ CinemaCataclysm")
        elseif input.KeyCode == Enum.KeyCode.Nine then
            VfxController.play("MeguminBlast", {
                cframe = center.CFrame,
                color = Color3.fromRGB(255, 90, 20),
                intensity = math.max(intensity, 1.35),
            })
        elseif input.KeyCode == Enum.KeyCode.Zero then
            VfxController.play("MeteorStrike", {
                cframe = center.CFrame,
                color = Color3.fromRGB(255, 120, 40),
                intensity = math.max(intensity, 1.2),
            })
        elseif input.KeyCode == Enum.KeyCode.Six then
            VfxController.play("OreShatter", {
                cframe = center.CFrame,
                color = Color3.fromRGB(180, 140, 90),
                intensity = intensity,
            })
        elseif input.KeyCode == Enum.KeyCode.Seven then
            VfxController.play("PetAppear", {
                cframe = auraAnchor.CFrame,
                target = auraAnchor,
                color = Color3.fromRGB(255, 140, 220),
                intensity = intensity,
            })
        elseif input.KeyCode == Enum.KeyCode.Eight then
            VfxController.play("EggHatch", {
                cframe = hitDummy.CFrame,
                target = hitDummy,
                color = Color3.fromRGB(255, 210, 90),
                intensity = math.max(intensity, 1.1),
            })
        elseif input.KeyCode == Enum.KeyCode.R then
            if lastReplay then
                lastReplay()
            end
        end
    end)

    RunService.Heartbeat:Connect(function()
        local ok, stats = pcall(function()
            return VfxController.getStats()
        end)
        if ok and stats then
            budgetHud.Text =
                `Tier {stats.tier} · FPS {stats.fps}\nFX {stats.active} · Emit {stats.emitters} · Drop {stats.dropped} · Therm {string.format(
                    "%.2f",
                    stats.thermal
                )}`
        end
    end)

    local autoStep = 0
    task.spawn(function()
        while true do
            if autoPlay then
                autoStep += 1
                if auraHandle and auraHandle:isPlaying() then
                    auraHandle:setIntensity(0.7 + 0.25 * math.sin(os.clock() * 2))
                end
                if handHandle and handHandle:isPlaying() then
                    handHandle:setIntensity(0.7 + 0.2 * math.sin(os.clock() * 2.4))
                end
                if chargeHandle and chargeHandle:isPlaying() then
                    chargeHandle:setIntensity(0.6 + 0.4 * (0.5 + 0.5 * math.sin(os.clock() * 3)))
                end

                local flood = if stressMode then 3 else 1
                for _ = 1, flood do
                    if autoStep % 2 == 1 then
                        VfxController.play("NeonImpact", {
                            cframe = flipbook.CFrame,
                            color = Color3.fromRGB(90, 230, 255),
                            intensity = intensity,
                        })
                    else
                        VfxController.play("SmokeDash", {
                            cframe = cast.CFrame,
                            color = Color3.fromRGB(70, 75, 90),
                            intensity = intensity,
                        })
                    end
                    if stressMode then
                        VfxController.play("CritImpact", {
                            cframe = center.CFrame,
                            color = Color3.fromRGB(255, 70, 120),
                            intensity = intensity,
                        })
                        VfxController.play("GroundSlam", {
                            cframe = hitDummy.CFrame,
                            intensity = intensity,
                        })
                    end
                end

                task.wait(if stressMode then 0.12 else 0.35)
                VfxController.play("NeonBolt", {
                    from = projectileStart.CFrame,
                    to = projectileEnd.CFrame,
                    color = Color3.fromRGB(120, 220, 255),
                    intensity = intensity * 0.95,
                })
                if not stressMode then
                    task.wait(0.25)
                    VfxController.play("ImpactBurst", {
                        cframe = center.CFrame,
                        color = center.Color,
                        intensity = intensity * 0.95,
                    })
                    task.wait(0.2)
                    VfxController.play("HitConfirm", {
                        cframe = hitDummy.CFrame,
                        target = hitDummy,
                        intensity = intensity,
                    })
                end
            end
            task.wait(if stressMode then 0.2 else 0.85)
        end
    end)

    -- Showcase CinemaCataclysm once on boot
    task.delay(0.9, function()
        VfxController.play("CinemaCataclysm", {
            cframe = center.CFrame,
            color = Color3.fromRGB(255, 70, 30),
            intensity = 1.5,
        })
        setStatus("★★★ CinemaCataclysm showcase (~7s)")
    end)

    print("[VfxLab] CinemaCataclysm key 5 · Megumin 9 · Meteor 0 · Ore/Pet/Egg 6-8")
end

return Playground
