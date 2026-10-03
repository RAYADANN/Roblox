--!strict
-- Ensure ReplicatedStorage.GameAssets has heroes / mutation FX (Workspace streams away).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ASSETS = "GameAssets"
local HEROES = "Heroes"
local MUTATION_FX = "MutationFx"

local HeroTemplateSync = {}

local function ensureAssets(): Folder
    local f = ReplicatedStorage:FindFirstChild(ASSETS)
    if f and f:IsA("Folder") then
        return f
    end
    local created = Instance.new("Folder")
    created.Name = ASSETS
    created.Parent = ReplicatedStorage
    return created
end

local function countModels(root: Instance): number
    local n = 0
    for _, tier in root:GetChildren() do
        if tier:IsA("Folder") then
            for _, child in tier:GetChildren() do
                if child:IsA("Model") then
                    n += 1
                end
            end
        elseif tier:IsA("Model") then
            n += 1
        end
    end
    return n
end

local function stripScripts(root: Instance)
    for _, d in root:GetDescendants() do
        if d:IsA("Script") or d:IsA("LocalScript") then
            d:Destroy()
        end
    end
end

local function findWorkspaceHeroes(): Instance?
    for _, name in { "Heroes", "Герои" } do
        local root = Workspace:FindFirstChild(name)
        if root then
            return root
        end
    end
    return nil
end

local function relocateLegacyFlat(assets: Folder, flatName: string, destName: string)
    local flat = ReplicatedStorage:FindFirstChild(flatName)
    if flat and flat.Parent == ReplicatedStorage then
        local existing = assets:FindFirstChild(destName)
        if existing then
            flat:Destroy()
            return
        end
        flat.Name = destName
        flat.Parent = assets
        stripScripts(flat)
    end
end

function HeroTemplateSync.ensure()
    local assets = ensureAssets()

    -- Migrate old flat RS roots into GameAssets if still present.
    relocateLegacyFlat(assets, "HeroTemplates", HEROES)
    relocateLegacyFlat(assets, "MutationFxTemplates", MUTATION_FX)
    relocateLegacyFlat(assets, "BrainrotsTemplate", "Stands")
    relocateLegacyFlat(assets, "Boxes", "Boxes")

    local rsHeroes = assets:FindFirstChild(HEROES)
    local wsHeroes = findWorkspaceHeroes()
    local needHeroCopy = true
    if rsHeroes then
        local rsCount = countModels(rsHeroes)
        local wsCount = if wsHeroes then countModels(wsHeroes) else 0
        if rsCount >= 50 or (wsCount > 0 and rsCount >= wsCount) then
            needHeroCopy = false
        end
    end
    if needHeroCopy and wsHeroes and countModels(wsHeroes) > 0 then
        if rsHeroes then
            rsHeroes:Destroy()
        end
        local copy = wsHeroes:Clone()
        copy.Name = HEROES
        stripScripts(copy)
        copy.Parent = assets
        wsHeroes:Destroy()
    end

    local rsFx = assets:FindFirstChild(MUTATION_FX)
    local wsFx = Workspace:FindFirstChild("BoxMutationEffect")
    if (not rsFx or #rsFx:GetChildren() == 0) and wsFx then
        if rsFx then
            rsFx:Destroy()
        end
        local copy = wsFx:Clone()
        copy.Name = MUTATION_FX
        stripScripts(copy)
        copy.Parent = assets
        wsFx:Destroy()
    elseif wsFx and rsFx and #rsFx:GetChildren() > 0 then
        wsFx:Destroy()
    end

    -- Pull leftover Workspace.Boxes / Mutations / Rarity if any.
    for _, pair in
        {
            { "Boxes", "Boxes" },
            { "Mutations", "Mutations" },
            { "Rarity", "Rarity" },
        }
    do
        local wsName, destName = pair[1], pair[2]
        local ws = Workspace:FindFirstChild(wsName)
        if ws and not assets:FindFirstChild(destName) then
            ws.Name = destName
            ws.Parent = assets
            stripScripts(ws)
        elseif ws and assets:FindFirstChild(destName) then
            ws:Destroy()
        end
    end
end

return HeroTemplateSync
