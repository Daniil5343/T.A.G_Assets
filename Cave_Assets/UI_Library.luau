--UI Functionality Module
local tweenService = game:GetService("TweenService")
local repStorage = game:GetService("ReplicatedStorage")

local tweenLibrary = require(script.TweenLibrary)
local textService = require(script.TextService)
local soundHNDLR = require(repStorage.PlayerModules.UserInterface.CAVE_UI_LIBRARY.UI_SoundHandler)

local types = require(game.ReplicatedStorage.Shared["Types(Make_Serv/Cli"])

type Theme = types.Theme
type assetID = types.AssetID

type buttonSet = types.buttonSet
type buttonChoice = types.buttonChoice

local mind = {}
mind.__index = mind

--[[
Ok.

-OpenVote (baked in CDs)
-CloseVote
-VoteVariantDismiss(Dismisses to variant)
-Thematics & music handling.
--Intercept "Dead" and "Variant" btoom

--Viewport 3D Rock OR 2D UI rock.
]]

--Duplicate Func. bc I dont think its needed to require voteMOD locally.
--Splits votes from full text into choicePart ("Resist_Resist And Run" -> "Resist") 
function mind.choiceSplit(choiceString: string): string
	local optString = string.match(choiceString, "^[^_]+") -- "%w+"
	local descString = string.match(choiceString, "_(.*)") --
	--print("Opt. & Desc. :", optString, descString)
	return optString, descString
end

function mind.Dead()
	--You are dead! No voting allowed.
end

--For multiVote, make one for Bool later.

--Will default to passed exclusive change info button-wise.
function mind.themeUpdate(voteUI:ImageLabel ,newTheme: Theme, buttons: buttonSet)
	warn("NewTheme:", newTheme)
	--Primary
	local eventBody: ImageLabel = voteUI
	local eventFrame: ImageLabel =  eventBody.BoxFrame
	local eventLabel: TextLabel = eventBody.eventText
	local labelTransparency: number = eventLabel.Transparency
	
	--GOiB
	local GOiB: ImageLabel = eventBody.EventGOiB
	local GOiB_Frame: ImageLabel = eventBody.EventGOiBFrame
	
	--votingBox
	local votingBox: Frame = eventBody.VotingBox
	
	--Background
	local backdrop: ImageLabel = eventBody.Parent["CaveMind_Backdrop"]
	
	--Sounds
	local sound: assetID
	
	--Text
	local labelText = textService.newText(eventLabel)
	labelText:soundAttach(newTheme.eventTextSound)
	
	--Buttons

	--Assignment | functions(?)
	eventBody.Image = "rbxassetid://"..newTheme.PrimaryBox
	eventFrame.Image = "rbxassetid://"..newTheme.BoxFrame
	
	GOiB.Image = "rbxassetid://"..newTheme.GoiB
	GOiB_Frame.Image = "rbxassetid://"..newTheme.GoiBFrame
	
	backdrop.Image = "rbxassetid://"..newTheme.Backdrop
	backdrop.Transparency = newTheme.BackdropTransparency
	
	if buttons then	mind.buttonUpdate(buttons, newTheme) end
end

--| Multi Library | -- 

--|CONSTRUCTORS
function mind.newMulti(multiUI)
	local self = setmetatable({}, mind)
	self.UI = multiUI
	self.mainDesc = "mainDesc"
	self.eventDesc = ""
	
	self.Desc = textService.newText(multiUI.eventText)
	self.Desc:soundAttach(9120299736)
	
	return self
end

function mind.newMind(mindUI)
	local self = setmetatable({}, mind)
	self.mind = mindUI
	return self
end

function mind.newBool(boolUI)
	local self = setmetatable({}, mind)
	self.UI = boolUI
	return self
end

function mind.newBackdrop(backdropUI)
	local self = setmetatable({}, mind)
	self.UI = backdropUI
	return self
end

-- | MULTI LIB. | --
function mind:multiOpen(revealMethod) -- Reveal/Grow (FadeIn, grow from center) | Fadein default
	if not  revealMethod then
		tweenLibrary.slideIn(self.UI)
	else
		tweenLibrary[revealMethod](self.UI)
	end	
end

--|:Animate option | MULTIPLE  closing funcs? | Slide | Smash | Shrink |Fade/Sleep | etc.
function mind:multiClose(closingStyle)
	if not closingStyle then 
		tweenLibrary.slideOut(self.UI)
	else
		tweenLibrary[closingStyle](self.UI)
	end
end

--| :Swap thematics and music. | themePackages or specifics, why not both.
function mind:descUpdate(description: string)
	self.Desc:clearText()
	self.Desc:typeText(description)
end


--|: Bring rock -> propogate cracks -> slide out & shrink -> refurbish -> slide in
function mind:multiVariantCall()
	--buttomThemeUpdate(buttons, newTheme)
	--buttonSetUp(eventTextStuff)
end



--Eventually support rich text | This works B/C of bSet not the options passed. Remember that


function mind.buttonDisplayText(buttonPass : buttonSet| buttonChoice, buttonText: string | {string})
	for ind : string, bChoice: buttonChoice in buttonPass do
		local count = tonumber(string.match(tostring(ind), "%d"))
		warn(buttonText[count], count)
		if not buttonText[count] or buttonText[count] == "" then continue end --invisible choice func.
		bChoice.button.Text = buttonText[count] --text will be the splitString from voting.
	end
end

--Visual Button Update
function mind.buttonInvis(buttonChoice: buttonChoice, val: boolean)
	
end

function mind.buttonImage(buttonChoice: buttonChoice, buttonText: string)

end

function mind.buttonFrame(buttonChoice: buttonChoice, buttonFrame: string)
	
end

--| Button.MouseLeave fixes | --
function mind.buttonMain(buttonChoice: buttonChoice, enterFunc: () -> (), leaveFunc: () -> ())
	local runSRVC = game:GetService("RunService")
	local guiInset =game:GetService("GuiService"):GetGuiInset()
	local mousePos: Vector2
	local entered = false
	local thread
	
	local leftWall
	local rightWall 
	local topWall 
	local bottomWall
	
	local buttonPos = buttonChoice.button.AbsolutePosition
	local buttonSize = buttonChoice.button.AbsoluteSize

	--warn("Button Bounds:", buttonPos, buttonSize)
	--warn("LW RW TW BW:", leftWall, rightWall, topWall, bottomWall)
	
	thread = runSRVC.Heartbeat:Connect(function(dT: number, callBack: () -> ())
		buttonPos = buttonChoice.button.AbsolutePosition
		buttonSize = buttonChoice.button.AbsoluteSize

		leftWall = buttonPos.X
		rightWall = buttonPos.X + buttonSize.X
		topWall = buttonPos.Y
		bottomWall = buttonPos.Y + buttonSize.Y
		
		local actualMouse = game:GetService("UserInputService"):GetMouseLocation()
		local mousePos = Vector2.new(actualMouse.X, actualMouse.Y) - Vector2.new(0, guiInset.Y)
		
		local withinBounds: boolean = (mousePos.X >= leftWall and mousePos.X <= rightWall) and (mousePos.Y >= topWall and mousePos.Y <= bottomWall)
		
		if not entered and withinBounds then
			entered = true
			enterFunc()
		elseif entered and not withinBounds then 
			entered = false
			leaveFunc()
		end
	end)
	return thread
end



--General Hook ()
function mind.buttonHook(buttonSet: buttonSet, multiUI, optionDesc: {string}, audioObjects: {assetID})
	local confirmClick = 0
	local currSelect: buttonChoice
	local connections = {}--Figure out way to DC later.
	
	for key, bChoice: buttonChoice in buttonSet do 
		local button: TextButton = bChoice.button
		
		--Put it in that timeManager codePattern
		local function mouseEntered()
			confirmClick = 0
			currSelect = button
			soundHNDLR.playLocal(127366656618533)
			tweenLibrary.buttonShake(bChoice)
			tweenLibrary.buttonSize(bChoice, 18)
		end
		
		local function mouseLeft()
		--	currSelect = nil --LeaveSound | why is this event so unreliable wtf | ok it's the speed.
			tweenLibrary.buttonSize(bChoice)
			multiUI.Desc:stop()
			multiUI.Desc:updateText(multiUI.mainDesc)
			--tweenLibrary.buttonShake(bChoice)
		end
		
		--[[
		button.MouseEnter:Connect(function()
			--it handles the DB, but its still a function call :shrug:
		end)
		button.MouseLeave:Connect(function()
			--LeaveSound | why is this event so unreliable wtf | ok it's the speed.
			--tweenLibrary.buttonSize(bChoice)
			--multiUI.Desc:stop()
			--multiUI.Desc:updateText(multiUI.mainDesc)
			--tweenLibrary.buttonShake(bChoice)
		end)
		]]
		
		local connectThread = mind.buttonMain(bChoice, mouseEntered, mouseLeft)
		table.insert(connections, connectThread)
		
		button.Activated:Connect(function()
			warn("CurrButton:", currSelect)
			confirmClick += 1
			warn("KeyPass:", key, "optionDesc:", optionDesc) 
			local numKey = (string.match(tostring(key), "%d"))
			multiUI.eventDesc = optionDesc[tonumber(numKey)]
			warn("Event Desc:", multiUI.eventDesc)
			warn("Click Count:", confirmClick)
			
			if confirmClick == 1 and currSelect == button then
			    multiUI:descUpdate(multiUI.eventDesc)		
				warn("Click twice to confirm your choice!")
			elseif confirmClick == 2 and currSelect == button then
				multiUI:close()
				--for i, v in connects do clear
				warn("Choice:", numKey, "confirmed.")
			end
			print("Okay close multi via reference proabably.")
		end)
	end
end

function mind.buttonActivated(buttonChoice: buttonChoice, confirmedClicks: number)
	local button: TextButton = buttonChoice.button
end

function mind.buttonUpdate(buttonSet: buttonSet, theme: Theme | {string})
	--themeAlt: {"Choice1" = {"button" = {ID: 123, Font, TextColor3}, "buttonImage" = 123, "buttonFrame" = 123}
	if theme.PrimaryBox then --typeof(theme) returns nothing but a table apparently
		for name, choiceItem in buttonSet do
			--Button 
			local button: TextButton = choiceItem.button
			button.Font = theme.buttonFont
			button.TextColor3 = theme.buttonTextColor

			--Button Image
			local image: ImageLabel = choiceItem.buttonImage
			image.Image = "rbxassetid://"..theme.buttonID

			--Button Frame
			local frame: ImageLabel = choiceItem.buttonFrame
			frame.Image = "rbxassetid://"..theme.buttonFrameID			

		end
	else --Named wrong?? option/choice
		for choiceName, choiceVal in theme do 
			warn("PASSED THEME:", theme)
			warn("Ind:", choiceName, "val:", choiceVal)
			warn("buttonSet table:", buttonSet, "choiceName:", choiceName)
			
			local changeSet = buttonSet[choiceName] --???
			warn("changeSet:", changeSet)
			
			local button = changeSet["button"]
			local image = changeSet["buttonImage"]
			local frame = changeSet["buttonFrame"]
			warn("buttonset:", buttonSet, "image:", image)
			
			local themeChange = theme[choiceName]

			--Button Table
			button.Font = themeChange.button["Font"]
			button.TextColor3 = themeChange.button["TextColor3"]

			--Button Image
			image.Image = "rbxassetid://"..themeChange.buttonImage

			--Button Frame
			frame.Image = "rbxassetid://"..themeChange.buttonFrame		
		end
	end
end

function mind.buttonDisable(buttonSet: buttonSet)
	for name, set in buttonSet do 
		set.button.Active = false
		--safeguard invis buttons?
	end 
end

function mind.buttonEnable(buttonSet: buttonSet)
	for name, set in buttonSet do 
		set.button.Active = true
		--safeguard invis buttons?
	end 
end

--Return to eventDescription after clicking, used to display extended button Information

--RichText: Glowing Text, color changing text, egc
function mind.buttonOptionHover(button, multiUI, text)
	--This will require selectionGained on console per button.
end

local function mouseEnter()
	
end

local function mouseLeave()
	
end

local function buttonActivated()
	
end

--|CaveMind| Resting: {-0.049, 0},{0, 0}
function mind:mindOpenFull(time, duration)
	local tweeninfo = TweenInfo.new(.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
	local tween = tweenService:Create(self.mind, tweeninfo, {Position = UDim2.new(-0.049, 0,.95, 0)})
	tween:Play()
	tween.Completed:Connect(function()
		tween:Destroy()
	end)
end

function mind:mindCloseFull() --| Don't really need it | Ok need it for the veins n stuff
	local tweeninfo = TweenInfo.new(.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
	local tween = tweenService:Create(self.mind, tweeninfo, {Position = UDim2.new(-0.049, 0,0, 0)})
	tween:Play()
	tween.Completed:Connect(function()
		tween:Destroy()
	end)
end

--text, {speed,sound} 
function mind:mindOpenPartial() -- text in another func
	local tweeninfo = TweenInfo.new(.75, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local tween = tweenService:Create(self.mind, tweeninfo, {Position = UDim2.new(0, 0,0,0)})
	tween:Play()
	tween.Completed:Connect(function()
		tween:Destroy()
	end)
end

function mind:mindClose()--.443 is center aligned.
	local tweeninfo = TweenInfo.new(.75, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local tween = tweenService:Create(self.mind, tweeninfo, {Position = UDim2.new(-0.049, 0,-0.165, 0)})
	tween:Play()
	tween.Completed:Connect(function()
		tween:Destroy()
	end)
end

function mind:mindBlink() --Interpret this as it's own minigame at some point, (weeping angels?)
	
end

--|Backdrop| Should we have a static backdrop and secondary gif BD?
function mind:backdropOpen(revealMethod)
	
end

function mind:backdropClose(closeMethod)
	
end

return mind
