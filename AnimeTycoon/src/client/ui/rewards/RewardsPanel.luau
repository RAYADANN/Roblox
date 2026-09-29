--!strict
-- Rewards: сетка 3×4, live timers, claimable highlight.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local MockData = require(script.Parent.MockData)
local RewardCard = require(script.Parent.components.RewardCard)
local RewardTimerLogic =
    require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("util").RewardTimerLogic)
local RewardsWindow = require(script.Parent.RewardsWindow)
local SG = require(script.Parent.layout)
local SkipAllButton = require(script.Parent.components.SkipAllButton)
local StrokeText = require(script.Parent.Parent.shop.components.StrokeText)
local tokens = require(script.Parent.tokens)
local types = require(script.Parent.types)

export type Props = {
    items: { types.RewardItem }?,
    skipPrice: number?,
    onClose: () -> (),
    onSkipAll: (() -> ())?,
    onClaim: ((id: string) -> ())?,
}

local function nowSec(): number
    return math.floor(workspace:GetServerTimeNow())
end

local function RewardsPanel(props: Props): React.Node
    local initial = props.items or MockData.items()
    local items, setItems = React.useState(initial)
    local skipPrice = props.skipPrice or MockData.skipPrice()
    local cols = SG.grid.columns

    local now, setNow = React.useState(nowSec)

    React.useEffect(function()
        local acc = 0
        local conn = RunService.Heartbeat:Connect(function(dt)
            acc += dt
            if acc < 0.25 then
                return
            end
            acc = 0
            setNow(nowSec())
        end)
        return function()
            conn:Disconnect()
        end
    end, {})

    local claimRows: { { claimed: boolean, unlockAt: number } } = {}
    for _, item in items do
        table.insert(claimRows, {
            claimed = item.claimed == true,
            unlockAt = item.unlockAt,
        })
    end
    local claimableIndex = RewardTimerLogic.firstClaimableIndex(claimRows, now)

    local function handleClaim(id: string)
        setItems(function(prev)
            local nextItems = table.clone(prev)
            for i, item in nextItems do
                if item.id == id then
                    local copy = table.clone(item)
                    copy.claimed = true
                    nextItems[i] = copy
                    break
                end
            end
            return nextItems
        end)
        if props.onClaim then
            props.onClaim(id)
        end
    end

    local children: { [string]: React.Node } = {}
    for i, item in items do
        local col = ((i - 1) % cols) + 1
        local row = math.floor((i - 1) / cols) + 1
        local x = SG.grid.xs[col]
        local y = SG.grid.ys[row]
        if x ~= nil and y ~= nil then
            children["R" .. item.id] = React.createElement(RewardCard, {
                item = item,
                position = UDim2.fromScale(x, y),
                size = SG.grid.cardSize,
                claimable = claimableIndex == i,
                layoutOrder = i,
                onClaim = handleClaim,
            })
        end
    end

    children.Leaving = React.createElement(StrokeText, {
        text = "Leaving Resets Progress!",
        color = tokens.titleWhite,
        strokeThickness = tokens.strokeText,
        size = SG.leaving.size,
        position = SG.leaving.pos,
        anchorPoint = SG.leaving.anchor,
        zIndex = 2,
    })

    children.Skip = React.createElement(SkipAllButton, {
        price = skipPrice,
        onActivated = props.onSkipAll or function() end,
    })

    return React.createElement(RewardsWindow, {
        title = "Rewards",
        onClose = props.onClose,
    }, children)
end

return RewardsPanel
