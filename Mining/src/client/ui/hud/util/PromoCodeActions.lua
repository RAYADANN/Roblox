--!strict

-- Клиентская активация промокода.



local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UserInputService = game:GetService("UserInputService")

local Fusion = require(ReplicatedStorage:WaitForChild("Packages").Fusion)

local peek = Fusion.peek

local Net = require(ReplicatedStorage:WaitForChild("Packages").Net)



local Notification = require(script.Parent.Parent.Parent.Notification)

local theme = require(script.Parent.Parent.theme)

local L = require(ReplicatedStorage:WaitForChild("shared").loc.Localization).t

local ServerMessage = require(ReplicatedStorage:WaitForChild("shared").loc.ServerMessage)



local C = theme.C

local SUCCESS_GOLD = Color3.fromRGB(255, 210, 50)



local PromoCodeActions = {}



local function trimCode(raw: string): string

	return raw:gsub("^%s+", ""):gsub("%s+$", "")

end



-- На таче TextBox.Changed часто не успевает до клика по кнопке — читаем поле напрямую.

local function resolveCodeText(fallback: string): string

	local pg = Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")

	if pg then

		for _, child in ipairs(pg:GetChildren()) do

			if child:IsA("ScreenGui") then

				local input = child:FindFirstChild("CodeInput", true)

				if input and input:IsA("TextBox") then

					local text = trimCode(input.Text)

					if text ~= "" then

						return text

					end

				end

			end

		end

	end



	local focused = UserInputService:GetFocusedTextBox()

	if focused then

		local text = trimCode(focused.Text)

		if text ~= "" then

			return text

		end

	end



	return trimCode(fallback)

end



function PromoCodeActions.tryRedeem(code: string, isBusy: any): boolean

	if peek(isBusy) then

		return false

	end

	local trimmed = resolveCodeText(code)

	if trimmed == "" then

		Notification.show({ text = L("modal.promo.enterCode"), color = C.closeBg, duration = 2.5 })

		return false

	end

	isBusy:set(true)

	task.spawn(function()

		local ok, result = pcall(function()

			return Net:Invoke("RedeemCode", trimmed)

		end)

		isBusy:set(false)

		if not ok then

			Notification.show({ text = L("modal.common.netError"), color = C.closeBg, duration = 3 })

			return

		end

		if typeof(result) == "table" and result.success then

			Notification.show({

				text = ServerMessage.t(result.message, result.messageParams),

				color = SUCCESS_GOLD,

				icon = "icon_gift",

				duration = 4,

			})

			return

		end

		local msg = ServerMessage.fromResult(result, "modal.promo.invalidCode")

		Notification.show({ text = msg, color = C.closeBg, duration = 3.5 })

	end)

	return true

end



return PromoCodeActions

