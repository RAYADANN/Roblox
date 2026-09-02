--!strict
-- Inventory window skeleton — fill in yourself.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)

export type Props = {
	onClose: (() -> ())?,
}

local function InventoryWindow(props: Props): React.Node
	return React.createElement("Frame", {
		Name = "InventoryWindow",
		Size = UDim2.fromScale(0.7, 0.7),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = theme.Colors.white,
		BorderSizePixel = 0,
		ClipsDescendants = false,
	}, {
		Corner = React.createElement("UICorner", {
			CornerRadius = UDim.new(theme.Radius.panel, 0),
		}),
		Stroke = React.createElement("UIStroke", {
			Color = theme.Colors.black,
			Thickness = theme.Stroke.panel,
		}),

		-- Title (sits on top edge — tune Position/AnchorPoint)
		Title = React.createElement("TextLabel", {
			Size = UDim2.new(0.3, 0, 0.3, 0),
			Position = UDim2.fromScale(0.02, -0.01),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			Text = "INVENTORY",
			Font = theme.Font.display,
			TextScaled = true,
			TextColor3 = theme.Colors.white,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 2,
		}, {
			Outline = React.createElement("UIStroke", {
				Color = theme.Colors.black,
				Thickness = theme.Stroke.title,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
			}),
		}),

		-- Close (ImageButton — no Text/Font props)
		Close = React.createElement("ImageButton", {
			Size = UDim2.fromScale(0.15, 0.15),
			Position = UDim2.fromScale(1.04, 0),
			AnchorPoint = Vector2.new(1, 0.5),
            BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Image = "rbxassetid://132233226642479",
			ImageColor3 = theme.Colors.white,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 2,
			[React.Event.Activated] = props.onClose,
		}, {
			Aspect = React.createElement("UIAspectRatioConstraint", {
				AspectRatio = 1,
				DominantAxis = Enum.DominantAxis.Width,
			}),
			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(theme.Radius.closeX, 0),
			}),
			
		}),

		-- Content
		Scroll = React.createElement("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 6,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
		}, {
			Pad = React.createElement("UIPadding", {
				PaddingTop = UDim.new(0, 24),
				PaddingBottom = UDim.new(0, 16),
				PaddingLeft = UDim.new(0, 16),
				PaddingRight = UDim.new(0, 16),
			}),
			Grid = React.createElement("UIGridLayout", {
				CellSize = UDim2.fromOffset(100, 100),
				CellPadding = UDim2.fromOffset(10, 10),
				FillDirectionMaxCells = 4,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			-- TODO: map your items here
			Slot1 = React.createElement("Frame", {
				BackgroundColor3 = theme.Colors.slotEmpty,
				BorderSizePixel = 0,
				LayoutOrder = 1,
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(theme.Radius.slot, 0),
				}),
				Stroke = React.createElement("UIStroke", {
					Color = theme.Colors.black,
					Thickness = theme.Stroke.slot,
				}),
			}),
		}),
	})
end

return InventoryWindow
