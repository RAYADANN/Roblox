--!strict
-- Шкала сна (GDD 11.1): сверху по центру, цвет по фазе, значок луна → глаз → сердитое лицо.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local GiantConfig = require(ReplicatedStorage.shared.data.GiantConfig)
local MotionPresets = require(script.Parent.Parent.motion.MotionPresets)
local theme = require(script.Parent.Parent.theme)
local useFlipperSpring = require(script.Parent.Parent.hooks.useFlipperSpring)
local useLayout = require(script.Parent.Parent.hooks.useLayout)

export type Props = {
    noise: number,
    phase: string,
}

local PHASES: { [string]: { color: Color3, label: string } } = {
    Deep = { color = Color3.fromHex("#4CD964"), label = "Zzz... Deep Sleep" },
    Restless = { color = Color3.fromHex("#F5CD30"), label = "Restless..." },
    EyeOpen = { color = Color3.fromHex("#DA8541"), label = "ONE EYE OPEN - FREEZE!" },
    Wake = { color = Color3.fromHex("#C4281C"), label = "HE'S AWAKE!" },
}

local function NoiseBar(props: Props): React.Node
    local layout = useLayout()
    local fill = useFlipperSpring(
        math.clamp(props.noise / GiantConfig.NOISE_MAX, 0, 1),
        MotionPresets.SPRING_NUMBER
    )
    local phase = PHASES[props.phase] or PHASES.Deep

    local function marker(at: number): React.Node
        return React.createElement("Frame", {
            Size = UDim2.new(0, layout.px(2), 1, 0),
            Position = UDim2.fromScale(at / GiantConfig.NOISE_MAX, 0),
            BackgroundColor3 = theme.Colors.white,
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            ZIndex = 3,
        })
    end

    return React.createElement("Frame", {
        Size = UDim2.fromOffset(layout.px(380), layout.px(58)),
        Position = UDim2.new(0.5, 0, 0, layout.safeTop + layout.gap(10)),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
    }, {
        Label = React.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, layout.px(24)),
            BackgroundTransparency = 1,
            Text = phase.label,
            TextColor3 = phase.color,
            TextStrokeTransparency = 0.2,
            Font = theme.Font.heavy,
            TextSize = layout.text(20, 18),
        }),
        Track = React.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, layout.px(22)),
            Position = UDim2.fromOffset(0, layout.px(30)),
            BackgroundColor3 = theme.Colors.bgChip,
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.pill }),
            Stroke = React.createElement(
                "UIStroke",
                { Color = theme.Colors.outlineDark, Thickness = 3 }
            ),
            Fill = React.createElement("Frame", {
                Size = UDim2.fromScale(fill, 1),
                BackgroundColor3 = phase.color,
                BorderSizePixel = 0,
                ZIndex = 2,
            }, {
                Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.pill }),
            }),
            Restless = marker(GiantConfig.RESTLESS_AT),
            Eye = marker(GiantConfig.EYE_OPEN_AT),
        }),
    })
end

return NoiseBar
