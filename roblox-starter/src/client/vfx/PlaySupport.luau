--!strict
-- Хелперы play-пайплайна (чтобы VfxEngine оставался тонким).

local Workspace = game:GetService("Workspace")
local Types = require(game:GetService("ReplicatedStorage").shared.vfx.Types)

export type EffectKind = Types.EffectKind

export type PlayContext = {
	cframe: CFrame?,
	from: CFrame?,
	to: CFrame?,
	target: Instance?,
	origin: Vector3?,
}

local PlaySupport = {}

local AUTO_STOP: { [EffectKind]: boolean } = {
	Burst = true,
	Projectile = true,
	Screen = true,
	Chain = true,
}
PlaySupport.AUTO_STOP = AUTO_STOP

function PlaySupport.resolveOrigin(ctx: PlayContext, kind: EffectKind): Vector3
	if kind == "Screen" then
		local cam = Workspace.CurrentCamera
		return if cam then cam.CFrame.Position else Vector3.zero
	end
	if ctx.origin then
		return ctx.origin
	end
	if ctx.cframe then
		return ctx.cframe.Position
	end
	if ctx.target and ctx.target:IsA("BasePart") then
		return (ctx.target :: BasePart).Position
	end
	if ctx.from then
		return ctx.from.Position
	end
	return Vector3.zero
end

function PlaySupport.resolveCFrame(ctx: PlayContext): CFrame
	if ctx.cframe then
		return ctx.cframe
	end
	if ctx.target and ctx.target:IsA("BasePart") then
		return (ctx.target :: BasePart).CFrame
	end
	if ctx.from then
		return ctx.from
	end
	return CFrame.new()
end

function PlaySupport.ensureFolder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

return PlaySupport
