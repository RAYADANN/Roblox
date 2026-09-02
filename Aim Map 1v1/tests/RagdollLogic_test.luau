local RagdollLogic = require("@shared/util/RagdollLogic")

return {
    ["knockVelocity: forward shot pushes forward + up"] = function(expect)
        local x, y, z = RagdollLogic.knockVelocity(0, 0, -1, 40, 12)
        expect(x).toBeCloseTo(0, 5)
        expect(y).toBeCloseTo(12, 5)
        expect(z).toBeCloseTo(-40, 5)
    end,
    ["knockVelocity: zero dir falls back to upBias"] = function(expect)
        local x, y, z = RagdollLogic.knockVelocity(0, 0, 0, 40, 12)
        expect(x).toEqual(0)
        expect(y).toEqual(12)
        expect(z).toEqual(0)
    end,
    ["knockVelocity: normalizes diagonal"] = function(expect)
        local x, y, z = RagdollLogic.knockVelocity(3, 0, 4, 50, 0)
        local mag = math.sqrt(x * x + y * y + z * z)
        expect(mag).toBeCloseTo(50, 4)
    end,
}
