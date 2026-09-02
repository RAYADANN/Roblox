--!strict
-- SimPop chrome button: PNG + hard shadow + UIStroke + shine sweep.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local ImageIds = require(script.Parent.ImageIds)
local SimPopChrome = require(script.Parent.SimPopChrome)
local theme = require(script.Parent.Parent.theme)

export type ScrollRef = SimPopChrome.ScrollRef
export type SimPopTone = ImageIds.SimPopTone
export type SimPopOrientation = ImageIds.SimPopOrientation
export type SimPopVariant = ImageIds.SimPopVariant

export type Props = {
    tone: SimPopTone?,
    orientation: SimPopOrientation?,
    variant: SimPopVariant?,
    label: string?,
    size: UDim2,
    aspectRatio: number?,
    onActivated: (() -> ())?,
    disabled: boolean?,
    layoutOrder: number?,
    appearDelay: number?,
    shineIntervalSec: number?,
    scrollRef: ScrollRef?,
    scrollMarginPx: number?,
}

local SHINE_ASPECT = 92 / 144

local DEFAULT_LABELS: { [SimPopTone]: string } = {
    blue = "PLAY",
    green = "BUY",
    orange = "GO",
    red = "STOP",
}

local function resolveChrome(props: Props): (SimPopTone, ImageIds.ChromeDef)
    local orientation: SimPopOrientation = props.orientation or "horizontal"
    local tone: SimPopTone = props.tone or "blue"

    if props.variant == "horizontal" or props.variant == "vertical" then
        orientation = props.variant
        if props.tone == nil then
            tone = "blue"
        end
    end

    return tone, ImageIds.SimPop[tone][orientation]
end

local function SimPopButton(props: Props): React.Node
    local tone, chrome = resolveChrome(props)

    return SimPopChrome({
        size = props.size,
        background = chrome.background,
        shine = ImageIds.SimPop.shine,
        aspectRatio = props.aspectRatio or chrome.ASPECT,
        shineWidth = chrome.shineWidth,
        shineAspect = SHINE_ASPECT,
        cornerRadius = theme.Radius.button,
        strokeThickness = theme.Stroke.button,
        label = props.label or DEFAULT_LABELS[tone],
        disabled = props.disabled,
        layoutOrder = props.layoutOrder,
        appearDelay = props.appearDelay,
        shineIntervalSec = props.shineIntervalSec,
        scrollRef = props.scrollRef,
        scrollMarginPx = props.scrollMarginPx,
        onActivated = props.onActivated,
    })
end

return SimPopButton
