-- !strict

--Overall, the main issue lay in the fact I was attempting to call this every frame/heartbeart. There was no true yielding and the function would just restart 
--regardless so there was little to be done there, It now seems much more efficient to use a seperate thread of our own. 
--Infact the only reason the QTFSM worked in the first place was due to the fact it had forced "transitions" in the form of durations.


warn("IS THIS THING RUNNING?")
--//Services
local repStorage =  game:GetService("ReplicatedStorage")
local runSRVC = game:GetService("RunService")
local pathFindingSRVC = game:GetService("PathfindingService")

local replicaHNDLR = require(repStorage.Modules.Replica_Handler)
local replicaAnim = repStorage.Remotes.Replica_Animation
local replicaPause = repStorage.Remotes.Replica_AnimationStop
local replicaVFX = repStorage.Remotes.Replica_VFX

--//Items 
local attackMod = require(script.MonkeyAttacks)

--//Gorilla Anims 
local gorillaP1_Run = repStorage.GorillaAnims.Actions.gorillaPhase1_run
local gorillaP1_Idle =  repStorage.GorillaAnims.Actions.Phase1.gorillaPhase1_idle

local gorillaP1_Punch1 = repStorage.GorillaAnims.Attacks.Phase1.gorilla_punch1
local gorillaP1_Punch2 = repStorage.GorillaAnims.Attacks.Phase1.gorilla_punch2
local gorillaP1_Sweep =  repStorage.GorillaAnims.Attacks.Phase1.gorilla_sweep

local ATTACK_RANGE = 5
local SEARCH_RANGE = 80
local CHASE_RANGE = 15

local control = {}
control.__index = control

---| MODEL/METHODS
--[[
Searching/Idle: Locate Enemy/Wander around | Searching state should have an IDLE function as opposed to idle state. -> Pathing
Pathing: Path towards Enemy -> Moving
Moving: MoveTowards Enemy -> Attacking
Attacking: Attack Enemy -> Attacking|Searching
]]


function control.newGorilla()
	warn("Gorilla Formed")
	local GorillaModel = game:GetService("ServerStorage").Gorilla:Clone()
	GorillaModel.Name = "Gorilla_Grodd"
	GorillaModel.HumanoidRootPart.Anchored = false
	GorillaModel.Parent = repStorage
	return GorillaModel
end

function control.spawnGorilla(Gorilla, pos: CFrame)
	warn("Gorilla Spawn:", Gorilla)
	Gorilla.Parent = game.Workspace.GorillaFolder
	Gorilla.Humanoid.HipHeight = 3.45
	Gorilla.Humanoid.WalkSpeed = 20
	Gorilla.PrimaryPart.CFrame = pos or CFrame.new(32, 56, -10)
	warn("Hip Height:", Gorilla.Humanoid.HipHeight)
	Gorilla.PrimaryPart:SetNetworkOwner(nil)

	local idleAnimaton: AnimationTrack = Gorilla.Humanoid.Animator:LoadAnimation(repStorage.GorillaAnims.Actions.Phase1.gorillaPhase1_idle)
	idleAnimaton.Priority = Enum.AnimationPriority.Idle
	
	 --replicaAnim:FireAllClients(repStorage.GorillaAnims.Actions.Phase1.gorillaPhase1_idle)
	idleAnimaton:Play()
end

function blockedMovement(GorillaRoot, enemyModel)
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {workspace.PlayerFolder}
	rayParams.FilterType = Enum.RaycastFilterType.Include
	
	local enemyRoot = enemyModel.HumanoidRootPart :: BasePart

	local rayResult = workspace:Raycast(GorillaRoot.Position, enemyRoot.Position*5)
	if rayResult then 
		if rayResult.Instance and not rayResult.Instance:IsDescendantOf(workspace.PlayerFolder) then
			return true	
		end
	end
	return false
end

function locateNearestEnemy(GorillaRoot: BasePart): BasePart
	local nearestEnemy, dist = nil
	local distTable = {}

	if #workspace.PlayerFolder:GetChildren() > 0 then
		for _, chara: Model in workspace.PlayerFolder:GetChildren() do 
			local root = chara.PrimaryPart :: BasePart
			local rootDist = (root.Position - GorillaRoot.Position).Magnitude
			if rootDist <= SEARCH_RANGE then	
				warn("Player Within visible distance.")
				table.insert(distTable, root)
			end
		end
	
		--All these will be at minimum 50 studs in range. 	
		table.sort(distTable, function(a: BasePart, b: BasePart) return (GorillaRoot.Position - a.Position).Magnitude < (GorillaRoot.Parent - b.Position).Magnitude  end )
	
		return distTable[1]
	end
	
	return nil
end

function distanceCheck(GorillaRoot: BasePart, enemyModel: Model): number
	return (enemyModel.PrimaryPart.Position - GorillaRoot.Position).Magnitude
end

function pathTowards(GorillaRoot,enemyModel): string
	warn("ENEMY MODEL?:", enemyModel)
	if enemyModel == nil then 
		return "Searching"
	end

	local enemyRoot = enemyModel.HumanoidRootPart
	local gorillaHum: Humanoid = GorillaRoot.Parent.Humanoid
	local gorillaAnim: Animator = gorillaHum.Animator
	gorillaHum.WalkSpeed = 32
	
	local runAnimation: AnimationTrack = GorillaRoot.Parent.Humanoid.Animator:LoadAnimation(repStorage.GorillaAnims.Actions.gorillaPhase1_run)
	runAnimation.Priority = Enum.AnimationPriority.Movement

	local chargePath = pathFindingSRVC:CreatePath({AgentHeight = 8})
	local success, err = pcall(function()
		chargePath:ComputeAsync(GorillaRoot.Position, enemyModel.HumanoidRootPart.Position)
	end)

	local waypoints 

	if success then 
		waypoints = chargePath:GetWaypoints()
		
		if #waypoints < 3 then
			return "Moving"
		end
		
		runAnimation:Play()
		
		for i, point: PathWaypoint in ipairs(waypoints) do
			gorillaHum:MoveTo(point.Position)
		
			if enemyModel.Humanoid.Health < 1 or not enemyRoot then  runAnimation:Stop() return "Searching" end 
			
			if (enemyRoot.Position - waypoints[#waypoints].Position).Magnitude > 30 then
				warn("Target too far, Recalculating.")
				runAnimation:Stop()
				return "Searching" 
			end
			
			if i >= 5 and (GorillaRoot.Position - enemyRoot.Position).Magnitude < 30 then-- If we're 5 in and less than 
				warn("Within attack range")
				runAnimation:Stop()
				return "Moving"
			end
			
			gorillaHum.MoveToFinished:Wait()
		end
		warn("This shouldn't be reachable.")
	else
		warn("Path calculation failed.")
		return "Searching"
	end
end

function directMove(GorillaRoot: BasePart, enemyModel: Model): string
	while distanceCheck(GorillaRoot, enemyModel) > 3 and distanceCheck(GorillaRoot, enemyModel)< 30 do
				GorillaRoot.Parent.Humanoid:MoveTo(enemyModel.PrimaryPart.Position)
				if distanceCheck(GorillaRoot, enemyModel) < 5 then
					return "Attacking"
				end
				
				if locateNearestEnemy(GorillaRoot).Parent ~= enemyModel then
					return "Searching"
				end
		end
end

function idleMovement(GorillaRoot: BasePart)--Load animations in state?
	local randX = math.random(GorillaRoot.Position.X-15,GorillaRoot.Position.X+15)
	local randZ = math.random(GorillaRoot.Position.Z-15,GorillaRoot.Position.Z+15)

	local gorillaModel = GorillaRoot.Parent :: Model
	local gorillaHum = gorillaModel.Humanoid :: Humanoid
	local gorillaAnimator:Animator = gorillaHum.Animator 

	local runAnimation: AnimationTrack = gorillaAnimator:LoadAnimation(repStorage.GorillaAnims.Actions.gorillaPhase1_run)
	runAnimation.Priority = Enum.AnimationPriority.Movement

	--Outfit with pathfinding if seen fit.
	--replicaAnim:FireAllClients(repStorage.GorillaAnims.Actions.gorillaPhase1_run)
	runAnimation:Play()
	gorillaHum:MoveTo(Vector3.new(randX, 0, randZ))
	gorillaHum.MoveToFinished:Connect(runAnimation:Stop())
	--return warn("Movement Yield.")
end

type stateType = {
	Name: string;
	NextState:() -> any; --Enter_Next | Functions ONLY IF, different behavior to be added.
	StateAction:() -> boolean;
	Completed: () -> string;
}

--| ATTACK DEPENDENCIES

function control:gorillaStagger()
	local stagger = task.spawn(function()
			self.stagger = true
			--Stagger Animation play, Highlight to signify
			task.wait(10)
			--Stagger Stop.
			self.stagger = false
	end)
end

function control:attackHandle()
	
end

function attackMethod(GorillaRoot, enemyModel)--Now has to account for ranged Attacks | Likely to be replaced.
	warn("Gorilla is attacking:", enemyModel)
end

---| STATE BEHAVIOR
function searchingState_Action(GorillaRoot: BasePart)
	if locateNearestEnemy(GorillaRoot) then
		return "Pathing"
	else
		idleMovement(GorillaRoot)
	end
end

function pathingState_Action(GorillaRoot: BasePart)
		local enemy = locateNearestEnemy(GorillaRoot)
		if enemy then 
			pathTowards(GorillaRoot, enemy)
		else
			return "Searching"
		end
end

function movingState_Action(GorillaRoot: BasePart)
		
end

function attackState_Action(GorillaRoot: BasePart)

end

control.gorillaStates = {
	{--Idle | Default State
		Name = "Searching",

		NextState =  "Pathing",--function(str: string) if str == "Charging" then return true end end,

		StateAction = searchingState_Action, --func

		Completed = function()--Plays after state_finish set to true | Can/Should also behave as cleanup 
			warn("Idle Complete")
			return true
		end,
	},

	{--Pathing | just pathfind to them
		Name = "Pathing",

		NextState = "Moving",

		StateAction = pathingState_Action,

		Completed = function()
			warn("Charging Complete")
			return true
		end,
	},

	{--Attack | Attack State, when within Radius use an attack.
		Name = "Attacking",

		NextState = "Attacking/Searching", --EnemyCheck if near then charge else idle.

		StateAction = attackState_Action,

		Completed = function()
			warn("Attack Complete")
		end,
	},

}
---| STATE_MACHINE

function control.create_StateMachine(NPC)
	local self = setmetatable({
		gorilla = NPC;
		humanoid = NPC.Humanoid;
		root = NPC.HumanoidRootPart; 
		stateThread = nil;

		animator = NPC.Humanoid.Animator;
		states = {}; --Given States
		currentState = nil :: string?;

		lastRangeTime = nil;
		lastPunchTime = nil;
		punchCounter = nil;
		stagger = false;
		--Animator = NPC.Humanoid.Animator;
		--idleAnim = NPC.Humanoid.Animator:LoadAnimation(gorillaP1_Idle);
		--runAnim = NPC.Humanoid.Animator:LoadAnimation(gorillaP1_Run);
	},control)
	return self
end

function control:defineStates(states: {stateType})
	for _, state in states do 
		self.states[state.Name] = state
	end 

	self.currentState = states[1].Name
end

function control:Begin()
	self.stateThread = task.spawn(function()
		while task.wait(.01) do
			local nextState = self.states[self.currentState].StateAction(self.root)--Now we yield.

			if not nextState then 
				nextState = self.currentState
			end

			warn("TRANSITIONED FROM:", self.currentState, "to", nextState)
			self.currentState = nextState
		end	
	end)
end

function control:Stop()
	self.stateThread = nil
	warn("ABRUPT STATE STOP")
end

local gorilla = control.newGorilla()
control.spawnGorilla(gorilla)

local gorillaFSM = control.create_StateMachine(gorilla)
gorillaFSM:defineStates(control.gorillaStates)

gorillaFSM:Begin()

return control
