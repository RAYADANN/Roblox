--!strict
-- Base.SellTable Money label = local player's expected $/s from producing heroes.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseLayout = require(ReplicatedStorage.shared.util.BaseLayout)
local ContainerLogic = require(ReplicatedStorage.shared.util.ContainerLogic)
local WorldBillboard = require(script.Parent.WorldBillboard)

local SellTableBoard = {}

local _money: TextLabel? = nil
local _lastText = ""
local _retrying = false
local _warned = false

local function findMoneyLabel(): TextLabel?
    local tableModel = BaseLayout.getSellTable()
    if not tableModel then
        return nil
    end
    local money = tableModel:FindFirstChild("Money", true)
    if money and money:IsA("TextLabel") then
        return money
    end
    return nil
end

local function scheduleRetry()
    if _retrying then
        return
    end
    _retrying = true
    task.spawn(function()
        for _ = 1, 40 do
            task.wait(0.25)
            _money = findMoneyLabel()
            if _money then
                _retrying = false
                if _lastText ~= "" then
                    _money.Text = _lastText
                end
                return
            end
        end
        _retrying = false
        if not _warned then
            _warned = true
            warn("[SellTableBoard] Base.SellTable Money label missing after wait")
        end
    end)
end

function SellTableBoard.bind()
    _money = findMoneyLabel()
    if _money == nil then
        scheduleRetry()
    end
end

function SellTableBoard.setRate(coinsPerSec: number)
    local text = WorldBillboard.shortMoney(coinsPerSec) .. "/s"
    _lastText = text
    if _money == nil or not _money.Parent then
        SellTableBoard.bind()
    end
    if _money == nil then
        return
    end
    _money.Text = text
end

function SellTableBoard.applySlotsJson(slotsJson: string)
    local slots = {}
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(slotsJson)
    end)
    if ok and typeof(decoded) == "table" then
        slots = decoded
    end
    local rate = ContainerLogic.totalIncomePerSecond(slots)
    SellTableBoard.setRate(rate)
end

function SellTableBoard.start()
    SellTableBoard.bind()
    SellTableBoard.setRate(0)
end

return SellTableBoard
