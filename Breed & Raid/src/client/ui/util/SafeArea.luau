--!strict

local GuiService = game:GetService("GuiService")

export type Cleanup = () -> ()

local SafeArea = {}

local _listeners: { () -> () } = {}
local _conn: RBXScriptConnection? = nil

local function notify()
	for _, listener in _listeners do
		listener()
	end
end

function SafeArea.start()
	if _conn then
		return
	end
	_conn = GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(notify)
end

function SafeArea.subscribe(listener: () -> ()): Cleanup
	table.insert(_listeners, listener)
	SafeArea.start()
	return function()
		local index = table.find(_listeners, listener)
		if index then
			table.remove(_listeners, index)
		end
	end
end

function SafeArea.insets(): (number, number, number, number)
	-- ScreenGui uses ScreenInsets.None so overlays can cover the whole display.
	-- Derive the Core UI safe rectangle relative to that full-screen space.
	local noneRect = GuiService:GetInsetArea(Enum.ScreenInsets.None)
	local coreRect = GuiService:GetInsetArea(Enum.ScreenInsets.CoreUISafeInsets)
	local left = math.max(0, coreRect.Min.X - noneRect.Min.X)
	local top = math.max(0, coreRect.Min.Y - noneRect.Min.Y)
	local right = math.max(0, noneRect.Max.X - coreRect.Max.X)
	local bottom = math.max(0, noneRect.Max.Y - coreRect.Max.Y)
	return left, top, right, bottom
end

function SafeArea.topInset(): number
	local _, top = SafeArea.insets()
	return top
end

function SafeArea.leftInset(): number
	local left = SafeArea.insets()
	return left
end

function SafeArea.rightInset(): number
	local _, _, right = SafeArea.insets()
	return right
end

function SafeArea.bottomInset(): number
	local _, _, _, bottom = SafeArea.insets()
	return bottom
end

return SafeArea
