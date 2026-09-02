--!strict
-- Back-compat alias: SimPopButton variant "horizontal".

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local SimPopButton = require(script.Parent.SimPopButton)

export type ScrollRef = SimPopButton.ScrollRef

export type Props = {
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

local function BlueButton(props: Props): React.Node
    return SimPopButton({
        variant = "horizontal",
        label = props.label,
        size = props.size,
        aspectRatio = props.aspectRatio,
        onActivated = props.onActivated,
        disabled = props.disabled,
        layoutOrder = props.layoutOrder,
        appearDelay = props.appearDelay,
        shineIntervalSec = props.shineIntervalSec,
        scrollRef = props.scrollRef,
        scrollMarginPx = props.scrollMarginPx,
    })
end

return BlueButton
