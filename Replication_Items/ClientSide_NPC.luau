local baseClone = game.ReplicatedStorage.ShopKeeper
local newID = require(game.ReplicatedStorage.Modules.RandomID_Generator)

local npc_LocalEvent = game.ReplicatedStorage.Events.localNPC_Event
local clientNPC_Handle_Event = game.ReplicatedStorage.Events.NPC_replicateHandlerEvent

local clientRemote = game.ReplicatedStorage.Events.clientRemote
local serverRequest = game.ReplicatedStorage.Events.serverNPC_RequestBind

local module = {}
module.__index = module
--NPC strings are 5 letter
--Verification strings are 7 letter

module.clientRequest = function(Location: Vector3, globalRep)--Specific NPCs such as a hallucination.
	if not globalRep then 
				warn("Firing")
				clientRemote:FireServer("localReplication", Location)
	else
		--Nothing.
	end	
end

module.serverRepRequest = function(Location: Vector3, globalRep)
	if not globalRep then 
		warn("Firing")
		serverRequest:Fire("localReplication", Location)
	else
		--Nothing.
	end	
end


module.new	= function(Location: Vector3, ID)
		local self = setmetatable({}, module)
	self.newNPC = baseClone:Clone()
	self.HumanoidRootPart = self.newNPC.HumanoidRootPart 
	self.HumanoidRootPart.Position = Location
	self.ID = ID
	
	--if not replicationTable[self.ID] then
	--	return warn("NPC isn't server verified terminating.")
	--end
	
		return self
end

module.Spawn = function(self, parentDirectory)
			self.newNPC.Parent = parentDirectory or workspace
end

return module

--[[
Problem:
1. NPC_Generator (Module/Server)
2. functionLocalCall (localScript)
3.due to ID being generated locally differing ID

Solution:
 .NPC_Gen (Mod/Serv)
 .ServerScript or situation calls for clientNPC to be generated
 .server creates NPC info and appends ID to it. Attaching to table
 .Whenever functionality or checks occur said table is indexxed with unique_ID for confirmation/handling/replication

]]
