--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)

export type Props = {
    title: string,
    accent: Color3?,
    onClose: () -> (),
    children: React.Node?,
}

local function ModalChrome(props: Props): React.Node
    local layout = useLayout()
    local accent = props.accent or theme.Colors.primary
    local design = theme.Design
    -- One scale for the whole window. Children stay in design pixels.
    local fit = layout.modalFitScale(design.MODAL_W, design.MODAL_H)

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
    }, {
        Shell = React.createElement("Frame", {
            Size = UDim2.fromOffset(design.MODAL_W, design.MODAL_H),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = theme.Colors.panelBg,
            BorderSizePixel = 0,
            ClipsDescendants = true,
        }, {
            Scale = React.createElement("UIScale", { Scale = fit }),
            Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.panel }),
            Stroke = React.createElement("UIStroke", {
                Color = accent,
                Thickness = theme.Stroke.thick,
                Transparency = 0.12,
            }),
            AccentBar = React.createElement("Frame", {
                Size = UDim2.fromOffset(design.MODAL_W, 3),
                BackgroundColor3 = accent,
                BorderSizePixel = 0,
            }),
            Title = React.createElement("TextLabel", {
                Size = UDim2.fromOffset(design.MODAL_W - 80, design.HEADER_H),
                Position = UDim2.fromOffset(16, 8),
                BackgroundTransparency = 1,
                Text = props.title,
                TextSize = 20,
                Font = theme.Font.title,
                TextColor3 = theme.Colors.textMain,
                TextXAlignment = Enum.TextXAlignment.Left,
            }),
            Close = React.createElement("TextButton", {
                Size = UDim2.fromOffset(44, 44),
                Position = UDim2.new(1, -16, 0, 12),
                AnchorPoint = Vector2.new(1, 0),
                BackgroundColor3 = theme.Colors.bg3,
                BorderSizePixel = 0,
                Text = "X",
                TextSize = 18,
                Font = theme.Font.title,
                TextColor3 = theme.Colors.textMain,
                AutoButtonColor = false,
                [React.Event.Activated] = props.onClose,
            }, {
                Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.btn }),
            }),
            Content = React.createElement("Frame", {
                Size = UDim2.fromOffset(design.MODAL_W - 24, design.MODAL_H - design.HEADER_H - 16),
                Position = UDim2.fromOffset(12, design.HEADER_H),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, props.children),
        }),
    })
end

return ModalChrome
