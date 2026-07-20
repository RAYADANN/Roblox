return {
	["encode empty"] = function(expect)
		local Sync = require("@shared/util/PlayerAttributeSync")
		expect(Sync.encode({})).toEqual("[]")
	end,
	["roundtrip slots"] = function(expect)
		local Sync = require("@shared/util/PlayerAttributeSync")
		local slots = { { id = "pet_a" }, { id = "pet_b" } }
		local raw = Sync.encode(slots)
		local decoded = Sync.decode(raw)
		expect(#decoded).toEqual(2)
		expect(decoded[1].id).toEqual("pet_a")
		expect(decoded[2].id).toEqual("pet_b")
	end,
	["decode missing"] = function(expect)
		local Sync = require("@shared/util/PlayerAttributeSync")
		expect(#Sync.decode(nil)).toEqual(0)
		expect(#Sync.decode("[]")).toEqual(0)
	end,
}
