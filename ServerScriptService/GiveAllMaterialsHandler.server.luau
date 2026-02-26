-- GiveAllMaterialsHandler (Server Script - Owner Only)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))
local RNGConfig = require(ReplicatedStorage:WaitForChild("RNGConfig"))

local RemoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local GiveAllMaterialsEvent = RemoteEventsFolder:WaitForChild("GiveAllMaterialsEvent")

GiveAllMaterialsEvent.OnServerEvent:Connect(function(player)
	if player.UserId ~= game.CreatorId then
		GiveAllMaterialsEvent:FireClient(player, {Success = false, Message = "Only the server owner can use this feature"})
		return
	end

	local data = PlayerDataManager.GetData(player)
	if not data then
		GiveAllMaterialsEvent:FireClient(player, {Success = false, Message = "No player data found"})
		return
	end

	local addedCount = 0
	local currentTime = os.time()

	for rarityName, items in pairs(RNGConfig.Items) do
		for _, itemData in ipairs(items) do
			local rollResult = {
				ItemName = itemData.Name,
				Rarity = rarityName,
				ItemDescription = itemData.Description,
				Timestamp = currentTime
			}
			if PlayerDataManager.AddItemToInventory(player, rollResult) then
				addedCount += 1
			end
		end
	end

	PlayerDataManager.SaveData(player)
	GiveAllMaterialsEvent:FireClient(player, {Success = true, Message = "Added " .. addedCount .. " materials!"})
end)

print("[GiveAllMaterialsHandler] Initialized")
