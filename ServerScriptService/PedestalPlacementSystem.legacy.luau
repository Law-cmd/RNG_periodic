-- Server script to handle placing crafted items on pedestals
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local PlaceItemEvent = RemoteEvents:WaitForChild("PlaceItemOnPedestal")

-- Create or reuse OpenPedestalSelection event
local OpenPedestalSelectionEvent = RemoteEvents:FindFirstChild("OpenPedestalSelection")
if not OpenPedestalSelectionEvent then
	OpenPedestalSelectionEvent = Instance.new("RemoteEvent")
	OpenPedestalSelectionEvent.Name = "OpenPedestalSelection"
	OpenPedestalSelectionEvent.Parent = RemoteEvents
end

local PlayerDataManager = require(game.ServerScriptService:WaitForChild("PlayerDataManager"))

-- Store placed items by pedestal
local placedItems = {}

local function createItemDisplay(itemName, itemRarity)
	local displayModel = Instance.new("Model")
	displayModel.Name = itemName .. "_Display"
	
	-- Create a base part for the item
	local basePart = Instance.new("Part")
	basePart.Name = "ItemBase"
	basePart.Anchored = true
	basePart.CanCollide = false
	
	-- Set shape and material based on item name
	if itemName:find("Steel") or itemName:find("Bronze") or itemName:find("Metal") or itemName:find("Alloy") or itemName == "Iron" or itemName == "Copper" then
		basePart.Shape = Enum.PartType.Block
		basePart.Size = Vector3.new(2.5, 1, 1.2) -- Ingot shape
		basePart.Material = Enum.Material.Metal
	elseif itemName == "Water" or itemName:find("Essence") or itemName:find("Crystal") or itemName == "Salt" then
		basePart.Shape = Enum.PartType.Ball
		basePart.Size = Vector3.new(2, 2, 2)
		basePart.Material = Enum.Material.Glass
		basePart.Transparency = 0.4
		basePart.Reflectance = 0.5
	else
		basePart.Shape = Enum.PartType.Ball
		basePart.Size = Vector3.new(2, 2, 2)
		basePart.Material = Enum.Material.Neon
	end
	
	-- Set color based on rarity (fallback values)
	local rarityColors = {
		["Common"] = Color3.fromRGB(150, 150, 150),
		["Uncommon"] = Color3.fromRGB(50, 200, 50),
		["Rare"] = Color3.fromRGB(50, 100, 255),
		["Epic"] = Color3.fromRGB(200, 50, 200),
		["Legendary"] = Color3.fromRGB(255, 200, 50),
		["Mythic"] = Color3.fromRGB(255, 100, 50),
		["Divine"] = Color3.fromRGB(255, 255, 255),
		["Exotic"] = Color3.fromRGB(100, 255, 255),
		["Celestial"] = Color3.fromRGB(150, 100, 255),
	}
	
	basePart.Color = rarityColors[itemRarity] or rarityColors["Common"]
	basePart.Parent = displayModel
	
	-- Add a glow effect
	local light = Instance.new("PointLight")
	light.Color = basePart.Color
	light.Brightness = 2
	light.Range = 6
	light.Parent = basePart
	
	-- Add a billboard with the item name
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ItemLabel"
	billboard.Size = UDim2.new(4, 0, 1, 0)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.Adornee = basePart
	billboard.AlwaysOnTop = true
	billboard.Parent = displayModel
	
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = itemName
	textLabel.TextColor3 = basePart.Color
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.Parent = billboard
	
	-- Add particle effect based on rarity
	local attachment = Instance.new("Attachment")
	attachment.Parent = basePart
	
	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(basePart.Color)
	particles.Size = NumberSequence.new(0.2, 0.5)
	particles.Lifetime = NumberRange.new(1, 2)
	particles.Rate = 20
	particles.Speed = NumberRange.new(1, 3)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Parent = attachment
	
	return displayModel
end

-- Function to place an item on an Item Stand
local function placeItemOnPedestal(player, itemStand, itemName)
	print("[PedestalPlacementSystem] placeItemOnPedestal called by " .. player.Name .. " for item: " .. itemName)
	
	-- Verify the player has this item and it is CRAFTED
	local inventory = PlayerDataManager.GetInventory(player)
	if not inventory then
		return {success = false, message = "Could not load inventory!"}
	end
	
	local hasItem = false
	local itemRarity = "Common"
	
	for _, item in ipairs(inventory) do
		if item.ItemName == itemName then
			-- Only allow CRAFTED items
			if not item.IsCrafted then
				return {success = false, message = "Only crafted items can be placed here!"}
			end
			
			hasItem = true
			itemRarity = item.Rarity or "Common"
			print("[PedestalPlacementSystem] Found crafted item in inventory: " .. item.ItemName)
			break
		end
	end
	
	if not hasItem then
		return {success = false, message = "You don't have this crafted item!"}
	end
	
	-- Find the EquipmentSpawner in the Item Stand
	local equipmentSpawner = itemStand:FindFirstChild("EquipmentSpawner")
	if not equipmentSpawner then
		print("[PedestalPlacementSystem] EquipmentSpawner not found!")
		return {success = false, message = "EquipmentSpawner not found!"}
	end
	
	print("[PedestalPlacementSystem] EquipmentSpawner found at: " .. tostring(equipmentSpawner.Position))
	
	-- Remove existing item display if any
	if placedItems[itemStand] then
		print("[PedestalPlacementSystem] Removing existing item display")
		placedItems[itemStand]:Destroy()
	end
	
	-- Create and place the item display
	print("[PedestalPlacementSystem] Creating item display")
	local itemDisplay = createItemDisplay(itemName, itemRarity)
	itemDisplay:PivotTo(equipmentSpawner.CFrame * CFrame.new(0, 3, 0))
	itemDisplay.Parent = itemStand
	
	-- Store the placed item
	placedItems[itemStand] = itemDisplay
	
	print("[PedestalPlacementSystem] Item placed successfully!")
	return {success = true, message = "Placed " .. itemName .. " on Item Stand"}
end

-- Handle place item requests
PlaceItemEvent.OnServerEvent:Connect(function(player, itemStand, itemName)
	if not itemStand or not itemName then return end
	local result = placeItemOnPedestal(player, itemStand, itemName)
	return result
end)

-- Setup ProximityPrompts for all pedestals
local function setupPedestal(model)
	if model.Name ~= "Item Stand" then return end
	
	local interactionPart = model:FindFirstChild("EquipmentSpawner") or model:FindFirstChild("MainPart") or model:FindFirstChildWhichIsA("BasePart")
	if not interactionPart then return end
	
	local prompt = interactionPart:FindFirstChild("PedestalPrompt") or Instance.new("ProximityPrompt")
	prompt.Name = "PedestalPrompt"
	prompt.ActionText = "Manage Pedestal"
	prompt.ObjectText = "Item Stand"
	prompt.HoldDuration = 0.5
	prompt.Parent = interactionPart
	
	prompt.Triggered:Connect(function(player)
		local ok, err = pcall(function()
			local inventory = PlayerDataManager.GetInventory(player)
			local craftedItems = {}
			
			for _, item in ipairs(inventory) do
				if item.IsCrafted then
					table.insert(craftedItems, item)
				end
			end
			
			print("[PedestalPlacementSystem] Firing OpenPedestalSelection to " .. player.Name .. " with " .. #craftedItems .. " crafted items")
			OpenPedestalSelectionEvent:FireClient(player, model, craftedItems)
		end)
		if not ok then
			warn("[PedestalPlacementSystem] Error in prompt trigger: " .. tostring(err))
		end
	end)
end

-- Initialize workspace pedestals
for _, child in ipairs(workspace:GetChildren()) do
	setupPedestal(child)
end

workspace.ChildAdded:Connect(setupPedestal)

-- Remove old debug events if they exist
local OpenTestUIEvent = RemoteEvents:FindFirstChild("OpenTestUIEvent")
if OpenTestUIEvent then
	-- We can't easily destroy from server if it's in ReplicatedStorage while running, 
	-- but we can stop listening.
end

return "Pedestal placement system initialized"