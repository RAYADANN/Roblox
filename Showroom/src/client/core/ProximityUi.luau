--!strict
-- Custom ProximityPrompt chrome: billboard-style text (no card background).

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local UiScreen = require(script.Parent.Parent.ui.util.UiScreen)
local theme = require(script.Parent.Parent.ui.theme)

local Font = theme.Font

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local screen = UiScreen.ensure(playerGui, "ShowroomPrompts", "toast")

type ActiveUi = {
    gui: BillboardGui,
    adorneeKey: string,
}

local active: { [ProximityPrompt]: ActiveUi } = {}
local started = false

local STACK_GAP = 2.2 -- room between Auction / Place Favorite
local BASE_Y = 0.35 -- sit at button / pad / stand height

-- Same look as BlockItem billboard / growth price.
local SPARK_GRADIENT = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 127)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 0)),
})

local function applyBillboardStroke(label: TextLabel)
    local stroke = label:FindFirstChildOfClass("UIStroke")
    if not stroke then
        stroke = Instance.new("UIStroke")
        stroke.Parent = label
    end
    stroke.Color = Color3.new(0, 0, 0)
    stroke.Thickness = 5
    stroke.Transparency = 0
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    stroke.LineJoinMode = Enum.LineJoinMode.Round
    stroke.StrokeSizingMode = Enum.StrokeSizingMode.FixedSize
end

local function applySparkGradient(label: TextLabel)
    local existing = label:FindFirstChild("SparkGradient")
    if existing and existing:IsA("UIGradient") then
        existing.Color = SPARK_GRADIENT
        existing.Enabled = true
        return
    end
    local spark = Instance.new("UIGradient")
    spark.Name = "SparkGradient"
    spark.Color = SPARK_GRADIENT
    spark.Rotation = 0
    spark.Parent = label
end

local function adorneeKeyOf(prompt: ProximityPrompt): string
    local p = prompt.Parent
    if p then
        return p:GetFullName()
    end
    return tostring(prompt)
end

local function keyLabel(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType): string
    if inputType == Enum.ProximityPromptInputType.Touch then
        return "TAP"
    end
    local ok, name = pcall(function()
        return UserInputService:GetStringForKeyCode(prompt.KeyboardKeyCode)
    end)
    if ok and typeof(name) == "string" and name ~= "" then
        return string.upper(name)
    end
    return "E"
end

local function reflowStack(adorneeKey: string)
    local list: { { prompt: ProximityPrompt, ui: ActiveUi } } = {}
    for prompt, ui in active do
        if ui.adorneeKey == adorneeKey then
            table.insert(list, { prompt = prompt, ui = ui })
        end
    end
    table.sort(list, function(a, b)
        local sa = a.prompt:GetAttribute("PromptStack")
        local sb = b.prompt:GetAttribute("PromptStack")
        local na = if typeof(sa) == "number" then sa else 0
        local nb = if typeof(sb) == "number" then sb else 0
        if na == nb then
            return a.prompt.Name < b.prompt.Name
        end
        return na < nb
    end)
    local n = #list
    for i, item in list do
        local fromTop = i - 1
        local y = BASE_Y + (n - 1 - fromTop) * STACK_GAP
        item.ui.gui.StudsOffset = Vector3.new(0, y, 0)
    end
end

local function destroyUi(prompt: ProximityPrompt)
    local ui = active[prompt]
    if not ui then
        return
    end
    local key = ui.adorneeKey
    ui.gui:Destroy()
    active[prompt] = nil
    reflowStack(key)
end

local function showUi(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType)
    destroyUi(prompt)
    local adornee = prompt.Parent
    if not adornee or (not adornee:IsA("BasePart") and not adornee:IsA("Attachment")) then
        return
    end

    local isTouch = inputType == Enum.ProximityPromptInputType.Touch
    local hasObject = prompt.ObjectText ~= ""
    local promptWidth = if isTouch then 280 else 250
    local promptHeight = if hasObject
        then (if isTouch then 96 else 84)
        else (if isTouch then 56 else 48)
    local keyWidth = if isTouch then 56 else 44
    local connections: { RBXScriptConnection } = {}

    local gui = Instance.new("BillboardGui")
    gui.Name = "CustomPrompt"
    gui.Size = UDim2.fromOffset(promptWidth, promptHeight)
    gui.StudsOffset = Vector3.new(0, BASE_Y, 0)
    gui.AlwaysOnTop = true
    gui.LightInfluence = 0
    gui.MaxDistance = prompt.MaxActivationDistance + 6
    gui.Adornee = adornee
    gui.Parent = screen

    -- No card / shadow — transparent root like world billboard text.
    local root = Instance.new("Frame")
    root.Name = "Root"
    root.Size = UDim2.fromScale(1, 1)
    root.BackgroundTransparency = 1
    root.BorderSizePixel = 0
    root.Parent = gui

    local key = Instance.new("TextButton")
    key.Name = "Key"
    key.Size = UDim2.fromOffset(keyWidth, if isTouch then 48 else 40)
    key.Position = UDim2.new(0, 0, 0.5, 0)
    key.AnchorPoint = Vector2.new(0, 0.5)
    key.BackgroundTransparency = 1
    key.BorderSizePixel = 0
    key.AutoButtonColor = false
    key.Active = isTouch
    key.Text = ""
    key.ZIndex = 4
    key.Parent = root
    local keyStroke = Instance.new("UIStroke")
    keyStroke.Color = Color3.new(1, 1, 1)
    keyStroke.Thickness = 2
    keyStroke.Transparency = 0.25
    keyStroke.Parent = key
    local kc = Instance.new("UICorner")
    kc.CornerRadius = UDim.new(0, 10)
    kc.Parent = key

    local kl = Instance.new("TextLabel")
    kl.BackgroundTransparency = 1
    kl.Size = UDim2.fromScale(1, 1)
    kl.Font = Font.display
    kl.TextScaled = true
    kl.TextColor3 = Color3.new(1, 1, 1)
    kl.Text = keyLabel(prompt, inputType)
    kl.ZIndex = 5
    kl.Parent = key
    applyBillboardStroke(kl)

    local textLeft = keyWidth + 10
    local action = Instance.new("TextLabel")
    action.Name = "Action"
    action.BackgroundTransparency = 1
    if hasObject then
        action.Position = UDim2.fromOffset(textLeft, 4)
        action.Size = UDim2.new(1, -textLeft, 0, if isTouch then 36 else 32)
    else
        action.Position = UDim2.fromOffset(textLeft, 0)
        action.Size = UDim2.new(1, -textLeft, 1, 0)
    end
    action.Font = Font.display
    action.TextScaled = true
    action.TextColor3 = Color3.new(1, 1, 1)
    action.TextXAlignment = Enum.TextXAlignment.Left
    action.TextYAlignment = Enum.TextYAlignment.Center
    action.TextTruncate = Enum.TextTruncate.AtEnd
    action.Text = prompt.ActionText
    action.ZIndex = 4
    action.Parent = root
    applyBillboardStroke(action)

    local object = Instance.new("TextLabel")
    object.Name = "Object"
    object.BackgroundTransparency = 1
    object.Position = UDim2.fromOffset(textLeft, if isTouch then 42 else 38)
    object.Size = UDim2.new(1, -textLeft, 0, if isTouch then 32 else 28)
    object.Font = Font.display
    object.TextScaled = true
    object.TextColor3 = Color3.new(1, 1, 1)
    object.TextXAlignment = Enum.TextXAlignment.Left
    object.TextYAlignment = Enum.TextYAlignment.Center
    object.TextTruncate = Enum.TextTruncate.AtEnd
    object.Text = prompt.ObjectText
    object.Visible = hasObject
    object.ZIndex = 4
    object.Parent = root
    applyBillboardStroke(object)
    applySparkGradient(object)

    local barBg = Instance.new("Frame")
    barBg.Name = "HoldBg"
    barBg.Size = UDim2.new(1, 0, 0, 4)
    barBg.Position = UDim2.new(0, 0, 1, -2)
    barBg.BackgroundColor3 = Color3.fromRGB(40, 44, 48)
    barBg.BackgroundTransparency = 0.35
    barBg.BorderSizePixel = 0
    barBg.Visible = prompt.HoldDuration > 0
    barBg.ZIndex = 4
    barBg.Parent = root
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(1, 0)
    barCorner.Parent = barBg
    local bar = Instance.new("Frame")
    bar.Name = "HoldFill"
    bar.Size = UDim2.fromScale(0, 1)
    bar.BackgroundColor3 = Color3.new(1, 1, 1)
    bar.BorderSizePixel = 0
    bar.Parent = barBg
    local barFillCorner = Instance.new("UICorner")
    barFillCorner.CornerRadius = UDim.new(1, 0)
    barFillCorner.Parent = bar
    local barSpark = Instance.new("UIGradient")
    barSpark.Name = "SparkGradient"
    barSpark.Color = SPARK_GRADIENT
    barSpark.Parent = bar

    local scale = Instance.new("UIScale")
    scale.Scale = 0.88
    scale.Parent = root
    TweenService:Create(
        scale,
        TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Scale = 1 }
    ):Play()

    if isTouch then
        table.insert(
            connections,
            key.InputBegan:Connect(function(input)
                if
                    input.UserInputType == Enum.UserInputType.Touch
                    or input.UserInputType == Enum.UserInputType.MouseButton1
                then
                    prompt:InputHoldBegin()
                end
            end)
        )
        table.insert(
            connections,
            key.InputEnded:Connect(function(input)
                if
                    input.UserInputType == Enum.UserInputType.Touch
                    or input.UserInputType == Enum.UserInputType.MouseButton1
                then
                    prompt:InputHoldEnd()
                end
            end)
        )
    end
    if prompt.HoldDuration > 0 then
        table.insert(
            connections,
            prompt.PromptButtonHoldBegan:Connect(function()
                bar.Size = UDim2.fromScale(0, 1)
                TweenService:Create(
                    bar,
                    TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear),
                    { Size = UDim2.fromScale(1, 1) }
                ):Play()
            end)
        )
        table.insert(
            connections,
            prompt.PromptButtonHoldEnded:Connect(function()
                TweenService:Create(bar, TweenInfo.new(0.1), { Size = UDim2.fromScale(0, 1) })
                    :Play()
            end)
        )
    end
    table.insert(
        connections,
        prompt:GetPropertyChangedSignal("ObjectText"):Connect(function()
            object.Text = prompt.ObjectText
            object.Visible = prompt.ObjectText ~= ""
        end)
    )
    table.insert(
        connections,
        prompt:GetPropertyChangedSignal("ActionText"):Connect(function()
            action.Text = prompt.ActionText
        end)
    )
    gui.Destroying:Connect(function()
        for _, conn in connections do
            conn:Disconnect()
        end
    end)

    local keyName = adorneeKeyOf(prompt)
    active[prompt] = { gui = gui, adorneeKey = keyName }
    reflowStack(keyName)
end

local ProximityUi = {}

function ProximityUi.start()
    if started then
        return
    end
    started = true
    ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
        if prompt.Style ~= Enum.ProximityPromptStyle.Custom then
            return
        end
        showUi(prompt, inputType)
    end)
    ProximityPromptService.PromptHidden:Connect(function(prompt)
        destroyUi(prompt)
    end)
end

return ProximityUi
