--!strict
-- Lightweight UI SFX. Safe if assets missing — never errors.

local SoundService = game:GetService("SoundService")

local IDS = {
	click = "rbxassetid://6895079853",
	buy = "rbxassetid://4522679180",
	collect = "rbxassetid://6895079853",
	hatch = "rbxassetid://9114221256",
	fail = "rbxassetid://138081500",
}

local bus: SoundGroup? = nil

local function getBus(): SoundGroup
	if bus and bus.Parent then
		return bus
	end
	local existing = SoundService:FindFirstChild("BreedRaidUiBus")
	if existing and existing:IsA("SoundGroup") then
		bus = existing
		return existing
	end
	local g = Instance.new("SoundGroup")
	g.Name = "BreedRaidUiBus"
	g.Volume = 0.55
	g.Parent = SoundService
	bus = g
	return g
end

local UiSound = {}

function UiSound.play(kind: string)
	local id = IDS[kind]
	if not id then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = 0.7
	s.SoundGroup = getBus()
	s.Parent = SoundService
	local ok = pcall(function()
		s:Play()
	end)
	if ok then
		s.Ended:Once(function()
			s:Destroy()
		end)
		task.delay(3, function()
			if s.Parent then
				s:Destroy()
			end
		end)
	else
		s:Destroy()
	end
end

return UiSound
