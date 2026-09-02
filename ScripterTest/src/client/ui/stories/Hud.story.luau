--!strict
-- Hoarcekat: полный HUD тестового задания (очки, кнопка достижений, окно, prompt, тосты).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local HudProvider = require(script.Parent.Parent.context.HudProvider)
local PointsChip = require(script.Parent.Parent.components.PointsChip)
local AchievementsButton = require(script.Parent.Parent.components.AchievementsButton)
local AchievementsPanel = require(script.Parent.Parent.panels.AchievementsPanel)
local ProximityPromptUI = require(script.Parent.Parent.components.ProximityPromptUI)
local ToastStack = require(script.Parent.Parent.components.ToastStack)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local theme = require(script.Parent.Parent.theme)
local mount = require(script.Parent.mount)

local function mockHud(overrides: { [string]: any }?): NetTypes.HudSyncPayload
	local hud = NetTypes.emptyHud()
	hud.points = 42
	hud.jumpCount = 2
	if overrides then
		for k, v in overrides do
			(hud :: any)[k] = v
		end
	end
	return hud
end

local function StoryApp(): React.Node
	local hud, setHud = React.useState(mockHud())
	local open, setOpen = React.useState(true)
	local toasts = React.useMemo(function()
		return {
			{ id = 1, text = "Покупка успешна!", color = theme.Colors.buy },
			{ id = 2, text = "Достижение: Прыгун", color = Color3.fromRGB(255, 212, 38) },
		}
	end, {})

	return React.createElement(HudProvider, {
		hud = hud,
		achievementsOpen = open,
		setAchievementsOpen = setOpen,
	}, {
		Root = React.createElement("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		}, {
			Currencies = React.createElement("Frame", {
				AutomaticSize = Enum.AutomaticSize.XY,
				Position = UDim2.new(0.5, 0, 0, 24),
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
			}, {
				Chip = React.createElement(PointsChip, { amount = hud.points }),
			}),
			Left = React.createElement("Frame", {
				AutomaticSize = Enum.AutomaticSize.XY,
				Position = UDim2.new(0, 28, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
			}, {
				Btn = React.createElement(AchievementsButton, {
					onActivated = function()
						setOpen(true)
					end,
				}),
			}),
			Panel = React.createElement(AchievementsPanel, {
				visible = open,
				hud = hud,
				onClose = function()
					setOpen(false)
					-- демо: чуть меняем прогресс при закрытии/открытии
					setHud(mockHud({
						jumpCount = 5,
						achJumpFive = true,
						points = 99,
					}))
				end,
			}),
			Toasts = React.createElement(ToastStack, { items = toasts }),
			Prompt = React.createElement(ProximityPromptUI, {
				prompt = {
					keyText = "E",
					objectText = "Object Text",
					actionText = "Action Text",
					inputType = Enum.ProximityPromptInputType.Keyboard,
				},
			}),
		}),
	})
end

return mount(React.createElement(StoryApp))
