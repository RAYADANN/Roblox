--!strict
-- Stand-on-pad input. One press per step-on; re-arms only after a stable leave.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.shared.data.Constants)
local FarmManager = require(script.Parent.FarmManager)
local PadIds = require(ReplicatedStorage.shared.data.PadIds)
local PadVisuals = require(script.Parent.PadVisuals)
local PlotRegistry = require(script.Parent.PlotRegistry)
local WorldFarmFactory = require(script.Parent.WorldFarmFactory)

export type Deps = {
    farmManager: FarmManager.FarmManager,
    plotRegistry: PlotRegistry.PlotRegistry,
}

local PadBinder = {}

-- Plot teleport / first sample: treat current pads as already-occupied, not a press.
local WARP_STUDS = 25

local function horizontalDistance(a: Vector3, b: Vector3): number
    local dx = a.X - b.X
    local dz = a.Z - b.Z
    return math.sqrt(dx * dx + dz * dz)
end

function PadBinder.start(deps: Deps)
    -- Consumed after press; cleared only after player left for PAD_REENTRY_SEC.
    local consumed: { [Player]: { [string]: boolean } } = {}
    -- Timestamp when leave began (set once, not every poll).
    local leftAt: { [Player]: { [string]: number } } = {}
    local busy: { [Player]: { [string]: boolean } } = {}
    local lastPos: { [Player]: Vector3 } = {}

    local function forget(player: Player)
        consumed[player] = nil
        leftAt[player] = nil
        busy[player] = nil
        lastPos[player] = nil
    end

    local function hookPlayer(player: Player)
        player.CharacterAdded:Connect(function()
            forget(player)
        end)
    end
    for _, player in Players:GetPlayers() do
        hookPlayer(player)
    end
    Players.PlayerAdded:Connect(hookPlayer)
    Players.PlayerRemoving:Connect(forget)

    task.spawn(function()
        while true do
            task.wait(0.08)
            local now = os.clock()
            for _, player in Players:GetPlayers() do
                local plot = deps.plotRegistry:get(player)
                if plot == nil then
                    continue
                end
                local character = player.Character
                local root = character and character:FindFirstChild("HumanoidRootPart")
                if root == nil or not root:IsA("BasePart") then
                    continue
                end

                local pads = WorldFarmFactory.padModels(plot.island)
                local used = consumed[player]
                if used == nil then
                    used = {}
                    consumed[player] = used
                end
                local leftBucket = leftAt[player]
                if leftBucket == nil then
                    leftBucket = {}
                    leftAt[player] = leftBucket
                end
                local busyBucket = busy[player]
                if busyBucket == nil then
                    busyBucket = {}
                    busy[player] = busyBucket
                end

                local pos = root.Position
                local prev = lastPos[player]
                lastPos[player] = pos
                local warped = prev == nil or (pos - prev).Magnitude > WARP_STUDS

                for _, def in PadIds do
                    local model = pads[def.action]
                    if model == nil then
                        continue
                    end
                    local part = WorldFarmFactory.findPadPart(model)
                    if part == nil then
                        continue
                    end

                    local inside = horizontalDistance(root.Position, part.Position)
                            <= Constants.PAD_STAND_RADIUS
                        and math.abs(root.Position.Y - part.Position.Y) <= 12

                    if not inside then
                        if used[def.action] or busyBucket[def.action] then
                            if leftBucket[def.action] == nil then
                                leftBucket[def.action] = now
                            elseif now - leftBucket[def.action] >= Constants.PAD_REENTRY_SEC then
                                used[def.action] = nil
                                leftBucket[def.action] = nil
                                busyBucket[def.action] = nil
                            end
                        else
                            leftBucket[def.action] = nil
                        end
                        continue
                    end

                    -- Standing on pad again: cancel leave timer.
                    leftBucket[def.action] = nil

                    if warped then
                        used[def.action] = true
                        continue
                    end

                    if used[def.action] then
                        continue
                    end
                    if busyBucket[def.action] or PadVisuals.isPressing(model) then
                        continue
                    end
                    if not deps.farmManager:canActivatePad(player, def.action) then
                        continue
                    end

                    used[def.action] = true
                    busyBucket[def.action] = true
                    PadVisuals.playPress(model, function()
                        local b = busy[player]
                        if b then
                            b[def.action] = nil
                        end
                    end)
                    deps.farmManager:handlePad(player, def.action)
                end
            end
        end
    end)
end

return PadBinder
