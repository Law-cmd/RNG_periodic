-- CraftingServer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local CraftingEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("CraftingEvent")
local InventoryUpdateEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("InventoryUpdateEvent")

local CraftingRecipes = require(ReplicatedStorage:WaitForChild("CraftingRecipes"))
local PlayerDataManager = require(game.ServerScriptService:WaitForChild("PlayerDataManager"))

local function CanCraft(player, recipe)
	local inv = PlayerDataManager.GetInventory(player)
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

local function ApplyCraft(player, recipe)
	local data = PlayerDataManager.GetData(player)
	local inv = data.Inventory

	local inventoryLookup = {}
	for i, item in ipairs(inv) do
		local key = item.ItemName .. "|" .. item.Rarity
		if not inventoryLookup[key] then
			inventoryLookup[key] = {quantity = 0, indices = {}}
		end
		inventoryLookup[key].quantity += (item.Quantity or 1)
		table.insert(inventoryLookup[key].indices, i)
	end

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
				needed -= toRemove
				if item.Quantity <= 0 then
					item._remove = true
				end
			end
		end
	end

	for i = #inv, 1, -1 do
		if inv[i]._remove then
			if data.EquippedIndex == i then
				data.EquippedIndex = nil
			elseif data.EquippedIndex and data.EquippedIndex > i then
				data.EquippedIndex -= 1
			end
			table.remove(inv, i)
		end
	end

	local resultFound = false
	for _, item in ipairs(inv) do
		if item.ItemName == recipe.Result.Name and item.Rarity == recipe.Result.Rarity then
			item.Quantity = (item.Quantity or 1) + 1
			item.IsCrafted = true
			item.Description = recipe.Result.Description
			resultFound = true
			break
		end
	end

	if not resultFound then
		table.insert(inv, {
			ItemName = recipe.Result.Name,
			Rarity = recipe.Result.Rarity,
			Description = recipe.Result.Description,
			Quantity = 1,
			Equipped = false,
			IsCrafted = true
		})
	end

	PlayerDataManager.SaveData(player)

	if _G.sendFullUpdate then
		_G.sendFullUpdate(player)
	end
end

CraftingEvent.OnServerEvent:Connect(function(player, recipeIndex)
	local recipes = CraftingRecipes.Recipes
	if not recipes or not recipes[recipeIndex] then
		CraftingEvent:FireClient(player, {Success = false, Message = "Recipe not found"})
		return
	end
	local recipe = recipes[recipeIndex]
	if CanCraft(player, recipe) then
		ApplyCraft(player, recipe)
		CraftingEvent:FireClient(player, {Success = true, Result = recipe.Result})
	else
		CraftingEvent:FireClient(player, {Success = false, Message = "Not enough ingredients"})
	end
end)

print("[CraftingServer] Initialized")
