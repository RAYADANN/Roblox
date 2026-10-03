--!strict
-- Stand previews + roulette on PlayerDataSync. Buy/Roll via server prompts.

local HttpService = game:GetService("HttpService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseLayout = require(ReplicatedStorage.shared.util.BaseLayout)
local BoxModel = require(script.Parent.BoxModel)
local BoxPresence = require(script.Parent.BoxPresence)
local Constants = require(ReplicatedStorage.shared.data.Constants)
local ContentRoots = require(ReplicatedStorage.shared.util.ContentRoots)
local OfferRoulette = require(script.Parent.OfferRoulette)
local UpgradeLogic = require(ReplicatedStorage.shared.util.UpgradeLogic)
local WorldBillboard = require(script.Parent.WorldBillboard)

export type OfferHud = {
    uid: string,
    templateId: string,
    boxModelName: string,
    rarity: string,
    heroId: string,
    displayName: string,
    baseIncome: number,
    buyPrice: number,
    mutationLabel: string,
}

local StandPromptBinder = {}

local _offers: { OfferHud } = {}
local _busy = false
local _awaitSpin = false
local _padModels: { [number]: Model } = {}
local _presence: { [number]: BoxPresence.Handle } = {}
local _lastOffersJson: string = ""
local _focusServiceBound = false
--- Bump to cancel an in-flight roll swap on that pad (avoids mid-turn cut).
local _rollAnimGen: { [number]: number } = {}
local _onIdle: (() -> ())? = nil
local _upgrades: { [string]: number } = {}

local function unlockedPadCount(): number
    return UpgradeLogic.unlockedPads(_upgrades)
end

local function isPadUnlocked(index: number): boolean
    return UpgradeLogic.isPadUnlocked(_upgrades, index)
end

local function getPad(index: number): BasePart?
    local stands = BaseLayout.getStands()
    if not stands then
        return nil
    end
    local stand = stands:FindFirstChild("Stand" .. index)
    if not stand then
        return nil
    end
    local pad = stand:FindFirstChild("BoxPlace") or stand:FindFirstChild("EggPlace")
    if pad and pad:IsA("BasePart") then
        return pad
    end
    return nil
end

local function clearPad(index: number)
    _rollAnimGen[index] = (_rollAnimGen[index] or 0) + 1
    local handle = _presence[index]
    if handle then
        handle.stop()
        _presence[index] = nil
    end
    local model = _padModels[index]
    if model then
        model:Destroy()
        _padModels[index] = nil
    end
end

local function getHighlightTemplate(): Highlight?
    return ContentRoots.boxHighlightTemplate()
end

local function setRollHighlight(model: Model, enabled: boolean)
    local hl = model:FindFirstChild("RollHighlight")
    if not hl or not hl:IsA("Highlight") then
        local any = model:FindFirstChildWhichIsA("Highlight")
        if any and any.Name ~= "FocusHighlight" and any:IsA("Highlight") then
            hl = any
            hl.Name = "RollHighlight"
        else
            local template = getHighlightTemplate()
            if not template then
                return
            end
            hl = template:Clone()
            hl.Name = "RollHighlight"
            hl.Parent = model
        end
    end
    if not hl:IsA("Highlight") then
        return
    end
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    -- Roll: outline only, fill fully transparent.
    hl.FillTransparency = 1
    hl.OutlineTransparency = 0
    hl.Enabled = enabled
end

local function setModelHidden(model: Model, hidden: boolean)
    local mod = if hidden then 1 else 0
    for _, d in model:GetDescendants() do
        if d:IsA("BasePart") then
            d.LocalTransparencyModifier = mod
        end
    end
    local bb = model:FindFirstChildWhichIsA("BillboardGui", true)
    if bb and bb:IsA("BillboardGui") then
        bb.Enabled = not hidden
    end
end

local function attachOfferBillboard(
    model: Model,
    offer: OfferHud | OfferRoulette.SpinOffer,
    mystery: boolean
)
    local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
    if not primary or not primary:IsA("BasePart") then
        return
    end
    local gui = WorldBillboard.attach(primary, "OfferBillboard")
    if not gui then
        return
    end
    if mystery then
        WorldBillboard.set(gui, {
            displayName = "???",
            rarity = "???",
            mutationText = "???",
            priceText = nil,
        })
    else
        local buyPrice = (offer :: any).buyPrice
        WorldBillboard.set(gui, {
            displayName = offer.displayName,
            rarity = offer.rarity,
            mutationText = (offer :: any).mutationLabel,
            priceText = if typeof(buyPrice) == "number" and buyPrice > 0
                then WorldBillboard.shortMoney(buyPrice)
                else nil,
        })
    end
end

--[[
  Seamless tick: hop+spin for full stepDuration (complete 360°).
  Rest orientation is captured from a fresh placeOn — never from a mid-spin model
  (that was tipping far pads when onComplete / next tick ran early).
]]
local function playSeamlessRollSwap(
    index: number,
    oldModel: Model?,
    newModel: Model,
    pad: BasePart,
    duration: number,
    isFinal: boolean
)
    _rollAnimGen[index] = (_rollAnimGen[index] or 0) + 1
    local gen = _rollAnimGen[index]

    _padModels[index] = newModel
    setRollHighlight(newModel, true)
    -- Fresh clone → upright rest. This CFrame is the only spin baseline.
    BoxModel.placeOn(newModel, pad)
    local restCf = newModel:GetPivot()
    local baseRot = restCf.Rotation
    local basePos = restCf.Position

    local spins = 1
    local hopHeight = if isFinal then 0.35 else 0.22

    if oldModel and oldModel.Parent then
        setRollHighlight(oldModel, true)
        setModelHidden(newModel, true)
        -- Snap old to the same upright rest (do NOT placeOn — it preserves tilt).
        oldModel:PivotTo(restCf)
    else
        setModelHidden(newModel, false)
    end

    local function poseAt(alpha: number): CFrame
        local a = math.clamp(alpha, 0, 1)
        local hop = math.sin(a * math.pi) * hopHeight
        local yaw = math.rad(360 * spins * a)
        return CFrame.new(basePos + Vector3.new(0, hop, 0)) * baseRot * CFrame.Angles(0, yaw, 0)
    end

    task.spawn(function()
        local t0 = os.clock()
        local swapped = oldModel == nil or oldModel.Parent == nil
        if swapped then
            setModelHidden(newModel, false)
        end

        while newModel.Parent do
            if _rollAnimGen[index] ~= gen then
                return
            end
            local a = math.clamp((os.clock() - t0) / duration, 0, 1)
            local cf = poseAt(a)

            if a < 0.5 and not swapped then
                if oldModel and oldModel.Parent then
                    oldModel:PivotTo(cf)
                else
                    swapped = true
                    setModelHidden(newModel, false)
                    newModel:PivotTo(cf)
                end
            else
                if not swapped then
                    swapped = true
                    if oldModel and oldModel.Parent then
                        oldModel:Destroy()
                    end
                    setModelHidden(newModel, false)
                end
                if newModel.Parent then
                    newModel:PivotTo(cf)
                end
            end
            if a >= 1 then
                break
            end
            task.wait()
        end

        if _rollAnimGen[index] ~= gen then
            return
        end

        if oldModel and oldModel.Parent then
            oldModel:Destroy()
        end
        if newModel.Parent then
            setModelHidden(newModel, false)
            -- Exact upright rest (not poseAt(1) float), then pad align.
            newModel:PivotTo(CFrame.new(basePos) * baseRot)
            BoxModel.placeOn(newModel, pad)
            local hl = newModel:FindFirstChild("RollHighlight")
            if hl and hl:IsA("Highlight") then
                hl.FillTransparency = 1
                hl.OutlineTransparency = 0
                hl.Enabled = true
            end
        end
    end)
end

local function applyOfferToPad(
    index: number,
    offer: OfferHud | OfferRoulette.SpinOffer,
    isFinal: boolean,
    stepDuration: number?
)
    if typeof((offer :: any).uid) == "string" and (offer :: any).uid == "" then
        clearPad(index)
        return
    end
    if offer.templateId == "" and offer.boxModelName == "" then
        clearPad(index)
        return
    end
    local pad = getPad(index)
    if not pad then
        return
    end
    local boxName = offer.boxModelName
    if boxName == "" then
        boxName = "Box1"
    end
    local model = BoxModel.clone(boxName, {
        mutationLabel = (offer :: any).mutationLabel,
    })
    if not model then
        return
    end

    local handle = _presence[index]
    if handle then
        handle.stop()
        _presence[index] = nil
    end

    local oldModel = _padModels[index]
    local dur = stepDuration or 0

    if _busy and dur > 0 then
        -- Final step already has the real offer; show real billboard (no post-spin remesh).
        attachOfferBillboard(model, offer, not isFinal)
        playSeamlessRollSwap(index, oldModel, model, pad, dur, isFinal)
        return
    end

    if oldModel then
        oldModel:Destroy()
    end
    BoxModel.placeOn(model, pad)
    _padModels[index] = model
    setRollHighlight(model, false)
    attachOfferBillboard(model, offer, false)
    _presence[index] = BoxPresence.start(model, {
        pad = pad,
        allowFocus = true,
        realign = function(m, p)
            BoxModel.placeOn(m, p)
        end,
    })
end

-- Client gates Buy: empty pads, locked pads, and mid-roulette must not show ProximityPrompt.
local function syncBuyPrompts()
    local base = BaseLayout.getLocal() or BaseLayout.getPrimary()
    if not base then
        return
    end
    for _, d in base:GetDescendants() do
        if d:IsA("ProximityPrompt") and d:GetAttribute("PromptKind") == "buy" then
            local idx = d:GetAttribute("OfferIndex")
            if typeof(idx) ~= "number" then
                continue
            end
            local padIndex = idx :: number
            local offer = _offers[padIndex]
            local canBuy = not _busy
                and isPadUnlocked(padIndex)
                and offer ~= nil
                and offer.uid ~= ""
            d.Enabled = canBuy
            d.MaxActivationDistance = if canBuy then 12 else 0
        end
    end
end

local function refreshVisuals()
    local unlocked = unlockedPadCount()
    for i = 1, Constants.OFFER_COUNT do
        if i > unlocked then
            clearPad(i)
            continue
        end
        local offer = _offers[i]
        if offer and offer.uid ~= "" then
            applyOfferToPad(i, offer, true)
        else
            clearPad(i)
        end
    end
    syncBuyPrompts()
end

local function setPadFocused(index: number, focused: boolean)
    if _busy then
        return
    end
    local handle = _presence[index]
    if handle then
        handle.setFocused(focused)
    end
end

local function offerIndexFromPrompt(prompt: ProximityPrompt): number?
    if prompt:GetAttribute("PromptKind") ~= "buy" then
        return nil
    end
    local idx = prompt:GetAttribute("OfferIndex")
    if typeof(idx) == "number" then
        return idx :: number
    end
    -- Fallback: match pad under StandN
    local parent = prompt.Parent
    if not parent then
        return nil
    end
    for i = 1, Constants.OFFER_COUNT do
        local pad = getPad(i)
        if pad and parent == pad then
            return i
        end
    end
    return nil
end

local function bindBuyFocusPrompts()
    if _focusServiceBound then
        return
    end
    _focusServiceBound = true
    ProximityPromptService.PromptShown:Connect(function(prompt: ProximityPrompt, _inputType)
        local index = offerIndexFromPrompt(prompt)
        if index then
            setPadFocused(index, true)
        end
    end)
    ProximityPromptService.PromptHidden:Connect(function(prompt: ProximityPrompt)
        local index = offerIndexFromPrompt(prompt)
        if index then
            setPadFocused(index, false)
        end
    end)
end

local function startRoulette()
    if _busy then
        return
    end
    local unlocked = unlockedPadCount()
    -- Clear focus scales before spin.
    for i = 1, unlocked do
        setPadFocused(i, false)
    end
    local finals: { OfferRoulette.SpinOffer } = {}
    for i = 1, unlocked do
        local o = _offers[i]
        if o and o.uid ~= "" then
            finals[i] = {
                templateId = o.templateId,
                boxModelName = o.boxModelName,
                rarity = o.rarity,
                heroId = o.heroId,
                displayName = o.displayName,
                baseIncome = o.baseIncome,
                buyPrice = o.buyPrice,
                mutationLabel = o.mutationLabel,
            }
        else
            finals[i] = {
                templateId = "",
                boxModelName = "",
                rarity = "common",
                heroId = "",
                displayName = "",
                baseIncome = 0,
            }
        end
    end
    OfferRoulette.play({
        padCount = unlocked,
        finals = finals,
        applyVisual = function(padIndex, spinOffer, isFinal, stepDuration)
            applyOfferToPad(padIndex, spinOffer, isFinal, stepDuration)
        end,
        setBusy = function(busy)
            local wasBusy = _busy
            _busy = busy
            syncBuyPrompts()
            if wasBusy and not busy then
                local cb = _onIdle
                if cb then
                    cb()
                end
            end
        end,
        onComplete = function()
            _busy = false
            _awaitSpin = false
            -- Snap every unlocked pad upright again (guards against any mid-spin settle race).
            for i = 1, unlocked do
                local model = _padModels[i]
                local offer = _offers[i]
                local pad = getPad(i)
                if model and offer and offer.uid ~= "" and pad then
                    _rollAnimGen[i] = (_rollAnimGen[i] or 0) + 1
                    BoxModel.placeOn(model, pad)
                    setRollHighlight(model, false)
                    attachOfferBillboard(model, offer, false)
                    local handle = _presence[i]
                    if handle then
                        handle.stop()
                    end
                    _presence[i] = BoxPresence.start(model, {
                        pad = pad,
                        allowFocus = true,
                        realign = function(m, p)
                            BoxModel.placeOn(m, p)
                        end,
                    })
                end
            end
            BoxModel.emitRollLandAll(_padModels)
            syncBuyPrompts()
            local cb = _onIdle
            if cb then
                cb()
            end
        end,
    })
end

function StandPromptBinder.applyUpgrades(upgrades: { [string]: number }?)
    _upgrades = if upgrades then upgrades else {}
    if not _busy then
        refreshVisuals()
    end
end

function StandPromptBinder.setOffersFromJson(offersJson: string, spun: boolean?)
    local decoded = {}
    local ok, result = pcall(function()
        return HttpService:JSONDecode(offersJson)
    end)
    if ok and typeof(result) == "table" then
        decoded = result
    end
    _offers = {}
    for i = 1, Constants.OFFER_COUNT do
        local row = decoded[i]
        if typeof(row) == "table" then
            _offers[i] = row :: OfferHud
        else
            _offers[i] = {
                uid = "",
                templateId = "",
                boxModelName = "",
                rarity = "common",
                heroId = "",
                displayName = "",
                baseIncome = 0,
                buyPrice = 0,
                mutationLabel = "",
            }
        end
    end

    local shouldSpin = (_awaitSpin or spun == true) and not _busy
    if shouldSpin then
        _awaitSpin = false
        _lastOffersJson = offersJson
        startRoulette()
        return
    end

    if _busy then
        return
    end

    if offersJson == _lastOffersJson then
        return
    end
    _lastOffersJson = offersJson
    refreshVisuals()
end

function StandPromptBinder.markSpinAwait()
    if _busy then
        return
    end
    _awaitSpin = true
end

--- Client preview model on StandN (for FTUE beam / spotlight).
function StandPromptBinder.getOfferModel(index: number): Model?
    return _padModels[index]
end

function StandPromptBinder.isBusy(): boolean
    return _busy
end

--- Fired when roulette finishes (also if setBusy goes true→false).
function StandPromptBinder.setOnIdle(callback: (() -> ())?)
    _onIdle = callback
end

function StandPromptBinder.start()
    bindBuyFocusPrompts()
    refreshVisuals()
end

return StandPromptBinder
