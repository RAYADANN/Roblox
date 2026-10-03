--!strict
-- Game content templates (boxes / heroes / stands / FX) live under ReplicatedStorage.
-- Workspace.Base* is player plots only — never put shared templates there.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ContentRoots = {}

local ASSETS = "GameAssets"

local function assetsFolder(): Folder?
    local f = ReplicatedStorage:FindFirstChild(ASSETS)
    if f and f:IsA("Folder") then
        return f
    end
    return nil
end

local function findIn(roots: { Instance? }, name: string): Instance?
    for _, root in roots do
        if root then
            local hit = root:FindFirstChild(name)
            if hit then
                return hit
            end
        end
    end
    return nil
end

--- Prefer GameAssets/<name>, then RS root, then Workspace (legacy).
local function resolve(name: string, legacyWsNames: { string }?): Instance?
    local assets = assetsFolder()
    local hit = findIn({ assets, ReplicatedStorage }, name)
    if hit then
        return hit
    end
    -- Legacy aliases (pre-migration names still accepted).
    local aliases: { [string]: { string } } = {
        Heroes = { "HeroTemplates" },
        HeroTemplates = { "Heroes" },
        MutationFx = { "MutationFxTemplates", "BoxMutationEffect" },
        MutationFxTemplates = { "MutationFx", "BoxMutationEffect" },
        Stands = { "BrainrotsTemplate" },
        BrainrotsTemplate = { "Stands" },
    }
    local alt = aliases[name]
    if alt then
        for _, a in alt do
            hit = findIn({ assets, ReplicatedStorage }, a)
            if hit then
                return hit
            end
        end
    end
    if legacyWsNames then
        for _, wsName in legacyWsNames do
            local ws = Workspace:FindFirstChild(wsName)
            if ws then
                return ws
            end
        end
    end
    return nil
end

function ContentRoots.assets(): Folder?
    return assetsFolder()
end

function ContentRoots.boxes(): Instance?
    return resolve("Boxes", { "Boxes" })
end

function ContentRoots.heroes(): Instance?
    return resolve("Heroes", { "Heroes", "Герои" })
        or resolve("HeroTemplates", { "Heroes", "Герои" })
end

function ContentRoots.mutationFx(): Instance?
    return resolve("MutationFx", { "BoxMutationEffect" })
        or resolve("MutationFxTemplates", { "BoxMutationEffect" })
end

function ContentRoots.mutations(): Instance?
    return resolve("Mutations", { "Mutations" })
end

function ContentRoots.rarity(): Instance?
    return resolve("Rarity", { "Rarity" })
end

function ContentRoots.stands(): Instance?
    return resolve("Stands", nil) or resolve("BrainrotsTemplate", nil)
end

function ContentRoots.boxHeroStand(): Model?
    local stands = ContentRoots.stands()
    if stands then
        local hs = stands:FindFirstChild("BoxHeroStand")
        if hs and hs:IsA("Model") then
            return hs
        end
        local deep = stands:FindFirstChild("BoxHeroStand", true)
        if deep and deep:IsA("Model") then
            return deep
        end
    end
    local ws = Workspace:FindFirstChild("BoxHeroStand")
    if ws and ws:IsA("Model") then
        return ws
    end
    return nil
end

function ContentRoots.secret(): Model?
    local heroes = ContentRoots.heroes()
    if heroes then
        local s = heroes:FindFirstChild("Secret", true)
        if s and s:IsA("Model") then
            return s
        end
    end
    local stands = ContentRoots.stands()
    if stands then
        local s = stands:FindFirstChild("Secret", true)
        if s and s:IsA("Model") then
            return s
        end
    end
    local ws = Workspace:FindFirstChild("Secret")
    if ws and ws:IsA("Model") then
        return ws
    end
    return nil
end

--- Palette / shape box model under Boxes/1|2|3 or Boxes direct child.
function ContentRoots.findBoxModel(boxModelName: string): Model?
    if boxModelName == "" then
        return nil
    end
    local boxes = ContentRoots.boxes()
    if boxes then
        for _, shape in { "1", "2", "3" } do
            local folder = boxes:FindFirstChild(shape)
            local hit = folder and folder:FindFirstChild(boxModelName)
            if hit and hit:IsA("Model") then
                return hit
            end
        end
        local direct = boxes:FindFirstChild(boxModelName)
        if direct and direct:IsA("Model") then
            return direct
        end
    end
    return nil
end

--- BillboardGui template (Boxes.Box1 preferred).
function ContentRoots.boxBillboardTemplate(): BillboardGui?
    local boxes = ContentRoots.boxes()
    if not boxes then
        return nil
    end
    local box1 = boxes:FindFirstChild("Box1")
    if box1 then
        local bb = box1:FindFirstChildWhichIsA("BillboardGui", true)
        if bb and bb:IsA("BillboardGui") then
            return bb
        end
    end
    for _, child in boxes:GetChildren() do
        local bb = child:FindFirstChildWhichIsA("BillboardGui", true)
        if bb and bb:IsA("BillboardGui") then
            return bb
        end
        if child:IsA("Folder") then
            for _, nested in child:GetChildren() do
                local nestedBb = nested:FindFirstChildWhichIsA("BillboardGui", true)
                if nestedBb and nestedBb:IsA("BillboardGui") then
                    return nestedBb
                end
            end
        end
    end
    return nil
end

--- First Highlight found under Boxes (legacy Box2 template).
function ContentRoots.boxHighlightTemplate(): Highlight?
    local boxes = ContentRoots.boxes()
    if not boxes then
        return nil
    end
    for _, d in boxes:GetDescendants() do
        if d:IsA("Highlight") then
            return d
        end
    end
    return nil
end

--- Roll-land Attachment with ParticleEmitters under Boxes.
function ContentRoots.boxRollLandAttachment(): Attachment?
    local boxes = ContentRoots.boxes()
    if not boxes then
        return nil
    end
    for _, d in boxes:GetDescendants() do
        if d:IsA("Attachment") and d.Name == "Attachment" then
            for _, c in d:GetDescendants() do
                if c:IsA("ParticleEmitter") then
                    return d
                end
            end
        end
    end
    return nil
end

return ContentRoots
