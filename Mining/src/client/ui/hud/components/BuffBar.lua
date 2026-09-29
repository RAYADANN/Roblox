--!strict
-- Панель активных бафов — левый нижний угол.
-- Показывает бонусы питомцев, временные предметные бусты и VIP.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage:WaitForChild("Packages").Fusion)

local ScopeFactory   = require(script.Parent.Parent.ScopeFactory)
local HudStateModule = require(script.Parent.Parent.HudState)
local BuffLogic      = require(script.Parent.Parent.util.BuffLogic)
local BuffSlot       = require(script.Parent.BuffSlot)
local ViewportLayout = require(script.Parent.Parent.Parent.util.ViewportLayout)

local Children = Fusion.Children
local peek     = Fusion.peek

local BuffBar = {}

function BuffBar.create(s: ScopeFactory.HudScope, state: HudStateModule.HudState)
	local timers: { [string]: any } = {}
	local serverRemaining: { [string]: number } = {}

	local entriesView = s:Computed(function(use)
		local gp = use(state.gamepasses)
		return BuffLogic.collect(use(state.petEffects), use(state.activeBoosts), gp)
	end)

	local visible = s:Computed(function(use)
		return #use(entriesView) > 0
	end)

	local dockBottom = s:Value(ViewportLayout.dockRowBottom())
	local leftPad = s:Value(ViewportLayout.buffBarLeftPad())
	local slotW = s:Value(ViewportLayout.buffSlotPx())
	local gap = s:Value(ViewportLayout.px(6))
	ViewportLayout.subscribe(function()
		dockBottom:set(ViewportLayout.dockRowBottom())
		leftPad:set(ViewportLayout.buffBarLeftPad())
		slotW:set(ViewportLayout.buffSlotPx())
		gap:set(ViewportLayout.px(6))
	end, s)

	local slotChildren = s:Computed(function(use)
		local entries = use(entriesView)
		local children: { Instance } = {
			s:New("UIListLayout")({
				FillDirection     = Enum.FillDirection.Horizontal,
				Padding           = s:Computed(function(innerUse)
					return UDim.new(0, innerUse(gap))
				end),
				SortOrder         = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
			}),
		}
		for _, entry in ipairs(entries) do
			local remVal = nil
			if entry.remaining and entry.remaining > 0 then
				local existing = timers[entry.id]
				if not existing then
					existing = s:Value(entry.remaining)
					timers[entry.id] = existing
					serverRemaining[entry.id] = entry.remaining
				elseif serverRemaining[entry.id] ~= entry.remaining then
					serverRemaining[entry.id] = entry.remaining
					existing:set(entry.remaining)
				end
				remVal = existing
			end
			children[#children + 1] = BuffSlot.create(s, entry, remVal, slotW)
		end
		return children
	end)

	-- Локальный отсчёт таймеров (раз в секунду).
	local heartbeatConn: RBXScriptConnection? = nil
	local lastTick = os.clock()
	heartbeatConn = RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if now - lastTick < 1 then return end
		lastTick = now
		for _, timerVal in pairs(timers) do
			local cur = peek(timerVal) or 0
			if cur > 0 then
				timerVal:set(math.max(0, cur - 1))
			end
		end
	end)
	table.insert(s, function()
		if heartbeatConn then
			heartbeatConn:Disconnect()
			heartbeatConn = nil
		end
	end)

	local barHeight = s:Computed(function(use)
		return math.floor(use(slotW) * (62 / 54) + 0.5)
	end)

	return s:New("Frame")({
		Name             = "BuffBar",
		Size             = s:Computed(function(use)
			local n = #use(entriesView)
			if n == 0 then return UDim2.fromOffset(0, 0) end
			local sw = use(slotW)
			local g = use(gap)
			return UDim2.fromOffset(n * sw + math.max(0, n - 1) * g, use(barHeight))
		end),
		Position         = s:Computed(function(use)
			local rowBottom = use(dockBottom)
			local h = use(barHeight)
			return UDim2.new(0, use(leftPad), 1, -(rowBottom + h))
		end),
		AnchorPoint      = Vector2.new(0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel  = 0,
		Visible          = visible,
		ZIndex           = 7,
		[Children] = slotChildren,
	})
end

return BuffBar
