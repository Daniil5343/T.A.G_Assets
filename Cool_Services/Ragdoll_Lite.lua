local physicsServ = game:GetService("PhysicsService")
local collisionPart = game.ReplicatedStorage.Stuff.CollisionPart
local players = game:GetService("Players")
local ragRemote = game:GetService("ReplicatedStorage").Remotes.RagDeath

local jointList = require(script.JointSettings) --settings list which is TBA.
local COLLISION_SCALE = .7

--local characterCollisions = physicsServ:RegisterCollisionGroup("Character")
--local collideCollision = physicsServ:RegisterCollisionGroup("Collide")

local ragdoll = {}
ragdoll.__index = ragdoll

--On account of platformstand killing the humanoid death pipeline, we need to have the server "wakeup" to it.
ragRemote.OnServerEvent:Connect(function(plr)
	warn("NeckSplit")
	local char = plr.Character
	char.Humanoid.PlatformStand = false
end)

function ragdoll:SetUp()
	local partFolder = Instance.new("Folder")
	partFolder.Name = "Parts"
	partFolder.Parent = self.Character
	local constFolder = Instance.new("Folder")
	constFolder.Name = "Balls"
	constFolder.Parent = self.Character

	local hun = self.Character:FindFirstChild("Humanoid") :: Humanoid
	hun.BreakJointsOnDeath = false
	
	--Construct Collision.
	for _, v in self.Character:GetDescendants() do 
		if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
			local COLLISION_SCALE = .7
			local collisionPart = Instance.new("Part")
			collisionPart.CanCollide = false
			collisionPart.Massless = true
			collisionPart.Name = "Collide" 
			collisionPart.Transparency = .65
			collisionPart.Color = Color3.new(1,0,0)
			collisionPart.Size = Vector3.new(v.Size.X * COLLISION_SCALE, v.Size.Y * COLLISION_SCALE, v.Size.Z* COLLISION_SCALE)
			collisionPart.Parent = self.Character["Parts"]
			print("DONE")

			collisionPart.CollisionGroup = "collideCollision"

			local weld = Instance.new("Weld")
			weld.Parent = v
			weld.Name = "collideWeld"
			weld.Part0 = v
			weld.Part1 = collisionPart
		end
	end
	
	--Construct BallSockets.
	for ind, motor in self.Character:GetDescendants() do 
		if not motor:IsA("Motor6D") then continue end 

		local ballSocket = Instance.new("BallSocketConstraint")
		ballSocket.Parent = constFolder
		ballSocket.Name = "Ball_"..motor.Name
		ballSocket.Enabled = false

		local att0 = Instance.new("Attachment")
		att0.Parent = motor.Part0
		att0.Name = "A0"
		att0.CFrame = motor.C0

		local att1 = Instance.new("Attachment")
		att1.Parent = motor.Part1
		att1.Name = "A1"
		att1.CFrame = motor.C1

		ballSocket.Attachment0 = att0
		ballSocket.Attachment1 = att1

		ballSocket.LimitsEnabled = true
		ballSocket.TwistLimitsEnabled =true

		ballSocket.UpperAngle = 45
		ballSocket.TwistLowerAngle = -90
		ballSocket.TwistUpperAngle = 90
		ballSocket.MaxFrictionTorque = 5
	end
end

function ragdoll.new(CharModel: Model)
		local self = setmetatable({
		Character = CharModel,
		root = CharModel:FindFirstChild("HumanoidRootPart") :: BasePart,	
		hum = CharModel:FindFirstChildOfClass("Humanoid") :: Humanoid,
		ragdolled = false :: boolean,
		--Signal?
		}, ragdoll);
		
		--SetUp parts/colliders function.
		 (function()
			local partFolder = Instance.new("Folder")
			partFolder.Name = "Parts"
			partFolder.Parent = self.Character
			local constFolder = Instance.new("Folder")
			constFolder.Name = "Balls"
			constFolder.Parent = self.Character

			local hun = self.Character:FindFirstChild("Humanoid") :: Humanoid
			hun.BreakJointsOnDeath = false

			--Construct Collision.
			for _, v in self.Character:GetDescendants() do 
				if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
					local COLLISION_SCALE = .7
					local collisionPart = Instance.new("Part")
					collisionPart.CanCollide = false
					collisionPart.Massless = true
					collisionPart.Name = "Collide" 
					collisionPart.Transparency = .65
					collisionPart.Color = Color3.new(1,0,0)
					collisionPart.Size = Vector3.new(v.Size.X * COLLISION_SCALE, v.Size.Y * COLLISION_SCALE, v.Size.Z* COLLISION_SCALE)
					collisionPart.Parent = self.Character["Parts"]
					print("DONE")

					collisionPart.CollisionGroup = "collideCollision"

					local weld = Instance.new("Weld")
					weld.Parent = v
					weld.Name = "collideWeld"
					weld.Part0 = v
					weld.Part1 = collisionPart
				end
			end

			--Construct BallSockets.
			for ind, motor in self.Character:GetDescendants() do 
				if not motor:IsA("Motor6D") then continue end 

				local ballSocket = Instance.new("BallSocketConstraint")
				ballSocket.Parent = constFolder
				ballSocket.Name = "Ball_"..motor.Name
				ballSocket.Enabled = false

				local att0 = Instance.new("Attachment")
				att0.Parent = motor.Part0
				att0.Name = "A0"
				att0.CFrame = motor.C0

				local att1 = Instance.new("Attachment")
				att1.Parent = motor.Part1
				att1.Name = "A1"
				att1.CFrame = motor.C1

				ballSocket.Attachment0 = att0
				ballSocket.Attachment1 = att1

				ballSocket.LimitsEnabled = true
				ballSocket.TwistLimitsEnabled =true

				ballSocket.UpperAngle = 45
				ballSocket.TwistLowerAngle = -90
				ballSocket.TwistUpperAngle = 90
				ballSocket.MaxFrictionTorque = 5
			end
		 end)()
		 
		 --Store the reference but return for immediate use.
		ragdoll[CharModel] = self
		return self
end

function ragdoll:Toggle(bool: boolean, timeWait: number)
	local camera: Camera = workspace.Camera
	local constFolder = self.Character:FindFirstChild("Balls")
	local partFolder = self.Character:FindFirstChild("Parts")	
	local hum: Humanoid = self.Character:FindFirstChildOfClass("Humanoid")

	if not constFolder then return end 
	
	local function partLoops(invBool: boolean)
		for ind, val in constFolder:GetChildren() do 
			if val:IsA("BallSocketConstraint") then
				warn("BallSocket:", bool,"BallEnabled", val.Enabled, "InvBool:", invBool)
				val.Enabled = invBool or bool 
			end
		end

		--Motor6Ds
		for ind, val in self.Character:GetDescendants() do 
			if val:IsA("Motor6D") then
				warn("MOTOR7D:", bool, val.Enabled, invBool)
				val.Enabled =   not val.Enabled
				print("So:",val.Enabled, invBool)
			end
		end
		
		--Playerparts
		for ind, val: BasePart in self.Character:GetChildren() do 
			if val:IsA("BasePart") then
				val.CanCollide = not val.CanCollide
			end
		end

		--CollisionParts
		for ind, val: BasePart in partFolder:GetChildren() do 
			val.CanCollide = not val.CanCollide
		end
	warn("Bool:", bool, "NotBool:", not bool)
	end
	
	partLoops()
	
	if timeWait then 
		hum.PlatformStand = true
		self.Character:SetAttribute("Ragdoll", bool)
		task.wait(timeWait)
		partLoops(not bool)
		hum.PlatformStand = false
	else
		hum.PlatformStand =  bool
	end
end

--function ragdoll.onPlrAdded(plr: Player): ()
--	plr.CharacterAppearanceLoaded:Connect(ragdoll.new)
--end

--players.PlayerAdded:Connect(ragdoll.onPlrAdded)

return ragdoll
