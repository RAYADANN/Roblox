--!strict
-- 3D hero preview inside an Index card (unlocked only).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local HeroScaleLogic = require(ReplicatedStorage.shared.util.HeroScaleLogic)

-- Runtime: StarterPlayerScripts.client.ui… → client.core
-- Hoarcekat: ReplicatedStorage.UI… has no sibling core — resolve via PlayerScripts.
local function requireHeroModel(): any?
    local client = script:FindFirstAncestor("client")
    if client then
        local hm = client:FindFirstChild("core") and client.core:FindFirstChild("HeroModel")
        if hm then
            return require(hm)
        end
    end
    local player = Players.LocalPlayer
    if player then
        local ps = player:FindFirstChild("PlayerScripts")
        local c = ps and ps:FindFirstChild("client")
        local hm = c and c:FindFirstChild("core") and c.core:FindFirstChild("HeroModel")
        if hm then
            return require(hm)
        end
    end
    return nil
end

local HeroModel = requireHeroModel()

export type Props = {
    heroId: string,
    rarity: string,
    mutations: { string }?,
    size: UDim2,
    position: UDim2,
    anchorPoint: Vector2,
    zIndex: number?,
}

local function IndexHeroViewport(props: Props): React.Node
    local host, setHost = React.useState(nil :: ViewportFrame?)
    local mutKey = if props.mutations and #props.mutations > 0 then props.mutations[1] else ""

    React.useEffect(function()
        if host == nil or HeroModel == nil then
            return nil
        end
        for _, child in host:GetChildren() do
            child:Destroy()
        end

        local hero = HeroModel.clone(props.heroId, nil, {
            rarity = props.rarity,
            mutations = props.mutations,
            viewportSafe = true,
            targetHeight = HeroScaleLogic.INDEX_HEIGHT,
            maxExtent = HeroScaleLogic.INDEX_MAX_EXTENT,
        })
        if hero then
            -- Slight ¾ turn so the silhouette reads better on Index cards.
            HeroModel.frameInViewport(hero, host, math.rad(28))
        end

        return function()
            for _, child in host:GetChildren() do
                child:Destroy()
            end
        end
    end, { host, props.heroId, props.rarity, mutKey } :: { unknown })

    return React.createElement("ViewportFrame", {
        Size = props.size,
        Position = props.position,
        AnchorPoint = props.anchorPoint,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LightColor = Color3.fromRGB(255, 255, 255),
        Ambient = Color3.fromRGB(200, 200, 200),
        ZIndex = props.zIndex or 1,
        ref = setHost,
    })
end

return IndexHeroViewport
