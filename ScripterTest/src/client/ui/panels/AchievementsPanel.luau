--!strict
-- Окно достижений. ZIndex у строк не ставим низким — при Global они уходят под панель.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local CloseButton = require(script.Parent.Parent.components.CloseButton)
local theme = require(script.Parent.Parent.theme)
local AchievementDatabase = require(ReplicatedStorage.shared.data.AchievementDatabase)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)

export type Props = {
	visible: boolean,
	hud: NetTypes.HudSyncPayload,
	onClose: () -> (),
}

local ROW_H = 88
local ROW_GAP = 12

local function isDone(hud: NetTypes.HudSyncPayload, id: string): boolean
	if id == "buyAllArea1" then
		return hud.achBuyAllArea1
	elseif id == "buyAllArea2" then
		return hud.achBuyAllArea2
	elseif id == "fallOffMap" then
		return hud.achFallOffMap
	elseif id == "jumpFiveTimes" then
		return hud.achJumpFive
	end
	return false
end

local function progressText(hud: NetTypes.HudSyncPayload, id: string): string
	if id == "jumpFiveTimes" and not hud.achJumpFive then
		return `{math.min(hud.jumpCount, 5)}/5`
	end
	if isDone(hud, id) then
		return "DONE"
	end
	return "—"
end

local function MissionRow(props: {
	title: string,
	description: string,
	done: boolean,
	progress: string,
	layoutOrder: number,
}): React.Node
	local bg = if props.done then Color3.fromRGB(106, 255, 17) else theme.Colors.slotEmpty

	return React.createElement("Frame", {
		Name = `Mission_{props.layoutOrder}`,
		Size = UDim2.new(1, 0, 0, ROW_H),
		BackgroundColor3 = bg,
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
	}, {
		Corner = React.createElement("UICorner", {
			CornerRadius = UDim.new(theme.Radius.slot, 0),
		}),
		Stroke = React.createElement("UIStroke", {
			Color = theme.Colors.black,
			Thickness = theme.Stroke.slot,
		}),
		Title = React.createElement("TextLabel", {
			Size = UDim2.new(1, -110, 0, 32),
			Position = UDim2.fromOffset(14, 12),
			BackgroundTransparency = 1,
			Text = props.title,
			Font = theme.Font.display,
			TextScaled = true,
			TextColor3 = theme.Colors.white,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, {
			Outline = React.createElement("UIStroke", {
				Color = theme.Colors.black,
				Thickness = theme.Stroke.text,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
			}),
		}),
		Desc = React.createElement("TextLabel", {
			Size = UDim2.new(1, -110, 0, 28),
			Position = UDim2.fromOffset(14, 46),
			BackgroundTransparency = 1,
			Text = props.description,
			Font = theme.Font.display,
			TextScaled = true,
			TextColor3 = theme.Colors.white,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, {
			Outline = React.createElement("UIStroke", {
				Color = theme.Colors.black,
				Thickness = 2,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
			}),
		}),
		Badge = React.createElement("TextLabel", {
			Size = UDim2.fromOffset(90, 42),
			Position = UDim2.new(1, -14, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundTransparency = 1,
			Text = props.progress,
			Font = theme.Font.display,
			TextScaled = true,
			TextColor3 = theme.Colors.white,
		}, {
			Outline = React.createElement("UIStroke", {
				Color = theme.Colors.black,
				Thickness = theme.Stroke.text,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
			}),
		}),
	})
end

local function AchievementsPanel(props: Props): React.Node
	if not props.visible then
		return nil
	end

	local list = AchievementDatabase.LIST
	local count = #list
	local canvasH = math.max(count * (ROW_H + ROW_GAP), ROW_H)

	local rowChildren: { [string]: React.Node } = {
		Layout = React.createElement("UIListLayout", {
			Padding = UDim.new(0, ROW_GAP),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}

	for index, def in ipairs(list) do
		rowChildren[def.id] = React.createElement(MissionRow, {
			title = def.title,
			description = def.description,
			done = isDone(props.hud, def.id),
			progress = progressText(props.hud, def.id),
			layoutOrder = index,
		})
	end

	return React.createElement("Frame", {
		Name = "AchievementsOverlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = theme.Colors.black,
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		Active = true,
	}, {
		Window = React.createElement("Frame", {
			Name = "AchievementsWindow",
			Size = UDim2.fromScale(0.7, 0.62),
			Position = UDim2.fromScale(0.5, 0.52),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = theme.Colors.panel,
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
			Title = React.createElement("TextLabel", {
				Size = UDim2.new(0.5, 0, 0, 48),
				Position = UDim2.fromScale(0.04, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				Text = "ACHIEVEMENTS",
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
			Close = React.createElement("Frame", {
				Size = UDim2.fromOffset(56, 56),
				Position = UDim2.new(1, 8, 0, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 2,
			}, {
				Btn = React.createElement(CloseButton, {
					size = UDim2.fromScale(1, 1),
					onActivated = props.onClose,
				}),
			}),
			Scroll = React.createElement("ScrollingFrame", {
				Name = "MissionList",
				Size = UDim2.new(1, -40, 1, -48),
				Position = UDim2.fromOffset(20, 36),
				BackgroundColor3 = theme.Colors.panelAlt,
				BackgroundTransparency = 0.35,
				BorderSizePixel = 0,
				ScrollBarThickness = 8,
				ScrollBarImageColor3 = theme.Colors.black,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				CanvasSize = UDim2.fromOffset(0, canvasH + 16),
				AutomaticCanvasSize = Enum.AutomaticSize.None,
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(theme.Radius.slot, 0),
				}),
				Inner = React.createElement("Frame", {
					Name = "Inner",
					Size = UDim2.new(1, -24, 0, canvasH),
					Position = UDim2.fromOffset(12, 12),
					BackgroundTransparency = 1,
				}, rowChildren),
			}),
		}),
	})
end

return AchievementsPanel
