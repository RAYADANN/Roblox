--!strict
-- Кэш звуков по eventId. См. audio.mdc.
-- Combat SFX: preload + clone templates so Play is not waiting on asset download.

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Logger = require(ReplicatedStorage.shared.util.Logger)
local SoundDatabase = require(ReplicatedStorage.shared.data.SoundDatabase)

local SoundManager = {}

local _cache: { [string]: Sound } = {}
local _templates: { [string]: Sound } = {}
local _templateFolder: Folder? = nil
local _preloaded = false
local _volumes: { [string]: number } = {
    sfx = 1,
    ui = 1,
    music = 1,
}

-- Load these first — first shot / hit must feel instant.
local PRIORITY_IDS = { "usp_fire", "hit_head", "hit_body", "kill", "dead", "footstep", "ui_click" }

local function resolveCategory(eventId: string): string
    if string.sub(eventId, 1, 3) == "ui_" then
        return "ui"
    end
    return "sfx"
end

local function ensureTemplateFolder(): Folder
    local folder = _templateFolder
    if folder and folder.Parent then
        return folder
    end
    folder = Instance.new("Folder")
    folder.Name = "AimSoundTemplates"
    folder.Parent = SoundService
    _templateFolder = folder
    return folder
end

local function makeTemplate(eventId: string, soundId: string): Sound
    local existing = _templates[eventId]
    if existing and existing.Parent then
        return existing
    end
    local sound = Instance.new("Sound")
    sound.Name = `Tpl_{eventId}`
    sound.SoundId = soundId
    sound.Volume = 0
    sound.Parent = ensureTemplateFolder()
    _templates[eventId] = sound
    return sound
end

local function preloadList(ids: { string })
    local instances: { Instance } = {}
    for _, eventId in ids do
        local entry = SoundDatabase[eventId]
        if entry and entry.id ~= "rbxassetid://0" then
            table.insert(instances, makeTemplate(eventId, entry.id))
        end
    end
    if #instances == 0 then
        return
    end
    pcall(function()
        ContentProvider:PreloadAsync(instances)
    end)
end

--- Warm combat SFX first, then the rest of SoundDatabase (non-blocking after priority).
function SoundManager.preload()
    if _preloaded then
        return
    end
    _preloaded = true

    preloadList(PRIORITY_IDS)

    task.spawn(function()
        local rest: { string } = {}
        for eventId, entry in SoundDatabase do
            if entry.id ~= "rbxassetid://0" and not table.find(PRIORITY_IDS, eventId) then
                table.insert(rest, eventId)
            end
        end
        preloadList(rest)
        Logger.info("SoundManager", "preload complete")
    end)
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
        if not sound or not sound.Parent then
            local template = makeTemplate(eventId, entry.id)
            sound = template:Clone()
            sound.Name = `Cached_{eventId}`
            sound.Parent = SoundService
            _cache[eventId] = sound
        end
        local cat = resolveCategory(eventId)
        sound.Volume = entry.volume * (_volumes[cat] or 1)
        sound.PlaybackSpeed = math.clamp(pitch, 0.5, 2)
        sound.TimePosition = 0
        sound:Play()
    end)

    if not ok then
        Logger.warn("SoundManager", `play failed {eventId}: {err}`)
    end
end

--- One-shot from preloaded template so overlapping shots don't fight a single cache.
function SoundManager.playOneShot(eventId: string, volumeScale: number?, pitch: number?)
    local entry = SoundDatabase[eventId]
    if not entry or entry.id == "rbxassetid://0" then
        return
    end
    local scale = math.clamp(volumeScale or 1, 0, 1)
    if scale < 0.01 then
        return
    end

    local ok, err = pcall(function()
        local template = _templates[eventId]
        local sound: Sound
        if template and template.Parent then
            sound = template:Clone()
        else
            sound = Instance.new("Sound")
            sound.SoundId = entry.id
        end
        sound.Name = `OneShot_{eventId}`
        local cat = resolveCategory(eventId)
        sound.Volume = entry.volume * scale * (_volumes[cat] or 1)
        sound.PlaybackSpeed = math.clamp(pitch or 1, 0.5, 2)
        sound.TimePosition = 0
        sound.Parent = SoundService
        sound.Ended:Connect(function()
            sound:Destroy()
        end)
        sound:Play()
        task.delay(8, function()
            if sound.Parent then
                sound:Destroy()
            end
        end)
    end)

    if not ok then
        Logger.warn("SoundManager", `playOneShot failed {eventId}: {err}`)
    end
end

function SoundManager.setVolume(category: string, volume: number)
    _volumes[category] = math.clamp(volume, 0, 1)
end

return SoundManager
