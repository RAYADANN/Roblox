--!strict
-- UI SFX without requiring StarterPlayer `client.core` from ReplicatedStorage.UI
-- (Hoarcekat stories live under UI, so `script.Parent…core.SoundManager` is missing).

local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")

export type SoundPlayer = {
    play: (eventId: string) -> (),
}

local cached: SoundPlayer? = nil

local function tryRequire(module: Instance?): SoundPlayer?
    if module == nil or not module:IsA("ModuleScript") then
        return nil
    end
    local ok, result = pcall(require, module)
    if ok and typeof(result) == "table" and typeof(result.play) == "function" then
        return result :: SoundPlayer
    end
    return nil
end

local function soundModuleFrom(scriptsRoot: Instance?): Instance?
    local client = scriptsRoot and scriptsRoot:FindFirstChild("client")
    local core = client and client:FindFirstChild("core")
    return core and core:FindFirstChild("SoundManager")
end

local function findSoundManager(): SoundPlayer?
    local player = Players.LocalPlayer
    if player then
        local sm = tryRequire(soundModuleFrom(player:FindFirstChild("PlayerScripts")))
        if sm then
            return sm
        end
    end
    return tryRequire(soundModuleFrom(StarterPlayer:FindFirstChild("StarterPlayerScripts")))
end

local function play(eventId: string)
    if cached == nil then
        cached = findSoundManager()
    end
    local player = cached
    if player == nil then
        return
    end
    player.play(eventId)
end

return {
    play = play,
}
