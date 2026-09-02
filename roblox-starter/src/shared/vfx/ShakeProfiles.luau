--!strict
-- Именованные профили camera shake. Pure — CI без Studio.

export type ShakeProfile = {
	amplitude: number,
	duration: number,
	roughness: number,
}

local ShakeProfiles = {
	Light = {
		amplitude = 0.08,
		duration = 0.12,
		roughness = 22,
	} :: ShakeProfile,
	Medium = {
		amplitude = 0.18,
		duration = 0.16,
		roughness = 28,
	} :: ShakeProfile,
	Heavy = {
		amplitude = 0.32,
		duration = 0.22,
		roughness = 36,
	} :: ShakeProfile,
}

function ShakeProfiles.resolve(name: string?): ShakeProfile?
	if name == nil then
		return nil
	end
	return ShakeProfiles[name]
end

return ShakeProfiles
