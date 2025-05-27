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

local ATTACK_RANGE = 6
local SEARCH_RANGE = 80
local CHASE_RANGE = 15

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
	Gorilla.Humanoid.WalkSpeed = 20
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

function locateEnemy(GorillaRoot: BasePart): Model --Model, Num
	local nearestEnemy, dist = nil, 80
	local distTable = {}
	
	if workspace.PlayerFolder:GetChildren() then
			for _, chara: Model in workspace.PlayerFolder:GetChildren() do 
				local root = chara.PrimaryPart
				 local rootDist = (root.Position - GorillaRoot.Position).Magnitude
				 if rootDist <= SEARCH_RANGE then	
					--warn("Player Within visible distance.")
					distTable[root.Parent] = rootDist
				end
			end
	for enemy, mag in distTable do 
		if mag <= dist then 
			dist = mag
			--print("NEAREST ENEMY:", enemy)
			nearestEnemy = enemy
		end
	end
		return nearestEnemy, dist
	end
	return nil, nil
end

function distanceCheck(GorillaRoot: BasePart,enemyRoot: BasePart): number
		return (enemyRoot.Position - GorillaRoot.Position).Magnitude
end

function moveTowards(GorillaRoot,enemyModel): string
	warn("ENEMY MODEL?:", enemyModel)
		if enemyModel == nil then 
			return "Idle"
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
			local animTracks = gorillaAnim:GetPlayingAnimationTracks() 
			
		if #waypoints <= 2 and math.abs((waypoints[1].Position.Y - GorillaRoot.Position.Y)) < 5  then
			warn("WAYPOINTS TOO SMALL, RUSHING")
			return "Rush"
		end
	
			for i, v in animTracks do 
				if v.Name == "gorillaPhase1_run" then
					v:Stop()
				end
			end
			
		runAnimation:Play()
		
		print("NUMBER OF POINTS:", #waypoints)
		for i, point in  waypoints do
				gorillaHum:MoveTo(point.Position)
				gorillaHum.MoveToFinished:Wait()
			
			if (enemyRoot.Position - waypoints[#waypoints].Position).Magnitude > 20 then 
				warn("TARGET HAS STRAYED TOO FAR RE-CALCING.")
				runAnimation:Stop()
				return "Charging"
			end
			
				if distanceCheck(GorillaRoot, enemyRoot) < 10 then
					runAnimation:Stop()
					warn("CLOSE ENOUGH, RETURNING ATTACK/RUSH FROM CHARGE")
					return "Rush"
				end
		end
		runAnimation:Stop()
		warn("Path Completed with no returns")
		return "Charging"
		else
			warn("PATH FAILED TO CALCULATE FROM", GorillaRoot.Parent, "to", enemyRoot.Parent)
			return "Idle"
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
end

---| STATE BEHAVIOR

function idleState_Action(GorillaRoot: BasePart)
	warn("Idle Began")
	local moved = idleMovement(GorillaRoot)
	local enemy, dist = locateEnemy(GorillaRoot)
	if enemy and dist < 50 then -- Chasing/Ranged range
		return "Charging" 
	end
	return "Idle"
end

function chargingState_Action(GorillaRoot: BasePart)
	local enemy, dist = locateEnemy(GorillaRoot)
	local moveResult
	
	if dist < 50 then 
		moveResult = moveTowards(GorillaRoot, enemy)
	end
	
	if moveResult == "Idle" then
		warn("CHARGING RETURNING: IDLE")
		return "Idle"
	end
	
	if moveResult == "Rush" then
		warn("CHARGING RETURNING: RUSH")
		return "Rush"
	end
	

	if locateEnemy(GorillaRoot) then 
		return "Charging"
	else
		return "Idle"
	end
end

function attackState_Action(GorillaRoot: BasePart)
		local enemy, dist = locateEnemy(GorillaRoot)
		local attackResult = attackMethod(GorillaRoot, enemy)
		warn("Attack called", enemy)	
	
		if enemy and dist <= 5 then
			return "Attacking"
		end
	
	_, dist = locateEnemy(GorillaRoot) 
	
	if enemy and dist > 3 or dist < 15 then
		return "Rush"
	else if enemy and dist > 20 and dist < 50 then
			return "Charging"
		end
	end		
 return "Idle"
end

function rushState_Action(GorillaRoot: BasePart)
	local enemyModel, dist = locateEnemy(GorillaRoot)
	local GorillaHum = GorillaRoot.Parent.Humanoid :: Humanoid
	local GorillaAnimator = GorillaHum.Animator :: Animator
	GorillaHum.WalkSpeed = 32
	
	local runAnimation: AnimationTrack = GorillaAnimator:LoadAnimation(gorillaP1_Run)
	runAnimation.Priority = Enum.AnimationPriority.Movement
	
	if dist <= 5 then
		return "Attacking"
	end
	
	runAnimation:Play()
	while dist < 25 and enemyModel and enemyModel.Humanoid.Health > 0 do 
		enemyModel, dist = locateEnemy(GorillaRoot)
		GorillaHum:MoveTo(enemyModel.PrimaryPart.Position)
		GorillaHum.MoveToFinished:Wait()
		enemyModel, dist = locateEnemy(GorillaRoot)
		if dist < 5 then
			GorillaHum.WalkSpeed = 20
			runAnimation:Stop()
			return "Attacking"
		end
	end
	
	if locateEnemy(GorillaRoot) then 
		runAnimation:Stop()
		return "Charging"
	else
		runAnimation:Stop()
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

		NextState = "Idle", --EnemyCheck if near then charge else idle.

		StateAction = attackState_Action,

		Completed = function()
			warn("Attack Complete")
		end,
	},
	
	{--Rush | Managing rush behavior in charge proving complex, test attempt
		Name = "Rush",

		NextState = "Attacking", --EnemyCheck if near then charge else idle.

		StateAction = rushState_Action,

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
			while task.wait(.01) do 
			--	warn("--PERFORMING STATE ACTION:")
				
					local nextState = self.states[self.currentState].StateAction(self.root)--Now we yield.
				
					if not nextState then 
			--		warn("--STATE ACTION ERROR, DEFAULTING--")
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
