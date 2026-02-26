--[[
	Equip Effects Visualizer
	Creates equip effects on other players' characters
	This script runs on each client and shows effects for all players
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local RemoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local EquipEffectsEvent = RemoteEventsFolder:WaitForChild("EquipEffectsEvent")

-- Require the EquipEffects module to use its effect creation functions
local EquipEffects = require(script.Parent:WaitForChild("EquipEffects"))

-- Track effects for each player
local activeEffects = {}

-- Create effects on a player's character
local function createEffectsOnPlayer(player, itemData)
	local character = player.Character
	if not character then return end

	-- Remove existing effects for this player
	if activeEffects[player.UserId] then
		local effects = EquipEffects.ActiveEffects[player.UserId]
		if effects then
			local function destroy(v)
				if typeof(v) == "Instance" then v:Destroy() end
			end
			if effects.Particles then destroy(effects.Particles) end
			if effects.Nucleus then
				destroy(effects.Nucleus.Core)
				for _, n in ipairs(effects.Nucleus.Nucleons) do destroy(n) end
			end
			if effects.Shells then
				for _, shell in ipairs(effects.Shells) do
					for _, e in ipairs(shell) do destroy(e) end
				end
			end
			if effects.Rings then
				for _, r in ipairs(effects.Rings) do destroy(r) end
			end
			EquipEffects.ActiveEffects[player.UserId] = nil
		end
	end

	-- Create new effects
	EquipEffects.EquipElement(player, itemData)
	activeEffects[player.UserId] = itemData
end

-- Handle equip effects event
EquipEffectsEvent.OnClientEvent:Connect(function(data)
	local player = data.Player
	local action = data.Action
	local itemData = data.ItemData

	if action == "Equip" then
		-- Don't create effects on our own character (handled by RNGClient)
		if player ~= Players.LocalPlayer then
			createEffectsOnPlayer(player, itemData)
		end
	elseif action == "Unequip" then
		if player ~= Players.LocalPlayer then
			if activeEffects[player.UserId] then
				local effects = EquipEffects.ActiveEffects[player.UserId]
				if effects then
					local function destroy(v)
						if typeof(v) == "Instance" then v:Destroy() end
					end
					if effects.Particles then destroy(effects.Particles) end
					if effects.Nucleus then
						destroy(effects.Nucleus.Core)
						for _, n in ipairs(effects.Nucleus.Nucleons) do destroy(n) end
					end
					if effects.Shells then
						for _, shell in ipairs(effects.Shells) do
							for _, e in ipairs(shell) do destroy(e) end
						end
					end
					if effects.Rings then
						for _, r in ipairs(effects.Rings) do destroy(r) end
					end
					EquipEffects.ActiveEffects[player.UserId] = nil
				end
				activeEffects[player.UserId] = nil
			end
		end
	end
end)

-- Handle player joining (show their equipped item if they have one)
Players.PlayerAdded:Connect(function(player)
	task.wait(2) -- Wait for character to load

	if player ~= Players.LocalPlayer then
		-- Request equipped item from server
		local GetEquippedFunction = RemoteEventsFolder:FindFirstChild("GetEquippedFunction")
		if GetEquippedFunction then
			local success, equippedItem = pcall(function()
				return GetEquippedFunction:InvokeServer(player)
			end)

			if success and equippedItem then
				createEffectsOnPlayer(player, equippedItem)
			end
		end
	end
end)

-- Handle player leaving
Players.PlayerRemoving:Connect(function(player)
	if activeEffects[player.UserId] then
		activeEffects[player.UserId] = nil
	end
end)

-- Handle character respawn for existing players
for _, player in ipairs(Players:GetPlayers()) do
	if player ~= Players.LocalPlayer then
		player.CharacterAdded:Connect(function(character)
			task.wait(1)
			if activeEffects[player.UserId] then
				createEffectsOnPlayer(player, activeEffects[player.UserId])
			end
		end)
	end
end

print("[EquipEffectsVisualizer] Initialized")