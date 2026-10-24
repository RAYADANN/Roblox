--!strict
-- Instance lookup for ContentRoots. Templates: ReplicatedStorage.GameAssets.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ContentRoots = require(ReplicatedStorage.shared.util.ContentRoots)

local ClientContentRoots = {}

function ClientContentRoots.resolve(name: string): Instance?
    return ContentRoots.resolve(name, function(rootName: string, childName: string): Instance?
        if rootName == ContentRoots.assetsFolderName() then
            local assets = ReplicatedStorage:FindFirstChild(rootName)
            if assets == nil then
                return nil
            end
            return assets:FindFirstChild(childName)
        end
        return ReplicatedStorage:FindFirstChild(childName)
    end)
end

return ClientContentRoots
