--[[
	Crafting Recipes Module
	Defines all craftable items and their ingredient requirements
]]

local CraftingRecipes = {}

-- All crafting recipes
CraftingRecipes.Recipes = {
	-- Common tier crafts
	{
		Result = {
			Name = "Steel",
			Rarity = "Uncommon",
			Description = "Strong alloy of iron and carbon\n\n⚡ Roll Speed: +10%\n🍀 Luck: x1.2"
		},
		Ingredients = {
			{Name = "Iron", Rarity = "Uncommon", Quantity = 2},
			{Name = "Carbon", Rarity = "Common", Quantity = 1}
		}
	},
	{
		Result = {
			Name = "Bronze",
			Rarity = "Uncommon",
			Description = "Copper and tin alloy\n\n⚡ Roll Speed: +10%\n🍀 Luck: x1.2"
		},
		Ingredients = {
			{Name = "Copper", Rarity = "Uncommon", Quantity = 2},
			{Name = "Tin", Rarity = "Common", Quantity = 1}
		}
	},
	{
		Result = {
			Name = "Water",
			Rarity = "Common",
			Description = "Essential compound of life\n\n⚡ Roll Speed: +5%\n🍀 Luck: x1.1"
		},
		Ingredients = {
			{Name = "Hydrogen", Rarity = "Common", Quantity = 2},
			{Name = "Oxygen", Rarity = "Common", Quantity = 1}
		}
	},
	{
		Result = {
			Name = "Ammonia",
			Rarity = "Uncommon",
			Description = "Important industrial chemical\n\n⚡ Roll Speed: +10%\n🍀 Luck: x1.2"
		},
		Ingredients = {
			{Name = "Nitrogen", Rarity = "Common", Quantity = 1},
			{Name = "Hydrogen", Rarity = "Common", Quantity = 3}
		}
	},
	{
		Result = {
			Name = "Salt",
			Rarity = "Common",
			Description = "Essential seasoning\n\n⚡ Roll Speed: +5%\n🍀 Luck: x1.1"
		},
		Ingredients = {
			{Name = "Sodium", Rarity = "Common", Quantity = 1},
			{Name = "Chlorine", Rarity = "Common", Quantity = 1}
		}
	},
	{
		Result = {
			Name = "Methane",
			Rarity = "Common",
			Description = "Simple hydrocarbon\n\n⚡ Roll Speed: +5%\n🍀 Luck: x1.1"
		},
		Ingredients = {
			{Name = "Carbon", Rarity = "Common", Quantity = 1},
			{Name = "Hydrogen", Rarity = "Common", Quantity = 4}
		}
	},
	{
		Result = {
			Name = "Silica",
			Rarity = "Common",
			Description = "Sand and glass base\n\n⚡ Roll Speed: +5%\n🍀 Luck: x1.1"
		},
		Ingredients = {
			{Name = "Silicon", Rarity = "Common", Quantity = 1},
			{Name = "Oxygen", Rarity = "Common", Quantity = 2}
		}
	},
	-- Rare tier crafts
	{
		Result = {
			Name = "Sterling Silver",
			Rarity = "Rare",
			Description = "Beautiful silver alloy\n\n⚡ Roll Speed: +15%\n🍀 Luck: x1.3"
		},
		Ingredients = {
			{Name = "Silver", Rarity = "Rare", Quantity = 2},
			{Name = "Copper", Rarity = "Uncommon", Quantity = 1}
		}
	},
	{
		Result = {
			Name = "Titanium Alloy",
			Rarity = "Rare",
			Description = "Aerospace-grade material\n\n⚡ Roll Speed: +15%\n🍀 Luck: x1.3"
		},
		Ingredients = {
			{Name = "Titanium", Rarity = "Rare", Quantity = 2},
			{Name = "Aluminum", Rarity = "Uncommon", Quantity = 1},
			{Name = "Vanadium", Rarity = "Uncommon", Quantity = 1}
		}
	},
	{
		Result = {
			Name = "Stainless Steel",
			Rarity = "Rare",
			Description = "Corrosion-resistant steel\n\n⚡ Roll Speed: +15%\n🍀 Luck: x1.3"
		},
		Ingredients = {
			{Name = "Iron", Rarity = "Uncommon", Quantity = 3},
			{Name = "Chromium", Rarity = "Rare", Quantity = 1},
			{Name = "Nickel", Rarity = "Rare", Quantity = 1}
		}
	},
	{
		Result = {
			Name = "Mithril Alloy",
			Rarity = "Rare",
			Description = "Elven metal enhanced\n\n⚡ Roll Speed: +15%\n🍀 Luck: x1.3"
		},
		Ingredients = {
			{Name = "Mithril", Rarity = "Rare", Quantity = 2},
			{Name = "Silver", Rarity = "Rare", Quantity = 1}
		}
	},
	{
		Result = {
			Name = "Vibranium Steel",
			Rarity = "Rare",
			Description = "Energy-absorbing alloy\n\n⚡ Roll Speed: +15%\n🍀 Luck: x1.3"
		},
		Ingredients = {
			{Name = "Vibranium", Rarity = "Rare", Quantity = 1},
			{Name = "Iron", Rarity = "Uncommon", Quantity = 2}
		}
	},
	{
		Result = {
			Name = "Crystal Blade",
			Rarity = "Rare",
			Description = "Gem-infused weapon\n\n⚡ Roll Speed: +15%\n🍀 Luck: x1.3"
		},
		Ingredients = {
			{Name = "Crystal Steel", Rarity = "Rare", Quantity = 1},
			{Name = "Diamond", Rarity = "Epic", Quantity = 1}
		}
	},
	-- Epic tier crafts
	{
		Result = {
			Name = "White Gold",
			Rarity = "Epic",
			Description = "Luxurious gold alloy\n\n⚡ Roll Speed: +20%\n🍀 Luck: x1.5"
		},
		Ingredients = {
			{Name = "Gold", Rarity = "Epic", Quantity = 2},
			{Name = "Palladium", Rarity = "Epic", Quantity = 1},
			{Name = "Silver", Rarity = "Rare", Quantity = 1}
		}
	},
	{
		Result = {
			Name = "Platinum Alloy",
			Rarity = "Epic",
			Description = "Ultra-durable precious metal\n\n⚡ Roll Speed: +20%\n🍀 Luck: x1.5"
		},
		Ingredients = {
			{Name = "Platinum", Rarity = "Epic", Quantity = 2},
			{Name = "Rhodium", Rarity = "Epic", Quantity = 1}
		}
	},
	{
		Result = {
			Name = "Uru Hammer",
			Rarity = "Epic",
			Description = "Asgardian weapon\n\n⚡ Roll Speed: +20%\n🍀 Luck: x1.5"
		},
		Ingredients = {
			{Name = "Uru", Rarity = "Epic", Quantity = 2},
			{Name = "Storm Silver", Rarity = "Rare", Quantity = 1}
		}
	},
	{
		Result = {
			Name = "Beskar Armor",
			Rarity = "Epic",
			Description = "Mandalorian protection\n\n⚡ Roll Speed: +20%\n🍀 Luck: x1.5"
		},
		Ingredients = {
			{Name = "Beskar", Rarity = "Epic", Quantity = 2},
			{Name = "Titanium", Rarity = "Rare", Quantity = 1}
		}
	},
	{
		Result = {
			Name = "Gemstone Array",
			Rarity = "Epic",
			Description = "Combined gem power\n\n⚡ Roll Speed: +20%\n🍀 Luck: x1.5"
		},
		Ingredients = {
			{Name = "Diamond", Rarity = "Epic", Quantity = 1},
			{Name = "Ruby", Rarity = "Epic", Quantity = 1},
			{Name = "Sapphire", Rarity = "Epic", Quantity = 1}
		}
	},
	-- Legendary tier crafts
	{
		Result = {
			Name = "Enriched Uranium",
			Rarity = "Legendary",
			Description = "Highly radioactive fuel\n\n⚡ Roll Speed: +25%\n🍀 Luck: x1.8"
		},
		Ingredients = {
			{Name = "Uranium", Rarity = "Legendary", Quantity = 2},
			{Name = "Plutonium", Rarity = "Legendary", Quantity = 1}
		}
	},
	{
		Result = {
			Name = "Radium Glow",
			Rarity = "Legendary",
			Description = "Permanently glowing material\n\n⚡ Roll Speed: +25%\n🍀 Luck: x1.8"
		},
		Ingredients = {
			{Name = "Radium", Rarity = "Legendary", Quantity = 2},
			{Name = "Phosphorus", Rarity = "Uncommon", Quantity = 1}
		}
	},
	{
		Result = {
			Name = "Time Loop",
			Rarity = "Legendary",
			Description = "Temporal manipulation\n\n⚡ Roll Speed: +25%\n🍀 Luck: x1.8"
		},
		Ingredients = {
			{Name = "Chronium", Rarity = "Legendary", Quantity = 2},
			{Name = "Time Crystal", Rarity = "Mythical", Quantity = 1}
		}
	},
	{
		Result = {
			Name = "Void Essence",
			Rarity = "Legendary",
			Description = "Pure nothingness\n\n⚡ Roll Speed: +25%\n🍀 Luck: x1.8"
		},
		Ingredients = {
			{Name = "Void Metal", Rarity = "Legendary", Quantity = 2},
			{Name = "Void Crystal", Rarity = "Mythical", Quantity = 1}
		}
	},
	{
		Result = {
			Name = "Dragonfire",
			Rarity = "Legendary",
			Description = "Eternal flame\n\n⚡ Roll Speed: +25%\n🍀 Luck: x1.8"
		},
		Ingredients = {
			{Name = "Dragonsteel", Rarity = "Legendary", Quantity = 2},
			{Name = "Phoenix Iron", Rarity = "Legendary", Quantity = 1}
		}
	},
	-- Mythical tier crafts
	{
		Result = {
			Name = "Superheavy Fusion",
			Rarity = "Mythical",
			Description = "Fusion of rarest elements\n\n⚡ Roll Speed: +30%\n🍀 Luck: x2.0"
		},
		Ingredients = {
			{Name = "Francium", Rarity = "Mythical", Quantity = 1},
			{Name = "Astatine", Rarity = "Mythical", Quantity = 1},
			{Name = "Californium", Rarity = "Mythical", Quantity = 1}
		}
	},
	{
		Result = {
			Name = "Einsteinium Compound",
			Rarity = "Mythical",
			Description = "Named after genius\n\n⚡ Roll Speed: +30%\n🍀 Luck: x2.0"
		},
		Ingredients = {
			{Name = "Einsteinium", Rarity = "Mythical", Quantity = 2},
			{Name = "Uranium", Rarity = "Legendary", Quantity = 1}
		}
	},
	{
		Result = {
			Name = "Reality Bender",
			Rarity = "Mythical",
			Description = "Warp existence itself\n\n⚡ Roll Speed: +30%\n🍀 Luck: x2.0"
		},
		Ingredients = {
			{Name = "Infinity Stone", Rarity = "Mythical", Quantity = 1},
			{Name = "Reality Shard", Rarity = "Mythical", Quantity = 2}
		}
	},
	{
		Result = {
			Name = "Dream Weaver",
			Rarity = "Mythical",
			Description = "Control dreams\n\n⚡ Roll Speed: +30%\n🍀 Luck: x2.0"
		},
		Ingredients = {
			{Name = "Dream Essence", Rarity = "Mythical", Quantity = 2},
			{Name = "Nightmare Fuel", Rarity = "Mythical", Quantity = 1}
		}
	},
	{
		Result = {
			Name = "Balance Keeper",
			Rarity = "Mythical",
			Description = "Perfect harmony\n\n⚡ Roll Speed: +30%\n🍀 Luck: x2.0"
		},
		Ingredients = {
			{Name = "Chaos Energy", Rarity = "Mythical", Quantity = 1},
			{Name = "Order Crystal", Rarity = "Mythical", Quantity = 1}
		}
	},
	-- Divine tier crafts
	{
		Result = {
			Name = "Island of Stability",
			Rarity = "Divine",
			Description = "Theoretical stable superheavy element\n\n⚡ Roll Speed: +40%\n🍀 Luck: x2.5"
		},
		Ingredients = {
			{Name = "Oganesson", Rarity = "Divine", Quantity = 1},
			{Name = "Tennessine", Rarity = "Divine", Quantity = 1},
			{Name = "Moscovium", Rarity = "Divine", Quantity = 1}
		}
	},
	{
		Result = {
			Name = "Elemental Core",
			Rarity = "Divine",
			Description = "Pure element power\n\n⚡ Roll Speed: +40%\n🍀 Luck: x2.5"
		},
		Ingredients = {
			{Name = "Ununennium", Rarity = "Divine", Quantity = 2},
			{Name = "Unbinilium", Rarity = "Divine", Quantity = 1}
		}
	},
	{
		Result = {
			Name = "Transmutation",
			Rarity = "Divine",
			Description = "Change anything\n\n⚡ Roll Speed: +40%\n🍀 Luck: x2.5"
		},
		Ingredients = {
			{Name = "Philosopher's Stone", Rarity = "Mythical", Quantity = 1},
			{Name = "Life Essence", Rarity = "Mythical", Quantity = 1},
			{Name = "Death Essence", Rarity = "Mythical", Quantity = 1}
		}
	},
	-- Exotic tier crafts
	{
		Result = {
			Name = "Matter-Antimatter",
			Rarity = "Exotic",
			Description = "Perfect balance of opposites\n\n⚡ Roll Speed: +50%\n🍀 Luck: x3.0"
		},
		Ingredients = {
			{Name = "Antimatter", Rarity = "Exotic", Quantity = 1},
			{Name = "Ununennium", Rarity = "Exotic", Quantity = 1}
		}
	},
	{
		Result = {
			Name = "Quantum Field",
			Rarity = "Exotic",
			Description = "Manipulate probability\n\n⚡ Roll Speed: +50%\n🍀 Luck: x3.0"
		},
		Ingredients = {
			{Name = "Quantium", Rarity = "Mythical", Quantity = 2},
			{Name = "Bose-Einstein Condensate", Rarity = "Exotic", Quantity = 1}
		}
	},
	{
		Result = {
			Name = "Faster Than Light",
			Rarity = "Exotic",
			Description = "Break cosmic speed limit\n\n⚡ Roll Speed: +50%\n🍀 Luck: x3.0"
		},
		Ingredients = {
			{Name = "Tachyon", Rarity = "Exotic", Quantity = 2},
			{Name = "Wormhole", Rarity = "Celestial", Quantity = 1}
		}
	},
	{
		Result = {
			Name = "Mass Generator",
			Rarity = "Exotic",
			Description = "Create matter from nothing\n\n⚡ Roll Speed: +50%\n🍀 Luck: x3.0"
		},
		Ingredients = {
			{Name = "Higgs Boson", Rarity = "Exotic", Quantity = 2},
			{Name = "Vacuum Energy", Rarity = "Celestial", Quantity = 1}
		}
	},
	-- Celestial tier crafts
	{
		Result = {
			Name = "Cosmic Singularity",
			Rarity = "Celestial",
			Description = "Heart of a black hole\n\n⚡ Roll Speed: +60%\n🍀 Luck: x4.0"
		},
		Ingredients = {
			{Name = "Dark Matter", Rarity = "Celestial", Quantity = 1},
			{Name = "Neutronium", Rarity = "Celestial", Quantity = 1},
			{Name = "Strange Matter", Rarity = "Celestial", Quantity = 1}
		}
	},
	{
		Result = {
			Name = "Universe Seed",
			Rarity = "Celestial",
			Description = "Create new realities\n\n⚡ Roll Speed: +60%\n🍀 Luck: x4.0"
		},
		Ingredients = {
			{Name = "Singularity", Rarity = "Celestial", Quantity = 1},
			{Name = "Cosmium", Rarity = "Mythical", Quantity = 2}
		}
	},
	{
		Result = {
			Name = "Stellar Forge",
			Rarity = "Celestial",
			Description = "Birth of stars\n\n⚡ Roll Speed: +60%\n🍀 Luck: x4.0"
		},
		Ingredients = {
			{Name = "Nebula Gas", Rarity = "Celestial", Quantity = 2},
			{Name = "Pulsar Core", Rarity = "Celestial", Quantity = 1}
		}
	},
	{
		Result = {
			Name = "Gamma Burst",
			Rarity = "Celestial",
			Description = "Most powerful explosion\n\n⚡ Roll Speed: +60%\n🍀 Luck: x4.0"
		},
		Ingredients = {
			{Name = "Gamma Ray Burst", Rarity = "Celestial", Quantity = 1},
			{Name = "Quasar Energy", Rarity = "Celestial", Quantity = 1},
			{Name = "Blazar Light", Rarity = "Celestial", Quantity = 1}
		}
	},
}

-- Helper function to get recipe by result name
function CraftingRecipes.GetRecipeByName(resultName)
	for _, recipe in ipairs(CraftingRecipes.Recipes) do
		if recipe.Result.Name == resultName then
			return recipe
		end
	end
	return nil
end

-- Helper function to get all craftable recipes
function CraftingRecipes.GetAllRecipes()
	return CraftingRecipes.Recipes
end

return CraftingRecipes