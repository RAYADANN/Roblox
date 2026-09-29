--!strict
-- Upgrade pad billboard: Rebirth-style ProgressLine (summon have/need).

local IconCatalog = require(game:GetService("ReplicatedStorage").shared.data.IconCatalog)

-- Matches client theme.Colors.progressTrack / RebirthPanel mask.
local PROGRESS_TRACK = Color3.fromRGB(40, 44, 48)
local PROGRESS_CORNER = 0.16
local HINT_TEXT = "Buy Dummies"

local PadSummonProgress = {}

local function fillMaskKeypoints(progressFill: number): { NumberSequenceKeypoint }
    if progressFill <= 0 then
        return {
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 1),
        }
    elseif progressFill >= 1 then
        return {
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 0),
        }
    end
    local edge = math.clamp(progressFill, 0.001, 0.999)
    return {
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(edge, 0),
        NumberSequenceKeypoint.new(math.min(edge + 0.002, 1), 1),
        NumberSequenceKeypoint.new(1, 1),
    }
end

local function findBillboardRoot(model: Instance): Frame?
    for _, inst in model:GetDescendants() do
        if inst:IsA("BillboardGui") then
            local frame = inst:FindFirstChild("Frame")
            if frame and frame:IsA("Frame") then
                return frame
            end
        end
    end
    return nil
end

local function findPriceLabel(model: Instance): TextLabel?
    for _, inst in model:GetDescendants() do
        if inst:IsA("TextLabel") and inst.Name == "Price" then
            return inst
        end
    end
    return nil
end

local function ensureHint(root: Frame): TextLabel
    local hint = root:FindFirstChild("SummonHint")
    if hint and hint:IsA("TextLabel") then
        return hint
    end
    if hint then
        hint:Destroy()
    end

    local created = Instance.new("TextLabel")
    created.Name = "SummonHint"
    created.BackgroundTransparency = 1
    created.BorderSizePixel = 0
    created.Size = UDim2.fromScale(1, 0.22)
    created.LayoutOrder = 2
    created.Font = Enum.Font.FredokaOne
    created.TextScaled = true
    created.TextColor3 = Color3.new(1, 1, 1)
    created.Text = HINT_TEXT
    created.TextXAlignment = Enum.TextXAlignment.Center
    created.TextYAlignment = Enum.TextYAlignment.Bottom
    created.Parent = root

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(0, 0, 0)
    stroke.Thickness = 0.12
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    stroke.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
    stroke.Parent = created

    return created
end

local function ensureSummonProgress(root: Frame): (Frame, ImageLabel, UIGradient, TextLabel)
    local track = root:FindFirstChild("SummonProgress")
    if track and track:IsA("Frame") then
        local fill = track:FindFirstChild("Fill")
        local amount = track:FindFirstChild("Amount")
        if fill and fill:IsA("ImageLabel") and amount and amount:IsA("TextLabel") then
            local mask = fill:FindFirstChildOfClass("UIGradient")
            if mask == nil then
                mask = Instance.new("UIGradient")
                mask.Parent = fill
            end
            track.LayoutOrder = 3
            track.Size = UDim2.fromScale(1, 0.34)
            return track, fill, mask, amount
        end
        track:Destroy()
    end

    local created = Instance.new("Frame")
    created.Name = "SummonProgress"
    created.BackgroundColor3 = PROGRESS_TRACK
    created.BorderSizePixel = 0
    created.Size = UDim2.fromScale(1, 0.34)
    created.LayoutOrder = 3
    created.ClipsDescendants = false
    created.Parent = root

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(PROGRESS_CORNER, 0)
    corner.Parent = created

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(0, 0, 0)
    stroke.Thickness = 2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = created

    local fill = Instance.new("ImageLabel")
    fill.Name = "Fill"
    fill.BackgroundTransparency = 1
    fill.BorderSizePixel = 0
    fill.Size = UDim2.fromScale(1, 1)
    fill.Image = IconCatalog.ProgressLine
    fill.ScaleType = Enum.ScaleType.Stretch
    fill.ZIndex = 1
    fill.Parent = created

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(PROGRESS_CORNER, 0)
    fillCorner.Parent = fill

    local mask = Instance.new("UIGradient")
    mask.Rotation = 0
    mask.Parent = fill

    local amount = Instance.new("TextLabel")
    amount.Name = "Amount"
    amount.BackgroundTransparency = 1
    amount.Size = UDim2.fromScale(1, 0.85)
    amount.Position = UDim2.fromScale(0.5, 0.5)
    amount.AnchorPoint = Vector2.new(0.5, 0.5)
    amount.Font = Enum.Font.FredokaOne
    amount.TextScaled = true
    amount.TextColor3 = Color3.new(1, 1, 1)
    amount.ZIndex = 3
    amount.Parent = created

    local amountStroke = Instance.new("UIStroke")
    amountStroke.Color = Color3.new(0, 0, 0)
    amountStroke.Thickness = 0.12
    amountStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    amountStroke.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
    amountStroke.Parent = amount

    return created, fill, mask, amount
end

function PadSummonProgress.apply(
    model: Instance?,
    fraction: number,
    label: string,
    visible: boolean?
)
    if model == nil then
        return
    end
    local root = findBillboardRoot(model)
    if root == nil then
        return
    end
    local show = visible ~= false
    local hint = ensureHint(root)
    local track, fill, mask, amount = ensureSummonProgress(root)
    hint.Visible = show
    track.Visible = show
    if not show then
        return
    end

    local price = findPriceLabel(model)
    if price then
        price.Visible = false
        local row = price.Parent
        if row and row:IsA("Frame") and row.Name == "PriceRow" then
            row.Visible = false
        end
    end

    local tag = root:FindFirstChild("TagName")
    if tag and tag:IsA("TextLabel") then
        tag.Size = UDim2.fromScale(1, 0.38)
        tag.LayoutOrder = 1
    end

    hint.Text = HINT_TEXT
    fill.Image = IconCatalog.ProgressLine
    mask.Transparency = NumberSequence.new(fillMaskKeypoints(math.clamp(fraction, 0, 1)))
    amount.Text = label
end

return PadSummonProgress
