--!strict
-- Настройки игрока. См. accessibility.mdc.

local SettingsManager = {}

local _reduceMotion = false
local _haptics = true

function SettingsManager.isReduceMotion(): boolean
    return _reduceMotion
end

function SettingsManager.setReduceMotion(value: boolean)
    _reduceMotion = value
end

function SettingsManager.isHapticsEnabled(): boolean
    return _haptics
end

function SettingsManager.setHapticsEnabled(value: boolean)
    _haptics = value
end

return SettingsManager
