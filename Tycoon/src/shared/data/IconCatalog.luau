--!strict
-- UI / world icon textures (rbxassetid after Studio upload).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IconCatalog = {
    Robux = "rbxassetid://89993298733560",
    -- Tutorial look-at arrow (assets/GameAssets/TutorialArrow.png).
    TutorialArrow = "rbxassetid://93602234200399",
    -- Optional permanent id after publish; GameAssets/BalanceBarBg.png syncs via Rojo first.
    MoneyBarBg = "rbxassetid://73084442227357",
    MoneyButton = "rbxassetid://78591792298186",
    -- Soft currency coin (GameAssets/Icons/icon_money).
    Money = "rbxassetid://102696924587009",
    -- Soft glint strip (shared SimPop shine texture).
    Shine = "rbxassetid://139702564707796",
    -- Rebirth modal (Icons folder → Studio MCP upload).
    Rebirth = "rbxassetid://123222845152715",
    Index = "rbxassetid://71451735020065",
    Close = "rbxassetid://134613001279150",
    RewardBackground = "rbxassetid://132505336129071",
    ProgressLine = "rbxassetid://121607259775944",
    RebirthButtonBackground = "rbxassetid://82872655520639",
    SkipButtonBackground = "rbxassetid://90451518298930",
    ItemsCount = "rbxassetid://117233661470760",
    -- Index item cards (Icons → Studio MCP upload).
    ItemBackGround = "rbxassetid://113499236763653",
    SakuraIcon = "rbxassetid://112952884669703",
    -- Toast / notification banner (notification_04_subtle).
    NotificationBackground = "rbxassetid://124189080578296",
    -- Exclusive offers: spinning sunburst + pink platform pedestal.
    ExclusiveSpinBg = "rbxassetid://90341293054365",
    ExclusivePlatformPink = "rbxassetid://77131002699260",
    ExclusiveRebirthCoins = "rbxassetid://101742405995903",
}

function IconCatalog.resolveImage(catalogId: string, gameAssetName: string?): string
    if gameAssetName then
        local assets = ReplicatedStorage:FindFirstChild("GameAssets")
        local ref = assets and assets:FindFirstChild(gameAssetName)
        if ref then
            if ref:IsA("ImageLabel") or ref:IsA("ImageButton") then
                local image = ref.Image
                if image ~= "" then
                    return image
                end
            elseif ref:IsA("Decal") then
                local texture = ref.Texture
                if texture ~= "" then
                    return texture
                end
            end
        end
    end
    if catalogId ~= "" then
        return catalogId
    end
    return ""
end

return IconCatalog
