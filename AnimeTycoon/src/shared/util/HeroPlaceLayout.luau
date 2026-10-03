--!strict
-- Stable ordering of HeroPlace PlaceParts across floors → slotIndex 1..30.
-- Floor1 Ramp, Floor2 SecondFloor.Ramp2, Floor3 ThirdFloor.Ramp3.
-- Buttons named Button1..Button10 open in numeric order within each floor.

local BaseLayout = require(script.Parent.BaseLayout)

local HeroPlaceLayout = {}

export type FloorDef = {
    floorIndex: number,
    floorModelName: string?, -- nil = always-visible ground floor under Base.Ramp
    rampName: string,
}

local FLOORS: { FloorDef } = {
    { floorIndex = 1, floorModelName = nil, rampName = "Ramp" },
    { floorIndex = 2, floorModelName = "SecondFloor", rampName = "Ramp2" },
    { floorIndex = 3, floorModelName = "ThirdFloor", rampName = "Ramp3" },
}

local function buttonIndex(name: string): number?
    local n = string.match(name, "^Button(%d+)$")
    if n then
        return tonumber(n)
    end
    return nil
end

local function sortButtons(buttons: { Instance })
    local allNumbered = true
    for _, b in buttons do
        if buttonIndex(b.Name) == nil then
            allNumbered = false
            break
        end
    end
    table.sort(buttons, function(a, b)
        if allNumbered then
            return (buttonIndex(a.Name) :: number) < (buttonIndex(b.Name) :: number)
        end
        local pa = a:FindFirstChild("PlacePart")
        local pb = b:FindFirstChild("PlacePart")
        if not pa or not pb or not pa:IsA("BasePart") or not pb:IsA("BasePart") then
            return a:GetFullName() < b:GetFullName()
        end
        if math.abs(pa.Position.X - pb.Position.X) > 0.5 then
            return pa.Position.X < pb.Position.X
        end
        if pa.Position.Z ~= pb.Position.Z then
            return pa.Position.Z < pb.Position.Z
        end
        return a:GetFullName() < b:GetFullName()
    end)
end

local function heroPlaceForFloor(base: Instance, floor: FloorDef): Instance?
    if floor.floorModelName == nil then
        local ramp = base:FindFirstChild(floor.rampName) or BaseLayout.getRamp(base)
        return ramp and ramp:FindFirstChild("HeroPlace")
    end
    local floorModel = base:FindFirstChild(floor.floorModelName)
    if not floorModel then
        return nil
    end
    local ramp = floorModel:FindFirstChild(floor.rampName)
    return ramp and ramp:FindFirstChild("HeroPlace")
end

local function collectButtons(heroPlace: Instance): { Instance }
    local buttons = {}
    for _, child in heroPlace:GetChildren() do
        if child.Name == "Button" or buttonIndex(child.Name) ~= nil then
            table.insert(buttons, child)
        end
    end
    sortButtons(buttons)
    return buttons
end

function HeroPlaceLayout.floors(): { FloorDef }
    return FLOORS
end

function HeroPlaceLayout.getOrderedPlaceParts(base: Instance?): { BasePart }
    local out: { BasePart } = {}
    local root = base or BaseLayout.getPrimary()
    if not root then
        return out
    end
    for _, floor in FLOORS do
        local heroPlace = heroPlaceForFloor(root, floor)
        if not heroPlace then
            continue
        end
        for _, button in collectButtons(heroPlace) do
            local pp = button:FindFirstChild("PlacePart")
            if pp and pp:IsA("BasePart") then
                table.insert(out, pp)
            end
        end
    end
    return out
end

--- PlacePart + owning Button + floor index for unlock visuals.
function HeroPlaceLayout.getOrderedSlots(base: Instance?): {
    {
        slotIndex: number,
        floorIndex: number,
        button: Instance,
        placePart: BasePart,
        floorModel: Instance?,
    }
}
    local out = {}
    local root = base or BaseLayout.getPrimary()
    if not root then
        return out
    end
    local slotIndex = 0
    for _, floor in FLOORS do
        local floorModel = if floor.floorModelName
            then root:FindFirstChild(floor.floorModelName)
            else nil
        local heroPlace = heroPlaceForFloor(root, floor)
        if not heroPlace then
            continue
        end
        for _, button in collectButtons(heroPlace) do
            local pp = button:FindFirstChild("PlacePart")
            if pp and pp:IsA("BasePart") then
                slotIndex += 1
                table.insert(out, {
                    slotIndex = slotIndex,
                    floorIndex = floor.floorIndex,
                    button = button,
                    placePart = pp,
                    floorModel = floorModel,
                })
            end
        end
    end
    return out
end

return HeroPlaceLayout
