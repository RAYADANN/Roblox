--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local HudContext = require(script.Parent.HudContext)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)

export type Props = {
    children: React.Node,
    hud: NetTypes.HudSyncPayload,
    buyUpgrade: (upgradeId: string) -> (),
    onMoneyOffer: ((productId: number) -> ())?,
    onExclusiveOffer: ((offerId: string) -> ())?,
    rebirthOpen: boolean?,
    setRebirthOpen: ((open: boolean) -> ())?,
    indexOpen: boolean?,
    setIndexOpen: ((open: boolean) -> ())?,
    requestRebirth: (() -> ())?,
    onSkipRebirth: (() -> ())?,
    tutorialOpen: boolean?,
    tutorialStep: number?,
    startTutorial: (() -> ())?,
    advanceTutorial: (() -> ())?,
    skipTutorial: (() -> ())?,
}

local function HudProvider(props: Props): React.Node
    local onMoneyOffer = props.onMoneyOffer
    local onExclusiveOffer = props.onExclusiveOffer
    local setRebirthOpen = props.setRebirthOpen
    local setIndexOpen = props.setIndexOpen
    local requestRebirth = props.requestRebirth
    local onSkipRebirth = props.onSkipRebirth
    local startTutorial = props.startTutorial
    local advanceTutorial = props.advanceTutorial
    local skipTutorial = props.skipTutorial
    local value = React.useMemo(function()
        return {
            hud = props.hud,
            buyUpgrade = props.buyUpgrade,
            onMoneyOffer = onMoneyOffer or function(_productId: number) end,
            onExclusiveOffer = onExclusiveOffer or function(_offerId: string) end,
            rebirthOpen = props.rebirthOpen == true,
            setRebirthOpen = setRebirthOpen or function(_open: boolean) end,
            indexOpen = props.indexOpen == true,
            setIndexOpen = setIndexOpen or function(_open: boolean) end,
            requestRebirth = requestRebirth or function() end,
            onSkipRebirth = onSkipRebirth or function() end,
            tutorialOpen = props.tutorialOpen == true,
            tutorialStep = props.tutorialStep or 1,
            startTutorial = startTutorial or function() end,
            advanceTutorial = advanceTutorial or function() end,
            skipTutorial = skipTutorial or function() end,
        }
    end, {
        props.hud,
        props.buyUpgrade,
        onMoneyOffer,
        onExclusiveOffer,
        props.rebirthOpen,
        setRebirthOpen,
        props.indexOpen,
        setIndexOpen,
        requestRebirth,
        onSkipRebirth,
        props.tutorialOpen,
        props.tutorialStep,
        startTutorial,
        advanceTutorial,
        skipTutorial,
    })

    return React.createElement(HudContext.Provider, { value = value }, props.children)
end

return HudProvider
