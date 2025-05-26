-- !nonstrict

--Overall, the main issue lay in the fact I was attempting to call this every frame/heartbeart. There was no true yielding and the function would just restart 
--regardless so there was little to be done there, It now seems much more efficient to use a seperate thread of our own. 
--Infact the only reason the QTFSM worked in the first place was due to the fact it had forced "transitions" in the form of durations.


warn("IS THIS THING RUNNING?")
--//Services
local repStorage =  game:GetService("ReplicatedStorage")
local runSRVC = game:GetService("RunService")
local pathFindingSRVC = game:GetService("PathfindingService")

--//Items 
--//Gorilla Anims 
local gorillaP1_Run = repStorage.GorillaAnims.Actions.gorillaPhase1_run
local gorillaP1_Idle =  repStorage.GorillaAnims.Actions.gorillaPhase1_idle

local gorillaP1_Punch1 = repStorage.GorillaAnims.Attacks.gorillaPhase1_punch1
local gorillaP1_Punch2 = repStorage.GorillaAnims.Attacks.gorillaPhase1_punch2
local gorillaP1_Sweep =  repStorage.GorillaAnims.Attacks.gorillaPhase1_sweep

local control = {}
control.__index = control

---| MODEL/METHODS

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
	Gorilla.Parent = game.Workspace
	Gorilla.Humanoid.HipHeight = 3.45
	Gorilla.Humanoid.WalkSpeed = 24
	Gorilla.PrimaryPart.CFrame = pos or CFrame.new(32, 56, -10)
	warn("Hip Height:", Gorilla.Humanoid.HipHeight)
	Gorilla.PrimaryPart:SetNetworkOwner(nil)
	
	local idleAnimaton: AnimationTrack = Gorilla.Humanoid.Animator:LoadAnimation(repStorage.GorillaAnims.Actions.gorillaPhase1_idle)
	idleAnimaton.Priority = Enum.AnimationPriority.Idle
	idleAnimaton:Play()
end

function blockedMovement(GorillaRoot, enemyModel)
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {workspace.PlayerFolder}
	rayParams.FilterType = Enum.RaycastFilterType.Include
	
	local rayResult = workspace:Raycast(GorillaRoot.Position, enemyModel.HumanoidRootPart.Position*5)
	if rayResult then 
			if rayResult.Instance and not rayResult.Instance:IsDescendantOf(workspace.PlayerFolder) then
				return true	
		end
	end
	return false
end

function locateEnemy(GorillaRoot: BasePart) --Model, Num
	local nearestEnemy, dist = nil, 50
	local distTable = {}
	
	for _, chara: Model in workspace.PlayerFolder:GetChildren() do 
		local root = chara.PrimaryPart
		 local rootDist = (root.Position - GorillaRoot.Position).Magnitude
		 if rootDist <= 50 then	
			warn("Player Within visible distance.")
			distTable[root.Parent] = rootDist
		end
	end
	for enemy, mag in distTable do 
		if mag <= dist then 
			dist = mag
			print("ENEMY:", enemy)
			nearestEnemy = enemy
		end
	end
		return nearestEnemy, dist
end

function distanceCheck(GorillaRoot: BasePart,enemyRoot: BasePart)
		return (enemyRoot.Position - GorillaRoot.Position).Magnitude
end

function moveTowards(GorillaRoot,enemyModel)
		warn("ENEMY MODEL?:", enemyModel)
		local enemyRoot = enemyModel.HumanoidRootPart
		local gorillaHum: Humanoid = GorillaRoot.Parent.Humanoid
		local gorillaAnim: Animator = gorillaHum.Animator
		local runAnimation: AnimationTrack = GorillaRoot.Parent.Humanoid.Animator:LoadAnimation(repStorage.GorillaAnims.Actions.gorillaPhase1_run)
		runAnimation.Priority = Enum.AnimationPriority.Movement
		
		local chargePath = pathFindingSRVC:CreatePath({AgentHeight = 8})
		local success, err = pcall(function()
			chargePath:ComputeAsync(GorillaRoot.Position, enemyModel.HumanoidRootPart.Position)
		end)
		
		local waypoints 
		
		if distanceCheck(GorillaRoot, enemyModel.HumanoidRootPart) < 10 then
			directMove(GorillaRoot,enemyRoot.Position)
			return "Attacking"
		end
		
		if success then 
			waypoints = chargePath:GetWaypoints()
			local animTracks = gorillaAnim:GetPlayingAnimationTracks() 
			for i, v in animTracks do 
				if v.Name == "gorillaPhase1_run" then
					v:Stop()
				end
			end
			
			runAnimation:Play()
			for i, point in  waypoints do
				if distanceCheck(GorillaRoot, enemyRoot) < 9 then
					directMove(GorillaRoot, enemyRoot.Position)
					runAnimation:Stop()
					return
				end
				
				gorillaHum:MoveTo(point.Position)
				
				gorillaHum.MoveToFinished:Wait()
				
				if waypoints[i+1] == nil then 
					runAnimation:Stop()
				end
				warn("Waypoint success")
			end
		else
			warn("PATH FAILED TO CALCULATE FROM", GorillaRoot.Parent, "to", enemyRoot.Parent)
		end--Pathfinding or Unit MoveTo | BOTH? | yes b/c If player moves too far it becomes naught.
		 --return true
end

function directMove(GorillaRoot: BasePart, position: Vector3)
	GorillaRoot.Parent.Humanoid:MoveTo(position)
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

	task.wait(math.random(2))
	runAnimation:Play()
	gorillaHum:MoveTo(Vector3.new(randX, 0, randZ))
--	gorillaHum.MoveToFinished:Wait()
	gorillaHum.MoveToFinished:Connect(function()
		runAnimation:Stop()
	end)
	--return warn("Movement Yield.")
end

type stateType = {
	Name: string;
	NextState:() -> any; --Enter_Next | Functions ONLY IF, different behavior to be added.
	StateAction:() -> boolean;
	Completed: () -> string;
}

local function attackMethod(GorillaRoot, enemyModel)--Now has to account for ranged Attacks
		warn("Gorilla is attacking:", enemyModel)
		return true 
end

---| STATE BEHAVIOR

function idleState_Action(GorillaRoot: BasePart)
	warn("Idle Began")
	local moved = idleMovement(GorillaRoot)
	local enemy, dist = locateEnemy(GorillaRoot)
	if enemy and dist then -- Chasing/Ranged range
		return "Charging" 
	end
end

function chargingState_Action(GorillaRoot: BasePart)
	local enemy = locateEnemy(GorillaRoot)
	local moveResult = moveTowards(GorillaRoot, enemy)
	
	if moveResult == "Attacking" then
		return "Attacking"
	end
	
	if  locateEnemy(GorillaRoot) then 
		return "Charging"
	end
end

function attackState_Action(GorillaRoot: BasePart)
		local enemy = locateEnemy(GorillaRoot)
		local attackResult = attackMethod(GorillaRoot, enemy)
		local enemyCheck, dist = locateEnemy(GorillaRoot)
		
		if enemyCheck and dist<10 then 
			return "Attacking"
		else
			return "Idle"
		end
end

 control.gorillaStates = {
	{--Idle | Default State
		Name = "Idle",
		
		NextState =  "Charging",--function(str: string) if str == "Charging" then return true end end,
		
		StateAction = idleState_Action, --func
		
		Completed = function()--Plays after state_finish set to true | Can/Should also behave as cleanup 
			warn("Idle Complete")
			return true
		end,
	},

	{--Charging | Chasing State
		Name = "Charging",
		
		NextState = "Attacking",
		
		StateAction = chargingState_Action,
		
		Completed = function()
				warn("Charging Complete")
				return true
		end,
	},

	{--Attack | Attack State, when within Radius use an attack.
		Name = "Attacking",

		NextState = "Attacking", --EnemyCheck if near then charge else idle.

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
		stateComplete  = true;
		
		lastRangeTime = nil;
		lastPunchTime = nil;
		punchCounter = nil;
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

function control:Progress()
	if self.currentState == nil then return end
	local current_state = self.currentState
	local current_state_table = self.states[self.currentState]
	local next_state: string? 
	
	 --Return of stateCompletion; can be nil or pointer to next state.
	local actionreturn_NextState = self.states[self.currentState].StateAction(self.root)
		
	if type(actionreturn_NextState) == type(string) then 
			self.stateComplete = true --set to true as a result.
			next_state =  actionreturn_NextState
	end
	
		if self.stateComplete then
			if current_state_table.Completed then 
				current_state_table.Completed()
			end 
		end
	
	self.currentState = next_state
	self.stateComplete = false
end

function control:Begin()
		self.stateThread = task.spawn(function()
			while task.wait(.1) do 
				if not self.stateComplete then return end 
				self.stateComplete = false
			--	warn("--PERFORMING STATE ACTION:")
				
				local nextState = self.states[self.currentState].StateAction(self.root)--Now we yield.
				
				if not nextState then 
			--		warn("--STATE ACTION ERROR, DEFAULTING--")
					nextState = self.currentState
				end
				
				self.currentState = nextState
				self.stateComplete = true
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
--Start

return control

--function control:Goto(state_name: string) --We'll return a goto next state here.
--	local old_state_name = self.currentState
--	local old_state: stateType = self.states[old_state_name]
--	local next_state: stateType = self.states[state_name]

--	if not next_state then return end 

--	local valid = true 
--	if next_state.Enter then --Enter function to determine valid-transition.
--		valid = next_state.Enter(old_state_name)
--	end

--	if valid then
--		self.currentState = state_name

--		if old_state.Completed then
--			old_state.Completed()	
--		end
--	else
--		self.currentState = old_state_name
--		warn("Failed transition.")
--	end
--end
