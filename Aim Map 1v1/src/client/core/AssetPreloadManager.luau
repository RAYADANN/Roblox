--!strict
-- Client boot: ContentProvider preload for UI images + VFX textures (+ sounds via SoundManager).

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetPreloadLogic = require(ReplicatedStorage.shared.util.AssetPreloadLogic)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local SoundManager = require(script.Parent.SoundManager)
local TextureCatalog = require(ReplicatedStorage.shared.vfx.TextureCatalog)
local UiImageCatalog = require(ReplicatedStorage.shared.data.UiImageCatalog)

local AssetPreloadManager = {}

local PRIORITY_VFX_KEYS: { string } =
    { "HitPunchCore", "HitSparksSky", "HitSmokeSoft", "HitBodyBurst" }

local _started = false
local _ready = false
local _done = 0
local _total = 0
local _folder: Folder? = nil

local function ensureFolder(): Folder
    local existing = _folder
    if existing and existing.Parent then
        return existing
    end

    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local gui = playerGui:FindFirstChild("AssetPreload")
    if not (gui and gui:IsA("ScreenGui")) then
        local screen = Instance.new("ScreenGui")
        screen.Name = "AssetPreload"
        screen.ResetOnSpawn = false
        screen.Enabled = false
        screen.Parent = playerGui
        gui = screen
    end

    local hold = gui:FindFirstChild("Hold")
    if not (hold and hold:IsA("Folder")) then
        local folder = Instance.new("Folder")
        folder.Name = "Hold"
        folder.Parent = gui
        hold = folder
    end
    _folder = hold
    return hold
end

local function collectUiIds(): { string }
    local ids: { string } = {}
    for _, id in UiImageCatalog.combat do
        table.insert(ids, id)
    end
    return AssetPreloadLogic.uniqueOrdered(ids)
end

local function isPriorityVfx(key: string): boolean
    return table.find(PRIORITY_VFX_KEYS, key) ~= nil
end

local function collectTextureIds(priorityOnly: boolean): { string }
    local ids: { string } = {}
    for key, entry in pairs(TextureCatalog) do
        if type(entry) == "table" then
            local id = (entry :: any).id
            if type(id) == "string" then
                local pri = isPriorityVfx(key)
                if priorityOnly == pri then
                    table.insert(ids, id)
                end
            end
        end
    end
    return AssetPreloadLogic.uniqueOrdered(ids)
end

local function makeImageHolders(ids: { string }): { Instance }
    local folder = ensureFolder()
    local instances: { Instance } = {}
    for _, id in ids do
        local img = Instance.new("ImageLabel")
        img.Name = "Pre_" .. string.gsub(id, "%W", "_")
        img.BackgroundTransparency = 1
        img.ImageTransparency = 1
        img.Size = UDim2.fromOffset(1, 1)
        img.Image = id
        img.Parent = folder
        table.insert(instances, img)
    end
    return instances
end

local function preloadIds(ids: { string })
    if #ids == 0 then
        return
    end
    _total += #ids
    local instances = makeImageHolders(ids)
    local finished = false
    task.spawn(function()
        local ok, err = pcall(function()
            ContentProvider:PreloadAsync(instances, function(_contentId, _status)
                _done = math.min(_total, _done + 1)
            end)
        end)
        if not ok then
            Logger.warn("AssetPreloadManager", `PreloadAsync failed: {err}`)
            _done = _total
        end
        finished = true
    end)
    -- Device emulator / odd viewports can hang PreloadAsync; don't block client boot.
    local deadline = os.clock() + 4
    while not finished and os.clock() < deadline do
        task.wait(0.05)
    end
    if not finished then
        Logger.warn("AssetPreloadManager", "PreloadAsync timed out — continuing boot")
        _done = _total
    end
end

--- Priority combat UI + hit VFX + combat SFX (yields). Rest of VFX textures in background.
function AssetPreloadManager.preload()
    if _started then
        return
    end
    _started = true
    _ready = false
    _done = 0
    _total = 0

    local priority: { string } = {}
    for _, id in collectUiIds() do
        table.insert(priority, id)
    end
    for _, id in collectTextureIds(true) do
        table.insert(priority, id)
    end
    preloadIds(AssetPreloadLogic.uniqueOrdered(priority))
    SoundManager.preload()

    task.spawn(function()
        preloadIds(collectTextureIds(false))
        _ready = true
        Logger.info(
            "AssetPreloadManager",
            `preload complete ({_done}/{math.max(_total, 1)} content callbacks)`
        )
    end)
end

function AssetPreloadManager.isReady(): boolean
    return _ready
end

--- Approximate 0..1 progress (priority + background).
function AssetPreloadManager.getProgress(): number
    if _total <= 0 then
        return if _ready then 1 else 0
    end
    return math.clamp(_done / _total, 0, 1)
end

return AssetPreloadManager
