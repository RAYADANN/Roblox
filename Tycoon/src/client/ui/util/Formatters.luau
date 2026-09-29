--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FormatMoney = require(ReplicatedStorage.shared.util.FormatMoney)

return { shortNumber = FormatMoney.short }
