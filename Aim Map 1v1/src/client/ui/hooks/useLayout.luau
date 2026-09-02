--!strict
-- Deprecated alias: prefer useDesign(). Kept so stray requires still resolve.

local useDesign = require(script.Parent.useDesign)

export type LayoutMetrics = useDesign.DesignMetrics

local function useLayout(): LayoutMetrics
    return useDesign()
end

return useLayout
