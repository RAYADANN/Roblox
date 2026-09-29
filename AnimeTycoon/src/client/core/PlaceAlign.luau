--!strict
-- Align model on a pad: bottoms match, XZ centered.
-- Orientation from optional template (e.g. BoxHeroStand); snap rot BEFORE measuring offset.

local PlaceAlign = {}

--[[
  Bottom of model bounding box = bottom of `pad`.
  Bounding-box center XZ = pad center XZ.
  If orientationModel is set, use its world rotation (applied first so
  localOffset is measured in the correct axes — not the pre-rotate ones).
]]
function PlaceAlign.onPad(model: Model, pad: BasePart, orientationModel: Model?)
    if orientationModel then
        local pos = model:GetPivot().Position
        model:PivotTo(CFrame.new(pos) * orientationModel:GetPivot().Rotation)
    end

    local pivot = model:GetPivot()
    local bbCf, bbSize = model:GetBoundingBox()
    local localOffset = pivot:PointToObjectSpace(bbCf.Position)
    local rotation = pivot.Rotation

    local padBottomY = pad.Position.Y - pad.Size.Y * 0.5
    local desiredCenter = Vector3.new(pad.Position.X, padBottomY + bbSize.Y * 0.5, pad.Position.Z)
    local worldOffset = rotation:VectorToWorldSpace(localOffset)
    local newPivotPos = desiredCenter - worldOffset

    model:PivotTo(CFrame.new(newPivotPos) * rotation)
end

return PlaceAlign
