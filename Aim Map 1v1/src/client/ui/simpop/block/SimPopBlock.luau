--!strict
-- SimPop Block card — shop / inventory / case tile.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local ImageIds = require(script.Parent.ImageIds)
local SimPopChrome = require(script.Parent.Parent.SimPopChrome)
local theme = require(script.Parent.Parent.Parent.theme)

export type SimPopBlockTone = ImageIds.SimPopBlockTone

export type Props = {
    tone: SimPopBlockTone?,
    --- filled = rarity plate art; frame = red outline only (shop drops).
    variant: ("filled" | "frame")?,
    --- Frame variant: rarity tint on chrome (defaults from tone → theme.Rarity).
    tint: Color3?,
    size: UDim2,
    --- When false, fill `size` (use in UIGridLayout cells). Default true.
    preserveAspect: boolean?,
    aspectRatio: number?,
    --- Equipped / selected: orange stroke + dark-orange shadow.
    selected: boolean?,
    children: { [string]: React.Node }?,
    disabled: boolean?,
    layoutOrder: number?,
    shineIntervalSec: number?,
    onActivated: (() -> ())?,
}

local TONE_RARITY: { [SimPopBlockTone]: string } = {
    blue = "common",
    green = "uncommon",
    purple = "rare",
    orange = "legendary",
    red = "mythic",
}

local function SimPopBlock(props: Props): React.Node
    local tone: SimPopBlockTone = props.tone or "blue"
    local variant = props.variant or "filled"
    local chrome = if variant == "frame" then ImageIds.Block.frame else ImageIds.Block[tone]
    local preserve = if props.preserveAspect == nil then true else props.preserveAspect
    local aspect: number? = if preserve then (props.aspectRatio or chrome.ASPECT) else nil
    local selected = props.selected == true
    local rarityKey = TONE_RARITY[tone]
    local tint = props.tint
        or (if variant == "frame" then (theme.Rarity :: { [string]: Color3 })[rarityKey] else nil)

    return React.createElement(SimPopChrome, {
        size = props.size,
        background = chrome.background,
        shine = ImageIds.Block.shine,
        aspectRatio = aspect,
        shineWidth = chrome.shineWidth,
        shineAspect = ImageIds.SHINE_ASPECT,
        cornerScale = theme.SimPop.slotCorner,
        strokeThickness = theme.Stroke.slot,
        strokeColor = if selected then theme.SimPop.selectedStroke else theme.Colors.black,
        shadowColor = if selected then theme.SimPop.selectedShadow else theme.Colors.black,
        imageColor = tint,
        children = props.children,
        disabled = props.disabled,
        layoutOrder = props.layoutOrder,
        shineIntervalSec = props.shineIntervalSec,
        onActivated = props.onActivated,
    })
end

return SimPopBlock
