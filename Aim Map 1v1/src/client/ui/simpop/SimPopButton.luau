--!strict
-- SimPop tone button (blue/green/orange/red chrome).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local ImageIds = require(script.Parent.ImageIds)
local SimPopChrome = require(script.Parent.SimPopChrome)

export type SimPopTone = ImageIds.SimPopTone
export type SimPopOrientation = ImageIds.SimPopOrientation

export type Props = {
    tone: SimPopTone?,
    orientation: SimPopOrientation?,
    label: string?,
    size: UDim2,
    aspectRatio: number?,
    --- When false, fill `size` (inventory EQUIP bar). Default true.
    preserveAspect: boolean?,
    strokeThickness: number?,
    strokeColor: Color3?,
    onActivated: (() -> ())?,
    disabled: boolean?,
    layoutOrder: number?,
    shineIntervalSec: number?,
}

local SHINE_ASPECT = 92 / 144

local DEFAULT_LABELS: { [SimPopTone]: string } = {
    blue = "PLAY",
    green = "BUY",
    orange = "GO",
    red = "STOP",
    purple = "CASE",
}

local function SimPopButton(props: Props): React.Node
    local tone: SimPopTone = props.tone or "blue"
    local orientation: SimPopOrientation = props.orientation or "horizontal"
    local chrome = ImageIds.SimPop[tone][orientation]
    local preserve = if props.preserveAspect == nil then true else props.preserveAspect
    local aspect: number? = if preserve then (props.aspectRatio or chrome.ASPECT) else nil

    return React.createElement(SimPopChrome, {
        size = props.size,
        background = chrome.background,
        shine = ImageIds.SimPop.shine,
        aspectRatio = aspect,
        shineWidth = chrome.shineWidth,
        shineAspect = SHINE_ASPECT,
        strokeThickness = props.strokeThickness,
        strokeColor = props.strokeColor,
        label = props.label or DEFAULT_LABELS[tone],
        disabled = props.disabled,
        layoutOrder = props.layoutOrder,
        shineIntervalSec = props.shineIntervalSec,
        onActivated = props.onActivated,
    })
end

return SimPopButton
