
--[[
    Equip Effects Module (Enhanced Atomic Model Version)
    Tier-based nucleus + shells, aura rings, sounds, auto-scaling
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local EquipEffects = {}
EquipEffects.ActiveEffects = {}
EquipEffects.ActiveBuffs = {} -- Track active buffs per player

---------------------------------------------------------------------
-- ELECTRON COUNTS (fallback, used if RNGConfig doesn't have it)
---------------------------------------------------------------------
local ElectronCounts = {
	Hydrogen = 1, Carbon = 6, Oxygen = 8, Nitrogen = 7,
	Iron = 26, Copper = 29, Aluminum = 13, Silicon = 14,
	Silver = 47, Titanium = 22, Chromium = 24, Nickel = 28,
	Gold = 79, Platinum = 78, Palladium = 46, Rhodium = 45,
	Uranium = 92, Plutonium = 94, Radium = 88, Thorium = 90,
	Francium = 87, Astatine = 85, Californium = 98, Einsteinium = 99,
	Oganesson = 118, Tennessine = 117, Moscovium = 115,
	Ununennium = 119, Unbinilium = 120,
	Antimatter = 200, DarkMatter = 250, Neutronium = 275, StrangeMatter = 300
}

---------------------------------------------------------------------
-- ELEMENT CONFIG (if you use it elsewhere)
---------------------------------------------------------------------
local ElementEffects = {
	-- your element-specific config if needed
}

---------------------------------------------------------------------
-- RARITY MULTIPLIERS
---------------------------------------------------------------------
local RarityMultipliers = {
	Common = {Size=1,Rate=1,Speed=1,Lifetime=1,Rings=1},
	Uncommon = {Size=1.2,Rate=1.3,Speed=1.2,Lifetime=1.1,Rings=1},
	Rare = {Size=1.5,Rate=1.6,Speed=1.4,Lifetime=1.2,Rings=2},
	Epic = {Size=1.8,Rate=2,Speed=1.6,Lifetime=1.3,Rings=2},
	Legendary = {Size=2.2,Rate=2.5,Speed=1.8,Lifetime=1.5,Rings=3},
	Mythical = {Size=2.8,Rate=3,Speed=2,Lifetime=1.8,Rings=3},
	Divine = {Size=3.5,Rate=3.5,Speed=2.2,Lifetime=2,Rings=4},
	Exotic = {Size=4,Rate=4,Speed=2.5,Lifetime=2.2,Rings=4},
	Celestial = {Size=6,Rate=5,Speed=3,Lifetime=2.5,Rings=5},
}

---------------------------------------------------------------------
-- BOHR SHELL CAPACITIES
---------------------------------------------------------------------
local ShellCapacities = {2, 8, 18, 32, 50, 72, 98, 128, 162, 200}

---------------------------------------------------------------------
-- PERFORMANCE AUTO-SCALING
---------------------------------------------------------------------
local function getPerformanceScale()
	local fps = 1 / RunService.RenderStepped:Wait()
	if fps < 30 then return 0.5 end
	if fps < 45 then return 0.75 end
	return 1
end

---------------------------------------------------------------------
-- UTILITY: Ensure attachment exists
---------------------------------------------------------------------
local function getOrCreateMainAttachment(hrp)
	local existing = hrp:FindFirstChild("MainEffectAttachment")
	if existing then return existing end

	local att = Instance.new("Attachment")
	att.Name = "MainEffectAttachment"
	att.Parent = hrp
	return att
end

---------------------------------------------------------------------
-- PARTICLES (stub – plug your existing particle logic here)
---------------------------------------------------------------------
local function createElementParticles(character, elementName, rarityName, rarityColor)
	-- put your existing particle emitter setup here if you had one
	return nil
end

---------------------------------------------------------------------
-- NEW HYBRID NUCLEUS (tier-based)
---------------------------------------------------------------------
local function createNucleus(character, elementName, rarityColor, rarityName)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return {} end

	local RNGConfig = require(ReplicatedStorage:WaitForChild("RNGConfig"))
	local electrons = RNGConfig.GetElectronCount(elementName)
	if electrons == 0 then
		electrons = ElectronCounts[elementName] or 4
	end

	-- Determine tier from electron count
	local tier
	if electrons <= 50 then tier = 1
	elseif electrons <= 150 then tier = 2
	elseif electrons <= 300 then tier = 3
	elseif electrons <= 600 then tier = 4
	else tier = 5 end

	local coreSize = 1 + tier * 0.4
	local nucleonCount = 6 + tier * 6

	local nucleusCore = Instance.new("Part")
	nucleusCore.Name = "NucleusCore"
	nucleusCore.Shape = Enum.PartType.Ball
	nucleusCore.Size = Vector3.new(coreSize, coreSize, coreSize)
	nucleusCore.Material = Enum.Material.Neon
	nucleusCore.Color = rarityColor
	nucleusCore.Transparency = math.clamp(0.45 - tier * 0.03, 0.1, 0.6)
	nucleusCore.CanCollide = false
	nucleusCore.Massless = true
	nucleusCore.Parent = character

	local att0 = Instance.new("Attachment", hrp)
	local att1 = Instance.new("Attachment", nucleusCore)

	local align = Instance.new("AlignPosition")
	align.Attachment0 = att1
	align.Attachment1 = att0
	align.MaxForce = math.huge
	align.Responsiveness = 60 + tier * 20
	align.Parent = nucleusCore

	local nucleons = {}

	for i = 1, nucleonCount do
		local p = Instance.new("Part")
		p.Name = "Nucleon_" .. i
		p.Shape = Enum.PartType.Ball
		p.Size = Vector3.new(0.25 + tier * 0.05, 0.25 + tier * 0.05, 0.25 + tier * 0.05)
		p.Material = Enum.Material.Neon
		p.Color = rarityColor:Lerp(Color3.new(1,1,1), 0.3)
		p.Transparency = 0.55
		p.CanCollide = false
		p.Massless = true
		p.Parent = character

		local a0 = Instance.new("Attachment", nucleusCore)
		local a1 = Instance.new("Attachment", p)

		local ap = Instance.new("AlignPosition")
		ap.Attachment0 = a1
		ap.Attachment1 = a0
		ap.MaxForce = math.huge
		ap.Responsiveness = 40 + tier * 10
		ap.Parent = p

		local angle = (i / nucleonCount) * math.pi * 2
		local radius = 0.6 + tier * 0.2

		task.spawn(function()
			while p.Parent do
				local t = tick() * (2 + tier * 0.5)
				local chaos = (tier >= 4) and math.sin(t * 4 + i) * 0.3 or 0

				a0.Position = Vector3.new(
					math.cos(t + angle) * (radius + chaos),
					math.sin(t * 1.5 + angle) * (0.3 + chaos),
					math.sin(t + angle) * (radius + chaos)
				)

				task.wait()
			end
		end)

		table.insert(nucleons, p)
	end

	return {Core = nucleusCore, Nucleons = nucleons}
end

---------------------------------------------------------------------
-- NEW BOHR ELECTRON SHELLS (tier-based)
---------------------------------------------------------------------
local function createElectronShells(character, elementName, rarityColor, rarityName)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return {} end

	local RNGConfig = require(ReplicatedStorage:WaitForChild("RNGConfig"))
	local trueElectrons = RNGConfig.GetElectronCount(elementName)
	if trueElectrons == 0 then
		trueElectrons = ElectronCounts[elementName] or 4
	end

	-- Determine tier
	local tier
	if trueElectrons <= 50 then tier = 1
	elseif trueElectrons <= 150 then tier = 2
	elseif trueElectrons <= 300 then tier = 3
	elseif trueElectrons <= 600 then tier = 4
	else tier = 5 end

	local tierElectronMap = {
		[1] = 30,
		[2] = 70,
		[3] = 140,
		[4] = 200,
		[5] = 260,
	}

	local electrons = tierElectronMap[tier]
	local scale = getPerformanceScale()
	electrons = math.floor(electrons * scale)

	local shells = {}
	local remaining = electrons
	local shellIndex = 1

	while remaining > 0 and shellIndex <= #ShellCapacities do
		local capacity = ShellCapacities[shellIndex]
		local count = math.min(remaining, capacity)
		remaining -= count

		local radius = 2 + shellIndex * (1.2 + tier * 0.3)
		local speed = 1 + shellIndex * (0.5 + tier * 0.2)

		local shellParts = {}

		for i = 1, count do
			local e = Instance.new("Part")
			e.Name = "Electron_" .. shellIndex .. "_" .. i
			e.Shape = Enum.PartType.Ball
			e.Size = Vector3.new(0.4 + tier * 0.05, 0.4 + tier * 0.05, 0.4 + tier * 0.05)
			e.Material = Enum.Material.Neon
			e.Color = rarityColor
			e.Transparency = 0.45
			e.CanCollide = false
			e.Massless = true
			e.Parent = character

			local a0 = Instance.new("Attachment", hrp)
			local a1 = Instance.new("Attachment", e)

			local ap = Instance.new("AlignPosition")
			ap.Attachment0 = a1
			ap.Attachment1 = a0
			ap.MaxForce = math.huge
			ap.Responsiveness = 50 + tier * 10
			ap.Parent = e

			local angleOffset = (i / count) * math.pi * 2
			local tiltAmount = 20 * tier
			local shellTilt = CFrame.Angles(
				math.rad(tiltAmount * shellIndex),
				math.rad(tiltAmount * 0.8),
				math.rad(tiltAmount * 1.2)
			)

			task.spawn(function()
				while e.Parent do
					local t = tick() * speed
					local wobble = (tier >= 4) and math.sin(t * 3 + i) * 0.4 or 0

					local baseAngle = t + angleOffset
					local localOffset = Vector3.new(
						math.cos(baseAngle) * (radius + wobble),
						0,
						math.sin(baseAngle) * (radius + wobble)
					)

					local tiltedOffset = shellTilt:VectorToWorldSpace(localOffset)

					a0.Position = Vector3.new(
						tiltedOffset.X,
						1.5 + tiltedOffset.Y,
						tiltedOffset.Z
					)

					task.wait()
				end
			end)

			table.insert(shellParts, e)
		end

		table.insert(shells, shellParts)
		shellIndex += 1
	end

	return shells
end

---------------------------------------------------------------------
-- AURA SYSTEM
---------------------------------------------------------------------
local function createAuraRings(character, rarityName, rarityColor)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return {} end

	local rarity = RarityMultipliers[rarityName] or RarityMultipliers.Common
	local scale = getPerformanceScale()
	local effects = {}

	local mainAttachment = getOrCreateMainAttachment(hrp)

	local gas = Instance.new("ParticleEmitter")
	gas.Name = "AtomicGas"
	gas.Color = ColorSequence.new(rarityColor)
	gas.LightEmission = 0.3
	gas.Size = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 1.5 * rarity.Size),
		NumberSequenceKeypoint.new(1, 3 * rarity.Size)
	}
	gas.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.82),
		NumberSequenceKeypoint.new(1, 1)
	}
	gas.Rate = 40 * rarity.Rate * scale
	gas.Lifetime = NumberRange.new(0.75 * rarity.Lifetime, 1.25 * rarity.Lifetime)
	gas.Speed = NumberRange.new(1, 3)
	gas.Rotation = NumberRange.new(0, 360)
	gas.RotSpeed = NumberRange.new(-30, 30)
	gas.SpreadAngle = Vector2.new(360, 360)
	gas.Parent = mainAttachment
	table.insert(effects, gas)

	if rarity.Rings >= 3 then
		local plasma = Instance.new("ParticleEmitter")
		plasma.Name = "PlasmaStorm"
		plasma.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, rarityColor),
			ColorSequenceKeypoint.new(1, rarityColor:Lerp(Color3.new(1,1,1), 0.5))
		}
		plasma.LightEmission = 0.3
		plasma.Size = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0.8 * rarity.Size),
			NumberSequenceKeypoint.new(1, 0)
		}
		plasma.Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0.48),
			NumberSequenceKeypoint.new(1, 1)
		}
		plasma.Rate = 60 * rarity.Rate * scale
		plasma.Lifetime = NumberRange.new(0.25, 0.5)
		plasma.Speed = NumberRange.new(6, 10 * rarity.Speed)
		plasma.SpreadAngle = Vector2.new(360, 360)
		plasma.Parent = mainAttachment
		table.insert(effects, plasma)
	end

	task.spawn(function()
		local baseRate = gas.Rate
		while gas.Parent do
			local pulse = (math.sin(tick() * 2) + 1) / 2
			gas.Rate = baseRate * (0.6 + pulse * 0.8)
			task.wait(0.1)
		end
	end)
	-- Celestial-exclusive directional energy burst
	if rarityName == "Celestial" then
		task.spawn(function()
			while mainAttachment.Parent do
				local beam = Instance.new("Part")
				beam.Name = "EnergyBurst"
				beam.Anchored = true
				beam.CanCollide = false
				beam.Material = Enum.Material.Neon
				beam.Color = rarityColor
				beam.Transparency = 0.3
				beam.Size = Vector3.new(0.4, 0.4, 4)
				local randomAngle = CFrame.Angles(
					math.rad(math.random(-20, 20)),
					math.rad(math.random(-180, 180)),
					0
				)
				beam.CFrame = hrp.CFrame * randomAngle * CFrame.new(0, 0, -2)

				beam.Parent = workspace

				local tween = TweenService:Create(
					beam,
					TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{
						Size = Vector3.new(0.4, 0.4, 30),
						Transparency = 1,
						CFrame = hrp.CFrame * CFrame.new(0, 0, -20)
					}
				)

				tween:Play()
				tween.Completed:Connect(function()
					beam:Destroy()
				end)

				task.wait(2.5) -- burst interval
			end
		end)
	end

	if rarity.Rings >= 4 then
		task.spawn(function()
			while mainAttachment.Parent do
				local shock = Instance.new("Part")
				shock.Shape = Enum.PartType.Cylinder
				shock.Size = Vector3.new(1, 0.2, 1)
				shock.Material = Enum.Material.Neon
				shock.Color = rarityColor
				shock.Transparency = 0.84
				shock.CanCollide = false
				shock.Anchored = true
				shock.CFrame = hrp.CFrame * CFrame.Angles(math.rad(90),0,0)
				shock.Parent = workspace

				local tween = TweenService:Create(
					shock,
					TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{Size = Vector3.new(20, 0.2, 20), Transparency = 1}
				)

				tween:Play()
				tween.Completed:Connect(function() shock:Destroy() end)
				task.wait(3 / rarity.Speed)
			end
		end)
	end

	return effects
end

---------------------------------------------------------------------
-- APPLY BUFFS (Roll Speed and Luck)
---------------------------------------------------------------------
local function applyBuffs(player, elementData)
	local RNGConfig = require(ReplicatedStorage:WaitForChild("RNGConfig"))
	local rarityName = elementData.Rarity

	local rarityData = nil
	for _, r in ipairs(RNGConfig.Rarities) do
		if r.Name == rarityName then
			rarityData = r
			break
		end
	end

	if not rarityData then return end

	EquipEffects.ActiveBuffs[player.UserId] = {
		RollSpeedBuff = rarityData.RollSpeedBuff or 0,
		LuckBuff = rarityData.LuckBuff or 1,
		Rarity = rarityName
	}

	print("[EquipEffects] Applied buffs for " .. player.Name .. ": RollSpeed=" .. (rarityData.RollSpeedBuff or 0) .. ", Luck=" .. (rarityData.LuckBuff or 1))
end

---------------------------------------------------------------------
-- REMOVE BUFFS
---------------------------------------------------------------------
local function removeBuffs(player)
	EquipEffects.ActiveBuffs[player.UserId] = nil
	print("[EquipEffects] Removed buffs for " .. player.Name)
end

---------------------------------------------------------------------
-- GET ACTIVE BUFFS
---------------------------------------------------------------------
function EquipEffects.GetActiveBuffs(player)
	return EquipEffects.ActiveBuffs[player.UserId]
end

---------------------------------------------------------------------
-- EQUIP ELEMENT
---------------------------------------------------------------------
function EquipEffects.EquipElement(player, elementData)
	local character = player.Character
	if not character then return false end

	-- Only unequip if this is the local player's effects
	if player == Players.LocalPlayer then
		EquipEffects.UnequipElement(player)
	else
		if EquipEffects.ActiveEffects[player.UserId] then
			local effects = EquipEffects.ActiveEffects[player.UserId]
			local function destroy(v)
				if typeof(v) == "Instance" then v:Destroy() end
			end
			if effects.Particles then destroy(effects.Particles) end
			if effects.Nucleus then
				destroy(effects.Nucleus.Core)
				for _, n in ipairs(effects.Nucleus.Nucleons) do destroy(n) end
			end
			if effects.Shells then
				for _, shell in ipairs(effects.Shells) do
					for _, e in ipairs(shell) do destroy(e) end
				end
			end
			if effects.Rings then
				for _, r in ipairs(effects.Rings) do destroy(r) end
			end
			EquipEffects.ActiveEffects[player.UserId] = nil
		end
	end

	local RNGConfig = require(ReplicatedStorage:WaitForChild("RNGConfig"))
	local rarityColor = Color3.new(1,1,1)
	local rarityName = "Common"

	for _, r in ipairs(RNGConfig.Rarities) do
		if r.Name == elementData.Rarity then
			rarityColor = r.Color
			rarityName = r.Name
			break
		end
	end

	if player == Players.LocalPlayer and elementData.IsCrafted then
		applyBuffs(player, elementData)
	end

	local effects = {
		Particles = createElementParticles(character, elementData.ItemName, rarityName, rarityColor),
		Nucleus = createNucleus(character, elementData.ItemName, rarityColor, rarityName),
		Shells = createElectronShells(character, elementData.ItemName, rarityColor, rarityName),
		Rings = createAuraRings(character, rarityName, rarityColor),
	}

	EquipEffects.ActiveEffects[player.UserId] = effects
	return true
end

---------------------------------------------------------------------
-- UNEQUIP ELEMENT
---------------------------------------------------------------------
function EquipEffects.UnequipElement(player)
	local effects = EquipEffects.ActiveEffects[player.UserId]
	if not effects then return end

	removeBuffs(player)

	local function destroy(v)
		if typeof(v) == "Instance" then v:Destroy() end
	end

	if effects.Particles then destroy(effects.Particles) end
	if effects.Nucleus then
		destroy(effects.Nucleus.Core)
		for _, n in ipairs(effects.Nucleus.Nucleons) do destroy(n) end
	end
	if effects.Shells then
		for _, shell in ipairs(effects.Shells) do
			for _, e in ipairs(shell) do destroy(e) end
		end
	end
	if effects.Rings then
		for _, r in ipairs(effects.Rings) do destroy(r) end
	end

	EquipEffects.ActiveEffects[player.UserId] = nil
end

---------------------------------------------------------------------
-- CHARACTER ADDED
---------------------------------------------------------------------
function EquipEffects.OnCharacterAdded(player, character)
	task.wait(1)
	local folder = ReplicatedStorage:WaitForChild("RemoteEvents")
	local getEquipped = folder:FindFirstChild("GetEquippedFunction")

	if getEquipped then
		local ok, item = pcall(function()
			return getEquipped:InvokeServer()
		end)

		if ok and item then
			EquipEffects.EquipElement(player, item)
		end
	end
end

return EquipEffects
