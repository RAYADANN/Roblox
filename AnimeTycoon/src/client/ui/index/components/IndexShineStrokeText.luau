--!strict
-- Mutation / rarity labels on Index cards: ColorSheen (Prismatic = legacy V3).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local MutationShineDatabase =
    require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("data").MutationShineDatabase)
local RarityShineDatabase =
    require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("data").RarityShineDatabase)

local ShineGradients = require(script.Parent.Parent.ShineGradients)
local StrokeText = require(script.Parent.Parent.Parent.shop.components.StrokeText)
local tokens = require(script.Parent.Parent.tokens)

export type ShineKind = "mutation" | "rarity"

export type Props = {
    text: string,
    shineKind: ShineKind,
    shineKey: string,
    size: UDim2?,
    position: UDim2?,
    anchorPoint: Vector2?,
    zIndex: number?,
    strokeThickness: number?,
}

local function resolveColorSheenApply(): any
    local underClient = script.Parent.Parent.Parent.Parent
    if underClient then
        local core = underClient:FindFirstChild("core")
        local mod = core and core:FindFirstChild("ColorSheenApply")
        if mod and mod:IsA("ModuleScript") then
            local ok, apply = pcall(require, mod)
            if ok then
                return apply
            end
        end
    end
    local sps = StarterPlayer:FindFirstChild("StarterPlayerScripts")
    local client = sps and sps:FindFirstChild("client")
    local core = client and client:FindFirstChild("core")
    local mod = core and core:FindFirstChild("ColorSheenApply")
    if mod and mod:IsA("ModuleScript") then
        return require(mod)
    end
    error("[IndexShineStrokeText] ColorSheenApply missing")
end

local ColorSheenApply = resolveColorSheenApply()

local function rgb(c: { r: number, g: number, b: number }): Color3
    return Color3.fromRGB(c.r, c.g, c.b)
end

local function resolveMutation(key: string): MutationShineDatabase.MutationShineDef?
    return MutationShineDatabase.resolveFromLabel(key) or MutationShineDatabase.get(key)
end

local function resolveRarity(key: string): RarityShineDatabase.RarityShineDef?
    return RarityShineDatabase.resolve(key)
end

local clocks: { [string]: number } = {}

local function IndexShineStrokeText(props: Props): React.Node
    local gradientRef = React.useRef(nil :: UIGradient?)
    local labelRef = React.useRef(nil :: TextLabel?)
    local kind = props.shineKind
    local key = props.shineKey

    local gradient = if kind == "mutation"
        then ShineGradients.forMutation(key)
        else ShineGradients.forRarity(key)

    local strokeColor: Color3? = nil
    if kind == "mutation" then
        local def = resolveMutation(key)
        if def then
            strokeColor = rgb(def.stroke)
        end
    else
        local def = resolveRarity(key)
        if def then
            strokeColor = rgb(def.stroke)
        end
    end

    React.useEffect(function()
        local mutDef = if kind == "mutation" then resolveMutation(key) else nil
        local rarDef = if kind == "rarity" then resolveRarity(key) else nil
        local defId = if mutDef then mutDef.id elseif rarDef then rarDef.id else nil
        if defId == nil then
            return nil
        end

        local clockKey = `{kind}:{defId}`
        if clocks[clockKey] == nil then
            clocks[clockKey] = os.clock()
        end
        local t0 = clocks[clockKey]

        local function tick(t: number)
            local grad = gradientRef.current
            local label = labelRef.current
            if grad == nil or label == nil then
                return
            end
            if mutDef then
                local legacy = mutDef.legacyMutationV
                local pose = if typeof(legacy) == "number" and legacy > 0
                    then ColorSheenApply.poseLegacyMutation(legacy, t, mutDef.baseRotation)
                    else ColorSheenApply.poseColorSheen(
                        mutDef.variant,
                        t,
                        mutDef.baseRotation,
                        mutDef.keys
                    )
                ColorSheenApply.applyPose(label, grad, pose, mutDef.keys)
            elseif rarDef then
                local pose = ColorSheenApply.poseColorSheen(
                    rarDef.variant,
                    t,
                    rarDef.baseRotation,
                    rarDef.keys
                )
                ColorSheenApply.applyPose(label, grad, pose, rarDef.keys)
            end
        end

        local animated = false
        if mutDef then
            local legacy = mutDef.legacyMutationV
            animated = (typeof(legacy) == "number" and legacy > 0) or mutDef.variant > 0
        elseif rarDef then
            animated = rarDef.variant > 0
        end

        if not animated then
            tick(0)
            return nil
        end

        local conn = RunService.Heartbeat:Connect(function()
            tick(os.clock() - t0)
        end)
        return function()
            conn:Disconnect()
        end
    end, { kind, key } :: { unknown })

    return React.createElement(StrokeText, {
        text = props.text,
        strokeThickness = props.strokeThickness or tokens.strokeText,
        strokeColor = strokeColor,
        size = props.size,
        position = props.position,
        anchorPoint = props.anchorPoint,
        zIndex = props.zIndex,
        gradient = gradient,
        labelRef = function(rbx: TextLabel?)
            labelRef.current = rbx
        end,
        gradientRef = function(rbx: UIGradient?)
            gradientRef.current = rbx
        end,
    })
end

return IndexShineStrokeText
