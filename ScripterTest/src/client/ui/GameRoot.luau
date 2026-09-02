--!strict
-- Корень React: HUD + сеть + тосты + Custom ProximityPrompt UI.

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local App = require(script.Parent.App)
local HudProvider = require(script.Parent.context.HudProvider)
local ToastStack = require(script.Parent.components.ToastStack)
local ProximityPromptUI = require(script.Parent.components.ProximityPromptUI)
local Zap = require(script.Parent.Parent.net.NetClient)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local SoundManager = require(script.Parent.Parent.core.SoundManager)

type ToastItem = ToastStack.ToastItem
type PromptView = ProximityPromptUI.PromptView

local ACH_TITLES: { [string]: string } = {
	buyAllArea1 = "Купить все плиты в Area1",
	buyAllArea2 = "Купить все плиты в Area2",
	fallOffMap = "Спрыгнуть за пределы карты",
	jumpFiveTimes = "Прыгнуть пять раз",
}

local function GameRoot(): React.Node
	local hud, setHud = React.useState(NetTypes.emptyHud())
	local achievementsOpen, setAchievementsOpen = React.useState(false)
	local toasts, setToasts = React.useState({} :: { ToastItem })
	local promptView, setPromptView = React.useState(nil :: PromptView?)
	local toastIdRef = React.useRef(0)

	local pushToast = React.useCallback(function(text: string, color: Color3)
		toastIdRef.current += 1
		local id = toastIdRef.current
		setToasts(function(prev)
			local next = table.clone(prev)
			table.insert(next, { id = id, text = text, color = color })
			return next
		end)
		task.delay(2.5, function()
			setToasts(function(prev)
				local next = {}
				for _, item in prev do
					if item.id ~= id then
						table.insert(next, item)
					end
				end
				return next
			end)
		end)
	end, {})

	React.useEffect(function()
		local cleanups = {
			Zap.PlayerDataSync.On(function(value)
				setHud(NetTypes.fromZapSync(value))
			end),
			Zap.Notify.On(function(payload)
				if payload.kind == "shop_ok" then
					SoundManager.play("shop_ok")
					pushToast("Покупка успешна!", Color3.fromRGB(80, 220, 120))
				elseif payload.kind == "shop_fail" then
					SoundManager.play("shop_fail")
					pushToast(payload.payload, Color3.fromRGB(255, 120, 80))
				end
			end),
			Zap.AchievementUnlocked.On(function(payload)
				SoundManager.play("achievement_unlock")
				local title = ACH_TITLES[payload.id] or payload.id
				pushToast(`Достижение: {title}`, Color3.fromRGB(255, 212, 38))
			end),
			ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
				if prompt.Style ~= Enum.ProximityPromptStyle.Custom then
					return
				end
				local parent = prompt.Parent
				local adornee = if parent and parent:IsA("BasePart") then parent else nil
				local keyText = UserInputService:GetStringForKeyCode(prompt.KeyboardKeyCode)
				if keyText == "" then
					keyText = prompt.KeyboardKeyCode.Name
				end
				setPromptView({
					keyText = keyText,
					objectText = prompt.ObjectText,
					actionText = prompt.ActionText,
					adornee = adornee,
					inputType = inputType,
				})
			end),
			ProximityPromptService.PromptHidden:Connect(function(prompt)
				if prompt.Style ~= Enum.ProximityPromptStyle.Custom then
					return
				end
				setPromptView(nil)
			end),
		}

		return function()
			for _, cleanup in cleanups do
				if typeof(cleanup) == "function" then
					cleanup()
				elseif typeof(cleanup) == "RBXScriptConnection" then
					(cleanup :: RBXScriptConnection):Disconnect()
				end
			end
		end
	end, { pushToast })

	return React.createElement(HudProvider, {
		hud = hud,
		achievementsOpen = achievementsOpen,
		setAchievementsOpen = setAchievementsOpen,
	}, {
		App = React.createElement(App),
		Toasts = React.createElement(ToastStack, { items = toasts }),
		Prompt = React.createElement(ProximityPromptUI, { prompt = promptView }),
	})
end

return GameRoot
