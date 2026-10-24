--!strict
-- Who may use a plot prompt. Server checks this before the action.
-- Client hides prompts it does not own; that hide is not the authority.

local PlotOwnership = {}

PlotOwnership.OWNER_ATTRIBUTE = "OwnerUserId"

function PlotOwnership.owns(ownerUserId: number?, playerUserId: number): boolean
    return ownerUserId ~= nil and ownerUserId ~= 0 and ownerUserId == playerUserId
end

return PlotOwnership
