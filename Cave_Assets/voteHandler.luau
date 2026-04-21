--//Services|<.\:/.>|
local replicatedStorage = game:GetService("ReplicatedStorage")
local eventHandler = require(game.ServerScriptService.CaveServerScripts.eventHandler)
local partyService =  require(game.ServerScriptService.CaveServerScripts.PartyService)
--Implement things like auto-skip text, anonymous voting, etc.

--//Functions 
local totalActivePlayersFn = partyService.GetPartyPlayers -- Dot notation with no object.

--//Items
local remotes = replicatedStorage.Remotes
local voteBool= remotes.interactionEvents.voteBool
local voteMulti = remotes.interactionEvents.voteMulti
local gameVoteStyle --Require(Settings.Anonymynity.Settings.Heads)


--//Singletons|Types
type Event = eventHandler.Event
local dead = "dead"

--[[VOTING TYPES:
	Events:
	 --NightRest | Explore 
	 -- UI LIST -> Options.
	Singleton:
	 	--Explore| Detour|NPC 
]]

--[[ currArchitecture

responded:
{
	[playerObject.UserID] = choiceNameString,
}

options: [1] = "optionName".."event descriptor"
{
	[1] = "Option#_Descriptor"
	[2] = "Option#_Descriptor"
	[3] = "Option#_Descriptor"
	[4] = "Option#_Descriptor"
}
]]


--split function.
local vote = {}

local function voteRequest(eventName)
	--Bring up dynamic vote menu.
end

--Checks if variant criteria is fulfilled.
local function variantPullCheck(event, RNGchance) --| UNIMPLEMENTED TBAS
	--if success then Splash spin text, "EVENT VARIANT"
	--Check conditionals of variant (randomly chosen)
	--refresh and freeze UI to variant
	
	if RNGchance >= event.variantChance then
		return nil --For now.
	else
		return nil
	end
end

--Checks if all active players have voted | Due to NPCs, this will be updated to use the literal instances instead of #'s'
local function fullVoteCheck(responseTable, totalActivePlayers: {Players} | number) : boolean
	if #responseTable == totalActivePlayers then
		return true
	end
end

--Quantifies all voted options, returns mostvoted option unless tied. | Will also display # maybe
local function mostVoted(optionList) : string
	local mostVoted = 0 
	local votes = {}
	local tieTable = {}
	local chosenOption
	
	for player, voteOption in optionList do 
		if votes[voteOption] == nil then
			votes[voteOption] = 0
		end
		votes[voteOption] += 1 
	end

		for option, votes in pairs(votes) do
			if votes > mostVoted then --Can tech error.
				mostVoted = votes
				chosenOption = option
			elseif votes == mostVoted then
				table.insert(tieTable, option)
			end
		end
		
		--Select a random event if tied.
		if #tieTable > 0 then
			warn("tied vote")
			chosenOption = tieTable[math.random(1, #tieTable)]
		end
		return chosenOption
end

--Splits votes from full text into choicePart ("Resist_Resist And Run" -> "Resist") 
function vote.choiceSplit(choiceString: string): string
	local optString = string.match(choiceString, "^[^_]+") -- "%w+"
	local descString = string.match(choiceString, "_(.*)") --
	print("Opt. & Desc. :", optString)
	return optString, descString
end

--So this should be for singleton events | Singleton/Popup events, yay/nay.
function vote.eventVote_Timer(duration)
	--Needs to be more complex to account for time resets
	--No it doesnt, send a remote out that just updates a task.wait() timer.
end

--Multiple option events | new event we can modift
function vote.eventVote_Multi(event: Event) -- for {[1] = buttonInfo} end		
	local eventName = event.Name
	local eventOptions = event.options -- {"Attack", "Refuse", "Appease", ""}
	local eventTheme =  event.Theme --{event.Name, event.headerText, event.screenTheme}

	local totalPlayers = game.Players:GetPlayers()
	local ActivePlayers :{Players} ,totalActivePlayers: number = totalActivePlayersFn() -- nondead/nonspectating/active players. StatHandler plr->char.
	-- nondead/nonspectating/active players. StatHandler plr->char OR partyService.

	local opt = nil --By default fire the first variant.
	local responded = {} 
	local voteBegan = false 
	
	local variantChance = math.random(6,100) -- Probably make this a local value. Or variants could each have their own specific chances.
	local variant: boolean | Event | nil
	
	local queueStartup
	local started
	local closeConn 

	local startTimer = math.ceil(totalActivePlayers/2) -- >= 1 | Re-implement?
	--Ceil or Floor
	
	--..|eventVariantCheckPull()|..-- | First check for variant, fire regular visual for normal event otherwise.
	local variant = variantPullCheck(event, variantChance) :: Event --type annotate later
	
	--..|FireAllActiveClients()|..-- | To handle variants, every event should be choice disabl
	for ind, player in totalPlayers do 
		
		if table.find(ActivePlayers, player) then
			voteMulti:FireClient(player, event, eventTheme)
		elseif table.find(ActivePlayers, player) and variant then
			voteMulti:FireClient(player, event, eventTheme, variant) --> variant catch func that wont clear the options -> catches -> clears/transitions -> unlocks event
		else --Indice [1] | GUI element | Blank for dead?
			voteMulti:FireClient(player, dead) --You are dead! everyone else is voting! OR un-interactable menu with skull bg.
			end
	end
	
	--Variant On the serverside.
	if variant then
		--VARIANT SELECTED!! (Pop-Up viz func here)
		warn("EVENT VARIANT SELECTED, LUCKY YOU!!!")
		table.clear(responded)
		eventName = variant.Name
		eventOptions = variant.options
		eventTheme = variant.Theme
	end
	--[[
		FIX: We have some visualizer func for every single eventPop. text, UI, wtv. 
		can obv be voteSkipped but buttons cannot be clicked until done.
	]]
	
	--if forcedVote then event:Start()
	--partyNPCs:Vote(voteChoices, responded) | toggleable | 5-10 seconds randomly.
	-- if not party.anonymousVoting then -> EmoteHead:Play(characterVoteSound) each char has a diff pitch for voice or they can be straight up non-verbal
	
	--..|onPlayerVote()|..--
	local conn = voteMulti.OnServerEvent:Connect(function(player, choice)--Bind viz as well.
		if responded[player.UserId] == choice then
			return end
		
		--table.insert(responded, player) Redundant?
		
		if responded[player.UserId] ~= choice then --Allow choice swap 
			table.remove(responded, player.UserId)
		end
		
		--Count/Update player vote.
		responded[player.UserId] = choice
		--EmoteHead:Visual(player.UserId, choice)
		
		opt = mostVoted(responded)
		
		--Queue default start with timer upon 1 vote (non-npc).
		if voteBegan == false then
			voteBegan = true
			if queueStartup then --Kill initial startup | Never started, not sure to implement
				task.cancel(queueStartup)
			end
			
			--Default Start timer anyway for every vote.
			queueStartup = task.spawn(function()
				task.wait(12)--Prob something to viz this | Restart waiting timer | task.wait(eventWait)
				event:Start(opt)
				started = true
				return
			end)
		end
		
		--If all players have voted
		if fullVoteCheck(responded, totalActivePlayers) then
			warn("Players have all voted on options, choosing now.")
			task.cancel(queueStartup)
			queueStartup = nil
			opt = mostVoted(responded)
			event:Start(vote.choiceSplit(opt))
			started = true
			return
		end
		
	end)
	
	if started then --Does this orphan literally everything (No, simply frees this listener).
		conn:Disconnect()
		conn = nil
	end

end

function vote.eventVote_chooseWho()
		--Same voting criteria as multi, just specifically choose who
end

function vote.eventVote_NPC(voteAllowed: boolean, responseList: {string}, playerWeight)
	--Vote based on player responses + mostVoted weight + npc personality + a tinge o
end

return vote
