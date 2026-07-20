--!strict

--[[
	Roll modal — Instance-backed overlay (not React host children).
	React-Lua text/buttons were invisible in Studio viewport; raw Instances paint correctly.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

export type RollOffer = {
	kind: "block" | "pet"?,
	id: string?,
	petId: string?, -- legacy
	displayName: string,
	rarity: string,
	oneIn: number,
	buyCost: number,
	grantQty: number?,
	spinCost: number,
	animating: boolean,
	cleared: boolean?,
}

export type Props = {
	offer: RollOffer?,
	onBuy: () -> (),
	onSpinAgain: () -> (),
	onClose: () -> (),
}

local RARITY_COLOR = {
	Common = Color3.fromRGB(200, 210, 230),
	Uncommon = Color3.fromRGB(80, 220, 120),
	Rare = Color3.fromRGB(90, 170, 255),
	Epic = Color3.fromRGB(200, 120, 255),
	Mythic = Color3.fromRGB(255, 90, 130),
}

local SPIN_NAMES = { "Scrap Pup", "Copper Cat", "Glow Fox", "Volt Owl", "Night Hound", "Void Drake" }

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function label(parent: Instance, props: { [string]: any }): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.BorderSizePixel = 0
	l.Font = Enum.Font.SourceSansBold
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextSize = 20
	l.ZIndex = 5
	for k, v in props do
		(l :: any)[k] = v
	end
	l.Parent = parent
	return l
end

local function button(parent: Instance, props: { [string]: any }, onClick: () -> ()): TextButton
	local b = Instance.new("TextButton")
	b.BorderSizePixel = 0
	b.Font = Enum.Font.SourceSansBold
	b.TextColor3 = Color3.new(1, 1, 1)
	b.TextSize = 20
	b.AutoButtonColor = true
	b.ZIndex = 5
	for k, v in props do
		(b :: any)[k] = v
	end
	corner(b, 8)
	b.MouseButton1Click:Connect(onClick)
	b.Parent = parent
	return b
end

local function destroyOverlay()
	local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
	if not pg then
		return
	end
	local existing = pg:FindFirstChild("NightRaidRollOverlay")
	if existing then
		existing:Destroy()
	end
end

local function mountOverlay(
	offer: RollOffer,
	showResult: boolean,
	tick: number,
	onBuy: () -> (),
	onSpinAgain: () -> (),
	onClose: () -> ()
)
	destroyOverlay()
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui

	local gui = Instance.new("ScreenGui")
	gui.Name = "NightRaidRollOverlay"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 200
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = pg

	local dimmer = Instance.new("TextButton")
	dimmer.Name = "Dimmer"
	dimmer.Size = UDim2.fromScale(1, 1)
	dimmer.BackgroundColor3 = Color3.new(0, 0, 0)
	dimmer.BackgroundTransparency = 0.45
	dimmer.Text = ""
	dimmer.AutoButtonColor = false
	dimmer.ZIndex = 1
	dimmer.Parent = gui
	dimmer.MouseButton1Click:Connect(onClose)

	local accent = if showResult
		then (RARITY_COLOR[offer.rarity] or Color3.fromRGB(82, 126, 255))
		else Color3.fromRGB(255, 212, 38)

	local card = Instance.new("Frame")
	card.Name = "Card"
	card.Size = UDim2.fromOffset(400, 380)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.BackgroundColor3 = Color3.fromRGB(24, 28, 44)
	card.BorderSizePixel = 0
	card.ZIndex = 2
	card.Parent = gui
	corner(card, 14)

	local stroke = Instance.new("UIStroke")
	stroke.Color = accent
	stroke.Thickness = 3
	stroke.Parent = card

	local displayName = if showResult then offer.displayName else SPIN_NAMES[(tick % #SPIN_NAMES) + 1]
	local rarityText = if showResult then string.format("%s  ·  1/%d", offer.rarity, offer.oneIn) else "???"

	label(card, {
		Name = "Title",
		Size = UDim2.new(1, -24, 0, 28),
		Position = UDim2.fromOffset(12, 18),
		Text = if showResult then "YOU ROLLED" else "SPINNING...",
		TextColor3 = Color3.fromRGB(255, 220, 80),
		TextSize = 20,
	})
	label(card, {
		Name = "PetName",
		Size = UDim2.new(1, -24, 0, 52),
		Position = UDim2.fromOffset(12, 54),
		Text = displayName,
		TextColor3 = accent,
		TextSize = 36,
	})
	label(card, {
		Name = "Rarity",
		Size = UDim2.new(1, -24, 0, 30),
		Position = UDim2.fromOffset(12, 116),
		Text = rarityText,
		TextSize = 22,
	})

	if showResult then
		local isBlock = offer.kind == "block"
		local hint = if isBlock
			then string.format("Buy = +%d blocks in inventory", offer.grantQty or 100)
			else "Buy = pet teleports to your yard"
		local buyLabel = if isBlock
			then string.format("Buy x%d  $%d", offer.grantQty or 100, offer.buyCost)
			else string.format("Buy  $%d", offer.buyCost)
		label(card, {
			Name = "Hint",
			Size = UDim2.new(1, -24, 0, 24),
			Position = UDim2.fromOffset(12, 156),
			Text = hint,
			TextColor3 = Color3.fromRGB(170, 180, 210),
			TextSize = 16,
			Font = Enum.Font.SourceSans,
		})
		button(card, {
			Name = "Buy",
			Size = UDim2.new(1, -24, 0, 52),
			Position = UDim2.fromOffset(12, 196),
			BackgroundColor3 = Color3.fromRGB(70, 130, 255),
			Text = buyLabel,
			TextSize = 22,
		}, onBuy)
		button(card, {
			Name = "Again",
			Size = UDim2.new(1, -24, 0, 46),
			Position = UDim2.fromOffset(12, 258),
			BackgroundColor3 = Color3.fromRGB(55, 62, 88),
			Text = "Roll again",
			TextSize = 20,
		}, onSpinAgain)
		button(card, {
			Name = "Close",
			Size = UDim2.new(1, -24, 0, 42),
			Position = UDim2.fromOffset(12, 314),
			BackgroundColor3 = Color3.fromRGB(40, 44, 62),
			Text = "Close",
			TextSize = 18,
			TextColor3 = Color3.fromRGB(200, 210, 230),
		}, onClose)
	end
end

local function offerId(offer: RollOffer?): string
	if not offer then
		return ""
	end
	if typeof(offer.id) == "string" and offer.id ~= "" then
		return offer.id
	end
	if typeof(offer.petId) == "string" then
		return offer.petId
	end
	return ""
end

local function RollOfferPanel(props: Props): React.Node
	local offer = props.offer
	local id = offerId(offer)
	local visible = offer ~= nil and offer.cleared ~= true and id ~= ""

	local tick, setTick = React.useState(0)
	local showResult, setShowResult = React.useState(true)

	local animating = if offer then offer.animating else false

	React.useEffect(function()
		if not visible then
			return
		end
		if not animating then
			setShowResult(true)
			return
		end
		setShowResult(false)
		local running = true
		local n = 0
		task.spawn(function()
			while running and n < 12 do
				n += 1
				setTick(n)
				task.wait(0.08)
			end
			if running then
				setShowResult(true)
			end
		end)
		return function()
			running = false
		end
	end, { id, animating, visible } :: { any })

	React.useEffect(function()
		if not visible or not offer then
			destroyOverlay()
			return
		end
		mountOverlay(offer, showResult, tick, props.onBuy, props.onSpinAgain, props.onClose)
		return function()
			destroyOverlay()
		end
	end, { visible, id, showResult, tick, animating } :: { any })

	return React.createElement("Frame", {
		Name = "RollOfferHost",
		Size = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		Visible = false,
	})
end

return RollOfferPanel
