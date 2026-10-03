--!strict
-- Global HUD visibility gate (cutscenes hide Shop/Upgrades/money).

local HudGate = {}

local _visible = true
local _listeners: { (visible: boolean) -> () } = {}

function HudGate.isVisible(): boolean
    return _visible
end

function HudGate.setVisible(visible: boolean)
    if _visible == visible then
        return
    end
    _visible = visible
    for _, listener in _listeners do
        task.spawn(listener, visible)
    end
end

function HudGate.onChanged(listener: (visible: boolean) -> ()): () -> ()
    table.insert(_listeners, listener)
    return function()
        local i = table.find(_listeners, listener)
        if i then
            table.remove(_listeners, i)
        end
    end
end

return HudGate
