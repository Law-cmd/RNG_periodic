--[[
    Simple Floating Test
    Run this to test the floating effect
    Usage: In the command bar, run:
    game.ServerScriptService.TestFloatingSimple:Test()
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local TestFloatingSimple = {}

function TestFloatingSimple.Test(playerName)
	-- Find the player
	local player
	if playerName then
		player = Players:FindFirstChild(playerName)
	else
		-- Get the first player in the game
		local allPlayers = Players:GetPlayers()
		if #allPlayers > 0 then
			player = allPlayers[1]
		end
	end
	
	if not player then
		warn("[TestFloatingSimple] No player found! Make sure you're in Play Mode.")
		return nil
	end
	
	local character = player.Character
	if not character then
		warn("[TestFloatingSimple] No character found for " .. player.Name .. "! Please spawn your character first.")
		return nil
	end
	
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		warn("[TestFloatingSimple] No HumanoidRootPart found!")
		return nil
	end
	
	print("[TestFloatingSimple] Starting floating test for " .. player.Name .. "...")
	print("[TestFloatingSimple] You should float 3 studs above the ground.")
	print("[TestFloatingSimple] Press SPACE to stop floating.")
	
	local connection
	local isFloating = true
	
	connection = RunService.Heartbeat:Connect(function()
		if not character.Parent or not isFloating then
			connection:Disconnect()
			return
		end
		
		-- Get current HRP (in case it was replaced)
		local currentHrp = character:FindFirstChild("HumanoidRootPart")
		if not currentHrp then
			connection:Disconnect()
			return
		end
		
		-- Raycast down to find ground
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.FilterDescendantsInstances = {character}
		
		local rayResult = workspace:Raycast(
			currentHrp.Position,
			Vector3.new(0, -100, 0),
			rayParams
		)
		
		local groundY = rayResult and rayResult.Position.Y or 0
		local targetY = groundY + 3
		
		-- Apply upward velocity
		local velocityY = (targetY - currentHrp.Position.Y) * 10
		currentHrp.AssemblyLinearVelocity = Vector3.new(
			currentHrp.AssemblyLinearVelocity.X,
			velocityY,
			currentHrp.AssemblyLinearVelocity.Z
		)
	end)
	
	-- Listen for jump to stop
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Jumping:Connect(function()
			isFloating = false
			print("[TestFloatingSimple] Floating stopped!")
		end)
	end
	
	return connection
end

return TestFloatingSimple