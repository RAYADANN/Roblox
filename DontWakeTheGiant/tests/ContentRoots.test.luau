--!strict
local ContentRoots = require("../src/shared/util/ContentRoots")

return {
    ["resolve: GameAssets wins over a legacy root child"] = function(expect)
        local tree = {
            GameAssets = { Boxes = "asset-boxes" },
            ReplicatedStorage = { Boxes = "legacy-boxes" },
        }
        local hit = ContentRoots.resolve(
            "Boxes",
            function(rootName: string, childName: string): string?
                local folder = tree[rootName]
                if folder == nil then
                    return nil
                end
                return folder[childName]
            end
        )
        expect(hit).toEqual("asset-boxes")
    end,
    ["resolve: falls back to ReplicatedStorage"] = function(expect)
        local tree = {
            ReplicatedStorage = { Heroes = "legacy-heroes" },
        }
        local hit = ContentRoots.resolve(
            "Heroes",
            function(rootName: string, childName: string): string?
                local folder = tree[rootName]
                if folder == nil then
                    return nil
                end
                return folder[childName]
            end
        )
        expect(hit).toEqual("legacy-heroes")
    end,
    ["resolve: missing name"] = function(expect)
        local hit = ContentRoots.resolve("Missing", function(): string?
            return nil
        end)
        expect(hit).toEqual(nil)
    end,
}
