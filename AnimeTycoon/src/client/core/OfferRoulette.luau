--!strict
-- Client stand-offer roulette (cosmetic). Finals come from server HUD.
-- Last step = real offer. Completion waits for EVERY pad (no early onComplete).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local BoxVisualLogic = require(ReplicatedStorage.shared.util.BoxVisualLogic)
local ContainerLogic = require(ReplicatedStorage.shared.util.ContainerLogic)
local HeroCatalog = require(ReplicatedStorage.shared.data.HeroCatalog)
local MutationLogic = require(ReplicatedStorage.shared.util.MutationLogic)
local OfferRouletteLogic = require(ReplicatedStorage.shared.util.OfferRouletteLogic)
local RarityDatabase = require(ReplicatedStorage.shared.data.RarityDatabase)

export type SpinOffer = {
    templateId: string,
    boxModelName: string,
    rarity: string,
    heroId: string,
    displayName: string,
    baseIncome: number,
    buyPrice: number?,
    mutationLabel: string?,
}

export type ApplyVisual = (
    padIndex: number,
    offer: SpinOffer,
    isFinal: boolean,
    stepDuration: number
) -> ()

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
    local entry = RarityDatabase.get(rarity)
    local standLevel = 1
    local boxModelName = BoxVisualLogic.pickBoxModelName(standLevel, math.random())
    local heroId = ContainerLogic.pickHeroId(rarity, math.random())
    local muts = MutationLogic.rollOfferMutations(rarity, math.random(), math.random())
    return {
        templateId = "stand" .. tostring(standLevel),
        boxModelName = boxModelName,
        rarity = rarity,
        heroId = heroId,
        displayName = HeroCatalog.displayName(heroId),
        baseIncome = if entry then entry.baseIncomePerMini else 5,
        buyPrice = ContainerLogic.buyPrice(rarity, #muts),
        mutationLabel = MutationLogic.formatLabel(muts),
    }
end

local function cancelZoomTween()
    if _zoomTween then
        _zoomTween:Cancel()
        _zoomTween = nil
    end
end

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

function OfferRoulette.isBusy(): boolean
    return false
end

function OfferRoulette.cancel()
    _token += 1
    cancelZoomTween()
end

function OfferRoulette.play(opts: PlayOpts)
    _token += 1
    local token = _token
    if opts.setBusy then
        opts.setBusy(true)
    end

    local delays = OfferRouletteLogic.stepDelays(nil)
    local stagger = OfferRouletteLogic.padStagger(nil)
    local zoomDur = OfferRouletteLogic.totalDuration(delays, stagger, opts.padCount)
    local startFov = zoomInOver(zoomDur)

    local padsLeft = opts.padCount
    local finished = false

    local function finishAll()
        if finished or token ~= _token then
            return
        end
        finished = true
        zoomOutSmooth(startFov)
        if opts.setBusy then
            opts.setBusy(false)
        end
        if opts.onComplete then
            opts.onComplete()
        end
    end

    local function padFinished()
        if token ~= _token then
            return
        end
        padsLeft -= 1
        if padsLeft <= 0 then
            finishAll()
        end
    end

    for pad = 1, opts.padCount do
        task.spawn(function()
            if pad > 1 and stagger > 0 then
                task.wait(stagger * (pad - 1))
            end
            if token ~= _token then
                padFinished()
                return
            end
            local stepCount = #delays
            for stepIndex, delay in delays do
                if token ~= _token then
                    padFinished()
                    return
                end
                local isLast = stepIndex == stepCount
                local final = opts.finals[pad]
                local useFinal = isLast
                    and final ~= nil
                    and typeof(final.templateId) == "string"
                    and final.templateId ~= ""
                local offer = if useFinal then final :: SpinOffer else fakeOffer()
                opts.applyVisual(pad, offer, useFinal, delay)
                task.wait(delay)
                -- Settle poseAt(1)+placeOn before next tick.
                task.wait()
            end
            padFinished()
        end)
    end
end

return OfferRoulette
