--!strict
-- Находит объекты сцены по контракту (STATUS.md «Контракт сцены»).
-- Чего нет у моделлера — строит серой заглушкой в Workspace.Greybox (только рантайм).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CarryLogic = require(ReplicatedStorage.shared.util.CarryLogic)
local HoardConfig = require(ReplicatedStorage.shared.data.HoardConfig)
local ItemsConfig = require(ReplicatedStorage.shared.data.ItemsConfig)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local Rarity = require(ReplicatedStorage.shared.data.Rarity)

local greybox = script.Parent.Parent.greybox
local Build = require(greybox.Build)
local GreyboxGiant = require(greybox.GreyboxGiant)
local GreyboxItems = require(greybox.GreyboxItems)
local GreyboxMap = require(greybox.GreyboxMap)
local GreyboxPlots = require(greybox.GreyboxPlots)

export type Scene = {
    giant: Model,
    plots: { Model },
    coverParts: { BasePart },
    roots: { Instance },
    fxFolder: Folder,
    itemsFolder: Folder,
    itemTemplate: (itemId: string) -> Model,
}

local Scene = {}

local function checkConfigs()
    local seen: { [string]: boolean } = {}
    for _, def in ItemsConfig.LIST do
        for _, ring in def.rings do
            seen[`{ring}:{def.rarity}`] = true
        end
    end
    for ringName, ring in HoardConfig.RINGS do
        local sum = CarryLogic.chancesSum(ring.chances)
        if math.abs(sum - 100) > 1e-6 then
            Logger.error(
                "Scene",
                `HoardConfig.{ringName}: шансы дают {sum}%, нужно 100%`
            )
        end
        for rarity in ring.chances do
            if not (Rarity.DEFS :: any)[rarity] then
                Logger.error(
                    "Scene",
                    `HoardConfig.{ringName}: неизвестная редкость {rarity}`
                )
            elseif not seen[`{ringName}:{rarity}`] then
                Logger.error(
                    "Scene",
                    `HoardConfig.{ringName}: нет предметов редкости {rarity} для этого кольца`
                )
            end
        end
    end
end

function Scene.resolve(): Scene
    checkConfigs()

    local root = Build.folder(workspace, "Greybox")
    local level = workspace:FindFirstChild("Level")

    if not level then
        Logger.info("Scene", "Workspace.Level нет — строю серую карту")
        GreyboxMap.build(root)
    end

    local giant = workspace:FindFirstChild("Giant") :: Model?
    if not giant then
        Logger.info("Scene", "Workspace.Giant нет — строю серого великана")
        giant = GreyboxGiant.build(root)
    end

    local plotsFolder = level and level:FindFirstChild("Plots")
    if not plotsFolder then
        plotsFolder = GreyboxPlots.build(root)
    end
    local plots: { Model } = {}
    for _, child in (plotsFolder :: Instance):GetChildren() do
        local index = tonumber(string.match(child.Name, "^Plot(%d+)$"))
        if index and child:IsA("Model") then
            plots[index] = child
        end
    end

    local hasGroundSpawns = false
    for _, marker in CollectionService:GetTagged("HoardSpawn") do
        local ring = marker:GetAttribute("Ring")
        if ring == "Outer" or ring == "Middle" then
            hasGroundSpawns = true
            break
        end
    end
    if not hasGroundSpawns then
        GreyboxMap.buildSpawns(root, HoardConfig.RINGS :: any)
    end

    -- Только живая сцена: варианты карт (MapVariant_*) и превью великана не участвуют.
    local roots: { Instance } = { root, giant :: Model }
    if level then
        table.insert(roots, level)
    end
    local coverParts: { BasePart } = {}
    for _, sceneRoot in roots do
        for _, inst in sceneRoot:GetDescendants() do
            if inst:IsA("BasePart") and inst:GetAttribute("Cover") == true then
                table.insert(coverParts, inst)
            end
        end
    end

    local assets = ReplicatedStorage:FindFirstChild("Assets")
    local assetItems = assets and assets:FindFirstChild("Items")
    local missing: { string } = {}
    for _, def in ItemsConfig.LIST do
        if not (assetItems and assetItems:FindFirstChild(def.id)) then
            table.insert(missing, def.id)
        end
    end
    if #missing > 0 then
        Logger.info(
            "Scene",
            `нет моделей в Assets.Items для {#missing} предметов — использую кубики`
        )
    end

    local function itemTemplate(itemId: string): Model
        local found = assetItems and assetItems:FindFirstChild(itemId)
        if found and found:IsA("Model") and found.PrimaryPart then
            return found:Clone()
        end
        return GreyboxItems.make(ItemsConfig.BY_ID[itemId])
    end

    return {
        giant = giant :: Model,
        plots = plots,
        coverParts = coverParts,
        roots = roots,
        fxFolder = Build.folder(workspace, "Fx"),
        itemsFolder = Build.folder(workspace, "Items"),
        itemTemplate = itemTemplate,
    }
end

return Scene
