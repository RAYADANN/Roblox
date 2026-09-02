--!strict
-- Pure helpers for client ContentProvider preload lists (CI-safe).

local AssetPreloadLogic = {}

function AssetPreloadLogic.isLoadableId(id: string): boolean
    if id == "" or id == "rbxassetid://0" then
        return false
    end
    return string.sub(id, 1, 13) == "rbxassetid://" or string.sub(id, 1, 11) == "rbxasset://"
end

--- Dedupe while preserving first-seen order.
function AssetPreloadLogic.uniqueOrdered(ids: { string }): { string }
    local seen: { [string]: boolean } = {}
    local out: { string } = {}
    for _, id in ids do
        if AssetPreloadLogic.isLoadableId(id) and not seen[id] then
            seen[id] = true
            table.insert(out, id)
        end
    end
    return out
end

function AssetPreloadLogic.collectFromMap(map: { [string]: string }): { string }
    local ids: { string } = {}
    for _, id in map do
        table.insert(ids, id)
    end
    return AssetPreloadLogic.uniqueOrdered(ids)
end

return AssetPreloadLogic
