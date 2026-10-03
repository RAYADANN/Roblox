--!strict
-- Align model on a pad: bottoms match, XZ centered.
-- Uses visible mesh bounds (ignores MutationFx / Root* / invisible helpers).

local PlaceAlign = {}

local function isHelperPart(part: BasePart): boolean
    local n = string.lower(part.Name)
    if part.Transparency >= 0.99 then
        return true
    end
    if n == "mutationfx" or n == "mutationfxcore" then
        return true
    end
    if string.find(n, "root", 1, true) then
        return true
    end
    return false
end

local function getAlignBounds(model: Model): (CFrame, Vector3)
    local minV: Vector3? = nil
    local maxV: Vector3? = nil
    for _, d in model:GetDescendants() do
        if d:IsA("BasePart") and not isHelperPart(d) then
            local cf = d.CFrame
            local half = d.Size * 0.5
            for _, sx in { -1, 1 } do
                for _, sy in { -1, 1 } do
                    for _, sz in { -1, 1 } do
                        local corner = cf * Vector3.new(half.X * sx, half.Y * sy, half.Z * sz)
                        if not minV or not maxV then
                            minV = corner
                            maxV = corner
                        else
                            minV = Vector3.new(
                                math.min(minV.X, corner.X),
                                math.min(minV.Y, corner.Y),
                                math.min(minV.Z, corner.Z)
                            )
                            maxV = Vector3.new(
                                math.max(maxV.X, corner.X),
                                math.max(maxV.Y, corner.Y),
                                math.max(maxV.Z, corner.Z)
                            )
                        end
                    end
                end
            end
        end
    end
    if not minV or not maxV then
        return model:GetBoundingBox()
    end
    return CFrame.new((minV + maxV) * 0.5), maxV - minV
end

--[[
  Bottom of visible mesh = bottom of `pad`.
  Mesh center XZ = pad center XZ.
  If orientationModel is set, use its world rotation (applied first so
  localOffset is measured in the correct axes — not the pre-rotate ones).
]]
function PlaceAlign.onPad(model: Model, pad: BasePart, orientationModel: Model?)
    if orientationModel then
        local pos = model:GetPivot().Position
        model:PivotTo(CFrame.new(pos) * orientationModel:GetPivot().Rotation)
    end

    local pivot = model:GetPivot()
    local bbCf, bbSize = getAlignBounds(model)
    local localOffset = pivot:PointToObjectSpace(bbCf.Position)
    local rotation = pivot.Rotation

    local padBottomY = pad.Position.Y - pad.Size.Y * 0.5
    local desiredCenter = Vector3.new(pad.Position.X, padBottomY + bbSize.Y * 0.5, pad.Position.Z)
    local worldOffset = rotation:VectorToWorldSpace(localOffset)
    local newPivotPos = desiredCenter - worldOffset

    model:PivotTo(CFrame.new(newPivotPos) * rotation)
end

return PlaceAlign
