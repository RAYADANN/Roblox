--!strict
-- Кэш звуков по eventId. См. audio.mdc.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Logger = require(ReplicatedStorage.shared.util.Logger)
local SoundDatabase = require(ReplicatedStorage.shared.data.SoundDatabase)

local SoundManager = {}

local _cache: { [string]: Sound } = {}
local _volumes: { [string]: number } = {
    sfx = 1,
    ui = 1,
    music = 1,
}

local function resolveCategory(eventId: string): string
    if string.sub(eventId, 1, 3) == "ui_" then
        return "ui"
    end
    return "sfx"
end

function SoundManager.play(eventId: string)
    SoundManager.playWithPitch(eventId, 1)
end

function SoundManager.playWithPitch(eventId: string, pitch: number)
    local entry = SoundDatabase[eventId]
    if not entry or entry.id == "rbxassetid://0" then
        return
    end

    local ok, err = pcall(function()
        local sound = _cache[eventId]
        if not sound then
            sound = Instance.new("Sound")
            sound.SoundId = entry.id
            sound.Volume = entry.volume
            sound.Parent = SoundService
            _cache[eventId] = sound
        end
        local cat = resolveCategory(eventId)
        sound.Volume = entry.volume * (_volumes[cat] or 1)
        sound.PlaybackSpeed = math.clamp(pitch, 0.5, 2)
        sound:Stop()
        sound:Play()
    end)

    if not ok then
        Logger.warn("SoundManager", `play failed {eventId}: {err}`)
    end
end

function SoundManager.setVolume(category: string, volume: number)
    _volumes[category] = math.clamp(volume, 0, 1)
end

return SoundManager
