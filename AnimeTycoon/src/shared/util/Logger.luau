--!strict
-- Единый логгер. Не использовать print() по проекту.
-- Pure: без game API — уровень задаётся через setMinLevel из init.

export type Level = "debug" | "info" | "warn" | "error"

local Logger = {}

local MIN_LEVEL: Level = "info"

local ORDER: { [Level]: number } = {
    debug = 1,
    info = 2,
    warn = 3,
    error = 4,
}

function Logger.setMinLevel(level: Level)
    MIN_LEVEL = level
end

local function shouldLog(level: Level): boolean
    return ORDER[level] >= ORDER[MIN_LEVEL]
end

function Logger.debug(tag: string, message: string)
    if shouldLog("debug") then
        print(`[DEBUG][{tag}] {message}`)
    end
end

function Logger.info(tag: string, message: string)
    if shouldLog("info") then
        print(`[INFO][{tag}] {message}`)
    end
end

function Logger.warn(tag: string, message: string)
    if shouldLog("warn") then
        warn(`[WARN][{tag}] {message}`)
    end
end

function Logger.error(tag: string, message: string)
    if shouldLog("error") then
        warn(`[ERROR][{tag}] {message}`)
    end
end

return Logger
