-- MoneySystem (Server Script)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataManager = require(script.Parent.PlayerDataManager)
local RNGConfig = require(ReplicatedStorage:WaitForChild("RNGConfig"))

local MoneyConfig = {
	BaseIncomeRate = 1,
	IncomeInterval = 1,
}

local incomeTasks = {}

local rarityMultiplier = {
	Common = 1, Uncommon = 1.5, Rare = 2, Epic = 3,
	Legendary = 5, Mythical = 8, Divine = 12, Exotic = 18, Celestial = 25,
}

local function calculateIncomeRate(player)
	local data = PlayerDataManager.GetData(player)
	if not data then return MoneyConfig.BaseIncomeRate end
	for _, item in ipairs(data.Inventory) do
		if item.Equipped then
			return MoneyConfig.BaseIncomeRate * (rarityMultiplier[item.Rarity] or 1)
		end
	end
	return MoneyConfig.BaseIncomeRate
end

local RemoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local MoneyUpdateEvent = RemoteEventsFolder:WaitForChild("MoneyUpdateEvent")

local function giveMoney(player)
	local rate = calculateIncomeRate(player)
	if rate > 0 then
		PlayerDataManager.AddCurrency(player, rate)
		MoneyUpdateEvent:FireClient(player, {
			Amount = rate,
			Total = PlayerDataManager.GetCurrency(player),
			IncomeRate = rate
		})
	end
end

local function startIncome(player)
	if incomeTasks[player.UserId] then
		task.cancel(incomeTasks[player.UserId])
	end
	incomeTasks[player.UserId] = task.spawn(function()
		while true do
			task.wait(MoneyConfig.IncomeInterval)
			if player and player.Parent == Players then
				giveMoney(player)
			else
				break
			end
		end
	end)
end

local function stopIncome(player)
	if incomeTasks[player.UserId] then
		task.cancel(incomeTasks[player.UserId])
		incomeTasks[player.UserId] = nil
	end
end

Players.PlayerAdded:Connect(function(player)
	task.wait(1)
	startIncome(player)
end)

Players.PlayerRemoving:Connect(function(player)
	stopIncome(player)
	PlayerDataManager.SaveData(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		task.wait(1)
		startIncome(player)
	end)
end

local GetMoneyFunction = RemoteEventsFolder:WaitForChild("GetMoneyFunction")
GetMoneyFunction.OnServerInvoke = function(player)
	return PlayerDataManager.GetCurrency(player)
end

local EquipEvent = RemoteEventsFolder:WaitForChild("EquipEvent")
EquipEvent.OnServerEvent:Connect(function(player)
	task.wait(0.5)
	startIncome(player)
end)

print("[MoneySystem] Initialized")
