-- Server script to animate displayed items on pedestals
local TweenService = game:GetService("TweenService")

-- Function to animate an item display
local function animateItemDisplay(itemDisplay)
	local basePart = itemDisplay:FindFirstChild("ItemBase")
	if not basePart then return end
	
	-- Store original position
	local originalCFrame = basePart.CFrame
	
	-- Create floating animation
	while itemDisplay and itemDisplay.Parent do
		-- Float up and down
		local floatUp = TweenService:Create(basePart, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			CFrame = originalCFrame * CFrame.new(0, 0.5, 0)
		})
		
		local floatDown = TweenService:Create(basePart, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			CFrame = originalCFrame
		})
		
		floatUp:Play()
		floatUp.Completed:Wait()
		
		if not itemDisplay or not itemDisplay.Parent then break end
		
		floatDown:Play()
		floatDown.Completed:Wait()
		
		if not itemDisplay or not itemDisplay.Parent then break end
		
		-- Rotate the item
		local rotationTween = TweenService:Create(basePart, TweenInfo.new(4, Enum.EasingStyle.Linear), {
			CFrame = basePart.CFrame * CFrame.Angles(0, math.rad(360), 0)
		})
		
		rotationTween:Play()
		rotationTween.Completed:Wait()
	end
end

-- Watch for new item displays being added
local lab = workspace:FindFirstChild("Lab")
if lab then
	lab.DescendantAdded:Connect(function(descendant)
		if descendant.Name == "ItemBase" and descendant:IsA("Part") then
			-- Wait a moment for the display to be fully set up
			task.wait(0.5)
			animateItemDisplay(descendant.Parent)
		end
	end)
	
	-- Animate existing items
	for _, descendant in lab:GetDescendants() do
		if descendant.Name == "ItemBase" and descendant:IsA("Part") then
			task.spawn(function()
				animateItemDisplay(descendant.Parent)
			end)
		end
	end
end

return "Item display animation system initialized"