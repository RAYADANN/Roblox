--!strict
-- FTUE overlay: Simpop white dialog (EN). World cue lives in TutorialSpotlight.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local playUiSound = require(script.Parent.Parent.util.playUiSound)
local theme = require(script.Parent.Parent.theme)
local useHoverPress = require(script.Parent.Parent.hooks.useHoverPress)

export type Props = {
    step: number,
    onNext: () -> (),
    onSkip: () -> (),
}

export type Step = {
    title: string,
    body: string,
}

local STEPS: { Step } = {
    {
        title = "Buy your first Dummy",
        body = "Walk onto the Buy pad and press the button.",
    },
    {
        title = "Pick up a cube",
        body = "Go to where cubes drop and collect one.",
    },
    {
        title = "Sell your cube",
        body = "Carry it to the Sell pad to deposit.",
    },
    {
        title = "Collect your cash",
        body = "Step on the Cash pad and claim your reward.",
    },
}

local L = theme.Layout.tutorial

local function outlinedText(kind: "title" | "body"): { [string]: React.Node }
    local isTitle = kind == "title"
    return {
        Outline = React.createElement("UIStroke", {
            Color = theme.Colors.black,
            Thickness = if isTitle then theme.Stroke.title else theme.Stroke.body,
            Transparency = 0,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
            LineJoinMode = Enum.LineJoinMode.Round,
            StrokeSizingMode = if isTitle
                then Enum.StrokeSizingMode.FixedSize
                else Enum.StrokeSizingMode.ScaledSize,
        }),
    }
end

local function Tutorial(props: Props): React.Node
    local step = STEPS[math.clamp(props.step, 1, #STEPS)]
    local nextScale, nextHandlers = useHoverPress({
        hoverScale = 1.06,
        pressScale = 0.94,
    })
    local skipScale, skipHandlers = useHoverPress({
        hoverScale = 1.04,
        pressScale = 0.96,
    })

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 100,
    }, {
        Card = React.createElement("Frame", {
            Size = UDim2.fromScale(L.cardW, L.cardH),
            Position = UDim2.fromScale(0.5, L.cardY),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = theme.Colors.white,
            BorderSizePixel = 0,
            ZIndex = 102,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = UDim.new(L.cardCornerScale, 0),
            }),
            Stroke = React.createElement("UIStroke", {
                Color = theme.Colors.black,
                Thickness = theme.Stroke.panel,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }),
            Title = React.createElement("TextLabel", {
                Size = UDim2.fromScale(1 - L.padX * 2, L.titleH),
                Position = UDim2.fromScale(L.padX, L.titleY),
                BackgroundTransparency = 1,
                Text = step.title,
                Font = theme.Font.display,
                TextScaled = true,
                TextColor3 = theme.Colors.white,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 103,
            }, outlinedText("title")),
            Body = React.createElement("TextLabel", {
                Size = UDim2.fromScale(1 - L.padX * 2, L.bodyH),
                Position = UDim2.fromScale(L.padX, L.bodyY),
                BackgroundTransparency = 1,
                Text = step.body,
                Font = theme.Font.display,
                TextScaled = true,
                TextWrapped = true,
                TextColor3 = theme.Colors.white,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                ZIndex = 103,
            }, outlinedText("body")),
            Skip = React.createElement("TextButton", {
                Size = UDim2.fromScale(L.skipW, L.btnH),
                Position = UDim2.fromScale(L.padX, 1 - L.btnPadY),
                AnchorPoint = Vector2.new(0, 1),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Text = "SKIP",
                Font = theme.Font.display,
                TextScaled = true,
                TextColor3 = theme.Colors.white,
                AutoButtonColor = false,
                ZIndex = 103,
                [React.Event.Activated] = function()
                    playUiSound.play("ui_click")
                    props.onSkip()
                end,
                [React.Event.MouseEnter] = skipHandlers.onMouseEnter,
                [React.Event.MouseLeave] = skipHandlers.onMouseLeave,
                [React.Event.MouseButton1Down] = skipHandlers.onMouseDown,
                [React.Event.MouseButton1Up] = skipHandlers.onMouseUp,
            }, {
                Scale = React.createElement("UIScale", { Scale = skipScale }),
                Outline = outlinedText("body").Outline,
            }),
            Next = React.createElement("TextButton", {
                Size = UDim2.fromScale(L.nextW, L.btnH),
                Position = UDim2.fromScale(1 - L.padX, 1 - L.btnPadY),
                AnchorPoint = Vector2.new(1, 1),
                BackgroundColor3 = theme.Colors.sell,
                BorderSizePixel = 0,
                Text = if props.step >= #STEPS then "DONE" else "NEXT",
                Font = theme.Font.display,
                TextScaled = true,
                TextColor3 = theme.Colors.white,
                AutoButtonColor = false,
                ZIndex = 103,
                [React.Event.Activated] = function()
                    playUiSound.play("ui_click")
                    props.onNext()
                end,
                [React.Event.MouseEnter] = nextHandlers.onMouseEnter,
                [React.Event.MouseLeave] = nextHandlers.onMouseLeave,
                [React.Event.MouseButton1Down] = nextHandlers.onMouseDown,
                [React.Event.MouseButton1Up] = nextHandlers.onMouseUp,
            }, {
                Scale = React.createElement("UIScale", { Scale = nextScale }),
                Corner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(L.btnCornerScale, 0),
                }),
                Stroke = React.createElement("UIStroke", {
                    Color = theme.Colors.black,
                    Thickness = theme.Stroke.panel * 0.45,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                }),
                Outline = outlinedText("body").Outline,
            }),
        }),
    })
end

return Tutorial
