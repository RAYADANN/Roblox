--!strict
-- Local gating for Take SellBox / Sell at SellGuy from HUD sync.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseLayout = require(ReplicatedStorage.shared.util.BaseLayout)
local SellBoxVisual = require(script.Parent.SellBoxVisual)

local SellBoxPromptBinder = {}

local function findPrompt(kind: string): ProximityPrompt?
    local base = BaseLayout.getLocal() or BaseLayout.getPrimary()
    if not base then
        return nil
    end
    for _, d in base:GetDescendants() do
        if d:IsA("ProximityPrompt") and d:GetAttribute("PromptKind") == kind then
            return d
        end
    end
    return nil
end

local function crateCount(sellCratesJson: string): number
    if sellCratesJson == "" then
        return 0
    end
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(sellCratesJson)
    end)
    if ok and typeof(decoded) == "table" then
        return #decoded
    end
    return 0
end

function SellBoxPromptBinder.applyHud(
    sellBoxCoins: number,
    sellBoxDeposits: number,
    sellCratesJson: string
)
    SellBoxVisual.setDeposits(sellBoxDeposits)

    local take = findPrompt("take_sellbox")
    if take then
        local canTake = sellBoxCoins > 0
        take.Enabled = canTake
        take.MaxActivationDistance = if canTake then 12 else 0
    end

    local sell = findPrompt("sell_crates")
    if sell then
        local canSell = crateCount(sellCratesJson) > 0
        sell.Enabled = canSell
        sell.MaxActivationDistance = if canSell then 14 else 0
    end
end

return SellBoxPromptBinder
