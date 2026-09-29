--!strict
-- Единая логика слоёв и глубины (клиент + сервер).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage:WaitForChild("shared").constants)

export type LayerDef = typeof(Constants.LAYERS[1])

local LayerUtil = {}

function LayerUtil.depthFromY(y: number): number
    return math.max(0, math.floor(-y / Constants.BLOCK_SIZE_STUDS))
end

function LayerUtil.getLayer(layerId: string): LayerDef?
    for _, layer in ipairs(Constants.LAYERS) do
        if layer.id == layerId then
            return layer
        end
    end
    return nil
end

function LayerUtil.layerFromDepth(depth: number): LayerDef
    for _, layer in ipairs(Constants.LAYERS) do
        if depth >= layer.depthStart and depth <= layer.depthEnd then
            return layer
        end
    end
    return Constants.LAYERS[#Constants.LAYERS]
end

function LayerUtil.layerIdFromDepth(depth: number): string
    return LayerUtil.layerFromDepth(depth).id
end

function LayerUtil.minPickaxeLevel(layerId: string): number
	local map = Constants.LAYER_PICKAXE_MIN_LEVEL
	local minLevel = map and map[layerId :: any]
	if typeof(minLevel) == "number" then
		return math.max(1, math.floor(minLevel))
	end
	return 1
end

function LayerUtil.isPickaxeTooWeak(pickaxeLevel: number, layerId: string): boolean
	return math.max(1, pickaxeLevel) < LayerUtil.minPickaxeLevel(layerId)
end

-- HP блока с учётом слоя и глубины внутри слоя (единый источник для сервера).
function LayerUtil.scaledBlockHp(baseHp: number, layerId: string, depth: number): number
	local multMap = Constants.LAYER_HP_MULTIPLIER
	local layerMult = if multMap then (multMap[layerId :: any] or 1) else 1
	local layer = LayerUtil.getLayer(layerId)
	local depthInLayer = if layer then math.max(0, depth - layer.depthStart) else 0
	local depthBonus = 1 + depthInLayer * (Constants.DEPTH_HP_BONUS_PER_LAYER_BLOCK or 0)
	local hp = baseHp * layerMult * depthBonus
	return math.max(1, math.floor(hp + 0.5))
end

function LayerUtil.colorToPayload(color: Color3): { r: number, g: number, b: number }
    return {
        r = math.floor(color.R * 255 + 0.5),
        g = math.floor(color.G * 255 + 0.5),
        b = math.floor(color.B * 255 + 0.5),
    }
end

return LayerUtil
