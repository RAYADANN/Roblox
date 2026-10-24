--!strict
-- Clone a BillboardGui authored in Studio. Do not build world UI in code.

local WorldBillboard = {}

local DEFAULT_MAX_DISTANCE = 50

function WorldBillboard.attach(
    adornee: BasePart,
    template: BillboardGui,
    name: string?
): BillboardGui
    local billboardName = name or template.Name
    local old = adornee:FindFirstChild(billboardName)
    if old then
        old:Destroy()
    end
    local clone = template:Clone()
    clone.Name = billboardName
    clone.Adornee = adornee
    clone.MaxDistance = if template.MaxDistance > 0
        then template.MaxDistance
        else DEFAULT_MAX_DISTANCE
    clone.Parent = adornee
    return clone
end

return WorldBillboard
