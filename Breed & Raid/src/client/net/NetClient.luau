--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemotesMod = require(ReplicatedStorage.shared.net.Remotes)
local SessionTypes = require(ReplicatedStorage.shared.types.Session)

type HudPayload = SessionTypes.HudPayload
type RemotesApi = RemotesMod.RemotesApi

local NetClient = {}
NetClient.__index = NetClient

export type NetClient = typeof(setmetatable(
	{} :: {
		_remotes: RemotesApi,
		_connections: { RBXScriptConnection },
	},
	NetClient
))

function NetClient.new(): NetClient
	return setmetatable({
		_remotes = RemotesMod.get(),
		_connections = {},
	}, NetClient)
end

function NetClient:onHudSync(handler: (HudPayload) -> ()): () -> ()
	local conn = self._remotes.HudSync.OnClientEvent:Connect(handler)
	table.insert(self._connections, conn)
	return function()
		conn:Disconnect()
	end
end

function NetClient:onNotify(handler: (payload: { kind: string, payload: string }) -> ()): () -> ()
	local conn = self._remotes.Notify.OnClientEvent:Connect(handler)
	table.insert(self._connections, conn)
	return function()
		conn:Disconnect()
	end
end

function NetClient:requestCollect()
	self._remotes.RequestCollect:FireServer()
end

function NetClient:requestCreatureRoll()
	self._remotes.RequestCreatureRoll:FireServer()
end

function NetClient:confirmCreatureBuy()
	self._remotes.ConfirmCreatureBuy:FireServer()
end

function NetClient:requestBlockRoll()
	self._remotes.RequestBlockRoll:FireServer()
end

function NetClient:confirmBlockBuy()
	self._remotes.ConfirmBlockBuy:FireServer()
end

function NetClient:startBreed(a: string, b: string)
	self._remotes.RequestStartBreed:FireServer(a, b)
end

function NetClient:cancelBreed()
	self._remotes.RequestCancelBreed:FireServer()
end

function NetClient:softSpeedBreed()
	self._remotes.RequestSoftSpeedBreed:FireServer()
end

function NetClient:placeDirt(x: number, z: number, rot: number?)
	-- legacy flat place → layer 0
	self._remotes.RequestPlaceBlock:FireServer("dirt", x, 0, z)
end

function NetClient:placeCube(blockId: string, cellX: number, cellY: number, cellZ: number)
	self._remotes.RequestPlaceBlock:FireServer(blockId, cellX, cellY, cellZ)
end

function NetClient:requestTakeBlock(placeableId: string)
	self._remotes.RequestTakeBlock:FireServer(placeableId)
end

function NetClient:destroy()
	for _, conn in self._connections do
		conn:Disconnect()
	end
	table.clear(self._connections)
end

return NetClient
