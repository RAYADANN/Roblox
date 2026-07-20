--!strict

local UserInputService = game:GetService("UserInputService")

local ScreenOrientation = {}

function ScreenOrientation.apply()
	if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
		-- Landscape на телефонах (mining/sim жанр)
		local ok, err = pcall(function()
			(UserInputService :: any):SetScreenOrientation(Enum.ScreenOrientation.LandscapeSensor)
		end)
		if not ok then
			warn(`[ScreenOrientation] {err}`)
		end
	end
end

return ScreenOrientation
