--!strict
-- Blur + FOV zoom while a HUD window is open. Imperative glue (не React).

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local MotionPresets = require(script.Parent.Parent.motion.MotionPresets)

local BLUR_NAME = "UiModalBlur"
local BLUR_SIZE = 18
local FOV_ZOOM_IN = 8 -- open → FieldOfView -= this (приближение)
local OPEN_INFO = TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local CLOSE_INFO = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local blur: BlurEffect? = nil
local baseFov: number? = nil
local generation = 0
local isOpen = false

local ModalFocus = {}

local function getCamera(): Camera?
    return Workspace.CurrentCamera
end

local function ensureBlur(): BlurEffect
    local existing = blur
    if existing ~= nil and existing.Parent ~= nil then
        return existing
    end
    local found = Lighting:FindFirstChild(BLUR_NAME)
    if found ~= nil and found:IsA("BlurEffect") then
        blur = found
        return found
    end
    local created = Instance.new("BlurEffect")
    created.Name = BLUR_NAME
    created.Size = 0
    created.Enabled = false
    created.Parent = Lighting
    blur = created
    return created
end

local function cancelGeneration(): number
    generation += 1
    return generation
end

function ModalFocus.setOpen(open: boolean)
    if open == isOpen then
        return
    end
    isOpen = open
    local token = cancelGeneration()
    local b = ensureBlur()
    local cam = getCamera()

    if open then
        b.Enabled = true
        MotionPresets.tween(b, { Size = BLUR_SIZE }, OPEN_INFO)
        if cam ~= nil then
            if baseFov == nil then
                baseFov = cam.FieldOfView
            end
            local target = math.clamp((baseFov :: number) - FOV_ZOOM_IN, 20, 120)
            MotionPresets.tween(cam, { FieldOfView = target }, OPEN_INFO)
        end
        return
    end

    -- close
    local restoreFov = baseFov
    baseFov = nil
    local blurTw = MotionPresets.tween(b, { Size = 0 }, CLOSE_INFO)
    blurTw.Completed:Connect(function()
        if token == generation then
            b.Enabled = false
        end
    end)
    if cam ~= nil and restoreFov ~= nil then
        MotionPresets.tween(cam, { FieldOfView = restoreFov }, CLOSE_INFO)
    end
end

function ModalFocus.isFocused(): boolean
    return isOpen
end

function ModalFocus.destroy()
    cancelGeneration()
    isOpen = false
    local cam = getCamera()
    if cam ~= nil and baseFov ~= nil then
        cam.FieldOfView = baseFov
    end
    baseFov = nil
    local b = blur
    blur = nil
    if b ~= nil then
        b:Destroy()
    end
    local leftover = Lighting:FindFirstChild(BLUR_NAME)
    if leftover ~= nil then
        leftover:Destroy()
    end
end

return ModalFocus
