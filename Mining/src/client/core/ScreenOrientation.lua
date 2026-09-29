--!strict
-- ScreenOrientation.lua — принудительный ландшафт на телефонах.
--
-- Roblox управляет ориентацией через PlayerGui.ScreenOrientation (актуальный
-- поддерживаемый API; StarterGui.ScreenOrientation задаёт значение по умолчанию,
-- но НЕ меняет ориентацию у уже вошедших игроков — для них нужно свойство их
-- PlayerGui). Мы форсим LandscapeSensor только на телефонах, оставляя планшеты,
-- десктоп и консоль нетронутыми.
--
-- LandscapeSensor выбран намеренно: позволяет переворот между landscape-left и
-- landscape-right (удобно левшам), но блокирует портрет.
--
-- Переносимый модуль: без зависимостей от игровой логики (только ViewportLayout
-- для определения тира устройства).

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local ViewportLayout = require(script.Parent.Parent.ui.util.ViewportLayout)

local ScreenOrientation = {}

-- Телефон = сенсорный ввод без мыши И маленький экран (phone-тир по
-- ViewportLayout). Планшеты (tablet/desktop-тир) под условие не попадают, даже
-- если сенсорные, — на них портрет допустим.
local function isPhone(): boolean
	if not UserInputService.TouchEnabled then
		return false
	end
	if UserInputService.MouseEnabled then
		return false
	end
	return ViewportLayout.isPhone()
end

function ScreenOrientation.apply(): ()
	if not isPhone() then
		return
	end
	local plr = Players.LocalPlayer
	if not plr then
		return
	end
	local pg = plr:FindFirstChildOfClass("PlayerGui") or plr:WaitForChild("PlayerGui", 5)
	if not pg or not pg:IsA("PlayerGui") then
		return
	end
	pcall(function()
		pg.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor
	end)
end

return ScreenOrientation
