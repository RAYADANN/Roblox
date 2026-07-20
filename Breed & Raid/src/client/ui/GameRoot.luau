--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local App = require(script.Parent.App)
local HatchReveal = require(script.Parent.components.HatchReveal)
local HudProvider = require(script.Parent.context.HudProvider)
local NetClient = require(script.Parent.Parent.net.NetClient)
local BuildController = require(script.Parent.Parent.core.BuildController)
local SessionTypes = require(ReplicatedStorage.shared.types.Session)
local UiSound = require(script.Parent.juice.UiSound)

type HudPayload = SessionTypes.HudPayload

local EMPTY_HUD: HudPayload = {
	cash = 0,
	buffer = 0,
	mps = 0,
	plotId = nil,
	creaturePreview = nil,
	blockPreview = nil,
	incubate = nil,
	lockUntil = 0,
	creatures = {},
	dirt = 0,
	spikes = 0,
	blocks = {},
	notify = nil,
}

local function parseHatch(payload: string): HatchReveal.HatchPayload
	-- "Name · 1 in 216 · Mythic · 216"
	local title, line, rarity, oneInRaw = string.match(payload, "^(.-)%s*·%s*(.-)%s*·%s*(.-)%s*·%s*(.-)%s*$")
	if title and line then
		return {
			title = title,
			line = line,
			rarity = rarity,
			oneIn = tonumber(oneInRaw),
			token = os.clock(),
		}
	end
	local t2, l2 = string.match(payload, "^(.-)%s*·%s*(.+)$")
	return {
		title = t2 or "Hybrid",
		line = l2 or payload,
		token = os.clock(),
	}
end

local function GameRoot(): React.Node
	local hud, setHud = React.useState(EMPTY_HUD)
	local toast, setToast = React.useState(nil :: string?)
	local breedOpen, setBreedOpen = React.useState(false)
	local selected, setSelected = React.useState({} :: { string })
	local buildMode, setBuildMode = React.useState(false)
	local buildBlock, setBuildBlock = React.useState("dirt")
	local juice, setJuice = React.useState({
		buyToken = 0,
		collectToken = 0,
		collectAmount = 0,
		cashPulse = 0,
		hatch = nil :: HatchReveal.HatchPayload?,
	})
	local netRef = React.useRef(nil :: NetClient.NetClient?)
	local buildRef = React.useRef(nil :: BuildController.BuildController?)

	React.useEffect(function()
		local net = NetClient.new()
		netRef.current = net
		local build = BuildController.new(net)
		buildRef.current = build
		build:onChanged(function(enabled, blockId)
			setBuildMode(enabled)
			setBuildBlock(blockId)
		end)
		build:start()

		local cleanups = {
			net:onHudSync(function(payload)
				setHud(payload)
				build:setInventory(payload.blocks or {})
			end),
			net:onNotify(function(payload)
				local kind = payload.kind
				local text = payload.payload

				if kind == "breed_ui" then
					setBreedOpen(true)
					return
				end

				if kind == "hatch" then
					setJuice(function(prev)
						local next = table.clone(prev)
						next.hatch = parseHatch(text)
						next.cashPulse = prev.cashPulse + 1
						return next
					end)
					-- Celebration owns the screen — skip duplicate toast
					return
				end

				if kind == "buy" then
					setJuice(function(prev)
						local next = table.clone(prev)
						next.buyToken = prev.buyToken + 1
						next.cashPulse = prev.cashPulse + 1
						return next
					end)
					setToast(text)
					task.delay(2.2, function()
						setToast(nil)
					end)
					return
				end

				if kind == "collect" then
					local amount = tonumber(text) or 0
					setJuice(function(prev)
						local next = table.clone(prev)
						next.collectToken = prev.collectToken + 1
						next.collectAmount = amount
						next.cashPulse = prev.cashPulse + 1
						return next
					end)
					setToast(`Collected ${text}`)
					task.delay(2.2, function()
						setToast(nil)
					end)
					return
				end

				if kind == "error" then
					UiSound.play("fail")
				end

				setToast(text)
				task.delay(2.5, function()
					setToast(nil)
				end)
			end),
		}
		return function()
			for _, cleanup in cleanups do
				cleanup()
			end
			build:destroy()
			net:destroy()
			netRef.current = nil
			buildRef.current = nil
		end
	end, {})

	local function withNet(fn: (NetClient.NetClient) -> ())
		local net = netRef.current
		if net then
			fn(net)
		end
	end

	local toggleSelect = React.useCallback(function(id: string)
		setSelected(function(prev)
			local nextList = table.clone(prev)
			local idx = table.find(nextList, id)
			if idx then
				table.remove(nextList, idx)
			else
				if #nextList >= 2 then
					table.remove(nextList, 1)
				end
				table.insert(nextList, id)
			end
			return nextList
		end)
	end, {})

	local startBreed = React.useCallback(function()
		if #selected < 2 then
			setToast("Pick 2 creatures")
			UiSound.play("fail")
			return
		end
		withNet(function(net)
			net:startBreed(selected[1], selected[2])
		end)
		setSelected({})
	end, { selected })

	local clearHatch = React.useCallback(function()
		setJuice(function(prev)
			local next = table.clone(prev)
			next.hatch = nil
			return next
		end)
	end, {})

	return React.createElement(HudProvider, {
		hud = hud,
		toast = toast,
		breedOpen = breedOpen,
		setBreedOpen = setBreedOpen,
		selected = selected,
		toggleSelect = toggleSelect,
		requestCollect = function()
			withNet(function(net)
				net:requestCollect()
			end)
		end,
		requestCreatureRoll = function()
			UiSound.play("click")
			withNet(function(net)
				net:requestCreatureRoll()
			end)
		end,
		confirmCreatureBuy = function()
			withNet(function(net)
				net:confirmCreatureBuy()
			end)
		end,
		requestBlockRoll = function()
			UiSound.play("click")
			withNet(function(net)
				net:requestBlockRoll()
			end)
		end,
		confirmBlockBuy = function()
			withNet(function(net)
				net:confirmBlockBuy()
			end)
		end,
		startBreed = startBreed,
		cancelBreed = function()
			withNet(function(net)
				net:cancelBreed()
			end)
		end,
		softSpeedBreed = function()
			withNet(function(net)
				net:softSpeedBreed()
			end)
		end,
		buildMode = buildMode,
		buildBlock = buildBlock,
		toggleBuildMode = function()
			local build = buildRef.current
			if build then
				build:toggle()
			end
		end,
	}, {
		App = React.createElement(App, {
			juice = juice,
			clearHatch = clearHatch,
		}),
	})
end

return GameRoot
