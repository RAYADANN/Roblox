--!strict

local MutationShineDatabase = require("../src/shared/data/MutationShineDatabase")

return {
    ["locked ColorSheen variants"] = function(expect)
        expect(MutationShineDatabase.get("normal").variant).toEqual(0)
        expect(MutationShineDatabase.get("secret").variant).toEqual(5)
        expect(MutationShineDatabase.get("galaxy").variant).toEqual(2)
        expect(MutationShineDatabase.get("diamond").variant).toEqual(4)
        expect(MutationShineDatabase.get("golden").variant).toEqual(5)
        expect(MutationShineDatabase.get("prismatic").legacyMutationV).toEqual(3)
    end,
}
