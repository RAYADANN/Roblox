--!strict
-- Full-screen Frame wash: red on take-damage, blue on local kill.
-- Lives on GameAim (IgnoreGuiInset) so it covers the 3D view including topbar.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local CombatFlashLogic = require(ReplicatedStorage.shared.util.CombatFlashLogic)
local KillBannerState = require(script.Parent.Parent.Parent.core.KillBannerState)
local MotionPresets = require(script.Parent.Parent.motion.MotionPresets)
local SettingsManager = require(script.Parent.Parent.Parent.core.SettingsManager)
local buildDamageHit = require(script.Parent.Parent.util.buildDamageHit)
local theme = require(script.Parent.Parent.theme)
local useFlipperSpring = require(script.Parent.Parent.hooks.useFlipperSpring)

export type DamageHit = buildDamageHit.DamageHit

export type Props = {
    hits: { DamageHit },
}

type Burst = {
    kind: CombatFlashLogic.Kind,
    id: string,
}

local DAMAGE_COLOR = theme.Colors.error
local KILL_COLOR = theme.Colors.sky

local function FlashBurst(props: { kind: CombatFlashLogic.Kind }): React.Node
    local reduce = SettingsManager.isReduceMotion()
    local opacityTarget, setOpacityTarget =
        React.useState(CombatFlashLogic.peakOpacity(props.kind, reduce))
    local opacity = useFlipperSpring(
        opacityTarget,
        if reduce then MotionPresets.SPRING_GENTLE else MotionPresets.SPRING_DAMAGE_FADE
    )

    React.useEffect(function()
        local thread = task.delay(CombatFlashLogic.holdSec(reduce), function()
            setOpacityTarget(0)
        end)
        return function()
            task.cancel(thread)
        end
    end, {})

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = if props.kind == "kill" then KILL_COLOR else DAMAGE_COLOR,
        BackgroundTransparency = CombatFlashLogic.backgroundTransparency(opacity),
        BorderSizePixel = 0,
        Active = false,
        Selectable = false,
        ZIndex = 1,
    })
end

local function CombatFlashLayer(props: Props): React.Node
    local burst, setBurst = React.useState(nil :: Burst?)
    local lastHitIdRef = React.useRef(nil :: string?)
    local killSnap, setKillSnap = React.useState(KillBannerState.getSnapshot())
    local lastKillTokenRef = React.useRef(killSnap.token)

    local hitsKey = ""
    for _, hit in props.hits do
        hitsKey ..= hit.id .. ","
    end

    React.useEffect(function()
        if #props.hits == 0 then
            return
        end
        local newest = props.hits[#props.hits]
        if newest.id == lastHitIdRef.current then
            return
        end
        lastHitIdRef.current = newest.id
        setBurst({
            kind = "damage",
            id = "d" .. newest.id,
        })
    end, { hitsKey })

    React.useEffect(function()
        return KillBannerState.subscribe(function()
            setKillSnap(KillBannerState.getSnapshot())
        end)
    end, {})

    React.useEffect(function()
        if killSnap.token <= lastKillTokenRef.current then
            return
        end
        lastKillTokenRef.current = killSnap.token
        setBurst({
            kind = "kill",
            id = "k" .. tostring(killSnap.token),
        })
    end, { killSnap.token })

    local children: { [string]: React.Node } = {}
    if burst then
        children["b_" .. burst.id] = React.createElement(FlashBurst, {
            kind = burst.kind,
        })
    end

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = false,
        Selectable = false,
        ZIndex = 1,
    }, children)
end

return CombatFlashLayer
