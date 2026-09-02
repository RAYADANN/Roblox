--!strict
-- Магазин плит: touch → покупка → зелёный + BillboardGui.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.shared.data.Constants)
local ShopDatabase = require(ReplicatedStorage.shared.data.ShopDatabase)
local ShopLogic = require(ReplicatedStorage.shared.util.ShopLogic)
local AchievementLogic = require(ReplicatedStorage.shared.util.AchievementLogic)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local ProfileManager = require(script.Parent.ProfileManager)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)

type HudSyncPayload = NetTypes.HudSyncPayload
type AreaId = ShopDatabase.AreaId

export type Deps = {
	profileManager: ProfileManager.ProfileManager,
	syncHud: (player: Player, payload: HudSyncPayload?) -> (),
	notify: (player: Player, kind: string, payload: string) -> (),
	onAchievement: (player: Player, id: string) -> (),
}

local ShopManager = {}
ShopManager.__index = ShopManager

local BOUGHT = Color3.fromRGB(Constants.SHOP_BOUGHT_COLOR[1], Constants.SHOP_BOUGHT_COLOR[2], Constants.SHOP_BOUGHT_COLOR[3])

local function getShop(areaId: string): Model?
	local scriptabled = workspace:FindFirstChild("Scriptabled")
	if not scriptabled then
		return nil
	end
	local area = scriptabled:FindFirstChild(areaId)
	if not area then
		return nil
	end
	local shop = area:FindFirstChild("Shop")
	if shop and shop:IsA("Model") then
		return shop
	end
	return nil
end

local function ensureBillboard(pad: BasePart, price: number)
	local existing = pad:FindFirstChild("PriceBillboard")
	if existing then
		existing:Destroy()
	end

	local bb = Instance.new("BillboardGui")
	bb.Name = "PriceBillboard"
	bb.Size = UDim2.fromOffset(140, 48)
	bb.StudsOffset = Vector3.new(0, 3.2, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 80
	bb.Parent = pad

	local label = Instance.new("TextLabel")
	label.Name = "Price"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = `{price}`
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.Parent = bb

	local outline = Instance.new("UIStroke")
	outline.Color = Color3.fromRGB(0, 0, 0)
	outline.Thickness = 3
	outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	outline.Parent = label
end

function ShopManager.new(deps: Deps)
	return setmetatable({
		_deps = deps,
		_debounce = {} :: { [string]: boolean },
		_started = false,
	}, ShopManager)
end

function ShopManager:_applyVisual(pad: BasePart, bought: boolean, price: number)
	if bought then
		pad.Color = BOUGHT
		pad.Material = Enum.Material.Neon
		local bb = pad:FindFirstChild("PriceBillboard")
		if bb then
			local label = bb:FindFirstChild("Price")
			if label and label:IsA("TextLabel") then
				label.Text = "DONE"
				label.TextColor3 = Color3.fromRGB(255, 255, 255)
			end
		end
	else
		pad.Color = Color3.fromRGB(
			Constants.SHOP_DEFAULT_COLOR[1],
			Constants.SHOP_DEFAULT_COLOR[2],
			Constants.SHOP_DEFAULT_COLOR[3]
		)
		pad.Material = Enum.Material.Plastic
		ensureBillboard(pad, price)
	end
end

function ShopManager:_tryBuy(player: Player, areaId: string, padId: string, pad: BasePart)
	local key = `{player.UserId}:{areaId}:{padId}`
	if self._debounce[key] then
		return
	end
	self._debounce[key] = true

	local profileManager = self._deps.profileManager
	local data = profileManager:get(player)
	if not data then
		self._debounce[key] = false
		return
	end

	local areaShop = data.shop[areaId :: AreaId]
	if not areaShop then
		self._debounce[key] = false
		return
	end
	if areaShop[padId] then
		self._debounce[key] = false
		return
	end

	local cost = ShopLogic.price(areaId, padId)
	if cost == nil then
		self._debounce[key] = false
		return
	end
	if not ShopLogic.canAfford(data.points, cost) then
		self._deps.notify(player, "shop_fail", "Недостаточно очков")
		task.delay(0.4, function()
			self._debounce[key] = false
		end)
		return
	end

	local unlockedId: string? = nil
	local ok = profileManager:mutate(player, function(d)
		local pads = d.shop[areaId :: AreaId]
		if pads[padId] then
			return
		end
		if d.points < cost then
			return
		end
		d.points -= cost
		pads[padId] = true

		local achId = AchievementLogic.areaAchievementId(areaId)
		if achId and AchievementLogic.shouldUnlockBuyAll(areaId, pads) then
			local achievements = d.achievements :: { [string]: boolean }
			if not achievements[achId] then
				achievements[achId] = true
				unlockedId = achId
			end
		end
	end)

	if ok then
		self:_applyVisual(pad, true, cost)
		self._deps.syncHud(player, nil)
		self._deps.notify(player, "shop_ok", padId)
		if unlockedId then
			self._deps.onAchievement(player, unlockedId)
		end
	end

	task.delay(0.35, function()
		self._debounce[key] = false
	end)
end

function ShopManager:_wirePad(areaId: string, pad: BasePart)
	local padId = pad.Name
	if not ShopLogic.isValidPad(padId) then
		return
	end
	local price = ShopLogic.price(areaId, padId)
	if price == nil then
		return
	end

	ensureBillboard(pad, price)
	pad.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		if not character then
			return
		end
		local player = Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end
		self:_tryBuy(player, areaId, padId, pad)
	end)
end

function ShopManager:_setupArea(areaId: string)
	local shop = getShop(areaId)
	if not shop then
		Logger.warn("ShopManager", `Shop not found for {areaId}`)
		return
	end
	for _, padId in ShopDatabase.PAD_ORDER do
		local pad = shop:FindFirstChild(padId)
		if pad and pad:IsA("BasePart") then
			self:_wirePad(areaId, pad)
		end
	end
end

function ShopManager:restorePlayerVisuals(player: Player)
	local data = self._deps.profileManager:get(player)
	if not data then
		return
	end
	for _, areaId in { "Area1", "Area2" } do
		local shop = getShop(areaId)
		if shop then
			local pads = data.shop[areaId :: AreaId]
			for _, padId in ShopDatabase.PAD_ORDER do
				local pad = shop:FindFirstChild(padId)
				if pad and pad:IsA("BasePart") then
					local price = ShopLogic.price(areaId, padId) or 0
					if pads[padId] then
						self:_applyVisual(pad, true, price)
					end
				end
			end
		end
	end
end

function ShopManager:start()
	if self._started then
		return
	end
	self._started = true
	task.spawn(function()
		local deadline = os.clock() + 30
		while os.clock() < deadline do
			if getShop("Area1") and getShop("Area2") then
				break
			end
			task.wait(0.25)
		end
		self:_setupArea("Area1")
		self:_setupArea("Area2")
		Logger.info("ShopManager", "started")
	end)
end

return ShopManager
