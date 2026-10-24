--!strict
-- Предметы в мире: лежит в точке, несут, брошен, на пьедестале. Взять / нести / бросить / поимка.
-- GDD 2.1, 2.4, 2.6, 12.3. Владелец истины о состоянии каждого предмета.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CarryLogic = require(ReplicatedStorage.shared.util.CarryLogic)
local FormatNumber = require(ReplicatedStorage.shared.util.FormatNumber)
local GameplayConfig = require(ReplicatedStorage.shared.data.GameplayConfig)
local GiantConfig = require(ReplicatedStorage.shared.data.GiantConfig)
local HoardConfig = require(ReplicatedStorage.shared.data.HoardConfig)
local ItemsConfig = require(ReplicatedStorage.shared.data.ItemsConfig)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local Rarity = require(ReplicatedStorage.shared.data.Rarity)

local Ragdoll = require(script.Parent.Ragdoll)
local RateLimiter = require(script.Parent.Parent.util.RateLimiter)

export type Home =
    { kind: "spawn", marker: BasePart }
    | { kind: "pedestal", plotIndex: number, slot: number }

export type ItemState = "Spawn" | "Carried" | "Dropped" | "Pedestal"

export type Item = {
    uid: string,
    def: ItemsConfig.ItemDef,
    model: Model,
    root: BasePart,
    state: ItemState,
    home: Home,
    carrier: Player?,
    prompt: ProximityPrompt?,
    droppedToken: number,
    weld: Weld?,
}

export type Deps = {
    scene: any,
    movement: any,
    noise: any,
    notify: (player: Player, kind: string, text: string) -> (),
    feed: (text: string) -> (),
    fireRagdoll: (player: Player, velocity: Vector3, duration: number) -> (),
    -- Заполняются после создания PlotService / HoardService / GiantService (цикл зависимостей).
    plots: any?,
    hoard: any?,
    onTeddyGrabbed: ((player: Player) -> ())?,
    onTeddyStir: ((holding: boolean) -> ())?,
}

local CarryService = {}
CarryService.__index = CarryService

function CarryService.new(deps: Deps)
    return setmetatable({
        _deps = deps,
        _items = {} :: { [string]: Item },
        _carrying = {} :: { [Player]: Item },
        _grabLimiter = RateLimiter.new(GameplayConfig.GRAB_MAX_PER_SEC, 1),
        _insidePlot = {} :: { [Player]: number? },
        _groundParams = RaycastParams.new(),
    }, CarryService)
end

-- Сила игрока: атрибут Strength ставит сервер (этап 2 — из профиля и тренажёра).
function CarryService.strengthOf(player: Player): number
    local value = player:GetAttribute("Strength")
    return if typeof(value) == "number" then value else GameplayConfig.START_STRENGTH
end

-- Требуемая сила задаётся редкостью (GDD 5.3); множитель размера — этап 2.
function CarryService.needOf(item: Item): number
    return GameplayConfig.NEED_BY_RARITY[item.def.rarity] or 0
end

function CarryService:carried(player: Player): Item?
    return self._carrying[player]
end

function CarryService:all(): { [string]: Item }
    return self._items
end

local function setPhysics(model: Model, carried: boolean)
    for _, part in model:GetDescendants() do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.CanQuery = not carried
            part.CanTouch = false
            part.Massless = true
        end
    end
end

function CarryService:_setPrompt(item: Item, kind: "Grab" | "Steal" | nil, ownerUserId: number?)
    if item.prompt then
        item.prompt:Destroy()
        item.prompt = nil
    end
    local isTeddyAtHome = kind ~= nil and item.def.rarity == "Secret" and item.state == "Spawn"
    self:_setTeddySign(item, isTeddyAtHome)
    if not kind then
        return
    end
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = kind
    prompt.ActionText = kind
    prompt.ObjectText = item.def.name
    prompt.HoldDuration = if kind == "Steal"
        then GameplayConfig.STEAL_HOLD_SEC
        else GameplayConfig.GRAB_HOLD_SEC
    prompt.MaxActivationDistance = GameplayConfig.GRAB_MAX_DIST - 2
    prompt.RequiresLineOfSight = false
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
    if ownerUserId then
        -- Клиент владельца прячет «Steal» на своих пьедесталах (сервер всё равно проверяет).
        prompt:SetAttribute("HideForUserId", ownerUserId)
    end
    prompt.Triggered:Connect(function(player)
        self:tryGrab(player, item)
    end)
    if isTeddyAtHome then
        -- Кража мишки (GDD 5.10): долгое удержание, всё это время великан ворочается.
        prompt.HoldDuration = GiantConfig.TEDDY_HOLD_SEC
        prompt.ActionText = "Steal Teddy"
        prompt.PromptButtonHoldBegan:Connect(function(player)
            if self._deps.noise:get() >= HoardConfig.TEDDY_MAX_NOISE then
                self._deps.notify(player, "hint", "Too loud — wait!")
            else
                self._deps.notify(player, "hint", "...teddy?..")
                if self._deps.onTeddyStir then
                    self._deps.onTeddyStir(true)
                end
            end
        end)
        prompt.PromptButtonHoldEnded:Connect(function()
            if self._deps.onTeddyStir then
                self._deps.onTeddyStir(false)
            end
        end)
    elseif kind == "Steal" then
        prompt.PromptButtonHoldBegan:Connect(function(player)
            if self._deps.plots then
                self._deps.plots:onStealBegin(player, item)
            end
        end)
        prompt.PromptButtonHoldEnded:Connect(function(player)
            if self._deps.plots and item.carrier ~= player then
                self._deps.plots:onStealCancelled(player, item)
            end
        end)
    end
    prompt.Parent = item.root
    item.prompt = prompt
end

-- Табличка над мишкой в руке великана: игрок заранее знает, что будет (GDD 5.10, шаг 1).
function CarryService:_setTeddySign(item: Item, shown: boolean)
    local sign = item.root:FindFirstChild("TeddySign")
    if shown and not sign then
        local gui = Instance.new("BillboardGui")
        gui.Name = "TeddySign"
        gui.Size = UDim2.fromOffset(240, 50)
        gui.StudsOffset = Vector3.new(0, 10, 0)
        gui.MaxDistance = 120
        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.Text = "😠 He WILL wake up!"
        label.Font = Enum.Font.FredokaOne
        label.TextScaled = true
        label.TextColor3 = Color3.fromHex("#C4281C")
        label.TextStrokeTransparency = 0
        label.TextStrokeColor3 = Color3.new(1, 1, 1)
        label.Parent = gui
        gui.Parent = item.root
    elseif not shown and sign then
        sign:Destroy()
    end
end

local function addRarityLight(item: Item)
    local range = (Rarity.DEFS :: any)[item.def.rarity].lightRange
    if range > 0 and not item.root:FindFirstChild("RarityLight") then
        local light = Instance.new("PointLight")
        light.Name = "RarityLight"
        light.Range = range
        light.Color = (Rarity.DEFS :: any)[item.def.rarity].color
        light.Brightness = 2
        light.Parent = item.root
    end
end

local function spawnCFrame(marker: BasePart): CFrame
    return marker.CFrame * CFrame.new(0, marker.Size.Y / 2, 0)
end

function CarryService:_unweld(item: Item)
    if item.weld then
        item.weld:Destroy()
        item.weld = nil
    end
    item.root.Anchored = true
    item.model.Parent = self._deps.scene.itemsFolder
end

function CarryService:_clearCarrier(item: Item)
    local carrier = item.carrier
    if carrier then
        self._carrying[carrier] = nil
        self._deps.movement:setCarryWeight(carrier, 0)
        carrier:SetAttribute("CarryingItemId", nil)
        carrier:SetAttribute("CarryingUid", nil)
        if self._deps.plots then
            self._deps.plots:onCarryEnded(carrier, item)
        end
    end
    item.carrier = nil
end

-- Создать предмет в точке появления. Вызывает HoardService.
function CarryService:spawnAt(itemId: string, marker: BasePart): Item
    local def = ItemsConfig.BY_ID[itemId]
    local model = self._deps.scene.itemTemplate(itemId)
    local root = model.PrimaryPart :: BasePart
    local item: Item = {
        uid = HttpService:GenerateGUID(false),
        def = def,
        model = model,
        root = root,
        state = "Spawn",
        home = { kind = "spawn", marker = marker },
        carrier = nil,
        prompt = nil,
        droppedToken = 0,
        weld = nil,
    }
    model:SetAttribute("ItemId", itemId)
    model:SetAttribute("Rarity", def.rarity)
    model:SetAttribute("Need", GameplayConfig.NEED_BY_RARITY[def.rarity] or 0)
    model:SetAttribute("Uid", item.uid)
    setPhysics(model, false)
    root.Anchored = true
    model:PivotTo(spawnCFrame(marker))
    model.Parent = self._deps.scene.itemsFolder
    addRarityLight(item)
    self._items[item.uid] = item
    self:_setPrompt(item, "Grab")
    return item
end

-- Поставить предмет на пьедестал (PlotService выбрал слот).
function CarryService:placeOnPedestal(
    item: Item,
    plotIndex: number,
    slot: number,
    pedestal: BasePart,
    ownerUserId: number
)
    self:_clearCarrier(item)
    self:_unweld(item)
    item.state = "Pedestal"
    item.home = { kind = "pedestal", plotIndex = plotIndex, slot = slot }
    item.model:SetAttribute("OwnerUserId", ownerUserId)
    item.model:PivotTo(pedestal.CFrame * CFrame.new(0, pedestal.Size.Y / 2 + 1, 0))
    self:_setPrompt(item, "Steal", ownerUserId)
end

function CarryService:destroy(item: Item)
    self:_clearCarrier(item)
    self._items[item.uid] = nil
    item.model:Destroy()
end

function CarryService:_returnHome(item: Item)
    local home = item.home
    if home.kind == "spawn" then
        self:_clearCarrier(item)
        self:_unweld(item)
        item.state = "Spawn"
        item.model:SetAttribute("OwnerUserId", nil)
        item.model:PivotTo(spawnCFrame(home.marker))
        self:_setPrompt(item, "Grab")
    else
        local plots = self._deps.plots
        local ok = plots and plots:returnToSlot(item, home.plotIndex, home.slot)
        if not ok then
            -- Владелец ушёл: предмет пропадает, его пьедестала больше нет.
            self:destroy(item)
        end
    end
end

function CarryService:_groundAt(position: Vector3): Vector3
    self._groundParams.FilterType = Enum.RaycastFilterType.Exclude
    local exclude: { Instance } = { self._deps.scene.itemsFolder, self._deps.scene.fxFolder }
    for _, player in Players:GetPlayers() do
        if player.Character then
            table.insert(exclude, player.Character)
        end
    end
    self._groundParams.FilterDescendantsInstances = exclude
    local hit = workspace:Raycast(
        position + Vector3.new(0, 4, 0),
        Vector3.new(0, -60, 0),
        self._groundParams
    )
    return if hit then hit.Position else position
end

-- Бросить в точке: 20 с бесхозный, потом домой (GDD 2.4).
function CarryService:dropAt(item: Item, position: Vector3)
    self:_clearCarrier(item)
    self:_unweld(item)
    item.state = "Dropped"
    item.model:SetAttribute("OwnerUserId", nil)
    item.model:PivotTo(CFrame.new(self:_groundAt(position)))
    self:_setPrompt(item, "Grab")
    item.droppedToken += 1
    local token = item.droppedToken
    task.delay(HoardConfig.DROPPED_LIFETIME_SEC, function()
        if
            self._items[item.uid] == item
            and item.state == "Dropped"
            and item.droppedToken == token
        then
            self:_returnHome(item)
        end
    end)
end

function CarryService:_attach(player: Player, item: Item): boolean
    local character = player.Character
    local head = character and character:FindFirstChild("Head") :: BasePart?
    if not head then
        return false
    end
    self:_setPrompt(item, nil)
    item.state = "Carried"
    item.carrier = player
    item.model.Parent = character
    item.root.Anchored = false
    item.model:PivotTo(
        head.CFrame * CFrame.new(0, head.Size.Y / 2 + GameplayConfig.CARRY_OFFSET_Y - 2, 0)
    )
    local weld = Instance.new("Weld")
    weld.Name = "CarryWeld"
    weld.Part0 = head
    weld.Part1 = item.root
    weld.C0 = CFrame.new(0, head.Size.Y / 2 + GameplayConfig.CARRY_OFFSET_Y - 2, 0)
    weld.Parent = item.root
    item.weld = weld
    self._carrying[player] = item
    local need = CarryService.needOf(item)
    self._deps.movement:setCarryWeight(
        player,
        item.def.weight,
        CarryLogic.speedMult(
            CarryService.strengthOf(player),
            need,
            GameplayConfig.CARRY_SPEED_BY_RATIO
        )
    )
    player:SetAttribute("CarryingItemId", item.def.id)
    player:SetAttribute("CarryingUid", item.uid)
    -- Нести можно из своего участка: доставка срабатывает только при входе снаружи.
    self._insidePlot[player] = self._deps.plots and self._deps.plots:plotIndexAt(head.Position)
        or nil
    return true
end

function CarryService:tryGrab(player: Player, item: Item): boolean
    if self._items[item.uid] ~= item or self._carrying[player] or item.carrier then
        return false
    end
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not (humanoid and root) or humanoid.Health <= 0 or Ragdoll.isActive(character :: Model) then
        return false
    end
    if (root.Position - item.root.Position).Magnitude > GameplayConfig.GRAB_MAX_DIST then
        return false
    end
    if not CarryLogic.canLift(CarryService.strengthOf(player), CarryService.needOf(item)) then
        self._deps.notify(
            player,
            "hint",
            `Need {FormatNumber.short(CarryService.needOf(item))} Strength`
        )
        return false
    end
    if not self._grabLimiter:allow(player) then
        return false
    end

    local fromState = item.state
    if fromState == "Pedestal" then
        local plots = self._deps.plots
        if not (plots and plots:canSteal(player, item)) then
            return false
        end
    elseif
        item.def.rarity == "Secret"
        and fromState == "Spawn"
        and self._deps.noise:get() >= HoardConfig.TEDDY_MAX_NOISE
    then
        self._deps.notify(player, "hint", "Too loud — wait!")
        return false
    end

    if not self:_attach(player, item) then
        return false
    end

    if fromState == "Pedestal" then
        self._deps.plots:onStolen(player, item)
    elseif item.def.rarity == "Secret" then
        if self._deps.onTeddyGrabbed then
            self._deps.onTeddyGrabbed(player)
        end
    else
        self._deps.noise:add((Rarity.DEFS :: any)[item.def.rarity].grabNoise, item.root.Position)
    end
    Logger.debug("Carry", `{player.Name} grabbed {item.def.id} from {fromState}`)
    return true
end

function CarryService:drop(player: Player)
    local item = self._carrying[player]
    local root = player.Character
        and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if item and root then
        self:dropAt(item, root.Position + root.CFrame.LookVector * 3)
    end
end

-- Выбили подушкой: краденое летит к владельцу, остальное падает на землю.
function CarryService:knockOut(player: Player)
    local item = self._carrying[player]
    if not item then
        return
    end
    if item.home.kind == "pedestal" then
        self:_returnHome(item)
    else
        local root = player.Character
            and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
        self:dropAt(item, if root then root.Position else item.root.Position)
    end
end

-- Рэгдолл с полётом. velocity задаёт клиент-владелец.
function CarryService:ragdoll(player: Player, duration: number, velocity: Vector3)
    local character = player.Character
    if not character then
        return
    end
    self._deps.movement:setRagdolled(player, true)
    player:SetAttribute("Ragdolled", true)
    Ragdoll.start(character, duration, function()
        self._deps.movement:setRagdolled(player, false)
        player:SetAttribute("Ragdolled", false)
    end)
    self._deps.fireRagdoll(player, velocity, duration)
end

-- Поимка великаном (GDD 2.4): предмет падает в точке поимки, игрок улетает к своему участку.
function CarryService:catch(player: Player, cause: string)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not root or Ragdoll.isActive(character :: Model) then
        return
    end
    local item = self._carrying[player]
    if item then
        self:dropAt(item, root.Position)
    end

    local target = self._deps.plots and self._deps.plots:plotCenterOf(player)
    local from = root.Position
    local dir = if target then (target - from) else Vector3.new(from.X, 0, from.Z)
    dir = Vector3.new(dir.X, 0, dir.Z)
    if dir.Magnitude < 1 then
        dir = Vector3.new(1, 0, 0)
    end
    local dist = GiantConfig.LAUNCH_DIST_MIN
        + math.random() * (GiantConfig.LAUNCH_DIST_MAX - GiantConfig.LAUNCH_DIST_MIN)
    if target then
        dist = math.min(dist, math.max(dir.Magnitude, 30))
    end
    local vx, vy, vz =
        CarryLogic.launchVelocity(dir.X, dir.Z, dist, GiantConfig.LAUNCH_HEIGHT, workspace.Gravity)
    self:ragdoll(player, GiantConfig.RAGDOLL_SEC, Vector3.new(vx, vy, vz))
    self._deps.notify(player, "caught", cause)
    Logger.info("Carry", `{player.Name} caught ({cause})`)
end

function CarryService:_checkDeliveries()
    local plots = self._deps.plots
    if not plots then
        return
    end
    for player, item in self._carrying do
        local root = player.Character
            and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
        if not root then
            continue
        end
        local index = plots:plotIndexAt(root.Position)
        local was = self._insidePlot[player]
        self._insidePlot[player] = index
        if index and index ~= was and plots:ownerIndex(player) == index then
            plots:deliver(player, item)
        end
    end
end

-- Предметы в точках на теле великана двигаются вместе с ним.
function CarryService:_followMarkers()
    local giant = self._deps.scene.giant
    for _, item in self._items do
        if
            item.state == "Spawn"
            and item.home.kind == "spawn"
            and item.home.marker:IsDescendantOf(giant)
        then
            item.model:PivotTo(spawnCFrame(item.home.marker))
        end
    end
end

function CarryService:start()
    Players.PlayerRemoving:Connect(function(player)
        local item = self._carrying[player]
        if item then
            local root = player.Character
                and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
            self:dropAt(item, if root then root.Position else item.root.Position)
        end
        self._insidePlot[player] = nil
        self._grabLimiter:clear(player)
    end)
    local function onCharacter(player: Player, character: Model)
        local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
        if humanoid then
            humanoid.Died:Connect(function()
                local item = self._carrying[player]
                if item then
                    self:dropAt(item, item.root.Position)
                end
            end)
        end
    end
    local function onPlayer(player: Player)
        player.CharacterAdded:Connect(function(character)
            onCharacter(player, character)
        end)
    end
    Players.PlayerAdded:Connect(onPlayer)
    for _, player in Players:GetPlayers() do
        onPlayer(player)
    end
    RunService.Heartbeat:Connect(function()
        self:_followMarkers()
    end)
    task.spawn(function()
        while true do
            task.wait(GiantConfig.TICK_SEC)
            self:_checkDeliveries()
        end
    end)
end

return CarryService
