--!strict
-- Shared world-space UI chrome. Card = surface + optional accent; content NEVER shares UIListLayout with chrome.

local FormatOneIn = require(script.Parent.Parent.util.FormatOneIn)
local RarityLogic = require(script.Parent.Parent.util.RarityLogic)
local ThemeColors = require(script.Parent.ThemeColors)

export type Rarity = RarityLogic.Rarity

local C = ThemeColors.Colors
local RarityPal = ThemeColors.Rarity

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
	local frame = Instance.new("Frame")
	frame.Name = "Card"
	frame.Size = size
	frame.BackgroundColor3 = C.bgChip
	frame.BorderSizePixel = 0
	frame.Parent = parent
	corner(frame, 12)
	stroke(frame, accent or C.bronze, 2)

	if accent then
		local bar = Instance.new("Frame")
		bar.Name = "AccentBar"
		bar.Size = UDim2.new(0, 3, 1, -12)
		bar.Position = UDim2.new(0, 5, 0.5, 0)
		bar.AnchorPoint = Vector2.new(0, 0.5)
		bar.BackgroundColor3 = accent
		bar.BorderSizePixel = 0
		bar.ZIndex = 2
		bar.Parent = frame
		corner(bar, 2)
	end

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -14, 1, -4)
	content.Position = UDim2.fromOffset(10, 2)
	content.BackgroundTransparency = 1
	content.ZIndex = 2
	content.Parent = frame

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 4)
	pad.PaddingBottom = UDim.new(0, 4)
	pad.PaddingLeft = UDim.new(0, 4)
	pad.PaddingRight = UDim.new(0, 6)
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
	gui.Size = UDim2.fromOffset(176, 86)
	gui.StudsOffset = Vector3.new(0, 2.7, 0)
	gui.MaxDistance = 120
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0
	gui.Parent = parent

	local _card, content = WorldUi.makeCardFrame(gui, UDim2.fromScale(1, 1), accent)
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 0)
	list.Parent = content

	WorldUi.makeText(content, {
		name = "Odds",
		text = FormatOneIn(props.oneIn),
		size = 22,
		color = accent,
		order = 1,
		height = 28,
		font = Enum.Font.GothamBlack,
	})
	local title = props.displayName
	if props.isHybrid then
		title = `✦ {title}`
	end
	WorldUi.makeText(content, {
		name = "Name",
		text = title,
		size = 11,
		color = C.inkSoft,
		order = 2,
		height = 15,
		font = Enum.Font.GothamMedium,
	})
	WorldUi.makeText(content, {
		name = "Mps",
		text = `${props.mps}/s`,
		size = 12,
		color = C.jade,
		order = 3,
		height = 16,
		font = Enum.Font.GothamBold,
	})
	return gui
end

function WorldUi.attachPadPreview(parent: Instance, name: string, header: string): BillboardGui
	local existing = parent:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = name
	gui.Size = UDim2.fromOffset(210, 118)
	gui.StudsOffset = Vector3.new(0, 4.4, 0)
	gui.MaxDistance = 80
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Parent = parent

	local card, content = WorldUi.makeCardFrame(gui, UDim2.fromScale(1, 1), C.bronze)
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
		color = C.gold,
		order = 1,
		height = 14,
		font = Enum.Font.GothamMedium,
	})
	-- Pad titles idle: ink for AA on cream (was soft)
	WorldUi.makeText(content, {
		name = "Title",
		text = "Ready",
		size = 13,
		color = C.ink,
		order = 2,
		height = 16,
		font = Enum.Font.GothamMedium,
	})
	WorldUi.makeText(content, {
		name = "Odds",
		text = "Press Roll",
		size = 20,
		color = C.gold,
		order = 3,
		height = 26,
		font = Enum.Font.GothamBlack,
	})
	WorldUi.makeText(content, {
		name = "Meta",
		text = "",
		size = 11,
		color = C.inkSoft,
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
	local strokeInst = card:FindFirstChildOfClass("UIStroke")
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
	if strokeInst and props.accent then
		strokeInst.Color = props.accent
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
	gui.MaxDistance = 90
	gui.Parent = parent
	local _card, content = WorldUi.makeCardFrame(gui, UDim2.fromScale(1, 1), props.accent or C.jade)
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Parent = content
	WorldUi.makeText(content, {
		name = props.labelName,
		text = props.defaultText,
		size = 18,
		color = props.accent or C.jade,
		order = 1,
		height = 32,
		font = Enum.Font.GothamBlack,
	})
	return gui
end

function WorldUi.styleHubPad(pad: BasePart, kind: "creature" | "block" | "collect" | "lock" | "incubator" | "spawn")
	pad.Material = Enum.Material.SmoothPlastic
	pad.TopSurface = Enum.SurfaceType.Smooth
	-- Loud mat colors (Discover station language) on dark UI family.
	if kind == "creature" then
		pad.Color = Color3.fromRGB(220, 70, 80)
	elseif kind == "block" then
		pad.Color = Color3.fromRGB(255, 190, 40)
	elseif kind == "collect" then
		pad.Color = C.jadeHi
	elseif kind == "lock" then
		pad.Color = C.primaryHi
	elseif kind == "incubator" then
		pad.Color = C.breed
	else
		pad.Color = Color3.fromRGB(70, 110, 180)
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
		pedestal.Color = Color3.fromRGB(90, 88, 82)
		pedestal.Transparency = 0.4
	elseif occupied then
		pedestal.Color = Color3.fromRGB(196, 175, 120)
		pedestal.Transparency = 0
	else
		pedestal.Color = Color3.fromRGB(210, 198, 175)
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
		return C.jade
	elseif kind == "buy" or kind == "roll" then
		return C.gold
	elseif kind == "lock" then
		return C.sky
	elseif kind == "steal" then
		return C.danger
	elseif kind == "breed" then
		return C.breed
	elseif kind == "take" or kind == "deposit" then
		return C.inkSoft
	end
	return C.bronze
end

return WorldUi
