--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local HudContext = require(script.Parent.context.HudContext)
local ResourceChip = require(script.Parent.components.ResourceChip)
local PhaseChip = require(script.Parent.components.PhaseChip)
local BatteryBar = require(script.Parent.components.BatteryBar)
local Toast = require(script.Parent.components.Toast)
local TutorialBanner = require(script.Parent.components.TutorialBanner)
local Button = require(script.Parent.components.Button)
local InventoryPanel = require(script.Parent.components.InventoryPanel)
local BuildPanel = require(script.Parent.components.BuildPanel)
local RollOfferPanel = require(script.Parent.components.RollOfferPanel)
local useLayout = require(script.Parent.hooks.useLayout)
local theme = require(script.Parent.theme)

local function App(): React.ReactElement<any, any>
	local layout = useLayout()
	local ctx = React.useContext(HudContext)
	local hud = ctx.hud

	return React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, {
		Phase = React.createElement(PhaseChip, {
			phase = hud.phase,
			remainingSec = hud.remainingSec,
		}),
		TopLeft = React.createElement("Frame", {
			Size = UDim2.fromOffset(layout.px(180), layout.px(110)),
			Position = UDim2.fromOffset(layout.safeLeft + layout.gap(16), layout.safeTop + layout.gap(12)),
			BackgroundTransparency = 1,
		}, {
			List = React.createElement("UIListLayout", {
				Padding = UDim.new(0, layout.gap(8)),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Credits = React.createElement(ResourceChip, {
				amount = hud.credits,
				layoutOrder = 1,
			}),
			Income = React.createElement(ResourceChip, {
				amount = hud.incomePerSec,
				label = "$/s",
				accent = theme.Colors.primaryHi,
				layoutOrder = 2,
			}),
			Buffer = React.createElement(ResourceChip, {
				amount = hud.buffer or 0,
				label = "buf",
				accent = theme.Colors.sell,
				layoutOrder = 3,
			}),
			Battery = React.createElement("Frame", {
				Size = UDim2.fromOffset(layout.px(168), layout.px(18)),
				BackgroundTransparency = 1,
				LayoutOrder = 4,
			}, {
				Bar = React.createElement(BatteryBar, { battery = hud.battery }),
			}),
		}),
		Actions = React.createElement("Frame", {
			Size = UDim2.fromOffset(layout.px(320), layout.touch(theme.Design.ROW_H)),
			Position = UDim2.new(1, -(layout.safeLeft + layout.gap(16)), 0, layout.safeTop + layout.gap(12)),
			AnchorPoint = Vector2.new(1, 0),
			BackgroundTransparency = 1,
		}, {
			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, layout.gap(8)),
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
			}),
			Collect = React.createElement(Button, {
				label = "Collect",
				variant = "sell",
				onActivated = ctx.collectAll,
			}),
			Build = React.createElement(Button, {
				label = "Blocks",
				variant = "primary",
				onActivated = ctx.openBuild,
			}),
			Lock = React.createElement(Button, {
				label = if hud.locked then "Unlock" else "Lock",
				variant = if hud.locked then "sell" else "secondary",
				onActivated = ctx.toggleLock,
			}),
		}),
		Inventory = React.createElement(InventoryPanel, {
			inventory = hud.inventory,
			selectedInvIndex = hud.selectedInvIndex,
			onSelect = ctx.selectInv,
			onRelease = ctx.releaseSelected,
		}),
		Build = React.createElement(BuildPanel, {
			open = hud.buildOpen and hud.rollOffer == nil,
			selectedBlockId = hud.selectedBlockId,
			blockInv = hud.blockInv,
			onSelectBlock = ctx.selectBlock,
			onClose = ctx.closeBuild,
		}),
		Roll = React.createElement(RollOfferPanel, {
			offer = hud.rollOffer,
			onBuy = ctx.confirmBuy or ctx.buyRolledPet,
			onSpinAgain = ctx.spinAgain,
			onClose = ctx.closeRoll,
		}),
		Tutorial = React.createElement(TutorialBanner, { step = hud.tutorialStep }),
		Toast = React.createElement(Toast, { text = hud.toast }),
		Reclaim = if hud.fogPetId ~= ""
			then React.createElement("Frame", {
				Size = UDim2.fromOffset(layout.px(160), layout.touch(theme.Design.ROW_H)),
				Position = UDim2.new(1, -(layout.safeLeft + layout.gap(16)), 1, -layout.gap(24)),
				AnchorPoint = Vector2.new(1, 1),
				BackgroundTransparency = 1,
			}, {
				Btn = React.createElement(Button, {
					label = "Reclaim Fog",
					variant = "secondary",
					onActivated = ctx.reclaimFog,
				}),
			})
			else nil,
	})
end

return App
