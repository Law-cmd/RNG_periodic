-- CraftingServer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local CraftingEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("CraftingEvent")
local InventoryUpdateEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("InventoryUpdateEvent")

local CraftingRecipes = require(ReplicatedStorage:WaitForChild("CraftingRecipes"))
local PlayerDataManager = require(game.ServerScriptService:WaitForChild("PlayerDataManager"))

-- Helper to check if player can craft a recipe
local function CanCraft(player, recipe)
	local inv = PlayerDataManager.GetInventory(player)
	-- Build lookup table
	local inventoryLookup = {}
	for _, item in ipairs(inv) do
		local key = item.ItemName .. "|" .. item.Rarity
		inventoryLookup[key] = (inventoryLookup[key] or 0) + (item.Quantity or 1)
	end

	for _, ing in ipairs(recipe.Ingredients) do
		local key = ing.Name .. "|" .. ing.Rarity
		if (inventoryLookup[key] or 0) < ing.Quantity then
			return false
		end
	end
	return true
end

-- Apply crafting (subtract ingredients, add result)
local function ApplyCraft(player, recipe)
	local data = PlayerDataManager.GetData(player)
	local inv = data.Inventory

	-- Build lookup table with item indices
	local inventoryLookup = {}
	for i, item in ipairs(inv) do
		local key = item.ItemName .. "|" .. item.Rarity
		if not inventoryLookup[key] then
			inventoryLookup[key] = {quantity = 0, indices = {}}
		end
		inventoryLookup[key].quantity = inventoryLookup[key].quantity + (item.Quantity or 1)
		table.insert(inventoryLookup[key].indices, i)
	end

	-- Subtract ingredients
	for _, ing in ipairs(recipe.Ingredients) do
		local key = ing.Name .. "|" .. ing.Rarity
		local needed = ing.Quantity
		local lookup = inventoryLookup[key]

		if lookup then
			for _, index in ipairs(lookup.indices) do
				if needed <= 0 then break end
				local item = inv[index]
				local available = item.Quantity or 1
				local toRemove = math.min(available, needed)
				item.Quantity = available - toRemove
				needed = needed - toRemove

				-- Remove item if quantity is 0
				if item.Quantity <= 0 then
					-- Mark for removal (we'll remove in reverse order later)
					item._remove = true
				end
			end
		end
	end

	-- Remove items marked for deletion (in reverse order to maintain indices)
	for i = #inv, 1, -1 do
		if inv[i]._remove then
			-- Check if the item being removed is equipped
			if data.EquippedIndex == i then
				data.EquippedIndex = nil
			elseif data.EquippedIndex and data.EquippedIndex > i then
				-- Adjust equipped index if it's after the removed item
				data.EquippedIndex = data.EquippedIndex - 1
			end
			table.remove(inv, i)
		end
	end

	-- Add result
	local resultKey = recipe.Result.Name .. "|" .. recipe.Result.Rarity
	local resultFound = false
	for _, item in ipairs(inv) do
		if item.ItemName == recipe.Result.Name and item.Rarity == recipe.Result.Rarity then
			item.Quantity = (item.Quantity or 1) + 1
			-- Mark as crafted if not already
			item.IsCrafted = true
			-- Use description from recipe (already includes buff info)
			item.Description = recipe.Result.Description
			resultFound = true
			break
		end
	end

	if not resultFound then
		-- Use description from recipe (already includes buff info)
		table.insert(inv, {
			ItemName = recipe.Result.Name,
			Rarity = recipe.Result.Rarity,
			Description = recipe.Result.Description,
			Quantity = 1,
			Equipped = false,
			IsCrafted = true
		})
	end

	-- Save inventory
	PlayerDataManager.SaveData(player)

	-- Notify client with full update (includes IsCrafted field)
	if _G.sendFullUpdate then
		_G.sendFullUpdate(player)
	end
end

-- Crafting event handler
CraftingEvent.OnServerEvent:Connect(function(player, recipeIndex)
	-- Get recipe by index
	local recipes = CraftingRecipes.Recipes
	if not recipes or not recipes[recipeIndex] then
		CraftingEvent:FireClient(player, {
			Success = false,
			Message = "Recipe not found"
		})
		return
	end

	local recipe = recipes[recipeIndex]

	-- Check ingredients
	if CanCraft(player, recipe) then
		ApplyCraft(player, recipe)
		CraftingEvent:FireClient(player, {
			Success = true,
			Result = recipe.Result
		})
	else
		CraftingEvent:FireClient(player, {
			Success = false,
			Message = "Not enough ingredients"
		})
	end
end)
