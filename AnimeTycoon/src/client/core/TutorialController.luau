--!strict
-- Client FTUE orchestrator: beam + near spotlight + hint; advances from HUD/notify.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StandPromptBinder = require(script.Parent.StandPromptBinder)
local TutorialBeam = require(script.Parent.TutorialBeam)
local TutorialHint = require(script.Parent.TutorialHint)
local TutorialHost = require(script.Parent.Parent.ui.util.TutorialHost)
local TutorialLogic = require(ReplicatedStorage.shared.util.TutorialLogic)
local TutorialSpotlight = require(script.Parent.Parent.ui.util.TutorialSpotlight)
local TutorialTargets = require(script.Parent.TutorialTargets)

export type HudSnap = {
    offersJson: string,
    slotsJson: string,
    inventoryJson: string,
    handUid: string,
    sellBoxCoins: number,
    sellCratesJson: string,
}

local TutorialController = {}

local _active = false
local _doneLocal = false
local _debugPinned = false
local _step = 1
local _didRoll = false
local _didBuy = false
local _didPlace = false
local _didOpen = false
local _didTake = false
local _didSell = false
local _offersJson = "[]"
local _slotsJson = "[]"
local _inventoryJson = "[]"
local _handUid = ""
local _sellBoxCoins = 0
local _sellCratesJson = "[]"
local _onComplete: (() -> ())? = nil

local function playerRoot(): BasePart?
    local player = Players.LocalPlayer
    local char = player and player.Character
    if not char then
        return nil
    end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:IsA("BasePart") then
        return hrp
    end
    return nil
end

local function hasReadySlot(): boolean
    if _slotsJson == "" or _slotsJson == "[]" then
        return false
    end
    local HttpService = game:GetService("HttpService")
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(_slotsJson)
    end)
    if not ok or typeof(decoded) ~= "table" then
        return false
    end
    for _, row in decoded do
        if typeof(row) == "table" and row.unpacked ~= true then
            if (tonumber(row.unpackProgress) or 0) >= 0.999 then
                return true
            end
        end
    end
    return false
end

local function buildSnap(): TutorialLogic.Snapshot
    return {
        didRoll = _didRoll,
        didBuy = _didBuy,
        didPlace = _didPlace,
        hasReady = hasReadySlot(),
        didOpen = _didOpen,
        hasSellBoxCoins = _sellBoxCoins > 0,
        didTake = _didTake,
        didSell = _didSell,
    }
end

local function resetActionFlags()
    _didRoll = false
    _didBuy = false
    _didPlace = false
    _didOpen = false
    _didTake = false
    _didSell = false
end

local function refreshVisuals()
    if not _active then
        return
    end
    local def = TutorialLogic.getStep(_step)
    if def == nil then
        TutorialHint.clear()
        TutorialBeam.setTarget(nil)
        TutorialSpotlight.setTarget(nil)
        return
    end
    TutorialHint.set(def.hint)
    local target = TutorialTargets.resolve(def.target, _offersJson, _slotsJson)
    TutorialBeam.setTarget(target)
    TutorialBeam.setVisible(true)
    -- Buy: wait for stand roulette to finish before spotlight frame.
    if def.id == "buy" and StandPromptBinder.isBusy() then
        TutorialSpotlight.setTarget(nil)
    else
        TutorialSpotlight.setTarget(target)
    end
end

local function finish()
    if not _active and _doneLocal then
        return
    end
    _active = false
    _doneLocal = true
    _step = TutorialLogic.STEP_DONE
    StandPromptBinder.setOnIdle(nil)
    TutorialHint.clear()
    TutorialBeam.stop()
    TutorialSpotlight.unbind()
    local cb = _onComplete
    _onComplete = nil
    if cb then
        cb()
    end
end

local function applyAdvance()
    if not _active then
        return
    end
    local snap = buildSnap()
    local nextStep = if _debugPinned
        then TutorialLogic.advanceOne(_step, snap)
        else TutorialLogic.advance(_step, snap)
    if nextStep == TutorialLogic.STEP_DONE then
        finish()
        return
    end
    if nextStep ~= _step then
        _step = nextStep
        refreshVisuals()
    else
        refreshVisuals()
    end
end

function TutorialController.isActive(): boolean
    return _active
end

function TutorialController.isDoneLocal(): boolean
    return _doneLocal
end

function TutorialController.getStep(): number
    return _step
end

--- Sync completion flag from server (also clears local done on Studio /tutorial reset).
function TutorialController.syncCompleted(serverCompleted: boolean)
    if serverCompleted then
        _doneLocal = true
        if _active then
            _active = false
            _onComplete = nil
            TutorialHint.clear()
            TutorialBeam.stop()
            TutorialSpotlight.unbind()
        end
        return
    end
    -- Server says not done (fresh profile or /tutorial).
    _doneLocal = false
end

function TutorialController.start(onComplete: (() -> ())?)
    if _active or _doneLocal then
        return
    end
    _active = true
    _debugPinned = false
    _onComplete = onComplete
    resetActionFlags()
    _step = TutorialLogic.advance(1, buildSnap())
    if _step == TutorialLogic.STEP_DONE then
        finish()
        return
    end
    TutorialSpotlight.bind(TutorialHost.spotlight(), playerRoot, TutorialLogic.NEAR_STUDS)
    TutorialBeam.start()
    StandPromptBinder.setOnIdle(function()
        if _active then
            refreshVisuals()
        end
    end)
    refreshVisuals()
end

function TutorialController.stop()
    if not _active then
        TutorialHint.clear()
        TutorialBeam.stop()
        TutorialSpotlight.unbind()
        return
    end
    _active = false
    _onComplete = nil
    StandPromptBinder.setOnIdle(nil)
    TutorialHint.clear()
    TutorialBeam.stop()
    TutorialSpotlight.unbind()
end

--- Force-restart from step 1 (debug). Clears local done; caller should reset server flag.
function TutorialController.restartForDebug(onComplete: (() -> ())?)
    TutorialController.stop()
    _doneLocal = false
    _debugPinned = true
    resetActionFlags()
    _active = true
    _onComplete = onComplete
    _step = 1
    TutorialSpotlight.bind(TutorialHost.spotlight(), playerRoot, TutorialLogic.NEAR_STUDS)
    TutorialBeam.start()
    StandPromptBinder.setOnIdle(function()
        if _active then
            refreshVisuals()
        end
    end)
    refreshVisuals()
end

function TutorialController.bindDebugHotkey(onRestart: () -> ())
    local RunService = game:GetService("RunService")
    if not RunService:IsStudio() then
        return
    end
    local UserInputService = game:GetService("UserInputService")
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end
        if input.KeyCode ~= Enum.KeyCode.T then
            return
        end
        onRestart()
    end)
end

function TutorialController.applyHud(hud: HudSnap)
    _offersJson = hud.offersJson
    _slotsJson = hud.slotsJson
    _inventoryJson = hud.inventoryJson
    _handUid = hud.handUid or ""
    _sellBoxCoins = hud.sellBoxCoins
    _sellCratesJson = hud.sellCratesJson
    if _active then
        applyAdvance()
    end
end

function TutorialController.onNotify(kind: string)
    if kind == "rolled" then
        _didRoll = true
    elseif kind == "bought" then
        _didBuy = true
    elseif kind == "placed" then
        _didPlace = true
    elseif kind == "unpacked" then
        _didOpen = true
    elseif kind == "sellbox_picked" then
        _didTake = true
    elseif kind == "income" then
        _didSell = true
    end
    if _active then
        applyAdvance()
    end
end

return TutorialController
