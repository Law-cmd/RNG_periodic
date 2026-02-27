--[[
	Money Display
	Shows the player's current money on screen
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for RemoteEvents
local RemoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local MoneyUpdateEvent = RemoteEventsFolder:WaitForChild("MoneyUpdateEvent")

-- Create money display GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MoneyDisplayGui"
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 50 -- Show above other GUIs
screenGui.Parent = playerGui

-- Money frame
local moneyFrame = Instance.new("Frame")
moneyFrame.Name = "MoneyFrame"
moneyFrame.Size = UDim2.new(0, 200, 0, 50)
moneyFrame.Position = UDim2.new(1, -210, 0, 10)
moneyFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
moneyFrame.BorderSizePixel = 0
moneyFrame.Parent = screenGui

local moneyCorner = Instance.new("UICorner")
moneyCorner.CornerRadius = UDim.new(0, 10)
moneyCorner.Parent = moneyFrame

local moneyStroke = Instance.new("UIStroke")
moneyStroke.Color = Color3.fromRGB(255, 215, 0) -- Gold color
moneyStroke.Thickness = 2
moneyStroke.Parent = moneyFrame

-- Money icon
local moneyIcon = Instance.new("TextLabel")
moneyIcon.Size = UDim2.new(0, 40, 1, 0)
moneyIcon.BackgroundTransparency = 1
moneyIcon.Text = "💰"
moneyIcon.TextSize = 24
moneyIcon.Font = Enum.Font.GothamBold
moneyIcon.Parent = moneyFrame

-- Money label
local moneyLabel = Instance.new("TextLabel")
moneyLabel.Name = "MoneyLabel"
moneyLabel.Size = UDim2.new(1, -50, 1, 0)
moneyLabel.Position = UDim2.new(0, 40, 0, 0)
moneyLabel.BackgroundTransparency = 1
moneyLabel.Text = "$0 (+$1/s)"
moneyLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
moneyLabel.TextSize = 18
moneyLabel.Font = Enum.Font.GothamBold
moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
moneyLabel.Parent = moneyFrame

-- Track current income rate
local currentIncomeRate = 1

-- Update money display
local function updateMoneyDisplay(amount, incomeRate)
	if incomeRate then
		currentIncomeRate = incomeRate
	end
	moneyLabel.Text = "$" .. tostring(amount) .. " (+$" .. tostring(currentIncomeRate) .. "/s)"
end

-- Listen for money updates from server
MoneyUpdateEvent.OnClientEvent:Connect(function(data)
	if data and data.Total ~= nil then
		updateMoneyDisplay(data.Total, data.IncomeRate)
	end
end)

-- Request initial money from server
task.spawn(function()
	task.wait(1)
	local GetMoneyFunction = RemoteEventsFolder:FindFirstChild("GetMoneyFunction")
	if GetMoneyFunction then
		local success, currentMoney = pcall(function()
			return GetMoneyFunction:InvokeServer()
		end)
		if success and currentMoney then
			updateMoneyDisplay(currentMoney)
		end
	end
end)

print("[MoneyDisplay] Initialized")