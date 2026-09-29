--!strict
-- Clone Workspace.Box1.BillboardGui as-is; only fill text fields.

local Workspace = game:GetService("Workspace")

export type BillboardProps = {
    displayName: string,
    rarity: string,
    mutationText: string?,
    priceText: string?,
}

local WorldBillboard = {}

local function findTemplate(): BillboardGui?
    local box1 = Workspace:FindFirstChild("Box1")
    if not box1 then
        return nil
    end
    local bb = box1:FindFirstChildWhichIsA("BillboardGui", true)
    if bb and bb:IsA("BillboardGui") then
        return bb
    end
    return nil
end

local function titleCase(s: string): string
    if s == "" then
        return s
    end
    return string.upper(string.sub(s, 1, 1)) .. string.lower(string.sub(s, 2))
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

--[[
  Exact clone of Box1.BillboardGui (Size, StudsOffset, children layout, etc.).
  Only Name / Adornee / Parent are set for runtime use — no layout overrides.
]]
function WorldBillboard.attach(adornee: BasePart, name: string?): BillboardGui?
    local existingName = name or "ItemBillboard"
    local old = adornee:FindFirstChild(existingName)
    if old then
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
    bb.Parent = adornee
    return bb
end

--[[
  Screen UI panel: clone BillboardGui.Frame (same fonts/strokes/gradients as world).
]]
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

function WorldBillboard.set(root: Instance, props: BillboardProps)
    local nameLabel = findLabel(root, "NameLabel")
    local rare = findLabel(root, "Rare")
    local mutation = findLabel(root, "Mutation")
    local price = findLabel(root, "Price")

    if nameLabel then
        nameLabel.Text = props.displayName
    end
    if rare then
        rare.Text = titleCase(props.rarity)
    end
    if mutation then
        local mut = props.mutationText or ""
        mutation.Text = mut
        mutation.Visible = mut ~= ""
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

return WorldBillboard
