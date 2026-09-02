--!strict
-- Deprecated imperative toast host — game UI toasts live in React (ToastStack).
-- Kept as a no-op shim so leftover calls don't create ScreenGuis.

export type ToastOptions = {
    text: string,
    color: Color3?,
    duration: number?,
}

local Notification = {}

function Notification.show(_opts: ToastOptions)
    -- Use HudContext.pushToast from React tree instead.
end

return Notification
