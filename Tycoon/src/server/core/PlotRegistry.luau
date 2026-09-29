--!strict
-- Discovers IslandMain / Island plots that have DummyItems.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Logger = require(game:GetService("ReplicatedStorage").shared.util.Logger)

export type Plot = {
    id: number,
    island: Folder,
}

local PlotRegistry = {}
PlotRegistry.__index = PlotRegistry

export type PlotRegistry = typeof(setmetatable(
    {} :: {
        _plots: { Plot },
        _byPlayer: { [Player]: Plot },
        _owner: { [number]: Player },
    },
    PlotRegistry
))

local function findMainButton(island: Folder): Model?
    local buttons = island:FindFirstChild("Buttons")
    if buttons then
        local underButtons = buttons:FindFirstChild("MainButton")
        if underButtons and underButtons:IsA("Model") then
            return underButtons
        end
    end
    local main = island:FindFirstChild("MainButton")
    if main and main:IsA("Model") then
        return main
    end
    return nil
end

local function islandPosition(island: Folder): Vector3
    local stand = island:FindFirstChild("Stand")
    if stand and stand:IsA("Model") then
        return stand:GetPivot().Position
    end
    local main = findMainButton(island)
    if main then
        return main:GetPivot().Position
    end
    return Vector3.zero
end

local function isPlotIsland(inst: Instance): boolean
    if not inst:IsA("Folder") then
        return false
    end
    if inst.Name ~= "Island" and inst.Name ~= "IslandMain" then
        return false
    end
    local dummyItems = inst:FindFirstChild("DummyItems")
    return dummyItems ~= nil and dummyItems:IsA("Folder") and #dummyItems:GetChildren() > 0
end

function PlotRegistry.new(): PlotRegistry
    local islands: { Folder } = {}
    for _, child in Workspace:GetChildren() do
        if isPlotIsland(child) then
            table.insert(islands, child)
        end
    end
    table.sort(islands, function(a, b)
        if a.Name == "IslandMain" then
            return true
        end
        if b.Name == "IslandMain" then
            return false
        end
        local pa = islandPosition(a)
        local pb = islandPosition(b)
        if pa.X == pb.X then
            return pa.Z < pb.Z
        end
        return pa.X < pb.X
    end)

    local plots: { Plot } = {}
    for i, island in islands do
        island:SetAttribute("PlotId", i)
        table.insert(plots, { id = i, island = island })
    end

    Logger.info("PlotRegistry", `plots={#plots}`)

    return setmetatable({
        _plots = plots,
        _byPlayer = {},
        _owner = {},
    }, PlotRegistry)
end

function PlotRegistry:get(player: Player): Plot?
    return self._byPlayer[player]
end

function PlotRegistry:assign(player: Player): Plot?
    local existing = self._byPlayer[player]
    if existing then
        return existing
    end
    for _, plot in self._plots do
        if self._owner[plot.id] == nil then
            self._owner[plot.id] = player
            self._byPlayer[player] = plot
            return plot
        end
    end
    Logger.warn("PlotRegistry", `no free plot for {player.Name}`)
    return nil
end

function PlotRegistry:release(player: Player)
    local plot = self._byPlayer[player]
    if plot then
        self._owner[plot.id] = nil
        self._byPlayer[player] = nil
    end
end

function PlotRegistry:teleport(player: Player, plot: Plot)
    local character = player.Character or player.CharacterAdded:Wait()
    local root = character:FindFirstChild("HumanoidRootPart")
    if root == nil or not root:IsA("BasePart") then
        return
    end
    local main = findMainButton(plot.island)
    local cf = if main then main:GetPivot() else CFrame.new(0, 8, 0)
    root.CFrame = cf * CFrame.new(0, 8, 12)
end

function PlotRegistry:ownerOf(plotId: number): Player?
    return self._owner[plotId]
end

function PlotRegistry:start()
    Players.PlayerRemoving:Connect(function(player)
        self:release(player)
    end)
end

return PlotRegistry
