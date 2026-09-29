--!strict
-- Farm HUD (screen Scale) + Aim Map-style modal portals (Rebirth / Index).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)
local ReactRoblox = require(ReplicatedStorage:WaitForChild("Packages").ReactRoblox)

local DesignRoot = require(script.Parent.DesignRoot)
local FarmHud = require(script.Parent.components.FarmHud)
local HudContext = require(script.Parent.context.HudContext)
local IndexPanel = require(script.Parent.components.IndexPanel)
local ModalCameraJuice = require(script.Parent.Parent.core.ModalCameraJuice)
local ModalHost = require(script.Parent.util.ModalHost)
local ModalScrim = require(script.Parent.components.ModalScrim)
local RebirthPanel = require(script.Parent.components.RebirthPanel)
local Tutorial = require(script.Parent.components.Tutorial)
local TutorialHost = require(script.Parent.util.TutorialHost)
local TutorialSpotlight = require(script.Parent.util.TutorialSpotlight)
local adapt = require(script.Parent.adapt)

local function App(): React.Node
    local ctx = React.useContext(HudContext)
    local anyModalOpen = ctx.rebirthOpen or ctx.indexOpen

    React.useEffect(function()
        if ctx.tutorialOpen then
            TutorialSpotlight.bind(TutorialHost.spotlight(), ctx.tutorialStep)
        else
            TutorialSpotlight.unbind()
        end
    end, { ctx.tutorialOpen, ctx.tutorialStep })

    React.useEffect(function()
        return function()
            TutorialSpotlight.unbind()
        end
    end, {})

    React.useEffect(function()
        ModalCameraJuice.setOpen(anyModalOpen)
        return function()
            if anyModalOpen then
                ModalCameraJuice.setOpen(false)
            end
        end
    end, { anyModalOpen })

    React.useEffect(function()
        local conn = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then
                return
            end
            if input.KeyCode ~= Enum.KeyCode.Escape then
                return
            end
            if ctx.tutorialOpen then
                ctx.skipTutorial()
            elseif ctx.rebirthOpen then
                ctx.setRebirthOpen(false)
            elseif ctx.indexOpen then
                ctx.setIndexOpen(false)
            end
        end)
        return function()
            conn:Disconnect()
        end
    end, {
        ctx.tutorialOpen,
        ctx.skipTutorial,
        ctx.rebirthOpen,
        ctx.setRebirthOpen,
        ctx.indexOpen,
        ctx.setIndexOpen,
    })

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, {
        -- FarmHud is authored as screen Scale (StarterGui.HUD), not DesignRoot canvas.
        Hud = React.createElement(FarmHud),
        Tutorial = if ctx.tutorialOpen
            then ReactRoblox.createPortal(
                React.createElement(Tutorial, {
                    step = ctx.tutorialStep,
                    onNext = ctx.advanceTutorial,
                    onSkip = ctx.skipTutorial,
                }),
                TutorialHost.get()
            )
            else nil,

        Rebirth = if ctx.rebirthOpen
            then ReactRoblox.createPortal(
                React.createElement("Frame", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ZIndex = 20,
                }, {
                    Scrim = React.createElement(ModalScrim, {
                        onActivated = function()
                            ctx.setRebirthOpen(false)
                        end,
                    }),
                    Root = React.createElement("Frame", {
                        Size = UDim2.fromScale(1, 1),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        ZIndex = 2,
                    }, {
                        Design = React.createElement(DesignRoot, {
                            config = adapt.DEFAULT,
                        }, {
                            Panel = React.createElement(RebirthPanel, {
                                coins = ctx.hud.coins,
                                rebirths = ctx.hud.rebirths,
                                onClose = function()
                                    ctx.setRebirthOpen(false)
                                end,
                                onRebirth = function()
                                    ctx.requestRebirth()
                                end,
                                onSkip = function()
                                    ctx.onSkipRebirth()
                                end,
                            }),
                        }),
                    }),
                }),
                ModalHost.get()
            )
            else nil,

        Index = if ctx.indexOpen
            then ReactRoblox.createPortal(
                React.createElement("Frame", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ZIndex = 20,
                }, {
                    Scrim = React.createElement(ModalScrim, {
                        onActivated = function()
                            ctx.setIndexOpen(false)
                        end,
                    }),
                    Root = React.createElement("Frame", {
                        Size = UDim2.fromScale(1, 1),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        ZIndex = 2,
                    }, {
                        Design = React.createElement(DesignRoot, {
                            config = adapt.DEFAULT,
                        }, {
                            Panel = React.createElement(IndexPanel, {
                                onClose = function()
                                    ctx.setIndexOpen(false)
                                end,
                            }),
                        }),
                    }),
                }),
                ModalHost.get()
            )
            else nil,
    })
end

return App
