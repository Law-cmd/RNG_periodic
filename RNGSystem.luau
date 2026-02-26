--[[
	RNG System Module
	Handles the weighted random selection of items based on rarity
]]

local RNGConfig = require(script.Parent.RNGConfig)

local RNGSystem = {}

-- Create a weighted table for efficient random selection
local function createWeightedTable()
	local weightedTable = {}

	for _, rarity in ipairs(RNGConfig.Rarities) do
		table.insert(weightedTable, {
			Name = rarity.Name,
			Chance = rarity.Chance,
			Color = rarity.Color
		})
	end

	return weightedTable
end

-- Select a random rarity based on weighted chances
function RNGSystem.SelectRarity()
	local weightedTable = createWeightedTable()
	local totalWeight = 0

	-- Calculate total weight
	for _, rarity in ipairs(weightedTable) do
		totalWeight = totalWeight + rarity.Chance
	end

	-- Generate random number
	local random = math.random() * totalWeight
	local currentWeight = 0

	-- Select rarity based on weight
	for _, rarity in ipairs(weightedTable) do
		currentWeight = currentWeight + rarity.Chance
		if random <= currentWeight then
			return rarity
		end
	end

	-- Fallback to first rarity (should never happen)
	return weightedTable[1]
end

-- Select a random item from a specific rarity
function RNGSystem.SelectItem(rarityName)
	local items = RNGConfig.Items[rarityName]

	if not items or #items == 0 then
		warn("No items found for rarity: " .. rarityName)
		return nil
	end

	local randomIndex = math.random(1, #items)
	return items[randomIndex]
end

-- Perform a complete roll (rarity + item)
function RNGSystem.PerformRoll()
	local rarity = RNGSystem.SelectRarity()
	local item = RNGSystem.SelectItem(rarity.Name)

	if not item then
		-- Fallback to common if something goes wrong
		rarity = RNGConfig.Rarities[1]
		item = RNGConfig.Items.Common[1]
	end

	-- Calculate total weight for percentage
	local totalWeight = 0
	for _, r in ipairs(RNGConfig.Rarities) do
		totalWeight = totalWeight + r.Chance
	end

	-- Calculate actual percentage chance
	local rarityChance = (rarity.Chance / totalWeight) * 100

	return {
		Rarity = rarity.Name,
		RarityColor = rarity.Color,
		RarityChance = rarityChance,
		ItemName = item.Name,
		ItemDescription = item.Description,
		Timestamp = os.time()
	}
end

-- Get rarity information by name
function RNGSystem.GetRarityInfo(rarityName)
	for _, rarity in ipairs(RNGConfig.Rarities) do
		if rarity.Name == rarityName then
			return rarity
		end
	end
	return nil
end

-- Calculate luck multiplier (can be used for game passes, etc.)
function RNGSystem.PerformRollWithLuck(luckMultiplier)
	luckMultiplier = luckMultiplier or 1

	-- Adjust chances based on luck (makes rare items more common)
	local adjustedRarities = {}
	for i, rarity in ipairs(RNGConfig.Rarities) do
		local adjustedChance = rarity.Chance

		-- Increase chances for rarer items with luck
		if i > 3 then -- Only affect rare and above
			adjustedChance = adjustedChance * luckMultiplier
		end

		table.insert(adjustedRarities, {
			Name = rarity.Name,
			Chance = adjustedChance,
			Color = rarity.Color
		})
	end

	-- Normalize chances to maintain 100% total
	local totalChance = 0
	for _, rarity in ipairs(adjustedRarities) do
		totalChance = totalChance + rarity.Chance
	end

	local random = math.random() * totalChance
	local currentWeight = 0

	for _, rarity in ipairs(adjustedRarities) do
		currentWeight = currentWeight + rarity.Chance
		if random <= currentWeight then
			local item = RNGSystem.SelectItem(rarity.Name)

			return {
				Rarity = rarity.Name,
				RarityColor = rarity.Color,
				RarityChance = (RNGConfig.Rarities[table.find(RNGConfig.Rarities, 
					function(r) return r.Name == rarity.Name end) or 1].Chance / totalChance) * 100,
				ItemName = item.Name,
				ItemDescription = item.Description,
				Timestamp = os.time()
			}
		end
	end

	-- Fallback
	return RNGSystem.PerformRoll()
end

return RNGSystem