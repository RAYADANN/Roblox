return {
    ["displayName replaces underscores"] = function(expect)
        local HeroCatalog = require("../src/shared/data/HeroCatalog")
        expect(HeroCatalog.displayName("Pipi_Kiwi")).toEqual("Pipi Kiwi")
        expect(HeroCatalog.displayName("La_Vacca_Saturno_Saturnita")).toEqual(
            "La Vacca Saturno Saturnita"
        )
        expect(HeroCatalog.displayName("Garama_and_Madundung")).toEqual("Garama and Madundung")
    end,
    ["displayName strips Brainrot"] = function(expect)
        local HeroCatalog = require("../src/shared/data/HeroCatalog")
        expect(HeroCatalog.displayName("Brainrot God Lucky Block")).toEqual("God Lucky Block")
    end,
    ["displayName keeps clean names"] = function(expect)
        local HeroCatalog = require("../src/shared/data/HeroCatalog")
        expect(HeroCatalog.displayName("Bombardiro Crocodilo")).toEqual("Bombardiro Crocodilo")
        expect(HeroCatalog.displayName("")).toEqual("")
    end,
}
