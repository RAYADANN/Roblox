--!strict
-- Fixed 1920×1080 canvas + UIScale.
-- Fit target = host AbsoluteSize (CoreUISafeInsets ScreenGui).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local DesignContext = require(script.Parent.context.DesignContext)
local SafeArea = require(script.Parent.util.SafeArea)
local adapt = require(script.Parent.adapt)

local UiScaler = adapt.UiScaler

export type Props = {
    children: React.Node?,
    config: UiScaler.Config?,
}

local function DesignRoot(props: Props): React.Node
    local config = props.config or adapt.DEFAULT
    local designRef = UiScaler.getReference(config)
    local hostRef = React.useRef(nil :: Frame?)
    local scale, setScale = React.useState(1)

    local function applyHost(size: Vector2)
        if size.X < 32 or size.Y < 32 then
            return
        end
        setScale(UiScaler.computeFromUsable(size, config))
    end

    React.useEffect(function()
        return SafeArea.subscribe(function()
            local host = hostRef.current
            if host then
                applyHost(host.AbsoluteSize)
            end
        end)
    end, {})

    local metrics: DesignContext.DesignMetrics = {
        scale = scale,
        reference = designRef,
        safeTop = 0,
        safeLeft = 0,
    }

    local canvasChildren: { [string]: React.Node } = {
        Scaler = React.createElement("UIScale", {
            Scale = scale,
        }),
    }

    local incoming = props.children
    if typeof(incoming) == "table" then
        for key, node in incoming :: { [string]: React.Node } do
            canvasChildren[key] = node
        end
    elseif incoming ~= nil then
        canvasChildren.Child = incoming :: React.Node
    end

    return React.createElement(DesignContext.Provider, {
        value = metrics,
    }, {
        Root = React.createElement("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Active = false,
            ZIndex = 2,
            ref = function(rbx: Frame?)
                hostRef.current = rbx
                if rbx then
                    applyHost(rbx.AbsoluteSize)
                end
            end,
            [React.Change.AbsoluteSize] = function(rbx: Frame)
                applyHost(rbx.AbsoluteSize)
            end,
        }, {
            Canvas = React.createElement("Frame", {
                Size = UDim2.fromOffset(designRef.X, designRef.Y),
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Active = false,
            }, canvasChildren),
        }),
    })
end

return DesignRoot
