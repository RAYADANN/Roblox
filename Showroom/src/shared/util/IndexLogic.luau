--!strict
-- Pure Index: eggs → base pets → owned evolutions.

local EggDatabase
local PetIndexDatabase
if script and script.Parent then
    EggDatabase = require(script.Parent.Parent.data.EggDatabase)
    PetIndexDatabase = require(script.Parent.Parent.data.PetIndexDatabase)
else
    EggDatabase = require("../data/EggDatabase")
    PetIndexDatabase = require("../data/PetIndexDatabase")
end

export type EggTab = {
    id: string,
    name: string,
    iconKey: string,
    selected: boolean,
}

export type PetCard = {
    id: string,
    name: string,
    modelName: string,
    unlocked: boolean,
    ownedCount: number,
    cardBgKey: string,
}

export type EvolutionCard = {
    id: string,
    name: string,
    modelName: string,
    unlocked: boolean,
}

-- ownedEvolutionIds: set of evolution id → true (any truthy).
export type OwnedMap = { [string]: boolean }?

local IndexLogic = {}

function IndexLogic.columnCount(): number
    return 4
end

function IndexLogic.eggTabs(selectedEggId: string?): { EggTab }
    local selected = selectedEggId or EggDatabase.defaultId()
    local tabs: { EggTab } = table.create(#EggDatabase.ORDER)
    for i, egg in EggDatabase.ORDER do
        tabs[i] = {
            id = egg.id,
            name = egg.name,
            iconKey = egg.iconKey,
            selected = egg.id == selected,
        }
    end
    return tabs
end

local function ownedCountForPet(petId: string, owned: OwnedMap): number
    local pet = PetIndexDatabase.get(petId)
    if pet == nil then
        return 0
    end
    local count = 0
    for _, evo in pet.evolutions do
        if owned and owned[evo.id] then
            count += 1
        end
    end
    return count
end

function IndexLogic.baseCards(eggId: string?, owned: OwnedMap): { PetCard }
    local egg = EggDatabase.get(eggId or EggDatabase.defaultId())
    local cardBgKey = if egg then egg.cardBgKey else "CardStandart"
    local pets = PetIndexDatabase.forEgg(eggId or EggDatabase.defaultId())
    local cards: { PetCard } = table.create(#pets)
    for i, pet in pets do
        local count = ownedCountForPet(pet.id, owned)
        cards[i] = {
            id = pet.id,
            name = pet.name,
            modelName = pet.modelName,
            unlocked = count > 0,
            ownedCount = count,
            cardBgKey = cardBgKey,
        }
    end
    return cards
end

function IndexLogic.evolutionCards(petId: string, owned: OwnedMap): { EvolutionCard }
    local pet = PetIndexDatabase.get(petId)
    if pet == nil then
        return {}
    end
    local cards: { EvolutionCard } = table.create(#pet.evolutions)
    for i, evo in pet.evolutions do
        local unlocked = owned ~= nil and owned[evo.id] == true
        cards[i] = {
            id = evo.id,
            name = evo.name,
            modelName = evo.modelName,
            unlocked = unlocked,
        }
    end
    return cards
end

function IndexLogic.petName(petId: string): string
    local pet = PetIndexDatabase.get(petId)
    return if pet then pet.name else petId
end

return IndexLogic
