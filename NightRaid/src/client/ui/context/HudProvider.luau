--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local HudContext = require(script.Parent.HudContext)

export type Props = {
	children: React.Node?,
	value: HudContext.HudContextValue,
}

local function HudProvider(props: Props): React.Node
	return React.createElement(HudContext.Provider, { value = props.value }, props.children)
end

return HudProvider
