--!strict
-- Look sensitivity: slider + text input + step buttons (persisted via Zap).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local Button = require(script.Parent.Button)
local Constants = require(ReplicatedStorage.shared.data.Constants)
local SensitivityLogic = require(ReplicatedStorage.shared.util.SensitivityLogic)
local playUiClick = require(script.Parent.Parent.util.playUiClick)
local theme = require(script.Parent.Parent.theme)

export type Props = {
    value: number,
    onChange: (next: number) -> (),
    onClose: () -> (),
}

local function formatSens(value: number): string
    return string.format("%.1f", value)
end

local function SensitivityPanel(props: Props): React.Node
    local step = Constants.LOOK_SENSITIVITY_STEP
    local panelW = 600

    local draftText, setDraftText = React.useState(formatSens(props.value))
    local dragging, setDragging = React.useState(false)
    local trackRef = React.useRef(nil :: Frame?)

    React.useEffect(function()
        if not dragging then
            setDraftText(formatSens(props.value))
        end
    end, { props.value, dragging })

    local ratio = SensitivityLogic.toRatio(props.value)

    local function applyFromScreenX(screenX: number)
        local track = trackRef.current
        if not track then
            return
        end
        local width = math.max(1, track.AbsoluteSize.X)
        local t = math.clamp((screenX - track.AbsolutePosition.X) / width, 0, 1)
        props.onChange(SensitivityLogic.fromRatio(t))
    end

    local function commitText(raw: string)
        local parsed = tonumber(raw)
        if parsed == nil then
            setDraftText(formatSens(props.value))
            return
        end
        local next = SensitivityLogic.round(parsed)
        props.onChange(next)
        setDraftText(formatSens(next))
    end

    local function commitDraft()
        commitText(draftText)
    end

    React.useEffect(function()
        if not dragging then
            return
        end
        local moved = UserInputService.InputChanged:Connect(function(input)
            if
                input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch
            then
                applyFromScreenX(input.Position.X)
            end
        end)
        local ended = UserInputService.InputEnded:Connect(function(input)
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                setDragging(false)
            end
        end)
        return function()
            moved:Disconnect()
            ended:Disconnect()
        end
    end, { dragging, props.onChange })

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 40,
    }, {
        Dim = React.createElement("TextButton", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0.45,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 40,
            [React.Event.Activated] = playUiClick.wrapActivated(props.onClose),
        }),

        Panel = React.createElement("Frame", {
            Size = UDim2.fromOffset(panelW, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = theme.Colors.panelBg,
            BorderSizePixel = 0,
            ClipsDescendants = false,
            ZIndex = 41,
            Active = true, -- sink clicks so Dim does not close the panel
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.panel }),
            Stroke = React.createElement("UIStroke", {
                Color = theme.Colors.dockBorder,
                Thickness = theme.Stroke.medium,
            }),
            Pad = React.createElement("UIPadding", {
                PaddingTop = UDim.new(0, 24),
                PaddingBottom = UDim.new(0, 24),
                PaddingLeft = UDim.new(0, 27),
                PaddingRight = UDim.new(0, 27),
            }),
            Layout = React.createElement("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Top,
                Padding = UDim.new(0, 15),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),

            Title = React.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundTransparency = 1,
                Text = "Look sensitivity",
                TextColor3 = theme.Colors.textMain,
                TextSize = 27,
                Font = theme.Font.title,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = 1,
                ZIndex = 42,
            }),
            Hint = React.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 0, 27),
                BackgroundTransparency = 1,
                Text = `{Constants.LOOK_SENSITIVITY_MIN} – {Constants.LOOK_SENSITIVITY_MAX} · drag / type · saved`,
                TextColor3 = theme.Colors.textMuted,
                TextSize = 18,
                Font = theme.Font.body,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = 2,
                ZIndex = 42,
            }),

            InputRow = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, 60),
                BackgroundTransparency = 1,
                LayoutOrder = 3,
                ZIndex = 42,
                Active = true,
            }, {
                Box = React.createElement("TextBox", {
                    Size = UDim2.new(0.42, 0, 1, 0),
                    BackgroundColor3 = theme.Colors.bg1,
                    BorderSizePixel = 0,
                    Text = draftText,
                    PlaceholderText = "1.0",
                    TextColor3 = theme.Colors.gold,
                    PlaceholderColor3 = theme.Colors.textMuted,
                    TextSize = 33,
                    Font = theme.Font.heavy,
                    ClearTextOnFocus = false,
                    ZIndex = 43,
                    [React.Change.Text] = function(rbx: TextBox)
                        setDraftText(rbx.Text)
                    end,
                    [React.Event.FocusLost] = function(rbx: TextBox, _enterPressed: boolean)
                        -- Read from the TextBox: draft state can lag scripted/IME input.
                        commitText(rbx.Text)
                    end,
                }, {
                    Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.btn }),
                    Stroke = React.createElement("UIStroke", {
                        Color = theme.Colors.dockBorder,
                        Thickness = theme.Stroke.thin,
                    }),
                }),
                Range = React.createElement("TextLabel", {
                    Size = UDim2.new(0.55, 0, 1, 0),
                    Position = UDim2.fromScale(0.45, 0),
                    BackgroundTransparency = 1,
                    Text = "type value + Enter",
                    TextColor3 = theme.Colors.textMuted,
                    TextSize = 18,
                    Font = theme.Font.body,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 42,
                }),
            }),

            Slider = React.createElement("TextButton", {
                Size = UDim2.new(1, 0, 0, 42),
                BackgroundColor3 = Color3.new(0, 0, 0),
                BackgroundTransparency = 0.99, -- not 1: fully transparent lets clicks hit Dim
                Text = "",
                AutoButtonColor = false,
                LayoutOrder = 4,
                ZIndex = 42,
                Active = true,
                [React.Event.InputBegan] = function(rbx: TextButton, input: InputObject)
                    if
                        input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch
                    then
                        local track = rbx:FindFirstChild("Track")
                        trackRef.current = if track and track:IsA("Frame") then track else rbx
                        setDragging(true)
                        applyFromScreenX(input.Position.X)
                    end
                end,
            }, {
                Track = React.createElement("Frame", {
                    Size = UDim2.new(1, 0, 0, 12),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = theme.Colors.bg1,
                    BorderSizePixel = 0,
                    ZIndex = 42,
                    Active = true,
                }, {
                    Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
                    Fill = React.createElement("Frame", {
                        Size = UDim2.new(ratio, 0, 1, 0),
                        BackgroundColor3 = theme.Colors.primary,
                        BorderSizePixel = 0,
                        ZIndex = 43,
                    }, {
                        Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
                    }),
                    Thumb = React.createElement("Frame", {
                        Size = UDim2.fromOffset(27, 27),
                        Position = UDim2.new(ratio, 0, 0.5, 0),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundColor3 = theme.Colors.white,
                        BorderSizePixel = 0,
                        ZIndex = 44,
                    }, {
                        Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
                        Stroke = React.createElement("UIStroke", {
                            Color = theme.Colors.primary,
                            Thickness = theme.Stroke.medium,
                        }),
                    }),
                }),
            }),

            Row = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, 66),
                BackgroundTransparency = 1,
                LayoutOrder = 5,
                ZIndex = 42,
                Active = true,
            }, {
                List = React.createElement("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 12),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }),
                Minus = React.createElement(Button, {
                    label = "−",
                    variant = "secondary",
                    width = 108,
                    height = 66,
                    layoutOrder = 1,
                    zIndex = 42,
                    onActivated = function()
                        props.onChange(SensitivityLogic.step(props.value, -step))
                    end,
                }),
                Plus = React.createElement(Button, {
                    label = "+",
                    variant = "primary",
                    width = 108,
                    height = 66,
                    layoutOrder = 2,
                    zIndex = 42,
                    onActivated = function()
                        props.onChange(SensitivityLogic.step(props.value, step))
                    end,
                }),
                Done = React.createElement(Button, {
                    label = "Done",
                    variant = "sell",
                    width = 165,
                    height = 66,
                    layoutOrder = 3,
                    zIndex = 42,
                    onActivated = function()
                        commitDraft()
                        props.onClose()
                    end,
                }),
            }),
        }),
    })
end

return SensitivityPanel
