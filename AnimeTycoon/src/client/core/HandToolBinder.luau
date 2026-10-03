--!strict
-- Native Backpack Tools for inventory containers + sell crates.
-- Equip → right-hand visual; SetHand so Place uses the selected container.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local BoxModel = require(script.Parent.BoxModel)
local HeroModel = require(script.Parent.HeroModel)

local HAND_HEIGHT = 1.6
local ATTR_UID = "HandUid"
local ATTR_KIND = "HandKind"

export type InvItem = {
    uid: string,
    displayName: string?,
    boxModelName: string?,
    heroId: string?,
    templateId: string?,
    unpacked: boolean?,
    mutations: { string }?,
    mutationLabel: string?,
}

export type SellCrateItem = {
    uid: string,
    coins: number?,
}

local HandToolBinder = {}

local _player = Players.LocalPlayer
local _tools: { [string]: Tool } = {}
local _syncing = false
local _lastHandUid = ""
local _setHand: ((string) -> ())? = nil
local _started = false

local function decodeArray(json: string): { any }
    if json == "" then
        return {}
    end
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(json)
    end)
    if ok and typeof(decoded) == "table" then
        return decoded :: { any }
    end
    return {}
end

local function weldVisualToHandle(tool: Tool, handle: BasePart, visual: Model)
    for _, d in visual:GetDescendants() do
        if d:IsA("BasePart") then
            d.Anchored = false
            d.CanCollide = false
            d.CanQuery = false
            d.CanTouch = false
            d.Massless = true
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = handle
            weld.Part1 = d
            weld.Parent = handle
        end
    end
    visual.Parent = tool
end

local function attachModel(tool: Tool, handle: BasePart, model: Model)
    -- Sit model slightly forward of the grip so it reads in-hand.
    model:PivotTo(handle.CFrame * CFrame.new(0, 0, -0.9) * CFrame.Angles(0, math.rad(90), 0))
    weldVisualToHandle(tool, handle, model)
end

local function makeHandle(tool: Tool): BasePart
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.2, 0.2, 0.2)
    handle.Transparency = 1
    handle.CanCollide = false
    handle.CanQuery = false
    handle.CanTouch = false
    handle.Massless = true
    handle.Parent = tool
    return handle
end

local function makeSellCrateModel(): Model
    local model = Instance.new("Model")
    model.Name = "SellCrateVisual"
    local part = Instance.new("Part")
    part.Name = "Box"
    part.Size = Vector3.new(1.2, 1.2, 1.2)
    part.Color = Color3.fromRGB(255, 200, 60)
    part.Material = Enum.Material.Neon
    part.Anchored = true
    part.CanCollide = false
    part.Parent = model
    model.PrimaryPart = part
    return model
end

local function buildContainerVisual(item: InvItem): Model?
    if item.unpacked == true and typeof(item.heroId) == "string" and item.heroId ~= "" then
        local hero = HeroModel.clone(item.heroId, nil, {
            mutations = item.mutations,
            mutationLabel = item.mutationLabel,
            templateId = item.templateId,
            targetHeight = HAND_HEIGHT,
            maxExtent = HAND_HEIGHT * 1.4,
        })
        return hero
    end
    local boxName = item.boxModelName or ""
    local box = BoxModel.clone(boxName, {
        mutations = item.mutations,
        mutationLabel = item.mutationLabel,
    })
    if box then
        HeroModel.normalizeSize(box, HAND_HEIGHT, HAND_HEIGHT * 1.4)
    end
    return box
end

local function destroyTool(uid: string)
    local tool = _tools[uid]
    if tool then
        tool:Destroy()
        _tools[uid] = nil
    end
end

local function backpack(): Backpack?
    local bp = _player:FindFirstChildOfClass("Backpack")
    return bp
end

local function character(): Model?
    return _player.Character
end

local function equippedTool(): Tool?
    local char = character()
    if not char then
        return nil
    end
    local t = char:FindFirstChildOfClass("Tool")
    if t and t:IsA("Tool") then
        return t
    end
    return nil
end

local function fireSetHand(uid: string)
    local fn = _setHand
    if fn then
        fn(uid)
    end
end

local function wireTool(tool: Tool, uid: string, kind: string)
    tool:SetAttribute(ATTR_UID, uid)
    tool:SetAttribute(ATTR_KIND, kind)
    tool.Equipped:Connect(function()
        if _syncing then
            return
        end
        if kind == "sell_crate" then
            fireSetHand("")
            return
        end
        fireSetHand(uid)
    end)
    tool.Unequipped:Connect(function()
        if _syncing then
            return
        end
        task.defer(function()
            if _syncing then
                return
            end
            local eq = equippedTool()
            if eq ~= nil then
                return
            end
            fireSetHand("")
        end)
    end)
end

local function createContainerTool(item: InvItem): Tool?
    local uid = item.uid
    if typeof(uid) ~= "string" or uid == "" then
        return nil
    end
    local tool = Instance.new("Tool")
    tool.Name = if typeof(item.displayName) == "string" and item.displayName ~= ""
        then item.displayName
        else "Container"
    tool.ToolTip = tool.Name
    tool.CanBeDropped = false
    tool.RequiresHandle = true
    local handle = makeHandle(tool)
    local visual = buildContainerVisual(item)
    if visual then
        attachModel(tool, handle, visual)
    end
    wireTool(tool, uid, "container")
    return tool
end

local function createSellCrateTool(crate: SellCrateItem): Tool?
    local uid = crate.uid
    if typeof(uid) ~= "string" or uid == "" then
        return nil
    end
    local coins = math.floor(tonumber(crate.coins) or 0)
    local tool = Instance.new("Tool")
    tool.Name = if coins > 0 then `Sell Box (${coins})` else "Sell Box"
    tool.ToolTip = tool.Name
    tool.CanBeDropped = false
    tool.RequiresHandle = true
    local handle = makeHandle(tool)
    attachModel(tool, handle, makeSellCrateModel())
    wireTool(tool, uid, "sell_crate")
    return tool
end

local function parentTool(tool: Tool)
    local bp = backpack()
    if bp then
        tool.Parent = bp
    else
        tool.Parent = _player
    end
end

local function equipUid(uid: string)
    if uid == "" then
        local humanoid = character() and character():FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:UnequipTools()
        end
        return
    end
    local tool = _tools[uid]
    if not tool then
        return
    end
    local eq = equippedTool()
    if eq == tool then
        return
    end
    local humanoid = character() and character():FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:EquipTool(tool)
    end
end

function HandToolBinder.apply(inventoryJson: string, sellCratesJson: string, handUid: string)
    local invRaw = decodeArray(inventoryJson)
    local crateRaw = decodeArray(sellCratesJson)
    local want: { [string]: true } = {}

    for _, raw in invRaw do
        if typeof(raw) == "table" then
            local item = raw :: InvItem
            local uid = item.uid
            if typeof(uid) == "string" and uid ~= "" then
                want[uid] = true
                if not _tools[uid] then
                    local tool = createContainerTool(item)
                    if tool then
                        _tools[uid] = tool
                        parentTool(tool)
                    end
                end
            end
        end
    end

    for _, raw in crateRaw do
        if typeof(raw) == "table" then
            local crate = raw :: SellCrateItem
            local uid = crate.uid
            if typeof(uid) == "string" and uid ~= "" then
                want[uid] = true
                if not _tools[uid] then
                    local tool = createSellCrateTool(crate)
                    if tool then
                        _tools[uid] = tool
                        parentTool(tool)
                    end
                else
                    -- Refresh label if coins changed.
                    local coins = math.floor(tonumber(crate.coins) or 0)
                    local tool = _tools[uid]
                    if tool then
                        tool.Name = if coins > 0 then `Sell Box (${coins})` else "Sell Box"
                        tool.ToolTip = tool.Name
                    end
                end
            end
        end
    end

    for uid in _tools do
        if not want[uid] then
            destroyTool(uid)
        end
    end

    _syncing = true
    local target = handUid or ""
    if target ~= _lastHandUid then
        _lastHandUid = target
        equipUid(target)
    elseif target ~= "" then
        -- Keep equipped if server still wants this hand.
        local eq = equippedTool()
        local attr = if eq then eq:GetAttribute(ATTR_UID) else nil
        if attr ~= target then
            equipUid(target)
        end
    end
    task.defer(function()
        _syncing = false
    end)
end

function HandToolBinder.setSetHandHandler(handler: (string) -> ())
    _setHand = handler
end

function HandToolBinder.start()
    if _started then
        return
    end
    _started = true
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
    end)

    local function onCharacter(char: Model)
        -- Re-parent tools into new backpack after respawn.
        task.defer(function()
            for _, tool in _tools do
                if tool.Parent ~= char then
                    parentTool(tool)
                end
            end
            if _lastHandUid ~= "" then
                _syncing = true
                equipUid(_lastHandUid)
                task.defer(function()
                    _syncing = false
                end)
            end
        end)
    end

    if _player.Character then
        onCharacter(_player.Character)
    end
    _player.CharacterAdded:Connect(onCharacter)
end

return HandToolBinder
