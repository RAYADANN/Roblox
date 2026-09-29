--!strict
-- Bind Workspace markers: Place*/BuyPlace/FavoritePlace. No cloned plots.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Constants = require(game:GetService("ReplicatedStorage").shared.data.Constants)
local Logger = require(game:GetService("ReplicatedStorage").shared.util.Logger)
local PadButtonVisual = require(script.Parent.PadButtonVisual)

export type PlotStands = { BasePart }
export type OfferPads = { BasePart }
export type PlaceButtons = { Model }
export type FavoriteStands = { BasePart }

export type Plot = {
    id: number,
    stands: PlotStands,
    offerPads: OfferPads,
    buttons: PlaceButtons,
    buyPlace: BasePart?,
    favoriteStands: FavoriteStands,
    favoriteCollectButton: Model?,
    owner: Player?,
}

local PlotManager = {}
PlotManager.__index = PlotManager

export type PlotManager = {
    get: (self: PlotManager, plotId: number) -> Plot?,
    getByPlayer: (self: PlotManager, player: Player) -> Plot?,
    claim: (self: PlotManager, player: Player) -> Plot?,
    release: (self: PlotManager, player: Player) -> (),
    getStand: (self: PlotManager, plotId: number, slotIndex: number) -> BasePart?,
    getFavoriteStand: (self: PlotManager, slotIndex: number) -> BasePart?,
    getOfferPad: (self: PlotManager, plotId: number, offerIndex: number) -> BasePart?,
    teleportToPlot: (self: PlotManager, player: Player) -> (),
    bindPlaceButtons: (self: PlotManager, onStand: (player: Player, slotIndex: number) -> ()) -> (),
    bindFavoriteCollect: (self: PlotManager, onCollect: (player: Player) -> ()) -> (),
    -- Server-owned Teleport particles (client cannot stick Enabled=false — replication).
    setStandFx: (self: PlotManager, slotIndex: number, occupied: boolean) -> (),
    syncStandFx: (self: PlotManager, occupiedBySlot: { [number]: boolean }) -> (),
}

local PLACE_NAMES = { "Place", "Place2", "Place3", "Place4", "Place5", "Place6" }
-- BuyPlace egg pads (legacy first pad name without digit).
local ITEM_PLACE_NAMES = { "ItemPlace", "ItemPlace2", "ItemPlace3" }

local function favoritePadName(slotIndex: number): string
    return `ItemPlace{slotIndex}`
end

local function findFavoritePad(favModel: Model, slotIndex: number): BasePart?
    local named = favModel:FindFirstChild(favoritePadName(slotIndex))
    if named and named:IsA("BasePart") then
        return named
    end
    -- Legacy: first pad was "ItemPlace" (no digit).
    if slotIndex == 1 then
        local legacy = favModel:FindFirstChild("ItemPlace")
        if legacy and legacy:IsA("BasePart") then
            return legacy
        end
    end
    return nil
end

local function destroyRuntimeJunk()
    local junk = Workspace:FindFirstChild("ShowroomPlots")
    if junk then
        junk:Destroy()
    end
end

local function collectPlaceModels(): { Model }
    local places: { Model } = {}
    local seen: { [string]: boolean } = {}
    for _, name in PLACE_NAMES do
        for _, child in Workspace:GetChildren() do
            if child.Name == name and child:IsA("Model") and not seen[child:GetFullName()] then
                seen[child:GetFullName()] = true
                table.insert(places, child)
            end
        end
    end
    return places
end

-- Placement marker under Place/Teleport. Must stay Anchored or physics yeets it
-- (FallenPartsDestroyHeight) and place/render silently break for the session.
local function prepareEggPlace(part: BasePart)
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
end

local function findEggPlacePart(tele: Instance): BasePart?
    local exact = tele:FindFirstChild("EggPlace")
    if exact and exact:IsA("BasePart") then
        return exact
    end
    local spaced = tele:FindFirstChild("Egg Place")
    if spaced and spaced:IsA("BasePart") then
        return spaced
    end
    for _, d in tele:GetDescendants() do
        if d:IsA("BasePart") and string.lower(d.Name) == "eggplace" then
            return d
        end
    end
    return nil
end

local function forEachTeleportEmitter(tele: Instance, fn: (ParticleEmitter) -> ())
    for _, d in tele:GetDescendants() do
        if d:IsA("ParticleEmitter") then
            fn(d)
        end
    end
end

local function setTeleportEmitters(tele: Instance, occupied: boolean)
    forEachTeleportEmitter(tele, function(emitter)
        emitter.Enabled = occupied
    end)
end

local function disableAllTeleportFx(places: { Model })
    for _, place in places do
        local tele = place:FindFirstChild("Teleport")
        if tele then
            setTeleportEmitters(tele, false)
        end
    end
    local orphan = Workspace:FindFirstChild("Teleport")
    if orphan and orphan:IsA("Model") then
        setTeleportEmitters(orphan, false)
    end
end

local function collectStands(places: { Model }): PlotStands
    local stands: PlotStands = {}
    for i, place in places do
        local tele = place:FindFirstChild("Teleport")
        local eggPlace = if tele then findEggPlacePart(tele) else nil
        if eggPlace then
            prepareEggPlace(eggPlace)
            stands[i] = eggPlace
        else
            -- Legacy pedestal.
            local stand = place:FindFirstChild("Stand")
            if stand and stand:IsA("BasePart") then
                stands[i] = stand
            end
        end
    end
    return stands
end

local function collectButtons(places: { Model }): PlaceButtons
    local buttons: PlaceButtons = {}
    for i, place in places do
        local button = place:FindFirstChild("Button")
        if button and button:IsA("Model") then
            buttons[i] = button
        end
    end
    return buttons
end

local function findBuyPlaceModel(): Model?
    local m = Workspace:FindFirstChild("BuyPlace")
    if m and m:IsA("Model") then
        return m
    end
    return nil
end

local function findFavoriteModel(): Model?
    local m = Workspace:FindFirstChild("FavoritePlace")
    if m and m:IsA("Model") then
        return m
    end
    return nil
end

local function collectOfferPads(buyModel: Model?): OfferPads
    local pads: OfferPads = {}
    local parent: Instance = if buyModel then buyModel else Workspace
    for i, name in ITEM_PLACE_NAMES do
        local p = parent:FindFirstChild(name)
        if p and p:IsA("BasePart") then
            pads[i] = p
        end
    end
    -- Fallback: legacy Workspace root pads.
    if #pads == 0 then
        for i, name in ITEM_PLACE_NAMES do
            local p = Workspace:FindFirstChild(name)
            if p and p:IsA("BasePart") then
                pads[i] = p
            end
        end
    end
    return pads
end

local function collectSpinButton(buyModel: Model?): BasePart?
    if buyModel then
        local buttonStand = buyModel:FindFirstChild("ButtonStand")
        if buttonStand and buttonStand:IsA("Model") then
            local btn = buttonStand:FindFirstChild("Button")
            if btn and btn:IsA("BasePart") then
                return btn
            end
            for _, d in buttonStand:GetDescendants() do
                if d:IsA("BasePart") and string.lower(d.Name) == "button" then
                    return d
                end
            end
        end
        local legacy = buyModel:FindFirstChild("BuyPlace")
        if legacy and legacy:IsA("BasePart") then
            return legacy
        end
    end
    local root = Workspace:FindFirstChild("BuyPlace")
    if root and root:IsA("BasePart") then
        return root
    end
    return nil
end

local function collectFavoriteStands(favModel: Model?): FavoriteStands
    local stands: FavoriteStands = {}
    if not favModel then
        return stands
    end
    for i = 1, Constants.FAVORITE_SLOT_COUNT do
        local p = findFavoritePad(favModel, i)
        if p then
            stands[i] = p
        end
    end
    return stands
end

local function ensureAttachment(part: BasePart): Attachment
    local existing = part:FindFirstChild("PromptAttachment")
    if existing and existing:IsA("Attachment") then
        -- Top of part, no extra lift — ProximityUi sits at button/pad level.
        existing.Position = Vector3.new(0, part.Size.Y * 0.5 + 0.15, 0)
        return existing
    end
    local att = Instance.new("Attachment")
    att.Name = "PromptAttachment"
    att.Position = Vector3.new(0, part.Size.Y * 0.5 + 0.15, 0)
    att.Parent = part
    return att
end

local function ensurePrompt(
    parent: Instance,
    name: string,
    actionText: string,
    objectText: string,
    kind: string,
    stackIndex: number?
): ProximityPrompt
    local existing = parent:FindFirstChild(name)
    local prompt: ProximityPrompt
    if existing and existing:IsA("ProximityPrompt") then
        prompt = existing
    else
        prompt = Instance.new("ProximityPrompt")
        prompt.Name = name
        prompt.Parent = parent
    end
    prompt.ActionText = actionText
    prompt.ObjectText = objectText
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = 16
    prompt.RequiresLineOfSight = false
    prompt.Enabled = true
    prompt.Style = Enum.ProximityPromptStyle.Custom
    prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
    prompt.ClickablePrompt = true
    local stack = stackIndex or 0
    prompt.UIOffset = Vector2.new(0, -stack * 92)
    prompt:SetAttribute("UiKind", kind)
    prompt:SetAttribute("PromptStack", stack)
    prompt:SetAttribute("PromptKind", kind)
    return prompt
end

local function destroyNamed(parent: Instance, name: string)
    local existing = parent:FindFirstChild(name)
    if existing then
        existing:Destroy()
    end
end

local function installScenePrompts(
    stands: PlotStands,
    offerPads: OfferPads,
    spinButton: BasePart?,
    favoriteStands: FavoriteStands
)
    if spinButton then
        spinButton.CanQuery = true
        local att = ensureAttachment(spinButton)
        local prompt = ensurePrompt(att, "BuyPlacePrompt", "Spin", "", "restock", 0)
        prompt:SetAttribute("PromptKind", "restock")
    end

    for i, pad in offerPads do
        pad.CanQuery = true
        local att = ensureAttachment(pad)
        local prompt = ensurePrompt(att, "BuyOfferPrompt", "Buy", "", "buy", 0)
        prompt:SetAttribute("PromptKind", "buy")
        prompt:SetAttribute("OfferIndex", i)
    end

    for i, stand in stands do
        stand.CanQuery = true
        if stand.Transparency >= 1 then
            stand.CanCollide = false
        end
        local att = ensureAttachment(stand)
        destroyNamed(att, "PlacePrompt")
        destroyNamed(att, "SellPrompt")
        stand:SetAttribute("SlotIndex", i)
    end

    for i, stand in favoriteStands do
        stand.CanQuery = true
        if stand.Transparency >= 1 then
            stand.CanCollide = false
        end
        local att = ensureAttachment(stand)
        destroyNamed(att, "PlacePrompt")
        destroyNamed(att, "SellPrompt")
        stand:SetAttribute("FavoriteSlotIndex", i)
        stand:SetAttribute("IsFavorite", true)
    end
end

local function horizontalDistance(a: Vector3, b: Vector3): number
    local dx = a.X - b.X
    local dz = a.Z - b.Z
    return math.sqrt(dx * dx + dz * dz)
end

local function pickButtonPart(button: Model): BasePart?
    -- New art: Cube.001 is the pressable face (not the largest mesh).
    local face = button:FindFirstChild("Cube.001")
    if face and face:IsA("BasePart") then
        return face
    end
    if button.PrimaryPart and button.PrimaryPart:IsA("BasePart") then
        return button.PrimaryPart
    end
    local named = button:FindFirstChild("Button")
    if named and named:IsA("BasePart") then
        return named
    end
    local best: BasePart? = nil
    local bestVol = -1
    for _, d in button:GetDescendants() do
        if d:IsA("BasePart") then
            local vol = d.Size.X * d.Size.Y * d.Size.Z
            if vol > bestVol then
                bestVol = vol
                best = d
            end
        end
    end
    return best
end

function PlotManager.new(): PlotManager
    destroyRuntimeJunk()

    local places = collectPlaceModels()
    local standsRaw = collectStands(places)
    local buttons = collectButtons(places)
    local buyModel = findBuyPlaceModel()
    local favModel = findFavoriteModel()
    local offerPads = collectOfferPads(buyModel)
    local spinButton = collectSpinButton(buyModel)
    local favoriteStands = collectFavoriteStands(favModel)
    local favoriteButton = if favModel then favModel:FindFirstChild("Button") else nil
    local favoriteCollectButton = if favoriteButton and favoriteButton:IsA("Model")
        then favoriteButton
        else nil

    local plotStands: PlotStands = {}
    for i = 1, math.min(6, #places) do
        local stand = standsRaw[i]
        if stand then
            stand:SetAttribute("SlotIndex", i)
            stand:SetAttribute("PlotId", 1)
            plotStands[i] = stand
        end
    end
    for i, pad in offerPads do
        pad:SetAttribute("OfferIndex", i)
        pad:SetAttribute("PlotId", 1)
    end
    if spinButton then
        spinButton:SetAttribute("PlotId", 1)
    end
    for i, stand in favoriteStands do
        stand:SetAttribute("FavoriteSlotIndex", i)
        stand:SetAttribute("PlotId", 1)
    end

    installScenePrompts(plotStands, offerPads, spinButton, favoriteStands)
    disableAllTeleportFx(places)

    local plot: Plot = {
        id = 1,
        stands = plotStands,
        offerPads = offerPads,
        buttons = buttons,
        buyPlace = spinButton,
        favoriteStands = favoriteStands,
        favoriteCollectButton = favoriteCollectButton,
        owner = nil,
    }

    Logger.info(
        "PlotManager",
        `scene: stands={#plotStands} buttons={#buttons} offers={#offerPads} spin={spinButton ~= nil} fav={#favoriteStands} collect={favoriteCollectButton ~= nil}`
    )

    return setmetatable({
        _plot = plot,
        _byPlayer = {} :: { [Player]: boolean },
        _buttonLoop = nil :: thread?,
        _collectLoop = nil :: thread?,
        _buttonParts = {} :: { [number]: BasePart },
    }, PlotManager) :: any
end

function PlotManager:bindPlaceButtons(onStand: (player: Player, slotIndex: number) -> ())
    local selfAny = self :: any
    local plot = selfAny._plot :: Plot

    local buttonParts: { [number]: BasePart } = {}
    local buttonModels: { [number]: Model } = {}
    for slotIndex, button in plot.buttons do
        PadButtonVisual.prepare(button)
        local part = pickButtonPart(button)
        if part then
            part.CanCollide = true
            part.CanTouch = true
            part:SetAttribute("SlotIndex", slotIndex)
            part:SetAttribute("PlotId", 1)
            local existing = part:FindFirstChild("PlaceClickDetector")
            if existing then
                existing:Destroy()
            end
            buttonParts[slotIndex] = part
            buttonModels[slotIndex] = button
        end
    end
    selfAny._buttonParts = buttonParts

    if selfAny._buttonLoop then
        task.cancel(selfAny._buttonLoop)
        selfAny._buttonLoop = nil
    end

    local consumed: { [Player]: { [number]: boolean } } = {}
    local leftAt: { [Player]: { [number]: number } } = {}
    local radius = Constants.PLACE_BUTTON_RADIUS
    local reentry = Constants.PLACE_BUTTON_REENTRY_SEC

    selfAny._buttonLoop = task.spawn(function()
        while true do
            task.wait(0.08)
            local now = os.clock()
            for _, player in Players:GetPlayers() do
                if not selfAny._byPlayer[player] then
                    continue
                end
                local character = player.Character
                local root = character and character:FindFirstChild("HumanoidRootPart")
                if root == nil or not root:IsA("BasePart") then
                    continue
                end

                local used = consumed[player]
                if used == nil then
                    used = {}
                    consumed[player] = used
                end
                local leftBucket = leftAt[player]
                if leftBucket == nil then
                    leftBucket = {}
                    leftAt[player] = leftBucket
                end

                for slotIndex, part in buttonParts do
                    local inside = horizontalDistance(root.Position, part.Position) <= radius
                        and math.abs(root.Position.Y - part.Position.Y) <= 12

                    if not inside then
                        if used[slotIndex] then
                            if leftBucket[slotIndex] == nil then
                                leftBucket[slotIndex] = now
                            elseif now - leftBucket[slotIndex] >= reentry then
                                used[slotIndex] = nil
                                leftBucket[slotIndex] = nil
                            end
                        else
                            leftBucket[slotIndex] = nil
                        end
                        continue
                    end

                    leftBucket[slotIndex] = nil
                    if used[slotIndex] then
                        continue
                    end
                    local model = buttonModels[slotIndex]
                    if model and PadButtonVisual.isPressing(model) then
                        continue
                    end
                    used[slotIndex] = true
                    if model then
                        PadButtonVisual.playPress(model)
                    end
                    onStand(player, slotIndex)
                end
            end
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        consumed[player] = nil
        leftAt[player] = nil
    end)
end

function PlotManager:bindFavoriteCollect(onCollect: (player: Player) -> ())
    local selfAny = self :: any
    local plot = selfAny._plot :: Plot
    local button = plot.favoriteCollectButton
    if not button then
        return
    end
    PadButtonVisual.prepare(button)
    local part = pickButtonPart(button)
    if not part then
        return
    end
    part.CanCollide = true
    part.CanTouch = true
    part:SetAttribute("PromptKind", "favorite_collect")

    if selfAny._collectLoop then
        task.cancel(selfAny._collectLoop)
        selfAny._collectLoop = nil
    end

    local consumed: { [Player]: boolean } = {}
    local leftAt: { [Player]: number } = {}
    local radius = Constants.PLACE_BUTTON_RADIUS
    local reentry = Constants.PLACE_BUTTON_REENTRY_SEC

    selfAny._collectLoop = task.spawn(function()
        while true do
            task.wait(0.08)
            local now = os.clock()
            for _, player in Players:GetPlayers() do
                if not selfAny._byPlayer[player] then
                    continue
                end
                local character = player.Character
                local root = character and character:FindFirstChild("HumanoidRootPart")
                if root == nil or not root:IsA("BasePart") then
                    continue
                end

                local inside = horizontalDistance(root.Position, part.Position) <= radius
                    and math.abs(root.Position.Y - part.Position.Y) <= 12
                if not inside then
                    if consumed[player] then
                        if leftAt[player] == nil then
                            leftAt[player] = now
                        elseif now - leftAt[player] >= reentry then
                            consumed[player] = nil
                            leftAt[player] = nil
                        end
                    else
                        leftAt[player] = nil
                    end
                    continue
                end
                leftAt[player] = nil
                if consumed[player] or PadButtonVisual.isPressing(button) then
                    continue
                end
                consumed[player] = true
                PadButtonVisual.playPress(button)
                onCollect(player)
            end
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        consumed[player] = nil
        leftAt[player] = nil
    end)
end

function PlotManager:get(plotId: number): Plot?
    if plotId ~= 1 then
        return nil
    end
    return (self :: any)._plot
end

function PlotManager:getByPlayer(player: Player): Plot?
    if (self :: any)._byPlayer[player] then
        return (self :: any)._plot
    end
    return nil
end

function PlotManager:claim(player: Player): Plot?
    local selfAny = self :: any
    selfAny._byPlayer[player] = true
    selfAny._plot.owner = player
    player:SetAttribute("ShowroomPlotId", 1)
    return selfAny._plot
end

function PlotManager:release(player: Player)
    local selfAny = self :: any
    selfAny._byPlayer[player] = nil
    if selfAny._plot.owner == player then
        selfAny._plot.owner = nil
    end
    player:SetAttribute("ShowroomPlotId", nil)
end

function PlotManager:getStand(_plotId: number, slotIndex: number): BasePart?
    return (self :: any)._plot.stands[slotIndex]
end

function PlotManager:setStandFx(slotIndex: number, occupied: boolean)
    local places = collectPlaceModels()
    local place = places[slotIndex]
    if not place then
        return
    end
    local tele = place:FindFirstChild("Teleport")
    if tele then
        setTeleportEmitters(tele, occupied)
    end
end

function PlotManager:syncStandFx(occupiedBySlot: { [number]: boolean })
    for i = 1, #PLACE_NAMES do
        self:setStandFx(i, occupiedBySlot[i] == true)
    end
    local orphan = Workspace:FindFirstChild("Teleport")
    if orphan and orphan:IsA("Model") then
        setTeleportEmitters(orphan, false)
    end
end

function PlotManager:getFavoriteStand(slotIndex: number): BasePart?
    return (self :: any)._plot.favoriteStands[slotIndex]
end

function PlotManager:getOfferPad(_plotId: number, offerIndex: number): BasePart?
    return (self :: any)._plot.offerPads[offerIndex]
end

function PlotManager:teleportToPlot(_player: Player) end

return PlotManager
