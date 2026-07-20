--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local ViewportLayout = require(script.Parent.Parent.util.ViewportLayout)

export type LayoutMetrics = ViewportLayout.Metrics

local function useLayout(): LayoutMetrics
	local metrics, setMetrics = React.useState(ViewportLayout.getMetrics())

	React.useEffect(function()
		setMetrics(ViewportLayout.getMetrics())
		return ViewportLayout.subscribe(function()
			setMetrics(ViewportLayout.getMetrics())
		end)
	end, {})

	return metrics
end

return useLayout
