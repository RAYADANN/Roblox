--!strict
-- Tycoon-style world chrome: BlockItem billboards, growth bar, custom prompt styling.

local RunService = game:GetService("RunService")

local theme = require(script.Parent.Parent.theme)

local C = theme.Colors
local Font = theme.Font
local Rarity = theme.Rarity

local CARD_RADIUS = 14
local CARD_SHADOW = 5

local WorldUi = {}

function WorldUi.rarityColor(rarity: string): Color3
    return Rarity[string.lower(rarity)] or Rarity.common
end

function WorldUi.promptAccent(kind: string?): Color3
    local map = theme.PromptKind
    if kind and map[kind] then
        return map[kind]
    end
    return map.default
end

function WorldUi.stylePrompt(prompt: ProximityPrompt, kind: string?, stackIndex: number?)
    prompt.Style = Enum.ProximityPromptStyle.Custom
    prompt.RequiresLineOfSight = false
    prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
    prompt.ClickablePrompt = true
    prompt.MaxActivationDistance = math.clamp(prompt.MaxActivationDistance, 8, 18)
    -- Vertical stack so Auction + Favorite (same stand) never sit on top of each other.
    local stack = stackIndex or 0
    prompt.UIOffset = Vector2.new(0, -stack * 92)
    if kind then
        prompt:SetAttribute("UiKind", kind)
    end
    prompt:SetAttribute("PromptStack", stack)
end

function WorldUi.shortMoney(n: number): string
    local v = math.floor(n + 0.5)
    if v < 1000 then
        return tostring(v)
    end
    if v < 1_000_000 then
        return string.format("%.1fK", v / 1000)
    end
    if v < 1_000_000_000 then
        return string.format("%.1fM", v / 1_000_000)
    end
    return string.format("%.1fB", v / 1_000_000_000)
end

function WorldUi.makeCard(parent: Instance, size: UDim2, accent: Color3): (Frame, Frame)
    local shadow = Instance.new("Frame")
    shadow.Name = "CardShadow"
    shadow.Size = size
    shadow.Position = UDim2.fromOffset(0, CARD_SHADOW)
    shadow.BackgroundColor3 = C.worldShadow
    shadow.BackgroundTransparency = 0.35
    shadow.BorderSizePixel = 0
    shadow.ZIndex = 1
    shadow.Parent = parent
    local sc = Instance.new("UICorner")
    sc.CornerRadius = UDim.new(0, CARD_RADIUS)
    sc.Parent = shadow

    local card = Instance.new("Frame")
    card.Name = "Card"
    card.Size = size
    card.BackgroundColor3 = C.worldCard
    card.BackgroundTransparency = 0.08
    card.BorderSizePixel = 0
    card.ZIndex = 2
    card.Parent = parent
    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, CARD_RADIUS)
    cc.Parent = card
    local stroke = Instance.new("UIStroke")
    stroke.Color = C.moneyButtonStroke
    stroke.Thickness = theme.Stroke.world
    stroke.Transparency = 0.15
    stroke.Parent = card

    local bar = Instance.new("Frame")
    bar.Name = "AccentBar"
    bar.Size = UDim2.new(0, 6, 1, -16)
    bar.Position = UDim2.new(0, 6, 0.5, 0)
    bar.AnchorPoint = Vector2.new(0, 0.5)
    bar.BackgroundColor3 = accent
    bar.BorderSizePixel = 0
    bar.ZIndex = 3
    bar.Parent = card
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 3)
    bc.Parent = bar

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -24, 1, -10)
    content.Position = UDim2.fromOffset(16, 5)
    content.BackgroundTransparency = 1
    content.ZIndex = 3
    content.Parent = card
    return card, content
end

export type ExhibitLabels = {
    petName: TextLabel,
    rarity: TextLabel,
    mutation: TextLabel,
    price: TextLabel?,
}

-- BlockItem Mutation.SparkGradient / growth fill / offer price
local SPARK_GRADIENT = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 127)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 0)),
})

local RARITY_GRADIENT_FALLBACK: { [string]: string } = {
    uncommon = "Common",
}

local function titleCase(id: string): string
    if id == "" then
        return ""
    end
    return string.upper(string.sub(id, 1, 1)) .. string.lower(string.sub(id, 2))
end

local COMBO_SHIMMER_NAME = "ComboShimmer"
local MAX_COMBO_KEYS = 20

local FALLBACK_MUTATION_COLORS: { [string]: Color3 } = {
    neon = Color3.fromRGB(40, 255, 210),
    gloss = Color3.fromRGB(230, 235, 255),
}

local function sampleGradientColors(grad: UIGradient): { Color3 }
    local out: { Color3 } = {}
    local kps = grad.Color.Keypoints
    if #kps == 0 then
        return out
    end
    table.insert(out, kps[1].Value)
    if #kps >= 3 then
        table.insert(out, kps[math.ceil(#kps / 2)].Value)
    end
    if #kps > 1 then
        table.insert(out, kps[#kps].Value)
    end
    return out
end

local function mutationStems(mutText: string, mutationIds: { string }?): { string }
    local stems: { string } = {}
    if mutationIds and #mutationIds > 0 then
        for _, id in mutationIds do
            if id ~= "" then
                table.insert(stems, titleCase(id))
            end
        end
        return stems
    end
    for _, seg in string.split(mutText, "-") do
        if seg ~= "" then
            table.insert(stems, titleCase(seg))
        end
    end
    return stems
end

local function ensureComboShimmer(label: TextLabel): UIGradient
    local existing = label:FindFirstChild(COMBO_SHIMMER_NAME)
    if existing and existing:IsA("UIGradient") then
        return existing
    end
    local g = Instance.new("UIGradient")
    g.Name = COMBO_SHIMMER_NAME
    g.Rotation = 0
    g.Parent = label
    return g
end

local function disableAllGradients(label: TextLabel)
    for _, child in label:GetChildren() do
        if child:IsA("UIGradient") then
            child.Enabled = false
        end
    end
end

--[[
  Stack mutation colors into one gradient so 2nd/3rd mutations add hues
  instead of replacing the previous gradient.
]]
local function setMutationGradientFromLabel(
    label: TextLabel,
    mutText: string,
    mutationIds: { string }?
)
    local colors: { Color3 } = {}
    for _, stem in mutationStems(mutText, mutationIds) do
        local named = label:FindFirstChild(`{stem}Gradient`)
        if named and named:IsA("UIGradient") and named.Name ~= COMBO_SHIMMER_NAME then
            for _, c in sampleGradientColors(named) do
                table.insert(colors, c)
            end
        else
            local fb = FALLBACK_MUTATION_COLORS[string.lower(stem)]
            if fb then
                table.insert(colors, fb)
            end
        end
    end

    if #colors == 0 then
        colors = {
            Color3.fromRGB(255, 80, 180),
            Color3.fromRGB(80, 220, 255),
            Color3.fromRGB(255, 230, 80),
            Color3.fromRGB(180, 100, 255),
        }
    elseif #colors == 1 then
        -- ColorSequence needs ≥2 keypoints; nudge a second stop for shimmer.
        local c = colors[1]
        local h, s, v = c:ToHSV()
        table.insert(colors, Color3.fromHSV(h, s, math.clamp(v * 0.55, 0, 1)))
    end

    -- Cap keypoints (Roblox max 20); keep endpoints of each chunk.
    if #colors > MAX_COMBO_KEYS then
        local trimmed: { Color3 } = {}
        local step = (#colors - 1) / (MAX_COMBO_KEYS - 1)
        for i = 0, MAX_COMBO_KEYS - 1 do
            local idx = math.floor(i * step + 0.5) + 1
            table.insert(trimmed, colors[idx])
        end
        colors = trimmed
    end

    local keys = table.create(#colors)
    local last = math.max(#colors - 1, 1)
    for i, c in colors do
        keys[i] = ColorSequenceKeypoint.new((i - 1) / last, c)
    end

    disableAllGradients(label)
    local combo = ensureComboShimmer(label)
    combo.Color = ColorSequence.new(keys)
    combo.Enabled = true
    label.TextColor3 = C.white
end

-- Scroll enabled mutation gradients so the label shimmer-scrolls.
local _shimmerLabels: { [TextLabel]: boolean } = {}
local _shimmerConn: RBXScriptConnection? = nil

local function stopShimmerIfIdle()
    if next(_shimmerLabels) ~= nil then
        return
    end
    if _shimmerConn then
        _shimmerConn:Disconnect()
        _shimmerConn = nil
    end
end

local function ensureMutationShimmer()
    if _shimmerConn then
        return
    end
    -- Sine Offset (no modulo wrap) — linear % jump looked stuttery.
    _shimmerConn = RunService.RenderStepped:Connect(function()
        local t = os.clock()
        local ox = math.sin(t * 1.2) * 0.7
        local oy = math.cos(t * 0.9) * 0.2
        for label in _shimmerLabels do
            if label.Parent == nil or not label.Visible then
                _shimmerLabels[label] = nil
            else
                for _, child in label:GetChildren() do
                    if child:IsA("UIGradient") and child.Enabled then
                        child.Offset = Vector2.new(ox, oy)
                    end
                end
            end
        end
        stopShimmerIfIdle()
    end)
end

local function setMutationShimmer(label: TextLabel, on: boolean)
    if on then
        _shimmerLabels[label] = true
        ensureMutationShimmer()
    else
        _shimmerLabels[label] = nil
        stopShimmerIfIdle()
    end
end

local function setRarityGradient(label: TextLabel, rarity: string)
    local key = string.lower(rarity)
    local stem = RARITY_GRADIENT_FALLBACK[key] or titleCase(key)
    local want = `{stem}Gradient`
    for _, child in label:GetChildren() do
        if child:IsA("UIGradient") then
            child.Enabled = child.Name == want
        end
    end
end

local function findBlockItemTemplate(): BillboardGui?
    local block = game:GetService("Workspace"):FindFirstChild("BlockItem")
    if not block then
        return nil
    end
    local bb = block:FindFirstChild("BillboardGui")
    if bb and bb:IsA("BillboardGui") then
        return bb
    end
    return nil
end

local function applyBillboardStroke(label: TextLabel)
    local stroke = label:FindFirstChildOfClass("UIStroke")
    if not stroke then
        stroke = Instance.new("UIStroke")
        stroke.Parent = label
    end
    -- Match BlockItem Rarity/PetName/Mutation outline.
    stroke.Color = Color3.new(0, 0, 0)
    stroke.Thickness = 5
    stroke.Transparency = 0
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    stroke.LineJoinMode = Enum.LineJoinMode.Round
    stroke.StrokeSizingMode = Enum.StrokeSizingMode.FixedSize
end

local function applySparkPriceStyle(label: TextLabel)
    label.TextColor3 = Color3.new(1, 1, 1)
    applyBillboardStroke(label)

    local existing = label:FindFirstChild("SparkGradient")
    if existing and existing:IsA("UIGradient") then
        existing.Color = SPARK_GRADIENT
        existing.Enabled = true
        for _, child in label:GetChildren() do
            if child:IsA("UIGradient") and child ~= existing then
                child.Enabled = false
            end
        end
        return
    end
    for _, child in label:GetChildren() do
        if child:IsA("UIGradient") then
            child.Enabled = false
        end
    end
    local spark = Instance.new("UIGradient")
    spark.Name = "SparkGradient"
    spark.Color = SPARK_GRADIENT
    spark.Rotation = 0
    spark.Parent = label
end

local function ensurePriceLabel(frame: Frame): TextLabel
    local existing = frame:FindFirstChild("Price")
    if existing and existing:IsA("TextLabel") then
        existing.LayoutOrder = 4
        existing.AnchorPoint = Vector2.new(0.5, 0)
        existing.Position = UDim2.fromScale(0.5, 0)
        existing.Size = UDim2.new(1, 0, 0.28, 0)
        existing.Visible = true
        applySparkPriceStyle(existing)
        return existing
    end
    local price = Instance.new("TextLabel")
    price.Name = "Price"
    price.BackgroundTransparency = 1
    price.Size = UDim2.new(1, 0, 0.28, 0)
    price.AnchorPoint = Vector2.new(0.5, 0)
    price.Position = UDim2.fromScale(0.5, 0)
    price.LayoutOrder = 4
    price.Font = Font.title
    price.TextScaled = true
    price.TextXAlignment = Enum.TextXAlignment.Center
    price.Text = ""
    price.Visible = true
    price.Parent = frame
    applySparkPriceStyle(price)
    return price
end

local function labelsFromBillboard(bb: BillboardGui, withPrice: boolean): ExhibitLabels?
    local frame = bb:FindFirstChild("Frame")
    if not (frame and frame:IsA("Frame")) then
        return nil
    end
    local petName = frame:FindFirstChild("PetName")
    local rarity = frame:FindFirstChild("Rarity")
    local mutation = frame:FindFirstChild("Mutation")
    if
        petName
        and petName:IsA("TextLabel")
        and rarity
        and rarity:IsA("TextLabel")
        and mutation
        and mutation:IsA("TextLabel")
    then
        rarity.LayoutOrder = 1
        petName.LayoutOrder = 2
        mutation.LayoutOrder = 3
        -- Template uses AnchorPoint 0.5 — breaks UIListLayout stacking / clips text.
        for _, label in { rarity, petName, mutation } do
            label.AnchorPoint = Vector2.new(0.5, 0)
            label.Position = UDim2.fromScale(0.5, 0)
            label.Size = UDim2.new(1, 0, label.Size.Y.Scale, 0)
        end
        local price: TextLabel? = nil
        if withPrice then
            price = ensurePriceLabel(frame)
        else
            local hide = frame:FindFirstChild("Price")
            if hide and hide:IsA("TextLabel") then
                hide.Visible = false
            end
        end
        return {
            petName = petName,
            rarity = rarity,
            mutation = mutation,
            price = price,
        }
    end
    return nil
end

local function prepareBillboard(bb: BillboardGui)
    bb.AlwaysOnTop = true
    bb.LightInfluence = 0
    bb.ClipsDescendants = false
    bb.MaxDistance = math.max(bb.MaxDistance, 80)
end

local function billboardHeightStuds(bb: BillboardGui, adornee: BasePart): number
    local size = bb.Size
    -- Offset = absolute studs. Scale×adornee.Y on a tall pad inflates clearance.
    if size.Y.Offset > 0 then
        return math.max(size.Y.Offset, 0.5)
    end
    return math.clamp(size.Y.Scale * adornee.Size.Y, 0.5, 2.5)
end

--- Adornee on stand/pad (stable Size). Pin just above the egg Part top.
function WorldUi.pinBillboardAbove(
    bb: BillboardGui,
    stand: BasePart,
    heightBody: BasePart?,
    padStuds: number?
)
    local gap = padStuds or 0.4
    local body = heightBody or stand
    bb.Adornee = stand
    if bb.Parent ~= stand then
        bb.Parent = stand
    end
    local bbH = billboardHeightStuds(bb, stand)
    local eggTopY = body.Position.Y + body.Size.Y * 0.5
    local centerY = eggTopY + gap + bbH * 0.5
    bb.StudsOffset = Vector3.zero
    bb.StudsOffsetWorldSpace = Vector3.new(
        body.Position.X - stand.Position.X,
        centerY - stand.Position.Y,
        body.Position.Z - stand.Position.Z
    )
    bb.Enabled = true
end

local function attachBlockItemBillboard(
    adornee: BasePart,
    billboardName: string,
    withPrice: boolean
): (BillboardGui, ExhibitLabels)
    local existing = adornee:FindFirstChild(billboardName)
    if existing then
        existing:Destroy()
    end

    local template = findBlockItemTemplate()
    local bb: BillboardGui
    local labels: ExhibitLabels

    if template then
        local clone = template:Clone()
        clone.Name = billboardName
        clone.Adornee = adornee
        clone.Enabled = true
        prepareBillboard(clone)
        clone.Parent = adornee
        bb = clone
        local fromTemplate = labelsFromBillboard(clone, withPrice)
        if fromTemplate then
            labels = fromTemplate
        else
            error(`[WorldUi] {billboardName}: BlockItem template missing PetName/Rarity/Mutation`)
        end
    else
        -- Fallback if Studio template is missing (rare).
        bb = Instance.new("BillboardGui")
        bb.Name = billboardName
        bb.Adornee = adornee
        bb.Size = UDim2.fromScale(10, 4)
        bb.StudsOffset = Vector3.new(0, 4, 0)
        bb.Parent = adornee
        prepareBillboard(bb)

        local frame = Instance.new("Frame")
        frame.Name = "Frame"
        frame.Size = UDim2.fromScale(1, 1)
        frame.BackgroundTransparency = 1
        frame.Parent = bb
        local list = Instance.new("UIListLayout")
        list.FillDirection = Enum.FillDirection.Vertical
        list.HorizontalAlignment = Enum.HorizontalAlignment.Center
        list.VerticalAlignment = Enum.VerticalAlignment.Center
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Parent = frame

        local function plain(name: string, order: number, heightScale: number): TextLabel
            local l = Instance.new("TextLabel")
            l.Name = name
            l.BackgroundTransparency = 1
            l.Size = UDim2.new(1, 0, heightScale, 0)
            l.AnchorPoint = Vector2.new(0.5, 0)
            l.Position = UDim2.fromScale(0.5, 0)
            l.LayoutOrder = order
            l.Font = Font.title
            l.TextScaled = true
            l.TextColor3 = C.white
            l.TextXAlignment = Enum.TextXAlignment.Center
            l.Text = ""
            l.Parent = frame
            return l
        end

        labels = {
            rarity = plain("Rarity", 1, 0.22),
            petName = plain("PetName", 2, 0.3),
            mutation = plain("Mutation", 3, 0.22),
            price = if withPrice then plain("Price", 4, 0.26) else nil,
        }
        if labels.price then
            applySparkPriceStyle(labels.price)
        end
    end

    labels.petName.Text = ""
    labels.rarity.Text = ""
    labels.mutation.Text = ""
    labels.mutation.Visible = false
    if labels.price then
        labels.price.Text = ""
        labels.price.Visible = false
    end
    setMutationShimmer(labels.mutation, false)
    return bb, labels
end

function WorldUi.attachExhibitBillboard(adornee: BasePart): (BillboardGui, ExhibitLabels)
    return attachBlockItemBillboard(adornee, "ExhibitBillboard", false)
end

function WorldUi.setItemBillboard(
    labels: ExhibitLabels,
    props: {
        displayName: string,
        rarity: string,
        mutationText: string?,
        mutationIds: { string }?,
        mutationId: string?, -- legacy: single id; prefer mutationIds
        priceText: string?,
    }
)
    labels.petName.Text = props.displayName
    labels.rarity.Text = titleCase(props.rarity)
    setRarityGradient(labels.rarity, props.rarity)

    local mutText = props.mutationText or ""
    if mutText ~= "" then
        labels.mutation.Text = mutText
        labels.mutation.Visible = true
        local ids = props.mutationIds
        if (not ids or #ids == 0) and props.mutationId and props.mutationId ~= "" then
            ids = { props.mutationId }
        end
        setMutationGradientFromLabel(labels.mutation, mutText, ids)
        setMutationShimmer(labels.mutation, true)
    else
        labels.mutation.Text = ""
        labels.mutation.Visible = false
        disableAllGradients(labels.mutation)
        setMutationShimmer(labels.mutation, false)
    end

    if labels.price then
        local priceText = props.priceText
        if priceText and priceText ~= "" then
            labels.price.Text = priceText
            labels.price.Visible = true
            applySparkPriceStyle(labels.price)
        else
            labels.price.Text = ""
            labels.price.Visible = false
        end
    end
end

-- Back-compat alias used by exhibit renderer.
function WorldUi.setExhibitBillboard(
    labels: ExhibitLabels,
    props: {
        displayName: string,
        rarity: string,
        mutationText: string?,
        mutationIds: { string }?,
        mutationId: string?,
        -- ignored legacy fields (timer removed from BlockItem billboard)
        priceText: string?,
        timerText: string?,
        timerColor: Color3?,
        mutationColor: Color3?,
        accent: Color3?,
    }
)
    WorldUi.setItemBillboard(labels, {
        displayName = props.displayName,
        rarity = props.rarity,
        mutationText = props.mutationText,
        mutationIds = props.mutationIds,
        mutationId = props.mutationId,
        priceText = nil, -- exhibits: no buy price on billboard
    })
end

function WorldUi.attachOfferBillboard(adornee: BasePart): (BillboardGui, ExhibitLabels)
    return attachBlockItemBillboard(adornee, "OfferBillboard", true)
end

function WorldUi.attachBankBillboard(adornee: BasePart): (BillboardGui, TextLabel)
    local existing = adornee:FindFirstChild("FavoriteBankBillboard")
    if existing then
        existing:Destroy()
    end

    local bb = Instance.new("BillboardGui")
    bb.Name = "FavoriteBankBillboard"
    bb.Adornee = adornee
    bb.AlwaysOnTop = true
    bb.LightInfluence = 0
    bb.Size = UDim2.fromScale(5, 5)
    bb.StudsOffset = Vector3.new(0, 5, 0)
    bb.MaxDistance = 80
    bb.Parent = adornee

    -- No card background — BlockItem-style title + amount.
    local root = Instance.new("Frame")
    root.Name = "Frame"
    root.Size = UDim2.fromScale(1, 1)
    root.BackgroundTransparency = 1
    root.BorderSizePixel = 0
    root.Parent = bb

    local list = Instance.new("UIListLayout")
    list.FillDirection = Enum.FillDirection.Vertical
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center
    list.VerticalAlignment = Enum.VerticalAlignment.Center
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 2)
    list.Parent = root

    local title = Instance.new("TextLabel")
    title.Name = "TagName"
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0.42, 0)
    title.LayoutOrder = 1
    title.Font = Font.display
    title.TextScaled = true
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.Text = "Bank"
    title.Parent = root
    applyBillboardStroke(title)

    local amount = Instance.new("TextLabel")
    amount.Name = "Price"
    amount.BackgroundTransparency = 1
    amount.Size = UDim2.new(1, 0, 0.5, 0)
    amount.LayoutOrder = 2
    amount.Font = Font.display
    amount.TextScaled = true
    amount.TextColor3 = Color3.new(1, 1, 1)
    amount.TextXAlignment = Enum.TextXAlignment.Center
    amount.Text = "0"
    amount.Parent = root
    applySparkPriceStyle(amount)

    return bb, amount
end

export type GrowthLabels = {
    track: Frame,
    fill: Frame,
    timer: TextLabel,
}

function WorldUi.formatGrowTimer(sec: number): string
    local s = math.max(0, math.ceil(sec))
    local m = math.floor(s / 60)
    local r = s % 60
    return string.format("%d:%02d", m, r)
end

function WorldUi.attachGrowthBillboard(adornee: BasePart): (BillboardGui, GrowthLabels)
    local existing = adornee:FindFirstChild("GrowthBillboard")
    if existing then
        existing:Destroy()
    end

    local bb = Instance.new("BillboardGui")
    bb.Name = "GrowthBillboard"
    bb.Adornee = adornee
    bb.AlwaysOnTop = true
    bb.LightInfluence = 0
    bb.Size = UDim2.fromScale(4.5, 0.55)
    bb.StudsOffset = Vector3.new(0, 0.45, 0)
    bb.MaxDistance = 70
    bb.Enabled = false
    bb.Parent = adornee

    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Size = UDim2.fromScale(1, 1)
    track.BackgroundColor3 = C.progressTrack
    track.BackgroundTransparency = 0.15
    track.BorderSizePixel = 0
    track.ClipsDescendants = true
    track.Parent = bb
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(0.5, 0)
    trackCorner.Parent = track
    local trackStroke = Instance.new("UIStroke")
    trackStroke.Color = C.outlineDark
    trackStroke.Thickness = 1.5
    trackStroke.Transparency = 0.25
    trackStroke.Parent = track

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.fromScale(0, 1)
    fill.BackgroundColor3 = Color3.new(1, 1, 1)
    fill.BorderSizePixel = 0
    fill.Parent = track
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0.5, 0)
    fillCorner.Parent = fill
    local spark = Instance.new("UIGradient")
    spark.Name = "SparkGradient"
    spark.Color = SPARK_GRADIENT
    spark.Rotation = 0
    spark.Parent = fill

    local timer = Instance.new("TextLabel")
    timer.Name = "Timer"
    timer.BackgroundTransparency = 1
    timer.Size = UDim2.fromScale(1, 1)
    timer.Font = Font.title
    timer.TextScaled = true
    timer.TextColor3 = C.white
    timer.TextStrokeTransparency = 0.4
    timer.TextStrokeColor3 = C.outlineDark
    timer.TextXAlignment = Enum.TextXAlignment.Center
    timer.TextYAlignment = Enum.TextYAlignment.Center
    timer.Text = "0:00"
    timer.ZIndex = 2
    timer.Parent = track

    return bb, {
        track = track,
        fill = fill,
        timer = timer,
    }
end

function WorldUi.pinGrowthBillboard(bb: BillboardGui, stand: BasePart)
    bb.Adornee = stand
    if bb.Parent ~= stand then
        bb.Parent = stand
    end
    -- Bottom of stand pedestal (under the egg).
    bb.StudsOffset = Vector3.new(0, 2, 0)
end

function WorldUi.setGrowthBillboard(
    labels: GrowthLabels,
    props: {
        progress: number,
        remainingSec: number,
        visible: boolean,
    }
)
    local bb = labels.track.Parent
    if bb and bb:IsA("BillboardGui") then
        bb.Enabled = props.visible
    end
    if not props.visible then
        return
    end
    local p = math.clamp(props.progress, 0, 1)
    labels.fill.Size = UDim2.fromScale(p, 1)
    labels.timer.Text = WorldUi.formatGrowTimer(props.remainingSec)
end

return WorldUi
