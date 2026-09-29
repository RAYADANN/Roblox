--!strict
-- Санитизация Workspace вокруг шахты: маркер зоны, площадки у входа, exclude для лучей.

local Constants = require(script.Parent.Parent.constants)

local MineZoneWorkspace = {}

export type SanitizeResult = {
	raycastExcludes: { Instance },
	deckParts: { BasePart },
}

local RAYCAST_EXCLUDE_NAMES = { "MineZoneMarker", "DeepDigger_TutorialPath", "MineRespawn" }
-- Union/пол — тонкий горизонтальный коллайдер. Столбы забора и декор выше — не deck.
local MAX_DECK_THICKNESS = Constants.BLOCK_SIZE_STUDS + 0.5

local function overlapsVolumeXZ(part: BasePart, volume: BasePart): boolean
	local volCF = volume.CFrame
	local vHalf = volume.Size / 2
	local rel = volCF:PointToObjectSpace(part.Position)
	local pHalf = part.Size / 2
	return math.abs(rel.X) <= vHalf.X + pHalf.X
		and math.abs(rel.Z) <= vHalf.Z + pHalf.Z
end

local function nearSurfaceBand(part: BasePart, volume: BasePart): boolean
	local topY = volume.Position.Y + volume.Size.Y / 2
	local partBottom = part.Position.Y - part.Size.Y / 2
	local partTop = part.Position.Y + part.Size.Y / 2
	return partBottom <= topY + 2 and partTop >= topY - 8
end

local function isExcludedAncestor(part: BasePart, volume: BasePart, mineFolder: Instance?): boolean
	if mineFolder and part:IsDescendantOf(mineFolder) then
		return true
	end
	local marker = volume.Parent
	if marker and part:IsDescendantOf(marker) then
		return true
	end
	return false
end

local function isMineEntrancePlatform(part: BasePart, volume: BasePart, mineFolder: Instance?): boolean
	if isExcludedAncestor(part, volume, mineFolder) then
		return false
	end
	if not part:IsA("BasePart") or part:IsA("Terrain") then
		return false
	end
	-- Не помечать гигантские части (Terrain/Union) по «центр ± size/2» — только реальное
	-- пересечение с коробкой зоны и горизонтальный пол.
	if part.Size.Y > MAX_DECK_THICKNESS then
		return false
	end
	if not overlapsVolumeXZ(part, volume) then
		return false
	end
	return nearSurfaceBand(part, volume)
end

-- Декор у периметра (забор, столбы): не deck, но луч прицела их не должен ловить.
local function isMineRayOccluder(part: BasePart, volume: BasePart, mineFolder: Instance?): boolean
	if isExcludedAncestor(part, volume, mineFolder) then
		return false
	end
	if not part:IsA("BasePart") or part:IsA("Terrain") then
		return false
	end
	if not overlapsVolumeXZ(part, volume) then
		return false
	end
	return nearSurfaceBand(part, volume)
end

function MineZoneWorkspace.sanitize(ws: Workspace): SanitizeResult
	local raycastExcludes: { Instance } = {}
	local deckParts: { BasePart } = {}

	for _, name in RAYCAST_EXCLUDE_NAMES do
		local inst = ws:FindFirstChild(name)
		if inst then
			table.insert(raycastExcludes, inst)
		end
	end

	local marker = ws:FindFirstChild("MineZoneMarker")
	if not marker then
		return { raycastExcludes = raycastExcludes, deckParts = deckParts }
	end

	local volume = marker:FindFirstChild("Volume")
	if not volume or not volume:IsA("BasePart") then
		return { raycastExcludes = raycastExcludes, deckParts = deckParts }
	end

	for _, desc in marker:GetDescendants() do
		if desc:IsA("BasePart") then
			desc.CanQuery = false
			desc.CanCollide = false
		end
	end

	local respawn = ws:FindFirstChild("MineRespawn")
	if respawn and respawn:IsA("BasePart") then
		respawn.CanQuery = false
	end

	local mineFolder = ws:FindFirstChild("DeepDigger_Mine")
	local seenDeck: { [BasePart]: boolean } = {}
	local seenOccluder: { [BasePart]: boolean } = {}

	for _, inst in ws:GetDescendants() do
		if not inst:IsA("BasePart") then
			continue
		end
		local part = inst :: BasePart

		if isMineEntrancePlatform(part, volume, mineFolder) and not seenDeck[part] then
			seenDeck[part] = true
			part.CanQuery = false
			-- Коллайдер обязателен: иначе провал под весь Union/пол.
			-- Проход в прокопанную ячейку — через MineDeckCollision (PASS_GROUP).
			part.CanCollide = true
			table.insert(deckParts, part)
			table.insert(raycastExcludes, inst)
			continue
		end

		if isMineRayOccluder(part, volume, mineFolder) and not seenOccluder[part] then
			seenOccluder[part] = true
			part.CanQuery = false
			part.CanCollide = true
			table.insert(deckParts, part)
			table.insert(raycastExcludes, inst)
		end
	end

	return { raycastExcludes = raycastExcludes, deckParts = deckParts }
end

function MineZoneWorkspace.columnInSurfaceGrid(gx: number, gz: number): boolean
	local hw = math.floor(Constants.SURFACE_W / 2)
	local hd = math.floor(Constants.SURFACE_D / 2)
	return gx >= -hw and gx <= hw and gz >= -hd and gz <= hd
end

return MineZoneWorkspace
