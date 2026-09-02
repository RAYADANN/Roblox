--!strict
-- Immediate UI click SFX on Activated. See audio.mdc.
-- Resolves SoundManager from live `client` or StarterPlayer (ReplicatedStorage.UI stories).

local StarterPlayer = game:GetService("StarterPlayer")

type SoundApi = {
    play: (eventId: string) -> (),
}

local function resolveSoundManager(): SoundApi?
    local client = script:FindFirstAncestor("client")
    if not client then
        local starterScripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
        client = starterScripts and starterScripts:FindFirstChild("client")
    end
    if not client then
        return nil
    end
    local core = client:FindFirstChild("core")
    local mod = core and core:FindFirstChild("SoundManager")
    if not mod or not mod:IsA("ModuleScript") then
        return nil
    end
    return require(mod) :: SoundApi
end

local SoundManager = resolveSoundManager()

local playUiClick = {}

function playUiClick.play()
    if SoundManager then
        SoundManager.play("ui_click")
    end
end

function playUiClick.wrapActivated(callback: (() -> ())?): () -> ()
    return function()
        playUiClick.play()
        if callback then
            callback()
        end
    end
end

return playUiClick
