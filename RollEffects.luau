--[[
	Roll Effects Module
	Handles visual effects and animations for rolls
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RollEffects = {}

-- Create a particle effect for rolls
function RollEffects.CreateRollParticles(player, rarityColor)
	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	-- Create particle emitter
	local particles = Instance.new("ParticleEmitter")
	particles.Parent = humanoidRootPart
	particles.Color = ColorSequence.new(rarityColor)
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2),
		NumberSequenceKeypoint.new(1, 0)
	})
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1)
	})
	particles.Lifetime = NumberRange.new(0.5, 1)
	particles.Rate = 50
	particles.Speed = NumberRange.new(5, 10)
	particles.SpreadAngle = Vector2.new(360, 360)
	particles.Enabled = true

	-- Disable after 2 seconds
	task.delay(2, function()
		particles.Enabled = false
		task.wait(1)
		particles:Destroy()
	end)
end

-- Create a beam effect shooting upward
function RollEffects.CreateBeamEffect(player, rarityColor)
	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	-- Create beam parts
	local beamPart = Instance.new("Part")
	beamPart.Anchored = true
	beamPart.CanCollide = false
	beamPart.Material = Enum.Material.Neon
	beamPart.Color = rarityColor
	beamPart.Size = Vector3.new(5, 50, 5)
	beamPart.CFrame = humanoidRootPart.CFrame * CFrame.new(0, 25, 0)
	beamPart.Transparency = 0.6
	beamPart.Parent = workspace

	-- Tween the beam
	local tweenInfo = TweenInfo.new(
		0.75,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)

	local tween = TweenService:Create(beamPart, tweenInfo, {
		Transparency = 1,
		Size = Vector3.new(8, 50, 8)
	})

	tween:Play()

	-- Destroy after animation
	task.delay(0.75, function()
		beamPart:Destroy()
	end)
end

-- Create a ring effect expanding outward
function RollEffects.CreateRingEffect(player, rarityColor)
	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	-- Create ring
	local ring = Instance.new("Part")
	ring.Anchored = true
	ring.CanCollide = false
	ring.Material = Enum.Material.Neon
	ring.Color = rarityColor
	ring.Size = Vector3.new(1, 0.5, 1)
	ring.Shape = Enum.PartType.Cylinder
	ring.CFrame = humanoidRootPart.CFrame * CFrame.Angles(0, 0, math.rad(90))
	ring.Transparency = 0.5
	ring.Parent = workspace

	-- Tween the ring
	local tweenInfo = TweenInfo.new(
		0.5,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)

	local tween = TweenService:Create(ring, tweenInfo, {
		Transparency = 1,
		Size = Vector3.new(20, 0.5, 20)
	})

	tween:Play()

	-- Destroy after animation
	task.delay(0.5, function()
		ring:Destroy()
	end)
end

-- Screen flash effect
function RollEffects.CreateScreenFlash(rarityColor, intensity)
	local player = game.Players.LocalPlayer
	if not player then return end

	local playerGui = player:WaitForChild("PlayerGui")

	-- Create flash frame
	local flashFrame = Instance.new("Frame")
	flashFrame.Name = "FlashEffect"
	flashFrame.Size = UDim2.new(1, 0, 1, 0)
	flashFrame.Position = UDim2.new(0, 0, 0, 0)
	flashFrame.BackgroundColor3 = rarityColor
	flashFrame.BackgroundTransparency = 1
	flashFrame.ZIndex = 1000
	flashFrame.Parent = playerGui

	-- Tween flash in and out
	local tweenInfo = TweenInfo.new(
		0.3,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.InOut
	)

	local tweenIn = TweenService:Create(flashFrame, tweenInfo, {
		BackgroundTransparency = 1 - intensity
	})

	local tweenOut = TweenService:Create(flashFrame, tweenInfo, {
		BackgroundTransparency = 1
	})

	tweenIn:Play()
	tweenIn.Completed:Connect(function()
		tweenOut:Play()
	end)

	-- Destroy after animation
	task.delay(0.6, function()
		flashFrame:Destroy()
	end)
end

-- Combined effect based on rarity
function RollEffects.PlayRollEffects(player, rarity, rarityColor, rarityIndex)
	-- Always play particles
	RollEffects.CreateRollParticles(player, rarityColor)

	-- Additional effects for rare items
	if rarityIndex >= 4 then -- Epic and above
		RollEffects.CreateRingEffect(player, rarityColor)
	end

	if rarityIndex >= 5 then -- Legendary and above
		RollEffects.CreateBeamEffect(player, rarityColor)
		RollEffects.CreateScreenFlash(rarityColor, 0.3)
	end

	if rarityIndex >= 7 then -- Divine and above
		RollEffects.CreateScreenFlash(rarityColor, 0.5)
		-- Extra particles
		task.delay(0.5, function()
			RollEffects.CreateRollParticles(player, rarityColor)
		end)
	end
end

return RollEffects