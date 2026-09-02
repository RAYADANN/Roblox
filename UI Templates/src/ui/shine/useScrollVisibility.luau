--!strict
-- Re-render only when a cell enters/leaves ScrollingFrame viewport.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local visibility = require(script.Parent.visibility)

export type ScrollRef = { current: ScrollingFrame? }
export type HostRef = { current: GuiObject? }

export type Options = {
    scrollRef: ScrollRef,
    hostRef: HostRef,
    marginPx: number?,
    enabled: boolean?,
}

local function useScrollVisibility(opts: Options): (boolean, () -> ())
    local marginPx = opts.marginPx or 24
    local enabled = if opts.enabled ~= nil then opts.enabled else true

    local visible, setVisible = React.useState(true)
    local recomputeRef = React.useRef(function() end)

    React.useEffect(function()
        if not enabled then
            setVisible(true)
            recomputeRef.current = function() end
            return function() end
        end

        local conns: { RBXScriptConnection } = {}

        local function disconnectAll()
            for _, conn in conns do
                conn:Disconnect()
            end
            table.clear(conns)
        end

        local function watch(inst: GuiObject, prop: string)
            table.insert(
                conns,
                inst:GetPropertyChangedSignal(prop):Connect(function()
                    recomputeRef.current()
                end)
            )
        end

        local function recompute()
            local scroll = opts.scrollRef.current
            local host = opts.hostRef.current
            if scroll == nil or host == nil then
                setVisible(true)
                return
            end
            local nextVisible = visibility.isInScrollView(host, scroll, marginPx)
            setVisible(function(prev)
                if prev == nextVisible then
                    return prev
                end
                return nextVisible
            end)
        end

        recomputeRef.current = recompute

        local function attach()
            disconnectAll()
            local scroll = opts.scrollRef.current
            local host = opts.hostRef.current
            if scroll == nil then
                recompute()
                return
            end
            watch(scroll, "CanvasPosition")
            watch(scroll, "AbsoluteSize")
            watch(scroll, "AbsolutePosition")
            if host then
                watch(host, "AbsolutePosition")
                watch(host, "AbsoluteSize")
            end
            recompute()
        end

        attach()

        return function()
            disconnectAll()
            recomputeRef.current = function() end
        end
    end, { enabled, marginPx })

    local function bump()
        recomputeRef.current()
    end

    return visible, bump
end

return useScrollVisibility
