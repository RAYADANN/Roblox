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

function SafeArea.topInset(): number
	-- IgnoreGuiInset HUDs must clear CoreGui topbar + translation banner
	local topbar = GuiService.TopbarInset.Height
	local guiY = GuiService:GetGuiInset().Y
	return math.max(topbar, guiY, 36) + 8
end

function SafeArea.leftInset(): number
	return math.max(GuiService:GetGuiInset().X, GuiService.TopbarInset.Min.X)
end

return SafeArea
