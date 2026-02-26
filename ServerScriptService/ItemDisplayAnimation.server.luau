-- ItemDisplayAnimation (Server Script)
-- Animates items placed on pedestals with floating + spinning
local TweenService = game:GetService("TweenService")

local function animateItemDisplay(itemDisplay)
	local basePart = itemDisplay:FindFirstChild("ItemBase")
	if not basePart then return end

	local originalCFrame = basePart.CFrame

	task.spawn(function()
		while itemDisplay and itemDisplay.Parent do
			local floatUp = TweenService:Create(basePart, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				CFrame = originalCFrame * CFrame.new(0, 0.5, 0)
			})
			local floatDown = TweenService:Create(basePart, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				CFrame = originalCFrame
			})

			floatUp:Play()
			floatUp.Completed:Wait()
			if not (itemDisplay and itemDisplay.Parent) then break end

			floatDown:Play()
			floatDown.Completed:Wait()
			if not (itemDisplay and itemDisplay.Parent) then break end
		end
	end)
end

-- Watch all Item Stand models in workspace
local function watchModel(model)
	if not model:IsA("Model") then return end
	model.DescendantAdded:Connect(function(descendant)
		if descendant.Name == "ItemBase" and descendant:IsA("Part") then
			task.wait(0.5)
			animateItemDisplay(descendant.Parent)
		end
	end)
	-- Animate existing items
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant.Name == "ItemBase" and descendant:IsA("Part") then
			animateItemDisplay(descendant.Parent)
		end
	end
end

for _, child in ipairs(workspace:GetChildren()) do
	watchModel(child)
end
workspace.ChildAdded:Connect(watchModel)

print("[ItemDisplayAnimation] Initialized")
