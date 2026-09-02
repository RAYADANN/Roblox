--!strict
-- SimPop long plate — shop offer / case row chrome.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local ImageIds = require(script.Parent.ImageIds)
local SimPopChrome = require(script.Parent.Parent.SimPopChrome)
local theme = require(script.Parent.Parent.Parent.theme)

export type LongTone = "blue" | "green" | "purple" | "orange" | "red" | "purpleDiamond"

export type Props = {
    tone: LongTone?,
    size: UDim2,
    --- When false, fill `size`. Default true (native long aspect).
    preserveAspect: boolean?,
    children: { [string]: React.Node }?,
    disabled: boolean?,
    layoutOrder: number?,
    shineIntervalSec: number?,
    onActivated: (() -> ())?,
}

local function SimPopLongBlock(props: Props): React.Node
    local tone: LongTone = props.tone or "purple"
    local chrome = ImageIds.LongBlock[tone]
    local preserve = if props.preserveAspect == nil then true else props.preserveAspect
    local aspect: number? = if preserve then chrome.ASPECT else nil

    return React.createElement(SimPopChrome, {
        size = props.size,
        background = chrome.background,
        shine = ImageIds.LongBlock.shine,
        aspectRatio = aspect,
        shineWidth = chrome.shineWidth,
        -- No aspect lock: stretch the long-plate gleam across full plate height.
        shineAspect = nil,
        cornerScale = theme.SimPop.cornerScale,
        strokeThickness = theme.Stroke.slot,
        strokeColor = theme.Colors.black,
        children = props.children,
        disabled = props.disabled,
        layoutOrder = props.layoutOrder,
        shineIntervalSec = props.shineIntervalSec,
        onActivated = props.onActivated,
    })
end

return SimPopLongBlock
