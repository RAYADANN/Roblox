--!strict
-- SimPop Block card — shop / inventory tile (block shine, slot chrome tokens).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local ImageIds = require(script.Parent.ImageIds)
local SimPopChrome = require(script.Parent.Parent.SimPopChrome)
local theme = require(script.Parent.Parent.Parent.theme)

export type ScrollRef = SimPopChrome.ScrollRef
export type SimPopBlockTone = ImageIds.SimPopBlockTone

export type Props = {
    tone: SimPopBlockTone?,
    size: UDim2,
    aspectRatio: number?,
    children: { [string]: React.Node }?,
    disabled: boolean?,
    layoutOrder: number?,
    appearDelay: number?,
    shineIntervalSec: number?,
    scrollRef: ScrollRef?,
    scrollMarginPx: number?,
    onActivated: (() -> ())?,
}

local function SimPopBlock(props: Props): React.Node
    local tone: SimPopBlockTone = props.tone or "blue"
    local chrome = ImageIds.Block[tone]

    return SimPopChrome({
        size = props.size,
        background = chrome.background,
        shine = ImageIds.Block.shine,
        aspectRatio = props.aspectRatio or chrome.ASPECT,
        shineWidth = chrome.shineWidth,
        shineAspect = ImageIds.SHINE_ASPECT,
        cornerRadius = theme.Radius.slot,
        strokeThickness = theme.Stroke.slot,
        children = props.children,
        disabled = props.disabled,
        layoutOrder = props.layoutOrder,
        appearDelay = props.appearDelay,
        shineIntervalSec = props.shineIntervalSec,
        scrollRef = props.scrollRef,
        scrollMarginPx = props.scrollMarginPx,
        onActivated = props.onActivated,
    })
end

return SimPopBlock
