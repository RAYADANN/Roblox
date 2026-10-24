--!strict
-- Поза великана: дыхание живота, взмах правой руки, подъём торса, веки (GDD 4.1, 4.3).
-- Все детали Anchored; позу задаёт сервер через PivotTo подмоделей, чтобы живот и кисть были физически точны.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GiantConfig = require(ReplicatedStorage.shared.data.GiantConfig)
local Logger = require(ReplicatedStorage.shared.util.Logger)

local UPPER = { "Head", "Torso", "Beard", "Belly", "ArmL", "ArmR", "Lids", "Gaze" }
local LID_LIFT = 1.2

local GiantRig = {}
GiantRig.__index = GiantRig

function GiantRig.new(model: Model)
    local subs: { [string]: Model } = {}
    local rest: { [string]: CFrame } = {}
    for _, child in model:GetChildren() do
        if child:IsA("Model") then
            subs[child.Name] = child
            rest[child.Name] = child:GetPivot()
        end
    end
    for _, name in { "Head", "Torso", "ArmR", "Belly", "Lids" } do
        if not subs[name] then
            Logger.warn("GiantRig", `нет подмодели Giant.{name}`)
        end
    end
    local lidParts: { [string]: { part: BasePart, rel: CFrame } } = {}
    if subs.Lids then
        for _, name in { "LidL", "LidR" } do
            local part = subs.Lids:FindFirstChild(name, true)
            if part and part:IsA("BasePart") then
                lidParts[name] = { part = part, rel = rest.Lids:ToObjectSpace(part.CFrame) }
            end
        end
    end
    -- Веер взгляда и радужки: видимы только в Eye Open / WAKE.
    local fan: { { part: BasePart, visible: number } } = {}
    if subs.Gaze then
        for _, part in subs.Gaze:GetDescendants() do
            if part:IsA("BasePart") and string.sub(part.Name, 1, 3) == "Fan" then
                local visible = part:GetAttribute("VisibleTransparency")
                table.insert(
                    fan,
                    { part = part, visible = if typeof(visible) == "number" then visible else 0.75 }
                )
                part.Transparency = 1
            end
        end
    end
    local function findPart(root: Instance?, name: string): BasePart?
        local found = root and root:FindFirstChild(name, true)
        return if found and found:IsA("BasePart") then found else nil
    end
    local hipPos = if rest.Torso then rest.Torso.Position else model:GetPivot().Position
    local shoulderPos = if rest.ArmR then rest.ArmR.Position else hipPos
    return setmetatable({
        model = model,
        _subs = subs,
        _rest = rest,
        _lidParts = lidParts,
        _fan = fan,
        _gazeOrigin = findPart(subs.Gaze, "GazeOrigin"),
        _irisL = findPart(subs.Head, "EyeL_Iris"),
        _irisR = findPart(subs.Head, "EyeR_Iris"),
        _eyeL = findPart(subs.Head, "EyeL"),
        _gazeShown = false,
        _hip = hipPos,
        _shoulder = shoulderPos,
        _t = 0,
        -- Управляемые параметры позы
        riseDeg = 0,
        armYaw = nil :: number?,
        armLift = 0,
        lidL = 0,
        lidR = 0,
        gazeYaw = 0,
        gazeVisible = false,
        shake = 0,
        stir = 0,
    }, GiantRig)
end

-- Покой правой руки смотрит на юг (+Z): yaw 90° в отсчёте от +X к +Z.
GiantRig.ARM_REST_YAW = 90

function GiantRig:shoulder(): Vector3
    return self._shoulder
end

function GiantRig:hand(): BasePart?
    local arm = self._subs.ArmR
    local hand = arm and arm:FindFirstChild("Hand", true)
    return if hand and hand:IsA("BasePart") then hand else nil
end

function GiantRig:eyePosition(): Vector3
    if self._eyeL then
        return self._eyeL.Position + Vector3.new(0, 1, 0)
    end
    if self._gazeOrigin then
        return self._gazeOrigin.Position
    end
    local head = self._subs.Head
    return if head
        then head:GetPivot().Position + Vector3.new(0, 10, 0)
        else self.model:GetPivot().Position
end

function GiantRig:_applyEyes()
    local shown = self.gazeVisible
    if shown ~= self._gazeShown then
        self._gazeShown = shown
        for _, entry in self._fan do
            entry.part.Transparency = if shown then entry.visible else 1
        end
        local light = self._gazeOrigin and self._gazeOrigin:FindFirstChildOfClass("SpotLight")
        if light then
            light.Enabled = shown
        end
    end
    if self._irisL then
        self._irisL.Transparency = if self.lidL > 0.5 then 0 else 1
    end
    if self._irisR then
        self._irisR.Transparency = if self.lidR > 0.5 then 0 else 1
    end
end

function GiantRig:step(dt: number)
    self._t += dt
    local phi = math.rad(self.riseDeg)
    local hip = self._hip
    local rise = CFrame.new(hip) * CFrame.Angles(0, 0, -phi) * CFrame.new(-hip)

    for name, sub in self._subs do
        local cf = self._rest[name]
        if name == "Belly" then
            local breath = (1 - math.cos(2 * math.pi * self._t / GiantConfig.BREATH_PERIOD_SEC)) / 2
            cf = cf + Vector3.new(0, breath * GiantConfig.BREATH_HEIGHT, 0)
            if self.shake > 0 then
                -- Предупреждение перед WAKE: живот трясётся.
                cf = cf + Vector3.new(0, (math.random() * 2 - 1) * self.shake, 0)
            end
        elseif name == "Head" and self.stir > 0 then
            -- Teddy_Stir: голова беспокойно ворочается, пока вор тянет мишку.
            local neck = cf.Position
            cf = CFrame.new(neck)
                * CFrame.Angles(math.rad(math.sin(self._t * 6) * 6 * self.stir), 0, 0)
                * CFrame.new(-neck)
                * cf
        elseif name == "ArmR" and self.armYaw then
            local s = self._shoulder
            local swing = CFrame.new(s)
                * CFrame.Angles(0, math.rad(GiantRig.ARM_REST_YAW - self.armYaw), 0)
                * CFrame.new(-s)
            cf = swing * cf + Vector3.new(0, self.armLift, 0)
        elseif name == "Gaze" then
            -- Веер в покое смотрит на север (−Z), это yaw −90°.
            cf = cf * CFrame.Angles(0, math.rad(-(self.gazeYaw + 90)), 0)
        end
        if table.find(UPPER, name) then
            cf = rise * cf
        end
        if sub:GetPivot() ~= cf then
            sub:PivotTo(cf)
        end
        if name == "Lids" then
            for lidName, entry in self._lidParts do
                local open = if lidName == "LidL" then self.lidL else self.lidR
                entry.part.CFrame = cf * entry.rel * CFrame.new(0, open * LID_LIFT, 0)
            end
        end
    end
    self:_applyEyes()
end

return GiantRig
