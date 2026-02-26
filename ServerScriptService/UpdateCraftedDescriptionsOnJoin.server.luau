-- UpdateCraftedDescriptionsOnJoin (Server Script)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local CraftingRecipes = require(ReplicatedStorage:WaitForChild("CraftingRecipes"))
local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))

-- Build lookup table once
local craftedItemDescriptions = {}
for _, recipe in ipairs(CraftingRecipes.Recipes) do
	local key = recipe.Result.Name .. "|" .. recipe.Result.Rarity
	craftedItemDescriptions[key] = recipe.Result.Description
end

local function updatePlayerCraftedItems(player)
	local data = PlayerDataManager.GetData(player)
	if not data or not data.Inventory then return end

	local updatedCount = 0
	for _, item in ipairs(data.Inventory) do
		if item.IsCrafted then
			local key = item.ItemName .. "|" .. item.Rarity
			local newDesc = craftedItemDescriptions[key]
			if newDesc and item.Description ~= newDesc then
				item.Description = newDesc
				updatedCount += 1
			end
		end
	end

	if updatedCount > 0 then
		PlayerDataManager.SaveData(player)
	end
end

for _, player in Players:GetPlayers() do
	updatePlayerCraftedItems(player)
end

Players.PlayerAdded:Connect(function(player)
	task.wait(1)
	updatePlayerCraftedItems(player)
end)

print("[UpdateCraftedDescriptionsOnJoin] Initialized")
