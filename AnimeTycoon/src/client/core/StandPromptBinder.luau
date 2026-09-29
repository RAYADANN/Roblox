--!strict
-- Stand previews + roulette on PlayerDataSync. Buy/Roll via server prompts.

local HttpService = game:GetService("HttpService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BoxModel = require(script.Parent.BoxModel)
local BoxPresence = require(script.Parent.BoxPresence)
local Constants = require(ReplicatedStorage.shared.data.Constants)
local OfferRoulette = require(script.Parent.OfferRoulette)
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

local function getPad(index: number): BasePart?
    local stands = Workspace:FindFirstChild("Stands")
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
    local box2 = Workspace:FindFirstChild("Box2")
    if not box2 then
        return nil
    end
    local hl = box2:FindFirstChildWhichIsA("Highlight")
    if hl and hl:IsA("Highlight") then
        return hl
    end
    return nil
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

local function attachOfferBillboard(model: Model, offer: OfferHud | OfferRoulette.SpinOffer, mystery: boolean)
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
  Seamless tick: hop+spin for full stepDuration.
  Mesh swap at hop peak. Duration matches roulette delay 1:1.
]]
local function playSeamlessRollSwap(
    index: number,
    oldModel: Model?,
    newModel: Model,
    pad: BasePart,
    duration: number,
    isFinal: boolean
)
    _padModels[index] = newModel
    setRollHighlight(newModel, true)
    BoxModel.placeOn(newModel, pad)
    local baseRot = newModel:GetPivot().Rotation
    local basePos = newModel:GetPivot().Position

    local spins = 1 -- full turn so end yaw lands on rest orientation
    local hopHeight = if isFinal then 0.35 else 0.22

    if oldModel and oldModel.Parent then
        setRollHighlight(oldModel, true)
        setModelHidden(newModel, true)
        BoxModel.placeOn(oldModel, pad)
    else
        setModelHidden(newModel, false)
    end

    local function poseAt(alpha: number): CFrame
        local a = math.clamp(alpha, 0, 1)
        local hop = math.sin(a * math.pi) * hopHeight
        -- Smoothstep reaches exactly 1 at a=1 (no short 3/4 cutoff).
        local eased = a * a * (3 - 2 * a)
        local yaw = math.rad(360 * spins * eased)
        return CFrame.new(basePos + Vector3.new(0, hop, 0)) * baseRot * CFrame.Angles(0, yaw, 0)
    end

    task.spawn(function()
        local t0 = os.clock()
        local swapped = oldModel == nil or oldModel.Parent == nil
        if swapped then
            setModelHidden(newModel, false)
        end

        while newModel.Parent and os.clock() - t0 < duration do
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
            task.wait()
        end

        if oldModel and oldModel.Parent then
            oldModel:Destroy()
        end
        if newModel.Parent then
            -- Finish the full turn (a=1), then snap to rest (same facing after 360°).
            setModelHidden(newModel, false)
            newModel:PivotTo(poseAt(1))
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
    local model = BoxModel.clone(boxName)
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
        attachOfferBillboard(model, offer, true)
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

local function refreshVisuals()
    for i = 1, Constants.OFFER_COUNT do
        local offer = _offers[i]
        if offer and offer.uid ~= "" then
            applyOfferToPad(i, offer, true)
        else
            clearPad(i)
        end
    end
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
    -- Clear focus scales before spin.
    for i = 1, Constants.OFFER_COUNT do
        setPadFocused(i, false)
    end
    local finals: { OfferRoulette.SpinOffer } = {}
    for i = 1, Constants.OFFER_COUNT do
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
        padCount = Constants.OFFER_COUNT,
        finals = finals,
        applyVisual = function(padIndex, spinOffer, isFinal, stepDuration)
            applyOfferToPad(padIndex, spinOffer, isFinal, stepDuration)
        end,
        setBusy = function(busy)
            _busy = busy
        end,
        onComplete = function()
            _busy = false
            _awaitSpin = false
            refreshVisuals()
            BoxModel.emitRollLandAll(_padModels)
        end,
    })
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

function StandPromptBinder.start()
    bindBuyFocusPrompts()
    refreshVisuals()
end

return StandPromptBinder
