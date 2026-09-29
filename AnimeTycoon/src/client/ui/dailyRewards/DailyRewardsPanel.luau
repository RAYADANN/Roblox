--!strict
-- Daily Rewards: 3×2 дни + Day 7 баннер; claim по порядку.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local DailyRewardsWindow = require(script.Parent.DailyRewardsWindow)
local Day7Card = require(script.Parent.components.Day7Card)
local DayCard = require(script.Parent.components.DayCard)
local MockData = require(script.Parent.MockData)
local SG = require(script.Parent.layout)
local types = require(script.Parent.types)

export type Props = {
    items: { types.DailyRewardItem }?,
    onClose: () -> (),
    onClaim: ((id: string) -> ())?,
}

local function firstClaimableIndex(items: { types.DailyRewardItem }): number?
    for i, item in items do
        if item.claimed ~= true then
            return i
        end
    end
    return nil
end

local function DailyRewardsPanel(props: Props): React.Node
    local initial = props.items or MockData.items()
    local items, setItems = React.useState(initial)
    local claimableIndex = firstClaimableIndex(items)

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

    for i = 1, 6 do
        local item = items[i]
        if item == nil then
            continue
        end
        local col = ((i - 1) % 3) + 1
        local row = math.floor((i - 1) / 3) + 1
        local x = SG.grid.xs[col]
        local y = SG.grid.ys[row]
        if x ~= nil and y ~= nil then
            children["D" .. item.id] = React.createElement(DayCard, {
                item = item,
                position = UDim2.fromScale(x, y),
                size = SG.grid.cardSize,
                claimable = claimableIndex == i,
                onClaim = handleClaim,
            })
        end
    end

    local day7 = items[7]
    if day7 ~= nil then
        children.Day7 = React.createElement(Day7Card, {
            item = day7,
            claimable = claimableIndex == 7,
            onClaim = handleClaim,
        })
    end

    return React.createElement(DailyRewardsWindow, {
        title = "Daily Rewards",
        onClose = props.onClose,
    }, children)
end

return DailyRewardsPanel
