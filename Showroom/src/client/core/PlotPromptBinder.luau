--!strict
-- Handles server-installed ProximityPrompts. Also listens to HUD sync early (no race).

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local EggModel = require(script.Parent.EggModel)
local ExhibitLogic = require(ReplicatedStorage.shared.util.ExhibitLogic)
local MutationFx = require(script.Parent.MutationFx)
local MutationLogic = require(ReplicatedStorage.shared.util.MutationLogic)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local Notification = require(script.Parent.Notification)
local OfferRoulette = require(script.Parent.OfferRoulette)
local SoundManager = require(script.Parent.SoundManager)
local WorldUi = require(script.Parent.Parent.ui.world.WorldUi)
local Zap = require(script.Parent.Parent.net.NetClient)

type HudSyncPayload = NetTypes.HudSyncPayload
type SpinOffer = OfferRoulette.SpinOffer

local PlotPromptBinder = {}

local localPlayer = Players.LocalPlayer
local _hud: HudSyncPayload = {
    coins = 0,
    plotId = 0,
    favoriteBank = 0,
    offers = {},
    slots = {},
    inventory = {},
    handUid = nil,
    handName = nil,
}
local _conns: { RBXScriptConnection } = {}
local _previewEggs: { [number]: Model } = {}
local _previewBodies: { [number]: BasePart } = {}
local _previewFxKey: { [number]: string } = {}
local _spinning = false
local _spinAwaitGen: number? = nil
local _spinGen = 0

local ITEM_PLACE_NAMES = { "ItemPlace", "ItemPlace2", "ItemPlace3" }

local function findOfferPads(): { BasePart }
    local pads: { BasePart } = {}
    local buy = Workspace:FindFirstChild("BuyPlace")
    local parent: Instance = if buy and buy:IsA("Model") then buy else Workspace
    for i, name in ITEM_PLACE_NAMES do
        local p = parent:FindFirstChild(name)
        if p and p:IsA("BasePart") then
            pads[i] = p
        end
    end
    return pads
end

local function findSpinButton(): BasePart?
    local buy = Workspace:FindFirstChild("BuyPlace")
    if buy and buy:IsA("Model") then
        local buttonStand = buy:FindFirstChild("ButtonStand")
        if buttonStand and buttonStand:IsA("Model") then
            local btn = buttonStand:FindFirstChild("Button")
            if btn and btn:IsA("BasePart") then
                return btn
            end
            for _, d in buttonStand:GetDescendants() do
                if d:IsA("BasePart") and string.lower(d.Name) == "button" then
                    return d
                end
            end
        end
        local legacy = buy:FindFirstChild("BuyPlace")
        if legacy and legacy:IsA("BasePart") then
            return legacy
        end
    elseif buy and buy:IsA("BasePart") then
        return buy
    end
    return nil
end

local function findFavoriteCollectPart(): BasePart?
    local fav = Workspace:FindFirstChild("FavoritePlace")
    if not fav or not fav:IsA("Model") then
        return nil
    end
    local button = fav:FindFirstChild("Button")
    if not button then
        return nil
    end
    if button:IsA("BasePart") then
        return button
    end
    if button:IsA("Model") then
        if button.PrimaryPart and button.PrimaryPart:IsA("BasePart") then
            return button.PrimaryPart
        end
        for _, d in button:GetDescendants() do
            if d:IsA("BasePart") then
                return d
            end
        end
    end
    return nil
end

local function setOfferPromptsEnabled(enabled: boolean)
    local pads = findOfferPads()
    for _, pad in pads do
        local att = pad:FindFirstChild("PromptAttachment")
        if att then
            local prompt = att:FindFirstChild("BuyOfferPrompt")
            if prompt and prompt:IsA("ProximityPrompt") then
                prompt.Enabled = enabled
            end
        end
    end
    local spin = findSpinButton()
    if spin then
        local att = spin:FindFirstChild("PromptAttachment")
        if att then
            local prompt = att:FindFirstChild("BuyPlacePrompt")
            if prompt and prompt:IsA("ProximityPrompt") then
                prompt.Enabled = enabled
            end
        end
    end
end

local function applyOfferToPad(
    pad: BasePart,
    offerIndex: number,
    offer: SpinOffer,
    showBuyPrompt: boolean
)
    local variant = EggModel.variantForKey(offer.templateId)
    local egg = _previewEggs[offerIndex]
    local body = _previewBodies[offerIndex]
    if
        not egg
        or egg.Parent ~= pad
        or not body
        or body.Parent == nil
        or EggModel.variantOf(egg) ~= variant
    then
        if egg then
            egg:Destroy()
        end
        -- Drop stale egg-parented billboards from older clients.
        local staleOnPad = pad:FindFirstChild("OfferBillboard")
        if staleOnPad then
            staleOnPad:Destroy()
        end
        local model, primary = EggModel.clone("OfferPreview", offer.templateId)
        model.Parent = pad
        WorldUi.attachOfferBillboard(pad)
        _previewEggs[offerIndex] = model
        _previewBodies[offerIndex] = primary
        _previewFxKey[offerIndex] = nil
        egg = model
        body = primary
    end

    local mutLabel = offer.mutationLabel or ""
    local mutIds = MutationLogic.idsFromLabel(mutLabel)
    local scale = ExhibitLogic.visualScale(0, #mutIds > 0, offer.sizeId, mutIds)
    EggModel.applyScale(egg, scale)
    EggModel.setVisible(egg, true)
    EggModel.pivotOn(egg, pad.CFrame)

    local bb = pad:FindFirstChild("OfferBillboard")
    if not (bb and bb:IsA("BillboardGui")) then
        WorldUi.attachOfferBillboard(pad)
        bb = pad:FindFirstChild("OfferBillboard")
    end
    local buyPrice = offer.buyPrice
    if buyPrice == nil then
        buyPrice = ExhibitLogic.buyPrice(offer.rarity, offer.sizeId, #mutIds)
    end
    local priceText = `${WorldUi.shortMoney(buyPrice)}`
    if bb and bb:IsA("BillboardGui") then
        WorldUi.pinBillboardAbove(bb, pad, body)
        local frame = bb:FindFirstChild("Frame")
        local petName = if frame then frame:FindFirstChild("PetName") else nil
        local rarity = if frame then frame:FindFirstChild("Rarity") else nil
        local mutation = if frame then frame:FindFirstChild("Mutation") else nil
        local price = if frame then frame:FindFirstChild("Price") else nil
        if
            petName
            and petName:IsA("TextLabel")
            and rarity
            and rarity:IsA("TextLabel")
            and mutation
            and mutation:IsA("TextLabel")
        then
            WorldUi.setItemBillboard({
                petName = petName,
                rarity = rarity,
                mutation = mutation,
                price = if price and price:IsA("TextLabel") then price else nil,
            }, {
                displayName = offer.displayName,
                rarity = offer.rarity,
                mutationText = mutLabel,
                priceText = priceText,
            })
        end
    end
    -- HUD income ticks re-push offers often; only rebuild/Emit when FX identity changes.
    local fxKey = `{offer.templateId}|{offer.sizeId}|{mutLabel}|{variant}`
    if _previewFxKey[offerIndex] ~= fxKey then
        _previewFxKey[offerIndex] = fxKey
        MutationFx.syncFromLabel(body, mutLabel)
    else
        MutationFx.follow(body)
    end

    local att = pad:FindFirstChild("PromptAttachment")
    if att then
        local prompt = att:FindFirstChild("BuyOfferPrompt")
        if prompt and prompt:IsA("ProximityPrompt") then
            if showBuyPrompt then
                prompt.ObjectText = ""
                prompt.ActionText = "Buy"
                prompt.Enabled = true
                WorldUi.stylePrompt(prompt, "buy", 0)
            else
                prompt.Enabled = false
            end
        end
    end
end

local function clearOfferPad(offerIndex: number)
    local egg = _previewEggs[offerIndex]
    local body = _previewBodies[offerIndex]
    if egg then
        EggModel.setVisible(egg, false)
    end
    if body then
        MutationFx.clear(body)
        _previewFxKey[offerIndex] = nil
    end
    local pads = findOfferPads()
    local pad = pads[offerIndex]
    if pad then
        local bb = pad:FindFirstChild("OfferBillboard")
        if bb and bb:IsA("BillboardGui") then
            bb.Enabled = false
        end
        local att = pad:FindFirstChild("PromptAttachment")
        if att then
            local prompt = att:FindFirstChild("BuyOfferPrompt")
            if prompt and prompt:IsA("ProximityPrompt") then
                prompt.Enabled = false
            end
        end
    end
end

local function updateOfferPreview(pad: BasePart, offerIndex: number)
    local offer = _hud.offers[offerIndex]
    if not offer or offer.uid == "" then
        clearOfferPad(offerIndex)
        return
    end
    applyOfferToPad(pad, offerIndex, {
        templateId = offer.templateId,
        rarity = offer.rarity,
        sizeId = offer.sizeId,
        displayName = offer.displayName,
        baseIncome = offer.baseIncome,
        buyPrice = offer.buyPrice,
        mutationLabel = offer.mutationLabel,
    }, not _spinning)
end

local function refreshBankBillboard()
    local collectPart = findFavoriteCollectPart()
    if not collectPart then
        return
    end
    local existing = collectPart:FindFirstChild("FavoriteBankBillboard")
    local label: TextLabel?
    if existing and existing:IsA("BillboardGui") then
        -- Drop legacy card chrome if still present.
        if existing:FindFirstChild("Card", true) then
            existing:Destroy()
            existing = nil
        else
            local price = existing:FindFirstChild("Price", true)
            if price and price:IsA("TextLabel") then
                label = price
            end
        end
    end
    if not label then
        local _, amount = WorldUi.attachBankBillboard(collectPart)
        label = amount
    end
    local bank = math.floor((_hud.favoriteBank or 0) + 0.5)
    label.Text = WorldUi.shortMoney(bank)
end

local function refreshSpinPrompt()
    local spin = findSpinButton()
    if not spin then
        return
    end
    local att = spin:FindFirstChild("PromptAttachment")
    if not att then
        return
    end
    local prompt = att:FindFirstChild("BuyPlacePrompt")
    if prompt and prompt:IsA("ProximityPrompt") then
        prompt.ActionText = "Spin"
        prompt.ObjectText = ""
        prompt.Enabled = not _spinning
        WorldUi.stylePrompt(prompt, "restock", 0)
    end
end

local function refreshVisuals()
    if not _spinning then
        local pads = findOfferPads()
        for i = 1, 3 do
            local pad = pads[i]
            if pad then
                updateOfferPreview(pad, i)
            end
        end
    end
    refreshBankBillboard()
    refreshSpinPrompt()
end

local function hudOffersToFinals(): { SpinOffer }
    local finals: { SpinOffer } = {}
    for i = 1, 3 do
        local offer = _hud.offers[i]
        if offer and offer.uid ~= "" then
            finals[i] = {
                templateId = offer.templateId,
                rarity = offer.rarity,
                sizeId = offer.sizeId,
                displayName = offer.displayName,
                baseIncome = offer.baseIncome,
                buyPrice = offer.buyPrice,
                mutationLabel = offer.mutationLabel,
            }
        end
    end
    return finals
end

local function startRoulette()
    local finals = hudOffersToFinals()
    local padCount = 0
    for i = 1, 3 do
        if finals[i] then
            padCount = i
        end
    end
    if padCount == 0 then
        _spinning = false
        setOfferPromptsEnabled(true)
        refreshVisuals()
        return
    end

    OfferRoulette.play({
        padCount = padCount,
        finals = finals,
        applyVisual = function(padIndex, offer, _isFinal)
            local pads = findOfferPads()
            local pad = pads[padIndex]
            if pad then
                applyOfferToPad(pad, padIndex, offer, false)
                local bb = pad:FindFirstChild("OfferBillboard")
                if bb and bb:IsA("BillboardGui") then
                    bb.Enabled = true
                end
            end
        end,
        setBusy = function(busy)
            _spinning = busy
            setOfferPromptsEnabled(not busy)
            refreshSpinPrompt()
        end,
        onComplete = function()
            _spinning = false
            setOfferPromptsEnabled(true)
            refreshVisuals()
            Notification.show({
                text = "Stock refreshed",
                color = Color3.fromRGB(80, 220, 120),
            })
        end,
    })
end

local function onPromptTriggered(prompt: ProximityPrompt, player: Player)
    if player ~= localPlayer then
        return
    end
    local kind = prompt:GetAttribute("PromptKind")
    if kind == "restock" then
        if _spinning or OfferRoulette.isBusy() then
            return
        end
        SoundManager.play("ui_click")
        _spinGen += 1
        local gen = _spinGen
        _spinning = true
        _spinAwaitGen = gen
        setOfferPromptsEnabled(false)
        refreshSpinPrompt()
        for i = 1, 3 do
            clearOfferPad(i)
        end
        local result = Zap.RefreshOffers.Call()
        if not result.success then
            if _spinAwaitGen == gen then
                _spinAwaitGen = nil
            end
            _spinning = false
            setOfferPromptsEnabled(true)
            refreshVisuals()
            Notification.show({
                text = result.error or "Restock failed",
                color = Color3.fromRGB(255, 120, 80),
            })
            return
        end
        -- If PlayerDataSync already consumed _spinAwaitGen during Call, roulette started.
        if _spinAwaitGen == gen then
            task.delay(0.2, function()
                if _spinAwaitGen == gen then
                    pcall(function()
                        return Zap.RequestHudSync.Call()
                    end)
                end
            end)
        end
    elseif kind == "buy" then
        if _spinning then
            return
        end
        local offerIndex = prompt:GetAttribute("OfferIndex")
        if typeof(offerIndex) ~= "number" then
            return
        end
        SoundManager.play("ui_click")
        local result = Zap.PickOfferIndex.Call(offerIndex)
        if not result.success then
            SoundManager.play("sell_fail")
            local err = result.error or "Cannot buy"
            if err == "not_enough_coins" then
                err = "Not enough coins"
            end
            Notification.show({
                text = err,
                color = Color3.fromRGB(255, 120, 80),
            })
        else
            Notification.show({
                text = "Added to inventory",
                color = Color3.fromRGB(80, 220, 120),
            })
        end
    end
end

function PlotPromptBinder.setHud(hud: HudSyncPayload)
    _hud = hud
    if _spinAwaitGen ~= nil and _spinning then
        _spinAwaitGen = nil
        startRoulette()
        return
    end
    refreshVisuals()
end

function PlotPromptBinder.start()
    table.insert(_conns, ProximityPromptService.PromptTriggered:Connect(onPromptTriggered))

    table.insert(
        _conns,
        Zap.PlayerDataSync.On(function(value)
            local hud = NetTypes.fromZapSync(value)
            PlotPromptBinder.setHud(hud)
        end)
    )

    task.spawn(function()
        task.wait(0.5)
        local ok, result = pcall(function()
            return Zap.RequestHudSync.Call()
        end)
        if not ok then
            warn("[PlotPromptBinder] RequestHudSync failed", result)
        end
        refreshVisuals()
    end)
end

return PlotPromptBinder
