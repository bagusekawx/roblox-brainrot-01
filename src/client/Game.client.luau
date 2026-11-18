-- Brainrot Bay HUD: everything the player reads and presses. The cash bar across
-- the top, the shop / lock / rebirth / help buttons down the right, the event
-- banner under the bar, and the carry warning along the bottom. The client never
-- owns game state: it draws what the server syncs and sends requests back.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateSyncRemote = remotes:WaitForChild("StateSync")
local shopRemote = remotes:WaitForChild("ShopRequest")
local rebirthRemote = remotes:WaitForChild("RebirthRequest")
local lockRemote = remotes:WaitForChild("LockBaseRequest")
local eventBannerRemote = remotes:WaitForChild("EventBanner")

local latestState = nil

local function roundedCorners(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function makeLabel(parent, name, text, size, position, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.TextSize = textSize
	label.TextScaled = true
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.TextStrokeTransparency = 0.5
	label.Parent = parent
	return label
end

local function makeButton(parent, name, text, size, position, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 20
	button.TextScaled = true
	button.Parent = parent
	roundedCorners(button, 10)
	return button
end

-- The HUD root. Top-left stays empty: Roblox's own menu buttons sit there.
local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotBayHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10
gui.Parent = player:WaitForChild("PlayerGui")

-- Cash bar, top centre: cash, income, brainrots, rebirth multiplier.
local cashBar = Instance.new("Frame")
cashBar.Name = "CashBar"
cashBar.AnchorPoint = Vector2.new(0.5, 0)
cashBar.Position = UDim2.new(0.5, 0, 0, 12)
cashBar.Size = UDim2.fromOffset(680, 56)
cashBar.BackgroundColor3 = Color3.fromRGB(15, 35, 75)
cashBar.BackgroundTransparency = 0.15
cashBar.BorderSizePixel = 0
cashBar.Parent = gui
roundedCorners(cashBar, 12)

local cashLabel = makeLabel(cashBar, "CashLabel", "CASH $100", UDim2.new(0.25, 0, 1, 0), UDim2.new(0, 0, 0, 0), 22, Color3.fromRGB(120, 255, 120))
local incomeLabel = makeLabel(cashBar, "IncomeLabel", "+$0/s", UDim2.new(0.25, 0, 1, 0), UDim2.new(0.25, 0, 0, 0), 22, Color3.fromRGB(255, 220, 80))
local countLabel = makeLabel(cashBar, "CountLabel", "BRAINROTS 0/4", UDim2.new(0.25, 0, 1, 0), UDim2.new(0.5, 0, 0, 0), 22, Color3.fromRGB(140, 200, 255))
local rebirthLabel = makeLabel(cashBar, "RebirthLabel", "REBIRTH x1.00", UDim2.new(0.25, 0, 1, 0), UDim2.new(0.75, 0, 0, 0), 22, Color3.fromRGB(220, 160, 255))

-- Event banner, under the cash bar: hidden until the server warns of a tsunami.
local banner = Instance.new("Frame")
banner.Name = "EventBanner"
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 78)
banner.Size = UDim2.fromOffset(560, 44)
banner.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
banner.BackgroundTransparency = 0.1
banner.BorderSizePixel = 0
banner.Visible = false
banner.Parent = gui
roundedCorners(banner, 10)
local bannerLabel = makeLabel(banner, "BannerLabel", "", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 22)

-- Buttons down the right side: shop, base lock, rebirth, help.
local shopButton = makeButton(gui, "ShopButton", "SHOP", UDim2.fromOffset(150, 48), UDim2.new(1, -166, 0, 90), Color3.fromRGB(40, 170, 70))
local lockButton = makeButton(gui, "LockButton", "LOCK BASE", UDim2.fromOffset(150, 48), UDim2.new(1, -166, 0, 146), Color3.fromRGB(40, 110, 220))
local rebirthButton = makeButton(gui, "RebirthButton", "REBIRTH", UDim2.fromOffset(150, 48), UDim2.new(1, -166, 0, 202), Color3.fromRGB(150, 70, 220))
local helpButton = makeButton(gui, "HelpButton", "HELP", UDim2.fromOffset(150, 48), UDim2.new(1, -166, 0, 258), Color3.fromRGB(100, 100, 110))

-- Carry warning, bottom centre: shows while the player carries a stolen brainrot.
local carryFrame = Instance.new("Frame")
carryFrame.Name = "CarryFrame"
carryFrame.AnchorPoint = Vector2.new(0.5, 1)
carryFrame.Position = UDim2.new(0.5, 0, 1, -16)
carryFrame.Size = UDim2.fromOffset(520, 44)
carryFrame.BackgroundColor3 = Color3.fromRGB(220, 130, 30)
carryFrame.BackgroundTransparency = 0.1
carryFrame.BorderSizePixel = 0
carryFrame.Visible = false
carryFrame.Parent = gui
roundedCorners(carryFrame, 10)
local carryLabel = makeLabel(carryFrame, "CarryLabel", "", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 20)

-- Controls hint, bottom left.
makeLabel(gui, "HintLabel", "WASD move  |  E buy / steal  |  SHOP for upgrades", UDim2.fromOffset(420, 28), UDim2.new(0, 12, 1, -40), 16)

-- Shop panel, centre screen: one row per upgrade, plus the rebirth row.
local shopPanel = Instance.new("Frame")
shopPanel.Name = "ShopPanel"
shopPanel.AnchorPoint = Vector2.new(0.5, 0.5)
shopPanel.Position = UDim2.fromScale(0.5, 0.5)
shopPanel.Size = UDim2.fromOffset(500, 400)
shopPanel.BackgroundColor3 = Color3.fromRGB(20, 30, 55)
shopPanel.BackgroundTransparency = 0.05
shopPanel.BorderSizePixel = 0
shopPanel.Visible = false
shopPanel.Parent = gui
roundedCorners(shopPanel, 14)
makeLabel(shopPanel, "ShopTitle", "UPGRADE SHOP", UDim2.new(1, 0, 0, 52), UDim2.new(0, 0, 0, 8), 28, Color3.fromRGB(255, 220, 80))

local shopRows = {}
local rowY = 68
for _, upgradeId in ipairs({ "WalkSpeed", "Carry", "Slots" }) do
	local upgrade = BrainrotData.Upgrades[upgradeId]
	local row = Instance.new("Frame")
	row.Name = upgradeId .. "Row"
	row.Position = UDim2.new(0, 16, 0, rowY)
	row.Size = UDim2.fromOffset(468, 64)
	row.BackgroundColor3 = Color3.fromRGB(35, 50, 90)
	row.BorderSizePixel = 0
	row.Parent = shopPanel
	roundedCorners(row, 8)
	makeLabel(row, "Name", upgrade.label, UDim2.new(0.42, 0, 0.5, 0), UDim2.new(0, 12, 0, 4), 20)
	makeLabel(row, "Desc", upgrade.desc, UDim2.new(0.42, 0, 0.5, 0), UDim2.new(0, 12, 0.5, -4), 16, Color3.fromRGB(180, 180, 180))
	local levelLabel = makeLabel(row, "Level", "Lv 0/5", UDim2.new(0.2, 0, 1, 0), UDim2.new(0.42, 0, 0, 0), 18, Color3.fromRGB(140, 200, 255))
	local buyButton = makeButton(row, "Buy", "$100", UDim2.fromOffset(120, 40), UDim2.new(1, -132, 0.5, -20), Color3.fromRGB(40, 170, 70))
	buyButton.MouseButton1Click:Connect(function()
		shopRemote:FireServer(upgradeId)
	end)
	shopRows[upgradeId] = { levelLabel = levelLabel, buyButton = buyButton, maxLevel = upgrade.maxLevel }
	rowY += 76
end

local rebirthRow = Instance.new("Frame")
rebirthRow.Name = "RebirthRow"
rebirthRow.Position = UDim2.new(0, 16, 0, rowY)
rebirthRow.Size = UDim2.fromOffset(468, 64)
rebirthRow.BackgroundColor3 = Color3.fromRGB(70, 35, 110)
rebirthRow.BorderSizePixel = 0
rebirthRow.Parent = shopPanel
roundedCorners(rebirthRow, 8)
makeLabel(rebirthRow, "Name", "REBIRTH", UDim2.new(0.42, 0, 0.5, 0), UDim2.new(0, 12, 0, 4), 20, Color3.fromRGB(220, 160, 255))
makeLabel(rebirthRow, "Desc", "+25% income forever. Resets cash + brainrots.", UDim2.new(0.42, 0, 0.5, 0), UDim2.new(0, 12, 0.5, -4), 14, Color3.fromRGB(200, 180, 220))
local rebirthCostLabel = makeLabel(rebirthRow, "Level", "$1,000", UDim2.new(0.2, 0, 1, 0), UDim2.new(0.42, 0, 0, 0), 18, Color3.fromRGB(220, 160, 255))
local rebirthBuyButton = makeButton(rebirthRow, "Buy", "REBIRTH", UDim2.fromOffset(120, 40), UDim2.new(1, -132, 0.5, -20), Color3.fromRGB(150, 70, 220))
rebirthBuyButton.MouseButton1Click:Connect(function()
	rebirthRemote:FireServer()
end)

local shopClose = makeButton(shopPanel, "Close", "X", UDim2.fromOffset(36, 36), UDim2.new(1, -44, 0, 8), Color3.fromRGB(200, 60, 60))
shopClose.MouseButton1Click:Connect(function()
	shopPanel.Visible = false
end)

-- Help panel, centre screen: how the game plays, in six lines.
local helpPanel = Instance.new("Frame")
helpPanel.Name = "HelpPanel"
helpPanel.AnchorPoint = Vector2.new(0.5, 0.5)
helpPanel.Position = UDim2.fromScale(0.5, 0.5)
helpPanel.Size = UDim2.fromOffset(520, 340)
helpPanel.BackgroundColor3 = Color3.fromRGB(20, 30, 55)
helpPanel.BackgroundTransparency = 0.05
helpPanel.BorderSizePixel = 0
helpPanel.Visible = false
helpPanel.Parent = gui
roundedCorners(helpPanel, 14)
makeLabel(helpPanel, "HelpTitle", "HOW TO PLAY", UDim2.new(1, 0, 0, 52), UDim2.new(0, 0, 0, 8), 28, Color3.fromRGB(255, 220, 80))
local helpText = makeLabel(
	helpPanel,
	"HelpText",
	"1. Brainrots walk the path. Press E near one to buy it.\n"
		.. "2. It moves to your base and earns cash every second.\n"
		.. "3. Steal from other bases with E -- then run home!\n"
		.. "4. LOCK BASE stops thieves for 30 seconds.\n"
		.. "5. A tsunami sweeps the island every few minutes and\n"
		.. "     knocks carried brainrots loose. Get home first!\n"
		.. "6. REBIRTH resets you for +25% income, forever.",
	UDim2.new(1, -32, 1, -72),
	UDim2.new(0, 16, 0, 60),
	18
)
helpText.TextXAlignment = Enum.TextXAlignment.Left
helpText.TextYAlignment = Enum.TextYAlignment.Top
local helpClose = makeButton(helpPanel, "Close", "X", UDim2.fromOffset(36, 36), UDim2.new(1, -44, 0, 8), Color3.fromRGB(200, 60, 60))
helpClose.MouseButton1Click:Connect(function()
	helpPanel.Visible = false
end)

-- Redraws every label and button from the latest synced state.
local function refreshHudFromState(state)
	cashLabel.Text = "CASH $" .. state.cash
	incomeLabel.Text = "+$" .. state.incomePerSecond .. "/s"
	countLabel.Text = "BRAINROTS " .. state.brainrotCount .. "/" .. state.slotCount
	rebirthLabel.Text = "REBIRTH x" .. string.format("%.2f", state.multiplier)
	if state.lockSecondsLeft > 0 then
		lockButton.Text = "LOCKED " .. math.ceil(state.lockSecondsLeft) .. "s"
	elseif state.lockCooldownLeft > 0 then
		lockButton.Text = "LOCK (" .. math.ceil(state.lockCooldownLeft) .. "s)"
	else
		lockButton.Text = "LOCK BASE"
	end
	rebirthCostLabel.Text = "$" .. state.rebirthCost
	local levels = { WalkSpeed = state.walkSpeedLevel, Carry = state.carryLevel, Slots = state.slotLevel }
	for upgradeId, row in pairs(shopRows) do
		local level = levels[upgradeId] or 0
		row.levelLabel.Text = "Lv " .. level .. "/" .. row.maxLevel
		if level >= row.maxLevel then
			row.buyButton.Text = "MAX"
		else
			row.buyButton.Text = "$" .. BrainrotData.upgradeCostFor(upgradeId, level)
		end
	end
	if #state.carrying > 0 then
		carryFrame.Visible = true
		carryLabel.Text = "CARRYING: " .. table.concat(state.carrying, ", ") .. " -- get to your base!"
	else
		carryFrame.Visible = false
	end
end

stateSyncRemote.OnClientEvent:Connect(function(state)
	latestState = state
	refreshHudFromState(state)
end)

eventBannerRemote.OnClientEvent:Connect(function(text, seconds)
	bannerLabel.Text = text
	banner.Visible = true
	task.delay(seconds, function()
		banner.Visible = false
	end)
end)

shopButton.MouseButton1Click:Connect(function()
	shopPanel.Visible = not shopPanel.Visible
	if shopPanel.Visible then
		helpPanel.Visible = false
		if latestState then
			refreshHudFromState(latestState)
		end
	end
end)
helpButton.MouseButton1Click:Connect(function()
	helpPanel.Visible = not helpPanel.Visible
	if helpPanel.Visible then
		shopPanel.Visible = false
	end
end)
lockButton.MouseButton1Click:Connect(function()
	lockRemote:FireServer()
end)
rebirthButton.MouseButton1Click:Connect(function()
	rebirthRemote:FireServer()
end)
