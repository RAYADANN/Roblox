--!strict
-- Where shared templates live. Player plots stay in Workspace.
-- Templates (models, BillboardGui) live in ReplicatedStorage.GameAssets.

local ASSETS = "GameAssets"
local REPLICATED = "ReplicatedStorage"

local ContentRoots = {}

function ContentRoots.assetsFolderName(): string
    return ASSETS
end

--- Prefer GameAssets/<name>, then a direct child of ReplicatedStorage.
function ContentRoots.resolve<T>(name: string, find: (string, string) -> T?): T?
    local fromAssets = find(ASSETS, name)
    if fromAssets ~= nil then
        return fromAssets
    end
    return find(REPLICATED, name)
end

return ContentRoots
