--!strict
-- World-space floating damage over bots / hits.

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local theme = require(script.Parent.Parent.theme)

export type Options = {
    position: Vector3,
    damage: number,
    headshot: boolean?,
}

local DamageNumber = {}

function DamageNumber.play(opts: Options)
    local anchor = Instance.new("Part")
    anchor.Name = "DamageNumberAnchor"
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.CanQuery = false
    anchor.CanTouch = false
    anchor.Transparency = 1
    anchor.Size = Vector3.new(0.2, 0.2, 0.2)
    anchor.CFrame = CFrame.new(opts.position + Vector3.new(0, 1.2, 0))
    anchor.Parent = workspace

    local gui = Instance.new("BillboardGui")
    gui.Name = "DamageNumber"
    gui.Size = UDim2.fromOffset(72, 36)
    gui.StudsOffset = Vector3.new(0, 0, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 140
    gui.Adornee = anchor
    gui.Parent = anchor

    local isHead = opts.headshot == true
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Text = if isHead
        then `HS {math.floor(opts.damage)}`
        else tostring(math.floor(opts.damage))
    label.TextColor3 = if isHead then theme.Colors.gold else theme.Colors.white
    label.Font = theme.Font.heavy
    label.TextSize = if isHead then 22 else 18
    label.TextStrokeTransparency = 0.4
    label.TextStrokeColor3 = theme.Colors.outlineDark
    label.Parent = gui

    local duration = 0.7
    local rise = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(anchor, rise, {
        CFrame = anchor.CFrame + Vector3.new(0, 2.2, 0),
    }):Play()
    TweenService:Create(label, rise, {
        TextTransparency = 1,
        TextStrokeTransparency = 1,
    }):Play()

    Debris:AddItem(anchor, duration + 0.05)
end

return DamageNumber
