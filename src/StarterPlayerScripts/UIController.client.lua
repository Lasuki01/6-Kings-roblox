-- ============================================
-- UIController.client.lua — Kingdom Siege
-- Renders the game HUD (Gold, Wave, Crystal HP) and manages interactive 3D context menus.
-- Side: Client
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")-- Configuration modules
local Config = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Config")
local TowerConfig = require(Config:WaitForChild("TowerConfig"))
local EconomyConfig = require(Config:WaitForChild("EconomyConfig"))
local HeroConfig = require(Config:WaitForChild("HeroConfig"))

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PlaceTower = Remotes:WaitForChild("PlaceTower")
local UpgradeTower = Remotes:WaitForChild("UpgradeTower")
local SellTower = Remotes:WaitForChild("SellTower")
local SelectClass = Remotes:WaitForChild("SelectClass")
local UseAbility = Remotes:WaitForChild("UseAbility")
local PurchaseItem = Remotes:WaitForChild("PurchaseItem")
local SyncGameState = Remotes:WaitForChild("SyncGameState")

-- Player references
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Active Floating Menu Reference
local currentOpenMenu = nil

-- Close active Billboard menu
local function CloseCurrentMenu()
	if currentOpenMenu then
		currentOpenMenu:Destroy()
		currentOpenMenu = nil
	end
end

-- ============================================
-- AUDIO & CUES SYSTEM
-- ============================================
local activeAmbientMusic = nil

local function TriggerLocalSound(soundId, volume)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. tostring(soundId)
	sound.Volume = volume or 0.6
	sound.Parent = playerGui
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	return sound
end

local function PlayAmbientMusic()
	if activeAmbientMusic then
		activeAmbientMusic:Stop()
		activeAmbientMusic:Destroy()
	end
	-- Gothic Castle Ambient Loop ID (Using verified working wind loop)
	activeAmbientMusic = TriggerLocalSound(6990273398, 0.25)
	activeAmbientMusic.Looped = true
end

-- Forward declaration of Class Selection and Main Menu functions
local OpenClassSelectionScreen

local function OpenMainMenuScreen()
	local lobbyGui = Instance.new("ScreenGui")
	lobbyGui.Name = "MainMenuGui"
	lobbyGui.ResetOnSpawn = false
	lobbyGui.Parent = playerGui
	
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
	background.Parent = lobbyGui
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 100)
	title.Position = UDim2.new(0, 0, 0.15, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = Color3.fromRGB(255, 60, 60)
	title.TextSize = 48
	title.Text = "KINGDOM SIEGE"
	title.Parent = background

	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Color3.fromRGB(20, 20, 25)
	titleStroke.Thickness = 2
	titleStroke.Parent = title
	
	-- Subtitle
	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1, 0, 0, 40)
	desc.Position = UDim2.new(0, 0, 0.28, 0)
	desc.BackgroundTransparency = 1
	desc.Font = Enum.Font.GothamSemibold
	desc.TextColor3 = Color3.fromRGB(150, 150, 155)
	desc.TextSize = 14
	desc.Text = "Co-op Medieval Fantasy Active Tower Defense"
	desc.Parent = background
	
	-- Stats Container
	local statsBox = Instance.new("Frame")
	statsBox.Size = UDim2.new(0, 320, 0, 140)
	statsBox.Position = UDim2.new(0.5, 0, 0.5, -20)
	statsBox.AnchorPoint = Vector2.new(0.5, 0.5)
	statsBox.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
	statsBox.Parent = background
	
	local statsCorner = Instance.new("UICorner")
	statsCorner.CornerRadius = UDim.new(0, 10)
	statsCorner.Parent = statsBox
	
	local statsStroke = Instance.new("UIStroke")
	statsStroke.Color = Color3.fromRGB(50, 50, 55)
	statsStroke.Thickness = 1.5
	statsStroke.Parent = statsBox
	
	local statsLayout = Instance.new("UIListLayout")
	statsLayout.FillDirection = Enum.FillDirection.Vertical
	statsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	statsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	statsLayout.Padding = UDim.new(0, 8)
	statsLayout.Parent = statsBox
	
	local statsTitle = Instance.new("TextLabel")
	statsTitle.Size = UDim2.new(0.9, 0, 0, 24)
	statsTitle.BackgroundTransparency = 1
	statsTitle.Font = Enum.Font.GothamBold
	statsTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
	statsTitle.TextSize = 13
	statsTitle.Text = "🛡️ YOUR HERO PROGRESS 🛡️"
	statsTitle.Parent = statsBox
	
	local lvlLbl = Instance.new("TextLabel")
	lvlLbl.Size = UDim2.new(0.9, 0, 0, 18)
	lvlLbl.BackgroundTransparency = 1
	lvlLbl.Font = Enum.Font.GothamSemibold
	lvlLbl.TextColor3 = Color3.fromRGB(240, 240, 245)
	lvlLbl.TextSize = 11
	lvlLbl.Text = "Level: 1 (XP: 0/100)"
	lvlLbl.Parent = statsBox
	
	local winsLbl = Instance.new("TextLabel")
	winsLbl.Size = UDim2.new(0.9, 0, 0, 18)
	winsLbl.BackgroundTransparency = 1
	winsLbl.Font = Enum.Font.GothamSemibold
	winsLbl.TextColor3 = Color3.fromRGB(200, 200, 205)
	winsLbl.TextSize = 11
	winsLbl.Text = "Total Wins: 0 | Total Matches: 0"
	winsLbl.Parent = statsBox
	
	local currencyLbl = Instance.new("TextLabel")
	currencyLbl.Size = UDim2.new(0.9, 0, 0, 18)
	currencyLbl.BackgroundTransparency = 1
	currencyLbl.Font = Enum.Font.GothamSemibold
	currencyLbl.TextColor3 = Color3.fromRGB(0, 255, 255)
	currencyLbl.TextSize = 11
	currencyLbl.Text = "Gems balance: 0"
	currencyLbl.Parent = statsBox
	
	-- Sync stats
	local function sync()
		local lvl = player:GetAttribute("Level") or 1
		local xp = player:GetAttribute("XP") or 0
		local wins = player:GetAttribute("TotalWins") or 0
		local matches = player:GetAttribute("TotalMatches") or 0
		local gems = player:GetAttribute("Gems") or 0
		
		lvlLbl.Text = "Level: " .. lvl .. " (XP: " .. xp .. "/" .. (lvl * 100) .. ")"
		winsLbl.Text = "Total Wins: " .. wins .. " | Total Matches: " .. matches
		currencyLbl.Text = "Gems balance: " .. gems
	end
	
	player:GetAttributeChangedSignal("Level"):Connect(sync)
	player:GetAttributeChangedSignal("XP"):Connect(sync)
	player:GetAttributeChangedSignal("TotalWins"):Connect(sync)
	player:GetAttributeChangedSignal("TotalMatches"):Connect(sync)
	player:GetAttributeChangedSignal("Gems"):Connect(sync)
	sync()
	
	-- Play Button
	local playBtn = Instance.new("TextButton")
	playBtn.Size = UDim2.new(0, 200, 0, 50)
	playBtn.Position = UDim2.new(0.5, 0, 0.75, 0)
	playBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	playBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 85)
	playBtn.BorderSizePixel = 0
	playBtn.Font = Enum.Font.GothamBold
	playBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	playBtn.TextSize = 16
	playBtn.Text = "ENTER BATTLE ⚔️"
	playBtn.Parent = background
	
	local playCorner = Instance.new("UICorner")
	playCorner.CornerRadius = UDim.new(0, 8)
	playCorner.Parent = playBtn
	
	local playStroke = Instance.new("UIStroke")
	playStroke.Color = Color3.fromRGB(255, 255, 255)
	playStroke.Thickness = 1.5
	playStroke.Parent = playBtn
	
	playBtn.MouseButton1Click:Connect(function()
		playBtn.Active = false
		TriggerLocalSound(12222247) -- UI select click
		
		local tween = TweenService:Create(background, TweenInfo.new(0.5), {Position = UDim2.new(0, 0, -1, 0)})
		tween:Play()
		tween.Completed:Wait()
		lobbyGui:Destroy()
		
		OpenClassSelectionScreen()
	end)
end

local function ShowEndgameOverlay(isVictory)
	local old = playerGui:FindFirstChild("EndgameGui")
	if old then old:Destroy() end
	
	local endgameGui = Instance.new("ScreenGui")
	endgameGui.Name = "EndgameGui"
	endgameGui.ResetOnSpawn = false
	endgameGui.Parent = playerGui
	
	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.Position = UDim2.new(0, 0, -1, 0)
	bg.BackgroundColor3 = isVictory and Color3.fromRGB(10, 24, 15) or Color3.fromRGB(24, 10, 10)
	bg.BackgroundTransparency = 0.15
	bg.Parent = endgameGui
	
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 80)
	title.Position = UDim2.new(0, 0, 0.35, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = isVictory and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(220, 40, 40)
	title.TextSize = 48
	title.Text = isVictory and "VICTORY 🎉" or "DEFEAT 💀"
	title.Parent = bg
	
	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(1, 0, 0, 40)
	subtitle.Position = UDim2.new(0, 0, 0.46, 0)
	subtitle.BackgroundTransparency = 1
	subtitle.Font = Enum.Font.GothamSemibold
	subtitle.TextColor3 = Color3.fromRGB(200, 200, 205)
	subtitle.TextSize = 16
	subtitle.Text = isVictory and "The Kingdom Crystal stands secure!" or "The Kingdom Crystal was shattered!"
	subtitle.Parent = bg
	
	if isVictory then
		TriggerLocalSound(9072709214) -- victory fanfare
	else
		TriggerLocalSound(9072709087) -- defeat sound
	end
	
	TweenService:Create(bg, TweenInfo.new(0.6, Enum.EasingStyle.Bounce), {Position = UDim2.new(0, 0, 0, 0)}):Play()
end

-- ============================================
-- 1. BUILD BOTTOM SCREEN HUD
-- ============================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GameHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main HUD bar container (Sleek dark theme, responsive)
local hudBar = Instance.new("Frame")
hudBar.Name = "HUDBar"
hudBar.Size = UDim2.new(0.95, 0, 0, 50)
hudBar.Position = UDim2.new(0.5, 0, 1, -15)
hudBar.AnchorPoint = Vector2.new(0.5, 1)
hudBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
hudBar.BackgroundTransparency = 0.15
hudBar.BorderSizePixel = 0
hudBar.Parent = screenGui

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MaxSize = Vector2.new(500, 55)
sizeConstraint.MinSize = Vector2.new(320, 45)
sizeConstraint.Parent = hudBar

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 10)
barCorner.Parent = hudBar

local barStroke = Instance.new("UIStroke")
barStroke.Color = Color3.fromRGB(60, 60, 65)
barStroke.Thickness = 1.5
barStroke.Parent = hudBar

-- Layout
local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Horizontal
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 10)
listLayout.Parent = hudBar

-- Helper: Create text labels
local function CreateHUDLabel(name, textColor, text, layoutOrder)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(0.3, 0, 0.8, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = textColor
	label.TextSize = 13
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Text = text
	label.LayoutOrder = layoutOrder
	label.Parent = hudBar
	
	local textConstraint = Instance.new("UITextSizeConstraint")
	textConstraint.MaxTextSize = 15
	textConstraint.MinTextSize = 10
	textConstraint.Parent = label

	return label
end

-- Gold, Gems, Wave, HP, and VIP status displays
local goldLabel = CreateHUDLabel("GoldLabel", Color3.fromRGB(255, 200, 50), "🪙 Gold: 400", 1)
goldLabel.Size = UDim2.new(0.18, 0, 0.8, 0)

local gemsLabel = CreateHUDLabel("GemsLabel", Color3.fromRGB(0, 255, 255), "💎 Gems: 0", 2)
gemsLabel.Size = UDim2.new(0.18, 0, 0.8, 0)

local waveLabel = CreateHUDLabel("WaveLabel", Color3.fromRGB(255, 255, 255), "🚩 Wave: 0/20", 3)
waveLabel.Size = UDim2.new(0.16, 0, 0.8, 0)

-- Crystal Health bar container
local hpContainer = Instance.new("Frame")
hpContainer.Name = "HPContainer"
hpContainer.Size = UDim2.new(0.24, 0, 0.8, 0)
hpContainer.BackgroundTransparency = 1
hpContainer.LayoutOrder = 4
hpContainer.Parent = hudBar

local vipLabel = CreateHUDLabel("VIPLabel", Color3.fromRGB(120, 120, 120), "👑 VIP", 5)
vipLabel.Size = UDim2.new(0.12, 0, 0.8, 0)

-- Make Gems and VIP labels interactive to prompt purchase
local gemsButton = Instance.new("TextButton")
gemsButton.Size = UDim2.new(1, 0, 1, 0)
gemsButton.BackgroundTransparency = 1
gemsButton.Text = ""
gemsButton.Parent = gemsLabel
gemsButton.MouseButton1Click:Connect(function()
	print("[UIController] Tapped Gems Label - Prompting 500 Gems purchase")
	PurchaseItem:FireServer("Product", "GEMS_500_ID")
end)

local vipButton = Instance.new("TextButton")
vipButton.Size = UDim2.new(1, 0, 1, 0)
vipButton.BackgroundTransparency = 1
vipButton.Text = ""
vipButton.Parent = vipLabel
vipButton.MouseButton1Click:Connect(function()
	print("[UIController] Tapped VIP Label - Prompting VIP pass purchase")
	PurchaseItem:FireServer("GamePass", "VIP_PASS_ID")
end)

local hpBgBar = Instance.new("Frame")
hpBgBar.Name = "HPBackground"
hpBgBar.Size = UDim2.new(1, 0, 0, 16)
hpBgBar.Position = UDim2.new(0, 0, 0.5, 0)
hpBgBar.AnchorPoint = Vector2.new(0, 0.5)
hpBgBar.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
hpBgBar.BorderSizePixel = 0
hpBgBar.Parent = hpContainer

local hpCorner = Instance.new("UICorner")
hpCorner.CornerRadius = UDim.new(0, 4)
hpCorner.Parent = hpBgBar

local hpFillBar = Instance.new("Frame")
hpFillBar.Name = "HPFill"
hpFillBar.Size = UDim2.new(1, 0, 1, 0)
hpFillBar.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
hpFillBar.BorderSizePixel = 0
hpFillBar.Parent = hpBgBar

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 4)
fillCorner.Parent = hpFillBar

local hpText = Instance.new("TextLabel")
hpText.Name = "HPText"
hpText.Size = UDim2.new(1, 0, 1, 0)
hpText.BackgroundTransparency = 1
hpText.Font = Enum.Font.GothamBold
-- Overlay white text
hpText.TextColor3 = Color3.fromRGB(255, 255, 255)
hpText.TextSize = 10
hpText.Text = "🛡️ HP: 1000/1000"
hpText.ZIndex = 3
hpText.Parent = hpContainer

-- STAT SYNCHRONIZERS

local function SyncGold()
	local gold = player:GetAttribute("Gold") or 0
	goldLabel.Text = "🪙 Gold: " .. gold
end

local function SyncGems()
	local gems = player:GetAttribute("Gems") or 0
	gemsLabel.Text = "💎 Gems: " .. gems
end

local function SyncVIP()
	local isVip = player:GetAttribute("IsVIP") == true
	if isVip then
		vipLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold color
	else
		vipLabel.TextColor3 = Color3.fromRGB(80, 80, 85) -- greyed out
	end
end

local function SyncWave()
	local wave = workspace:GetAttribute("CurrentWave") or 0
	waveLabel.Text = "🚩 Wave: " .. wave .. "/20"
end

local function SyncCrystalHP()
	local crystal = workspace:WaitForChild("KingdomCrystal", 10)
	if crystal then
		local hpVal = crystal:WaitForChild("CrystalHP", 5)
		if hpVal then
			local function update()
				local hp = hpVal.Value
				local maxHP = EconomyConfig.CRYSTAL_MAX_HP
				local pct = math.clamp(hp / maxHP, 0, 1)
				TweenService:Create(hpFillBar, TweenInfo.new(0.3), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
				hpText.Text = "🛡️ HP: " .. hp .. "/" .. maxHP
			end
			hpVal.Changed:Connect(update)
			update()
		end
	end
end

player:GetAttributeChangedSignal("Gold"):Connect(SyncGold)
player:GetAttributeChangedSignal("Gems"):Connect(SyncGems)
player:GetAttributeChangedSignal("IsVIP"):Connect(SyncVIP)
workspace:GetAttributeChangedSignal("CurrentWave"):Connect(SyncWave)

-- Run initial syncs
SyncGold()
SyncGems()
SyncVIP()
SyncWave()
task.spawn(SyncCrystalHP)

-- ============================================
-- 1B. BUILD TOP-RIGHT PROFILE HUD (Level & XP)
-- ============================================
local profileBar = Instance.new("Frame")
profileBar.Name = "ProfileBar"
profileBar.Size = UDim2.new(0, 130, 0, 45)
profileBar.Position = UDim2.new(1, -15, 0, 15)
profileBar.AnchorPoint = Vector2.new(1, 0)
profileBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
profileBar.BackgroundTransparency = 0.15
profileBar.BorderSizePixel = 0
profileBar.Parent = screenGui

local profileCorner = Instance.new("UICorner")
profileCorner.CornerRadius = UDim.new(0, 8)
profileCorner.Parent = profileBar

local profileStroke = Instance.new("UIStroke")
profileStroke.Color = Color3.fromRGB(60, 60, 65)
profileStroke.Thickness = 1.2
profileStroke.Parent = profileBar

local profileLayout = Instance.new("UIListLayout")
profileLayout.FillDirection = Enum.FillDirection.Vertical
profileLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
profileLayout.VerticalAlignment = Enum.VerticalAlignment.Center
profileLayout.Padding = UDim.new(0, 2)
profileLayout.Parent = profileBar

local levelText = Instance.new("TextLabel")
levelText.Size = UDim2.new(0.9, 0, 0.4, 0)
levelText.BackgroundTransparency = 1
levelText.Font = Enum.Font.GothamBold
levelText.TextColor3 = Color3.fromRGB(255, 215, 0) -- gold color
levelText.TextSize = 11
levelText.Text = "⭐ Level: 1"
levelText.Parent = profileBar

local xpTextLabel = Instance.new("TextLabel")
xpTextLabel.Size = UDim2.new(0.9, 0, 0.4, 0)
xpTextLabel.BackgroundTransparency = 1
xpTextLabel.Font = Enum.Font.GothamSemibold
xpTextLabel.TextColor3 = Color3.fromRGB(200, 200, 205)
xpTextLabel.TextSize = 9
xpTextLabel.Text = "XP: 0/100"
xpTextLabel.Parent = profileBar

local function SyncProfile()
	local lvl = player:GetAttribute("Level") or 1
	local xp = player:GetAttribute("XP") or 0
	local maxXP = lvl * 100
	levelText.Text = "⭐ Level: " .. lvl
	xpTextLabel.Text = "XP: " .. xp .. "/" .. maxXP
end

player:GetAttributeChangedSignal("Level"):Connect(SyncProfile)
player:GetAttributeChangedSignal("XP"):Connect(SyncProfile)
SyncProfile()

-- ============================================
-- 2. BUILD BILLBOARD CONTEXT MENU
-- ============================================

-- Helper: Create a styled context menu button
local function CreateMenuButton(name, text, color, parent)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(0.9, 0, 0, 36) -- Increased touch target height for mobile fingers
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 11
	button.Text = text
	button.Parent = parent

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 5)
	btnCorner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = 0.85
	stroke.Thickness = 1
	stroke.Parent = button

	-- Subtle hover transitions
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.15), {BackgroundTransparency = 0.15}):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.15), {BackgroundTransparency = 0.0}):Play()
	end)

	return button
end

-- Open context menu above a selected zonePart
local function OpenPlacementMenu(zonePart)
	CloseCurrentMenu()

	local isOccupied = zonePart:GetAttribute("Occupied") == true
	local towerModelVal = zonePart:FindFirstChild("TowerModel")
	local towerModel = towerModelVal and towerModelVal.Value
	
	-- Height and sizing based on state (scaled up for mobile buttons)
	local menuHeight = isOccupied and 135 or 240
	
	-- Billboard Frame
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PlacementMenu"
	billboard.Adornee = zonePart
	billboard.Size = UDim2.new(0, 245, 0, menuHeight) -- wider for fingers
	billboard.StudsOffset = Vector3.new(0, 6, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = playerGui
	currentOpenMenu = billboard

	-- Main background Frame
	local frame = Instance.new("Frame")
	frame.Name = "Container"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	frame.BackgroundTransparency = 0.12
	frame.BorderSizePixel = 0
	frame.Parent = billboard

	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 8)
	frameCorner.Parent = frame

	local frameStroke = Instance.new("UIStroke")
	frameStroke.Color = Color3.fromRGB(75, 75, 80)
	frameStroke.Thickness = 1.5
	frameStroke.Parent = frame

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 5)
	layout.Parent = frame

	if not isOccupied then
		-- Option Header
		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.Size = UDim2.new(0.9, 0, 0, 22)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBold
		title.TextColor3 = Color3.fromRGB(150, 150, 155)
		title.TextSize = 11
		title.Text = "SELECT TOWER TO PLACE"
		title.Parent = frame

		-- Iterates over config definitions to draw purchase buttons
		-- Sort by Cost ascending
		local sortedTowers = {}
		for name, config in pairs(TowerConfig.Towers) do
			table.insert(sortedTowers, {Name = name, Config = config})
		end
		table.sort(sortedTowers, function(a, b)
			return a.Config.Levels[1].Cost < b.Config.Levels[1].Cost
		end)

		local currentWave = workspace:GetAttribute("CurrentWave") or 0

		for _, item in ipairs(sortedTowers) do
			local name = item.Name
			local config = item.Config
			local cost = config.Levels[1].Cost
			local isLocked = config.UnlockWave and currentWave < config.UnlockWave
			
			local btnText = config.Name .. " (" .. cost .. " G)"
			local btnColor = Color3.fromRGB(45, 45, 52)
			
			if isLocked then
				btnText = config.Name .. " (Wave " .. config.UnlockWave .. ")"
				btnColor = Color3.fromRGB(30, 20, 20)
			end

			local btn = CreateMenuButton("Buy_" .. name, btnText, btnColor, frame)
			
			if isLocked then
				btn.TextColor3 = Color3.fromRGB(150, 100, 100)
				btn.Active = false
			else
				btn.MouseButton1Click:Connect(function()
					PlaceTower:FireServer(name, zonePart)
					TriggerLocalSound(286522724) -- place hammer sound
					CloseCurrentMenu()
				end)
			end
		end
	else
		-- Zone is occupied, display upgrade / sell actions
		if not towerModel then
			CloseCurrentMenu()
			return
		end

		local towerType = towerModel:GetAttribute("Type") or "Tower"
		local currentLevel = towerModel:GetAttribute("Level") or 1
		local nextLevel = currentLevel + 1
		
		local typeConfig = TowerConfig.Towers[towerType]
		local levelConfig = typeConfig and typeConfig.Levels[nextLevel]

		-- Title Header
		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.Size = UDim2.new(0.9, 0, 0, 22)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBold
		title.TextColor3 = Color3.fromRGB(0, 180, 255)
		title.TextSize = 12
		title.Text = (typeConfig and typeConfig.Name or towerType) .. " (Lv. " .. currentLevel .. ")"
		title.Parent = frame

		-- Upgrade Button
		if levelConfig then
			local upgCost = levelConfig.Cost
			local upgBtn = CreateMenuButton("UpgradeButton", "Upgrade (" .. upgCost .. " G)", Color3.fromRGB(40, 110, 50), frame)
			upgBtn.MouseButton1Click:Connect(function()
				UpgradeTower:FireServer(towerModel)
				TriggerLocalSound(286522724) -- hammer build sound
				CloseCurrentMenu()
			end)
		else
			local upgBtn = CreateMenuButton("UpgradeButtonMax", "MAX LEVEL REACHED", Color3.fromRGB(50, 50, 50), frame)
			upgBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
			upgBtn.Active = false
		end

		-- Sell Button
		local totalSpent = 0
		if typeConfig then
			for l = 1, currentLevel do
				local lData = typeConfig.Levels[l]
				if lData then
					totalSpent = totalSpent + lData.Cost
				end
			end
		end
		local refundVal = math.floor(totalSpent * 0.75)
		
		local sellBtn = CreateMenuButton("SellButton", "Sell (+" .. refundVal .. " G)", Color3.fromRGB(150, 40, 40), frame)
		sellBtn.MouseButton1Click:Connect(function()
			SellTower:FireServer(towerModel)
			TriggerLocalSound(9072709117) -- cash payout sound
			CloseCurrentMenu()
		end)
	end
end

-- ============================================
-- 3. MOUSE INTERACTION & CLICK DETECTOR
-- ============================================

UserInputService.InputBegan:Connect(function(input, processed)
	-- If they clicked UI elements, do not trigger close or open logic
	if processed then return end
	
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local mouse = player:GetMouse()
		local target = mouse.Target
		
		if target and CollectionService:HasTag(target, "PlacementZone") then
			-- Open menu for clicked zone
			OpenPlacementMenu(target)
		else
			-- Clicked away in the game world, close menu
			CloseCurrentMenu()
		end
	end
end)

-- ============================================
-- 4. BUILD CLASS SELECTION SCREEN (Lobby Screen)
-- ============================================

local hudConnections = {}

local function ClearHeroHUD()
	-- Destroy any existing HUD elements
	local existingFrame = screenGui:FindFirstChild("HeroHUDFrame")
	if existingFrame then existingFrame:Destroy() end
	local existingBtn = screenGui:FindFirstChild("AbilityBtn")
	if existingBtn then existingBtn:Destroy() end
	
	-- Disconnect connections
	for _, conn in ipairs(hudConnections) do
		if conn then
			conn:Disconnect()
		end
	end
	table.clear(hudConnections)
end

local function InitializeHeroHUD(className)
	local classConfig = HeroConfig.Classes[className]
	if not classConfig then return end
	
	-- Ensure we clean up any previous HUD state/connections
	ClearHeroHUD()
	
	local classColors = {
		Knight = Color3.fromRGB(180, 180, 185),
		Ranger = Color3.fromRGB(100, 200, 100),
		Mage = Color3.fromRGB(0, 180, 255),
		Necromancer = Color3.fromRGB(180, 0, 255),
		StormCaller = Color3.fromRGB(255, 220, 50),
		DragonKnight = Color3.fromRGB(255, 60, 0)
	}
	local classColor = classColors[className] or Color3.fromRGB(120, 120, 120)

	-- 1. HERO INFO FRAME (Bottom Left)
	local heroFrame = Instance.new("Frame")
	heroFrame.Name = "HeroHUDFrame"
	heroFrame.Size = UDim2.new(0, 180, 0, 50)
	heroFrame.Position = UDim2.new(0.02, 0, 1, -15)
	heroFrame.AnchorPoint = Vector2.new(0, 1)
	heroFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	heroFrame.BackgroundTransparency = 0.15
	heroFrame.Parent = screenGui

	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 8)
	frameCorner.Parent = heroFrame

	local frameStroke = Instance.new("UIStroke")
	frameStroke.Color = Color3.fromRGB(60, 60, 65)
	frameStroke.Thickness = 1.5
	frameStroke.Parent = heroFrame

	local heroName = Instance.new("TextLabel")
	heroName.Size = UDim2.new(0.9, 0, 0.4, 0)
	heroName.Position = UDim2.new(0.05, 0, 0.05, 0)
	heroName.BackgroundTransparency = 1
	heroName.Font = Enum.Font.GothamBold
	heroName.TextColor3 = classColor
	heroName.TextSize = 12
	heroName.TextXAlignment = Enum.TextXAlignment.Left
	heroName.Text = classConfig.Name
	heroName.Parent = heroFrame

	local hpBg = Instance.new("Frame")
	hpBg.Size = UDim2.new(0.9, 0, 0, 12)
	hpBg.Position = UDim2.new(0.05, 0, 0.85, 0)
	hpBg.AnchorPoint = Vector2.new(0, 1)
	hpBg.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	hpBg.BorderSizePixel = 0
	hpBg.Parent = heroFrame

	local hpFill = Instance.new("Frame")
	hpFill.Size = UDim2.new(1, 0, 1, 0)
	hpFill.BackgroundColor3 = Color3.fromRGB(230, 50, 50)
	hpFill.BorderSizePixel = 0
	hpFill.Parent = hpBg

	local hpText = Instance.new("TextLabel")
	hpText.Size = UDim2.new(1, 0, 1, 0)
	hpText.BackgroundTransparency = 1
	hpText.Font = Enum.Font.GothamBold
	hpText.TextColor3 = Color3.fromRGB(255, 255, 255)
	hpText.TextSize = 8
	hpText.Text = "HP: 100/100"
	hpText.Parent = hpBg

	-- Sync Hero Health (discharging old connections on death/respawn)
	local healthChangedConn = nil
	local function SyncHeroHP()
		if healthChangedConn then
			healthChangedConn:Disconnect()
			healthChangedConn = nil
		end
		
		local char = player.Character
		if not char then return end
		local hum = char:FindFirstChild("Humanoid")
		if not hum then return end
		
		local function update()
			local hp = math.max(0, math.floor(hum.Health))
			local maxHP = math.floor(hum.MaxHealth)
			local pct = math.clamp(hp / maxHP, 0, 1)
			TweenService:Create(hpFill, TweenInfo.new(0.2), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
			hpText.Text = "HP: " .. hp .. "/" .. maxHP
		end
		
		healthChangedConn = hum.HealthChanged:Connect(update)
		update()
	end
	
	local charAddedConn = player.CharacterAdded:Connect(function(char)
		task.wait(0.2)
		SyncHeroHP()
	end)
	table.insert(hudConnections, charAddedConn)
	
	if player.Character then
		SyncHeroHP()
	end

	-- 2. HERO ABILITY BUTTON (Bottom Right)
	local abilityBtn = Instance.new("TextButton")
	abilityBtn.Name = "AbilityBtn"
	abilityBtn.Size = UDim2.new(0, 110, 0, 50)
	abilityBtn.Position = UDim2.new(0.98, 0, 1, -15)
	abilityBtn.AnchorPoint = Vector2.new(1, 1)
	abilityBtn.BackgroundColor3 = classColor
	abilityBtn.BorderSizePixel = 0
	abilityBtn.Font = Enum.Font.GothamBold
	abilityBtn.TextColor3 = Color3.fromRGB(15, 15, 20)
	abilityBtn.TextSize = 11
	abilityBtn.Text = classConfig.Ability.Name .. "\n[E]"
	abilityBtn.Parent = screenGui

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = abilityBtn

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Color3.fromRGB(255, 255, 255)
	btnStroke.Thickness = 1.5
	btnStroke.Parent = abilityBtn

	-- Cooldown shade overlay
	local cdOverlay = Instance.new("Frame")
	cdOverlay.Name = "CooldownOverlay"
	cdOverlay.Size = UDim2.new(1, 0, 0, 0)
	cdOverlay.Position = UDim2.new(0, 0, 1, 0)
	cdOverlay.AnchorPoint = Vector2.new(0, 1)
	cdOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	cdOverlay.BackgroundTransparency = 0.5
	cdOverlay.BorderSizePixel = 0
	cdOverlay.Parent = abilityBtn

	local cdText = Instance.new("TextLabel")
	cdText.Name = "CDText"
	cdText.Size = UDim2.new(1, 0, 1, 0)
	cdText.BackgroundTransparency = 1
	cdText.Font = Enum.Font.GothamBold
	cdText.TextColor3 = Color3.fromRGB(255, 255, 255)
	cdText.TextSize = 18
	cdText.Text = ""
	cdText.Parent = abilityBtn

	local onCooldown = false
	local cooldownDuration = classConfig.Ability.Cooldown

	local function TriggerAbilityUse()
		if onCooldown then return end
		
		-- Fire to server
		UseAbility:FireServer()
		TriggerLocalSound(138084705) -- ability cast trigger sound
		
		-- Run client side visual cooldown
		onCooldown = true
		abilityBtn.Active = false
		
		-- Fill the overlay instantly
		cdOverlay.Size = UDim2.new(1, 0, 1, 0)
		
		task.spawn(function()
			local elapsed = 0
			while elapsed < cooldownDuration do
				local remaining = math.ceil(cooldownDuration - elapsed)
				cdText.Text = tostring(remaining)
				
				local pct = 1.0 - (elapsed / cooldownDuration)
				cdOverlay.Size = UDim2.new(1, 0, pct, 0)
				
				elapsed = elapsed + task.wait(0.2)
			end
			
			cdOverlay.Size = UDim2.new(1, 0, 0, 0)
			cdText.Text = ""
			onCooldown = false
			abilityBtn.Active = true
		end)
	end

	-- Connect triggers
	abilityBtn.MouseButton1Click:Connect(TriggerAbilityUse)
	
	local keyEConn = UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.E then
			TriggerAbilityUse()
		end
	end)
	table.insert(hudConnections, keyEConn)
end

function OpenClassSelectionScreen()
	local selectGui = Instance.new("ScreenGui")
	selectGui.Name = "ClassSelectionGui"
	selectGui.ResetOnSpawn = false
	selectGui.Parent = playerGui

	-- Fullscreen dark background
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	background.Parent = selectGui

	-- Decorative title
	local mainTitle = Instance.new("TextLabel")
	mainTitle.Name = "MainTitle"
	mainTitle.Size = UDim2.new(1, 0, 0, 80)
	mainTitle.Position = UDim2.new(0, 0, 0.05, 0)
	mainTitle.BackgroundTransparency = 1
	mainTitle.Font = Enum.Font.GothamBold
	mainTitle.TextColor3 = Color3.fromRGB(240, 240, 245)
	mainTitle.TextSize = 28
	mainTitle.Text = "CHOOSE YOUR HERO CLASS"
	mainTitle.Parent = background

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "SubTitle"
	subtitle.Size = UDim2.new(1, 0, 0, 30)
	subtitle.Position = UDim2.new(0, 0, 0.12, 0)
	subtitle.BackgroundTransparency = 1
	subtitle.Font = Enum.Font.GothamSemibold
	subtitle.TextColor3 = Color3.fromRGB(130, 130, 135)
	subtitle.TextSize = 14
	subtitle.Text = "Select your class to enter the siege"
	subtitle.Parent = background

	-- Scrollable class cards list (mobile friendly!)
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "ClassScroll"
	scrollFrame.Size = UDim2.new(0.9, 0, 0.65, 0)
	scrollFrame.Position = UDim2.new(0.5, 0, 0.5, 20)
	scrollFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.CanvasSize = UDim2.new(0, 1100, 0, 0)
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 105)
	scrollFrame.Parent = background

	local gridLayout = Instance.new("UIListLayout")
	gridLayout.FillDirection = Enum.FillDirection.Horizontal
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	gridLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	gridLayout.Padding = UDim.new(0, 20)
	gridLayout.Parent = scrollFrame

	local classDetails = {
		Knight = { Color = Color3.fromRGB(180, 180, 185), Icon = "🛡️" },
		Ranger = { Color = Color3.fromRGB(100, 200, 100), Icon = "🏹" },
		Mage = { Color = Color3.fromRGB(0, 180, 255), Icon = "🔮" },
		Necromancer = { Color = Color3.fromRGB(180, 0, 255), Icon = "💀" },
		StormCaller = { Color = Color3.fromRGB(255, 220, 50), Icon = "⚡" },
		DragonKnight = { Color = Color3.fromRGB(255, 60, 0), Icon = "🔥" }
	}

	-- Draw class choice cards
	for className, details in pairs(HeroConfig.Classes) do
		local spec = classDetails[className] or { Color = Color3.fromRGB(120, 120, 120), Icon = "⚔️" }

		local card = Instance.new("Frame")
		card.Name = className .. "Card"
		card.Size = UDim2.new(0, 160, 0.9, 0)
		card.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
		card.BorderSizePixel = 0
		card.Parent = scrollFrame

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 10)
		cardCorner.Parent = card

		local cardStroke = Instance.new("UIStroke")
		cardStroke.Color = Color3.fromRGB(50, 50, 55)
		cardStroke.Thickness = 1.5
		cardStroke.Parent = card

		local cardLayout = Instance.new("UIListLayout")
		cardLayout.FillDirection = Enum.FillDirection.Vertical
		cardLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		cardLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		cardLayout.Padding = UDim.new(0, 6)
		cardLayout.Parent = card

		-- Icon
		local iconLbl = Instance.new("TextLabel")
		iconLbl.Size = UDim2.new(0.9, 0, 0, 40)
		iconLbl.BackgroundTransparency = 1
		iconLbl.Font = Enum.Font.GothamBold
		iconLbl.TextSize = 30
		iconLbl.Text = spec.Icon
		iconLbl.Parent = card

		-- Name
		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size = UDim2.new(0.9, 0, 0, 20)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Font = Enum.Font.GothamBold
		nameLbl.TextColor3 = spec.Color
		nameLbl.TextSize = 14
		nameLbl.Text = details.Name
		nameLbl.Parent = card

		-- Stats
		local hpLbl = Instance.new("TextLabel")
		hpLbl.Size = UDim2.new(0.9, 0, 0, 14)
		hpLbl.BackgroundTransparency = 1
		hpLbl.Font = Enum.Font.GothamSemibold
		hpLbl.TextColor3 = Color3.fromRGB(150, 150, 155)
		hpLbl.TextSize = 10
		hpLbl.Text = "❤️ HP: " .. details.HP .. " | 👟 Speed: " .. details.Speed
		hpLbl.Parent = card

		-- Ability Name
		local abNameLbl = Instance.new("TextLabel")
		abNameLbl.Size = UDim2.new(0.9, 0, 0, 16)
		abNameLbl.BackgroundTransparency = 1
		abNameLbl.Font = Enum.Font.GothamBold
		abNameLbl.TextColor3 = Color3.fromRGB(200, 200, 205)
		abNameLbl.TextSize = 11
		abNameLbl.Text = "Ability: " .. details.Ability.Name
		abNameLbl.Parent = card

		-- Ability Desc
		local abDescLbl = Instance.new("TextLabel")
		abDescLbl.Size = UDim2.new(0.95, 0, 0.25, 0)
		abDescLbl.BackgroundTransparency = 1
		abDescLbl.Font = Enum.Font.Gotham
		abDescLbl.TextColor3 = Color3.fromRGB(130, 130, 135)
		abDescLbl.TextSize = 9
		abDescLbl.TextWrapped = true
		abDescLbl.TextYAlignment = Enum.TextYAlignment.Top
		abDescLbl.Text = details.Ability.Description
		abDescLbl.Parent = card

		-- Select / Buy Button
		local ClassPassKeys = {
			Mage = "MAGE_PASS_ID",
			Necromancer = "NECRO_PASS_ID",
			StormCaller = "STORM_PASS_ID",
			DragonKnight = "DRAGON_PASS_ID"
		}

		local selectBtn = Instance.new("TextButton")
		selectBtn.Size = UDim2.new(0.85, 0, 0, 30)
		selectBtn.BackgroundColor3 = spec.Color
		selectBtn.BorderSizePixel = 0
		selectBtn.Font = Enum.Font.GothamBold
		selectBtn.TextColor3 = Color3.fromRGB(15, 15, 20)
		selectBtn.TextSize = 11
		selectBtn.Parent = card

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 5)
		btnCorner.Parent = selectBtn

		local function UpdateButtonState()
			local isFree = details.Cost == "Free"
			local attrName = "Owns" .. className .. "Class"
			local isOwned = isFree or (player:GetAttribute(attrName) == true)

			if isOwned then
				selectBtn.Text = "SELECT"
				selectBtn.BackgroundColor3 = spec.Color
				selectBtn.TextColor3 = Color3.fromRGB(15, 15, 20)
			else
				selectBtn.Text = "BUY (" .. details.Cost .. " R$)"
				selectBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40) -- Crimson Red for Buy
				selectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			end
		end

		UpdateButtonState()

		-- Listen for attribute changes (ownership sync)
		local attrName = "Owns" .. className .. "Class"
		if details.Cost ~= "Free" then
			player:GetAttributeChangedSignal(attrName):Connect(UpdateButtonState)
		end

		selectBtn.MouseButton1Click:Connect(function()
			local isFree = details.Cost == "Free"
			local isOwned = isFree or (player:GetAttribute(attrName) == true)

			if isOwned then
				print("[UIController] Selecting class: " .. className)
				SelectClass:FireServer(className)
				TriggerLocalSound(12222247) -- click select
				
				-- Fade out background
				local tween = TweenService:Create(background, TweenInfo.new(0.5), {Position = UDim2.new(0, 0, -1, 0)})
				tween:Play()
				tween.Completed:Wait()
				selectGui:Destroy()
				
				-- Enable HUD bars
				InitializeHeroHUD(className)
			else
				local passKey = ClassPassKeys[className]
				if passKey then
					print("[UIController] Prompting purchase for pass: " .. passKey)
					PurchaseItem:FireServer("GamePass", passKey)
				end
			end
		end)
	end
end

-- Open Main Menu and Ambient Music on startup
task.spawn(OpenMainMenuScreen)
task.spawn(PlayAmbientMusic)

-- Listen for Game State updates to trigger Victory/GameOver overlays and handle lobby resets
SyncGameState.OnClientEvent:Connect(function(data)
	if data.State == "Victory" then
		ShowEndgameOverlay(true)
	elseif data.State == "GameOver" then
		ShowEndgameOverlay(false)
	elseif data.State == "Lobby" then
		-- Destroy endgame overlay if it exists
		local endgameGui = playerGui:FindFirstChild("EndgameGui")
		if endgameGui then endgameGui:Destroy() end
		
		-- Clear hero HUD and connections
		ClearHeroHUD()
		
		-- Destroy class selection GUI if it exists
		local selectGui = playerGui:FindFirstChild("ClassSelectionGui")
		if selectGui then selectGui:Destroy() end
		
		-- Re-open Main Menu Screen if not active
		local mainLobby = playerGui:FindFirstChild("MainMenuGui")
		if not mainLobby then
			OpenMainMenuScreen()
		end
	end
end)

print("[UIController] Context HUD and interaction systems initialized.")
