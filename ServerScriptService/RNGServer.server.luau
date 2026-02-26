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

-- Create BulkDeleteEvent if it doesn't exist
local BulkDeleteEvent = RemoteEventsFolder:FindFirstChild("BulkDeleteEvent")
if not BulkDeleteEvent then
	BulkDeleteEvent = Instance.new("RemoteEvent")
	BulkDeleteEvent.Name = "BulkDeleteEvent"
	BulkDeleteEvent.Parent = RemoteEventsFolder
end

local function sendFullUpdate(player)
	local data = PlayerDataManager.GetData(player)
	if not data then return end

	local copy = {
		Inventory = {},
		TotalRolls = #data.RollHistory,
		Currency = data.Currency or 0,
	}

	for i, item in ipairs(data.Inventory) do
		copy.Inventory[i] = {
			ItemName = item.ItemName,
			Rarity = item.Rarity,
			Description = item.Description,
			Equipped = (data.EquippedIndex == i),
			Quantity = item.Quantity or 1,
			OriginalIndex = i,
			IsCrafted = item.IsCrafted or false
		}
	end

	InventoryUpdateEvent:FireClient(player, copy)
end

_G.sendFullUpdate = sendFullUpdate

Players.PlayerAdded:Connect(function(player)
	PlayerDataManager.LoadData(player)
	sendFullUpdate(player)
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerDataManager.SaveData(player)
end)

-- Auto-save every 60 seconds
task.spawn(function()
	while true do
		task.wait(60)
		for _, player in Players:GetPlayers() do
			PlayerDataManager.SaveData(player)
		end
	end
end)

RollEvent.OnServerEvent:Connect(function(player)
	local canRoll, msg = PlayerDataManager.CanRoll(player)
	if not canRoll then
		RollEvent:FireClient(player, {Success=false, Message=msg})
		return
	end

	local luckMultiplier = 1
	local equippedItem = PlayerDataManager.GetEquippedItem(player)
	if equippedItem and equippedItem.IsCrafted then
		local RNGConfig = require(ReplicatedStorage:WaitForChild("RNGConfig"))
		for _, rarity in ipairs(RNGConfig.Rarities) do
			if rarity.Name == equippedItem.Rarity then
				luckMultiplier = rarity.LuckBuff or 1
				break
			end
		end
	end

	local rollResult = RNGSystem.PerformRollWithLuck(luckMultiplier)

	if not rollResult or not rollResult.ItemName then
		RollEvent:FireClient(player, {Success=false, Message="Invalid roll result"})
		return
	end

	PlayerDataManager.UpdateRollTime(player)

	local normalizedItem = {
		ItemName = rollResult.ItemName,
		Rarity = rollResult.Rarity,
		Description = rollResult.ItemDescription,
		Equipped = false,
		ObtainedAt = rollResult.Timestamp or os.time()
	}

	PlayerDataManager.AddItemToInventory(player, normalizedItem)
	PlayerDataManager.AddToRollHistory(player, normalizedItem)

	RollEvent:FireClient(player, {
		Success = true,
		Result = rollResult
	})

	sendFullUpdate(player)
end)

EquipEvent.OnServerEvent:Connect(function(player, index)
	local success, equippedItem = PlayerDataManager.EquipItem(player, index)
	if success then
		local fullEquippedItem = PlayerDataManager.GetEquippedItem(player)
		EquipEvent:FireClient(player, {Success = true, EquippedItem = fullEquippedItem})
		local EquipEffectsEvent = RemoteEventsFolder:FindFirstChild("EquipEffectsEvent")
		if EquipEffectsEvent then
			EquipEffectsEvent:FireAllClients({Player = player, Action = "Equip", ItemData = fullEquippedItem})
		end
	else
		EquipEvent:FireClient(player, {Success = false, Message = equippedItem or "Failed to equip item"})
	end
	sendFullUpdate(player)
end)

DeleteEvent.OnServerEvent:Connect(function(player, index)
	local success = PlayerDataManager.RemoveItemFromInventory(player, index)
	if success then
		sendFullUpdate(player)
	end
end)

BulkDeleteEvent.OnServerEvent:Connect(function(player, indices)
	if type(indices) ~= "table" or #indices == 0 then return end
	table.sort(indices, function(a, b) return a > b end)
	for _, index in ipairs(indices) do
		PlayerDataManager.RemoveItemFromInventory(player, index)
	end
	sendFullUpdate(player)
end)

GetInventoryFunction.OnServerInvoke = function(player)
	local data = PlayerDataManager.GetData(player)
	if not data then return {} end
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
	return inventoryCopy
end

local GetInventoryForCraftingFunction = RemoteEventsFolder:WaitForChild("GetInventoryForCraftingFunction")
GetInventoryForCraftingFunction.OnServerInvoke = function(player)
	local data = PlayerDataManager.GetData(player)
	if not data then return {} end
	local groupedInventory = {}
	for _, item in ipairs(data.Inventory) do
		local key = item.ItemName .. "|" .. item.Rarity
		groupedInventory[key] = (groupedInventory[key] or 0) + (item.Quantity or 1)
	end
	return groupedInventory
end

GetEquippedFunction.OnServerInvoke = function(player, targetPlayer)
	local queryPlayer = targetPlayer or player
	local data = PlayerDataManager.GetData(queryPlayer)
	if not data then return nil end
	if data.EquippedIndex and data.Inventory[data.EquippedIndex] then
		local item = data.Inventory[data.EquippedIndex]
		return {ItemName = item.ItemName, Rarity = item.Rarity, Description = item.Description, IsCrafted = item.IsCrafted or false}
	end
	return nil
end

print("[RNGServer] Initialized")
