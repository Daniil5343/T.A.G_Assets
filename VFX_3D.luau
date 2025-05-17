local tweenSRVC = game:GetService("TweenService")
local VFX = {}

--||UNUSED||:
local function bloodCylinder(origin,bloodRadius, color, part)
	local bloodCylinder = Instance.new("Part")
	bloodCylinder.CFrame = CFrame.new(origin)
	bloodCylinder.Orientation = Vector3.new(0,0,90)
	bloodCylinder.Name = string.match(part.Name, "%d+")
	bloodCylinder.Shape = Enum.PartType.Cylinder
	bloodCylinder.BrickColor = color
	bloodCylinder.CanCollide = false
	bloodCylinder.Size = Vector3.new(0.0125, .1, .1)
	bloodCylinder.Anchored = true
	bloodCylinder.Parent = part

	local cylinderInfo = TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, true)
	local cylinderProperties = {Size = Vector3.new(bloodCylinder.Size.X,1.5,1.5)}
	local cylinderTween = tweenSRVC:Create(bloodCylinder, cylinderInfo, cylinderProperties)

	cylinderTween:Play()

	cylinderTween.Completed:Connect(function()
		--	cylinderTween:Destroy()
	end)
end
--||UNUSED||:

function VFX.Bleed_Squirt(location: Vector3)
	for i = 1, math.random(10,20) do
		local tweenSRVC = game.TweenService
		local newInfo = TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, .25)
		local propTable = {
			Transparency = 1,
			Size = Vector3.new(0,0,0)
		}

		local b = Instance.new("Part")
		local newTween = tweenSRVC:Create(b,newInfo, propTable)

		b.CanCollide = true
		b.Shape = Enum.PartType.Block
		b.Material = Enum.Material.SmoothPlastic
		b.Size = Vector3.new(math.random(3)/10, math.random(5)/10, math.random(5)/10)
		b.Name = "Blood"
		local bloodColors = {"Bright red","Really red","Crimson","Maroon"}
		b.BrickColor = BrickColor.new(bloodColors[math.random(#bloodColors)])
		b.Velocity = Vector3.new(math.random(-30,30),math.random(20,30),math.random(-30,30)) 
		b.Parent = workspace
		b.CFrame = CFrame.new(location)

		newTween:Play()
		task.delay(.5 ,function()
			b.Material = Enum.Material.Neon
		end)
		newTween.Completed:Connect(function()
			newTween:Destroy()
		end)
		game:GetService("Debris"):AddItem(b,5)
	end
end

function VFX.Bleed_Pool(origin: Vector3, minAmount: number,maxAmount: number)--Flat Cylinder tween, little more expensive
	if not minAmount then minAmount = 10 end
	if not maxAmount then maxAmount = 10 end
	
	if maxAmount < minAmount then
		minAmount = 10
		maxAmount =40
	end
		
	for i = minAmount, math.random(maxAmount) do
		local newInfo = TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, .25)
		local conn 
		local propTable = {
			Transparency = 1,
			Size = Vector3.new(0,0,0)
		}
		
		--Cube Section
		local bloodCube = Instance.new("Part")
		local cubeFade = tweenSRVC:Create(bloodCube,newInfo, propTable)

		bloodCube.CanCollide = true
		bloodCube.Shape = Enum.PartType.Block
		bloodCube.Material = Enum.Material.SmoothPlastic
		bloodCube.Size = Vector3.new(math.random(3)/10, math.random(5)/10, math.random(5)/10)
		bloodCube.Name = "bloodCube_"..i
		
		local bloodColors = {"Bright red","Really red","Crimson","Maroon"}
		bloodCube.BrickColor = BrickColor.new(bloodColors[math.random(#bloodColors)])
		bloodCube.Velocity = Vector3.new(math.random(-30,30),math.random(20,30),math.random(-30,30)) 
		bloodCube.Parent = workspace.Garbage
		bloodCube.CFrame = CFrame.new(origin)
		bloodCube.CastShadow = false
	
		cubeFade:Play()
		
		--bloodCylinder section		
		local bloodCylinder = Instance.new("Part")
		bloodCylinder.Size = Vector3.new(0.0125, .1, .1)
		bloodCylinder.Name = string.match(bloodCube.Name, "%d+")
		bloodCylinder.Shape = Enum.PartType.Cylinder
		bloodCylinder.BrickColor = bloodCube.BrickColor
		bloodCylinder.CanCollide = false
		bloodCylinder.Anchored = true
		bloodCylinder.Parent = bloodCube
		bloodCylinder.Material = Enum.Material.SmoothPlastic
		bloodCylinder.CastShadow = false
		
		local cylinderInfo = TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, true)
		local cylinderCloseInfo = TweenInfo.new(.75, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
		local cylinderProperties = {Size = Vector3.new(bloodCylinder.Size.X,1.5,1.5)}
		
		local cylinderTween = tweenSRVC:Create(bloodCylinder, cylinderInfo, cylinderProperties)
		local cylinderCloseTween =  tweenSRVC:Create(bloodCylinder, cylinderCloseInfo, {Size = Vector3.new(bloodCylinder.Size.X, 0,0), Transparency = 0})
		
		local touched = false
		conn = bloodCube.Touched:Connect(function(part)
			if part.Name == "Baseplate" and not touched then
				bloodCube.AssemblyLinearVelocity = Vector3.new(2,.5,3) 
				bloodCube.AssemblyAngularVelocity = Vector3.new(2,.5,3)
				touched = true
				
				local rayParams = RaycastParams.new()
				rayParams.FilterDescendantsInstances = { workspace.Baseplate}--
				rayParams.FilterType = Enum.RaycastFilterType.Include
				local floorRay = workspace:Raycast(bloodCube.Position, Vector3.new(0,-bloodCube.Position.Y,0), rayParams)
				
			if floorRay then 
					if floorRay.Instance then 
						warn("touch successful")
						if floorRay.Instance.Name == "Baseplate" then
							bloodCylinder.CFrame = CFrame.new(floorRay.Position)
							bloodCylinder.Orientation = Vector3.new(0,0,90)
							bloodCylinder.Parent = bloodCube
							cylinderTween:Play()
							if conn then 
								conn:Disconnect()
							end
						end
					end
				else 
					--warn("Fail Touch")
					end
			end 
		end)
		
		task.delay(.5 ,function()
			bloodCube.Material = Enum.Material.Neon
		end)
		
		cubeFade.Completed:Connect(function()
			cubeFade:Destroy()
			cylinderTween:Pause()
			task.delay(3, function()
				cylinderCloseTween:Play()
				
				cylinderCloseTween.Completed:Connect(function()
					cylinderCloseTween:Destroy()
				end)
			end)
		end)
	game:GetService("Debris"):AddItem(bloodCube,10) 
		end
end

function VFX.Bleed_Drip(origin: Vector3, duration: number) --skinny rectangle fall, tween to cylinder.
	
end

function VFX.Smoke_Cloud(origin: Vector3, spread: number, spreadTime: number, color: Color3 ) --Running smoke, can toggle shapes: circular is running, cube is AOE
	
end

function VFX.Smoke_Impact(origin: Vector3, startColor: Color3, endColor: Color3) --Imagine fading air cubes from heavy hits, or orange -> black explosion flames
	
end

return VFX
