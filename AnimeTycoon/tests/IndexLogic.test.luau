return {
    ["findKey normal vs mutation"] = function(expect)
        local IndexLogic = require("../src/shared/util/IndexLogic")
        expect(IndexLogic.findKey("Pipi_Kiwi")).toEqual("Pipi_Kiwi")
        expect(IndexLogic.findKey("Pipi_Kiwi", "golden")).toEqual("Pipi_Kiwi:golden")
        expect(IndexLogic.findKey("")).toEqual("")
    end,
    ["addFound is idempotent"] = function(expect)
        local IndexLogic = require("../src/shared/util/IndexLogic")
        local found = {}
        expect(IndexLogic.addFound(found, "Pipi_Kiwi", nil)).toEqual(true)
        expect(IndexLogic.addFound(found, "Pipi_Kiwi", nil)).toEqual(false)
        expect(IndexLogic.addFound(found, "Pipi_Kiwi", "golden")).toEqual(true)
        expect(#found).toEqual(2)
    end,
    ["buildEntries covers all heroes × tiers"] = function(expect)
        local IndexLogic = require("../src/shared/util/IndexLogic")
        local HeroCatalog = require("../src/shared/data/HeroCatalog")
        local RarityDatabase = require("../src/shared/data/RarityDatabase")
        local MutationDatabase = require("../src/shared/data/MutationDatabase")

        local heroCount = 0
        for _, rarity in RarityDatabase.ordered() do
            heroCount += #HeroCatalog.pool(rarity)
        end
        local tierCount = 1 + #MutationDatabase.indexIds()
        local entries = IndexLogic.buildEntries({ "Pipi_Kiwi", "Pipi_Kiwi:golden" })
        expect(#entries).toEqual(heroCount * tierCount)
        expect(table.find(IndexLogic.tierOrder(), "prismatic")).toEqual(nil)

        local unlocked = 0
        local pipi: any = nil
        for _, e in entries do
            if e.unlocked then
                unlocked += 1
            end
            if e.id == "Pipi_Kiwi" then
                pipi = e
            end
        end
        expect(unlocked).toEqual(2)
        expect(pipi ~= nil).toBeTruthy()
        expect(pipi.name).toEqual("Pipi Kiwi")
        expect(pipi.tier).toEqual("normal")
        expect(pipi.unlocked).toEqual(true)
        expect(pipi.incomePerMini > 0).toBeTruthy()
    end,
    ["backfillFromOwned marks unpacked only"] = function(expect)
        local IndexLogic = require("../src/shared/util/IndexLogic")
        local found = {}
        local n = IndexLogic.backfillFromOwned(found, {
            { unpacked = true, heroId = "Pipi_Kiwi", mutations = { "golden" } },
            { unpacked = false, heroId = "Sigma Boy", mutations = {} },
            nil,
        }, {
            { unpacked = true, heroId = "Tim Cheese", mutations = {} },
        })
        expect(n).toEqual(2)
        expect(table.find(found, "Pipi_Kiwi:golden") ~= nil).toBeTruthy()
        expect(table.find(found, "Tim Cheese") ~= nil).toBeTruthy()
        expect(table.find(found, "Sigma Boy") == nil).toBeTruthy()
    end,
}
