--!strict
-- Uniform toy sizes: authored ScaleTo differs wildly (0.08…2.5+), so never use raw ScaleTo(k).

export type Size3 = { X: number, Y: number, Z: number }

local HeroScaleLogic = {}

--- World pad / pedestal hero height (studs, visual mesh).
HeroScaleLogic.PAD_HEIGHT = 8.0
--- Conveyor mini height (toys heroes produce).
HeroScaleLogic.MINI_HEIGHT = 4.286
--- HeroReveal viewport hero height.
HeroScaleLogic.REVEAL_HEIGHT = 7.0
--- Index card viewport hero height.
HeroScaleLogic.INDEX_HEIGHT = 11.25

--- Cap width/depth so bike-wide meshes still fit the pad.
HeroScaleLogic.PAD_MAX_EXTENT = 11.0
HeroScaleLogic.MINI_MAX_EXTENT = 6.43
HeroScaleLogic.REVEAL_MAX_EXTENT = 9.5
HeroScaleLogic.INDEX_MAX_EXTENT = 15.75

--[[
  Factor to multiply current model:GetScale() so visual height ≈ targetHeight,
  without exceeding maxExtent on any axis (optional).
]]
function HeroScaleLogic.factor(visualSize: Size3, targetHeight: number, maxExtent: number?): number
    local h = math.max(visualSize.Y, 0.05)
    local byHeight = targetHeight / h
    if typeof(maxExtent) == "number" and (maxExtent :: number) > 0 then
        local m = math.max(visualSize.X, visualSize.Y, visualSize.Z, 0.05)
        local byExtent = (maxExtent :: number) / m
        return math.min(byHeight, byExtent)
    end
    return byHeight
end

return HeroScaleLogic
