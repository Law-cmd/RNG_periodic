--[[
	Money System
	Server-sided money system that gives players income over time
	Base rate: 1 buck per second
	Can be modified by equipped items
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataManager = require(script.Parent.PlayerDataManager)
local RNGConfig = require(ReplicatedStorage:WaitForChild("RNGConfig"))

-- Money system configuration
local MoneyConfig = {
	BaseIncomeRate = 1, -- Base bucks per second
	IncomeInterval = 1, -- How often to give money (in seconds)
}

-- Track income tasks for each player
local incomeTasks = {}

-- Calculate income rate for a player based on equipped item
local function calculateIncomeRate(player)
	local data = PlayerDataManager.GetData(player)
	if not data then
		return MoneyConfig.BaseIncomeRate
	end

	-- Get equipped item
	local equippedItem = nil
	for _, item in ipairs(data.Inventory) do
		if item.Equipped then
			equippedItem = item
			break
		end
	end

	-- Start with base rate
	local incomeRate = MoneyConfig.BaseIncomeRate

	-- If player has an equipped item, check for income modifiers
	if equippedItem then
		-- Find rarity data
		for _, rarity in ipairs(RNGConfig.Rarities) do
			if rarity.Name == equippedItem.Rarity then
				-- Add income multiplier based on rarity
				-- Higher rarity = more money per second
				local rarityMultiplier = {
					["Common"] = 1,
					["Uncommon"] = 1.5,
					["Rare"] = 2,
					["Epic"] = 3,
					["Legendary"] = 5,
					["Mythical"] = 8,
					["Divine"] = 12,
					["Exotic"] = 18,
					["Celestial"] = 25,
				}
				
				local multiplier = rarityMultiplier[rarity.Name] or 1
				incomeRate = MoneyConfig.BaseIncomeRate * multiplier
				break
			end
		end
	end

	return incomeRate
end

-- Give money to a player
local function giveMoney(player)
	local incomeRate = calculateIncomeRate(player)
	
	if incomeRate > 0 then
		local success = PlayerDataManager.AddCurrency(player, incomeRate)
		if success then
			-- Save the data
			PlayerDataManager.SaveData(player)
			
			-- Optional: Notify client of money update
			local RemoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
			if RemoteEventsFolder then
				local MoneyUpdateEvent = RemoteEventsFolder:FindFirstChild("MoneyUpdateEvent")
				if MoneyUpdateEvent then
					MoneyUpdateEvent:FireClient(player, {
						Amount = incomeRate,
						Total = PlayerDataManager.GetCurrency(player),
						IncomeRate = incomeRate
					})
				end
			end
		end
	end
end

-- Start income for a player
local function startIncome(player)
	-- Stop any existing income task
	if incomeTasks[player.UserId] then
		task.cancel(incomeTasks[player.UserId])
	end

	-- Start new income task
	incomeTasks[player.UserId] = task.spawn(function()
		while true do
			task.wait(MoneyConfig.IncomeInterval)
			if player and player.Parent == Players then
				giveMoney(player)
			else
				-- Player left, stop the task
				break
			end
		end
	end)
	
	print("[MoneySystem] Started income for " .. player.Name .. " at " .. calculateIncomeRate(player) .. " bucks/sec")
end

-- Stop income for a player
local function stopIncome(player)
	if incomeTasks[player.UserId] then
		task.cancel(incomeTasks[player.UserId])
		incomeTasks[player.UserId] = nil
		print("[MoneySystem] Stopped income for " .. player.Name)
	end
end

-- Handle player joining
Players.PlayerAdded:Connect(function(player)
	-- Wait for data to load
	task.wait(1)
	
	-- Start income
	startIncome(player)
end)

-- Handle player leaving
Players.PlayerRemoving:Connect(function(player)
	-- Stop income
	stopIncome(player)
	
	-- Save data one last time
	PlayerDataManager.SaveData(player)
end)

-- Handle players already in game
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		task.wait(1)
		startIncome(player)
	end)
end

-- Handle GetMoneyFunction requests
local RemoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local GetMoneyFunction = RemoteEventsFolder:WaitForChild("GetMoneyFunction")

GetMoneyFunction.OnServerInvoke = function(player)
	return PlayerDataManager.GetCurrency(player)
end

-- Listen for equip events to update income rate
local EquipEvent = RemoteEventsFolder:WaitForChild("EquipEvent")

EquipEvent.OnServerEvent:Connect(function(player, itemIndex)
	-- Restart income with new rate after equip
	task.wait(0.5) -- Wait for equip to complete
	startIncome(player)
end)

print("[MoneySystem] Initialized")