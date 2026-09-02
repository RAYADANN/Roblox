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
local Toast = require(script.Parent.components.Toast)

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
	-- "Name · 1 in 216 · Mythic · 216 · expected · mult"
	local title, line, rarity, oneInRaw, expectedRaw, multRaw =
		string.match(payload, "^(.-)%s*·%s*(.-)%s*·%s*(.-)%s*·%s*(.-)%s*·%s*(.-)%s*·%s*(.-)%s*$")
	if title and line then
		return {
			title = title,
			line = line,
			rarity = rarity,
			oneIn = tonumber(oneInRaw),
			expectedOneIn = tonumber(expectedRaw),
			mult = tonumber(multRaw),
			token = os.clock(),
		}
	end
	local t4, l4, r4, o4 = string.match(payload, "^(.-)%s*·%s*(.-)%s*·%s*(.-)%s*·%s*(.-)%s*$")
	if t4 and l4 then
		return {
			title = t4,
			line = l4,
			rarity = r4,
			oneIn = tonumber(o4),
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

local function parseHatchBust(payload: string): HatchReveal.HatchPayload
	-- "fail · expected" or "burn · expected"
	local kind, expectedRaw = string.match(payload, "^(%w+)%s*·%s*(%d+)")
	local bust: ("fail" | "burn") = if kind == "burn" then "burn" else "fail"
	return {
		title = if bust == "burn" then "Burned" else "Failed",
		line = if bust == "burn" then "Parents destroyed" else "Parents returned",
		expectedOneIn = tonumber(expectedRaw),
		bust = bust,
		token = os.clock(),
	}
end

local function GameRoot(): React.Node
	local hud, setHud = React.useState(EMPTY_HUD)
	local toast, setToast = React.useState(nil :: string?)
	local toastTone, setToastTone = React.useState("info" :: Toast.Tone)
	local carryStatus, setCarryStatus = React.useState(nil :: string?)
	local carryStartedAt, setCarryStartedAt = React.useState(nil :: number?)
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
		rollPreviewToken = 0,
		stealAlertToken = 0,
		stealAlertMessage = nil :: string?,
	})
	local netRef = React.useRef(nil :: NetClient.NetClient?)
	local buildRef = React.useRef(nil :: BuildController.BuildController?)
	local previewRef = React.useRef("")
	local blockPreviewRef = React.useRef("")

	React.useEffect(function()
		if not toast then
			return
		end
		local clearThread = task.delay(2.5, function()
			setToast(nil)
		end)
		return function()
			pcall(task.cancel, clearThread)
		end
	end, { toast })

	React.useEffect(function()
		if not carryStatus or not carryStartedAt then
			return
		end
		local elapsed = math.max(0, os.clock() - carryStartedAt)
		local clearThread = task.delay(math.max(0, 90 - elapsed), function()
			setCarryStatus(nil)
			setCarryStartedAt(nil)
		end)
		return function()
			pcall(task.cancel, clearThread)
		end
	end, { carryStatus, carryStartedAt })

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
				local creatureKey = if payload.creaturePreview then payload.creaturePreview.templateId else ""
				local blockKey = if payload.blockPreview then payload.blockPreview.templateId else ""
				if (creatureKey ~= "" and creatureKey ~= previewRef.current)
					or (blockKey ~= "" and blockKey ~= blockPreviewRef.current)
				then
					setJuice(function(prev)
						local next = table.clone(prev)
						next.rollPreviewToken = prev.rollPreviewToken + 1
						return next
					end)
					UiSound.play("click")
				end
				previewRef.current = creatureKey
				blockPreviewRef.current = blockKey
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

				if kind == "hatch_bust" then
					setJuice(function(prev)
						local next = table.clone(prev)
						next.hatch = parseHatchBust(text)
						return next
					end)
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
					setToastTone("success")
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
					setToastTone("success")
					return
				end

				if kind == "error" then
					UiSound.play("fail")
					setToastTone("danger")
				elseif kind == "steal" then
					setToastTone("warning")
					if string.find(text, "^Carrying ") then
						setCarryStatus(text)
						setCarryStartedAt(os.clock())
					elseif text == "Deposited!" or text == "Carry lost" then
						setCarryStatus(nil)
						setCarryStartedAt(nil)
						setToastTone(if text == "Deposited!" then "success" else "warning")
					elseif string.find(text, "^Robbed!") then
						setToastTone("danger")
						setJuice(function(prev)
							local next = table.clone(prev)
							next.stealAlertToken = prev.stealAlertToken + 1
							next.stealAlertMessage = text
							return next
						end)
						UiSound.play("fail")
					end
				elseif kind == "lock" or kind == "bat" or kind == "breed" then
					setToastTone(if kind == "bat" then "success" else "info")
				else
					setToastTone("info")
				end

				setToast(text)
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
		toastTone = toastTone,
		carryStatus = carryStatus,
		carryStartedAt = carryStartedAt,
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
