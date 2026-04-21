--UI Visual Effects Module
local types = require(game.ReplicatedStorage.Shared["Types(Make_Serv/Cli"])
local tweenService = game:GetService("TweenService")
local defaultSize --{0.954, 0},{0.892, 0} |
local shrunkSize --{0.159, 0.148}

type multi_Styles = 
{
	fadein: "fadeIn",
	growOut: "growOut",
	shrinkOut: "shrinkOut",
}

type button_Styles = 
{
	buttonShake: "buttonShake";
	buttonPop: "buttonPop";
	buttonFlash: "buttonFlash"; --Silver Stripe, Special options
	buttonCrack: "buttonCrack"; --have to return this one to cancel
	buttonBounce: "buttonBounce";
	buttonColor: "buttonColor";
	buttonDarken: "buttonDarken";
}

local ui  = {}

local ui_tweenLibrary = {
	shrinkTable = --shrinkOut
	{
		tweenInfo = TweenInfo.new(.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In),
		propertyTable = {Size = UDim2.new(.159, 0, .148, 0)}
	},
	
	growTableIn = 
	{
		tweenInfo = TweenInfo.new(.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
		propertyTable = {Size = UDim2.new(.954, 0, .892, 0)}
	}, 
	
	slideTableIn = 
	{
			tweenInfo = TweenInfo.new(.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
			propertyTable = {Position = UDim2.new(0.5,0,0.5,0)}
	},

	slideTableOut = 
	{
		tweenInfo = TweenInfo.new(.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut),
		propertyTable = {Position = UDim2.new(1.5,0,0.5,0)}
	},

	mindFlashTable = --high Z-index bi-horizontal black gradient representing the mind/transition 
	{--1/2 tweened other half needs manual implementation
			tweenInfo = TweenInfo.new(.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut),
			propertyTable = {Position = UDim2.new(0.5,0,0.5,0)}
	}
}	

local button_tweenLibrary = {
	buttonShakeTable = 
	{
		tweenInfo = TweenInfo.new(.1, Enum.EasingStyle.Bounce, Enum.EasingDirection.InOut),
		propertyTable = {Rotation = 10}
	},

	buttonShakeBackTable = 
	{
		tweenInfo = TweenInfo.new(.1, Enum.EasingStyle.Bounce, Enum.EasingDirection.InOut),
		propertyTable = {Rotation = -10}
	},

	buttonSizeTable = 
	{
		tweenInfo =TweenInfo.new(.1, Enum.EasingStyle.Bounce, Enum.EasingDirection.InOut),
		propertyTable = {TextSize = 14}
	},
	
}

--This is temporary: change to a sin() sequence eventually |Same with isBeingTweened
function ui.buttonShake(buttonChoice: types.buttonChoice)
	if buttonChoice.tweening then return end
	buttonChoice.tweening = true
	
	local button = buttonChoice.button
	
	local shakeForward = tweenService:Create(button, button_tweenLibrary.buttonShakeTable.tweenInfo, button_tweenLibrary.buttonShakeTable.propertyTable)
	local shakeBack = tweenService:Create(button, button_tweenLibrary.buttonShakeBackTable.tweenInfo, button_tweenLibrary.buttonShakeBackTable.propertyTable)
	local normal = tweenService:Create(button, button_tweenLibrary.buttonShakeBackTable.tweenInfo, {Rotation = 0})
	shakeForward:Play()
	shakeForward.Completed:Once(function()  
		shakeBack:Play()
	end)
	
	shakeBack.Completed:Once(function()
		shakeForward:Destroy()
		shakeBack:Destroy()
		normal:Play()
		normal.Completed:Wait()
		normal:Destroy()
		buttonChoice.tweening = false;
	end)
end

function ui.buttonSize(buttonChoice: types.buttonChoice, size: number)
	local button = buttonChoice.button
	local propTable
	if size then propTable = {TextSize = size} else propTable = button_tweenLibrary.buttonSizeTable.propertyTable end
	local tween = tweenService:Create(button, button_tweenLibrary.buttonSizeTable.tweenInfo, propTable)

	tween:Play()
	tween.Completed:Once(function()
		tween:Destroy()
	end)
end

--Have to be small in the first place, meaning call shrink regardless.
function ui.growIn(uiFrame: Frame | ImageLabel )
	local tween = tweenService:Create(uiFrame, ui_tweenLibrary.growTableIn.tweenInfo, ui_tweenLibrary.growTableIn.propertyTable)
	
	--Just Incase not already shrunk
	uiFrame.Size = UDim2.new(0.159, 0, 0.148, 0)
	
	tween:Play()
	tween.Completed:Once(function()
		tween:Destroy()
	end)
end

function ui.shrinkOut(uiFrame: Frame | ImageLabel)
	local tween = tweenService:Create(uiFrame, ui_tweenLibrary.growTableIn.tweenInfo, ui_tweenLibrary.shrinkTable.propertyTable)
	
	tween:Play()
	tween.Completed:Once(function()
		tween:Destroy()
	end)
end

--function ui.slide

function ui.slideIn(uiFrame: Frame, easingStyle)--ShrinkOut/GrowIn?
	uiFrame.Position = UDim2.new(1.5,0,0.5,0)
	local tween = tweenService:Create(uiFrame, ui_tweenLibrary.slideTableIn.tweenInfo, ui_tweenLibrary.slideTableIn.propertyTable)
	
	tween:Play()
	tween.Completed:Once(function()
		tween:Destroy()
	end)
end

function ui.slideOut(uiFrame, eastingStyle)
	local tween = tweenService:Create(uiFrame, ui_tweenLibrary.slideTableOut.tweenInfo, ui_tweenLibrary.slideTableOut.propertyTable)

	tween:Play()
	
	tween.Completed:Wait() 
	tween:Destroy()
	--ui.shrinkOut(uiFrame)
end

function ui.fadeIn(uiFrame,t)
	local twinfo = TweenInfo.new(t, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
	local tween = tweenService:Create(uiFrame, TweenInfo, {Transparency = 0})
end

function ui.mindPartialAppear(uiFrame)
	--local twinfo = TweenInfo.new(.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
	--local tween = tweenService:Create(uiFrame, TweenInfo, {Position = UDim2.new(-0.075, 0,-0.165,0)})
	--tween:Play()
	--tween.Completed:Connect(function()
	--	tween:Destroy()
	--end)
end

function ui.mindPartialDisappear(uiFrame)
	--local twinfo = TweenInfo.new(.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
	--local tween = tweenService:Create(uiFrame, TweenInfo, {Position = UDim2.new(-0.075, 0,0, 0)})
	--tween:Play()
	--tween.Completed:Connect(function()
	--	tween:Destroy()
	--end)
end

--ShrinkIn
--GrowOut

--<CaveMind> Resting: {-0.049, 0} -> {-.049, .95} | Partial Hidden: {{-0.075, 0},{0, 0} -> Vis: {-0.075, 0},{-0.165,0}
function ui.mindAppear(mindFrame: Frame, duration: number)
	local twinfo = TweenInfo.new(.35, Enum.EasingStyle.Bounce, Enum.EasingDirection.In)
	local tween = tweenService:Create(mindFrame, TweenInfo, {Position = UDim2.new(-0.049, 0,.95, 0)})
	tween:Play()
	tween.Completed:Connect(function()
		tween:Destroy()
	end)
end

function ui.mindDisappear(mindFrame: Frame)
	local twinfo = TweenInfo.new(.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.In)
	local tween = tweenService:Create(mindFrame, TweenInfo, {Position = UDim2.new(-0.049, 0,0, 0)})
	tween:Play()
	tween.Completed:Connect(function()
		tween:Destroy()
	end)
end

return ui

--{0.954, 0},{0.892, 0} | 159, 148
