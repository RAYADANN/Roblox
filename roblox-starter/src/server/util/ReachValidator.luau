--!strict

local ReachValidator = {}

function ReachValidator.isWithin(character: Model?, worldPos: Vector3, maxDist: number): boolean
	if not character then
		return false
	end
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return false
	end
	return (root.Position - worldPos).Magnitude <= maxDist
end

return ReachValidator
