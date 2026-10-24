--!strict
-- Участки (GDD 2.6, 6.1): выдача, пьедесталы, доставка, кража, замок, доход.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyConfig = require(ReplicatedStorage.shared.data.EconomyConfig)
local GameplayConfig = require(ReplicatedStorage.shared.data.GameplayConfig)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local PlotOwnership = require(ReplicatedStorage.shared.util.PlotOwnership)
local Rarity = require(ReplicatedStorage.shared.data.Rarity)

type Plot = {
    index: number,
    model: Model,
    cframe: CFrame,
    owner: Player?,
    slots: { [number]: any },
    pedestals: { BasePart },
    lockedUntil: number,
    cooldownUntil: number,
    signLabel: TextLabel?,
    lockLabel: TextLabel?,
}

export type Deps = {
    plots: { Model },
    carry: any,
    hoard: any,
    movement: any,
    profiles: any,
    notify: (player: Player, kind: string, text: string) -> (),
    feed: (text: string) -> (),
    syncCoins: (player: Player, coins: number, incomePerSec: number) -> (),
}

local PlotService = {}
PlotService.__index = PlotService

local function billboard(adornee: BasePart, offsetY: number, textSize: number): TextLabel
    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.fromOffset(260, 70)
    gui.StudsOffset = Vector3.new(0, offsetY, 0)
    gui.AlwaysOnTop = false
    gui.MaxDistance = 400
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0.2
    label.Font = Enum.Font.FredokaOne
    label.TextSize = textSize
    label.Text = ""
    label.Parent = gui
    gui.Parent = adornee
    return label
end

function PlotService.new(deps: Deps)
    local plots: { Plot } = {}
    for index, model in deps.plots do
        local pedestals: { BasePart } = {}
        local folder = model:FindFirstChild("Pedestals")
        for slot = 1, GameplayConfig.PEDESTALS_OPEN do
            local p = folder and folder:FindFirstChild(`P{slot}`)
            if p and p:IsA("BasePart") then
                pedestals[slot] = p
            else
                Logger.warn("Plots", `{model.Name}: нет пьедестала P{slot}`)
            end
        end
        plots[index] = {
            index = index,
            model = model,
            cframe = model:GetPivot(),
            owner = nil,
            slots = {},
            pedestals = pedestals,
            lockedUntil = 0,
            cooldownUntil = 0,
            signLabel = nil,
            lockLabel = nil,
        }
    end
    return setmetatable({
        _deps = deps,
        _plots = plots,
        _byPlayer = {} :: { [Player]: Plot },
        _income = {} :: { [Player]: number },
    }, PlotService)
end

-- Запросы ---------------------------------------------------------------

function PlotService:ownerIndex(player: Player): number?
    local plot = self._byPlayer[player]
    return plot and plot.index
end

function PlotService:plotCenterOf(player: Player): Vector3?
    local plot = self._byPlayer[player]
    return plot and plot.cframe.Position
end

function PlotService:plotIndexAt(position: Vector3): number?
    local half = GameplayConfig.PLOT_SIZE / 2
    for _, plot in self._plots do
        local localPos = plot.cframe:PointToObjectSpace(position)
        if
            math.abs(localPos.X) <= half
            and math.abs(localPos.Z) <= half
            and localPos.Y > -2
            and localPos.Y < 30
        then
            return plot.index
        end
    end
    return nil
end

function PlotService:isLocked(index: number): boolean
    local plot = self._plots[index]
    return plot ~= nil and workspace:GetServerTimeNow() < plot.lockedUntil
end

function PlotService:canSteal(thief: Player, item: any): boolean
    local home = item.home
    if home.kind ~= "pedestal" then
        return false
    end
    local plot = self._plots[home.plotIndex]
    if not plot or not plot.owner or plot.owner == thief then
        return false
    end
    return not self:isLocked(plot.index)
end

-- Пьедесталы --------------------------------------------------------------

function PlotService:_freeSlot(plot: Plot): number?
    for slot = 1, GameplayConfig.PEDESTALS_OPEN do
        if plot.pedestals[slot] and plot.slots[slot] == nil then
            return slot
        end
    end
    return nil
end

function PlotService:_recalcIncome(plot: Plot)
    local owner = plot.owner
    if not owner then
        return
    end
    local total = 0
    for _, item in plot.slots do
        -- Краденый и ещё не доставленный предмет держит слот, но дохода не даёт.
        if item.state == "Pedestal" then
            total += item.def.income
        end
    end
    self._income[owner] = total
    self:_setSign(plot, owner.DisplayName, `{total}/s`)
end

-- Вывеска: SignGui.OwnerName / SignGui.Income у моделлера, иначе свой BillboardGui.
function PlotService:_setSign(plot: Plot, ownerName: string, income: string)
    local sign = plot.model:FindFirstChild("Sign")
    local gui = sign and sign:FindFirstChild("SignGui", true)
    local nameLabel = gui and gui:FindFirstChild("OwnerName", true)
    local incomeLabel = gui and gui:FindFirstChild("Income", true)
    if
        nameLabel
        and nameLabel:IsA("TextLabel")
        and incomeLabel
        and incomeLabel:IsA("TextLabel")
    then
        nameLabel.Text = ownerName
        incomeLabel.Text = income
    elseif plot.signLabel then
        plot.signLabel.Text = if income ~= "" then `{ownerName}\n{income}` else ownerName
    end
end

-- Neon-ободок пьедестала цвета редкости, когда занят.
function PlotService:_setRim(plot: Plot, slot: number, item: any?)
    local pedestal = plot.pedestals[slot]
    local rim = pedestal and pedestal:FindFirstChild("Rim", true)
    if rim and rim:IsA("BasePart") then
        rim.Transparency = if item then 0 else 1
        if item then
            rim.Color = (Rarity.DEFS :: any)[item.def.rarity].color
        end
    end
end

-- Игрок вошёл на свой участок с предметом: встаёт на первый свободный пьедестал (GDD 7.1).
function PlotService:deliver(player: Player, item: any)
    local plot = self._byPlayer[player]
    if not plot then
        return
    end
    local slot = self:_freeSlot(plot)
    if not slot then
        self._deps.notify(player, "hint", "All pedestals are full!")
        return
    end
    local oldHome = item.home
    if oldHome.kind == "pedestal" then
        local victimPlot = self._plots[oldHome.plotIndex]
        if victimPlot then
            victimPlot.slots[oldHome.slot] = nil
            self:_setRim(victimPlot, oldHome.slot, nil)
            self:_recalcIncome(victimPlot)
            if victimPlot.owner then
                self._deps.notify(
                    victimPlot.owner,
                    "stolen",
                    `{player.DisplayName} stole your {item.def.name}!`
                )
            end
        end
        self._deps.feed(`{player.DisplayName} stole {item.def.name}!`)
    elseif oldHome.kind == "spawn" then
        self._deps.hoard:onSpawnFreed(oldHome.marker)
        if
            item.def.rarity == "Legendary"
            or item.def.rarity == "Mythic"
            or item.def.rarity == "Secret"
        then
            self._deps.feed(`{player.DisplayName} stole the {item.def.name}!`)
        end
    end
    plot.slots[slot] = item
    self:_setRim(plot, slot, item)
    self._deps.carry:placeOnPedestal(item, plot.index, slot, plot.pedestals[slot], player.UserId)
    self:_recalcIncome(plot)
    self._deps.notify(player, "delivered", item.def.name)
end

-- Вернуть краденое на пьедестал владельца. false — владельца больше нет.
function PlotService:returnToSlot(item: any, plotIndex: number, slot: number): boolean
    local plot = self._plots[plotIndex]
    if not plot or not plot.owner or plot.slots[slot] ~= item then
        return false
    end
    self._deps.carry:placeOnPedestal(item, plotIndex, slot, plot.pedestals[slot], plot.owner.UserId)
    self:_recalcIncome(plot)
    return true
end

-- Кража ---------------------------------------------------------------------

function PlotService:onStealBegin(thief: Player, item: any)
    if not self:canSteal(thief, item) then
        return
    end
    local owner = self._plots[item.home.plotIndex].owner :: Player
    thief:SetAttribute("StealingFrom", owner.UserId)
    self._deps.notify(owner, "steal_warn", `{thief.DisplayName} is stealing your {item.def.name}!`)
end

function PlotService:onStealCancelled(thief: Player, _item: any)
    if not self._deps.carry:carried(thief) then
        thief:SetAttribute("StealingFrom", nil)
    end
end

function PlotService:onStolen(thief: Player, item: any)
    local plot = self._plots[item.home.plotIndex]
    thief:SetAttribute("StealingFrom", plot and plot.owner and plot.owner.UserId or nil)
    if plot then
        self:_recalcIncome(plot)
    end
end

function PlotService:onCarryEnded(player: Player, _item: any)
    player:SetAttribute("StealingFrom", nil)
end

-- Замок ---------------------------------------------------------------------

function PlotService:_setBarrier(plot: Plot, locked: boolean)
    plot.model:SetAttribute("Locked", locked)
    local barrier = plot.model:FindFirstChild("Barrier")
    if barrier then
        for _, part in barrier:GetDescendants() do
            if part:IsA("BasePart") then
                part.Transparency = if locked then 0.3 else 1
            end
        end
    end
end

function PlotService:_ejectIntruders(plot: Plot)
    local exit = plot.cframe * CFrame.new(0, 4, -GameplayConfig.PLOT_SIZE / 2 - 6)
    for _, player in Players:GetPlayers() do
        local root = player.Character
            and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
        if player ~= plot.owner and root and self:plotIndexAt(root.Position) == plot.index then
            self._deps.movement:exempt(player, 2)
            player.Character:PivotTo(CFrame.lookAt(exit.Position, exit.Position + exit.LookVector))
        end
    end
end

function PlotService:tryLock(player: Player)
    local plot = self._byPlayer[player]
    if not plot then
        return
    end
    local now = workspace:GetServerTimeNow()
    if now < plot.lockedUntil then
        return
    end
    if now < plot.cooldownUntil then
        self._deps.notify(player, "hint", `Lock ready in {math.ceil(plot.cooldownUntil - now)}s`)
        return
    end
    plot.lockedUntil = now + GameplayConfig.LOCK_DURATION_SEC
    plot.cooldownUntil = plot.lockedUntil + GameplayConfig.LOCK_COOLDOWN_SEC
    plot.model:SetAttribute("LockedUntil", plot.lockedUntil)
    self:_setBarrier(plot, true)
    self:_ejectIntruders(plot)
end

-- Выдача участков ----------------------------------------------------------

function PlotService:_spawnCFrame(plot: Plot): CFrame
    local spawnPart = plot.model:FindFirstChild("Spawn")
    local base = if spawnPart and spawnPart:IsA("BasePart") then spawnPart.CFrame else plot.cframe
    local pos = base.Position + Vector3.new(0, 4, 0)
    return CFrame.lookAt(pos, Vector3.new(0, pos.Y, 0))
end

function PlotService:_assign(player: Player)
    for _, plot in self._plots do
        if not plot.owner then
            plot.owner = player
            plot.slots = {}
            self._byPlayer[player] = plot
            self._income[player] = 0
            plot.model:SetAttribute(PlotOwnership.OWNER_ATTRIBUTE, player.UserId)
            plot.model:SetAttribute("OwnerName", player.DisplayName)
            player:SetAttribute("PlotIndex", plot.index)
            self:_recalcIncome(plot)
            return
        end
    end
    Logger.warn("Plots", `нет свободного участка для {player.Name}`)
end

function PlotService:_release(player: Player)
    local plot = self._byPlayer[player]
    if not plot then
        return
    end
    self._byPlayer[player] = nil
    self._income[player] = nil
    for _, item in plot.slots do
        if item.state == "Pedestal" then
            self._deps.carry:destroy(item)
        end
        -- Несомые чужие предметы этого участка исчезнут, когда попытаются вернуться домой.
    end
    plot.slots = {}
    plot.owner = nil
    plot.lockedUntil = 0
    plot.cooldownUntil = 0
    self:_setBarrier(plot, false)
    plot.model:SetAttribute(PlotOwnership.OWNER_ATTRIBUTE, nil)
    plot.model:SetAttribute("OwnerName", nil)
    for slot in plot.pedestals do
        self:_setRim(plot, slot, nil)
    end
    self:_setSign(plot, "Free camp", "")
end

function PlotService:_setupPlot(plot: Plot)
    local sign = plot.model:FindFirstChild("Sign")
    if sign and sign:IsA("BasePart") and not sign:FindFirstChild("SignGui", true) then
        plot.signLabel = billboard(sign, 3, 28)
    end
    self:_setSign(plot, "Free camp", "")
    local floor = plot.model.PrimaryPart or plot.model:FindFirstChild("Floor")
    if floor and floor:IsA("BasePart") then
        plot.lockLabel = billboard(floor, 18, 32)
    end
    local button = plot.model:FindFirstChild("LockButton")
    if button and button:IsA("BasePart") then
        local prompt = Instance.new("ProximityPrompt")
        prompt.Name = "Lock"
        prompt.ActionText = "Lock camp"
        prompt.ObjectText = "Lock"
        prompt.HoldDuration = 0
        prompt.MaxActivationDistance = 8
        prompt.RequiresLineOfSight = false
        prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
        prompt:SetAttribute("OwnerOnly", true)
        prompt.Triggered:Connect(function(player)
            if plot.owner == player then
                self:tryLock(player)
            end
        end)
        prompt.Parent = button
    end
end

function PlotService:_incomeTick()
    local now = workspace:GetServerTimeNow()
    for _, plot in self._plots do
        local owner = plot.owner
        if owner then
            local income = self._income[owner] or 0
            local coins = 0
            self._deps.profiles:mutate(owner, function(data)
                data.Coins += income
                data.TotalEarned += income
                coins = data.Coins
            end)
            self._deps.syncCoins(owner, coins, income)
        end
        if
            plot.lockedUntil > 0
            and now >= plot.lockedUntil
            and plot.model:GetAttribute("Locked")
        then
            self:_setBarrier(plot, false)
        end
        if plot.lockLabel then
            local left = math.ceil(plot.lockedUntil - now)
            plot.lockLabel.Text = if left > 0
                then string.format("🔒 %d:%02d", left // 60, left % 60)
                else ""
        end
    end
end

function PlotService:start()
    for _, plot in self._plots do
        self:_setupPlot(plot)
    end
    local function onPlayer(player: Player)
        self:_assign(player)
        player.CharacterAdded:Connect(function(character)
            local plot = self._byPlayer[player]
            if plot then
                self._deps.movement:exempt(player, 2)
                task.defer(function()
                    character:PivotTo(self:_spawnCFrame(plot))
                end)
            end
        end)
    end
    Players.PlayerAdded:Connect(onPlayer)
    for _, player in Players:GetPlayers() do
        onPlayer(player)
    end
    Players.PlayerRemoving:Connect(function(player)
        self:_release(player)
    end)
    task.spawn(function()
        while true do
            task.wait(EconomyConfig.INCOME_TICK_SEC)
            self:_incomeTick()
        end
    end)
end

return PlotService
