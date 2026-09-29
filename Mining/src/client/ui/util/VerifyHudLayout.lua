--!strict

-- Studio smoke: HUD в пределах экрана, верхний хром ниже Roblox topbar.

local RunService = game:GetService("RunService")

local SafeArea = require(script.Parent.SafeArea)
local ViewportLayout = require(script.Parent.ViewportLayout)

local VerifyHudLayout = {}

local TOP_NODES = { "CurrencyRibbon", "InventoryWidget", "TopRightActionRow", "PromoCodeButton", "SocialRewardButton", "QuestTrackerHost" }

function VerifyHudLayout.check(gui: ScreenGui)
	if not RunService:IsStudio() then
		return
	end

	task.defer(function()
		if not gui.Parent then
			return
		end

		local vp = ViewportLayout.getSize()
		local availW = ViewportLayout.availableWidth()
		local topInset = SafeArea.topInset()
		local minTopY = ViewportLayout.topHudY()
		local issues: { string } = {}

		if not gui.IgnoreGuiInset then
			issues[#issues + 1] = "HUD IgnoreGuiInset=false (expected full-screen)"
		end
		if gui.ScreenInsets ~= Enum.ScreenInsets.None then
			issues[#issues + 1] = "HUD ScreenInsets not None"
		end

		local function checkNode(name: string, maxW: number?, maxH: number?)
			local node = gui:FindFirstChild(name, true)
			if not node or not node:IsA("GuiObject") then
				return
			end
			local abs = node.AbsoluteSize
			local pos = node.AbsolutePosition

			if pos.Y < minTopY - 6 then
				issues[#issues + 1] = (`{name} overlaps topbar (y={math.floor(pos.Y)}, min={math.floor(minTopY)})`)
			end
			if abs.X > vp.X + 2 then
				issues[#issues + 1] = (`{name} wider than screen ({math.floor(abs.X)} > {math.floor(vp.X)})`)
			end
			if pos.Y + abs.Y > vp.Y + 2 then
				issues[#issues + 1] = (`{name} below viewport ({math.floor(pos.Y + abs.Y)} > {math.floor(vp.Y)})`)
			end
			if maxW and abs.X > maxW + 2 then
				issues[#issues + 1] = (`{name} exceeds maxW ({math.floor(abs.X)} > {maxW})`)
			end
			if maxH and abs.Y > maxH + 2 then
				issues[#issues + 1] = (`{name} exceeds maxH ({math.floor(abs.Y)} > {maxH})`)
			end
		end

		local modalW, modalH = ViewportLayout.modalPixels(600, 450)
		checkNode("Modal", modalW, modalH)
		checkNode("LeftSidebar", availW)
		for _, nodeName in TOP_NODES do
			checkNode(nodeName)
		end

		local inv = gui:FindFirstChild("InventoryWidget", true)
		if inv and inv:IsA("GuiObject") then
			local abs = inv.AbsoluteSize
			if abs.X < 48 or abs.Y < 20 then
				issues[#issues + 1] = (`InventoryWidget too small ({math.floor(abs.X)}x{math.floor(abs.Y)})`)
			end
			local count = inv:FindFirstChild("Count", true)
			if count and count:IsA("TextLabel") and count.Text == "" then
				issues[#issues + 1] = "InventoryWidget Count label empty"
			end
		end

		if #issues > 0 then
			warn(
				"[HudLayout] tier=",
				ViewportLayout.tier(),
				"vp=",
				vp,
				"inset=",
				topInset,
				"issues:",
				table.concat(issues, "; ")
			)
		else
			print(
				"[HudLayout] OK tier=",
				ViewportLayout.tier(),
				"vp=",
				vp.X,
				"x",
				vp.Y,
				"inset=",
				topInset
			)
		end
	end)
end

return VerifyHudLayout
