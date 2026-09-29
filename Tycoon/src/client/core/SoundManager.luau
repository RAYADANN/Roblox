--!strict
-- Cached sounds by eventId. Music loops with fade-in. See audio.mdc.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Logger = require(ReplicatedStorage.shared.util.Logger)
local SoundDatabase = require(ReplicatedStorage.shared.data.SoundDatabase)

local MUSIC_FADE = TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local SoundManager = {}

local SFX_POOL = 3
local _music: { [string]: Sound } = {}
local _pools: { [string]: { Sound } } = {}
local _poolCursor: { [string]: number } = {}
local _volumes: { [string]: number } = {
    sfx = 1,
    ui = 1,
    music = 1,
}
local _musicTween: Tween? = nil
local _started = false

local function resolveCategory(eventId: string, entry: SoundDatabase.SoundEntry): string
    if entry.category then
        return entry.category
    end
    if string.sub(eventId, 1, 3) == "ui_" then
        return "ui"
    end
    if string.sub(eventId, 1, 3) == "bg_" then
        return "music"
    end
    return "sfx"
end

local function makeSound(eventId: string, entry: SoundDatabase.SoundEntry, looped: boolean): Sound
    local sound = Instance.new("Sound")
    sound.Name = eventId
    sound.SoundId = entry.id
    sound.Looped = looped
    sound.Parent = SoundService
    return sound
end

local function ensureMusic(eventId: string, entry: SoundDatabase.SoundEntry): Sound
    local sound = _music[eventId]
    if sound then
        return sound
    end
    sound = makeSound(eventId, entry, true)
    _music[eventId] = sound
    return sound
end

-- Cache a few instances per cue so a second click can start while the first is still playing.
local function nextOneShot(eventId: string, entry: SoundDatabase.SoundEntry): Sound
    local pool = _pools[eventId]
    if pool == nil then
        pool = {}
        _pools[eventId] = pool
    end
    for _, sound in pool do
        if not sound.IsPlaying then
            return sound
        end
    end
    if #pool < SFX_POOL then
        local sound = makeSound(eventId, entry, false)
        table.insert(pool, sound)
        return sound
    end
    local cursor = ((_poolCursor[eventId] or 0) % SFX_POOL) + 1
    _poolCursor[eventId] = cursor
    return pool[cursor]
end

function SoundManager.playMusic(eventId: string)
    local entry = SoundDatabase[eventId]
    if not entry or entry.id == "rbxassetid://0" then
        return
    end

    local ok, err = pcall(function()
        local sound = ensureMusic(eventId, entry)
        local cat = resolveCategory(eventId, entry)
        local target = entry.volume * (_volumes[cat] or 1)
        sound.Looped = true
        if sound.IsPlaying then
            sound.Volume = target
            return
        end
        if _musicTween then
            _musicTween:Cancel()
            _musicTween = nil
        end
        sound.Volume = 0
        sound:Play()
        local tween = TweenService:Create(sound, MUSIC_FADE, { Volume = target })
        _musicTween = tween
        tween:Play()
    end)

    if not ok then
        Logger.warn("SoundManager", `music failed {eventId}: {err}`)
    end
end

function SoundManager.play(eventId: string)
    SoundManager.playWithPitch(eventId, 1)
end

function SoundManager.playWithPitch(eventId: string, pitch: number)
    local entry = SoundDatabase[eventId]
    if not entry or entry.id == "rbxassetid://0" then
        return
    end
    if entry.loop == true then
        SoundManager.playMusic(eventId)
        return
    end

    local ok, err = pcall(function()
        local sound = nextOneShot(eventId, entry)
        local cat = resolveCategory(eventId, entry)
        sound.Volume = entry.volume * (_volumes[cat] or 1)
        sound.PlaybackSpeed = math.clamp(pitch, 0.5, 2)
        sound.TimePosition = 0
        sound:Play()
    end)

    if not ok then
        Logger.warn("SoundManager", `play failed {eventId}: {err}`)
    end
end

function SoundManager.setVolume(category: string, volume: number)
    _volumes[category] = math.clamp(volume, 0, 1)
end

function SoundManager.start()
    if _started then
        return
    end
    _started = true
    SoundManager.playMusic("bg_music")
end

return SoundManager
