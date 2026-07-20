--!strict

-- RemoteEvent stubs per GDD §16. Zap later (TECH_STACK).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local REMOTE_NAMES = {
	"RequestCreatureRoll",
	"ConfirmCreatureBuy",
	"RequestBlockRoll",
	"ConfirmBlockBuy",
	"RequestPlaceCreature",
	"RequestMoveCreature",
	"RequestUnequip",
	"RequestCollect",
	"RequestStartBreed",
	"RequestCancelBreed",
	"RequestSoftSpeedBreed",
	"RequestStartSteal",
	"RequestDepositSteal",
	"RequestReclaim",
	"RequestLock",
	"RequestBatSwing",
	"RequestPlaceBlock",
	"RequestTakeBlock",
	"RequestBuyNest",
	"RequestBuyLuck",
	"HudSync",
	"Notify",
}

export type RemotesApi = {
	[string]: RemoteEvent,
}

local function ensureFolder(): Folder
	local existing = ReplicatedStorage:FindFirstChild("Remotes")
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage
	return folder
end

local function ensureRemote(folder: Folder, name: string): RemoteEvent
	local existing = folder:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = folder
	return remote
end

local Remotes = {}

function Remotes.init(): RemotesApi
	local folder = ensureFolder()
	local api: RemotesApi = {}
	for _, name in REMOTE_NAMES do
		api[name] = ensureRemote(folder, name)
	end
	return api
end

function Remotes.get(): RemotesApi
	local folder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
	local api: RemotesApi = {}
	for _, name in REMOTE_NAMES do
		api[name] = folder:WaitForChild(name) :: RemoteEvent
	end
	return api
end

return Remotes
