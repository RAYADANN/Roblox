--!strict
-- Сериализация экипированных питомцев для Player-атрибута (репликация другим клиентам).

local HttpService = game:GetService("HttpService")

local PetEquippedSync = {}

PetEquippedSync.ATTRIBUTE = "DD_EquippedPets"

export type Slot = { uid: string, petId: string }

function PetEquippedSync.encode(slots: { Slot }): string
	local payload: { { uid: string, petId: string } } = {}
	for _, slot in ipairs(slots) do
		if typeof(slot.uid) == "string" and slot.uid ~= ""
			and typeof(slot.petId) == "string" and slot.petId ~= ""
		then
			table.insert(payload, { uid = slot.uid, petId = slot.petId })
		end
	end
	return HttpService:JSONEncode(payload)
end

function PetEquippedSync.decode(raw: any): { Slot }
	if typeof(raw) ~= "string" or raw == "" then
		return {}
	end
	local ok, parsed = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if not ok or typeof(parsed) ~= "table" then
		return {}
	end
	local result: { Slot } = {}
	for _, item in ipairs(parsed) do
		if typeof(item) == "table" and typeof(item.uid) == "string" and typeof(item.petId) == "string" then
			table.insert(result, { uid = item.uid, petId = item.petId })
		end
	end
	return result
end

return PetEquippedSync
