-- PedestalPlacementSystem (Server Script)
-- Handles ProximityPrompt interaction + crafted item placement on pedestals

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- Create or reuse PlaceItemOnPedestal event
local PlaceItemEvent = RemoteEvents:FindFirstChild("PlaceItemOnPedestal")
if not PlaceItemEvent then
	PlaceItemEvent = Instance.new("RemoteEvent")
	PlaceItemEvent.Name = "PlaceItemOnPedestal"
	PlaceItemEvent.Parent = RemoteEvents
end

-- Create or reuse OpenPedestalSelection event
local OpenPedestalSelectionEvent = RemoteEvents:FindFirstChild("OpenPedestalSelection")
if not OpenPedestalSelectionEvent then
	OpenPedestalSelectionEvent = Instance.new("RemoteEvent")
	OpenPedestalSelectionEvent.Name = "OpenPedestalSelection"
	OpenPedestalSelectionEvent.Parent = RemoteEvents
end

local PlayerDataManager = require(game.ServerScriptService:WaitForChild("PlayerDataManager"))

-- Store placed item models per pedestal so we can clear them when replaced
local placedItems = {}

-- Rarity color table
local rarityColors = {
	Common    = Color3.fromRGB(150, 150, 150),
	Uncommon  = Color3.fromRGB(50, 200, 50),
	Rare      = Color3.fromRGB(50, 100, 255),
	Epic      = Color3.fromRGB(200, 50, 200),
	Legendary = Color3.fromRGB(255, 200, 50),
	Mythical  = Color3.fromRGB(255, 100, 50),
	Divine    = Color3.fromRGB(255, 255, 255),
	Exotic    = Color3.fromRGB(100, 255, 255),
	Celestial = Color3.fromRGB(150, 100, 255),
}

-- Builds the visual 3D item. Ensures it has a PrimaryPart for pivoting.
local function createItemDisplay(itemName, itemRarity)
	local displayModel = Instance.new("Model")
	displayModel.Name = itemName .. "_Display"

	local basePart = Instance.new("Part")
	basePart.Name = "ItemBase"
	basePart.Anchored = true
	basePart.CanCollide = false

	-- Determine geometric shape based on item name keywords
	if itemName:find("Steel") or itemName:find("Bronze") or itemName:find("Alloy") or itemName:find("Metal") or itemName == "Iron" or itemName == "Copper" then
		basePart.Shape    = Enum.PartType.Block
		basePart.Size     = Vector3.new(2.5, 1, 1.2)
		basePart.Material = Enum.Material.Metal
	elseif itemName == "Water" or itemName:find("Crystal") or itemName:find("Essence") or itemName == "Salt" then
		basePart.Shape        = Enum.PartType.Ball
		basePart.Size         = Vector3.new(2, 2, 2)
		basePart.Material     = Enum.Material.Glass
		basePart.Transparency = 0.4
		basePart.Reflectance  = 0.5
	else
		basePart.Shape    = Enum.PartType.Ball
		basePart.Size     = Vector3.new(2, 2, 2)
		basePart.Material = Enum.Material.Neon
	end

	basePart.Color  = rarityColors[itemRarity] or rarityColors.Common
	basePart.Parent = displayModel
	
	-- Critical fix: Set PrimaryPart so :PivotTo() works perfectly
	displayModel.PrimaryPart = basePart

	-- Glow effect
	local light = Instance.new("PointLight")
	light.Color      = basePart.Color
	light.Brightness = 3
	light.Range      = 10
	light.Parent     = basePart

	-- Billboard GUI for item name
	local billboard = Instance.new("BillboardGui")
	billboard.Size         = UDim2.new(5, 0, 1.2, 0)
	billboard.StudsOffset  = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop  = true
	billboard.Adornee      = basePart
	billboard.Parent       = displayModel

	local label = Instance.new("TextLabel")
	label.Size               = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text               = itemName
	label.TextColor3         = basePart.Color
	label.TextScaled         = true
	label.Font               = Enum.Font.GothamBold
	label.Parent             = billboard

	-- Particle effect
	local att = Instance.new("Attachment", basePart)
	local particles = Instance.new("ParticleEmitter", att)
	particles.Color       = ColorSequence.new(basePart.Color)
	particles.Size        = NumberSequence.new(0.2, 0.5)
	particles.Lifetime    = NumberRange.new(1, 2)
	particles.Rate        = 20
	particles.Speed       = NumberRange.new(1, 3)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Parent      = att

	-- Simple continuous rotation handled by the server
	task.spawn(function()
		while basePart and basePart.Parent do
			basePart.CFrame = basePart.CFrame * CFrame.Angles(0, math.rad(1), 0)
			task.wait()
		end
	end)

	return displayModel
end

-- Core placement logic, completely rewritten for safety
local function placeItemOnPedestal(player, itemStand, itemName)
	-- 1. Validate the Pedestal exists and has a spawn point
	if not itemStand or not itemStand:IsA("Model") then
		warn("[Pedestal] Invalid itemStand passed by", player.Name)
		return
	end

	local equipmentSpawner = itemStand:FindFirstChild("EquipmentSpawner")
	if not equipmentSpawner or not equipmentSpawner:IsA("BasePart") then
		warn("[Pedestal] ItemStand", itemStand.Name, "is missing 'EquipmentSpawner' BasePart.")
		return
	end

	-- 2. Verify Player Inventory & Ownership
	local inventory = PlayerDataManager.GetInventory(player)
	if not inventory then
		warn("[Pedestal] Could not load inventory for", player.Name)
		return
	end

	local itemRarity = "Common"
	local hasItem = false

	for _, item in ipairs(inventory) do
		if item.ItemName == itemName and item.IsCrafted then
			hasItem = true
			itemRarity = item.Rarity or "Common"
			break
		end
	end

	if not hasItem then
		warn("[Pedestal]", player.Name, "attempted to place", itemName, "but doesn't own a crafted version.")
		return
	end

	-- 3. Clear Existing Item
	if placedItems[itemStand] then
		placedItems[itemStand]:Destroy()
		placedItems[itemStand] = nil
	end

	-- 4. Create and Position New Item
	local display = createItemDisplay(itemName, itemRarity)
	
	-- We use PivotTo now that PrimaryPart is guaranteed to be set
	-- Float it exactly 3 studs above the spawner's center point
	display:PivotTo(equipmentSpawner.CFrame * CFrame.new(0, 3, 0))
	display.Parent = itemStand
	
	-- Store reference
	placedItems[itemStand] = display

	print("[Pedestal] Successfully placed", itemName, "on", itemStand.Name, "by", player.Name)
end

-- Network Reception
PlaceItemEvent.OnServerEvent:Connect(function(player, itemStand, itemName)
	placeItemOnPedestal(player, itemStand, itemName)
end)

-- Prompt Setup Function
local function setupPedestal(model)
	if not model:IsA("Model") or model.Name ~= "Item Stand" then return end

	local part = model:FindFirstChild("EquipmentSpawner") 
		or model:FindFirstChild("MainPart") 
		or model:FindFirstChildWhichIsA("BasePart")
		
	if not part then return end
	if part:FindFirstChild("PedestalPrompt") then return end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name         = "PedestalPrompt"
	prompt.ActionText   = "Manage Pedestal"
	prompt.ObjectText   = "Item Stand"
	prompt.HoldDuration = 0.5
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 10
	prompt.Parent       = part

	prompt.Triggered:Connect(function(player)
		local ok, err = pcall(function()
			local inventory = PlayerDataManager.GetInventory(player)
			local craftedItems = {}

			if inventory then
				for _, item in ipairs(inventory) do
					if item.IsCrafted then
						table.insert(craftedItems, item)
					end
				end
			end

			-- Always fire so UI opens, even if empty
			OpenPedestalSelectionEvent:FireClient(player, model, craftedItems)
		end)

		if not ok then
			warn("[PedestalPlacementSystem] Trigger error:", err)
		end
	end)
end

-- Initialize existing pedestals + future ones (handling nested pedestals gracefully)
for _, desc in ipairs(workspace:GetDescendants()) do
	setupPedestal(desc)
end
workspace.DescendantAdded:Connect(setupPedestal)

print("[PedestalPlacementSystem] Completely Rewritten & Initialized")
