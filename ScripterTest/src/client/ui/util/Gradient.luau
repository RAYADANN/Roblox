--!strict
-- Build UIGradient props from theme GradientDef.
-- ColorSequence/NumberSequence require keypoints starting at 0 and ending at 1.

local React = require(game:GetService("ReplicatedStorage"):WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)

local function gradientElement(def: theme.GradientDef): React.Node
	local n = #def.stops
	assert(n >= 2, "GradientDef needs at least 2 stops")

	local colorKeys = table.create(n)
	local alphaKeys = table.create(n)
	for i, stop in def.stops do
		local t = stop.pos
		if i == 1 then
			t = 0
		elseif i == n then
			t = 1
		else
			t = math.clamp(t, 0, 1)
		end
		colorKeys[i] = ColorSequenceKeypoint.new(t, stop.color)
		alphaKeys[i] = NumberSequenceKeypoint.new(t, 1 - stop.alpha)
	end

	return React.createElement("UIGradient", {
		Color = ColorSequence.new(colorKeys),
		Transparency = NumberSequence.new(alphaKeys),
		Rotation = def.rotation,
	})
end

return {
	element = gradientElement,
}
