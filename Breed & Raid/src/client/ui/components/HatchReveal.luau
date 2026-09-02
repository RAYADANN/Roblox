--!strict
-- Hatch roulette — rarity reel → jackpot reel → slam oneIn. Predetermined by server.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)
local Flipper = require(ReplicatedStorage:WaitForChild("Packages").Flipper)

local FormatOneIn = require(ReplicatedStorage.shared.util.FormatOneIn)
local BreedLogic = require(ReplicatedStorage.shared.util.BreedLogic)
local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)
local MathFx = require(script.Parent.Parent.juice.MathFx)
local UiSound = require(script.Parent.Parent.juice.UiSound)
local MotionPresets = require(script.Parent.Parent.motion.MotionPresets)
local OrnateButton = require(script.Parent.OrnateButton)
local Icon = require(script.Parent.Icon)

export type HatchPayload = {
	title: string,
	line: string,
	rarity: string?,
	oneIn: number?,
	expectedOneIn: number?,
	mult: number?,
	bust: ("fail" | "burn")?,
	token: number,
}

export type Props = {
	payload: HatchPayload?,
	onDone: () -> (),
	onFuseAgain: (() -> ())?,
}

type Phase = "crack" | "rarity" | "mult" | "reveal" | "bust"

local RARITIES = { "Common", "Uncommon", "Rare", "Epic", "Mythic", "Secret" }
local MULTS = { 0.5, 1, 2, 5, 10 }
local CELL = 64

local function accentFor(rarity: string?, mult: number?): Color3
	if mult and mult >= 5 then
		return Color3.fromRGB(255, 210, 70)
	elseif mult and mult >= 2 then
		return Color3.fromRGB(255, 170, 60)
	elseif mult and mult < 1 then
		return Color3.fromRGB(160, 160, 180)
	end
	local key = string.lower(rarity or "")
	if key == "secret" then
		return Color3.fromRGB(255, 60, 100)
	elseif key == "mythic" then
		return Color3.fromRGB(255, 200, 60)
	elseif key == "epic" then
		return Color3.fromRGB(180, 100, 255)
	elseif key == "rare" then
		return Color3.fromRGB(80, 160, 255)
	elseif key == "uncommon" then
		return Color3.fromRGB(80, 200, 120)
	end
	return theme.Colors.goldHi
end

local function rarityIndex(name: string): number
	for i, r in RARITIES do
		if string.lower(r) == string.lower(name) then
			return i
		end
	end
	return 1
end

local function multIndex(mult: number): number
	for i, m in MULTS do
		if math.abs(m - mult) < 0.01 then
			return i
		end
	end
	return 2
end

local function buildStrip(items: { any }, targetIdx: number, spins: number): ({ any }, number)
	local strip = {}
	local n = #items
	for _ = 1, spins do
		for _, item in items do
			table.insert(strip, item)
		end
	end
	-- Near-miss: one full cycle past, then land on target (adds tension)
	for i = 1, n do
		table.insert(strip, items[i])
	end
	for i = 1, targetIdx do
		table.insert(strip, items[i])
	end
	local landIndex = #strip -- 1-based index of landing cell
	-- Extra padding below so strip can overshoot visually
	for i = 1, n do
		table.insert(strip, items[i])
	end
	return strip, landIndex
end

local function HatchReveal(props: Props): React.Node
	local layout = useLayout()
	local payload = props.payload
	local phase, setPhase = React.useState("crack" :: Phase)
	local reelY, setReelY = React.useState(0)
	local multY, setMultY = React.useState(0)
	local flashRarity, setFlashRarity = React.useState("Rare")
	local flashMult, setFlashMult = React.useState(1)
	local slam, setSlam = React.useState(0.2)
	local veil, setVeil = React.useState(1)
	local rootRef = React.useRef(nil :: Frame?)
	local closedRef = React.useRef(false)
	local spinningRef = React.useRef(true)
	local rarityStripRef = React.useRef(nil :: { any }?)
	local multStripRef = React.useRef(nil :: { number }?)
	local rarityLandRef = React.useRef(1)
	local multLandRef = React.useRef(1)
	local onDoneRef = React.useRef(props.onDone)
	local onFuseAgainRef = React.useRef(props.onFuseAgain)
	local layoutRef = React.useRef(layout)
	local actionsReady, setActionsReady = React.useState(false)
	onDoneRef.current = props.onDone
	onFuseAgainRef.current = props.onFuseAgain
	layoutRef.current = layout

	local function finish(fuseAgain: boolean)
		if closedRef.current then
			return
		end
		closedRef.current = true
		local onFuseAgain = onFuseAgainRef.current
		if fuseAgain and onFuseAgain then
			onFuseAgain()
		else
			onDoneRef.current()
		end
	end

	React.useEffect(function()
		if not payload then
			return
		end
		closedRef.current = false
		spinningRef.current = true
		setActionsReady(false)
		setPhase("crack")
		setReelY(0)
		setMultY(0)
		setSlam(0.2)
		setVeil(0.2)
		UiSound.play("hatch")

		local veilMotor = Flipper.SingleMotor.new(0.2, false)
		local cVeil = veilMotor:onStep(setVeil)
		veilMotor:start()
		veilMotor:setGoal(Flipper.Spring.new(0.4, MotionPresets.SPRING_GENTLE))

		local isBust = payload.bust ~= nil
		local targetRarity = payload.rarity or "Rare"
		local targetMult = payload.mult or 1
		local rStrip, rLand = buildStrip(RARITIES, rarityIndex(targetRarity), 5)
		local mStrip, mLand = buildStrip(MULTS, multIndex(targetMult), 4)
		rarityStripRef.current = rStrip
		multStripRef.current = mStrip
		rarityLandRef.current = rLand
		multLandRef.current = mLand

		local rarityMotor = Flipper.SingleMotor.new(0, false)
		local multMotor = Flipper.SingleMotor.new(0, false)
		local slamMotor = Flipper.SingleMotor.new(0.2, false)
		local cR = rarityMotor:onStep(function(v)
			setReelY(v)
			local idx = math.clamp(math.floor(-v / CELL) + 1, 1, #rStrip)
			local cell = rStrip[idx]
			if typeof(cell) == "string" then
				setFlashRarity(cell)
			end
		end)
		local cM = multMotor:onStep(function(v)
			setMultY(v)
			local idx = math.clamp(math.floor(-v / CELL) + 1, 1, #mStrip)
			local cell = mStrip[idx]
			if typeof(cell) == "number" then
				setFlashMult(cell)
			end
		end)
		local cS = slamMotor:onStep(setSlam)
		rarityMotor:start()
		multMotor:start()
		slamMotor:start()

		local tickConn: RBXScriptConnection? = nil
		local lastTick = 0
		tickConn = RunService.Heartbeat:Connect(function()
			if not spinningRef.current then
				return
			end
			local now = os.clock()
			if now - lastTick > 0.14 then
				lastTick = now
				UiSound.play("click")
			end
		end)

		local threads: { thread } = {}
		local function later(sec: number, fn: () -> ())
			table.insert(threads, task.delay(sec, fn))
		end

		-- Phase: crack suspense
		later(1.1, function()
			if closedRef.current then
				return
			end
			if isBust then
				setPhase("bust")
				-- Short doom spin then land fail/burn
				local bustItems = { "Common", "Rare", "Epic", "Mythic", "FAIL", "BURN" }
				local landName = if payload.bust == "burn" then "BURN" else "FAIL"
				local landIdx = if landName == "BURN" then 6 else 5
				local bStrip, bLand = buildStrip(bustItems, landIdx, 4)
				rarityStripRef.current = bStrip
				rarityLandRef.current = bLand
				local targetY = -((bLand - 1) * CELL)
				rarityMotor:setGoal(Flipper.Spring.new(targetY, { frequency = 2.2, dampingRatio = 0.85 }))
				later(2.4, function()
					setFlashRarity(landName)
					spinningRef.current = false
					setActionsReady(true)
					local root = rootRef.current
					if root then
						MathFx.shockwave(root, Color3.fromRGB(200, 60, 80), layoutRef.current.px(240), 0.45)
					end
					UiSound.play("fail")
				end)
			else
				setPhase("rarity")
				local targetY = -((rLand - 1) * CELL)
				-- Fast spin then spring land
				rarityMotor:setGoal(Flipper.Spring.new(targetY * 0.35, { frequency = 6, dampingRatio = 1 }))
				later(0.35, function()
					rarityMotor:setGoal(Flipper.Spring.new(targetY, { frequency = 2.4, dampingRatio = 0.78 }))
				end)
			end
		end)

		if not isBust then
			later(3.6, function()
				if closedRef.current then
					return
				end
				setPhase("mult")
				setFlashRarity(targetRarity)
				local root = rootRef.current
				if root then
					MathFx.burstDots(root, accentFor(targetRarity, nil), 12)
				end
				local targetY = -((mLand - 1) * CELL)
				multMotor:setGoal(Flipper.Spring.new(targetY * 0.4, { frequency = 6, dampingRatio = 1 }))
				later(0.3, function()
					multMotor:setGoal(Flipper.Spring.new(targetY, { frequency = 2.5, dampingRatio = 0.8 }))
				end)
			end)

			later(6.0, function()
				if closedRef.current then
					return
				end
				setPhase("reveal")
				spinningRef.current = false
				setFlashMult(targetMult)
				setActionsReady(true)
				slamMotor:setGoal(Flipper.Spring.new(1.2, MotionPresets.SPRING_BOUNCY))
				local root = rootRef.current
				local accent = accentFor(targetRarity, targetMult)
				if root then
					MathFx.auraPulse(root, accent)
					MathFx.confetti(root, if targetMult >= 5 then 52 elseif targetMult >= 2 then 40 else 28)
					MathFx.shockwave(root, accent, layoutRef.current.px(300), 0.55)
					if targetMult >= 2 then
						MathFx.goldFlash(root)
					end
				end
				UiSound.play("hatch")
				later(0.35, function()
					slamMotor:setGoal(Flipper.Spring.new(1, MotionPresets.SPRING_SNAPPY))
				end)
			end)
		end

		local safety = task.delay(18, function()
			finish(false)
		end)

		return function()
			pcall(task.cancel, safety)
			for _, t in threads do
				pcall(task.cancel, t)
			end
			if tickConn then
				tickConn:Disconnect()
			end
			cVeil:disconnect()
			cR:disconnect()
			cM:disconnect()
			cS:disconnect()
			veilMotor:destroy()
			rarityMotor:destroy()
			multMotor:destroy()
			slamMotor:destroy()
		end
		-- phase intentionally omitted from deps; sequence is driven by token
	end, { if payload then payload.token else 0 })

	if not payload then
		return React.createElement(React.Fragment)
	end

	local isBust = payload.bust ~= nil
	local accent = accentFor(payload.rarity, payload.mult)
	local rarityStrip = rarityStripRef.current or RARITIES
	local multStrip = multStripRef.current or MULTS
	local cardFit = layout.modalFitScale(460, 540)
	local centerX = layout.safeLeft + (layout.viewport.X - layout.safeLeft - layout.safeRight) / 2
	local centerY = layout.safeTop + (layout.viewport.Y - layout.safeTop - layout.safeBottom) / 2

	local function reelCells(strip: { any }, offset: number, colorFn: (any) -> Color3): { [string]: React.Node }
		local nodes: { [string]: React.Node } = {}
		for i, item in strip do
			local label = if typeof(item) == "number"
				then (if item < 1 then "WHIFF ×0.5" elseif item == 1 then "×1" else `×{item}`)
				else tostring(item)
			nodes["c" .. i] = React.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, CELL),
				Position = UDim2.fromOffset(0, (i - 1) * CELL + offset),
				BackgroundTransparency = 1,
				Text = string.upper(label),
				TextSize = layout.text(22),
				Font = theme.Font.heavy,
				TextColor3 = colorFn(item),
				ZIndex = 104,
			})
		end
		return nodes
	end

	local phaseTitle = if phase == "crack"
		then "EGG CRACKING…"
		elseif phase == "rarity"
		then "ROLLING RARITY…"
		elseif phase == "mult"
		then "JACKPOT SPIN…"
		elseif phase == "bust"
		then "OUTCOME…"
		else (if (payload.mult or 1) >= 2 then "JACKPOT HATCH!" else "YOU HATCHED")

	return React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = theme.Surface.overlay,
		BackgroundTransparency = veil,
		BorderSizePixel = 0,
		ZIndex = 100,
	}, {
		Blocker = React.createElement("TextButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			Active = true,
			ZIndex = 100,
			[React.Event.Activated] = function()
				if actionsReady then
					finish(false)
				end
			end,
		}),
		Card = React.createElement("Frame", {
			ref = rootRef,
			Size = UDim2.fromOffset(layout.px(460), layout.px(540)),
			Position = UDim2.fromOffset(centerX, centerY),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = theme.Surface.base,
			BorderSizePixel = 0,
			ZIndex = 101,
		}, {
			Fit = React.createElement("UIScale", { Scale = cardFit }),
			Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.lg }),
			Stroke = React.createElement("UIStroke", {
				Color = accent,
				Thickness = 4,
				Transparency = 0.1,
			}),
			Eyebrow = React.createElement("TextLabel", {
				Size = UDim2.new(1, -layout.px(32), 0, layout.px(28)),
				Position = UDim2.fromOffset(layout.px(16), layout.px(16)),
				BackgroundTransparency = 1,
				Text = phaseTitle,
				TextSize = layout.text(18),
				Font = theme.Font.heavy,
				TextColor3 = accent,
				ZIndex = 103,
			}),
			Expected = if payload.expectedOneIn
				then React.createElement("TextLabel", {
					Size = UDim2.new(1, -layout.px(32), 0, layout.px(18)),
					Position = UDim2.fromOffset(layout.px(16), layout.px(44)),
					BackgroundTransparency = 1,
					Text = `Base fuse ~ {FormatOneIn(payload.expectedOneIn)}`,
					TextSize = layout.text(12),
					Font = theme.Font.body,
					TextColor3 = theme.Content.secondary,
					ZIndex = 103,
				})
				else nil,

			-- Crack suspense
			Crack = if phase == "crack"
				then React.createElement(Icon, {
					name = "egg",
					size = 96,
					color = theme.Action.reward,
					position = UDim2.new(0.5, 0, 0, layout.px(120)),
					anchorPoint = Vector2.new(0.5, 0),
					zIndex = 106,
				})
				else nil,

			-- Rarity window
			RarityWindow = React.createElement("Frame", {
				Size = UDim2.fromOffset(layout.px(320), CELL * 3),
				Position = UDim2.new(0.5, 0, 0, layout.px(78)),
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundColor3 = theme.Surface.sunken,
				BorderSizePixel = 0,
				ClipsDescendants = true,
				ZIndex = 102,
				Visible = phase == "rarity" or phase == "bust" or phase == "mult",
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.md }),
				Stroke = React.createElement("UIStroke", {
					Color = accentFor(flashRarity, nil),
					Thickness = 2,
				}),
				Strip = React.createElement("Frame", {
					Size = UDim2.new(1, 0, 0, #rarityStrip * CELL),
					BackgroundTransparency = 1,
					ZIndex = 103,
				}, reelCells(rarityStrip, reelY + CELL, function(item)
					if typeof(item) == "string" then
						if item == "FAIL" or item == "BURN" then
							return Color3.fromRGB(255, 80, 90)
						end
						return accentFor(item, nil)
					end
					return theme.Colors.goldHi
				end)),
				CenterBand = React.createElement("Frame", {
					Size = UDim2.new(1, 0, 0, CELL),
					Position = UDim2.new(0, 0, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = accentFor(flashRarity, nil),
					BackgroundTransparency = 0.78,
					BorderSizePixel = 0,
					ZIndex = 105,
				}, {
					Top = React.createElement("Frame", {
						Size = UDim2.new(1, 0, 0, 2),
						BackgroundColor3 = accentFor(flashRarity, nil),
						BorderSizePixel = 0,
					}),
					Bot = React.createElement("Frame", {
						Size = UDim2.new(1, 0, 0, 2),
						Position = UDim2.new(0, 0, 1, -2),
						BackgroundColor3 = accentFor(flashRarity, nil),
						BorderSizePixel = 0,
					}),
				}),
			}),

			-- Mult window (during mult phase, stacked under rarity or replace)
			MultWindow = if phase == "mult" or phase == "reveal"
				then React.createElement("Frame", {
					Size = UDim2.fromOffset(layout.px(280), CELL * 3),
					Position = UDim2.new(0.5, 0, 0, layout.px(if phase == "reveal" then 78 else 290)),
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundColor3 = theme.Surface.sunken,
					BorderSizePixel = 0,
					ClipsDescendants = true,
					ZIndex = 102,
					Visible = phase == "mult",
				}, {
					Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.md }),
					Stroke = React.createElement("UIStroke", {
						Color = accentFor(nil, flashMult),
						Thickness = 2,
					}),
					Strip = React.createElement("Frame", {
						Size = UDim2.new(1, 0, 0, #multStrip * CELL),
						BackgroundTransparency = 1,
						ZIndex = 103,
					}, reelCells(multStrip, multY + CELL, function(item)
						return accentFor(nil, if typeof(item) == "number" then item else 1)
					end)),
					CenterBand = React.createElement("Frame", {
						Size = UDim2.new(1, 0, 0, CELL),
						Position = UDim2.new(0, 0, 0.5, 0),
						AnchorPoint = Vector2.new(0, 0.5),
						BackgroundColor3 = accentFor(nil, flashMult),
						BackgroundTransparency = 0.78,
						BorderSizePixel = 0,
						ZIndex = 105,
					}),
				})
				else nil,

			-- Final reveal
			Reveal = if phase == "reveal"
				then React.createElement("Frame", {
					Size = UDim2.new(1, -layout.px(24), 0, layout.px(280)),
					Position = UDim2.new(0.5, 0, 0, layout.px(70)),
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundTransparency = 1,
					ZIndex = 106,
				}, {
					Banner = React.createElement("TextLabel", {
						Size = UDim2.new(1, 0, 0, layout.px(28)),
						BackgroundColor3 = accent,
						BackgroundTransparency = 0.2,
						Text = BreedLogic.mutateLabel(payload.mult or 1),
						TextSize = layout.text(16),
						Font = theme.Font.heavy,
						TextColor3 = theme.Content.primary,
						ZIndex = 107,
					}, {
						Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.chip }),
					}),
					Title = React.createElement("TextLabel", {
						Size = UDim2.new(1, 0, 0, layout.px(36)),
						Position = UDim2.fromOffset(0, layout.px(40)),
						BackgroundTransparency = 1,
						Text = string.upper(payload.title),
						TextSize = layout.text(24),
						Font = theme.Font.display,
						TextColor3 = theme.Content.primary,
						ZIndex = 107,
					}),
					Rarity = React.createElement("TextLabel", {
						Size = UDim2.new(1, 0, 0, layout.px(26)),
						Position = UDim2.fromOffset(0, layout.px(78)),
						BackgroundTransparency = 1,
						Text = payload.rarity or flashRarity,
						TextSize = layout.text(20),
						Font = theme.Font.title,
						TextColor3 = accent,
						ZIndex = 107,
					}),
					Odds = React.createElement("TextLabel", {
						Size = UDim2.new(1, 0, 0, layout.px(56)),
						Position = UDim2.fromOffset(0, layout.px(120)),
						BackgroundTransparency = 1,
						Text = if payload.oneIn then FormatOneIn(payload.oneIn) else payload.line,
						TextSize = layout.text(40),
						Font = theme.Font.heavy,
						TextColor3 = theme.Content.primary,
						ZIndex = 107,
					}, {
						Scale = React.createElement("UIScale", { Scale = slam }),
					}),
					Sub = React.createElement("TextLabel", {
						Size = UDim2.new(1, 0, 0, layout.px(20)),
						Position = UDim2.fromOffset(0, layout.px(184)),
						BackgroundTransparency = 1,
						Text = if payload.expectedOneIn
							then `from {FormatOneIn(payload.expectedOneIn)} base`
							else "",
						TextSize = layout.text(13),
						Font = theme.Font.body,
						TextColor3 = theme.Content.secondary,
						ZIndex = 107,
					}),
				})
				else nil,

			BustCopy = if phase == "bust" and isBust
				then React.createElement("TextLabel", {
					Size = UDim2.new(1, -layout.px(40), 0, layout.px(48)),
					Position = UDim2.new(0.5, 0, 1, -layout.px(120)),
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundTransparency = 1,
					Text = if payload.bust == "burn"
						then "Burned! Parents gone — fuse again for the chase."
						else "Failed — parents returned. Try another fuse.",
					TextSize = layout.text(14),
					Font = theme.Font.body,
					TextColor3 = Color3.fromRGB(255, 180, 180),
					TextWrapped = true,
					ZIndex = 107,
				})
				else nil,

			Actions = if actionsReady
				then React.createElement("Frame", {
					Size = UDim2.new(1, -layout.px(32), 0, layout.px(44)),
					Position = UDim2.new(0.5, 0, 1, -layout.px(58)),
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundTransparency = 1,
					ZIndex = 110,
				}, {
					List = React.createElement("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						Padding = UDim.new(0, layout.gap(10)),
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
					}),
					Fuse = React.createElement(OrnateButton, {
						text = "Fuse Again",
						variant = "jade",
						onClick = function()
							finish(true)
						end,
						width = 140,
					}),
					Continue = React.createElement(OrnateButton, {
						text = "Continue",
						variant = "ghost",
						onClick = function()
							finish(false)
						end,
						width = 120,
					}),
				})
				else React.createElement("TextLabel", {
					Size = UDim2.new(1, -layout.px(24), 0, layout.px(20)),
					Position = UDim2.new(0.5, 0, 1, -layout.px(40)),
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundTransparency = 1,
					Text = "Don't look away…",
					TextSize = layout.text(13),
					Font = theme.Font.body,
					TextColor3 = theme.Content.secondary,
					ZIndex = 103,
				}),
		}),
	})
end

return HatchReveal
