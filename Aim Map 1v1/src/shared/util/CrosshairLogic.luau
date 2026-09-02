--!strict
-- Crosshair id validation / defaults.
--# selene: allow(incorrect_standard_library_use)

local CrosshairDatabase = if script
    then require(script.Parent.Parent.data.CrosshairDatabase)
    else require("@shared/data/CrosshairDatabase")

local CrosshairLogic = {}

function CrosshairLogic.default(): string
    return CrosshairDatabase.defaultId()
end

function CrosshairLogic.isValid(id: string): boolean
    return typeof(id) == "string" and CrosshairDatabase.isValid(id)
end

function CrosshairLogic.resolve(id: string?): string
    if id and CrosshairLogic.isValid(id) then
        return id
    end
    return CrosshairLogic.default()
end

return CrosshairLogic
