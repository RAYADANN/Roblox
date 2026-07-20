--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "NightRaidRemotes"

local function getFolder(): Folder
	if RunService:IsServer() then
		local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = FOLDER_NAME
			folder.Parent = ReplicatedStorage
		end
		return folder :: Folder
	end
	return ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
end

local function remoteEvent(name: string): RemoteEvent
	local folder = getFolder()
	if RunService:IsServer() then
		local existing = folder:FindFirstChild(name)
		if existing and existing:IsA("RemoteEvent") then
			return existing
		end
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
		return remote
	end
	return folder:WaitForChild(name) :: RemoteEvent
end

return {
	ShineState = remoteEvent("ShineState"),
	CycleChanged = remoteEvent("CycleChanged"),
	ReclaimFog = remoteEvent("ReclaimFog"),
	Toast = remoteEvent("Toast"),
	-- pets leftover / steal bag
	InventorySync = remoteEvent("InventorySync"),
	-- block stacks { [blockId]: qty }
	BlockInvSync = remoteEvent("BlockInvSync"),
	BufferSync = remoteEvent("BufferSync"),
	RequestRoll = remoteEvent("RequestRoll"), -- kind: "block" | "pet"
	RollResult = remoteEvent("RollResult"),
	ConfirmBuy = remoteEvent("ConfirmBuy"), -- kind
	CollectAll = remoteEvent("CollectAll"),
	PlacePet = remoteEvent("PlacePet"),
	OpenBuild = remoteEvent("OpenBuild"),
	RequestPlaceBlock = remoteEvent("RequestPlaceBlock"),
	RequestTakeBlock = remoteEvent("RequestTakeBlock"),
	RequestSteal = remoteEvent("RequestSteal"),
	BatHit = remoteEvent("BatHit"),
	BatHitBlock = remoteEvent("BatHitBlock"),
	ToggleLock = remoteEvent("ToggleLock"),
	PlotStateSync = remoteEvent("PlotStateSync"),
}
