--!strict
-- HUD from sim-pop icons — currencies + main rails + bottom actions.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local ImageIds = require(script.Parent.Parent.ImageIds)
local theme = require(script.Parent.Parent.theme)
local HudButton = require(script.Parent.HudButton)

export type Props = {
	onAction: ((icon: ImageIds.HudIcon) -> ())?,
	coins: number?,
	gems: number?,
}

-- Primary gameplay
local LEFT: { ImageIds.HudIcon } = {
	"inventory",
	"shop",
	"eggs",
	"rebirth",
	"boosts",
	"daily",
	"spin",
	"trade",
}

-- Meta / social
local RIGHT: { ImageIds.HudIcon } = {
	"settings",
	"codes",
	"quests",
	"achievements",
	"leaderboard",
	"premium",
	"index",
	"gift",
	"friends",
	"robuxShop",
}

local BOTTOM: { ImageIds.HudIcon } = {
	"teleport",
	"zones",
	"play",
	"dungeon",
	"boss",
	"skills",
	"afk",
}

local ICON = UDim2.fromOffset(88, 88)
local GAP = 10

local function rail(
	name: string,
	icons: { ImageIds.HudIcon },
	anchor: Vector2,
	position: UDim2,
	onAction: ((ImageIds.HudIcon) -> ())?
): React.Node
	local children: { [string]: React.Node } = {
		List = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, GAP),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}

	for i, icon in icons do
		children[icon] = React.createElement(HudButton, {
			icon = icon,
			size = ICON,
			layoutOrder = i,
			onActivated = if onAction
				then function()
					onAction(icon)
				end
				else nil,
		})
	end

	return React.createElement("Frame", {
		Name = name,
		AutomaticSize = Enum.AutomaticSize.XY,
		Position = position,
		AnchorPoint = anchor,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, children)
end

local function currencyChip(
	name: string,
	icon: ImageIds.HudIcon,
	amount: number,
	layoutOrder: number
): React.Node
	return React.createElement("Frame", {
		Name = name,
		Size = UDim2.fromOffset(220, 56),
		BackgroundColor3 = Color3.fromRGB(20, 20, 24),
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		LayoutOrder = layoutOrder,
	}, {
		Corner = React.createElement("UICorner", {
			CornerRadius = UDim.new(1, 0),
		}),
		Stroke = React.createElement("UIStroke", {
			Color = theme.Colors.black,
			Thickness = 3,
		}),
		Icon = React.createElement("ImageLabel", {
			Size = UDim2.fromOffset(44, 44),
			Position = UDim2.new(0, 8, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			Image = ImageIds.Hud[icon],
			ScaleType = Enum.ScaleType.Fit,
		}),
		Amount = React.createElement("TextLabel", {
			Size = UDim2.new(1, -64, 1, 0),
			Position = UDim2.fromOffset(56, 0),
			BackgroundTransparency = 1,
			Text = tostring(amount),
			Font = theme.Font.display,
			TextScaled = true,
			TextColor3 = theme.Colors.white,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, {
			Pad = React.createElement("UIPadding", {
				PaddingTop = UDim.new(0, 8),
				PaddingBottom = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 12),
			}),
			Outline = React.createElement("UIStroke", {
				Color = theme.Colors.black,
				Thickness = 3,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
			}),
		}),
	})
end

local function Hud(props: Props): React.Node
	local onAction = props.onAction
	local coins = props.coins or 12500
	local gems = props.gems or 340

	local bottomChildren: { [string]: React.Node } = {
		List = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, GAP),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}

	for i, icon in BOTTOM do
		local size = if icon == "play" then UDim2.fromOffset(104, 104) else ICON
		bottomChildren[icon] = React.createElement(HudButton, {
			icon = icon,
			size = size,
			layoutOrder = i,
			onActivated = if onAction
				then function()
					onAction(icon)
				end
				else nil,
		})
	end

	return React.createElement("Frame", {
		Name = "Hud",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, {
		Currencies = React.createElement("Frame", {
			Name = "Currencies",
			AutomaticSize = Enum.AutomaticSize.XY,
			Position = UDim2.new(0.5, 0, 0, 24),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, {
			List = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 16),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Coins = currencyChip("Coins", "coins", coins, 1),
			Gems = currencyChip("Gems", "gems", gems, 2),
		}),

		Left = rail("Left", LEFT, Vector2.new(0, 0.5), UDim2.new(0, 28, 0.5, 0), onAction),
		Right = rail("Right", RIGHT, Vector2.new(1, 0.5), UDim2.new(1, -28, 0.5, 0), onAction),

		Bottom = React.createElement("Frame", {
			Name = "Bottom",
			AutomaticSize = Enum.AutomaticSize.XY,
			Position = UDim2.new(0.5, 0, 1, -28),
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, bottomChildren),
	})
end

return Hud
