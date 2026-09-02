--!strict
-- Duel HUD — Scale layout of the DesignRoot canvas (no Offset / touchMul).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local HealthBar = require(script.Parent.HealthBar)
local HudIconButton = require(script.Parent.HudIconButton)
local SimPopButton = require(script.Parent.Parent.simpop.SimPopButton)
local SimPopIds = require(script.Parent.Parent.simpop.ImageIds)
local UiImageCatalog = require(ReplicatedStorage.shared.data.UiImageCatalog)
local theme = require(script.Parent.Parent.theme)

export type Props = {
    statusText: string,
    scoreText: string,
    skinText: string,
    recordText: string,
    hintText: string,
    health: number,
    maxHealth: number,
    showVsBot: boolean,
    showRematch: boolean,
    rematchReady: boolean,
    settingsOpen: boolean,
    onSettings: () -> (),
    onVsBot: () -> (),
    onRematch: () -> (),
    onShop: () -> (),
    onInvite: () -> (),
    onInventory: () -> (),
}

local LEFT: { UiImageCatalog.HudIconKey } = { "shop", "inventory", "invite" }
local RIGHT: { UiImageCatalog.HudIconKey } = { "settings", "sensitivity", "crosshair" }
local BUTTON_ASPECT = SimPopIds.SimPop.blue.horizontal.ASPECT

local function outlinedLabel(
    text: string,
    size: UDim2,
    position: UDim2,
    color: Color3,
    font: Enum.Font,
    xAlign: Enum.TextXAlignment?
): React.Node
    return React.createElement("TextLabel", {
        Size = size,
        Position = position,
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color,
        TextScaled = true,
        Font = font,
        TextXAlignment = xAlign or Enum.TextXAlignment.Left,
    }, {
        Outline = React.createElement("UIStroke", {
            Color = theme.Colors.black,
            Thickness = theme.Stroke.text,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
        }),
    })
end

local function rail(
    icons: { UiImageCatalog.HudIconKey },
    anchor: Vector2,
    position: UDim2,
    size: UDim2,
    gapScale: number,
    handlers: { [UiImageCatalog.HudIconKey]: (() -> ())? }
): React.Node
    local children: { [string]: React.Node } = {
        List = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(gapScale, 0),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    }

    for i, icon in icons do
        children[icon] = React.createElement(HudIconButton, {
            icon = icon,
            layoutOrder = i,
            widthScale = 1,
            onActivated = handlers[icon],
        })
    end

    return React.createElement("Frame", {
        Size = size,
        Position = position,
        AnchorPoint = anchor,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, children)
end

local function DuelHud(props: Props): React.Node
    local L = theme.Layout.hud
    local padX = L.padX
    local padY = L.padY

    local handlers: { [UiImageCatalog.HudIconKey]: (() -> ())? } = {
        shop = props.onShop,
        inventory = props.onInventory,
        invite = props.onInvite,
        settings = props.onSettings,
        sensitivity = props.onSettings,
        crosshair = props.onSettings,
    }

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, {
        Top = React.createElement("Frame", {
            Size = UDim2.new(1 - padX * 2, 0, L.topH, 0),
            Position = UDim2.fromScale(padX, padY),
            BackgroundTransparency = 1,
        }, {
            Status = outlinedLabel(
                props.statusText,
                UDim2.fromScale(1, L.statusH),
                UDim2.fromScale(0, 0),
                theme.Colors.textMain,
                theme.Font.display
            ),
            Score = outlinedLabel(
                props.scoreText,
                UDim2.fromScale(1, L.scoreH),
                UDim2.fromScale(0, L.statusH),
                theme.Colors.gold,
                theme.Font.display
            ),
        }),

        Left = rail(
            LEFT,
            Vector2.new(0, 0.5),
            UDim2.fromScale(padX, 0.5),
            UDim2.fromScale(L.railW, L.railH),
            L.iconGap,
            handlers
        ),
        Right = rail(
            RIGHT,
            Vector2.new(1, 0.5),
            UDim2.fromScale(1 - padX, 0.5),
            UDim2.fromScale(L.railW, L.railH),
            L.iconGap,
            handlers
        ),

        BottomLeft = React.createElement("Frame", {
            Size = UDim2.fromScale(L.bottomLeftW, L.bottomLeftH),
            Position = UDim2.new(padX, 0, 1 - L.bottomPad, 0),
            AnchorPoint = Vector2.new(0, 1),
            BackgroundTransparency = 1,
        }, {
            HpRow = React.createElement("Frame", {
                Size = UDim2.fromScale(1, L.hpRowH),
                BackgroundTransparency = 1,
            }, {
                Icon = React.createElement("ImageLabel", {
                    Size = UDim2.fromScale(L.hpIconW, 1),
                    Position = UDim2.fromScale(0, 0.5),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundTransparency = 1,
                    Image = UiImageCatalog.hudIcon("health"),
                    ScaleType = Enum.ScaleType.Fit,
                }, {
                    Aspect = React.createElement("UIAspectRatioConstraint", {
                        AspectRatio = 1,
                        DominantAxis = Enum.DominantAxis.Height,
                    }),
                }),
                Bar = React.createElement("Frame", {
                    Size = UDim2.new(1 - L.hpIconW - 0.02, 0, 1, 0),
                    Position = UDim2.fromScale(L.hpIconW + 0.02, 0),
                    BackgroundTransparency = 1,
                }, {
                    Inner = React.createElement(HealthBar, {
                        health = props.health,
                        maxHealth = props.maxHealth,
                    }),
                }),
            }),
            Skin = outlinedLabel(
                props.skinText,
                UDim2.fromScale(1, L.metaH),
                UDim2.fromScale(0, L.hpRowH + 0.04),
                theme.Colors.textSub,
                theme.Font.body
            ),
            Record = outlinedLabel(
                props.recordText,
                UDim2.fromScale(1, L.metaH),
                UDim2.fromScale(0, L.hpRowH + L.metaH + 0.06),
                theme.Colors.textMuted,
                theme.Font.body
            ),
            Hint = outlinedLabel(
                props.hintText,
                UDim2.fromScale(1, L.metaH),
                UDim2.fromScale(0, L.hpRowH + L.metaH * 2 + 0.08),
                theme.Colors.textMuted,
                theme.Font.body
            ),
        }),

        BottomCta = React.createElement("Frame", {
            Size = UDim2.fromScale(L.ctaW, L.ctaH),
            Position = UDim2.fromScale(0.5, 1 - L.bottomPad),
            AnchorPoint = Vector2.new(0.5, 1),
            BackgroundTransparency = 1,
        }, {
            List = React.createElement("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(L.ctaGap, 0),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
            VsBot = if props.showVsBot
                then React.createElement(SimPopButton, {
                    tone = "blue",
                    label = "VS BOT",
                    size = UDim2.fromScale(L.ctaBtnW, 1),
                    aspectRatio = BUTTON_ASPECT,
                    layoutOrder = 1,
                    onActivated = props.onVsBot,
                })
                else nil,
            Rematch = if props.showRematch
                then React.createElement(SimPopButton, {
                    tone = "green",
                    label = if props.rematchReady then "READY" else "REMATCH",
                    size = UDim2.fromScale(L.ctaBtnW, 1),
                    aspectRatio = BUTTON_ASPECT,
                    layoutOrder = 2,
                    disabled = props.rematchReady,
                    onActivated = props.onRematch,
                })
                else nil,
            Sens = React.createElement(SimPopButton, {
                tone = if props.settingsOpen then "orange" else "blue",
                orientation = "horizontal",
                label = if props.settingsOpen then "CLOSE" else "SENS",
                size = UDim2.fromScale(L.ctaSensW, 1),
                aspectRatio = BUTTON_ASPECT,
                layoutOrder = 3,
                onActivated = props.onSettings,
            }),
        }),
    })
end

return DuelHud
