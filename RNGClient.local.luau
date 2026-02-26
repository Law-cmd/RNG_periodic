--[[
	RNG Client Script
	Handles client-side interactions and UI updates
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for RemoteEvents to be created by server
local RemoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local RollEvent = RemoteEventsFolder:WaitForChild("RollEvent")
local EquipEvent = RemoteEventsFolder:WaitForChild("EquipEvent")
local DeleteEvent = RemoteEventsFolder:WaitForChild("DeleteEvent")
local BulkDeleteEvent = RemoteEventsFolder:WaitForChild("BulkDeleteEvent")
local InventoryUpdateEvent = RemoteEventsFolder:WaitForChild("InventoryUpdateEvent")
local GetInventoryFunction = RemoteEventsFolder:WaitForChild("GetInventoryFunction")
local CraftingEvent = RemoteEventsFolder:WaitForChild("CraftingEvent")
local GetInventoryForCraftingFunction = RemoteEventsFolder:WaitForChild("GetInventoryForCraftingFunction")
-- Note: OpenPedestalSelection is set up below once the server creates it

-- Require modules
local UIHandler = require(script.Parent.UIHandler)
local RollEffects = require(script.Parent.RollEffects)
local EquipEffects = require(script.Parent.EquipEffects)
local RNGConfig = require(ReplicatedStorage:WaitForChild("RNGConfig"))
local CraftingRecipes = require(ReplicatedStorage:WaitForChild("CraftingRecipes"))

-- Create UI
local gui = UIHandler.CreateUI(playerGui)
local mainFrame = gui:WaitForChild("MainFrame")
local rollButton = mainFrame:WaitForChild("RollButton")
local inventoryButton = mainFrame:WaitForChild("InventoryButton")
local collectionButton = mainFrame:WaitForChild("CollectionButton")
local craftingButton = mainFrame:WaitForChild("CraftingButton")
local craftedInventoryButton = mainFrame:WaitForChild("CraftedInventoryButton")
local autoRollButton = mainFrame:WaitForChild("AutoRollButton")

-- State
local isRolling = false
local lastRollTime = 0
local cachedInventory = {}
local playerStats = {
	TotalRolls = 0,
	Currency = 0
}
local isEquipping = false -- Prevent multiple equip clicks

-- Auto roll state
local isAutoRolling = false
local autoRollInterval = 0 -- seconds between auto rolls (0 = as fast as cooldown allows)
local autoRollConnection = nil

-- Get rarity index
local function getRarityIndex(rarityName)
	for i, rarity in ipairs(RNGConfig.Rarities) do
		if rarity.Name == rarityName then
			return i
		end
	end
	return 1
end

-- Auto roll function
local function startAutoRoll()
	if isAutoRolling then return end
	isAutoRolling = true
	UIHandler.SetAutoRollState(gui, true)

	autoRollConnection = task.spawn(function()
		while isAutoRolling do
			-- Check if we can roll
			local activeBuffs = EquipEffects.GetActiveBuffs(player)
			local rollSpeedBuff = activeBuffs and activeBuffs.RollSpeedBuff or 0
			local effectiveCooldown = RNGConfig.RollCooldown * (1 - rollSpeedBuff)
			
			local currentTime = tick()
			local timeSinceLastRoll = currentTime - lastRollTime

			if timeSinceLastRoll >= effectiveCooldown then
				-- Perform roll
				RollEvent:FireServer()
				-- Wait for the roll to complete
				task.wait(0.5)
			else
				-- Wait until cooldown is over
				local waitTime = effectiveCooldown - timeSinceLastRoll
				task.wait(waitTime)
			end

			-- Wait for the auto roll interval
			task.wait(autoRollInterval)
		end
	end)
end

local function stopAutoRoll()
	isAutoRolling = false
	UIHandler.SetAutoRollState(gui, false)
	if autoRollConnection then
		autoRollConnection = nil
	end
end

local function toggleAutoRoll()
	if isAutoRolling then
		stopAutoRoll()
	else
		startAutoRoll()
	end
end

-- Handle roll button click
rollButton.MouseButton1Click:Connect(function()
	if isRolling then return end

	-- Check cooldown with roll speed buff
	local activeBuffs = EquipEffects.GetActiveBuffs(player)
	local rollSpeedBuff = activeBuffs and activeBuffs.RollSpeedBuff or 0
	local effectiveCooldown = RNGConfig.RollCooldown * (1 - rollSpeedBuff)
	
	local currentTime = tick()
	local timeSinceLastRoll = currentTime - lastRollTime

	if timeSinceLastRoll < effectiveCooldown then
		local timeRemaining = effectiveCooldown - timeSinceLastRoll
		UIHandler.UpdateCooldown(gui, timeRemaining)
		return
	end

	-- Set rolling state
	isRolling = true
	UIHandler.SetRollButtonEnabled(gui, false)

	-- Request roll from server
	RollEvent:FireServer()
end)

-- Handle roll response
RollEvent.OnClientEvent:Connect(function(response)
	if response.Broadcast then
		-- Show broadcast for other players' rare rolls
		UIHandler.ShowBroadcast(gui, response.PlayerName, response.Result)
	elseif response.Success then
		-- Update UI with result
		UIHandler.UpdateResult(gui, response.Result)

		-- Play effects
		local rarityIndex = getRarityIndex(response.Result.Rarity)
		RollEffects.PlayRollEffects(player, response.Result.Rarity, response.Result.RarityColor, rarityIndex)

		-- Update state
		lastRollTime = tick()

		-- Start cooldown timer with roll speed buff
		local activeBuffs = EquipEffects.GetActiveBuffs(player)
		local rollSpeedBuff = activeBuffs and activeBuffs.RollSpeedBuff or 0
		local effectiveCooldown = RNGConfig.RollCooldown * (1 - rollSpeedBuff)
		
		task.spawn(function()
			for i = effectiveCooldown, 0, -0.1 do
				UIHandler.UpdateCooldown(gui, i)
				task.wait(0.1)
			end
			UIHandler.UpdateCooldown(gui, 0)
		end)

		-- Re-enable button after a short delay
		task.wait(0.5)
		isRolling = false
		UIHandler.SetRollButtonEnabled(gui, true)
	else
		-- Show error message
		UIHandler.UpdateCooldown(gui, 0)
		warn("Roll failed: " .. (response.Message or "Unknown error"))

		isRolling = false
		UIHandler.SetRollButtonEnabled(gui, true)
	end
end)

-- Handle Pedestal UI (deferred so we don't block script startup)
task.spawn(function()
	local OpenPedestalSelectionEvent = RemoteEventsFolder:WaitForChild("OpenPedestalSelection", 30)
	if not OpenPedestalSelectionEvent then
		warn("[RNGClient] OpenPedestalSelection event not found after 30s!")
		return
	end
	OpenPedestalSelectionEvent.OnClientEvent:Connect(function(itemStand, craftedItems)
		UIHandler.CreatePedestalSelectionUI(playerGui, craftedItems, itemStand)
	end)
end)

-- Create inventory UI for crafted items
local function createInventoryUIForCrafted(playerGui, inventory)
	local invGui = Instance.new("ScreenGui")
	invGui.Name = "CraftedInventoryGui"
	invGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	invGui.DisplayOrder = 100
	invGui.Parent = playerGui

	-- Inventory frame (responsive for mobile)
	local invFrame = Instance.new("Frame")
	invFrame.Name = "InventoryFrame"
	invFrame.Size = UDim2.new(0.9, 0, 0.8, 0)
	invFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	invFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	invFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	invFrame.BorderSizePixel = 0
	invFrame.Active = false -- Don't block clicks on transparent areas
	invFrame.Parent = invGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 15)
	corner.Parent = invFrame

	-- Title (responsive for mobile)
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -70, 0, 50)
	title.Position = UDim2.new(0, 10, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "CRAFTED ITEMS"
	title.TextColor3 = Color3.fromRGB(200, 100, 200)
	title.TextSize = 20
	title.Font = Enum.Font.GothamBold
	title.Parent = invFrame

	-- Close button (larger for mobile)
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 60, 0, 60)
	closeButton.Position = UDim2.new(1, -70, 0, 10)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.Text = "✕"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 30
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = invFrame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton

	-- Scroll frame for items (responsive for mobile)
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, -20, 1, -80)
	scrollFrame.Position = UDim2.new(0, 10, 0, 70)
	scrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 10
	scrollFrame.Parent = invFrame

	local scrollCorner = Instance.new("UICorner")
	scrollCorner.CornerRadius = UDim.new(0, 10)
	scrollCorner.Parent = scrollFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 5)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = scrollFrame

	-- Close button functionality
	closeButton.MouseButton1Click:Connect(function()
		invGui:Destroy()
	end)

	-- Track selected items
	local selectedItems = {}
	local itemFrames = {}

	-- Function to display items
	local function displayItems(itemsToDisplay)
		print("[CraftedInventory] displayItems called with " .. #itemsToDisplay .. " items")
		-- Check if scrollFrame still exists
		if not scrollFrame or not scrollFrame.Parent then
			print("[CraftedInventory] scrollFrame is invalid")
			return
		end
		-- Clear existing items
		for _, child in ipairs(scrollFrame:GetChildren()) do
			if child:IsA("Frame") or child:IsA("TextLabel") then
				child:Destroy()
			end
		end

		if #itemsToDisplay == 0 then
			print("[CraftedInventory] No items to display")
			local noItems = Instance.new("TextLabel")
			noItems.Size = UDim2.new(1, -10, 0, 50)
			noItems.BackgroundTransparency = 1
			noItems.Text = "No crafted items yet!"
			noItems.TextColor3 = Color3.fromRGB(150, 150, 150)
			noItems.TextSize = 16
			noItems.Font = Enum.Font.Gotham
			noItems.Parent = scrollFrame
			return
		end

		-- Sort items by rarity
		local sortedItems = {}
		for i, item in ipairs(itemsToDisplay) do
			sortedItems[i] = item
		end

		table.sort(sortedItems, function(a, b)
			local rarityA = getRarityIndex(a.Rarity)
			local rarityB = getRarityIndex(b.Rarity)
			if rarityA ~= rarityB then
				return rarityA < rarityB
			end
			return a.ItemName < b.ItemName
		end)

		-- Display each item
		for i, item in ipairs(sortedItems) do
			selectedItems[i] = false

			local itemFrame = Instance.new("Frame")
			itemFrame.Size = UDim2.new(1, -10, 0, 115)
			itemFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
			itemFrame.BorderSizePixel = 0
			itemFrame.Parent = scrollFrame

			local itemCorner = Instance.new("UICorner")
			itemCorner.CornerRadius = UDim.new(0, 8)
			itemCorner.Parent = itemFrame

			-- Get rarity color
			local rarityColor = Color3.fromRGB(200, 200, 200)
			for _, rarity in ipairs(RNGConfig.Rarities) do
				if rarity.Name == item.Rarity then
					rarityColor = rarity.Color
					break
				end
			end

			local stroke = Instance.new("UIStroke")
			stroke.Color = rarityColor
			stroke.Thickness = 2
			stroke.Parent = itemFrame

			-- Add crafted badge if item is crafted
			if item.IsCrafted then
				local craftedBadge = Instance.new("TextLabel")
				craftedBadge.Size = UDim2.new(0, 60, 0, 20)
				craftedBadge.Position = UDim2.new(1, -70, 0, 5)
				craftedBadge.BackgroundColor3 = Color3.fromRGB(150, 100, 200)
				craftedBadge.BorderSizePixel = 0
				craftedBadge.Text = "⚒️"
				craftedBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
				craftedBadge.TextSize = 14
				craftedBadge.Font = Enum.Font.GothamBold
				craftedBadge.Parent = itemFrame

				local badgeCorner = Instance.new("UICorner")
				badgeCorner.CornerRadius = UDim.new(0, 4)
				badgeCorner.Parent = craftedBadge
			end

			-- Selection checkbox
			local checkbox = Instance.new("TextButton")
			checkbox.Name = "Checkbox"
			checkbox.Size = UDim2.new(0, 40, 0, 40)
			checkbox.Position = UDim2.new(0, 10, 0.5, -20)
			checkbox.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
			checkbox.Text = "☐"
			checkbox.TextColor3 = Color3.fromRGB(200, 200, 200)
			checkbox.TextSize = 24
			checkbox.Font = Enum.Font.GothamBold
			checkbox.Parent = itemFrame

			local checkboxCorner = Instance.new("UICorner")
			checkboxCorner.CornerRadius = UDim.new(0, 6)
			checkboxCorner.Parent = checkbox

			checkbox.MouseButton1Click:Connect(function()
				selectedItems[i] = not selectedItems[i]
				if selectedItems[i] then
					checkbox.Text = "☑"
					checkbox.TextColor3 = Color3.fromRGB(100, 200, 100)
				else
					checkbox.Text = "☐"
					checkbox.TextColor3 = Color3.fromRGB(200, 200, 200)
				end
			end)

			local itemName = Instance.new("TextLabel")
			itemName.Size = UDim2.new(0.5, -60, 0, 30)
			itemName.Position = UDim2.new(0, 60, 0, 5)
			itemName.BackgroundTransparency = 1
			local quantity = item.Quantity or 1
			itemName.Text = quantity > 1 and (item.ItemName .. " x" .. quantity) or item.ItemName
			itemName.TextColor3 = Color3.fromRGB(255, 255, 255)
			itemName.TextSize = 18
			itemName.Font = Enum.Font.GothamBold
			itemName.TextXAlignment = Enum.TextXAlignment.Left
			itemName.Parent = itemFrame

			local itemRarity = Instance.new("TextLabel")
			itemRarity.Size = UDim2.new(0.5, -60, 0, 25)
			itemRarity.Position = UDim2.new(0, 60, 0, 35)
			itemRarity.BackgroundTransparency = 1
			itemRarity.Text = item.Rarity
			itemRarity.TextColor3 = rarityColor
			itemRarity.TextSize = 16
			itemRarity.Font = Enum.Font.Gotham
			itemRarity.TextXAlignment = Enum.TextXAlignment.Left
			itemRarity.Parent = itemFrame

			-- Add buff description for crafted items
			if item.Description then
				local itemDesc = Instance.new("TextLabel")
				itemDesc.Size = UDim2.new(1, -70, 0, 50)
				itemDesc.Position = UDim2.new(0, 60, 0, 60)
				itemDesc.BackgroundTransparency = 1
				itemDesc.Text = item.Description
				itemDesc.TextColor3 = Color3.fromRGB(150, 200, 255)
				itemDesc.TextSize = 11
				itemDesc.Font = Enum.Font.Gotham
				itemDesc.TextXAlignment = Enum.TextXAlignment.Left
				itemDesc.TextYAlignment = Enum.TextYAlignment.Top
				itemDesc.TextWrapped = true
				itemDesc.Parent = itemFrame
			end

			local equipButton = Instance.new("TextButton")
			equipButton.Size = UDim2.new(0, 90, 0, 50)
			equipButton.Position = UDim2.new(1, -190, 0.5, -25)
			equipButton.BackgroundColor3 = item.Equipped and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(100, 100, 120)
			equipButton.Text = item.Equipped and "EQUIPPED" or "EQUIP"
			equipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			equipButton.TextSize = 14
			equipButton.Font = Enum.Font.GothamBold
			equipButton.Parent = itemFrame

			local equipCorner = Instance.new("UICorner")
			equipCorner.CornerRadius = UDim.new(0, 6)
			equipCorner.Parent = equipButton

			equipButton.MouseButton1Click:Connect(function()
				if isEquipping then return end -- Prevent multiple clicks
				isEquipping = true
				equipButton.Text = "EQUIPPING..."
				EquipEvent:FireServer(item.OriginalIndex)
				-- Reset after a short delay
				task.delay(0.5, function()
					isEquipping = false
					if invGui and invGui.Parent then
						-- Refresh inventory to update button state
						refreshInventory()
					end
				end)
			end)

			local deleteButton = Instance.new("TextButton")
			deleteButton.Size = UDim2.new(0, 90, 0, 50)
			deleteButton.Position = UDim2.new(1, -95, 0.5, -25)
			deleteButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
			deleteButton.Text = "DELETE"
			deleteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			deleteButton.TextSize = 14
			deleteButton.Font = Enum.Font.GothamBold
			deleteButton.Parent = itemFrame

			local deleteCorner = Instance.new("UICorner")
			deleteCorner.CornerRadius = UDim.new(0, 6)
			deleteCorner.Parent = deleteButton

			deleteButton.MouseButton1Click:Connect(function()
				DeleteEvent:FireServer(item.OriginalIndex)
			end)

			itemFrames[i] = {
				frame = itemFrame,
				checkbox = checkbox
			}
		end

		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollFrame.UIListLayout.AbsoluteContentSize.Y + 10)
	end

	-- Initial display
	displayItems(inventory)

	-- Function to refresh inventory display
	local function refreshInventory()
		-- Filter for crafted items only
		local craftedItems = {}
		for _, item in ipairs(cachedInventory) do
			if item.IsCrafted then
				table.insert(craftedItems, item)
			end
		end
		print("[CraftedInventory] Found " .. #craftedItems .. " crafted items out of " .. #cachedInventory .. " total")
		displayItems(craftedItems)
	end

	-- Listen for inventory updates and refresh
	InventoryUpdateEvent.OnClientEvent:Connect(function(data)
		if data then
			cachedInventory = data.Inventory or {}
			playerStats.TotalRolls = data.TotalRolls or 0
			playerStats.Currency = data.Currency or 0
			print("[CraftedInventory] Inventory updated: " .. #cachedInventory .. " items")
			-- Refresh the crafted inventory display if it's open
			if invGui and invGui.Parent and invGui.Parent == playerGui then
				print("[CraftedInventory] Refreshing display...")
				refreshInventory()
			else
				print("[CraftedInventory] UI not open or invalid")
			end
		end
	end)
end

-- Create inventory UI
local function createInventoryUI()
	local invGui = Instance.new("ScreenGui")
	invGui.Name = "InventoryGui"
	invGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	invGui.DisplayOrder = 100
	invGui.Parent = playerGui

	-- Inventory frame (responsive for mobile)
	local invFrame = Instance.new("Frame")
	invFrame.Name = "InventoryFrame"
	invFrame.Size = UDim2.new(0.9, 0, 0.8, 0)
	invFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	invFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	invFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	invFrame.BorderSizePixel = 0
	invFrame.Active = false -- Don't block clicks on transparent areas
	invFrame.Parent = invGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 15)
	corner.Parent = invFrame

	-- Title (responsive for mobile)
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -70, 0, 50)
	title.Position = UDim2.new(0, 10, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "ELEMENTS"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 20
	title.Font = Enum.Font.GothamBold
	title.Parent = invFrame

	-- Close button (larger for mobile)
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 60, 0, 60)
	closeButton.Position = UDim2.new(1, -70, 0, 10)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.Text = "✕"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 30
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = invFrame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton

	-- Control panel for bulk actions (responsive for mobile)
	local controlPanel = Instance.new("Frame")
	controlPanel.Name = "ControlPanel"
	controlPanel.Size = UDim2.new(1, -20, 0, 70)
	controlPanel.Position = UDim2.new(0, 10, 0, 70)
	controlPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	controlPanel.BorderSizePixel = 0
	controlPanel.Parent = invFrame

	local controlCorner = Instance.new("UICorner")
	controlCorner.CornerRadius = UDim.new(0, 10)
	controlCorner.Parent = controlPanel

	-- Scroll frame for items (responsive for mobile)
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, -20, 1, -140)
	scrollFrame.Position = UDim2.new(0, 10, 0, 140)
	scrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 10
	scrollFrame.Parent = invFrame

	local scrollCorner = Instance.new("UICorner")
	scrollCorner.CornerRadius = UDim.new(0, 10)
	scrollCorner.Parent = scrollFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 5)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = scrollFrame

	-- Close button functionality
	closeButton.MouseButton1Click:Connect(function()
		invGui:Destroy()
	end)

	return invGui, scrollFrame
end

-- Handle inventory updates from server
InventoryUpdateEvent.OnClientEvent:Connect(function(data)
	if data then
		cachedInventory = data.Inventory or {}
		playerStats.TotalRolls = data.TotalRolls or 0
		playerStats.Currency = data.Currency or 0
		print("Inventory updated: " .. #cachedInventory .. " items, " .. playerStats.TotalRolls .. " total rolls")
	end
end)

-- Show inventory
inventoryButton.MouseButton1Click:Connect(function()
	print("Inventory button clicked!")
	
	-- Check if inventory is already open
	if playerGui:FindFirstChild("InventoryGui") then
		print("Inventory already open, returning")
		return
	end

	print("Creating inventory UI...")
	local invGui, scrollFrame = createInventoryUI()

	-- Use cached inventory first, fall back to server request
	local inventory = cachedInventory
	print("Cached inventory has " .. #inventory .. " items")

	-- If no cached inventory, request from server
	if not inventory or #inventory == 0 then
		print("No cached inventory, requesting from server...")
		local success, serverInventory = pcall(function()
			return GetInventoryFunction:InvokeServer()
		end)

		print("Server request success:", success, "Result type:", type(serverInventory))

		if success and serverInventory then
			inventory = serverInventory
			cachedInventory = serverInventory
			print("Received " .. #inventory .. " items from server")
		else
			warn("Failed to get inventory: " .. tostring(serverInventory))
			local errorLabel = Instance.new("TextLabel")
			errorLabel.Size = UDim2.new(1, -10, 0, 50)
			errorLabel.BackgroundTransparency = 1
			errorLabel.Text = "Error loading inventory!"
			errorLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
			errorLabel.TextSize = 16
			errorLabel.Font = Enum.Font.Gotham
			errorLabel.Parent = scrollFrame
			return
		end
	end

	print("Displaying inventory with " .. #inventory .. " items")
	print("First item data:", inventory[1] and inventory[1].ItemName or "No items")

	if #inventory == 0 then
		local noItems = Instance.new("TextLabel")
		noItems.Size = UDim2.new(1, -10, 0, 50)
		noItems.BackgroundTransparency = 1
		noItems.Text = "No elements yet! Roll to get started."
		noItems.TextColor3 = Color3.fromRGB(150, 150, 150)
		noItems.TextSize = 16
		noItems.Font = Enum.Font.Gotham
		noItems.Parent = scrollFrame
		return
	end

	-- Track selected items
	local selectedItems = {}
	local itemFrames = {}

	-- Function to display items
	local function displayItems(itemsToDisplay)
		-- Clear existing items
		for _, child in ipairs(scrollFrame:GetChildren()) do
			if child:IsA("Frame") or child:IsA("TextLabel") then
				child:Destroy()
			end
		end

		if #itemsToDisplay == 0 then
			local noItems = Instance.new("TextLabel")
			noItems.Size = UDim2.new(1, -10, 0, 50)
			noItems.BackgroundTransparency = 1
			noItems.Text = "No elements yet! Roll to get started."
			noItems.TextColor3 = Color3.fromRGB(150, 150, 150)
			noItems.TextSize = 16
			noItems.Font = Enum.Font.Gotham
			noItems.Parent = scrollFrame
			return
		end

		-- Sort items by rarity
		local sortedItems = {}
		for i, item in ipairs(itemsToDisplay) do
			sortedItems[i] = item
		end

		table.sort(sortedItems, function(a, b)
			local rarityA = getRarityIndex(a.Rarity)
			local rarityB = getRarityIndex(b.Rarity)
			if rarityA ~= rarityB then
				return rarityA < rarityB
			end
			return a.ItemName < b.ItemName
		end)

		-- Display each item
		for i, item in ipairs(sortedItems) do
			selectedItems[i] = false

			local itemFrame = Instance.new("Frame")
			itemFrame.Size = UDim2.new(1, -10, 0, 80)
			itemFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
			itemFrame.BorderSizePixel = 0
			itemFrame.Parent = scrollFrame

			local itemCorner = Instance.new("UICorner")
			itemCorner.CornerRadius = UDim.new(0, 8)
			itemCorner.Parent = itemFrame

			-- Get rarity color
			local rarityColor = Color3.fromRGB(200, 200, 200)
			for _, rarity in ipairs(RNGConfig.Rarities) do
				if rarity.Name == item.Rarity then
					rarityColor = rarity.Color
					break
				end
			end

			local stroke = Instance.new("UIStroke")
			stroke.Color = rarityColor
			stroke.Thickness = 2
			stroke.Parent = itemFrame

			-- Add crafted badge if item is crafted
			if item.IsCrafted then
				local craftedBadge = Instance.new("TextLabel")
				craftedBadge.Size = UDim2.new(0, 60, 0, 20)
				craftedBadge.Position = UDim2.new(1, -70, 0, 5)
				craftedBadge.BackgroundColor3 = Color3.fromRGB(150, 100, 200)
				craftedBadge.BorderSizePixel = 0
				craftedBadge.Text = "⚒️"
				craftedBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
				craftedBadge.TextSize = 14
				craftedBadge.Font = Enum.Font.GothamBold
				craftedBadge.Parent = itemFrame

				local badgeCorner = Instance.new("UICorner")
				badgeCorner.CornerRadius = UDim.new(0, 4)
				badgeCorner.Parent = craftedBadge
			end

			-- Selection checkbox
			local checkbox = Instance.new("TextButton")
			checkbox.Name = "Checkbox"
			checkbox.Size = UDim2.new(0, 40, 0, 40)
			checkbox.Position = UDim2.new(0, 10, 0.5, -20)
			checkbox.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
			checkbox.Text = "☐"
			checkbox.TextColor3 = Color3.fromRGB(200, 200, 200)
			checkbox.TextSize = 24
			checkbox.Font = Enum.Font.GothamBold
			checkbox.Parent = itemFrame

			local checkboxCorner = Instance.new("UICorner")
			checkboxCorner.CornerRadius = UDim.new(0, 6)
			checkboxCorner.Parent = checkbox

			checkbox.MouseButton1Click:Connect(function()
				selectedItems[i] = not selectedItems[i]
				if selectedItems[i] then
					checkbox.Text = "☑"
					checkbox.TextColor3 = Color3.fromRGB(100, 200, 100)
				else
					checkbox.Text = "☐"
					checkbox.TextColor3 = Color3.fromRGB(200, 200, 200)
				end
			end)

			local itemName = Instance.new("TextLabel")
			itemName.Size = UDim2.new(0.5, -60, 0, 30)
			itemName.Position = UDim2.new(0, 60, 0, 5)
			itemName.BackgroundTransparency = 1
			local quantity = item.Quantity or 1
			itemName.Text = quantity > 1 and (item.ItemName .. " x" .. quantity) or item.ItemName
			itemName.TextColor3 = Color3.fromRGB(255, 255, 255)
			itemName.TextSize = 18
			itemName.Font = Enum.Font.GothamBold
			itemName.TextXAlignment = Enum.TextXAlignment.Left
			itemName.Parent = itemFrame

			local itemRarity = Instance.new("TextLabel")
			itemRarity.Size = UDim2.new(0.5, -60, 0, 25)
			itemRarity.Position = UDim2.new(0, 60, 0, 35)
			itemRarity.BackgroundTransparency = 1
			itemRarity.Text = item.Rarity
			itemRarity.TextColor3 = rarityColor
			itemRarity.TextSize = 16
			itemRarity.Font = Enum.Font.Gotham
			itemRarity.TextXAlignment = Enum.TextXAlignment.Left
			itemRarity.Parent = itemFrame

			local equipButton = Instance.new("TextButton")
			equipButton.Size = UDim2.new(0, 90, 0, 50)
			equipButton.Position = UDim2.new(1, -190, 0.5, -25)
			equipButton.BackgroundColor3 = item.Equipped and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(100, 100, 120)
			equipButton.Text = item.Equipped and "EQUIPPED" or "EQUIP"
			equipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			equipButton.TextSize = 14
			equipButton.Font = Enum.Font.GothamBold
			equipButton.Parent = itemFrame

			local equipCorner = Instance.new("UICorner")
			equipCorner.CornerRadius = UDim.new(0, 6)
			equipCorner.Parent = equipButton

			equipButton.MouseButton1Click:Connect(function()
				EquipEvent:FireServer(item.OriginalIndex)
			end)

			local deleteButton = Instance.new("TextButton")
			deleteButton.Size = UDim2.new(0, 90, 0, 50)
			deleteButton.Position = UDim2.new(1, -95, 0.5, -25)
			deleteButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
			deleteButton.Text = "DELETE"
			deleteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			deleteButton.TextSize = 14
			deleteButton.Font = Enum.Font.GothamBold
			deleteButton.Parent = itemFrame

			local deleteCorner = Instance.new("UICorner")
			deleteCorner.CornerRadius = UDim.new(0, 6)
			deleteCorner.Parent = deleteButton

			deleteButton.MouseButton1Click:Connect(function()
				DeleteEvent:FireServer(item.OriginalIndex)
			end)

			itemFrames[i] = {
				frame = itemFrame,
				checkbox = checkbox
			}
		end

		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollFrame.UIListLayout.AbsoluteContentSize.Y + 10)
	end

	-- Initial display
	displayItems(inventory)

	-- Function to refresh inventory display
	local function refreshInventory()
		-- Use cached inventory
		inventory = cachedInventory
		displayItems(inventory)
	end

	-- Listen for inventory updates and refresh
	InventoryUpdateEvent.OnClientEvent:Connect(function(data)
		if data then
			cachedInventory = data.Inventory or {}
			playerStats.TotalRolls = data.TotalRolls or 0
			playerStats.Currency = data.Currency or 0
			print("Inventory updated: " .. #cachedInventory .. " items")
			-- Refresh the inventory display if it's open
			if invGui and invGui.Parent then
				refreshInventory()
			end
		end
	end)
end)


-- Handle equip response
EquipEvent.OnClientEvent:Connect(function(response)
	print("[RNGClient] EquipEvent received. Success:", response.Success)
	if response.Success then
		print("[RNGClient] Element equipped successfully!")
		-- Apply equip effects
		if response.EquippedItem then
			print("[RNGClient] EquippedItem data:", response.EquippedItem.ItemName, response.EquippedItem.Rarity, "IsCrafted:", response.EquippedItem.IsCrafted)
			EquipEffects.EquipElement(player, response.EquippedItem)
			
			-- Show buff notification if crafted
			if response.EquippedItem.IsCrafted then
				local RNGConfig = require(ReplicatedStorage:WaitForChild("RNGConfig"))
				local rarityData = nil
				for _, r in ipairs(RNGConfig.Rarities) do
					if r.Name == response.EquippedItem.Rarity then
						rarityData = r
						break
					end
				end
				
				if rarityData then
					local rollSpeedBuff = math.floor((rarityData.RollSpeedBuff or 0) * 100)
					local luckBuff = rarityData.LuckBuff or 1
					print("[RNGClient] Buffs applied: Roll Speed +" .. rollSpeedBuff .. "%, Luck x" .. luckBuff)
				end
			end
		else
			print("[RNGClient] No EquippedItem in response, requesting from server...")
			-- Fallback: Request equipped item from server
			task.spawn(function()
				local RemoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
				local GetEquippedFunction = RemoteEventsFolder:FindFirstChild("GetEquippedFunction")
				if GetEquippedFunction then
					local success, equippedItem = pcall(function()
						return GetEquippedFunction:InvokeServer()
					end)
					if success and equippedItem then
						print("[RNGClient] Got equipped item from server:", equippedItem.ItemName)
						EquipEffects.EquipElement(player, equippedItem)
					else
						print("[RNGClient] Failed to get equipped item from server")
					end
				else
					print("[RNGClient] GetEquippedFunction not found")
				end
			end)
		end
	else
		warn("[RNGClient] Failed to equip element: " .. (response.Message or "Unknown error"))
	end
end)

-- Handle character respawn
player.CharacterAdded:Connect(function(character)
	EquipEffects.OnCharacterAdded(player, character)
end)

-- Apply effects if character already exists
if player.Character then
	EquipEffects.OnCharacterAdded(player, player.Character)
end

-- Handle collection button click
collectionButton.MouseButton1Click:Connect(function()
	-- Check if collection is already open
	if playerGui:FindFirstChild("CollectionGui") then
		return
	end

	-- Use cached inventory
	local ownedItems = cachedInventory

	-- If no cached inventory, request from server
	if not ownedItems or #ownedItems == 0 then
		local success, serverInventory = pcall(function()
			return GetInventoryFunction:InvokeServer()
		end)

		if success and serverInventory then
			ownedItems = serverInventory
			cachedInventory = serverInventory
		end
	end

	-- Create collection UI
	UIHandler.CreateCollectionUI(playerGui, ownedItems)
end)

-- Handle crafted inventory button click
craftedInventoryButton.MouseButton1Click:Connect(function()
	-- Check if crafted inventory is already open
	if playerGui:FindFirstChild("CraftedInventoryGui") then
		return
	end

	-- Use cached inventory
	local inventory = cachedInventory

	-- If no cached inventory, request from server
	if not inventory or #inventory == 0 then
		local success, serverInventory = pcall(function()
			return GetInventoryFunction:InvokeServer()
		end)

		if success and serverInventory then
			inventory = serverInventory
			cachedInventory = serverInventory
		end
	end

	-- Filter for crafted items only
	local craftedItems = {}
	for _, item in ipairs(inventory) do
		if item.IsCrafted then
			table.insert(craftedItems, item)
		end
	end

	-- Create inventory UI for crafted items
	createInventoryUIForCrafted(playerGui, craftedItems)
end)

-- Handle auto roll button click
autoRollButton.MouseButton1Click:Connect(function()
	toggleAutoRoll()
end)

-- Handle crafting button click
craftingButton.MouseButton1Click:Connect(function()
	-- Check if crafting is already open
	if playerGui:FindFirstChild("CraftingGui") then
		return
	end

	-- Get inventory from server
	local success, inventory = pcall(function()
		return GetInventoryForCraftingFunction:InvokeServer()
	end)

	if not success or not inventory then
		warn("Failed to get inventory for crafting")
		return
	end

	-- Create crafting UI
	local craftingResult = UIHandler.CreateCraftingUI(playerGui, inventory, CraftingRecipes.Recipes)
	local craftingGui = craftingResult.Gui
	local recipesScroll = craftingResult.RecipesScroll
	local detailsScroll = craftingResult.DetailsScroll
	local detailsTitle = craftingResult.DetailsTitle

	-- Build inventory lookup table
	local inventoryLookup = {}
	for key, quantity in pairs(inventory) do
		inventoryLookup[key] = quantity
	end

	-- Track currently selected recipe
	local selectedRecipeIndex = nil

	-- Function to show recipe details
	local function showRecipeDetails(recipeIndex)
		selectedRecipeIndex = recipeIndex
		local recipe = CraftingRecipes.Recipes[recipeIndex]
		if not recipe then return end

		-- Update title
		detailsTitle.Text = recipe.Result.Name .. " (" .. recipe.Result.Rarity .. ")"

		-- Clear previous details (except the layout)
		for _, child in ipairs(detailsScroll:GetChildren()) do
			if child.ClassName ~= "UIListLayout" then
				child:Destroy()
			end
		end

		-- Show description
		local descFrame = Instance.new("Frame")
		descFrame.Size = UDim2.new(1, -10, 0, 60)
		descFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		descFrame.BorderSizePixel = 0
		descFrame.Parent = detailsScroll

		local descCorner = Instance.new("UICorner")
		descCorner.CornerRadius = UDim.new(0, 8)
		descCorner.Parent = descFrame

		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(1, -20, 1, 0)
		descLabel.Position = UDim2.new(0, 10, 0, 0)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = recipe.Result.Description
		descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		descLabel.TextSize = 14
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextWrapped = true
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextYAlignment = Enum.TextYAlignment.Top
		descLabel.Parent = descFrame

		-- Spacer between description and ingredients
		local spacer = Instance.new("Frame")
		spacer.Size = UDim2.new(1, 0, 0, 10)
		spacer.BackgroundTransparency = 1
		spacer.Parent = detailsScroll

		-- Show required ingredients
		local ingredientsTitle = Instance.new("TextLabel")
		ingredientsTitle.Size = UDim2.new(1, 0, 0, 25)
		ingredientsTitle.BackgroundTransparency = 1
		ingredientsTitle.Text = "Required Ingredients:"
		ingredientsTitle.TextColor3 = Color3.fromRGB(180, 180, 180)
		ingredientsTitle.TextSize = 14
		ingredientsTitle.Font = Enum.Font.GothamBold
		ingredientsTitle.TextXAlignment = Enum.TextXAlignment.Left
		ingredientsTitle.Parent = detailsScroll

		for _, ingredient in ipairs(recipe.Ingredients) do
			local key = ingredient.Name .. "|" .. ingredient.Rarity
			local have = inventoryLookup[key] or 0
			local haveEnough = have >= ingredient.Quantity

			local ingFrame = Instance.new("Frame")
			ingFrame.Size = UDim2.new(1, -10, 0, 45)
			ingFrame.BackgroundColor3 = haveEnough and Color3.fromRGB(50, 80, 50) or Color3.fromRGB(80, 50, 50)
			ingFrame.BorderSizePixel = 0
			ingFrame.Parent = detailsScroll

			local ingCorner = Instance.new("UICorner")
			ingCorner.CornerRadius = UDim.new(0, 8)
			ingCorner.Parent = ingFrame

			local ingName = Instance.new("TextLabel")
			ingName.Size = UDim2.new(0.6, -10, 1, 0)
			ingName.Position = UDim2.new(0, 10, 0, 0)
			ingName.BackgroundTransparency = 1
			ingName.Text = ingredient.Name
			ingName.TextColor3 = Color3.fromRGB(255, 255, 255)
			ingName.TextSize = 14
			ingName.Font = Enum.Font.GothamBold
			ingName.TextXAlignment = Enum.TextXAlignment.Left
			ingName.Parent = ingFrame

			local ingRarity = Instance.new("TextLabel")
			ingRarity.Size = UDim2.new(0.3, -10, 1, 0)
			ingRarity.Position = UDim2.new(0.6, 0, 0, 0)
			ingRarity.BackgroundTransparency = 1
			ingRarity.Text = ingredient.Rarity
			ingRarity.TextColor3 = Color3.fromRGB(200, 200, 200)
			ingRarity.TextSize = 12
			ingRarity.Font = Enum.Font.Gotham
			ingRarity.TextXAlignment = Enum.TextXAlignment.Left
			ingRarity.Parent = ingFrame

			local ingQuantity = Instance.new("TextLabel")
			ingQuantity.Size = UDim2.new(0.4, -10, 1, 0)
			ingQuantity.Position = UDim2.new(1, -10, 0, 0)
			ingQuantity.BackgroundTransparency = 1
			ingQuantity.Text = have .. "/" .. ingredient.Quantity
			ingQuantity.TextColor3 = haveEnough and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
			ingQuantity.TextSize = 14
			ingQuantity.Font = Enum.Font.GothamBold
			ingQuantity.TextXAlignment = Enum.TextXAlignment.Right
			ingQuantity.Parent = ingFrame
		end

		-- Add craft button at bottom
		local canCraft = true
		for _, ingredient in ipairs(recipe.Ingredients) do
			local key = ingredient.Name .. "|" .. ingredient.Rarity
			local have = inventoryLookup[key] or 0
			if have < ingredient.Quantity then
				canCraft = false
				break
			end
		end

		local craftButton = Instance.new("TextButton")
		craftButton.Name = "CraftButton"
		craftButton.Size = UDim2.new(1, -20, 0, 50)
		craftButton.BackgroundColor3 = canCraft and Color3.fromRGB(100, 150, 100) or Color3.fromRGB(100, 50, 50)
		craftButton.BorderSizePixel = 0
		craftButton.Text = canCraft and "Craft!" or "Not Enough Ingredients"
		craftButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		craftButton.TextSize = 18
		craftButton.Font = Enum.Font.GothamBold
		craftButton.Parent = detailsScroll

		local craftCorner = Instance.new("UICorner")
		craftCorner.CornerRadius = UDim.new(0, 10)
		craftCorner.Parent = craftButton

		if canCraft then
			craftButton.MouseButton1Click:Connect(function()
				print("[RNGClient] Crafting recipe " .. recipeIndex)
				CraftingEvent:FireServer(recipeIndex)
			end)
		end

		detailsScroll.CanvasSize = UDim2.new(0, 0, 0, detailsLayout.AbsoluteContentSize.Y + 10)
	end

	-- Populate recipes (sorted by rarity)
	local sortedRecipes = {}
	for i, recipe in ipairs(CraftingRecipes.Recipes) do
		sortedRecipes[i] = recipe
	end

	-- Sort recipes by result rarity (least rare to most rare)
	table.sort(sortedRecipes, function(a, b)
		local rarityA = getRarityIndex(a.Result.Rarity)
		local rarityB = getRarityIndex(b.Result.Rarity)
		if rarityA ~= rarityB then
			return rarityA < rarityB
		end
		-- If same rarity, sort by name alphabetically
		return a.Result.Name < b.Result.Name
	end)

	for recipeIndex, recipe in ipairs(sortedRecipes) do
		-- Find the original index in the unsorted recipes array
		local originalIndex = table.find(CraftingRecipes.Recipes, recipe)

		-- Check if player has all ingredients
		local canCraft = true
		for _, ingredient in ipairs(recipe.Ingredients) do
			local key = ingredient.Name .. "|" .. ingredient.Rarity
			local have = inventoryLookup[key] or 0
			if have < ingredient.Quantity then
				canCraft = false
				break
			end
		end

		-- Get rarity color for the recipe result
		local rarityColor = Color3.fromRGB(200, 200, 200)
		for _, rarity in ipairs(RNGConfig.Rarities) do
			if rarity.Name == recipe.Result.Rarity then
				rarityColor = rarity.Color
				break
			end
		end

		local recipeButton = Instance.new("TextButton")
		recipeButton.Name = "Recipe" .. originalIndex
		recipeButton.Size = UDim2.new(1, -10, 0, 40)
		recipeButton.BackgroundColor3 = canCraft and rarityColor or Color3.fromRGB(50, 50, 60)
		recipeButton.BorderSizePixel = 0
		recipeButton.Text = recipe.Result.Name
		recipeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		recipeButton.Font = Enum.Font.GothamBold
		recipeButton.TextSize = 16
		recipeButton.LayoutOrder = recipeIndex -- Set layout order to maintain sorting
		recipeButton.Parent = recipesScroll

		recipeButton.MouseButton1Click:Connect(function()
			showRecipeDetails(originalIndex)
		end)
	end

	recipesScroll.CanvasSize = UDim2.new(0, 0, 0, recipesScroll.UIListLayout.AbsoluteContentSize.Y + 10)
end)

-- Handle crafting response
CraftingEvent.OnClientEvent:Connect(function(response)
	if response.Success then
		print("[RNGClient] Successfully crafted " .. response.Result.Name)
		-- Wait a moment for the inventory update to arrive
		task.wait(0.1)
		-- Refresh crafting UI if open (don't close it)
		local craftingGui = playerGui:FindFirstChild("CraftingGui")
		if craftingGui then
			-- Trigger a refresh by clicking the crafting button again
			craftingButton.MouseButton1Click:Fire()
		end
	else
		warn("[RNGClient] Crafting failed: " .. (response.Message or "Unknown error"))
	end
end)

print("RNG Client initialized!")