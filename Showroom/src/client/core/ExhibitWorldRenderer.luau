--!strict
-- Renders exhibits on stands + Auction/Favorite prompts.
-- NPC crowds bind to occupied stands (Place/Favorite pads), not to exhibit models.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local AnimalModel = require(script.Parent.AnimalModel)
local AuctionBidderVisual = require(script.Parent.AuctionBidderVisual)
local Constants = require(ReplicatedStorage.shared.data.Constants)
local EggModel = require(script.Parent.EggModel)
local ExhibitLogic = require(ReplicatedStorage.shared.util.ExhibitLogic)
local IncubatorStandFx = require(script.Parent.IncubatorStandFx)
local MutationFx = require(script.Parent.MutationFx)
local MutationLogic = require(ReplicatedStorage.shared.util.MutationLogic)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local Notification = require(script.Parent.Notification)
local NpcCrowdVisual = require(script.Parent.NpcCrowdVisual)
local SoundManager = require(script.Parent.SoundManager)
local WorldUi = require(script.Parent.Parent.ui.world.WorldUi)
local Zap = require(script.Parent.Parent.net.NetClient)

type WorldExhibitPub = NetTypes.WorldExhibitPub
type NpcHandle = NpcCrowdVisual.NpcHandle
type BidderHandle = AuctionBidderVisual.Handle
type ExhibitLabels = WorldUi.ExhibitLabels
type GrowthLabels = WorldUi.GrowthLabels

type StandCrowd = {
    standPart: BasePart,
    cf: CFrame,
    lookAt: Vector3,
    rarity: string,
    targetN: number,
    celebrateUntil: number,
    celebrateKind: string,
    open: boolean,
    npcs: { NpcHandle },
    npcSpawnCooldown: number,
}

type Entry = {
    model: Model,
    body: BasePart,
    petModel: Model?,
    petBody: BasePart?,
    animalName: string,
    billboard: BillboardGui,
    labels: ExhibitLabels,
    growthBb: BillboardGui,
    growthLabels: GrowthLabels,
    growthStartedAt: number,
    growthDuration: number,
    mutationFxKey: string,
    eggVariant: string,
    standFxOn: boolean,
    favoritePrompt: ProximityPrompt,
    auctionPrompt: ProximityPrompt,
    reactPrompt: ProximityPrompt,
    auctionBidders: { BidderHandle },
    auctionLeaveStarted: boolean,
    baseCf: CFrame,
    petBaseCf: CFrame,
    pub: WorldExhibitPub,
}

local ExhibitWorldRenderer = {}

local localPlayer = Players.LocalPlayer

local _folder: Folder? = nil
local _entries: { [string]: Entry } = {}
-- Crowds keyed by physical stand, independent of exhibit uid/owner.
local _crowds: { [string]: StandCrowd } = {}
local _animConn: RBXScriptConnection? = nil

local function favoritePadName(slotIndex: number): string
    return `ItemPlace{slotIndex}`
end

local function ensureFolder(): Folder
    if _folder and _folder.Parent then
        return _folder
    end
    local f = Workspace:FindFirstChild("ShowroomExhibits")
    if f and f:IsA("Folder") then
        _folder = f
        return f
    end
    local created = Instance.new("Folder")
    created.Name = "ShowroomExhibits"
    created.Parent = Workspace
    _folder = created
    return created
end

local function findGrowthStand(slotIndex: number): BasePart?
    local PLACE_NAMES = { "Place", "Place2", "Place3", "Place4", "Place5", "Place6" }
    local stands: { BasePart } = {}
    local seen: { [string]: boolean } = {}
    for _, name in PLACE_NAMES do
        for _, child in Workspace:GetChildren() do
            if child.Name == name and child:IsA("Model") then
                local stand = IncubatorStandFx.findEggPlace(child)
                if stand and not seen[stand:GetFullName()] then
                    seen[stand:GetFullName()] = true
                    table.insert(stands, stand)
                end
            end
        end
    end
    return stands[slotIndex]
end

local function findFavoriteStand(slotIndex: number): BasePart?
    local fav = Workspace:FindFirstChild("FavoritePlace")
    if not fav or not fav:IsA("Model") then
        return nil
    end
    local pad = fav:FindFirstChild(favoritePadName(slotIndex))
    if pad and pad:IsA("BasePart") then
        return pad
    end
    if slotIndex == 1 then
        local legacy = fav:FindFirstChild("ItemPlace")
        if legacy and legacy:IsA("BasePart") then
            return legacy
        end
    end
    return nil
end

local function findStand(pub: WorldExhibitPub): BasePart?
    if pub.isFavorite then
        return findFavoriteStand(pub.slotIndex)
    end
    return findGrowthStand(pub.slotIndex)
end

local function entryKey(pub: WorldExhibitPub): string
    local kind = if pub.isFavorite then "f" else "g"
    return `{pub.ownerUserId}:{kind}:{pub.slotIndex}`
end

-- Stable stand id for crowds (occupied Place / Favorite pads only).
local function crowdKey(pub: WorldExhibitPub): string
    local kind = if pub.isFavorite then "f" else "g"
    return `{pub.plotId}:{kind}:{pub.slotIndex}`
end

-- Feet on stand footprint; gaze toward exhibit height — never the animated item CFrame.
local function standCrowdPose(stand: BasePart): (CFrame, Vector3)
    local floorY = stand.Position.Y - stand.Size.Y * 0.5
    local cf = CFrame.new(stand.Position.X, floorY, stand.Position.Z)
    local lookAt = stand.Position + Vector3.new(0, stand.Size.Y * 0.35, 0)
    return cf, lookAt
end

local function formatBid(n: number): string
    return WorldUi.shortMoney(n)
end

local function decodeAuctionBids(json: string?): { { buyerName: string, amount: number } }
    if typeof(json) ~= "string" or json == "" then
        return {}
    end
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(json)
    end)
    if ok and typeof(decoded) == "table" then
        return decoded :: { { buyerName: string, amount: number } }
    end
    return {}
end

local function ensurePrompt(
    parent: BasePart,
    name: string,
    action: string,
    kind: string,
    stackIndex: number
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
    prompt.ActionText = action
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = 14
    prompt.RequiresLineOfSight = false
    WorldUi.stylePrompt(prompt, kind, stackIndex)
    return prompt
end

local function animOffset(_animId: string, t: number, _scale: number): CFrame
    -- MVP: only spin around Y.
    return CFrame.Angles(0, t * 2.6, 0)
end

local function localProgress(entry: Entry, pub: WorldExhibitPub): number
    if pub.evolved or pub.isFavorite then
        return 1
    end
    if entry.growthDuration > 0 then
        local elapsed = os.clock() - entry.growthStartedAt
        return math.clamp(elapsed / entry.growthDuration, 0, 1)
    end
    return math.clamp(pub.progress or 0, 0, 1)
end

local function hatchScales(pub: WorldExhibitPub, progress: number): (number, number)
    local mutIds = MutationLogic.idsFromLabel(pub.mutationLabel)
    local sizeId = pub.sizeId or "medium"
    local mutated = pub.mutated == true
    local evolved = pub.evolved == true
    return ExhibitLogic.hatchEggScale(progress, evolved, mutated, sizeId, mutIds),
        ExhibitLogic.hatchPetScale(progress, evolved, mutated, sizeId, mutIds)
end

local function destroyPet(entry: Entry)
    if entry.petModel then
        entry.petModel:Destroy()
    end
    entry.petModel = nil
    entry.petBody = nil
    entry.animalName = ""
end

local function ensurePet(entry: Entry, pub: WorldExhibitPub, folder: Folder)
    local wantVariant = entry.eggVariant
    local wantSpecies = AnimalModel.speciesForKey(wantVariant, pub.uid)
    if wantSpecies == "" then
        destroyPet(entry)
        return
    end
    if entry.petModel and entry.animalName == wantSpecies then
        return
    end
    destroyPet(entry)
    local pet, body = AnimalModel.clone(`Pet_{pub.uid}`, wantVariant, pub.uid)
    if not pet or not body then
        return
    end
    pet.Parent = folder
    AnimalModel.setVisible(pet, false)
    entry.petModel = pet
    entry.petBody = body
    entry.animalName = wantSpecies
    entry.petBaseCf = AnimalModel.cfOnSurface(pet, entry.baseCf)
end

local function activeFxBody(entry: Entry, eggScale: number, petScale: number): BasePart
    if petScale >= eggScale and entry.petBody then
        return entry.petBody
    end
    return entry.body
end

local function syncEntry(key: string, pub: WorldExhibitPub)
    local stand = findStand(pub)
    if not stand then
        return
    end
    local folder = ensureFolder()
    local entry = _entries[key]
    local isNew = entry == nil
    if not entry then
        local egg, part = EggModel.clone(`Exhibit_{pub.uid}`, pub.templateId)
        egg.Parent = folder

        local bb, labels = WorldUi.attachExhibitBillboard(stand)
        local growthBb, growthLabels = WorldUi.attachGrowthBillboard(stand)

        local existingTake = part:FindFirstChild("TakePrompt")
        if existingTake then
            existingTake:Destroy()
        end
        local existingSell = part:FindFirstChild("SellPrompt")
        if existingSell then
            existingSell:Destroy()
        end
        -- Prompts on the stand pedestal (not the egg body) so UI sits at incubator height.
        for _, staleName in { "FavoritePrompt", "AuctionPrompt", "ReactPrompt" } do
            local staleBody = part:FindFirstChild(staleName)
            if staleBody then
                staleBody:Destroy()
            end
        end

        local favoritePrompt =
            ensurePrompt(stand, "FavoritePrompt", "Place Favorite", "favorite", 0)
        favoritePrompt.KeyboardKeyCode = Enum.KeyCode.Q

        local auctionPrompt = ensurePrompt(stand, "AuctionPrompt", "Auction", "auction", 1)
        auctionPrompt.KeyboardKeyCode = Enum.KeyCode.E

        local reactPrompt = ensurePrompt(stand, "ReactPrompt", "React", "react", 0)

        favoritePrompt.Triggered:Connect(function(player)
            if player ~= localPlayer then
                return
            end
            local live = _entries[key]
            if not live then
                return
            end
            if live.pub.isFavorite or not live.pub.evolved then
                return
            end
            SoundManager.play("ui_click")
            local result = Zap.MoveToFavorite.Call(live.pub.slotIndex)
            if not result.success then
                SoundManager.play("sell_fail")
                local msg = result.error or "Cannot favorite"
                if result.error == "favorite_full" then
                    msg = "Favorite stands are full"
                elseif result.error == "not_grown" then
                    msg = "Grow the exhibit first"
                end
                Notification.show({
                    text = msg,
                    color = Color3.fromRGB(255, 120, 80),
                })
            end
        end)

        auctionPrompt.Triggered:Connect(function(player)
            if player ~= localPlayer then
                return
            end
            local live = _entries[key]
            if not live then
                return
            end
            if not live.pub.evolved then
                return
            end
            SoundManager.play("ui_click")
            local fromFavorite = live.pub.isFavorite == true
            local result = Zap.StartAuction.Call(live.pub.slotIndex, fromFavorite)
            if not result.success then
                SoundManager.play("sell_fail")
                local msg = result.error or "Cannot auction"
                if result.error == "not_grown" then
                    msg = "Grow the exhibit first"
                elseif result.error == "auction_busy" then
                    msg = "Auction already in progress"
                end
                Notification.show({
                    text = msg,
                    color = Color3.fromRGB(255, 120, 80),
                })
            end
        end)

        reactPrompt.Triggered:Connect(function(player)
            if player ~= localPlayer then
                return
            end
            local live = _entries[key]
            if not live then
                return
            end
            if live.pub.ownerUserId == localPlayer.UserId or live.pub.isFavorite then
                return
            end
            Zap.ReactExhibit.Call(live.pub.ownerUserId, live.pub.slotIndex)
        end)

        entry = {
            model = egg,
            body = part,
            petModel = nil,
            petBody = nil,
            animalName = "",
            billboard = bb,
            labels = labels,
            growthBb = growthBb,
            growthLabels = growthLabels,
            growthStartedAt = 0,
            growthDuration = 0,
            mutationFxKey = "",
            eggVariant = EggModel.variantOf(egg),
            standFxOn = false,
            favoritePrompt = favoritePrompt,
            auctionPrompt = auctionPrompt,
            reactPrompt = reactPrompt,
            auctionBidders = {},
            auctionLeaveStarted = false,
            baseCf = stand.CFrame,
            petBaseCf = stand.CFrame,
            pub = pub,
        }
        _entries[key] = entry
    end

    -- Swap egg mesh if catalog template maps to another Eggs/* variant.
    local wantVariant = EggModel.variantForKey(pub.templateId)
    if entry.eggVariant ~= wantVariant then
        local parent = entry.model.Parent
        local old = entry.model
        local egg, part = EggModel.clone(old.Name, pub.templateId)
        egg.Parent = parent
        old:Destroy()
        entry.model = egg
        entry.body = part
        entry.eggVariant = wantVariant
        entry.mutationFxKey = ""
        destroyPet(entry)
    end

    ensurePet(entry, pub, folder)

    local prevPub = entry.pub
    entry.pub = pub
    if entry.favoritePrompt.Parent ~= stand then
        entry.favoritePrompt.Parent = stand
    end
    if entry.auctionPrompt.Parent ~= stand then
        entry.auctionPrompt.Parent = stand
    end
    if entry.reactPrompt.Parent ~= stand then
        entry.reactPrompt.Parent = stand
    end

    local progress = localProgress(entry, pub)
    local eggScale, petScale = hatchScales(pub, progress)
    local offset = animOffset("spin", os.clock() + pub.slotIndex, math.max(eggScale, petScale, 0.2))

    if eggScale < 0.05 or (pub.auctioning and pub.auctionPhase == "sold") then
        EggModel.setVisible(entry.model, false)
    else
        EggModel.setVisible(entry.model, true)
        EggModel.applyScale(entry.model, eggScale)
        entry.baseCf = EggModel.cfOnSurface(entry.model, stand.CFrame)
        entry.model:PivotTo(entry.baseCf * offset)
    end

    if entry.petModel and entry.petBody then
        if petScale < 0.05 or (pub.auctioning and pub.auctionPhase == "sold") then
            AnimalModel.setVisible(entry.petModel, false)
        else
            AnimalModel.setVisible(entry.petModel, true)
            AnimalModel.applyScale(entry.petModel, petScale)
            entry.petBaseCf = AnimalModel.cfOnSurface(entry.petModel, stand.CFrame)
            entry.petModel:PivotTo(entry.petBaseCf * offset)
        end
    end

    local fxBody = activeFxBody(entry, eggScale, petScale)
    WorldUi.pinBillboardAbove(entry.billboard, stand, fxBody)

    -- Land burst only; Teleport Enabled is server-owned (PlotManager.syncStandFx).
    if not pub.isFavorite then
        if not entry.standFxOn then
            if isNew then
                IncubatorStandFx.onEggLanded(stand)
            end
            entry.standFxOn = true
        end
    else
        if entry.standFxOn and not prevPub.isFavorite then
            local pad = findGrowthStand(prevPub.slotIndex)
            if pad then
                IncubatorStandFx.onEggCleared(pad)
            end
        end
        entry.standFxOn = false
    end

    local auctioning = pub.auctioning == true
    local auctionPhase = pub.auctionPhase or ""
    local auctionBids = decodeAuctionBids(pub.auctionBidsJson)

    local mutText = ""
    if typeof(pub.mutationLabel) == "string" then
        mutText = pub.mutationLabel
    end

    WorldUi.setExhibitBillboard(entry.labels, {
        displayName = pub.displayName,
        rarity = pub.rarity,
        mutationText = mutText,
    })

    local fxKey = `{mutText}|{if petScale >= 0.05 then "pet" else "egg"}`
    if entry.mutationFxKey ~= fxKey then
        entry.mutationFxKey = fxKey
        MutationFx.syncFromLabel(fxBody, mutText)
    end
    MutationFx.follow(fxBody)

    local isOwner = pub.ownerUserId == localPlayer.UserId
    local grown = pub.evolved == true
    local onFavorite = pub.isFavorite == true
    local showGrowth = not grown and not auctioning and not onFavorite
    if showGrowth then
        -- Lock duration once. Server progress uses os.time() (1s steps) — do NOT
        -- resync fill from remainingSec or the bar will wobble every second.
        if entry.growthDuration <= 0 then
            local dur = pub.evolveDurationSec
            if typeof(dur) ~= "number" or dur <= 0 then
                dur = 25
            end
            local p0 = math.clamp(pub.progress or 0, 0, 1)
            entry.growthDuration = dur
            entry.growthStartedAt = os.clock() - p0 * dur
            WorldUi.pinGrowthBillboard(entry.growthBb, stand)
        end
    else
        entry.growthDuration = 0
        entry.growthStartedAt = 0
        WorldUi.setGrowthBillboard(entry.growthLabels, {
            progress = 0,
            remainingSec = 0,
            visible = false,
        })
    end
    entry.auctionPrompt.Enabled = isOwner and grown and not auctioning
    entry.auctionPrompt.ActionText = "Auction"
    local auctionValue = pub.auctionValue
    if typeof(auctionValue) ~= "number" or auctionValue <= 0 then
        auctionValue = pub.sellPrice
    end
    entry.auctionPrompt.ObjectText = `${WorldUi.shortMoney(auctionValue)}`
    entry.auctionPrompt:SetAttribute("SlotIndex", pub.slotIndex)
    WorldUi.stylePrompt(entry.auctionPrompt, "auction", if onFavorite then 0 else 1)
    entry.favoritePrompt.Enabled = isOwner and grown and not auctioning and not onFavorite
    entry.favoritePrompt.ActionText = "Place Favorite"
    local favIncome = math.max(0, pub.incomeRate)
    entry.favoritePrompt.ObjectText = `+{WorldUi.shortMoney(favIncome)}/s`
    entry.favoritePrompt:SetAttribute("SlotIndex", pub.slotIndex)
    WorldUi.stylePrompt(entry.favoritePrompt, "favorite", 0)
    entry.reactPrompt.Enabled = not isOwner and not auctioning and not onFavorite
    entry.reactPrompt.ActionText = "React"
    entry.reactPrompt.ObjectText = pub.displayName
    WorldUi.stylePrompt(entry.reactPrompt, "react", 0)

    -- Dedicated auction bidders: approach, stand, bid; winner jumps; sold → leave with pet.
    if auctioning then
        if not entry.auctionLeaveStarted then
            local bidderCount = math.clamp(math.floor(pub.auctionBidderCount or #auctionBids), 3, 8)
            while #entry.auctionBidders > bidderCount do
                local b = table.remove(entry.auctionBidders)
                if b then
                    AuctionBidderVisual.destroy(b)
                end
            end
            while #entry.auctionBidders < bidderCount do
                local i = #entry.auctionBidders + 1
                local handle = AuctionBidderVisual.spawn(stand.CFrame, i, bidderCount)
                if handle then
                    table.insert(entry.auctionBidders, handle)
                else
                    break
                end
            end

            for i, bidder in entry.auctionBidders do
                local bid = auctionBids[i]
                if bid then
                    AuctionBidderVisual.setBid(bidder, `{bid.buyerName}: {formatBid(bid.amount)}`)
                else
                    AuctionBidderVisual.setBid(bidder, nil)
                end
                AuctionBidderVisual.setWinner(
                    bidder,
                    auctionPhase == "finished" and i == #entry.auctionBidders
                )
            end
        end

        if auctionPhase == "sold" and not entry.auctionLeaveStarted then
            entry.auctionLeaveStarted = true
            local winner = entry.auctionBidders[#entry.auctionBidders]
            for i = 1, #entry.auctionBidders - 1 do
                AuctionBidderVisual.destroy(entry.auctionBidders[i])
            end
            entry.auctionBidders = if winner then { winner } else {}
            if winner then
                AuctionBidderVisual.setBid(winner, "Sold!")
                local leaveBody = entry.petBody or entry.body
                AuctionBidderVisual.beginLeaveWithPet(winner, stand.CFrame, leaveBody)
            end
            EggModel.setVisible(entry.model, false)
            if entry.petModel then
                AnimalModel.setVisible(entry.petModel, false)
            end
        end
    else
        if #entry.auctionBidders > 0 then
            AuctionBidderVisual.destroyAll(entry.auctionBidders)
            entry.auctionLeaveStarted = false
        end
    end
end

local function syncCrowds(pubs: { WorldExhibitPub })
    local alive: { [string]: boolean } = {}
    local perStandMax = Constants.NPC_PER_STAND_MAX

    for _, pub in pubs do
        local stand = findStand(pub)
        if not stand then
            continue
        end
        local key = crowdKey(pub)
        alive[key] = true
        local auctioning = pub.auctioning == true
        local cf, lookAt = standCrowdPose(stand)
        local targetN = if auctioning
            then 0
            else math.clamp(math.floor((pub.npcTarget or 0) + 0.5), 0, perStandMax)

        local crowd = _crowds[key]
        if not crowd then
            crowd = {
                standPart = stand,
                cf = cf,
                lookAt = lookAt,
                rarity = pub.rarity,
                targetN = targetN,
                celebrateUntil = pub.celebrateUntil or 0,
                celebrateKind = pub.celebrateKind or "",
                open = not auctioning,
                npcs = {},
                npcSpawnCooldown = 0,
            }
            _crowds[key] = crowd
        else
            crowd.standPart = stand
            crowd.cf = cf
            crowd.lookAt = lookAt
            crowd.rarity = pub.rarity
            crowd.targetN = targetN
            crowd.celebrateUntil = pub.celebrateUntil or 0
            crowd.celebrateKind = pub.celebrateKind or ""
            crowd.open = not auctioning
        end

        if auctioning then
            for _, npc in crowd.npcs do
                if not NpcCrowdVisual.isLeaving(npc) then
                    NpcCrowdVisual.beginLeave(npc, crowd.cf)
                end
            end
        else
            local present = 0
            for _, npc in crowd.npcs do
                if NpcCrowdVisual.isAlive(npc) and not NpcCrowdVisual.isLeaving(npc) then
                    present += 1
                end
            end
            if present > targetN + 1 then
                for _, npc in crowd.npcs do
                    if present <= targetN then
                        break
                    end
                    if NpcCrowdVisual.isAlive(npc) and not NpcCrowdVisual.isLeaving(npc) then
                        NpcCrowdVisual.beginLeave(npc, crowd.cf)
                        present -= 1
                    end
                end
            end
            while present < targetN do
                local handle = NpcCrowdVisual.spawn(
                    crowd.cf,
                    present + 1,
                    targetN,
                    crowd.rarity,
                    key,
                    crowd.npcs
                )
                if not handle then
                    break
                end
                table.insert(crowd.npcs, handle)
                present += 1
            end
        end

        for _, npc in crowd.npcs do
            if NpcCrowdVisual.isAlive(npc) then
                NpcCrowdVisual.setBidText(npc, nil)
            end
        end
    end

    for key, crowd in _crowds do
        if not alive[key] then
            for _, npc in crowd.npcs do
                if NpcCrowdVisual.isAlive(npc) and not NpcCrowdVisual.isLeaving(npc) then
                    NpcCrowdVisual.beginLeave(npc, crowd.cf)
                elseif NpcCrowdVisual.isAlive(npc) == false then
                    NpcCrowdVisual.destroy(npc)
                end
            end
            local still = false
            for _, npc in crowd.npcs do
                if NpcCrowdVisual.isAlive(npc) then
                    still = true
                    break
                end
            end
            if not still then
                _crowds[key] = nil
            else
                crowd.targetN = 0
                crowd.open = false
            end
        end
    end
end

local function applyPubs(pubs: { WorldExhibitPub })
    local alive: { [string]: boolean } = {}
    for _, pub in pubs do
        local key = entryKey(pub)
        alive[key] = true
        syncEntry(key, pub)
    end
    for key, entry in _entries do
        if not alive[key] then
            AuctionBidderVisual.destroyAll(entry.auctionBidders)
            if entry.standFxOn and not entry.pub.isFavorite then
                local pad = findGrowthStand(entry.pub.slotIndex)
                if pad then
                    IncubatorStandFx.onEggCleared(pad)
                end
            end
            if entry.billboard and entry.billboard.Parent then
                entry.billboard:Destroy()
            end
            if entry.growthBb and entry.growthBb.Parent then
                entry.growthBb:Destroy()
            end
            destroyPet(entry)
            entry.model:Destroy()
            _entries[key] = nil
        end
    end
    syncCrowds(pubs)
end

local function tickVisuals(dt: number)
    local t = os.clock()
    local nowWall = os.time()

    local stands: { NpcCrowdVisual.StandInfo } = {}
    for key, crowd in _crowds do
        table.insert(stands, {
            key = key,
            cf = crowd.cf,
            lookAt = crowd.lookAt,
            rarity = crowd.rarity,
            celebrate = crowd.celebrateUntil > nowWall,
            celebrateKind = crowd.celebrateKind,
            open = crowd.open,
        })
    end

    local totalPresent = 0
    local allNpcs: { NpcHandle } = {}
    for _, crowd in _crowds do
        for _, npc in crowd.npcs do
            if NpcCrowdVisual.isAlive(npc) and not NpcCrowdVisual.isLeaving(npc) then
                totalPresent += 1
            end
            if NpcCrowdVisual.isAlive(npc) then
                table.insert(allNpcs, npc)
            end
        end
    end

    for _, entry in _entries do
        local pub = entry.pub
        local progress = localProgress(entry, pub)
        local eggScale, petScale = hatchScales(pub, progress)
        local spinScale = math.max(eggScale, petScale, 0.2)
        local offset = animOffset("spin", t + pub.slotIndex, spinScale)
        local sold = pub.auctioning and pub.auctionPhase == "sold"
        local stand = findStand(pub)

        if sold then
            EggModel.setVisible(entry.model, false)
            if entry.petModel then
                AnimalModel.setVisible(entry.petModel, false)
            end
        else
            if eggScale < 0.05 then
                EggModel.setVisible(entry.model, false)
            else
                EggModel.setVisible(entry.model, true)
                EggModel.applyScale(entry.model, eggScale)
                if stand then
                    entry.baseCf = EggModel.cfOnSurface(entry.model, stand.CFrame)
                end
                entry.model:PivotTo(entry.baseCf * offset)
            end

            if entry.petModel and entry.petBody then
                if petScale < 0.05 then
                    AnimalModel.setVisible(entry.petModel, false)
                else
                    AnimalModel.setVisible(entry.petModel, true)
                    AnimalModel.applyScale(entry.petModel, petScale)
                    if stand then
                        entry.petBaseCf = AnimalModel.cfOnSurface(entry.petModel, stand.CFrame)
                    end
                    entry.petModel:PivotTo(entry.petBaseCf * offset)
                end
            end
        end

        local fxBody = activeFxBody(entry, eggScale, petScale)
        MutationFx.follow(fxBody)
        if stand then
            WorldUi.pinBillboardAbove(entry.billboard, stand, fxBody)
            local growing = not pub.evolved and not pub.auctioning and not pub.isFavorite
            if growing and entry.growthDuration > 0 then
                local elapsed = os.clock() - entry.growthStartedAt
                local barProgress = math.clamp(elapsed / entry.growthDuration, 0, 1)
                local rem = math.max(0, entry.growthDuration - elapsed)
                WorldUi.setGrowthBillboard(entry.growthLabels, {
                    progress = barProgress,
                    remainingSec = rem,
                    visible = true,
                })
            elseif entry.growthBb.Enabled then
                WorldUi.setGrowthBillboard(entry.growthLabels, {
                    progress = 0,
                    remainingSec = 0,
                    visible = false,
                })
            end

            local aliveBidders: { BidderHandle } = {}
            for _, bidder in entry.auctionBidders do
                if bidder.model and bidder.model.Parent then
                    AuctionBidderVisual.step(bidder, stand.CFrame, dt)
                    if bidder.model.Parent then
                        table.insert(aliveBidders, bidder)
                    end
                end
            end
            entry.auctionBidders = aliveBidders
        end
    end

    for key, crowd in _crowds do
        for _, npc in crowd.npcs do
            NpcCrowdVisual.step(npc, stands, allNpcs, dt)
        end

        local aliveNpcs: { NpcHandle } = {}
        for _, npc in crowd.npcs do
            if NpcCrowdVisual.isAlive(npc) then
                table.insert(aliveNpcs, npc)
            end
        end
        crowd.npcs = aliveNpcs

        if crowd.targetN <= 0 and #crowd.npcs == 0 then
            _crowds[key] = nil
            continue
        end

        if crowd.open and crowd.targetN > 0 then
            crowd.npcSpawnCooldown = math.max(0, crowd.npcSpawnCooldown - dt)

            for _, npc in crowd.npcs do
                if NpcCrowdVisual.shouldRetire(npc) then
                    NpcCrowdVisual.beginLeave(npc, crowd.cf)
                    break
                end
            end

            local present = 0
            for _, npc in crowd.npcs do
                if NpcCrowdVisual.isAlive(npc) and not NpcCrowdVisual.isLeaving(npc) then
                    present += 1
                end
            end

            if
                present < crowd.targetN
                and totalPresent < Constants.NPC_TOTAL_SOFT_CAP
                and crowd.npcSpawnCooldown <= 0
            then
                local handle = NpcCrowdVisual.spawn(
                    crowd.cf,
                    present + 1,
                    crowd.targetN,
                    crowd.rarity,
                    key,
                    crowd.npcs
                )
                if handle then
                    table.insert(crowd.npcs, handle)
                    totalPresent += 1
                    crowd.npcSpawnCooldown = 0.45 + math.random() * 1.1
                end
            end
        end
    end
end

function ExhibitWorldRenderer.start()
    IncubatorStandFx.disableAll()
    Zap.WorldExhibitsSync.On(function(value)
        local pubs = NetTypes.decodeWorld(value.payloadJson)
        applyPubs(pubs)
    end)
    if not _animConn then
        _animConn = RunService.RenderStepped:Connect(tickVisuals)
    end
    task.spawn(function()
        task.wait(0.6)
        pcall(function()
            Zap.RequestHudSync.Call()
        end)
    end)
end

return ExhibitWorldRenderer
