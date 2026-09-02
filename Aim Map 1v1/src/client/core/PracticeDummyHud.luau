--!strict
-- Mounts React HP billboards above practice dummies.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.shared.data.Constants)
local DummyHealthBillboard = require(script.Parent.Parent.ui.components.DummyHealthBillboard)

local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages.React)
local ReactRoblox = require(Packages.ReactRoblox)

local PracticeDummyHud = {}

type Mount = {
    gui: BillboardGui,
    root: any,
    conns: { RBXScriptConnection },
}

local mounts: { [Model]: Mount } = {}

local function unmount(model: Model)
    local mount = mounts[model]
    if not mount then
        return
    end
    for _, c in mount.conns do
        c:Disconnect()
    end
    mount.root:unmount()
    mount.gui:Destroy()
    mounts[model] = nil
end

local function render(model: Model, mount: Mount)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local health = if humanoid then humanoid.Health else 0
    local maxHealth = if humanoid then humanoid.MaxHealth else Constants.PRACTICE_DUMMY_HP
    local label = string.gsub(model.Name, "_", " ")
    mount.root:render(React.createElement(DummyHealthBillboard, {
        name = label,
        health = health,
        maxHealth = maxHealth,
    }))
end

local function mountDummy(model: Model)
    if mounts[model] then
        return
    end
    if model:GetAttribute(Constants.PRACTICE_DUMMY_ATTRIBUTE) ~= true then
        return
    end
    local adornee = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
    if not adornee or not adornee:IsA("BasePart") then
        return
    end

    local gui = Instance.new("BillboardGui")
    gui.Name = "DummyHpUi"
    gui.Size = UDim2.fromOffset(90, 42)
    gui.StudsOffset = Vector3.new(0, 3.4, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 120
    gui.Adornee = adornee
    gui.Parent = model

    local root = ReactRoblox.createRoot(gui)
    local mount: Mount = { gui = gui, root = root, conns = {} }
    mounts[model] = mount
    render(model, mount)

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid then
        table.insert(
            mount.conns,
            humanoid.HealthChanged:Connect(function()
                render(model, mount)
            end)
        )
        table.insert(
            mount.conns,
            humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
                render(model, mount)
            end)
        )
    end
    table.insert(
        mount.conns,
        model.AncestryChanged:Connect(function(_, parent)
            if parent == nil then
                unmount(model)
            end
        end)
    )
end

function PracticeDummyHud.start()
    local folder = workspace:FindFirstChild("PracticeDummies")
    local function watch(container: Instance)
        for _, child in container:GetChildren() do
            if child:IsA("Model") then
                mountDummy(child)
            end
        end
        container.ChildAdded:Connect(function(child)
            if child:IsA("Model") then
                task.defer(mountDummy, child)
            end
        end)
        container.ChildRemoved:Connect(function(child)
            if child:IsA("Model") then
                unmount(child)
            end
        end)
    end

    if folder then
        watch(folder)
    else
        workspace.ChildAdded:Connect(function(child)
            if child.Name == "PracticeDummies" then
                watch(child)
            end
        end)
    end
end

return PracticeDummyHud
