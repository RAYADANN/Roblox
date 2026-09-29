--!strict
-- Stable ordering of Ramp.HeroPlace PlaceParts → slotIndex 1..N.
-- Server prompts, client renderer, and prompt gating MUST share this.

local Workspace = game:GetService("Workspace")

local HeroPlaceLayout = {}

local function sortButtons(buttons: { Instance })
    table.sort(buttons, function(a, b)
        local pa = a:FindFirstChild("PlacePart")
        local pb = b:FindFirstChild("PlacePart")
        if not pa or not pb or not pa:IsA("BasePart") or not pb:IsA("BasePart") then
            return a:GetFullName() < b:GetFullName()
        end
        -- Left column (smaller X) first, then along Z.
        if math.abs(pa.Position.X - pb.Position.X) > 0.5 then
            return pa.Position.X < pb.Position.X
        end
        if pa.Position.Z ~= pb.Position.Z then
            return pa.Position.Z < pb.Position.Z
        end
        return a:GetFullName() < b:GetFullName()
    end)
end

function HeroPlaceLayout.getOrderedPlaceParts(): { BasePart }
    local out: { BasePart } = {}
    local ramp = Workspace:FindFirstChild("Ramp")
    local heroPlace = ramp and ramp:FindFirstChild("HeroPlace")
    if not heroPlace then
        return out
    end
    local buttons = {}
    for _, child in heroPlace:GetChildren() do
        if child.Name == "Button" then
            table.insert(buttons, child)
        end
    end
    sortButtons(buttons)
    for _, button in buttons do
        local pp = button:FindFirstChild("PlacePart")
        if pp and pp:IsA("BasePart") then
            table.insert(out, pp)
        end
    end
    return out
end

return HeroPlaceLayout
