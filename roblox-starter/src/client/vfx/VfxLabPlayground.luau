--!strict
-- VfxLab Playground: UI buttons + camera modes + signature effects.
-- Start from LocalScript: require(...).start()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local VfxController = require(script.Parent.Parent.core.VfxController)

local Playground = {}

local function ensureLab(): Folder
	local existing = Workspace:FindFirstChild("VfxLab")
	if existing and existing:IsA("Folder") and existing:FindFirstChild("CenterBurst") then
		return existing
	end
	if existing then
		existing:Destroy()
	end

	local lab = Instance.new("Folder")
	lab.Name = "VfxLab"
	lab.Parent = Workspace

	local function makePart(name: string, cframe: CFrame, color: Color3, size: Vector3?): BasePart
		local part = Instance.new("Part")
		part.Name = name
		part.Anchored = true
		part.CanCollide = false
		part.Material = Enum.Material.Neon
		part.Color = color
		part.Size = size or Vector3.new(1.5, 1.5, 1.5)
		part.CFrame = cframe
		part.Parent = lab

		local bb = Instance.new("BillboardGui")
		bb.Name = "Tag"
		bb.Size = UDim2.fromOffset(120, 26)
		bb.StudsOffset = Vector3.new(0, 2.6, 0)
		bb.AlwaysOnTop = true
		bb.Parent = part
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(1, 1)
		t.Font = Enum.Font.GothamBold
		t.TextScaled = true
		t.TextColor3 = Color3.new(1, 1, 1)
		t.TextStrokeTransparency = 0.4
		t.Text = name
		t.Parent = bb
		return part
	end

	local origin = Vector3.new(0, 6, 0)
	makePart("CenterBurst", CFrame.new(origin), Color3.fromRGB(120, 220, 255))
	makePart("CastBurst", CFrame.new(origin + Vector3.new(-12, 0, 0)), Color3.fromRGB(255, 210, 80))
	makePart("FlipbookBurst", CFrame.new(origin + Vector3.new(12, 0, 0)), Color3.fromRGB(255, 90, 220))
	makePart("AuraAnchor", CFrame.new(origin + Vector3.new(0, 0, 12)), Color3.fromRGB(180, 100, 255), Vector3.new(2, 2, 2))
	makePart(
		"HandGlowAnchor",
		CFrame.new(origin + Vector3.new(0, 0, -12)),
		Color3.fromRGB(100, 255, 160),
		Vector3.new(1.2, 2.4, 1.2)
	)
	makePart("ProjectileStart", CFrame.new(origin + Vector3.new(-18, 0, -10)), Color3.fromRGB(90, 180, 255), Vector3.new(1, 1, 1))
	makePart("ProjectileEnd", CFrame.new(origin + Vector3.new(18, 0, -10)), Color3.fromRGB(255, 90, 180), Vector3.new(1, 1, 1))
	makePart("HitDummy", CFrame.new(origin + Vector3.new(0, 0, 22)), Color3.fromRGB(255, 255, 255), Vector3.new(3, 4, 1.5))

	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Anchored = true
	floor.Material = Enum.Material.SmoothPlastic
	floor.Color = Color3.fromRGB(20, 22, 30)
	floor.Size = Vector3.new(48, 1, 48)
	floor.CFrame = CFrame.new(origin + Vector3.new(0, -2.5, 0))
	floor.Parent = lab

	-- Show uploaded flipbook atlases on pads (edit + play visibility)
	local neonDecal = Instance.new("Decal")
	neonDecal.Name = "AtlasPreview"
	neonDecal.Face = Enum.NormalId.Front
	neonDecal.Texture = "rbxassetid://117687641569968"
	neonDecal.Parent = lab.FlipbookBurst

	local smokeDecal = Instance.new("Decal")
	smokeDecal.Name = "AtlasPreview"
	smokeDecal.Face = Enum.NormalId.Front
	smokeDecal.Texture = "rbxassetid://131840252392616"
	smokeDecal.Parent = lab.CastBurst

	lab.FlipbookBurst.Tag.TextLabel.Text = "NEON"
	lab.CastBurst.Tag.TextLabel.Text = "SMOKE"
	lab.CenterBurst.Tag.TextLabel.Text = "IMPACT"
	lab.AuraAnchor.Tag.TextLabel.Text = "AURA"
	lab.HandGlowAnchor.Tag.TextLabel.Text = "HAND"
	lab.ProjectileStart.Tag.TextLabel.Text = "FROM"
	lab.ProjectileEnd.Tag.TextLabel.Text = "TO"
	lab.HitDummy.Tag.TextLabel.Text = "HIT"

	return lab
end

local function getPart(name: string): BasePart
	local lab = ensureLab()
	local part = lab:WaitForChild(name, 5)
	assert(part, `missing {name}`)
	return part :: BasePart
end

function Playground.start()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local okStart, errStart = pcall(function()
		VfxController.start({ cameraMode = "HumanoidOffset" })
	end)
	if not okStart then
		warn("[VfxLab] VfxController.start failed:", errStart)
	end

	ensureLab()

	local center = getPart("CenterBurst")
	local cast = getPart("CastBurst")
	local flipbook = getPart("FlipbookBurst")
	local auraAnchor = getPart("AuraAnchor")
	local handGlowAnchor = getPart("HandGlowAnchor")
	local projectileStart = getPart("ProjectileStart")
	local projectileEnd = getPart("ProjectileEnd")
	local hitDummy = getPart("HitDummy")

	local auraHandle = VfxController.play("PowerAura", {
		cframe = auraAnchor.CFrame,
		color = auraAnchor.Color,
		intensity = 0.85,
	})
	local handHandle = VfxController.play("HandGlow", {
		cframe = handGlowAnchor.CFrame,
		target = handGlowAnchor,
		color = handGlowAnchor.Color,
		intensity = 0.85,
	})

	local autoPlay = true
	local cameraMode = "HumanoidOffset"

	local gui = Instance.new("ScreenGui")
	gui.Name = "VfxLabUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 80
	gui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(1, 0)
	panel.Position = UDim2.new(1, -16, 0, 72)
	panel.Size = UDim2.fromOffset(220, 460)
	panel.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
	panel.BackgroundTransparency = 0.18
	panel.BorderSizePixel = 0
	panel.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -16, 0, 28)
	title.Position = UDim2.fromOffset(8, 8)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Color3.fromRGB(240, 245, 255)
	title.Text = "VFX LAB"
	title.Parent = panel

	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Size = UDim2.new(1, -16, 0, 36)
	status.Position = UDim2.fromOffset(8, 34)
	status.BackgroundTransparency = 1
	status.Font = Enum.Font.Gotham
	status.TextSize = 12
	status.TextWrapped = true
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.TextYAlignment = Enum.TextYAlignment.Top
	status.TextColor3 = Color3.fromRGB(160, 190, 220)
	status.Text = "Auto ON · Cam Humanoid · keys 1-4"
	status.Parent = panel

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 6)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = panel

	local spacer = Instance.new("Frame")
	spacer.BackgroundTransparency = 1
	spacer.Size = UDim2.new(1, 0, 0, 70)
	spacer.LayoutOrder = 0
	spacer.Parent = panel

	local function setStatus(msg: string)
		status.Text = msg
	end

	local function makeButton(label: string, order: number, onClick: () -> ())
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -16, 0, 30)
		btn.BackgroundColor3 = Color3.fromRGB(28, 36, 52)
		btn.BorderSizePixel = 0
		btn.Font = Enum.Font.GothamMedium
		btn.TextSize = 13
		btn.TextColor3 = Color3.fromRGB(230, 240, 255)
		btn.Text = label
		btn.LayoutOrder = order
		btn.AutoButtonColor = true
		btn.Parent = panel
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent = btn
		btn.MouseButton1Click:Connect(function()
			local ok, err = pcall(onClick)
			if not ok then
				setStatus(`ERR: {err}`)
				warn("[VfxLab]", err)
			end
		end)
	end

	makeButton("Neon Impact", 1, function()
		VfxController.play("NeonImpact", {
			cframe = flipbook.CFrame,
			color = Color3.fromRGB(90, 230, 255),
			intensity = 1.25,
		})
		setStatus("NeonImpact")
	end)
	makeButton("Smoke Dash", 2, function()
		VfxController.play("SmokeDash", {
			cframe = cast.CFrame,
			color = Color3.fromRGB(90, 95, 110),
			intensity = 1.2,
		})
		setStatus("SmokeDash")
	end)
	makeButton("Impact Burst", 3, function()
		VfxController.play("ImpactBurst", {
			cframe = center.CFrame,
			color = center.Color,
			intensity = 1.2,
		})
		setStatus("ImpactBurst")
	end)
	makeButton("Cast Burst", 4, function()
		VfxController.play("CastBurst", {
			cframe = cast.CFrame,
			color = cast.Color,
			intensity = 1.15,
		})
		setStatus("CastBurst")
	end)
	makeButton("Neon Bolt", 5, function()
		VfxController.play("NeonBolt", {
			from = projectileStart.CFrame,
			to = projectileEnd.CFrame,
			color = Color3.fromRGB(120, 220, 255),
			intensity = 1.15,
		})
		setStatus("NeonBolt")
	end)
	makeButton("Hit Confirm", 6, function()
		VfxController.play("HitConfirm", {
			cframe = hitDummy.CFrame,
			target = hitDummy,
			color = Color3.fromRGB(255, 255, 255),
		})
		setStatus("HitConfirm")
	end)
	makeButton("Damage Flash", 7, function()
		VfxController.play("DamageFlash", { intensity = 0.7 })
		setStatus("DamageFlash")
	end)
	makeButton("Toggle Auto", 8, function()
		autoPlay = not autoPlay
		setStatus(`Auto {if autoPlay then "ON" else "OFF"} · Cam {cameraMode}`)
	end)
	makeButton("Cam: Humanoid", 9, function()
		cameraMode = "HumanoidOffset"
		VfxController.setCameraMode("HumanoidOffset")
		setStatus("Cam HumanoidOffset")
	end)
	makeButton("Cam: ShakeBus", 10, function()
		cameraMode = "ShakeBus"
		VfxController.setCameraMode("ShakeBus", function(offset)
			local cam = Workspace.CurrentCamera
			if cam then
				cam.CFrame = cam.CFrame * CFrame.new(offset * 0.35)
			end
		end)
		setStatus("Cam ShakeBus")
	end)
	makeButton("Cam: Noop", 11, function()
		cameraMode = "Noop"
		VfxController.setCameraMode("Noop")
		setStatus("Cam Noop")
	end)
	makeButton("Stop All", 12, function()
		VfxController.stopAll()
		auraHandle = VfxController.play("PowerAura", {
			cframe = auraAnchor.CFrame,
			color = auraAnchor.Color,
			intensity = 0.85,
		})
		handHandle = VfxController.play("HandGlow", {
			cframe = handGlowAnchor.CFrame,
			target = handGlowAnchor,
			color = handGlowAnchor.Color,
			intensity = 0.85,
		})
		setStatus("Stopped · loops restarted")
	end)

	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then
			return
		end
		if input.KeyCode == Enum.KeyCode.One then
			VfxController.play("NeonImpact", {
				cframe = flipbook.CFrame,
				color = Color3.fromRGB(90, 230, 255),
				intensity = 1.25,
			})
		elseif input.KeyCode == Enum.KeyCode.Two then
			VfxController.play("SmokeDash", {
				cframe = cast.CFrame,
				color = Color3.fromRGB(90, 95, 110),
				intensity = 1.2,
			})
		elseif input.KeyCode == Enum.KeyCode.Three then
			VfxController.play("NeonBolt", {
				from = projectileStart.CFrame,
				to = projectileEnd.CFrame,
				color = Color3.fromRGB(120, 220, 255),
			})
		elseif input.KeyCode == Enum.KeyCode.Four then
			autoPlay = not autoPlay
			setStatus(`Auto {if autoPlay then "ON" else "OFF"} · Cam {cameraMode}`)
		end
	end)

	local autoStep = 0
	task.spawn(function()
		while true do
			if autoPlay then
				autoStep += 1
				if auraHandle and auraHandle:isPlaying() then
					auraHandle:setIntensity(0.7 + 0.25 * math.sin(os.clock() * 2))
				end
				if handHandle and handHandle:isPlaying() then
					handHandle:setIntensity(0.7 + 0.2 * math.sin(os.clock() * 2.4))
				end

				if autoStep % 2 == 1 then
					VfxController.play("NeonImpact", {
						cframe = flipbook.CFrame,
						color = Color3.fromRGB(90, 230, 255),
						intensity = 1.15,
					})
				else
					VfxController.play("SmokeDash", {
						cframe = cast.CFrame,
						color = Color3.fromRGB(70, 75, 90),
						intensity = 1.1,
					})
				end

				task.wait(0.35)
				VfxController.play("NeonBolt", {
					from = projectileStart.CFrame,
					to = projectileEnd.CFrame,
					color = Color3.fromRGB(120, 220, 255),
					intensity = 1.05,
				})
				task.wait(0.25)
				VfxController.play("ImpactBurst", {
					cframe = center.CFrame,
					color = center.Color,
					intensity = 1.05,
				})
				task.wait(0.2)
				VfxController.play("HitConfirm", {
					cframe = hitDummy.CFrame,
					target = hitDummy,
				})
			end
			task.wait(0.85)
		end
	end)

	print("[VfxLab] playground ready — panel right, keys 1-4")
end

return Playground
