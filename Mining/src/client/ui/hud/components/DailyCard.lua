--!strict
-- DailyCard.lua — Phase 10.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Fusion = require(ReplicatedStorage:WaitForChild("Packages").Fusion)

local ScopeFactory = require(script.Parent.Parent.ScopeFactory)
local theme = require(script.Parent.Parent.theme)
local DailyRewardDatabase = require(ReplicatedStorage:WaitForChild("shared").data.DailyRewardDatabase)
local UiAssets = require(ReplicatedStorage:WaitForChild("shared").data.UiAssets)
local L = require(ReplicatedStorage:WaitForChild("shared").loc.Localization).t

local Children = Fusion.Children
local C = theme.C
local ICON = theme.ICON

local RARITY_COLOR = theme.RARITY_COLOR

export type CardState = "past" | "current" | "future"

export type Props = {
    cycleDay: number,
    state: CardState,
    layoutOrder: number?,
    width: number?,
    height: number?,
}

local DailyCard = {}

function DailyCard.startPulse(stroke: UIStroke): () -> ()
    if not stroke or not stroke:IsA("UIStroke") then
        return function() end
    end
    local running = true
    task.spawn(function()
        local goingUp = false
        while running and stroke.Parent do
            local target = goingUp and 0.05 or 0.45
            local tween = TweenService:Create(stroke, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Transparency = target,
            })
            tween:Play()
            tween.Completed:Wait()
            goingUp = not goingUp
        end
    end)
    return function()
        running = false
    end
end

function DailyCard.create(s: ScopeFactory.HudScope, props: Props)
    local cardW = props.width or 100
    local cardH = props.height or 140
    local cardSize = UDim2.fromOffset(cardW, cardH)
    local reward = DailyRewardDatabase.get(props.cycleDay)
    if not reward then
        return s:New("Frame")({
            Size = cardSize,
            BackgroundTransparency = 1,
        })
    end
    local stateName = props.state
    local isCurrent = stateName == "current"
    local rarityColor = RARITY_COLOR[reward.rarity] or C.common
    local iconKey = DailyRewardDatabase.iconFor(reward)
    local rewardImage = UiAssets.resolve(iconKey)

    local stroke = s:New("UIStroke")({
        Name = "MainStroke",
        Color = if isCurrent then C.gold else rarityColor,
        Thickness = if isCurrent then 4 else if stateName == "future" then 1.5 else 2,
        Transparency = if stateName == "future" then 0.7 else 0.05,
    })

    local cardBg
    if stateName == "future" then
        cardBg = Color3.fromRGB(28, 28, 38)
    elseif stateName == "past" then
        cardBg = Color3.fromRGB(40, 40, 55)
    else
        cardBg = Color3.fromRGB(72, 58, 28)
    end

    local topOffset = if isCurrent then 26 else 6
    local iconSize = 40

    local cardChildren: { any } = {
        s:New("UICorner")({ CornerRadius = UDim.new(0, 8) }),
        stroke,
    }

    if isCurrent then
        table.insert(cardChildren, s:New("Frame")({
            Name = "TodayBadge",
            Size = UDim2.new(1, -8, 0, 20),
            Position = UDim2.new(0, 4, 0, 4),
            BackgroundColor3 = C.gold,
            BorderSizePixel = 0,
            ZIndex = 5,
            [Children] = {
                s:New("UICorner")({ CornerRadius = UDim.new(0, 6) }),
                s:New("TextLabel")({
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Text = L("modal.daily.today"),
                    TextSize = 11,
                    Font = Enum.Font.GothamBlack,
                    TextColor3 = Color3.fromRGB(40, 25, 0),
                    ZIndex = 6,
                }),
            },
        }))
    end

    if not isCurrent then
        table.insert(cardChildren, s:New("TextLabel")({
            Size = UDim2.new(1, 0, 0, 18),
            Position = UDim2.new(0, 0, 0, topOffset),
            BackgroundTransparency = 1,
            Text = L("modal.daily.dayN", { day = props.cycleDay }),
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            TextColor3 = C.textLabel,
            ZIndex = 3,
        }))
    end
    if stateName == "past" then
        table.insert(cardChildren, s:New("ImageLabel")({
            Size = UDim2.fromOffset(32, 32),
            Position = UDim2.new(0.5, -16, 0.5, -28),
            BackgroundTransparency = 1,
            Image = UiAssets.image("icon_check"),
            ImageColor3 = ICON.tint,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 3,
        }))
    else
        table.insert(cardChildren, s:New("ImageLabel")({
            Name = "RewardIcon",
            Size = UDim2.fromOffset(iconSize, iconSize),
            Position = UDim2.new(0.5, -iconSize / 2, 0.5, -28),
            BackgroundTransparency = 1,
            Image = rewardImage,
            ImageColor3 = Color3.fromRGB(255, 255, 255),
            ImageTransparency = if stateName == "future" then ICON.mutedAlpha else 0,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 4,
        }))
    end

    table.insert(cardChildren, s:New("TextLabel")({
        Name = "RewardLabel",
        Size = UDim2.new(1, -8, 0, 36),
        Position = UDim2.new(0, 4, 1, -44),
        BackgroundTransparency = 1,
        Text = L(reward.label),
        TextSize = if isCurrent then 14 else 13,
        Font = Enum.Font.GothamBold,
        TextColor3 = if stateName == "future" then C.textMuted else if isCurrent then C.goldHi else C.textMain,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 4,
    }))

    return s:New("Frame")({
        Name = "DailyCard_" .. tostring(props.cycleDay),
        Size = cardSize,
        BackgroundColor3 = cardBg,
        BackgroundTransparency = if stateName == "future" then 0.35 else 0,
        BorderSizePixel = 0,
        LayoutOrder = props.layoutOrder or props.cycleDay,
        ZIndex = if isCurrent then 8 else 4,
        [Children] = cardChildren,
    })
end

return DailyCard
