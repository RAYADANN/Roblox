--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local HudContext = require(script.Parent.HudContext)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)

export type Props = {
	children: React.Node,
	hud: NetTypes.HudSyncPayload,
	achievementsOpen: boolean,
	setAchievementsOpen: (open: boolean) -> (),
}

local function HudProvider(props: Props): React.Node
	local value = React.useMemo(function()
		return {
			hud = props.hud,
			achievementsOpen = props.achievementsOpen,
			setAchievementsOpen = props.setAchievementsOpen,
		}
	end, { props.hud, props.achievementsOpen, props.setAchievementsOpen } :: { any })

	return React.createElement(HudContext.Provider, { value = value }, props.children)
end

return HudProvider
