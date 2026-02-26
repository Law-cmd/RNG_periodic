--[[
	Player Data Manager
	Handles saving and loading player inventory and roll history
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local PlayerDataStore = DataStoreService:GetDataStore("PlayerRNGData")

local PlayerDataManager = {}
PlayerDataManager.PlayerData = {}

-- Default data structure for new players
local function getDefaultData()
	return {
		Inventory = {},
		EquippedIndex = nil, -- Index of equipped item or nil
		RollHistory = {},
		TotalRolls = 0,
		LastRollTime = 0,
		Currency = 0, -- Optional currency for roll costs
		LuckMultiplier = 1
	}
end

-- Load player data
function PlayerDataManager.LoadData(player)
	local success, data = pcall(function()
		return PlayerDataStore:GetAsync(player.UserId)
	end)

	if success and data then
		-- Migrate old data format to new format
		if data.EquippedItem ~= nil and data.EquippedIndex == nil then
			print("Migrating old EquippedItem field to EquippedIndex for " .. player.Name)
			data.EquippedIndex = data.EquippedItem
			data.EquippedItem = nil
		end
		
		-- Ensure all inventory items have IsCrafted field
		if data.Inventory then
			for _, item in ipairs(data.Inventory) do
				if item.IsCrafted == nil then
					item.IsCrafted = false -- Default to false for existing items
				end
			end
		end
		
		PlayerDataManager.PlayerData[player.UserId] = data
		print("Loaded data for " .. player.Name)
	else
		PlayerDataManager.PlayerData[player.UserId] = getDefaultData()
		print("Created new data for " .. player.Name)
	end

	return PlayerDataManager.PlayerData[player.UserId]
end

-- Save player data
function PlayerDataManager.SaveData(player)
	local data = PlayerDataManager.PlayerData[player.UserId]

	if not data then
		warn("No data to save for " .. player.Name)
		return false
	end

	local success, err = pcall(function()
		PlayerDataStore:SetAsync(player.UserId, data)
	end)

	if success then
		print("Saved data for " .. player.Name)
		return true
	else
		warn("Failed to save data for " .. player.Name .. ": " .. tostring(err))
		return false
	end
end

-- Get player data
function PlayerDataManager.GetData(player)
	return PlayerDataManager.PlayerData[player.UserId]
end

-- Add item to player inventory (with stacking)
function PlayerDataManager.AddItemToInventory(player, rollResult)
	local data = PlayerDataManager.GetData(player)

	if not data then
		warn("No data found for " .. player.Name)
		return false
	end

	-- Check if item already exists (same name and rarity)
	for _, item in ipairs(data.Inventory) do
		if item.ItemName == rollResult.ItemName and item.Rarity == rollResult.Rarity then
			-- Increment quantity instead of adding new entry
			item.Quantity = (item.Quantity or 1) + 1
			print("Stacked " .. rollResult.ItemName .. " (now x" .. item.Quantity .. ") for " .. player.Name)
			return true
		end
	end

	-- Create new inventory entry
	local inventoryItem = {
		ItemName = rollResult.ItemName,
		Rarity = rollResult.Rarity,
		Description = rollResult.ItemDescription,
		ObtainedAt = rollResult.Timestamp,
		Equipped = false,
		Quantity = 1,
		IsCrafted = rollResult.IsCrafted or false -- Include IsCrafted field
	}

	table.insert(data.Inventory, inventoryItem)
	print("Added " .. rollResult.ItemName .. " to " .. player.Name .. "'s inventory. Total items: " .. #data.Inventory)

	-- Add to roll history (keep last 50 rolls)
	table.insert(data.RollHistory, 1, {
		ItemName = rollResult.ItemName,
		Rarity = rollResult.Rarity,
		Timestamp = rollResult.Timestamp
	})

	if #data.RollHistory > 50 then
		table.remove(data.RollHistory)
	end

	data.TotalRolls = data.TotalRolls + 1

	return true
end

-- Check if player can roll (cooldown check)
function PlayerDataManager.CanRoll(player)
	local data = PlayerDataManager.GetData(player)

	if not data then
		return false, "No data found"
	end

	local RNGConfig = require(game.ReplicatedStorage:WaitForChild("RNGConfig"))
	local currentTime = os.time()
	local timeSinceLastRoll = currentTime - data.LastRollTime

	if timeSinceLastRoll < RNGConfig.RollCooldown then
		local timeRemaining = RNGConfig.RollCooldown - timeSinceLastRoll
		return false, "Cooldown: " .. timeRemaining .. "s remaining"
	end

	return true, "Can roll"
end

-- Update last roll time
function PlayerDataManager.UpdateRollTime(player)
	local data = PlayerDataManager.GetData(player)

	if data then
		data.LastRollTime = os.time()
	end
end

-- Get player inventory
function PlayerDataManager.GetInventory(player)
	local data = PlayerDataManager.GetData(player)
	return data and data.Inventory or {}
end

-- Set player inventory (for crafting system)
function PlayerDataManager.SetInventory(player, inventory)
	local data = PlayerDataManager.GetData(player)

	if not data then
		warn("No data found for " .. player.Name)
		return false
	end

	-- Keep track of existing IsCrafted status
	local existingCraftedStatus = {}
	for _, item in ipairs(data.Inventory) do
		local key = item.ItemName .. "|" .. item.Rarity
		existingCraftedStatus[key] = item.IsCrafted or false
	end

	-- Convert dictionary back to array format
	local newInventory = {}
	for key, quantity in pairs(inventory) do
		local itemName, rarity = key:match("(.+)|(.+)")
		if itemName and rarity then
			-- Find description from RNGConfig
			local description = ""
			local RNGConfig = require(game.ReplicatedStorage:WaitForChild("RNGConfig"))
			for _, rarityData in ipairs(RNGConfig.Rarities) do
				if rarityData.Name == rarity then
					local items = RNGConfig.Items[rarity]
					if items then
						for _, item in ipairs(items) do
							if item.Name == itemName then
								description = item.Description
								break
							end
						end
					end
					break
				end
			end

			-- Check if item already exists in inventory
			local found = false
			for _, existingItem in ipairs(newInventory) do
				if existingItem.ItemName == itemName and existingItem.Rarity == rarity then
					existingItem.Quantity = quantity
					found = true
					break
				end
			end

			if not found then
				-- Preserve IsCrafted status from existing inventory
				local wasCrafted = existingCraftedStatus[key] or false
				table.insert(newInventory, {
					ItemName = itemName,
					Rarity = rarity,
					Description = description,
					Quantity = quantity,
					Equipped = false,
					IsCrafted = wasCrafted -- Preserve existing IsCrafted status
				})
			end
		end
	end

	data.Inventory = newInventory
	print("[PlayerDataManager] Set inventory for " .. player.Name .. " with " .. #newInventory .. " items")
	return true
end

-- Get player roll history
function PlayerDataManager.GetRollHistory(player)
	local data = PlayerDataManager.GetData(player)
	return data and data.RollHistory or {}
end

-- Add to roll history
function PlayerDataManager.AddToRollHistory(player, rollResult)
	local data = PlayerDataManager.GetData(player)

	if not data then
		return false
	end

	-- Add to roll history (keep last 50 rolls)
	table.insert(data.RollHistory, 1, {
		ItemName = rollResult.ItemName,
		Rarity = rollResult.Rarity,
		Timestamp = rollResult.Timestamp
	})

	if #data.RollHistory > 50 then
		table.remove(data.RollHistory)
	end

	return true
end

-- Equip an item
function PlayerDataManager.EquipItem(player, itemIndex)
	print("[PlayerDataManager] EquipItem called for player:", player.Name, "index:", tostring(itemIndex))
	local data = PlayerDataManager.GetData(player)

	if not data then
		print("[PlayerDataManager] No data found for player")
		return false, "No data found"
	end

	if not data.Inventory[itemIndex] then
		print("[PlayerDataManager] Invalid item index:", itemIndex, "Inventory size:", #data.Inventory)
		return false, "Invalid item index"
	end

	-- Unequip all items
	for _, item in ipairs(data.Inventory) do
		item.Equipped = false
	end

	-- Equip selected item
	data.Inventory[itemIndex].Equipped = true
	data.EquippedIndex = itemIndex

	print("[PlayerDataManager] Equipped item at index " .. itemIndex .. " for " .. player.Name)

	-- Return a complete item object with all required fields
	local equippedItem = data.Inventory[itemIndex]
	local returnData = {
		ItemName = equippedItem.ItemName,
		Rarity = equippedItem.Rarity,
		Description = equippedItem.Description or "No description",
		IsCrafted = equippedItem.IsCrafted or false
	}
	print("[PlayerDataManager] Returning item data:", returnData.ItemName, returnData.Rarity, "IsCrafted:", returnData.IsCrafted)
	return true, returnData
end

-- Remove item from inventory (with stacking support)
function PlayerDataManager.RemoveItemFromInventory(player, itemIndex)
	local data = PlayerDataManager.GetData(player)

	if not data or not data.Inventory[itemIndex] then
		return false
	end

	local item = data.Inventory[itemIndex]
	local quantity = item.Quantity or 1

	if quantity > 1 then
		-- Decrement quantity instead of removing
		item.Quantity = quantity - 1
		print("Decremented " .. item.ItemName .. " to x" .. item.Quantity .. " for " .. player.Name)
		return true
	end

	-- Check if the item being deleted is equipped
	local wasEquipped = item.Equipped

	-- Remove the item (quantity is 1)
	table.remove(data.Inventory, itemIndex)

	-- If the deleted item was equipped, update equipped index
	if wasEquipped then
		data.EquippedIndex = nil
	elseif data.EquippedIndex and data.EquippedIndex > itemIndex then
		-- If an item after the deleted one was equipped, adjust the index
		data.EquippedIndex = data.EquippedIndex - 1
	end

	print("Removed item at index " .. itemIndex .. " from " .. player.Name .. "'s inventory. Remaining items: " .. #data.Inventory)

	return true
end

-- Get equipped item
function PlayerDataManager.GetEquippedItem(player)
	local data = PlayerDataManager.GetData(player)

	if not data then
		return nil
	end

	for _, item in ipairs(data.Inventory) do
		if item.Equipped then
			return item
		end
	end

	return nil
end

-- Get player currency
function PlayerDataManager.GetCurrency(player)
	local data = PlayerDataManager.GetData(player)
	return data and data.Currency or 0
end

-- Add currency
function PlayerDataManager.AddCurrency(player, amount)
	local data = PlayerDataManager.GetData(player)

	if not data then
		return false
	end

	data.Currency = data.Currency + amount
	return true
end

-- Remove currency (returns true if successful, false if not enough)
function PlayerDataManager.RemoveCurrency(player, amount)
	local data = PlayerDataManager.GetData(player)

	if not data or data.Currency < amount then
		return false
	end

	data.Currency = data.Currency - amount
	return true
end

-- Get total rolls
function PlayerDataManager.GetTotalRolls(player)
	local data = PlayerDataManager.GetData(player)
	return data and data.TotalRolls or 0
end

return PlayerDataManager