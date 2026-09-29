--!strict
-- Live hero models from the place's Characters folder (server spawn + client Index).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local HeroLogic = require(ReplicatedStorage.shared.util.HeroLogic)
local Logger = require(ReplicatedStorage.shared.util.Logger)

local FOLDER_NAME = "Characters"

local WorldHeroCatalog = {}

local function catalogFolder(): Folder?
    local rs = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
    if rs and rs:IsA("Folder") then
        return rs
    end
    local ws = Workspace:FindFirstChild(FOLDER_NAME)
    if ws and ws:IsA("Folder") then
        return ws
    end
    return nil
end

-- Characters in Workspace would sit in the world as a crowd. ReplicatedStorage
-- keeps templates available to every client ViewportFrame without drawing them.
function WorldHeroCatalog.publish()
    local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
    if existing and existing:IsA("Folder") then
        return
    end
    local folder = Workspace:FindFirstChild(FOLDER_NAME)
    if folder and folder:IsA("Folder") then
        folder.Parent = ReplicatedStorage
        Logger.info("WorldHeroCatalog", `published {FOLDER_NAME} to ReplicatedStorage`)
    else
        Logger.warn("WorldHeroCatalog", `missing {FOLDER_NAME} folder`)
    end
end

function WorldHeroCatalog.templateForTier(tier: number): Model?
    local folder = catalogFolder()
    if folder == nil then
        return nil
    end
    local name = HeroLogic.modelNameForTier(tier)
    local inst = folder:FindFirstChild(name)
    if inst and inst:IsA("Model") then
        return inst
    end
    Logger.warn("WorldHeroCatalog", `missing hero model "{name}" for tier {tier}`)
    return nil
end

function WorldHeroCatalog.ensureStandPart(model: Model): BasePart?
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:IsA("BasePart") then
        model.PrimaryPart = hrp
        return hrp
    end
    local torso = model:FindFirstChild("Torso")
    if torso and torso:IsA("BasePart") then
        model.PrimaryPart = torso
        return torso
    end
    local upper = model:FindFirstChild("UpperTorso")
    if upper and upper:IsA("BasePart") then
        model.PrimaryPart = upper
        return upper
    end
    for _, inst in model:GetDescendants() do
        if inst:IsA("BasePart") then
            model.PrimaryPart = inst
            return inst
        end
    end
    return nil
end

return WorldHeroCatalog
