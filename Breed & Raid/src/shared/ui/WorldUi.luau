--!strict
-- Toybox Premium world-space chrome. Layouts belong in Content, never beside shell decoration.

local FormatOneIn = require(script.Parent.Parent.util.FormatOneIn)
local RarityLogic = require(script.Parent.Parent.util.RarityLogic)
local ThemeColors = require(script.Parent.ThemeColors)

export type Rarity = RarityLogic.Rarity

local C = ThemeColors.Colors
local RarityPal = ThemeColors.Rarity
local Surface = ThemeColors.Surface
local Content = ThemeColors.Content
local Action = ThemeColors.Action
local Border = ThemeColors.Border
local Semantic = ThemeColors.Semantic

local CARD_RADIUS = 22
local CARD_SHADOW_DEPTH = 7

local WorldUi = {}
WorldUi.Colors = C

function WorldUi.bandColor(rarity: Rarity): Color3
	local key = string.lower(rarity)
	return RarityPal[key] or RarityPal.common
end

function WorldUi.stylePrompt(prompt: ProximityPrompt, kind: string?)
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.RequiresLineOfSight = false
	prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
	prompt.ClickablePrompt = true
	prompt.UIOffset = Vector2.new(0, 0)
	if kind then
		prompt:SetAttribute("UiKind", kind)
	end
end

local function stroke(parent: GuiObject, color: Color3, thickness: number)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.Parent = parent
	return s
end

local function corner(parent: GuiObject, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

--- Card shell + Content frame (list/layout goes in Content only).
function WorldUi.makeCardFrame(parent: Instance, size: UDim2, accent: Color3?): (Frame, Frame)
	local shadow = Instance.new("Frame")
	shadow.Name = "CardShadow"
	shadow.Size = size
	shadow.Position = UDim2.fromOffset(0, CARD_SHADOW_DEPTH)
	shadow.BackgroundColor3 = Action.neutralShadow
	shadow.BackgroundTransparency = 0.16
	shadow.BorderSizePixel = 0
	shadow.ZIndex = 1
	shadow.Parent = parent
	corner(shadow, CARD_RADIUS)

	local frame = Instance.new("Frame")
	frame.Name = "Card"
	frame.Size = size
	frame.BackgroundColor3 = Surface.raised
	frame.BorderSizePixel = 0
	frame.ZIndex = 2
	frame.Parent = parent
	corner(frame, CARD_RADIUS)
	stroke(frame, Border.light, 3)

	local bar = Instance.new("Frame")
	bar.Name = "AccentBar"
	bar.Size = UDim2.new(0, 7, 1, -20)
	bar.Position = UDim2.new(0, 7, 0.5, 0)
	bar.AnchorPoint = Vector2.new(0, 0.5)
	bar.BackgroundColor3 = accent or Action.neutral
	bar.BorderSizePixel = 0
	bar.ZIndex = 3
	bar.Parent = frame
	corner(bar, 4)

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -28, 1, -12)
	content.Position = UDim2.fromOffset(20, 6)
	content.BackgroundTransparency = 1
	content.ZIndex = 3
	content.Parent = frame

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 5)
	pad.PaddingBottom = UDim.new(0, 5)
	pad.PaddingLeft = UDim.new(0, 5)
	pad.PaddingRight = UDim.new(0, 5)
	pad.Parent = content

	return frame, content
end

function WorldUi.makeText(parent: Instance, props: {
	name: string,
	text: string,
	size: number,
	color: Color3,
	order: number?,
	height: number?,
	font: Enum.Font?,
}): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = props.name
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, props.height or (props.size + 6))
	label.Text = props.text
	label.TextSize = props.size
	label.Font = props.font or Enum.Font.GothamBold
	label.TextColor3 = props.color
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextWrapped = true
	label.LayoutOrder = props.order or 1
	label.ZIndex = 3
	label.Parent = parent
	return label
end

local function makeChip(parent: Instance, name: string, text: string, accent: Color3, order: number): Frame
	local chip = Instance.new("Frame")
	chip.Name = name
	chip.AutomaticSize = Enum.AutomaticSize.X
	chip.Size = UDim2.fromOffset(0, 20)
	chip.BackgroundColor3 = Surface.base
	chip.BorderSizePixel = 0
	chip.LayoutOrder = order
	chip.ZIndex = 4
	chip.Parent = parent
	corner(chip, 10)
	stroke(chip, accent, 2)

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 9)
	padding.PaddingRight = UDim.new(0, 9)
	padding.Parent = chip

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.AutomaticSize = Enum.AutomaticSize.X
	label.Size = UDim2.new(0, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = string.upper(text)
	label.TextColor3 = accent
	label.TextSize = 10
	label.ZIndex = 5
	label.Parent = chip
	return chip
end

function WorldUi.attachCreatureBillboard(parent: Instance, props: {
	displayName: string,
	oneIn: number,
	mps: number,
	rarity: Rarity,
	isHybrid: boolean?,
}): BillboardGui
	local existing = parent:FindFirstChild("NestBillboard")
	if existing then
		existing:Destroy()
	end

	local accent = WorldUi.bandColor(props.rarity)
	local gui = Instance.new("BillboardGui")
	gui.Name = "NestBillboard"
	gui.Size = UDim2.fromOffset(224, 132)
	gui.StudsOffset = Vector3.new(0, 3.1, 0)
	gui.MaxDistance = 150
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Parent = parent

	local _card, content = WorldUi.makeCardFrame(gui, UDim2.fromScale(1, 1), accent)
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 1)
	list.Parent = content

	WorldUi.makeText(content, {
		name = "Name",
		text = props.displayName,
		size = 15,
		color = Content.primary,
		order = 1,
		height = 20,
		font = Enum.Font.GothamBold,
	})
	WorldUi.makeText(content, {
		name = "Odds",
		text = FormatOneIn(props.oneIn),
		size = 28,
		color = accent,
		order = 2,
		height = 34,
		font = Enum.Font.GothamBlack,
	})
	WorldUi.makeText(content, {
		name = "Mps",
		text = string.format("$%g/s", props.mps),
		size = 15,
		color = Action.collect,
		order = 3,
		height = 20,
		font = Enum.Font.GothamBold,
	})

	local chips = Instance.new("Frame")
	chips.Name = "Chips"
	chips.Size = UDim2.new(1, 0, 0, 22)
	chips.BackgroundTransparency = 1
	chips.LayoutOrder = 4
	chips.ZIndex = 4
	chips.Parent = content

	local chipList = Instance.new("UIListLayout")
	chipList.FillDirection = Enum.FillDirection.Horizontal
	chipList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	chipList.VerticalAlignment = Enum.VerticalAlignment.Center
	chipList.SortOrder = Enum.SortOrder.LayoutOrder
	chipList.Padding = UDim.new(0, 5)
	chipList.Parent = chips

	makeChip(chips, "RarityChip", props.rarity, accent, 1)
	if props.isHybrid then
		makeChip(chips, "HybridChip", "HYBRID", Action.breed, 2)
	end
	return gui
end

function WorldUi.attachPadPreview(parent: Instance, name: string, header: string): BillboardGui
	local existing = parent:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = name
	gui.Size = UDim2.fromOffset(224, 126)
	gui.StudsOffset = Vector3.new(0, 4.4, 0)
	gui.MaxDistance = 100
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Parent = parent

	local actionAccent = if string.find(header, "BLOCK") then Action.reward else Action.danger
	local card, content = WorldUi.makeCardFrame(gui, UDim2.fromScale(1, 1), actionAccent)
	card.Name = "Card"

	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 2)
	list.Parent = content

	WorldUi.makeText(content, {
		name = "Header",
		text = header,
		size = 10,
		color = actionAccent,
		order = 1,
		height = 14,
		font = Enum.Font.GothamBold,
	})
	WorldUi.makeText(content, {
		name = "Title",
		text = "Ready",
		size = 14,
		color = Content.primary,
		order = 2,
		height = 18,
		font = Enum.Font.GothamBold,
	})
	WorldUi.makeText(content, {
		name = "Odds",
		text = "Press Roll",
		size = 22,
		color = actionAccent,
		order = 3,
		height = 28,
		font = Enum.Font.GothamBlack,
	})
	WorldUi.makeText(content, {
		name = "Meta",
		text = "",
		size = 11,
		color = Content.secondary,
		order = 4,
		height = 16,
	})
	local legacy = Instance.new("TextLabel")
	legacy.Name = "PreviewLabel"
	legacy.Size = UDim2.fromScale(0, 0)
	legacy.BackgroundTransparency = 1
	legacy.TextTransparency = 1
	legacy.Text = ""
	legacy.Parent = gui
	return gui
end

function WorldUi.setPadPreview(part: BasePart, billboardName: string, props: {
	title: string,
	odds: string,
	meta: string,
	accent: Color3?,
})
	local gui = part:FindFirstChild(billboardName)
	if not gui then
		return
	end
	local card = gui:FindFirstChild("Card")
	if not card then
		return
	end
	local content = card:FindFirstChild("Content") or card
	local title = content:FindFirstChild("Title")
	local odds = content:FindFirstChild("Odds")
	local meta = content:FindFirstChild("Meta")
	if title and title:IsA("TextLabel") then
		title.Text = props.title
	end
	if odds and odds:IsA("TextLabel") then
		odds.Text = props.odds
		if props.accent then
			odds.TextColor3 = props.accent
		end
	end
	if meta and meta:IsA("TextLabel") then
		meta.Text = props.meta
	end
	local accentBar = card:FindFirstChild("AccentBar")
	if accentBar and accentBar:IsA("Frame") and props.accent then
		accentBar.BackgroundColor3 = props.accent
	end
	local legacy = gui:FindFirstChild("PreviewLabel")
	if legacy and legacy:IsA("TextLabel") then
		legacy.Text = `{props.title}\n{props.odds}\n{props.meta}`
	end
end

function WorldUi.attachStatusBillboard(parent: Instance, name: string, props: {
	size: UDim2?,
	offset: Vector3?,
	labelName: string,
	defaultText: string,
	accent: Color3?,
}): BillboardGui
	local existing = parent:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = name
	gui.Size = props.size or UDim2.fromOffset(140, 48)
	gui.StudsOffset = props.offset or Vector3.new(0, 3.5, 0)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.MaxDistance = 110
	gui.Parent = parent
	local statusAccent = props.accent or Action.collect
	local _card, content = WorldUi.makeCardFrame(gui, UDim2.fromScale(1, 1), statusAccent)
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Parent = content
	WorldUi.makeText(content, {
		name = props.labelName,
		text = props.defaultText,
		size = 18,
		color = statusAccent,
		order = 1,
		height = 32,
		font = Enum.Font.GothamBlack,
	})
	return gui
end

function WorldUi.styleHubPad(pad: BasePart, kind: "creature" | "block" | "collect" | "lock" | "incubator" | "spawn")
	pad.Material = Enum.Material.SmoothPlastic
	pad.TopSurface = Enum.SurfaceType.Smooth
	if kind == "creature" then
		pad.Color = Action.danger
	elseif kind == "block" then
		pad.Color = Action.reward
	elseif kind == "collect" then
		pad.Color = Action.collectHighlight
	elseif kind == "lock" then
		pad.Color = Action.primaryHighlight
	elseif kind == "incubator" then
		pad.Color = Action.breed
	else
		pad.Color = Action.primary
	end
	local light = pad:FindFirstChild("PadLight")
	if not light then
		local pl = Instance.new("PointLight")
		pl.Name = "PadLight"
		pl.Brightness = 0.6
		pl.Range = 10
		pl.Color = pad.Color
		pl.Parent = pad
	end
end

function WorldUi.styleNest(pedestal: BasePart, unlocked: boolean, occupied: boolean?)
	pedestal.Material = Enum.Material.SmoothPlastic
	if not unlocked then
		pedestal.Color = Semantic.locked
		pedestal.Transparency = 0.4
	elseif occupied then
		pedestal.Color = Surface.tinted
		pedestal.Transparency = 0
	else
		pedestal.Color = Surface.sunken
		pedestal.Transparency = 0
	end
end

function WorldUi.findLabel(root: Instance, name: string): TextLabel?
	local label = root:FindFirstChild(name, true)
	if label and label:IsA("TextLabel") then
		return label
	end
	return nil
end

function WorldUi.promptAccent(kind: string?): Color3
	if kind == "collect" then
		return Action.collect
	elseif kind == "buy" or kind == "roll" then
		return Action.reward
	elseif kind == "lock" then
		return Action.primary
	elseif kind == "steal" then
		return Action.danger
	elseif kind == "breed" then
		return Action.breed
	elseif kind == "take" or kind == "deposit" then
		return Action.neutral
	end
	return Action.neutral
end

return WorldUi
