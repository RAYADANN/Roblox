--!strict
-- Строка шага соц-награды: подпись + статус (готово / кнопка действия).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage:WaitForChild("Packages").Fusion)

local theme = require(script.Parent.Parent.theme)

local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local C = theme.C

export type Props = {
	layoutOrder: number,
	labelDone: string,
	labelPending: string,
	actionLabel: string,
	done: any,
	onAction: () -> (),
	disabled: any?,
	sc: ((number) -> number)?,
	textSize: number?,
	zIndex: number?,
}

local SocialRewardStepRow = {}

function SocialRewardStepRow.create(s: any, props: Props)
	local sc = props.sc or function(n: number): number
		return n
	end
	local textSize = props.textSize or 12
	local zIndex = props.zIndex or 4

	return s:New("Frame")({
		Name = "SocialRewardStep",
		LayoutOrder = props.layoutOrder,
		Size = UDim2.new(1, 0, 0, sc(44)),
		BackgroundColor3 = C.panelInner,
		BackgroundTransparency = s:Computed(function(use)
			return if use(props.done) then 0.35 else 0.1
		end),
		BorderSizePixel = 0,
		ZIndex = zIndex,
		[Children] = {
			s:New("UICorner")({ CornerRadius = UDim.new(0, sc(10)) }),
			s:New("UIStroke")({
				Color = s:Computed(function(use)
					return if use(props.done) then C.sell else C.textMuted
				end),
				Thickness = 1,
				Transparency = s:Computed(function(use)
					return if use(props.done) then 0.25 else 0.55
				end),
			}),
			s:New("TextLabel")({
				Size = UDim2.new(1, -sc(108), 1, -sc(8)),
				Position = UDim2.new(0, sc(12), 0, sc(4)),
				BackgroundTransparency = 1,
				Text = s:Computed(function(use)
					return if use(props.done) then props.labelDone else props.labelPending
				end),
				TextSize = textSize,
				Font = Enum.Font.GothamBold,
				TextColor3 = s:Computed(function(use)
					return if use(props.done) then C.sell else C.textMain
				end),
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				ZIndex = zIndex + 1,
			}),
			s:New("TextButton")({
				Size = UDim2.new(0, sc(92), 0, sc(30)),
				Position = UDim2.new(1, -sc(100), 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = s:Computed(function(use)
					return if use(props.done) then C.sell else C.btnBg
				end),
				BackgroundTransparency = s:Computed(function(use)
					return if use(props.done) then 0.15 else 0
				end),
				BorderSizePixel = 0,
				Text = s:Computed(function(use)
					if use(props.done) then
						return "✓"
					end
					return props.actionLabel
				end),
				TextSize = s:Computed(function(use)
					return if use(props.done) then textSize + 2 else math.max(9, textSize - 1)
				end),
				Font = Enum.Font.GothamBlack,
				TextColor3 = s:Computed(function(use)
					return if use(props.done) then C.sell else C.textMain
				end),
				AutoButtonColor = false,
				Active = s:Computed(function(use)
					return not use(props.done) and not use(props.disabled)
				end),
				Visible = s:Computed(function(use)
					return not use(props.done)
				end),
				ZIndex = zIndex + 1,
				[Children] = {
					s:New("UICorner")({ CornerRadius = UDim.new(0, sc(8)) }),
				},
				[OnEvent("Activated")] = props.onAction,
			}),
			s:New("TextLabel")({
				Size = UDim2.fromOffset(sc(28), sc(28)),
				Position = UDim2.new(1, -sc(36), 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				Text = "✓",
				TextSize = textSize + 4,
				Font = Enum.Font.GothamBlack,
				TextColor3 = C.sell,
				Visible = s:Computed(function(use)
					return use(props.done)
				end),
				ZIndex = zIndex + 1,
			}),
		},
	})
end

return SocialRewardStepRow
