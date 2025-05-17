local radiusEvent = game.ReplicatedStorage.Events.RadiusEvent
local clientRemote = game.ReplicatedStorage.Events.clientRemote
local radiusEvent_Global = game.ReplicatedStorage.Events.globalRadiusEvent

local ID_Generator = require(game.ReplicatedStorage.Modules.RandomID_Generator)
local GoodSignal = require(script.GoodSignal)
local replicationHandler = require(game.ReplicatedStorage.Modules.clientNPC_Generator.replicationHandler)

local partDebounceTable = {} --Remake to npcDebounceTable, indexes based on Gen_ID
local radiusNPCTable = {}--Table containing NPCs (or NPC_IDs) which allows the server to know which NPCs are connected

local debounceTimer = 1.5
local constructorVisible: boolean = true
local constructorTransparency: number = .65
local constructorMaterial =  Enum.Material.Neon
local coolColors = {
	novaKin = Color3.new(1, 0, .6),
	coolBlue = Color3.new(0, 0.69, 1),
	iceBlue = Color3.new(.45, .7, 1),
}


local constructorColor_Default: Color3 = coolColors.novaKin

local react = {}
react.__index = react

--|-Communication Server <---> Client|---

--Integrate this to work as a method of the radiusObject.
react.ClientInteracted = function(self ,Client: Player, NPC: Model, Enter: boolean) -- For INCOMING data silly
		local Animator = NPC:FindFirstChild("Humanoid").Animator 
		local shopAnims = {}--We'd probably reach to the server to set that attribute but whatever
		shopAnims.Idle = {NPC.DefaultAnim1, NPC.DefaultAnim2}
		shopAnims.Entered =  {NPC.shopAnim1, NPC.shopAnim2, NPC.shopAnim3}
		shopAnims.Leaving =  {NPC.shopLeave1, NPC.shopLeave2}
		
		local shopVisibility = NPC.shopVisibility.Value
		local nearPlayers = {}--Index may be truly random is our only issue
		
	if not self.activeList[Client] then 
			if partDebounceTable[NPC] then return end --if it's in the debounce piss off!
			partDebounceTable[NPC] = NPC
		
		local newAnim = Random.new():NextInteger(1, #shopAnims.Entered)
		local ChosenAnim = shopAnims.Entered[newAnim]
		
		local playerRadius = Client.Character.Position
		
			for ind , player in game.Players do 
					if (player.Character.Position - playerRadius).Magnitude <= shopVisibility then
							nearPlayers[ind] = player
					end
			end
				
			for  _, player in nearPlayers do 
				clientRemote:FireClient(player,NPC, newAnim, shopAnims, true)
			end				
			
			task.delay(debounceTimer, function()
					partDebounceTable[NPC] = nil
			end)--Okay this should go by the basis of ending the animations based on their time but!
			
	else--
		
		if partDebounceTable[NPC]  then return end --if it's in the debounce don't re-bother
			partDebounceTable[NPC] = NPC

			local newAnim = Random.new():NextInteger(1, #shopAnims.Leaving)
			local ChosenAnim = shopAnims.Leaving[newAnim] --oh wait when did I do this lol

			local playerRadius = Client.Character.Position

			for ind , player in game.Players do 
				if (player.Character.Position - playerRadius).Magnitude <= shopVisibility then
					nearPlayers[ind] = player
				end
			end

			for _, player in nearPlayers do 
				clientRemote:FireClient(player,NPC, newAnim, shopAnims, false)
			end		
		end		
end

---|Literal Animators|---

react.AnimPlay = function(NPC, newAnim, animList)
		local Animator: Animator = NPC:FindFirstChild("Humanoid").Animator
		local newTrack = Animator:LoadAnimation(animList.Entered[newAnim])
		newTrack:Play()--Welcome! / EnterAnim
end

react.AnimHalt = function(NPC, newAnim, animList)
	
	local Animator: Animator = NPC:FindFirstChild("Humanoid").Animator
	local tracksTable = Animator:GetPlayingAnimationTracks()
	
	local genDefault = Random.new():NextInteger(1, #animList.Idle)	
	
	local leavingTrack = Animator:LoadAnimation(animList.Leaving[newAnim])
	leavingTrack:Play()--Goodbye! / ExitAnim
	
	for _, animation: Animation in tracksTable do 
		if string.match(animation.Name, "Idle") then 
			animation:Stop()
		end
	end
		
	leavingTrack.Stopped:Connect(function()
			local newDefaultTrack = Animator:LoadAnimation(animList.Idle[genDefault])
			newDefaultTrack:Play() --  Default/ IdleAnim, this should be looped.
	end)	
end

react.ClientRecieved = function(NPC, newAnim, animList, Enter: boolean)
		if Enter then 
			react.AnimPlay(NPC, newAnim, animList)
		else
			react.AnimHalt(NPC, newAnim, animList)
		end		
end

---|Constructor and Handlers|---


--Values to table throw:	1.Visible: key,	2.Color, 2.Material ,3.Transparency, 4.Shape
react.newRadius_Continuous = function(NPC, Radius: number,visibilityTable: table, overlapTable: table )--take a radius focused on a part and play a specific animation for them
	warn("RadiusCheck:", NPC)
	table.insert(radiusNPCTable, replicationHandler.verifiedNPCs[NPC.ID]) --> We NEED ID for this stuff, these NPCs literally won't exist on the server. a special class of  "tempNPC"
	
	local self = setmetatable({}, react)
	
	local ID = NPC.ID
	local NPC = NPC.newNPC --We just needed to get the ID first and foremost
	warn("NPC Check:", NPC)
	--Global works for the spatialQuery to be interactable by multiplt clients?

	self.NPC = NPC
	
	local defaultParams = OverlapParams.new()
	defaultParams.FilterType = Enum.RaycastFilterType.Exclude
	defaultParams.FilterDescendantsInstances = {NPC, game.Workspace.Baseplate}
	
	self.npcCenter = NPC:FindFirstChild("HumanoidRootPart").Position	
	self.Key = ID or nil--bindable event for replicating to Server from client for radiusEvents (spawning SS NPC)
	self.Touched = GoodSignal.new()
	--self.global = Global or false --Can be interacted with by npcs/exists on the server as a whole. Not needed now we're using SQ's
	self.Counter = 0
	self.counterFunction = nil --If a counter function is provided insert it here, also dependent on Global variable as well | Require/Spawn stuff serv
	
	self.radiusPosition = NPC:FindFirstChild("HumanoidRootPart").Position	
	self.radius = Radius
	self.radiusSize = Vector3.new(Radius, Radius, Radius)
	self.overlapTable = overlapTable or defaultParams
	self.activeList = {}

	if constructorVisible or visibilityTable.visible then			
			self.interactionZone = Instance.new("Part")  --> this has to be fired to all clients so they can recieve it and construct it themselves. the deb is stored on the server so it can't be abused regardless
			self.interactionZone.CastShadow = false
			self.interactionZone.Name = self.Key
			self.interactionZone.Material = constructorMaterial or visibilityTable.Material   
			self.interactionZone.Transparency = constructorTransparency or visibilityTable.Transparency 
			
			self.interactionZone.Size = self.radiusSize * 2 --Radius is 1/2(diam)
			self.interactionZone.Shape = Enum.PartType.Ball
	
			self.radiusWeld = Instance.new("WeldConstraint")
			self.radiusWeld.Part0 = self.interactionZone
			self.radiusWeld.Part1 = NPC:FindFirstChild("HumanoidRootPart")
				
			self.interactionZone.CanCollide = false
			self.interactionZone.Position = NPC:FindFirstChild("HumanoidRootPart").Position	
			self.interactionZone.Parent = NPC.HumanoidRootPart
			self.radiusWeld.Parent = self.interactionZone
	
	if visibilityTable then
		if typeof(visibilityTable.color) == "Color3" then
				self.interactionZone.Color =  visibilityTable.color or constructorColor_Default
		elseif type(visibilityTable.color) == "string" then 
				self.interactionZone.Color = coolColors[visibilityTable.color] or constructorColor_Default
			else		
				warn("radiusColor type:", typeof(visibilityTable.color), "invalid. Use a number or indexName, switching to default [Novakin].")
				self.interactionZone.Color = constructorColor_Default
			end		
			else
				self.interactionZone.Transparency = 1
			end
	else
		self.interactionZone.Color = constructorColor_Default
	end

	return self
	
end--Since this is a server event it creates a di

react.Cast = function(self, waitPeriod: number)
	warn("Thread created")
		local thread = task.spawn(function() 
			while true do 
				self.radiusPosition = self.NPC.HumanoidRootPart.Position
				
				local partsinRadius = workspace:GetPartBoundsInRadius(self.radiusPosition, self.radius, self.overlapTable)
				local partCheckTable = {}
				print(partsinRadius)
				for _, object in partsinRadius do
					
					if  table.find(partCheckTable, object.Parent) then 
						continue 
					else
						table.insert(partCheckTable, object.Parent)
						
						if game.Players:GetPlayerFromCharacter(object.Parent) then
								self.Touched:Fire(object.Parent)
								warn("Event Successfully fired")
						end
					end		
				end
				task.wait(waitPeriod or .1)
			end
		end)
		
		return function()
			task.cancel(thread)
			self.Touched:DisconnectAll()
			self.interactionZone:destroy()
			warn("Thread cancelled")
		end
end
--[[This should look like:
local radiusThread = newRadius:Cast()
--.Touched:Connect(function stuff) and finished with item
radiusThread()
]]

--NOT NEEDED: Direct Reference on NPC.pos index supercedes and is more efficient.
react.radiusUpdate = function(self, frequency) --Higher frequency for higher movements.
	local radiusUpdate = task.spawn(function()
		while true do 
			self.radiusPosition = self.NPC.Position
		task.wait(frequency or .1)
		end
	end)
	
	return function()
		task.cancel(radiusUpdate)
		game.Debris:AddItem(self.interactionZone)
	end
end

react.radiusAdjust = function(self, desiredRadius, tweenTime)
	
 if self.Global then 
	
	if tweenTime then
			
	end
	
 else
			self.radiusSize = Vector3.new(desiredRadius, desiredRadius, desiredRadius)
		end
	
end

react.radiusTimer = function(self, limit: number)
		
end

--Depending on how far this goes it could be possible to make a "radiusAdjust type thing" for use in attacks and such, this could be derived into attackPresets as a class for secondary phases and such
--This could also work well for dynamic NPCs "I'm scared go away..." with an adjusted radius.
return react


--[[We need:

1.To create unique IDs
2.To :Attribute() to NPCs (Server or Client)
3.To FireToClients
4.Create simple threads containing magnitude checks which are logically equivalent to .Touched:()
5.Only fire these when Player is detected to be in range 
]]

--[[
react.newRadius_Stationary = function(NPC: Model, Radius: number, Global: boolean, counter, visible, color)--take a radius focused on a part and play a specific animation for them
	local self = setmetatable({}, react)
	self. npcCenter = NPC:FindFirstChild("HumanoidRootPart").Position	

	self.interactionZone = Instance.new("Part")  --> this has to be fired to all clients so they can recieve it. the deb is stored on the server so it can't be abused regardless
	self.interactionZone.Size = Vector3.new(Radius, Radius, Radius)
	self.interactionZone.Shape = Enum.PartType.Ball
	
	if constructorVisible or visible then
		self.interactionZone.Material = constructorMaterial
		self.interactionZone.Transparency = constructorTransparency
		self.interactionZone.Color = coolColors[color] or constructorColor_Default
	else
		self.interactionZone.Transparency = 1
	end
	
	self.interactionZone.CanCollide = false
	self.interactionZone.Position = self.npcCenter
	self.interactionZone.Parent = NPC.HumanoidRootPart
	
	return self
end--Since this is a server event it creates a 
]]
