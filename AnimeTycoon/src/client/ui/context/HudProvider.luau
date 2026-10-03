--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local HudContext = require(script.Parent.HudContext)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)

export type Props = {
    children: React.Node,
    hud: NetTypes.HudSyncPayload,
    buyUpgrade: (upgradeId: string) -> (),
    onBoostOffer: ((offerId: string) -> ())?,
    onBoostOfferSeen: (() -> ())?,
}

local function HudProvider(props: Props): React.Node
    local value = React.useMemo(function()
        return {
            hud = props.hud,
            buyUpgrade = props.buyUpgrade,
            onBoostOffer = props.onBoostOffer,
            onBoostOfferSeen = props.onBoostOfferSeen,
        }
    end, { props.hud, props.buyUpgrade, props.onBoostOffer, props.onBoostOfferSeen })

    return React.createElement(HudContext.Provider, { value = value }, props.children)
end

return HudProvider
