--!strict
-- Рэгдолл R15 (GDD 12.3): BallSocketConstraint на месте Motor6D, корневой сустав остаётся.
-- Сервер меняет суставы (видно всем), клиент-владелец задаёт скорость полёта и состояние Physics.

local Ragdoll = {}

type Active = { token: number, sockets: { Instance }, motors: { Motor6D } }

local active: { [Model]: Active } = {}
local nextToken = 0

local function isRootJoint(motor: Motor6D): boolean
    return motor.Name == "Root" or motor.Name == "RootJoint"
end

local function restore(character: Model)
    local entry = active[character]
    if not entry then
        return
    end
    active[character] = nil
    for _, socket in entry.sockets do
        socket:Destroy()
    end
    for _, motor in entry.motors do
        if motor.Parent then
            motor.Enabled = true
        end
    end
end

function Ragdoll.isActive(character: Model): boolean
    return active[character] ~= nil
end

-- Возвращает токен; onDone вызывается, когда персонаж встал (если рэгдолл не перебит новым).
function Ragdoll.start(character: Model, duration: number, onDone: (() -> ())?): number
    nextToken += 1
    local token = nextToken
    local existing = active[character]
    if existing then
        existing.token = token
    else
        local entry: Active = { token = token, sockets = {}, motors = {} }
        for _, motor in character:GetDescendants() do
            if motor:IsA("Motor6D") and not isRootJoint(motor) and motor.Part0 and motor.Part1 then
                local a0 = Instance.new("Attachment")
                a0.Name = "RagdollA0"
                a0.CFrame = motor.C0
                a0.Parent = motor.Part0
                local a1 = Instance.new("Attachment")
                a1.Name = "RagdollA1"
                a1.CFrame = motor.C1
                a1.Parent = motor.Part1
                local socket = Instance.new("BallSocketConstraint")
                socket.Attachment0 = a0
                socket.Attachment1 = a1
                socket.LimitsEnabled = true
                socket.UpperAngle = 60
                socket.Parent = motor.Part0
                table.insert(entry.sockets, a0)
                table.insert(entry.sockets, a1)
                table.insert(entry.sockets, socket)
                table.insert(entry.motors, motor)
                motor.Enabled = false
            end
        end
        active[character] = entry
    end

    task.delay(duration, function()
        local entry = active[character]
        if entry and entry.token == token then
            restore(character)
            if onDone then
                onDone()
            end
        end
    end)
    return token
end

function Ragdoll.stop(character: Model)
    restore(character)
end

return Ragdoll
