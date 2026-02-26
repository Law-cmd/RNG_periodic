-- PedestalPlacementSystem (Server Script)
-- Handles ProximityPrompt interaction + crafted item placement on pedestals

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

-- Store placed item models per pedestal
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

-- Build a visual model for the placed item
local function createItemDisplay(itemName, itemRarity)
	local displayModel = Instance.new("Model")
	displayModel.Name = itemName .. "_Display"

	local basePart = Instance.new("Part")
	basePart.Name = "ItemBase"
	basePart.Anchored = true
	basePart.CanCollide = false

	-- Shape based on item type
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

	-- Glow
	local light = Instance.new("PointLight")
	light.Color      = basePart.Color
	light.Brightness = 3
	light.Range      = 10
	light.Parent     = basePart

	-- Billboard label
	local billboard = Instance.new("BillboardGui")
	billboard.Size         = UDim2.new(5, 0, 1.2, 0)
	billboard.StudsOffset  = Vector3.new(0, 4, 0)
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

	-- Particles
	local att = Instance.new("Attachment", basePart)
	local particles = Instance.new("ParticleEmitter", att)
	particles.Color       = ColorSequence.new(basePart.Color)
	particles.Size        = NumberSequence.new(0.2, 0.5)
	particles.Lifetime    = NumberRange.new(1, 2)
	particles.Rate        = 20
	particles.Speed       = NumberRange.new(1, 3)
	particles.SpreadAngle = Vector2.new(180, 180)

	-- Spin animation
	task.spawn(function()
		while basePart.Parent do
			basePart.CFrame = basePart.CFrame * CFrame.Angles(0, math.rad(1), 0)
			task.wait()
		end
	end)

	return displayModel
end

-- Place an item on a pedestal (called when player picks from the UI)
local function placeItemOnPedestal(player, itemStand, itemName)
	local inventory = PlayerDataManager.GetInventory(player)
	if not inventory then
		return {success = false, message = "Could not load inventory!"}
	end

	local itemRarity = "Common"
	local hasItem = false

	for _, item in ipairs(inventory) do
		if item.ItemName == itemName then
			if not item.IsCrafted then
				return {success = false, message = "Only crafted items can be placed here!"}
			end
			hasItem    = true
			itemRarity = item.Rarity or "Common"
			break
		end
	end

	if not hasItem then
		return {success = false, message = "You don't have this crafted item!"}
	end

	local equipmentSpawner = itemStand:FindFirstChild("EquipmentSpawner")
	if not equipmentSpawner then
		return {success = false, message = "EquipmentSpawner not found inside Item Stand!"}
	end

	-- Remove old display
	if placedItems[itemStand] then
		placedItems[itemStand]:Destroy()
	end

	-- Place new display
	local display = createItemDisplay(itemName, itemRarity)
	display:PivotTo(equipmentSpawner.CFrame * CFrame.new(0, 3, 0))
	display.Parent = itemStand
	placedItems[itemStand] = display

	print("[PedestalPlacementSystem] Placed", itemName, "on", itemStand.Name)
	return {success = true, message = "Placed " .. itemName}
end

-- Listen for the client selection event
PlaceItemEvent.OnServerEvent:Connect(function(player, itemStand, itemName)
	if not itemStand or not itemName then return end
	placeItemOnPedestal(player, itemStand, itemName)
end)

-- Attach ProximityPrompt to every "Item Stand" in the workspace
local function setupPedestal(model)
	if not model:IsA("Model") then return end
	if model.Name ~= "Item Stand" then return end

	-- Find a part to attach to
	local part = model:FindFirstChild("EquipmentSpawner")
		or model:FindFirstChild("MainPart")
		or model:FindFirstChildWhichIsA("BasePart")
	if not part then
		warn("[PedestalPlacementSystem] No base part found in", model.Name)
		return
	end

	-- Avoid duplicate prompts
	if part:FindFirstChild("PedestalPrompt") then return end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name         = "PedestalPrompt"
	prompt.ActionText   = "Manage Pedestal"
	prompt.ObjectText   = "Item Stand"
	prompt.HoldDuration = 0.5
	prompt.Parent       = part

	prompt.Triggered:Connect(function(player)
		local ok, err = pcall(function()
			local inventory = PlayerDataManager.GetInventory(player)
			local craftedItems = {}

			for _, item in ipairs(inventory) do
				if item.IsCrafted then
					table.insert(craftedItems, item)
				end
			end

			print("[PedestalPlacementSystem] Found", #craftedItems, "crafted items for", player.Name)
			OpenPedestalSelectionEvent:FireClient(player, model, craftedItems)
		end)

		if not ok then
			warn("[PedestalPlacementSystem] Trigger error:", err)
		end
	end)

	print("[PedestalPlacementSystem] Set up prompt on", model.Name)
end

-- Run on all existing workspace children
for _, child in ipairs(workspace:GetChildren()) do
	setupPedestal(child)
end
workspace.ChildAdded:Connect(setupPedestal)

print("[PedestalPlacementSystem] Initialized")
