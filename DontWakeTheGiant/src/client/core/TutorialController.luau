--!strict
-- FTUE glue: snapshot → step → beam, hint, spotlight. Not started from boot.
-- Pass getSnapshot / resolveTarget from the game. Steps live in TutorialLogic.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local TutorialBeam = require(script.Parent.TutorialBeam)
local TutorialHint = require(script.Parent.TutorialHint)
local TutorialLogic = require(ReplicatedStorage.shared.util.TutorialLogic)
local TutorialSpotlight = require(script.Parent.TutorialSpotlight)
local UiScreen = require(script.Parent.Parent.ui.util.UiScreen)

export type Deps = {
    getSnapshot: () -> TutorialLogic.Snapshot,
    resolveTarget: (targetId: string) -> BasePart?,
}

local TutorialController = {}

local _conn: RBXScriptConnection? = nil
local _elapsed = 0

function TutorialController.start(deps: Deps)
    if _conn then
        return
    end
    local player = Players.LocalPlayer
    local gui = UiScreen.ensure(player:WaitForChild("PlayerGui"), "TutorialSpotlight", "tutorial")
    TutorialBeam.start()
    TutorialSpotlight.start(gui)
    _conn = RunService.Heartbeat:Connect(function(dt)
        _elapsed += dt
        if _elapsed < 0.15 then
            return
        end
        _elapsed = 0
        local step = TutorialLogic.resolveStep(deps.getSnapshot())
        local def = TutorialLogic.getStep(step)
        if def == nil then
            TutorialBeam.setVisible(false)
            TutorialHint.hide()
            TutorialSpotlight.setTarget(nil)
            return
        end
        TutorialHint.show(def.hint)
        local target = deps.resolveTarget(def.target)
        TutorialBeam.setTarget(target)
        TutorialBeam.setVisible(target ~= nil)
        TutorialSpotlight.setTarget(target)
    end)
end

function TutorialController.stop()
    if _conn then
        _conn:Disconnect()
        _conn = nil
    end
    TutorialBeam.stop()
    TutorialHint.hide()
    TutorialSpotlight.stop()
end

return TutorialController
