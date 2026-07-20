--!strict
-- Reference sim HUD: top chips · left nav · bottom hammer/bat · center popups.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local HudContext = require(script.Parent.context.HudContext)
local ResourceChip = require(script.Parent.components.ResourceChip)
local LeftNav = require(script.Parent.components.LeftNav)
local ToolHotbar = require(script.Parent.components.ToolHotbar)
local RollRewardModal = require(script.Parent.components.RollRewardModal)
local PetsPanel = require(script.Parent.components.PetsPanel)
local BreedModal = require(script.Parent.components.BreedModal)
local HatchReveal = require(script.Parent.components.HatchReveal)
local JuiceLayer = require(script.Parent.components.JuiceLayer)
local useLayout = require(script.Parent.hooks.useLayout)
local theme = require(script.Parent.theme)

export type JuiceState = {
	buyToken: number,
	collectToken: number,
	collectAmount: number,
	cashPulse: number,
	hatch: HatchReveal.HatchPayload?,
}

export type AppProps = {
	juice: JuiceState,
	clearHatch: () -> (),
}

local function equipOrToggleBat()
	local player = Players.LocalPlayer
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local equipped = character:FindFirstChild("Bat")
	if equipped and equipped:IsA("Tool") then
		humanoid:UnequipTools()
		return
	end
	local backpack = player:FindFirstChild("Backpack")
	local bat = backpack and backpack:FindFirstChild("Bat")
	if bat and bat:IsA("Tool") then
		humanoid:EquipTool(bat)
	end
end

local function App(props: AppProps): React.Node
	local layout = useLayout()
	local ctx = React.useContext(HudContext)
	local C = theme.Colors
	local showBuildMats = ctx.buildMode
	local bufferAmt = math.floor(ctx.hud.buffer)
	local collectLabel = "Collect"

	local shopOpen, setShopOpen = React.useState(false)
	local petsOpen, setPetsOpen = React.useState(false)
	local batActive, setBatActive = React.useState(false)

	local previewKey = (ctx.hud.creaturePreview and ctx.hud.creaturePreview.templateId) or ""
	local blockKey = (ctx.hud.blockPreview and ctx.hud.blockPreview.templateId) or ""
	React.useEffect(function()
		if previewKey ~= "" or blockKey ~= "" then
			setShopOpen(true)
			setPetsOpen(false)
		end
	end, { previewKey, blockKey })

	React.useEffect(function()
		local player = Players.LocalPlayer
		local conns: { RBXScriptConnection } = {}
		local function syncBat(character: Model?)
			setBatActive(character ~= nil and character:FindFirstChild("Bat") ~= nil)
		end
		local function hook(character: Model)
			syncBat(character)
			table.insert(conns, character.ChildAdded:Connect(function()
				syncBat(character)
			end))
			table.insert(conns, character.ChildRemoved:Connect(function()
				syncBat(character)
			end))
		end
		if player.Character then
			hook(player.Character)
		end
		table.insert(conns, player.CharacterAdded:Connect(hook))
		return function()
			for _, conn in conns do
				conn:Disconnect()
			end
		end
	end, {})

	return React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, {
		Top = React.createElement("Frame", {
			Size = UDim2.new(1, -layout.gap(24), 0, layout.px(theme.Design.CHIP_H)),
			Position = UDim2.fromOffset(layout.safeLeft + layout.gap(12), layout.safeTop + layout.gap(8)),
			BackgroundTransparency = 1,
		}, {
			List = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, layout.gap(8)),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
			Cash = React.createElement(ResourceChip, {
				label = "Cash",
				amount = ctx.hud.cash,
				accent = C.gold,
				layoutOrder = 1,
				pulseToken = props.juice.cashPulse,
				emphasize = true,
			}),
			Buffer = React.createElement(ResourceChip, {
				label = "Buffer",
				amount = ctx.hud.buffer,
				accent = C.jade,
				layoutOrder = 2,
			}),
			Mps = React.createElement(ResourceChip, {
				label = "$/s",
				amount = ctx.hud.mps,
				accent = C.primary,
				layoutOrder = 3,
			}),
			Dirt = if showBuildMats
				then React.createElement(ResourceChip, {
					label = "Dirt",
					amount = ctx.hud.dirt,
					accent = C.dirt,
					layoutOrder = 4,
				})
				else nil,
			Spikes = if showBuildMats
				then React.createElement(ResourceChip, {
					label = "Spikes",
					amount = ctx.hud.spikes,
					accent = C.spikes,
					layoutOrder = 5,
				})
				else nil,
		}),

		Left = React.createElement(LeftNav, {
			petsActive = petsOpen,
			breedActive = ctx.breedOpen,
			shopActive = shopOpen,
			collectLabel = collectLabel,
			onPets = function()
				setPetsOpen(true)
				setShopOpen(false)
				ctx.setBreedOpen(false)
			end,
			onBreed = function()
				setPetsOpen(false)
				setShopOpen(false)
				ctx.setBreedOpen(true)
			end,
			onShop = function()
				setPetsOpen(false)
				ctx.setBreedOpen(false)
				setShopOpen(true)
			end,
			onCollect = function()
				ctx.requestCollect()
			end,
		}),

		Tools = React.createElement(ToolHotbar, {
			buildActive = ctx.buildMode,
			batActive = batActive,
			onHammer = function()
				setPetsOpen(false)
				setShopOpen(false)
				ctx.setBreedOpen(false)
				ctx.toggleBuildMode()
			end,
			onBat = function()
				if ctx.buildMode then
					ctx.toggleBuildMode()
				end
				equipOrToggleBat()
				task.defer(function()
					local character = Players.LocalPlayer.Character
					setBatActive(character ~= nil and character:FindFirstChild("Bat") ~= nil)
				end)
			end,
		}),

		Hint = if ctx.buildMode
			then React.createElement("TextLabel", {
				Size = UDim2.fromOffset(layout.px(480), layout.px(28)),
				Position = UDim2.new(0.5, 0, 1, -(layout.touch(theme.Design.HOTBAR_BTN) + layout.gap(70))),
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundColor3 = C.bgChip,
				BackgroundTransparency = 0.05,
				Text = "  Q = block · click place · Shift+click break  ",
				TextSize = layout.text(12),
				Font = theme.Font.body,
				TextColor3 = C.textMain,
				ZIndex = 16,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.chip }),
				Stroke = React.createElement("UIStroke", {
					Color = C.outline,
					Thickness = theme.Stroke.thin,
					Transparency = 0.65,
				}),
			})
			else nil,

		Toast = if ctx.toast
			then React.createElement("TextLabel", {
				Size = UDim2.fromOffset(layout.px(340), layout.px(40)),
				Position = UDim2.new(0.5, 0, 0, layout.safeTop + layout.px(64)),
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundColor3 = C.bgChip,
				Text = ctx.toast,
				TextSize = layout.text(14),
				Font = theme.Font.title,
				TextColor3 = C.textMain,
				ZIndex = 30,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.chip }),
				Stroke = React.createElement("UIStroke", {
					Color = C.outline,
					Thickness = theme.Stroke.thin,
					Transparency = 0.65,
				}),
			})
			else nil,

		Shop = React.createElement(RollRewardModal, {
			open = shopOpen,
			onClose = function()
				setShopOpen(false)
			end,
		}),
		Pets = React.createElement(PetsPanel, {
			open = petsOpen,
			onClose = function()
				setPetsOpen(false)
			end,
			onBreed = function()
				setPetsOpen(false)
				ctx.setBreedOpen(true)
			end,
		}),
		Breed = React.createElement(BreedModal),
		Juice = React.createElement(JuiceLayer, {
			buyToken = props.juice.buyToken,
			collectToken = props.juice.collectToken,
			collectAmount = props.juice.collectAmount,
		}),
		Hatch = React.createElement(HatchReveal, {
			payload = props.juice.hatch,
			onDone = props.clearHatch,
		}),
	})
end

return App
