-- Update crafted item descriptions when players join
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local CraftingRecipes = require(ReplicatedStorage:WaitForChild("CraftingRecipes"))
local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))

-- Build a lookup table for crafted item descriptions
local craftedItemDescriptions = {}
for _, recipe in ipairs(CraftingRecipes.Recipes) do
	local key = recipe.Result.Name .. "|" .. recipe.Result.Rarity
	craftedItemDescriptions[key] = recipe.Result.Description
end

print("[UpdateOnJoin] Loaded " .. #craftedItemDescriptions .. " crafted item descriptions")

-- Function to update a player's crafted items
local function updatePlayerCraftedItems(player)
	local data = PlayerDataManager.GetData(player)
	if not data or not data.Inventory then
		return
	end

	local updatedCount = 0
	for i, item in ipairs(data.Inventory) do
		if item.IsCrafted then
			local key = item.ItemName .. "|" .. item.Rarity
			local newDescription = craftedItemDescriptions[key]
			if newDescription and item.Description ~= newDescription then
				item.Description = newDescription
				updatedCount = updatedCount + 1
				print("[UpdateOnJoin] Updated " .. item.ItemName .. " (" .. item.Rarity .. ") for " .. player.Name)
			end
		end
	end

	if updatedCount > 0 then
		PlayerDataManager.SaveData(player)
		print("[UpdateOnJoin] Saved " .. updatedCount .. " updated items for " .. player.Name)
	end
end

-- Update existing players
for _, player in Players:GetPlayers() do
	updatePlayerCraftedItems(player)
end

-- Update new players when they join
Players.PlayerAdded:Connect(function(player)
	-- Wait for data to load
	task.wait(1)
	updatePlayerCraftedItems(player)
end)