--!strict
-- Eye Open подаётся как Red Light, Green Light (GDD 2.3): у игроков в зоне крупно
-- «FREEZE!» красным, когда глаз открылся, и «GO!» зелёным, когда закрылся.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local GiantConfig = require(ReplicatedStorage.shared.data.GiantConfig)
local MotionPresets = require(script.Parent.Parent.motion.MotionPresets)
local theme = require(script.Parent.Parent.theme)
local useFlipperSpring = require(script.Parent.Parent.hooks.useFlipperSpring)
local useLayout = require(script.Parent.Parent.hooks.useLayout)

local SHOW_SEC = 1.2
local FREEZE_COLOR = Color3.fromHex("#C4281C")
local GO_COLOR = Color3.fromHex("#4CD964")

export type Props = {
    phase: string,
}

local function inZone(): boolean
    local character = Players.LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not root then
        return false
    end
    return Vector2.new(root.Position.X, root.Position.Z).Magnitude <= GiantConfig.ZONE_RADIUS
end

local function PhaseBanner(props: Props): React.Node
    local layout = useLayout()
    local banner, setBanner = React.useState(nil :: { text: string, color: Color3, id: number }?)
    local prevPhase = React.useRef(props.phase)
    local scale = useFlipperSpring(if banner then 1 else 0.6, MotionPresets.SPRING_BOUNCY)

    React.useEffect(function()
        local prev = prevPhase.current
        prevPhase.current = props.phase
        local nextBanner = nil
        if props.phase == "EyeOpen" and prev ~= "EyeOpen" then
            nextBanner = { text = "FREEZE!", color = FREEZE_COLOR }
        elseif prev == "EyeOpen" and props.phase ~= "EyeOpen" and props.phase ~= "Wake" then
            nextBanner = { text = "GO!", color = GO_COLOR }
        end
        if nextBanner and inZone() then
            local id = os.clock()
            setBanner({ text = nextBanner.text, color = nextBanner.color, id = id })
            task.delay(SHOW_SEC, function()
                setBanner(function(current)
                    return if current and current.id == id then nil else current
                end)
            end)
        end
        return nil
    end, { props.phase })

    if not banner then
        return nil
    end
    return React.createElement("TextLabel", {
        Size = UDim2.fromOffset(layout.px(520), layout.px(120)),
        Position = UDim2.fromScale(0.5, 0.38),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Text = banner.text,
        TextColor3 = banner.color,
        Font = theme.Font.heavy,
        TextScaled = true,
    }, {
        Stroke = React.createElement(
            "UIStroke",
            { Color = theme.Colors.outlineDark, Thickness = 4 }
        ),
        Scale = React.createElement("UIScale", { Scale = scale }),
    })
end

return PhaseBanner
