--[[
	Give All Materials Handler
	Handles the GiveAllMaterialsEvent RemoteEvent
	Allows ONLY the server owner to request all materials for testing
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))
local RNGConfig = require(ReplicatedStorage:WaitForChild("RNGConfig"))

local RemoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local GiveAllMaterialsEvent = RemoteEventsFolder:WaitForChild("GiveAllMaterialsEvent")

GiveAllMaterialsEvent.OnServerEvent:Connect(function(player)
	print("[GiveAllMaterialsHandler] Request from " .. player.Name)
	
	-- Check if player is the server owner
	if player.UserId ~= game.CreatorId then
		warn("[GiveAllMaterialsHandler] Unauthorized request from " .. player.Name .. " (not the server owner)")
		GiveAllMaterialsEvent:FireClient(player, {Success = false, Message = "Only the server owner can use this feature"})
		return
	end
	
	local data = PlayerDataManager.GetData(player)
	if not data then
		warn("[GiveAllMaterialsHandler] No player data found for " .. player.Name)
		GiveAllMaterialsEvent:FireClient(player, {Success = false, Message = "No player data found"})
		return
	end

	local addedCount = 0
	local currentTime = os.time()

	-- Loop through all rarities and items
	for rarityName, items in pairs(RNGConfig.Items) do
		for _, itemData in ipairs(items) do
			-- Create roll result structure
			local rollResult = {
				ItemName = itemData.Name,
				Rarity = rarityName,
				ItemDescription = itemData.Description,
				Timestamp = currentTime
			}
			
			-- Add to inventory
			local success = PlayerDataManager.AddItemToInventory(player, rollResult)
			if success then
				addedCount = addedCount + 1
			end
		end
	end

	-- Save the data
	PlayerDataManager.SaveData(player)
	
	print("[GiveAllMaterialsHandler] Successfully added " .. addedCount .. " materials to " .. player.Name .. "'s inventory!")
	
	-- Send success response
	GiveAllMaterialsEvent:FireClient(player, {
		Success = true,
		Message = "Added " .. addedCount .. " materials to your inventory!"
	})
end)