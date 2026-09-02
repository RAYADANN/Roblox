--!strict
-- Server-authoritative USP fire: rate-limit, origin sanity, raycast, damage.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.shared.data.Constants)
local CrosshairDatabase = require(ReplicatedStorage.shared.data.CrosshairDatabase)
local DeathRagdoll = require(script.Parent.DeathRagdoll)
local MatchManager = require(script.Parent.MatchManager)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local PracticeDummyManager = require(script.Parent.PracticeDummyManager)
local RateLimiter = require(script.Parent.Parent.util.RateLimiter)
local VfxBroadcaster = require(script.Parent.VfxBroadcaster)
local WeaponLogic = require(ReplicatedStorage.shared.util.WeaponLogic)
local WorldMuzzle = require(script.Parent.WorldMuzzle)
local Zap = require(script.Parent.Parent.net.NetServer)

export type Deps = {
    matchManager: MatchManager.MatchManager,
    practiceDummies: PracticeDummyManager.PracticeDummyManager,
    setCrosshair: (player: Player, crosshairId: string) -> NetTypes.SetCrosshairResult,
    notify: (player: Player, kind: string, payload: string) -> (),
}

export type WeaponFireManager = {
    fire: (
        self: WeaponFireManager,
        player: Player,
        origin: Vector3,
        direction: Vector3
    ) -> NetTypes.FireWeaponResult,
    fireFromBot: (
        self: WeaponFireManager,
        botModel: Model,
        origin: Vector3,
        direction: Vector3
    ) -> NetTypes.FireWeaponResult,
}

local WeaponFireManager = {}
WeaponFireManager.__index = WeaponFireManager

function WeaponFireManager.new(deps: Deps): WeaponFireManager
    return setmetatable({
        _deps = deps,
        _limiter = RateLimiter.new(Constants.FIRE_RATE_MAX_PER_SEC, 1),
        _lastShot = {} :: { [Player]: number },
        _lastBotShot = {} :: { [Model]: number },
    }, WeaponFireManager) :: any
end

local function characterPosition(player: Player): Vector3?
    local character = player.Character
    if not character then
        return nil
    end
    local head = character:FindFirstChild("Head")
    if head and head:IsA("BasePart") then
        return head.Position
    end
    local root = character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        return root.Position
    end
    return nil
end

local function modelMuzzle(model: Model): Vector3?
    return WorldMuzzle.ofCharacter(model)
end

local function miss(traceEnd: Vector3?): NetTypes.FireWeaponResult
    return { success = true, hit = false, killed = false, traceEnd = traceEnd }
end

local function broadcastFire(except: Player?, origin: Vector3)
    local args = { effectId = "UspFire", pos = origin, intensity = 1 }
    if except then
        VfxBroadcaster.playExcept(except, args)
    else
        VfxBroadcaster.playAll(args)
    end
end

local function broadcastHit(except: Player?, headshot: boolean, hitPos: Vector3)
    local args = {
        effectId = if headshot then "HitHead" else "HitBody",
        pos = hitPos,
        intensity = if headshot then 1.2 else 0.8,
    }
    if except then
        VfxBroadcaster.playExcept(except, args)
    else
        VfxBroadcaster.playAll(args)
    end
end

local function broadcastSurface(except: Player?, hitPos: Vector3)
    local args = {
        effectId = "HitSurface",
        pos = hitPos,
        intensity = 0.75,
    }
    if except then
        VfxBroadcaster.playExcept(except, args)
    else
        VfxBroadcaster.playAll(args)
    end
end

--- Ray hit world / non-damage target: body attachment FX, no flesh SFX.
local function surfaceImpact(
    except: Player?,
    hitPos: Vector3,
    endPos: Vector3
): NetTypes.FireWeaponResult
    broadcastSurface(except, hitPos)
    return {
        success = true,
        hit = false,
        killed = false,
        hitPos = hitPos,
        traceEnd = endPos,
    }
end

local function notifyTookDamage(victim: Player, damage: number, headshot: boolean, fromPos: Vector3)
    Zap.TookDamage.Fire(victim, {
        damage = damage,
        headshot = headshot,
        fromPos = fromPos,
    })
end

-- Remote viewers: tracer leaves the gun. Shooter plays a separate FP muzzle tracer locally.
local function broadcastTracer(except: Player?, fromPos: Vector3, toPos: Vector3, skinId: string)
    local args = {
        effectId = "BulletTracer",
        intensity = 1,
        from = fromPos,
        to = toPos,
        skinId = skinId,
    }
    if except then
        VfxBroadcaster.playExcept(except, args)
    else
        VfxBroadcaster.playAll(args)
    end
end

function WeaponFireManager:fire(
    player: Player,
    origin: Vector3,
    direction: Vector3
): NetTypes.FireWeaponResult
    local matchManager = self._deps.matchManager
    local practiceDummies = self._deps.practiceDummies
    local inMatch = matchManager:isAliveInMatch(player)
    local hasCharacter = player.Character ~= nil and characterPosition(player) ~= nil
    if not inMatch and not hasCharacter then
        return { success = false, hit = false, killed = false, error = "no_character" }
    end

    if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then
        return { success = false, hit = false, killed = false, error = "bad_args" }
    end

    if not self._limiter:allow(player) then
        return { success = false, hit = false, killed = false, error = "rate" }
    end

    local now = os.clock()
    local last = self._lastShot[player]
    if last and (now - last) < Constants.USP_FIRE_COOLDOWN_SEC then
        return { success = false, hit = false, killed = false, error = "cooldown" }
    end

    local charPos = characterPosition(player)
    if not charPos then
        return { success = false, hit = false, killed = false, error = "no_character" }
    end

    if not WeaponLogic.isOriginSane((charPos - origin).Magnitude) then
        origin = charPos
    end

    if not WeaponLogic.directionMagnitudeOk(direction.Magnitude) then
        return { success = false, hit = false, killed = false, error = "bad_dir" }
    end
    local dir = direction.Unit

    self._lastShot[player] = now
    broadcastFire(player, origin)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { player.Character :: Instance }

    local result = workspace:Raycast(origin, dir * Constants.USP_MAX_RANGE_STUDS, params)
    local endPos = if result then result.Position else origin + dir * Constants.USP_MAX_RANGE_STUDS
    if result and not WeaponLogic.isInRange(result.Distance) then
        endPos = origin + dir * Constants.USP_MAX_RANGE_STUDS
        result = nil
    end

    local skinId = matchManager:getFlexVisible(player)
    local characterForMuzzle = player.Character
    local muzzle = if characterForMuzzle then WorldMuzzle.ofCharacter(characterForMuzzle) else nil
    broadcastTracer(player, muzzle or origin, endPos, skinId)

    if not result then
        return miss(endPos)
    end

    local hitPart = result.Instance

    -- Crosshair wall panel (CS-custom style: shoot to select)
    local panelId = hitPart:GetAttribute(Constants.CROSSHAIR_PANEL_ATTRIBUTE)
    if typeof(panelId) == "string" then
        local setResult = self._deps.setCrosshair(player, panelId)
        if setResult.success and setResult.crosshairId then
            self._deps.notify(
                player,
                "crosshair",
                CrosshairDatabase.displayName(setResult.crosshairId)
            )
        end
        broadcastSurface(player, result.Position)
        return {
            success = true,
            hit = true,
            killed = false,
            hitPos = result.Position,
            traceEnd = endPos,
        }
    end

    local character = hitPart:FindFirstAncestorOfClass("Model")
    if not character then
        return surfaceImpact(player, result.Position, endPos)
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return surfaceImpact(player, result.Position, endPos)
    end

    local zone = WeaponLogic.zoneFromPart(hitPart.Name)
    local damage = WeaponLogic.damageForZone(zone)
    local headshot = zone == "head"

    if practiceDummies:isDummy(character) then
        if inMatch then
            return surfaceImpact(player, result.Position, endPos)
        end
        local hpAfter = WeaponLogic.applyDamage(humanoid.Health, damage)
        humanoid.Health = hpAfter
        VfxBroadcaster.playAll({
            effectId = "HitConfirm",
            intensity = if headshot then 1.2 else 0.8,
            pos = result.Position,
        })
        broadcastHit(player, headshot, result.Position)
        local killed = WeaponLogic.isLethal(hpAfter)
        if killed then
            humanoid.Health = 0
            DeathRagdoll.apply(character, dir, result.Position)
            practiceDummies:onKilled(character)
        end
        return {
            success = true,
            hit = true,
            killed = killed,
            damage = damage,
            hitPos = result.Position,
            headshot = headshot,
            traceEnd = endPos,
        }
    end

    -- Duel bot
    if matchManager:isBotCharacter(character) then
        if not inMatch then
            return surfaceImpact(player, result.Position, endPos)
        end
        local matchState = matchManager:getMatchFor(player)
        if not matchState or not matchManager:isBotAliveInMatch(matchState.matchId) then
            return surfaceImpact(player, result.Position, endPos)
        end

        local hpAfter = WeaponLogic.applyDamage(humanoid.Health, damage)
        humanoid.Health = hpAfter
        VfxBroadcaster.playAll({
            effectId = "HitConfirm",
            intensity = if headshot then 1.2 else 0.8,
            pos = result.Position,
        })
        broadcastHit(player, headshot, result.Position)
        local killed = WeaponLogic.isLethal(hpAfter)
        if killed then
            humanoid.Health = 0
            DeathRagdoll.apply(character, dir, result.Position)
            matchManager:onPlayerKillBot(player, character)
        end
        return {
            success = true,
            hit = true,
            killed = killed,
            damage = damage,
            hitPos = result.Position,
            headshot = headshot,
            traceEnd = endPos,
        }
    end

    if not inMatch then
        return surfaceImpact(player, result.Position, endPos)
    end

    local victimPlayer = Players:GetPlayerFromCharacter(character)
    if not victimPlayer then
        return surfaceImpact(player, result.Position, endPos)
    end

    local opponent = matchManager:getOpponent(player)
    if opponent ~= victimPlayer then
        return surfaceImpact(player, result.Position, endPos)
    end
    if not matchManager:isAliveInMatch(victimPlayer) then
        return surfaceImpact(player, result.Position, endPos)
    end

    local hpAfter = WeaponLogic.applyDamage(humanoid.Health, damage)
    humanoid.Health = hpAfter

    VfxBroadcaster.playAll({
        effectId = "HitConfirm",
        intensity = if headshot then 1.2 else 0.8,
        pos = result.Position,
    })
    broadcastHit(player, headshot, result.Position)
    notifyTookDamage(victimPlayer, damage, headshot, origin)

    local killed = WeaponLogic.isLethal(hpAfter)
    if killed then
        humanoid.Health = 0
        DeathRagdoll.apply(character, dir, result.Position)
        matchManager:onKill(player, victimPlayer)
    end

    return {
        success = true,
        hit = true,
        killed = killed,
        damage = damage,
        hitPos = result.Position,
        headshot = headshot,
        traceEnd = endPos,
    }
end

function WeaponFireManager:fireFromBot(
    botModel: Model,
    origin: Vector3,
    direction: Vector3
): NetTypes.FireWeaponResult
    local matchManager = self._deps.matchManager
    if not matchManager:isBotCharacter(botModel) then
        return { success = false, hit = false, killed = false, error = "not_bot" }
    end

    if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then
        return { success = false, hit = false, killed = false, error = "bad_args" }
    end

    local now = os.clock()
    local last = self._lastBotShot[botModel]
    if last and (now - last) < Constants.USP_FIRE_COOLDOWN_SEC then
        return { success = false, hit = false, killed = false, error = "cooldown" }
    end

    local muzzle = modelMuzzle(botModel)
    if not muzzle then
        return { success = false, hit = false, killed = false, error = "no_character" }
    end
    -- Always leave the gun. Caller direction must already be muzzle → target.
    origin = muzzle
    if not WeaponLogic.directionMagnitudeOk(direction.Magnitude) then
        return { success = false, hit = false, killed = false, error = "bad_dir" }
    end
    local dir = direction.Unit
    self._lastBotShot[botModel] = now
    broadcastFire(nil, origin)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { botModel }

    local result = workspace:Raycast(origin, dir * Constants.USP_MAX_RANGE_STUDS, params)
    local endPos = if result then result.Position else origin + dir * Constants.USP_MAX_RANGE_STUDS
    if result and not WeaponLogic.isInRange(result.Distance) then
        endPos = origin + dir * Constants.USP_MAX_RANGE_STUDS
        result = nil
    end
    local botMuzzle = WorldMuzzle.ofCharacter(botModel) or origin
    broadcastTracer(nil, botMuzzle, endPos, Constants.DEFAULT_SKIN_ID)

    if not result then
        return miss(endPos)
    end

    local hitPart = result.Instance
    local character = hitPart:FindFirstAncestorOfClass("Model")
    if not character then
        return surfaceImpact(nil, result.Position, endPos)
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return surfaceImpact(nil, result.Position, endPos)
    end

    local victimPlayer = Players:GetPlayerFromCharacter(character)
    if not victimPlayer then
        return surfaceImpact(nil, result.Position, endPos)
    end
    if not matchManager:isAliveInMatch(victimPlayer) then
        return surfaceImpact(nil, result.Position, endPos)
    end

    local zone = WeaponLogic.zoneFromPart(hitPart.Name)
    local damage = WeaponLogic.damageForZone(zone)
    local headshot = zone == "head"
    local hpAfter = WeaponLogic.applyDamage(humanoid.Health, damage)
    humanoid.Health = hpAfter

    VfxBroadcaster.playAll({
        effectId = "HitConfirm",
        intensity = if headshot then 1.2 else 0.8,
        pos = result.Position,
    })
    broadcastHit(nil, headshot, result.Position)
    notifyTookDamage(victimPlayer, damage, headshot, origin)

    local killed = WeaponLogic.isLethal(hpAfter)
    if killed then
        humanoid.Health = 0
        DeathRagdoll.apply(character, dir, result.Position)
        matchManager:onBotKillPlayer(botModel, victimPlayer)
    end

    return {
        success = true,
        hit = true,
        killed = killed,
        damage = damage,
        hitPos = result.Position,
        headshot = headshot,
        traceEnd = endPos,
    }
end

return WeaponFireManager
