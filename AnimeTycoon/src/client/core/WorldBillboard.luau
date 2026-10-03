--!strict
-- Clone ReplicatedStorage.GameAssets.Boxes.Box1.BillboardGui.

local MutationShine = require(script.Parent.MutationShine)
local RarityShine = require(script.Parent.RarityShine)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentRoots = require(ReplicatedStorage.shared.util.ContentRoots)

export type BillboardProps = {
    displayName: string,
    rarity: string,
    mutationText: string?,
    priceText: string?,
}

local WorldBillboard = {}

local BILLBOARD_MAX_DISTANCE = 50
local _cachedTemplate: BillboardGui? = nil

local function findTemplate(): BillboardGui?
    if _cachedTemplate and _cachedTemplate.Parent then
        return _cachedTemplate
    end
    local bb = ContentRoots.boxBillboardTemplate()
    if bb then
        _cachedTemplate = bb
    end
    return bb
end

local function titleCase(s: string): string
    if s == "" then
        return s
    end
    return string.upper(string.sub(s, 1, 1)) .. string.lower(string.sub(s, 2))
end

local function unbindShineLabels(root: Instance)
    local rare = WorldBillboard.findLabel(root, "Rare")
    local mutation = WorldBillboard.findLabel(root, "Mutation")
    if rare then
        RarityShine.unbind(rare)
    end
    if mutation then
        MutationShine.unbind(mutation)
    end
end

function WorldBillboard.shortMoney(n: number): string
    local v = math.floor(n + 0.5)
    if v < 1000 then
        return "$" .. tostring(v)
    end
    if v < 1_000_000 then
        return string.format("$%.1fK", v / 1000)
    end
    if v < 1_000_000_000 then
        return string.format("$%.1fM", v / 1_000_000)
    end
    return string.format("$%.1fB", v / 1_000_000_000)
end

function WorldBillboard.attach(adornee: BasePart, name: string?): BillboardGui?
    local existingName = name or "ItemBillboard"
    local old = adornee:FindFirstChild(existingName)
    if old then
        unbindShineLabels(old)
        old:Destroy()
    end

    local template = findTemplate()
    if not template then
        warn("[WorldBillboard] Box1.BillboardGui template missing")
        return nil
    end

    local bb = template:Clone()
    bb.Name = existingName
    bb.Adornee = adornee
    bb.MaxDistance = BILLBOARD_MAX_DISTANCE
    bb.Parent = adornee
    return bb
end

function WorldBillboard.clonePanel(parent: Instance, name: string?): Frame?
    local template = findTemplate()
    if not template then
        warn("[WorldBillboard] Box1.BillboardGui template missing")
        return nil
    end
    local src = template:FindFirstChild("Frame")
    if not src or not src:IsA("Frame") then
        warn("[WorldBillboard] BillboardGui.Frame missing")
        return nil
    end
    local panel = src:Clone()
    panel.Name = name or "BillboardPanel"
    panel.Visible = true
    panel.Parent = parent
    return panel
end

local function findLabel(root: Instance, name: string): TextLabel?
    local direct = root:FindFirstChild(name, true)
    if direct and direct:IsA("TextLabel") then
        return direct
    end
    return nil
end

local function ensureBlackStroke(label: TextLabel)
    local stroke = label:FindFirstChildOfClass("UIStroke")
    if stroke == nil then
        stroke = Instance.new("UIStroke")
        stroke.Parent = label
    end
    stroke.Color = Color3.new(0, 0, 0)
    stroke.LineJoinMode = Enum.LineJoinMode.Bevel
end

function WorldBillboard.set(root: Instance, props: BillboardProps)
    local nameLabel = findLabel(root, "NameLabel")
    local rare = findLabel(root, "Rare")
    local mutation = findLabel(root, "Mutation")
    local price = findLabel(root, "Price")

    if nameLabel then
        nameLabel.Text = props.displayName
        ensureBlackStroke(nameLabel)
    end
    if rare then
        rare.Text = titleCase(props.rarity)
        RarityShine.apply(rare, props.rarity)
        ensureBlackStroke(rare)
    end
    if mutation then
        local mut = props.mutationText or ""
        mutation.Text = mut
        mutation.Visible = mut ~= ""
        if mut ~= "" then
            MutationShine.apply(mutation, mut)
            ensureBlackStroke(mutation)
        else
            MutationShine.unbind(mutation)
        end
    end
    if price then
        local p = props.priceText
        if p and p ~= "" then
            price.Text = p
            price.Visible = true
        else
            price.Visible = false
        end
    end
end

function WorldBillboard.findLabel(root: Instance, name: string): TextLabel?
    return findLabel(root, name)
end

local HERO_BB_NAMES: { [string]: boolean } = {
    SlotBillboard = true,
    ItemBillboard = true,
}

--- Cap distance only for hero slot billboards. All other world UI keeps unlimited range.
function WorldBillboard.applyMaxDistance(root: Instance?)
    local scope = root or game:GetService("Workspace")
    for _, d in scope:GetDescendants() do
        if d:IsA("BillboardGui") then
            if HERO_BB_NAMES[d.Name] == true then
                d.MaxDistance = BILLBOARD_MAX_DISTANCE
            else
                d.MaxDistance = 0
            end
        end
    end
end

return WorldBillboard
