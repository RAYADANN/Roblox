--!strict
-- Absolute center of HUD money chip (для FlyBurst / CoinRain).

local HudMoneyAnchor = {}

local _gui: GuiObject? = nil
local _onPulse: (() -> ())? = nil

function HudMoneyAnchor.bind(gui: GuiObject?)
    _gui = gui
end

function HudMoneyAnchor.getBound(): GuiObject?
    local gui = _gui
    if gui == nil or gui.Parent == nil then
        return nil
    end
    return gui
end

function HudMoneyAnchor.setPulseHandler(handler: (() -> ())?)
    _onPulse = handler
end

function HudMoneyAnchor.getCenter(): Vector2?
    local gui = HudMoneyAnchor.getBound()
    if gui == nil then
        return nil
    end
    local pos = gui.AbsolutePosition
    local size = gui.AbsoluteSize
    return Vector2.new(pos.X + size.X * 0.35, pos.Y + size.Y * 0.5)
end

function HudMoneyAnchor.pulse()
    local fn = _onPulse
    if fn then
        fn()
    end
end

return HudMoneyAnchor
