local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIHandler = {}

-- Create the main RNG UI
function UIHandler.CreateUI(playerGui)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "RNGGui"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 10
	screenGui.Parent = playerGui

	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0.9, 0, 0, 60)
	mainFrame.Position = UDim2.new(0.5, 0, 1, -70)
	mainFrame.AnchorPoint = Vector2.new(0.5, 1)
	mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	mainFrame.BackgroundTransparency = 0.8
	mainFrame.BorderSizePixel = 0
	mainFrame.Active = false -- Don't block clicks on transparent areas
	mainFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 15)
	corner.Parent = mainFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 100, 120)
	stroke.Thickness = 2
	stroke.Parent = mainFrame

	-- Result Frame
	local resultFrame = Instance.new("Frame")
	resultFrame.Name = "ResultFrame"
	resultFrame.Size = UDim2.new(0.9, 0, 0, 140)
	resultFrame.Position = UDim2.new(0.5, 0, 0, -160)
	resultFrame.AnchorPoint = Vector2.new(0.5, 0)
	resultFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	resultFrame.BackgroundTransparency = 1
	resultFrame.BorderSizePixel = 0
	resultFrame.Active = false -- Don't block clicks
	resultFrame.Parent = screenGui

	local resultCorner = Instance.new("UICorner")
	resultCorner.CornerRadius = UDim.new(0, 10)
	resultCorner.Parent = resultFrame

	-- Result text
	local resultText = Instance.new("TextLabel")
	resultText.Name = "ResultText"
	resultText.Size = UDim2.new(1, -20, 0, 40)
	resultText.Position = UDim2.new(0, 10, 0, 10)
	resultText.BackgroundTransparency = 1
	resultText.Text = "Click Roll to Start!"
	resultText.TextColor3 = Color3.fromRGB(200, 200, 200)
	resultText.TextSize = 22
	resultText.Font = Enum.Font.GothamBold
	resultText.TextWrapped = true
	resultText.Parent = resultFrame

	local rarityText = Instance.new("TextLabel")
	rarityText.Name = "RarityText"
	rarityText.Size = UDim2.new(1, -20, 0, 30)
	rarityText.Position = UDim2.new(0, 10, 0, 55)
	rarityText.BackgroundTransparency = 1
	rarityText.Text = ""
	rarityText.TextColor3 = Color3.fromRGB(255, 255, 255)
	rarityText.TextSize = 18
	rarityText.Font = Enum.Font.Gotham
	rarityText.Parent = resultFrame

	local descText = Instance.new("TextLabel")
	descText.Name = "DescriptionText"
	descText.Size = UDim2.new(1, -20, 0, 35)
	descText.Position = UDim2.new(0, 10, 0, 90)
	descText.BackgroundTransparency = 1
	descText.Text = ""
	descText.TextColor3 = Color3.fromRGB(255, 255, 255)
	descText.TextSize = 15
	descText.Font = Enum.Font.Gotham
	descText.TextWrapped = true
	descText.Parent = resultFrame

	local chanceText = Instance.new("TextLabel")
	chanceText.Name = "ChanceText"
	chanceText.Size = UDim2.new(1, -20, 0, 25)
	chanceText.Position = UDim2.new(0, 10, 0, 125)
	chanceText.BackgroundTransparency = 1
	chanceText.Text = ""
	chanceText.TextColor3 = Color3.fromRGB(255, 255, 255)
	chanceText.TextSize = 13
	chanceText.Font = Enum.Font.Gotham
	chanceText.Parent = resultFrame

	-- Roll button
	local rollButton = Instance.new("TextButton")
	rollButton.Name = "RollButton"
	rollButton.Size = UDim2.new(0.3, 0, 1, -5)
	rollButton.Position = UDim2.new(0.5, 0, 0, 5)
	rollButton.AnchorPoint = Vector2.new(0.5, 0)
	rollButton.BackgroundColor3 = Color3.fromRGB(50, 150, 250)
	rollButton.BackgroundTransparency = 0.2
	rollButton.BorderSizePixel = 0
	rollButton.Text = "ROLL"
	rollButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	rollButton.TextSize = 20
	rollButton.Font = Enum.Font.GothamBold
	rollButton.AutoButtonColor = false
	rollButton.Parent = mainFrame

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 10)
	buttonCorner.Parent = rollButton

	-- Cooldown text
	local cooldownText = Instance.new("TextLabel")
	cooldownText.Name = "CooldownText"
	cooldownText.Size = UDim2.new(0.7, -10, 0, 25)
	cooldownText.Position = UDim2.new(0, 60, 0, 0)
	cooldownText.BackgroundTransparency = 1
	cooldownText.Text = ""
	cooldownText.TextColor3 = Color3.fromRGB(255, 100, 100)
	cooldownText.TextSize = 16
	cooldownText.Font = Enum.Font.Gotham
	cooldownText.Parent = mainFrame

	-- Inventory button
	local inventoryButton = Instance.new("TextButton")
	inventoryButton.Name = "InventoryButton"
	inventoryButton.Size = UDim2.new(0, 60, 1, -10)
	inventoryButton.Position = UDim2.new(1, -5, 0, 5)
	inventoryButton.AnchorPoint = Vector2.new(1, 0)
	inventoryButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	inventoryButton.BackgroundTransparency = 0.2
	inventoryButton.BorderSizePixel = 0
	inventoryButton.Text = "INV"
	inventoryButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	inventoryButton.TextSize = 16
	inventoryButton.Font = Enum.Font.GothamBold
	inventoryButton.Parent = mainFrame

	local invCorner = Instance.new("UICorner")
	invCorner.CornerRadius = UDim.new(0, 8)
	invCorner.Parent = inventoryButton

	-- Collection button
	local collectionButton = Instance.new("TextButton")
	collectionButton.Name = "CollectionButton"
	collectionButton.Size = UDim2.new(0, 60, 1, -10)
	collectionButton.Position = UDim2.new(0, 5, 0, 5)
	collectionButton.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
	collectionButton.BackgroundTransparency = 0.2
	collectionButton.BorderSizePixel = 0
	collectionButton.Text = "COL"
	collectionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	collectionButton.TextSize = 14
	collectionButton.Font = Enum.Font.GothamBold
	collectionButton.Parent = mainFrame

	local collectionCorner = Instance.new("UICorner")
	collectionCorner.CornerRadius = UDim.new(0, 8)
	collectionCorner.Parent = collectionButton

	-- Crafting button
	local craftingButton = Instance.new("TextButton")
	craftingButton.Name = "CraftingButton"
	craftingButton.Size = UDim2.new(0, 60, 1, -10)
	craftingButton.Position = UDim2.new(0, 70, 0, 5)
	craftingButton.BackgroundColor3 = Color3.fromRGB(150, 100, 200)
	craftingButton.BackgroundTransparency = 0.2
	craftingButton.BorderSizePixel = 0
	craftingButton.Text = "CRAFT"
	craftingButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	craftingButton.TextSize = 14
	craftingButton.Font = Enum.Font.GothamBold
	craftingButton.Parent = mainFrame

	local craftingCorner = Instance.new("UICorner")
	craftingCorner.CornerRadius = UDim.new(0, 8)
	craftingCorner.Parent = craftingButton

	-- Crafted Inventory button
	local craftedInventoryButton = Instance.new("TextButton")
	craftedInventoryButton.Name = "CraftedInventoryButton"
	craftedInventoryButton.Size = UDim2.new(0, 60, 1, -10)
	craftedInventoryButton.Position = UDim2.new(0, 135, 0, 5)
	craftedInventoryButton.BackgroundColor3 = Color3.fromRGB(200, 100, 200)
	craftedInventoryButton.BackgroundTransparency = 0.2
	craftedInventoryButton.BorderSizePixel = 0
	craftedInventoryButton.Text = "C-INV"
	craftedInventoryButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	craftedInventoryButton.TextSize = 14
	craftedInventoryButton.Font = Enum.Font.GothamBold
	craftedInventoryButton.Parent = mainFrame

	local craftedInvCorner = Instance.new("UICorner")
	craftedInvCorner.CornerRadius = UDim.new(0, 8)
	craftedInvCorner.Parent = craftedInventoryButton

	-- Auto-roll button
	local autoRollButton = Instance.new("TextButton")
	autoRollButton.Name = "AutoRollButton"
	autoRollButton.Size = UDim2.new(0, 50, 0, 50)
	autoRollButton.Position = UDim2.new(1, -55, 0, -55)
	autoRollButton.AnchorPoint = Vector2.new(1, 1)
	autoRollButton.BackgroundColor3 = Color3.fromRGB(150, 100, 200)
	autoRollButton.BackgroundTransparency = 0.2
	autoRollButton.BorderSizePixel = 0
	autoRollButton.Text = "AUTO"
	autoRollButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	autoRollButton.TextSize = 12
	autoRollButton.Font = Enum.Font.GothamBold
	autoRollButton.Parent = mainFrame

	local autoRollCorner = Instance.new("UICorner")
	autoRollCorner.CornerRadius = UDim.new(0, 8)
	autoRollCorner.Parent = autoRollButton

	return screenGui
end

-- Update result with slide animation
function UIHandler.UpdateResult(gui, rollResult)
	local resultFrame = gui:FindFirstChild("ResultFrame")
	if not resultFrame then return end

	local RNGConfig = require(ReplicatedStorage:WaitForChild("RNGConfig"))
	local electronCount = RNGConfig.GetElectronCount(rollResult.ItemName)

	resultFrame.ResultText.Text = rollResult.ItemName
	resultFrame.RarityText.Text = rollResult.Rarity
	resultFrame.RarityText.TextColor3 = rollResult.RarityColor
	resultFrame.DescriptionText.Text = rollResult.ItemDescription
	resultFrame.ChanceText.Text = string.format("Chance: %.2f%% | Electrons: %d", rollResult.RarityChance, electronCount)

	local tweenIn = TweenService:Create(
		resultFrame,
		TweenInfo.new(0.4, Enum.EasingStyle.Back),
		{ Position = UDim2.new(0.5, 0, 0, 20) }
	)
	tweenIn:Play()

	task.delay(2, function()
		local tweenOut = TweenService:Create(
			resultFrame,
			TweenInfo.new(0.4, Enum.EasingStyle.Quad),
			{ Position = UDim2.new(0.5, 0, 0, -160) }
		)
		tweenOut:Play()
	end)
end

-- Update cooldown
function UIHandler.UpdateCooldown(gui, timeRemaining)
	local mainFrame = gui:FindFirstChild("MainFrame")
	if not mainFrame then return end

	local cooldownText = mainFrame:FindFirstChild("CooldownText")
	if cooldownText then
		if timeRemaining > 0 then
			cooldownText.Text = string.format("Cooldown: %.1fs", timeRemaining)
		else
			cooldownText.Text = ""
		end
	end
end

-- Enable/disable roll button
function UIHandler.SetRollButtonEnabled(gui, enabled)
	local mainFrame = gui:FindFirstChild("MainFrame")
	if not mainFrame then return end

	local rollButton = mainFrame:FindFirstChild("RollButton")
	if rollButton then
		rollButton.BackgroundColor3 = enabled and Color3.fromRGB(50, 150, 250) or Color3.fromRGB(100, 100, 100)
		rollButton.Text = enabled and "ROLL" or "ROLLING..."
	end
end

-- Auto-roll toggle
function UIHandler.SetAutoRollState(gui, isActive)
	local mainFrame = gui:FindFirstChild("MainFrame")
	if not mainFrame then return end

	local autoButton = mainFrame:FindFirstChild("AutoRollButton")
	if autoButton then
		autoButton.BackgroundColor3 = isActive and Color3.fromRGB(200, 100, 100) or Color3.fromRGB(150, 100, 200)
		autoButton.Text = isActive and "STOP" or "AUTO"
	end
end
-- Create Collection UI
function UIHandler.CreateCollectionUI(playerGui, inventory)
	local RNGConfig = require(ReplicatedStorage:WaitForChild("RNGConfig"))

	-- Extract unique item names from inventory
	local ownedItems = {}
	local seenItems = {}
	for _, item in ipairs(inventory) do
		if not seenItems[item.ItemName] then
			seenItems[item.ItemName] = true
			table.insert(ownedItems, item.ItemName)
		end
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CollectionGui"
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 100
	screenGui.Parent = playerGui

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 15)
	corner.Parent = mainFrame

	-- Count total items in config
	local totalItems = 0
	for _, items in pairs(RNGConfig.Items) do
		totalItems = totalItems + #items
	end

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -70, 0, 50)
	title.Position = UDim2.new(0, 10, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "COLLECTION (" .. #ownedItems .. "/" .. totalItems .. ")"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 20
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame

	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 60, 0, 60)
	closeButton.Position = UDim2.new(1, -70, 0, 10)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.Text = "✕"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 30
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = mainFrame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "ScrollFrame"
	scrollFrame.Size = UDim2.new(1, -20, 1, -80)
	scrollFrame.Position = UDim2.new(0, 10, 0, 70)
	scrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 10
	scrollFrame.Parent = mainFrame

	local scrollCorner = Instance.new("UICorner")
	scrollCorner.CornerRadius = UDim.new(0, 10)
	scrollCorner.Parent = scrollFrame

	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.new(0, 120, 0, 120)
	layout.CellPadding = UDim2.new(0, 10, 0, 10)
	layout.Parent = scrollFrame

	-- Create ALL items sorted by rarity (owned and unowned)
	for _, rarity in ipairs(RNGConfig.Rarities) do
		local items = RNGConfig.Items[rarity.Name]
		if items then
			for _, item in ipairs(items) do
				-- Check if player owns this item
				local isOwned = false
				for _, ownedName in ipairs(ownedItems) do
					if ownedName == item.Name then
						isOwned = true
						break
					end
				end

				local itemFrame = Instance.new("Frame")
				itemFrame.Size = UDim2.new(1, 0, 1, 0)
				-- Different background for owned vs unowned
				itemFrame.BackgroundColor3 = isOwned and Color3.fromRGB(40, 60, 50) or Color3.fromRGB(40, 40, 50)
				itemFrame.BackgroundTransparency = isOwned and 0 or 0.3
				itemFrame.BorderSizePixel = 0
				itemFrame.Parent = scrollFrame

				local itemCorner = Instance.new("UICorner")
				itemCorner.CornerRadius = UDim.new(0, 10)
				itemCorner.Parent = itemFrame

				local stroke = Instance.new("UIStroke")
				stroke.Color = rarity.Color
				stroke.Thickness = isOwned and 3 or 1
				stroke.Transparency = isOwned and 0 or 0.5
				stroke.Parent = itemFrame

				if isOwned then
					-- OWNED: Show full details
					local nameLabel = Instance.new("TextLabel")
					nameLabel.Size = UDim2.new(1, -10, 0, 30)
					nameLabel.Position = UDim2.new(0, 5, 0, 5)
					nameLabel.BackgroundTransparency = 1
					nameLabel.Text = item.Name
					nameLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
					nameLabel.TextSize = 16
					nameLabel.Font = Enum.Font.GothamBold
					nameLabel.TextWrapped = true
					nameLabel.Parent = itemFrame

					local descLabel = Instance.new("TextLabel")
					descLabel.Size = UDim2.new(1, -10, 0, 35)
					descLabel.Position = UDim2.new(0, 5, 0, 35)
					descLabel.BackgroundTransparency = 1
					descLabel.Text = item.Description
					descLabel.TextColor3 = Color3.fromRGB(200, 255, 200)
					descLabel.TextSize = 11
					descLabel.Font = Enum.Font.Gotham
					descLabel.TextWrapped = true
					descLabel.Parent = itemFrame

					local rarityLabel = Instance.new("TextLabel")
					rarityLabel.Size = UDim2.new(1, -10, 0, 25)
					rarityLabel.Position = UDim2.new(0, 5, 0, 70)
					rarityLabel.BackgroundTransparency = 1
					rarityLabel.Text = rarity.Name
					rarityLabel.TextColor3 = rarity.Color
					rarityLabel.TextSize = 13
					rarityLabel.Font = Enum.Font.GothamBold
					rarityLabel.Parent = itemFrame

					local chanceLabel = Instance.new("TextLabel")
					chanceLabel.Size = UDim2.new(1, -10, 0, 20)
					chanceLabel.Position = UDim2.new(0, 5, 0, 95)
					chanceLabel.BackgroundTransparency = 1
					chanceLabel.Text = string.format("Chance: %.3f%%", rarity.Chance)
					chanceLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
					chanceLabel.TextSize = 10
					chanceLabel.Font = Enum.Font.Gotham
					chanceLabel.Parent = itemFrame
				else
					-- NOT OWNED: Show only name, rarity, and chance
					local nameLabel = Instance.new("TextLabel")
					nameLabel.Size = UDim2.new(1, -10, 0, 40)
					nameLabel.Position = UDim2.new(0, 5, 0, 5)
					nameLabel.BackgroundTransparency = 1
					nameLabel.Text = "???"
					nameLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
					nameLabel.TextSize = 20
					nameLabel.Font = Enum.Font.GothamBold
					nameLabel.Parent = itemFrame

					local rarityLabel = Instance.new("TextLabel")
					rarityLabel.Size = UDim2.new(1, -10, 0, 25)
					rarityLabel.Position = UDim2.new(0, 5, 0, 45)
					rarityLabel.BackgroundTransparency = 1
					rarityLabel.Text = rarity.Name
					rarityLabel.TextColor3 = rarity.Color
					rarityLabel.TextSize = 13
					rarityLabel.Font = Enum.Font.GothamBold
					rarityLabel.Parent = itemFrame

					local chanceLabel = Instance.new("TextLabel")
					chanceLabel.Size = UDim2.new(1, -10, 0, 25)
					chanceLabel.Position = UDim2.new(0, 5, 0, 70)
					chanceLabel.BackgroundTransparency = 1
					chanceLabel.Text = string.format("Chance: %.3f%%", rarity.Chance)
					chanceLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
					chanceLabel.TextSize = 12
					chanceLabel.Font = Enum.Font.Gotham
					chanceLabel.Parent = itemFrame
				end
			end
		end
	end

	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)

	closeButton.MouseButton1Click:Connect(function()
		screenGui:Destroy()
	end)

	return screenGui
end

-- Create Crafting UI
function UIHandler.CreateCraftingUI(playerGui, groupedInventory, recipes)
	local RNGConfig = require(ReplicatedStorage:WaitForChild("RNGConfig"))

	---------------------------------------------------------------------
	-- HELPERS
	---------------------------------------------------------------------

	-- Check if an item is used as an ingredient in any recipe
	local function isIngredient(itemName)
		for _, recipe in ipairs(recipes) do
			for _, ingredient in ipairs(recipe.Ingredients) do
				if ingredient.Name == itemName then
					return true
				end
			end
		end
		return false
	end

	-- Check if an item is the result of any recipe
	local function isCraftedResult(itemName)
		for _, recipe in ipairs(recipes) do
			if recipe.Result.Name == itemName then
				return true
			end
		end
		return false
	end

	---------------------------------------------------------------------
	-- MAIN GUI
	---------------------------------------------------------------------

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CraftingGui"
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 100
	screenGui.Parent = playerGui

	local craftingFrame = Instance.new("Frame")
	craftingFrame.Name = "CraftingFrame"
	craftingFrame.Size = UDim2.new(0.9, 0, 0.8, 0)
	craftingFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	craftingFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	craftingFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	craftingFrame.BorderSizePixel = 0
	craftingFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 15)
	corner.Parent = craftingFrame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -70, 0, 50)
	title.Position = UDim2.new(0, 10, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "CRAFTING"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 20
	title.Font = Enum.Font.GothamBold
	title.Parent = craftingFrame

	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 60, 0, 60)
	closeButton.Position = UDim2.new(1, -70, 0, 10)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.Text = "✕"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 30
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = craftingFrame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton

	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "ContentFrame"
	contentFrame.Size = UDim2.new(1, -20, 1, -80)
	contentFrame.Position = UDim2.new(0, 10, 0, 70)
	contentFrame.BackgroundTransparency = 1
	contentFrame.Parent = craftingFrame

	---------------------------------------------------------------------
	-- LEFT SIDE: RECIPES
	---------------------------------------------------------------------

	local recipesFrame = Instance.new("Frame")
	recipesFrame.Name = "RecipesFrame"
	recipesFrame.Size = UDim2.new(0.5, -5, 1, 0)
	recipesFrame.Position = UDim2.new(0, 0, 0, 0)
	recipesFrame.BackgroundTransparency = 1
	recipesFrame.Parent = contentFrame

	local recipesTitle = Instance.new("TextLabel")
	recipesTitle.Size = UDim2.new(1, 0, 0, 30)
	recipesTitle.BackgroundTransparency = 1
	recipesTitle.Text = "RECIPES"
	recipesTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
	recipesTitle.TextSize = 16
	recipesTitle.Font = Enum.Font.GothamBold
	recipesTitle.Parent = recipesFrame

	local recipesScroll = Instance.new("ScrollingFrame")
	recipesScroll.Name = "RecipesScroll"
	recipesScroll.Size = UDim2.new(1, 0, 1, -30)
	recipesScroll.Position = UDim2.new(0, 0, 0, 30)
	recipesScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	recipesScroll.BorderSizePixel = 0
	recipesScroll.ScrollBarThickness = 10
	recipesScroll.Parent = recipesFrame

	local recipesCorner = Instance.new("UICorner")
	recipesCorner.CornerRadius = UDim.new(0, 10)
	recipesCorner.Parent = recipesScroll

	local recipesLayout = Instance.new("UIListLayout")
	recipesLayout.Padding = UDim.new(0, 5)
	recipesLayout.SortOrder = Enum.SortOrder.LayoutOrder
	recipesLayout.Parent = recipesScroll

	---------------------------------------------------------------------
	-- RIGHT SIDE: RECIPE DETAILS
	---------------------------------------------------------------------

	local detailsFrame = Instance.new("Frame")
	detailsFrame.Name = "DetailsFrame"
	detailsFrame.Size = UDim2.new(0.5, -5, 1, 0)
	detailsFrame.Position = UDim2.new(0.5, 5, 0, 0)
	detailsFrame.BackgroundTransparency = 1
	detailsFrame.Parent = contentFrame

	local detailsTitle = Instance.new("TextLabel")
	detailsTitle.Name = "DetailsTitle"
	detailsTitle.Size = UDim2.new(1, 0, 0, 30)
	detailsTitle.BackgroundTransparency = 1
	detailsTitle.Text = "SELECT A RECIPE"
	detailsTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
	detailsTitle.TextSize = 16
	detailsTitle.Font = Enum.Font.GothamBold
	detailsTitle.Parent = detailsFrame

	local detailsScroll = Instance.new("ScrollingFrame")
	detailsScroll.Name = "DetailsScroll"
	detailsScroll.Size = UDim2.new(1, 0, 1, -30)
	detailsScroll.Position = UDim2.new(0, 0, 0, 30)
	detailsScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	detailsScroll.BorderSizePixel = 0
	detailsScroll.ScrollBarThickness = 10
	detailsScroll.Parent = detailsFrame

	local detailsCorner = Instance.new("UICorner")
	detailsCorner.CornerRadius = UDim.new(0, 10)
	detailsCorner.Parent = detailsScroll

	local detailsLayout = Instance.new("UIListLayout")
	detailsLayout.Padding = UDim.new(0, 5)
	detailsLayout.Parent = detailsScroll

	---------------------------------------------------------------------
	-- POPULATE RECIPES
	---------------------------------------------------------------------

	closeButton.MouseButton1Click:Connect(function()
		screenGui:Destroy()
	end)

	return {
		Gui = screenGui,
		RecipesScroll = recipesScroll,
		DetailsScroll = detailsScroll,
		DetailsTitle = detailsTitle
	}
end
-- Helper: Get Rarity Color
local function getRarityColor(rarityName)
	local RNGConfig = require(ReplicatedStorage:WaitForChild("RNGConfig"))
	for _, r in ipairs(RNGConfig.Rarities) do
		if r.Name == rarityName then
			return r.Color
		end
	end
	return Color3.fromRGB(200, 200, 200)
end

-- Create Pedestal Selection UI
function UIHandler.CreatePedestalSelectionUI(playerGui, craftedItems, itemStand)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PedestalSelectionGui"
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 110
	screenGui.Parent = playerGui

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0.6, 0, 0.7, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 15)
	corner.Parent = mainFrame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -70, 0, 50)
	title.Position = UDim2.new(0, 10, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "SELECT ITEM TO DISPLAY"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 20
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame

	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 40, 0, 40)
	closeButton.Position = UDim2.new(1, -50, 0, 10)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.Text = "✕"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 20
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = mainFrame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, -20, 1, -80)
	scrollFrame.Position = UDim2.new(0, 10, 0, 70)
	scrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 8
	scrollFrame.Parent = mainFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 5)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = scrollFrame

	if #craftedItems == 0 then
		local noItems = Instance.new("TextLabel")
		noItems.Size = UDim2.new(1, 0, 0, 100)
		noItems.BackgroundTransparency = 1
		noItems.Text = "You haven't crafted any items yet!"
		noItems.TextColor3 = Color3.fromRGB(150, 150, 150)
		noItems.TextSize = 16
		noItems.Font = Enum.Font.Gotham
		noItems.Parent = scrollFrame
	end

	for _, item in ipairs(craftedItems) do
		local itemButton = Instance.new("TextButton")
		itemButton.Size = UDim2.new(1, -10, 0, 60)
		itemButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		itemButton.BorderSizePixel = 0
		itemButton.Text = ""
		itemButton.AutoButtonColor = true
		itemButton.Parent = scrollFrame

		local itemCorner = Instance.new("UICorner")
		itemCorner.CornerRadius = UDim.new(0, 8)
		itemCorner.Parent = itemButton

		local rarityColor = getRarityColor(item.Rarity)
		local stroke = Instance.new("UIStroke")
		stroke.Color = rarityColor
		stroke.Thickness = 1
		stroke.Parent = itemButton

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -20, 0, 30)
		nameLabel.Position = UDim2.new(0, 10, 0, 5)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = item.ItemName
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextSize = 18
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = itemButton

		local rarityLabel = Instance.new("TextLabel")
		rarityLabel.Size = UDim2.new(1, -20, 0, 20)
		rarityLabel.Position = UDim2.new(0, 10, 0, 30)
		rarityLabel.BackgroundTransparency = 1
		rarityLabel.Text = item.Rarity
		rarityLabel.TextColor3 = rarityColor
		rarityLabel.TextSize = 14
		rarityLabel.Font = Enum.Font.Gotham
		rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
		rarityLabel.Parent = itemButton

		itemButton.MouseButton1Click:Connect(function()
			local PlaceItemEvent = ReplicatedStorage.RemoteEvents:WaitForChild("PlaceItemOnPedestal")
			if PlaceItemEvent then
				PlaceItemEvent:FireServer(itemStand, item.ItemName)
			end
			screenGui:Destroy()
		end)
	end

	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)

	closeButton.MouseButton1Click:Connect(function()
		screenGui:Destroy()
	end)

	return screenGui
end

return UIHandler
