--!strict
-- Клиентские правила мира: полёт рэгдолла, скрытие чужих подсказок, барьер замка,
-- «!» над игроками в конусе взгляда, красный контур вора для владельца.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")

local Zap = require(script.Parent.Parent.net.NetClient)

local player = Players.LocalPlayer

local WorldController = {}

local function onRagdoll(data: { velocity: Vector3, duration: number })
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not (humanoid and root) then
        return
    end
    humanoid:ChangeState(Enum.HumanoidStateType.Physics)
    root.AssemblyLinearVelocity = data.velocity
    task.delay(data.duration, function()
        if humanoid.Parent and humanoid:GetState() == Enum.HumanoidStateType.Physics then
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)
end

-- Владелец не видит «Steal» на своих пьедесталах; чужой не видит кнопку замка.
local function filterPrompt(prompt: ProximityPrompt): boolean
    local hideFor = prompt:GetAttribute("HideForUserId")
    if hideFor == player.UserId then
        return false
    end
    if prompt:GetAttribute("OwnerOnly") then
        local plot = prompt:FindFirstAncestorWhichIsA("Model")
        while plot and plot:GetAttribute("OwnerUserId") == nil and plot.Parent do
            plot = plot.Parent:FindFirstAncestorWhichIsA("Model")
        end
        return plot ~= nil and plot:GetAttribute("OwnerUserId") == player.UserId
    end
    return true
end

local function bindPrompts()
    local function apply(prompt: ProximityPrompt)
        prompt.Enabled = filterPrompt(prompt)
    end
    ProximityPromptService.PromptShown:Connect(function(prompt)
        apply(prompt)
    end)
    -- PromptShown не приходит для выключенных, а владелец участка меняется: переоцениваем раз в 0.5 с.
    local tracked: { [ProximityPrompt]: boolean } = {}
    local function track(inst: Instance)
        if inst:IsA("ProximityPrompt") then
            tracked[inst] = true
            apply(inst)
            inst.Destroying:Connect(function()
                tracked[inst] = nil
            end)
        end
    end
    for _, inst in workspace:GetDescendants() do
        track(inst)
    end
    workspace.DescendantAdded:Connect(track)
    task.spawn(function()
        while true do
            task.wait(0.5)
            for prompt in tracked do
                apply(prompt)
            end
        end
    end)
end

-- Барьер чужого закрытого участка твёрдый только у этого клиента: персонаж симулирует клиент.
local function updateBarriers()
    for _, plots in { workspace:FindFirstChild("Level"), workspace:FindFirstChild("Greybox") } do
        local folder = plots and plots:FindFirstChild("Plots")
        if not folder then
            continue
        end
        for _, plot in folder:GetChildren() do
            local solid = plot:GetAttribute("Locked") == true
                and plot:GetAttribute("OwnerUserId") ~= player.UserId
            local barrier = plot:FindFirstChild("Barrier")
            if barrier then
                for _, part in barrier:GetDescendants() do
                    if part:IsA("BasePart") and part.CanCollide ~= solid then
                        part.CanCollide = solid
                    end
                end
            end
        end
    end
end

local function spottedGui(character: Model): TextLabel?
    local head = character:FindFirstChild("Head")
    if not head then
        return nil
    end
    local gui = head:FindFirstChild("SpottedGui") :: BillboardGui?
    if not gui then
        local newGui = Instance.new("BillboardGui")
        newGui.Name = "SpottedGui"
        newGui.Size = UDim2.fromOffset(40, 60)
        newGui.StudsOffset = Vector3.new(0, 4.5, 0)
        newGui.AlwaysOnTop = true
        local label = Instance.new("TextLabel")
        label.Name = "Mark"
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.Text = "!"
        label.Font = Enum.Font.FredokaOne
        label.TextScaled = true
        label.TextColor3 = Color3.fromHex("#FFC93C")
        label.TextStrokeTransparency = 0
        label.Parent = newGui
        newGui.Parent = head
        gui = newGui
    end
    return (gui :: BillboardGui):FindFirstChild("Mark") :: TextLabel?
end

local function updatePlayers()
    for _, other in Players:GetPlayers() do
        local character = other.Character
        if not character then
            continue
        end
        local spotted = other:GetAttribute("Spotted")
        local mark = spottedGui(character)
        if mark then
            local amount = if typeof(spotted) == "number" then spotted else 0
            mark.Visible = amount > 0
            mark.TextTransparency = 1 - math.clamp(amount, 0.25, 1)
            mark.Size = UDim2.fromScale(1, 0.4 + 0.6 * amount)
        end
        -- Вор, который несёт мой предмет, подсвечен красным только у меня (GDD 2.6).
        local thief = other ~= player and other:GetAttribute("StealingFrom") == player.UserId
        local highlight = character:FindFirstChild("ThiefHighlight") :: Highlight?
        if thief and not highlight then
            local h = Instance.new("Highlight")
            h.Name = "ThiefHighlight"
            h.FillTransparency = 1
            h.OutlineColor = Color3.fromHex("#C4281C")
            h.Parent = character
        elseif not thief and highlight then
            highlight:Destroy()
        end
    end
end

function WorldController.start()
    Zap.Ragdoll.On(onRagdoll)
    bindPrompts()
    local acc = 0
    RunService.Heartbeat:Connect(function(dt)
        acc += dt
        if acc >= 0.1 then
            acc = 0
            updateBarriers()
            updatePlayers()
        end
    end)
end

return WorldController
