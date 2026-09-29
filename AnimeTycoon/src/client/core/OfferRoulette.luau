--!strict
-- Client stand-offer roulette (cosmetic). Finals come from server HUD.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local ContainerCatalog = require(ReplicatedStorage.shared.data.ContainerCatalog)
local ContainerLogic = require(ReplicatedStorage.shared.util.ContainerLogic)
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

export type ApplyVisual = (padIndex: number, offer: SpinOffer, isFinal: boolean, stepDuration: number) -> ()

export type PlayOpts = {
    padCount: number,
    finals: { SpinOffer },
    applyVisual: ApplyVisual,
    onComplete: (() -> ())?,
    setBusy: ((busy: boolean) -> ())?,
}

local OfferRoulette = {}

local _token = 0
local _boxCycle = 0
local FOV_ZOOM = 12
local FOV_OUT = 0.28
local _zoomTween: Tween? = nil

local function fakeOffer(): SpinOffer
    -- Hard-cycle Box1/2/3 so mesh swaps are obvious every tick.
    _boxCycle = (_boxCycle % 3) + 1
    local boxModelName = "Box" .. tostring(_boxCycle)
    local templateId = "box" .. tostring(_boxCycle)
    local template = ContainerCatalog.get(templateId)
    local rarity = MutationLogic.pickRarity(math.random())
    local entry = RarityDatabase.get(rarity)
    local muts = MutationLogic.rollOfferMutations(rarity, math.random(), math.random())
    return {
        templateId = templateId,
        boxModelName = boxModelName,
        rarity = rarity,
        heroId = ContainerLogic.pickHeroId(templateId, math.random()),
        displayName = if template then template.displayName else "Box",
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
    -- Cancel any in-flight spin, then run exactly one new sequence.
    _token += 1
    local token = _token
    if opts.setBusy then
        opts.setBusy(true)
    end

    local delays = OfferRouletteLogic.stepDelays(nil)
    local stagger = OfferRouletteLogic.padStagger(nil)
    local finalDur = delays[#delays] or 0.4
    local maxDur = OfferRouletteLogic.totalDuration(delays, stagger, opts.padCount) + finalDur
    local startFov = zoomInOver(maxDur)

    task.spawn(function()
        for pad = 1, opts.padCount do
            task.spawn(function()
                if pad > 1 then
                    task.wait(stagger * (pad - 1))
                end
                if token ~= _token then
                    return
                end
                for _, delay in delays do
                    if token ~= _token then
                        return
                    end
                    -- stepDuration == wait: anim fills the whole tick, no seam/pause
                    opts.applyVisual(pad, fakeOffer(), false, delay)
                    task.wait(delay)
                end
                if token ~= _token then
                    return
                end
                local final = opts.finals[pad]
                if final and final.templateId ~= "" then
                    opts.applyVisual(pad, final, true, finalDur)
                    task.wait(finalDur)
                end
            end)
        end
        task.wait(maxDur + 0.05)
        if token ~= _token then
            return
        end
        zoomOutSmooth(startFov)
        if opts.setBusy then
            opts.setBusy(false)
        end
        if opts.onComplete then
            opts.onComplete()
        end
    end)
end

return OfferRoulette
