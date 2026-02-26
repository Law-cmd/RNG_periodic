local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RNGSystem = require(ReplicatedStorage:WaitForChild("RNGSystem"))
local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))

local RemoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local RollEvent = RemoteEventsFolder:WaitForChild("RollEvent")
local InventoryUpdateEvent = RemoteEventsFolder:WaitForChild("InventoryUpdateEvent")
local EquipEvent = RemoteEventsFolder:WaitForChild("EquipEvent")
local DeleteEvent = RemoteEventsFolder:WaitForChild("DeleteEvent")
local GetInventoryFunction = RemoteEventsFolder:WaitForChild("GetInventoryFunction")

-- Create GetEquippedFunction if it doesn't exist
local GetEquippedFunction = RemoteEventsFolder:FindFirstChild("GetEquippedFunction")
if not GetEquippedFunction then
	GetEquippedFunction = Instance.new("RemoteFunction")
	GetEquippedFunction.Name = "GetEquippedFunction"
	GetEquippedFunction.Parent = RemoteEventsFolder
end

local function sendFullUpdate(player)
	local data = PlayerDataManager.GetData(player)
	if not data then return end

	-- Send a clean copy so client can't mutate server table
	local copy = {
		Inventory = {},
		TotalRolls = #data.RollHistory,
		Currency = 0, -- You can add currency tracking later
	}

	-- Create a copy of the inventory (server keeps original order)
	for i, item in ipairs(data.Inventory) do
		copy.Inventory[i] = {
			ItemName = item.ItemName,
			Rarity = item.Rarity,
			Description = item.Description,
			Equipped = (data.EquippedIndex == i),
			Quantity = item.Quantity or 1,
			OriginalIndex = i, -- Keep original index for actions
			IsCrafted = item.IsCrafted or false
		}
	end

	print("[RNGServer] EquippedIndex: " .. tostring(data.EquippedIndex))

	print("[RNGServer] Sending inventory update to " .. player.Name .. ": " .. #copy.Inventory .. " items")
	InventoryUpdateEvent:FireClient(player, copy)
end

-- Make sendFullUpdate accessible globally for other scripts
_G.sendFullUpdate = sendFullUpdate

Players.PlayerAdded:Connect(function(player)
	PlayerDataManager.LoadData(player)
	sendFullUpdate(player)
end)

-- Save data when player leaves
Players.PlayerRemoving:Connect(function(player)
	local success = PlayerDataManager.SaveData(player)
	if success then
		print("[RNGServer] Saved data for " .. player.Name .. " on leave")
	else
		warn("[RNGServer] Failed to save data for " .. player.Name)
	end
end)

-- Auto-save every 60 seconds for all players
task.spawn(function()
	while true do
		task.wait(60)
		for _, player in Players:GetPlayers() do
			PlayerDataManager.SaveData(player)
			print("[RNGServer] Auto-saved data for " .. player.Name)
		end
	end
end)

RollEvent.OnServerEvent:Connect(function(player)
	local canRoll, msg = PlayerDataManager.CanRoll(player)
	if not canRoll then
		RollEvent:FireClient(player, {Success=false, Message=msg})
		return
	end

	-- Check if player has a crafted item equipped for luck buff
	local luckMultiplier = 1
	local equippedItem = PlayerDataManager.GetEquippedItem(player)
	if equippedItem and equippedItem.IsCrafted then
		-- Get luck buff from rarity
		local RNGConfig = require(ReplicatedStorage:WaitForChild("RNGConfig"))
		for _, rarity in ipairs(RNGConfig.Rarities) do
			if rarity.Name == equippedItem.Rarity then
				luckMultiplier = rarity.LuckBuff or 1
				print("[RNGServer] " .. player.Name .. " has luck buff: " .. luckMultiplier .. " from " .. equippedItem.ItemName)
				break
			end
		end
	end

	-- Perform roll with luck multiplier
	local rollResult = RNGSystem.PerformRollWithLuck(luckMultiplier)

	-- EXPECTED FORMAT:
	-- rollResult = { ItemName = "", Rarity = "", ItemDescription = "" }

	if not rollResult or not rollResult.ItemName then
		warn("[RNGServer] Invalid roll result")
		RollEvent:FireClient(player, {Success=false, Message="Invalid roll result"})
		return
	end

	-- Update roll time for cooldown
	PlayerDataManager.UpdateRollTime(player)

	-- Normalize the roll result to match inventory format
	local normalizedItem = {
		ItemName = rollResult.ItemName,
		Rarity = rollResult.Rarity,
		Description = rollResult.ItemDescription,
		Equipped = false,
		ObtainedAt = rollResult.Timestamp or os.time()
	}

	PlayerDataManager.AddItemToInventory(player, normalizedItem)
	PlayerDataManager.AddToRollHistory(player, normalizedItem)

	-- Send success response to client
	RollEvent:FireClient(player, {
		Success = true,
		Result = rollResult
	})

	sendFullUpdate(player)
end)

EquipEvent.OnServerEvent:Connect(function(player, index)
	print("[RNGServer] Equip request from " .. player.Name .. " for index " .. tostring(index))
	local success, equippedItem = PlayerDataManager.EquipItem(player, index)

	if success then
		print("[RNGServer] Equip successful for " .. player.Name)
		print("[RNGServer] EquippedItem data:", equippedItem.ItemName, equippedItem.Rarity)
		-- Get full equipped item data including IsCrafted
		local fullEquippedItem = PlayerDataManager.GetEquippedItem(player)
		-- Send success response to client with equipped item data
		EquipEvent:FireClient(player, {
			Success = true,
			EquippedItem = fullEquippedItem
		})
		-- Broadcast equip change to all players for visual effects
		local EquipEffectsEvent = RemoteEventsFolder:FindFirstChild("EquipEffectsEvent")
		if EquipEffectsEvent then
			EquipEffectsEvent:FireAllClients({
				Player = player,
				Action = "Equip",
				ItemData = fullEquippedItem
			})
		end
	else
		print("[RNGServer] Equip failed for " .. player.Name .. ": " .. tostring(equippedItem))
		-- Send error response to client
		EquipEvent:FireClient(player, {
			Success = false,
			Message = equippedItem or "Failed to equip item"
		})
	end

	sendFullUpdate(player)
end)

-- Handle delete item request
DeleteEvent.OnServerEvent:Connect(function(player, index)
	local success = PlayerDataManager.RemoveItemFromInventory(player, index)
	if success then
		print("[RNGServer] Item deleted at index " .. index .. " for " .. player.Name)
		sendFullUpdate(player)
	else
		warn("[RNGServer] Failed to delete item at index " .. index .. " for " .. player.Name)
	end
end)

-- Handle bulk delete request
local BulkDeleteEvent = Instance.new("RemoteEvent")
BulkDeleteEvent.Name = "BulkDeleteEvent"
BulkDeleteEvent.Parent = RemoteEventsFolder

BulkDeleteEvent.OnServerEvent:Connect(function(player, indices)
	if type(indices) ~= "table" or #indices == 0 then
		warn("[RNGServer] Invalid bulk delete request from " .. player.Name)
		return
	end

	print("[RNGServer] Bulk delete request from " .. player.Name .. " for " .. #indices .. " items")

	-- Sort indices in descending order to maintain correct indices during deletion
	table.sort(indices, function(a, b) return a > b end)

	local deletedCount = 0
	for _, index in ipairs(indices) do
		local success = PlayerDataManager.RemoveItemFromInventory(player, index)
		if success then
			deletedCount = deletedCount + 1
		end
	end

	print("[RNGServer] Successfully deleted " .. deletedCount .. "/" .. #indices .. " items for " .. player.Name)
	sendFullUpdate(player)
end)

-- Handle GetInventoryFunction request from client
GetInventoryFunction.OnServerInvoke = function(player)
	print("[RNGServer] GetInventoryFunction called by " .. player.Name)
	local data = PlayerDataManager.GetData(player)
	if not data then 
		print("[RNGServer] No data found for player")
		return {} 
	end

	print("[RNGServer] Player has " .. #data.Inventory .. " items in inventory")

	-- Return a clean copy of the inventory (NOT sorted - server keeps original order)
	local inventoryCopy = {}
	for i, item in ipairs(data.Inventory) do
		inventoryCopy[i] = {
			ItemName = item.ItemName,
			Rarity = item.Rarity,
			Description = item.Description,
			Equipped = (data.EquippedIndex == i),
			Quantity = item.Quantity or 1,
			OriginalIndex = i,
			IsCrafted = item.IsCrafted or false
		}
	end

	print("[RNGServer] EquippedIndex: " .. tostring(data.EquippedIndex))

	-- Return the inventory copy (keep OriginalIndex for client actions)
	return inventoryCopy
end

-- Handle GetInventoryForCraftingFunction request from client
local GetInventoryForCraftingFunction = RemoteEventsFolder:WaitForChild("GetInventoryForCraftingFunction")
GetInventoryForCraftingFunction.OnServerInvoke = function(player)
	print("[RNGServer] GetInventoryForCraftingFunction called by " .. player.Name)
	local data = PlayerDataManager.GetData(player)
	if not data then 
		print("[RNGServer] No data found for player")
		return {} 
	end

	-- Return inventory as a dictionary (key: "ItemName|Rarity", value: quantity)
	local groupedInventory = {}
	for _, item in ipairs(data.Inventory) do
		local key = item.ItemName .. "|" .. item.Rarity
		groupedInventory[key] = (groupedInventory[key] or 0) + (item.Quantity or 1)
	end

	print("[RNGServer] Returning " .. #data.Inventory .. " items as grouped inventory")
	return groupedInventory
end

-- Handle GetEquippedFunction request from client
GetEquippedFunction.OnServerInvoke = function(player, targetPlayer)
	-- If targetPlayer is provided, get that player's equipped item
	-- Otherwise, get the requesting player's equipped item
	local queryPlayer = targetPlayer or player
	
	print("[RNGServer] GetEquippedFunction called by " .. player.Name .. " for " .. queryPlayer.Name)
	local data = PlayerDataManager.GetData(queryPlayer)
	if not data then 
		print("[RNGServer] No data found for player")
		return nil 
	end

	if data.EquippedIndex and data.Inventory[data.EquippedIndex] then
		local equippedItem = data.Inventory[data.EquippedIndex]
		print("[RNGServer] Returning equipped item: " .. equippedItem.ItemName)
		return {
			ItemName = equippedItem.ItemName,
			Rarity = equippedItem.Rarity,
			Description = equippedItem.Description,
			IsCrafted = equippedItem.IsCrafted or false
		}
	else
		print("[RNGServer] No equipped item")
		return nil
	end
end
