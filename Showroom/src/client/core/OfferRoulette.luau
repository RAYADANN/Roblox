--!strict
-- Client egg-offer roulette: cycle fake eggs → land on server offers + FOV zoom.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local ExhibitCatalog = require(ReplicatedStorage.shared.data.ExhibitCatalog)
local ExhibitLogic = require(ReplicatedStorage.shared.util.ExhibitLogic)
local MutationLogic = require(ReplicatedStorage.shared.util.MutationLogic)
local OfferRouletteLogic = require(ReplicatedStorage.shared.util.OfferRouletteLogic)
local RarityDatabase = require(ReplicatedStorage.shared.data.RarityDatabase)

export type SpinOffer = {
    templateId: string,
    rarity: string,
    sizeId: string,
    displayName: string,
    baseIncome: number,
    buyPrice: number?,
    mutationLabel: string?,
}

export type ApplyVisual = (padIndex: number, offer: SpinOffer, isFinal: boolean) -> ()

export type PlayOpts = {
    padCount: number,
    finals: { SpinOffer },
    applyVisual: ApplyVisual,
    onComplete: (() -> ())?,
    setBusy: ((busy: boolean) -> ())?,
}

local OfferRoulette = {}

local _token = 0
local FOV_ZOOM = 12
local FOV_OUT = 0.28
local _zoomTween: Tween? = nil

local function fakeOffer(): SpinOffer
    local rarity = MutationLogic.pickRarity(math.random())
    local templateId = MutationLogic.pickTemplate(math.random())
    local template = ExhibitCatalog.byId[templateId]
    local sizeId = ExhibitLogic.rollSize(math.random())
    local entry = RarityDatabase.get(rarity)
    local baseName = if template then template.displayName else "Egg"
    local mutLabel = ""
    local muts = MutationLogic.rollEggMutations(rarity, math.random(), math.random())
    if #muts > 0 then
        mutLabel = MutationLogic.formatLabel(muts)
    end
    return {
        templateId = templateId,
        rarity = rarity,
        sizeId = sizeId,
        displayName = baseName,
        baseIncome = if entry then entry.baseIncomePerSec else 5,
        buyPrice = ExhibitLogic.buyPrice(rarity, sizeId, #muts),
        mutationLabel = mutLabel,
    }
end

local function cancelZoomTween()
    if _zoomTween then
        _zoomTween:Cancel()
        _zoomTween = nil
    end
end

-- Smooth FOV push-in across the whole spin; quicker ease-out on finish.
local function zoomInOver(durationSec: number): number
    local cam = Workspace.CurrentCamera
    if not cam then
        return 70
    end
    cancelZoomTween()
    local startFov = cam.FieldOfView
    local target = math.clamp(startFov - FOV_ZOOM, 40, 90)
    local tween = TweenService:Create(
        cam,
        TweenInfo.new(math.max(0.05, durationSec), Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
        { FieldOfView = target }
    )
    _zoomTween = tween
    tween:Play()
    return startFov
end

local function zoomOutSmooth(startFov: number)
    local cam = Workspace.CurrentCamera
    if not cam then
        return
    end
    cancelZoomTween()
    local tween = TweenService:Create(
        cam,
        TweenInfo.new(FOV_OUT, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { FieldOfView = startFov }
    )
    _zoomTween = tween
    tween:Play()
end

local _active = false

function OfferRoulette.isBusy(): boolean
    return _active
end

function OfferRoulette.play(opts: PlayOpts)
    _token += 1
    local token = _token
    _active = true
    if opts.setBusy then
        opts.setBusy(true)
    end

    local delays = OfferRouletteLogic.stepDelays(nil)
    local stagger = OfferRouletteLogic.padStagger(nil)
    local spinDuration = OfferRouletteLogic.totalDuration(delays, stagger, opts.padCount)
    local startFov = zoomInOver(spinDuration)
    local pending = opts.padCount

    local function finishOne()
        pending -= 1
        if pending > 0 then
            return
        end
        if token ~= _token then
            return
        end
        _active = false
        zoomOutSmooth(startFov)
        if opts.setBusy then
            opts.setBusy(false)
        end
        if opts.onComplete then
            opts.onComplete()
        end
    end

    for padIndex = 1, opts.padCount do
        task.spawn(function()
            if stagger > 0 and padIndex > 1 then
                task.wait(stagger * (padIndex - 1))
            end
            if token ~= _token then
                finishOne()
                return
            end
            local final = opts.finals[padIndex]
            for step = 1, #delays do
                if token ~= _token then
                    break
                end
                local isLast = step == #delays
                local offer: SpinOffer = if isLast and final then final else fakeOffer()
                opts.applyVisual(padIndex, offer, isLast)
                task.wait(delays[step])
            end
            if final and token == _token then
                opts.applyVisual(padIndex, final, true)
            end
            finishOne()
        end)
    end
end

function OfferRoulette.cancel()
    _token += 1
    _active = false
    cancelZoomTween()
end

return OfferRoulette
