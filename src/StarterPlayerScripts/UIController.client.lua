-- ============================================
-- UIController.client.lua — Kingdom Siege
-- Highly responsive, symmetric, mobile-optimized dark fantasy UI.
-- Side: Client
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

-- Configuration modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Config = Modules:WaitForChild("Config")
local TowerConfig = require(Config:WaitForChild("TowerConfig"))
local EconomyConfig = require(Config:WaitForChild("EconomyConfig"))
local HeroConfig = require(Config:WaitForChild("HeroConfig"))
local UIStyleConfig = require(Config:WaitForChild("UIStyleConfig"))

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

-- UI state
local selectedTowerToPlace = nil
local selectedBaseZone = nil
local currentGameState = "Lobby"
local assignedPath = nil
local currentCrystalHP = EconomyConfig.CRYSTAL_MAX_HP
local crystalHpFill = nil
local crystalHpText = nil

-- References to active instances
local screenGui = nil
local activeConsole = nil
local activeHighlight = nil
local activeBeam = nil
local activeAttachments = {}
local activeAmbientMusic = nil

-- Responsive checks
local isMobile = UserInputService.TouchEnabled

-- Helper: Clean visual effects
local function ClearGuideBeam()
	if activeBeam then activeBeam:Destroy(); activeBeam = nil end
	for _, attach in ipairs(activeAttachments) do
		if attach then attach:Destroy() end
	end
	table.clear(activeAttachments)
end

local function ClearHighlight()
	if activeHighlight then activeHighlight:Destroy(); activeHighlight = nil end
end

-- ============================================
-- AUDIO & CUES
-- ============================================
local function TriggerLocalSound(soundId, volume)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. tostring(soundId)
	sound.Volume = volume or 0.4
	sound.Parent = playerGui
	sound:Play()
	sound.Ended:Connect(function() sound:Destroy() end)
	return sound
end

local function PlayAmbientMusic()
	if activeAmbientMusic then
		activeAmbientMusic:Stop(); activeAmbientMusic:Destroy()
	end
	activeAmbientMusic = TriggerLocalSound(6990273398, 0.15)
	activeAmbientMusic.Looped = true
end

-- ============================================
-- UI STYLING & DECORATORS
-- ============================================
local function AddGothicOrnaments(frame)
	local corners = {
		TL = { Position = UDim2.new(0, 0, 0, 0), AnchorPoint = Vector2.new(0, 0), Rotation = 0 },
		TR = { Position = UDim2.new(1, 0, 0, 0), AnchorPoint = Vector2.new(1, 0), Rotation = 90 },
		BL = { Position = UDim2.new(0, 0, 1, 0), AnchorPoint = Vector2.new(0, 1), Rotation = 270 },
		BR = { Position = UDim2.new(1, 0, 1, 0), AnchorPoint = Vector2.new(1, 1), Rotation = 180 },
	}
	
	for name, data in pairs(corners) do
		local f = Instance.new("ImageLabel")
		f.Name = "Ornament_" .. name
		f.Size = UDim2.new(0, 20, 0, 20)
		f.Position = data.Position
		f.AnchorPoint = data.AnchorPoint
		f.Rotation = data.Rotation
		f.BackgroundTransparency = 1
		f.Image = "rbxassetid://3084795328"
		f.ImageColor3 = UIStyleConfig.Colors.BorderGold
		f.ZIndex = 2 -- Draw on top of borders
		f.Parent = frame
	end
end

local function StylePanelFrame(frame, hasGoldBorder)
	frame.BackgroundTransparency = 1
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.5
	stroke.Transparency = 0.3
	stroke.Color = hasGoldBorder and UIStyleConfig.Colors.BorderGold or UIStyleConfig.Colors.BorderBronze
	stroke.Parent = frame

	local strokeGrad = Instance.new("UIGradient")
	strokeGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, UIStyleConfig.Colors.BorderGold),
		ColorSequenceKeypoint.new(0.5, UIStyleConfig.Colors.BorderBronze),
		ColorSequenceKeypoint.new(1, UIStyleConfig.Colors.BorderGold),
	})
	strokeGrad.Rotation = 45
	strokeGrad.Parent = stroke

	-- 1. Solid Color backing
	local bgSolid = Instance.new("Frame")
	bgSolid.Name = "BgSolid"
	bgSolid.Size = UDim2.new(1, 0, 1, 0)
	bgSolid.BorderSizePixel = 0
	bgSolid.ZIndex = 0
	bgSolid.Parent = frame
	
	local bgSolidCorner = Instance.new("UICorner")
	bgSolidCorner.CornerRadius = UDim.new(0, 10)
	bgSolidCorner.Parent = bgSolid
	
	local panelGrad = Instance.new("UIGradient")
	panelGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, UIStyleConfig.Colors.PanelBg),
		ColorSequenceKeypoint.new(1, UIStyleConfig.Colors.PanelBgDark),
	})
	panelGrad.Rotation = 90
	panelGrad.Parent = bgSolid

	-- 2. Textured Vignette layer
	local bgTexture = Instance.new("ImageLabel")
	bgTexture.Name = "BgTexture"
	bgTexture.Size = UDim2.new(1, 0, 1, 0)
	bgTexture.BackgroundTransparency = 1
	bgTexture.Image = "rbxassetid://256336585" -- Subtle stone vignette
	bgTexture.ImageColor3 = Color3.fromRGB(0, 0, 0)
	bgTexture.ImageTransparency = 0.65
	bgTexture.ZIndex = 0
	bgTexture.Parent = frame
	
	local bgTextureCorner = Instance.new("UICorner")
	bgTextureCorner.CornerRadius = UDim.new(0, 10)
	bgTextureCorner.Parent = bgTexture
end

local function ApplyHoverTransitions(btn)
	local stroke = btn:FindFirstChildOfClass("UIStroke")
	local originalSize = btn.Size
	
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(originalSize.X.Scale * 1.03, originalSize.X.Offset * 1.03, originalSize.Y.Scale * 1.03, originalSize.Y.Offset * 1.03)
		}):Play()
		if stroke then
			TweenService:Create(stroke, TweenInfo.new(0.15), {Transparency = 0}):Play()
		end
	end)

	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = originalSize
		}):Play()
		if stroke then
			TweenService:Create(stroke, TweenInfo.new(0.15), {Transparency = 0.3}):Play()
		end
	end)

	if btn:IsA("GuiButton") then
		btn.MouseButton1Down:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.08), {
				Size = UDim2.new(originalSize.X.Scale * 0.96, originalSize.X.Offset * 0.96, originalSize.Y.Scale * 0.96, originalSize.Y.Offset * 0.96)
			}):Play()
		end)
		btn.MouseButton1Up:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.08), {
				Size = originalSize
			}):Play()
		end)
	end
end

-- ============================================
-- TRANSLATORS & VISUAL HIGH-FIDELITY
-- ============================================
local function GetCleanBaseName(zoneName)
	if string.find(zoneName, "Interior") then
		local num = string.match(zoneName, "Interior_(%d+)") or "1"
		return "Keep Spot " .. num
	else
		local path = ""
		if string.find(zoneName, "ForestPath") then
			path = "Forest"
		elseif string.find(zoneName, "UndeadPath") then
			path = "Graveyard"
		elseif string.find(zoneName, "DragonPass") then
			path = "Dragon Pass"
		end
		
		local segment = string.match(zoneName, "Path_(%d+)") or "1"
		local side = string.find(zoneName, "_L_") and "Left" or "Right"
		
		return path .. " S" .. segment .. " (" .. side .. ")"
	end
end

local function GetPlayerBases()
	local bases = {}
	local mapModel = workspace:FindFirstChild("Map")
	local placementFolder = mapModel and mapModel:FindFirstChild("PlacementZones")
	
	if placementFolder then
		for _, zone in ipairs(placementFolder:GetChildren()) do
			if CollectionService:HasTag(zone, "PlacementZone") then
				local name = zone.Name
				local isInterior = string.find(name, "Interior") ~= nil
				local isAssignedPath = assignedPath and string.find(name, assignedPath) ~= nil
				
				if isInterior or isAssignedPath then
					table.insert(bases, zone)
				end
			end
		end
	end
	
	table.sort(bases, function(a, b) return a.Name < b.Name end)
	return bases
end

local function HighlightZone(zonePart)
	ClearHighlight()
	if not zonePart then return end
	
	local highlight = Instance.new("Highlight")
	highlight.Name = "LocalZoneHighlight"
	highlight.Adornee = zonePart
	highlight.FillColor = UIStyleConfig.Colors.SelectionGlow
	highlight.FillTransparency = 0.4
	highlight.OutlineColor = UIStyleConfig.Colors.BorderGold
	highlight.OutlineTransparency = 0.1
	highlight.Parent = zonePart
	
	activeHighlight = highlight
end

local function DrawGuideBeam(pathName)
	ClearGuideBeam()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	local targetPart = nil
	local mapModel = workspace:FindFirstChild("Map")
	if mapModel then
		local spawnPoints = mapModel:FindFirstChild("EnemySpawns") or mapModel:FindFirstChild("SpawnPoints")
		if spawnPoints then targetPart = spawnPoints:FindFirstChild(pathName) end
		
		if not targetPart and mapModel:FindFirstChild("Paths") then
			local pathFolder = mapModel.Paths:FindFirstChild(pathName)
			local waypoints = pathFolder and pathFolder:FindFirstChild("Waypoints")
			targetPart = waypoints and waypoints:FindFirstChild("Waypoint_1")
		end
	end
	
	if not targetPart then return end
	
	local attach0 = Instance.new("Attachment"); attach0.Parent = root
	local attach1 = Instance.new("Attachment"); attach1.Parent = targetPart
	
	local beam = Instance.new("Beam")
	beam.Attachment0 = attach0
	beam.Attachment1 = attach1
	beam.Color = ColorSequence.new(UIStyleConfig.Colors.BorderGold)
	beam.Width0 = 0.8; beam.Width1 = 0.8
	beam.FaceCamera = true
	beam.Texture = "rbxassetid://403930419"
	beam.TextureSpeed = 2.5
	beam.LightEmission = 0.8
	beam.Parent = root
	
	activeBeam = beam
	table.insert(activeAttachments, attach0)
	table.insert(activeAttachments, attach1)
	
	task.delay(5, function()
		if beam == activeBeam then ClearGuideBeam() end
	end)
end

local function ShowPathAssignmentBanner(pathName)
	local old = playerGui:FindFirstChild("PathBannerGui")
	if old then old:Destroy() end
	
	local pathTheme = UIStyleConfig.PathThemes[pathName]
	if not pathTheme then return end
	
	local bannerGui = Instance.new("ScreenGui")
	bannerGui.Name = "PathBannerGui"
	bannerGui.ResetOnSpawn = false
	bannerGui.DisplayOrder = 18
	bannerGui.Parent = playerGui
	
	local banner = Instance.new("Frame")
	banner.Name = "Banner"
	banner.Size = UDim2.new(1, 0, 0, 75)
	banner.Position = UDim2.new(0, 0, 0.2, 0)
	banner.BackgroundColor3 = UIStyleConfig.Colors.PanelBg
	banner.BorderSizePixel = 0
	banner.Parent = bannerGui
	
	local panelGrad = Instance.new("UIGradient")
	panelGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, UIStyleConfig.Colors.PanelBgDark),
		ColorSequenceKeypoint.new(0.5, UIStyleConfig.Colors.PanelBg),
		ColorSequenceKeypoint.new(1, UIStyleConfig.Colors.PanelBgDark)
	})
	panelGrad.Parent = banner

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.Font = UIStyleConfig.Fonts.Title
	text.TextColor3 = pathTheme.Color
	text.TextScaled = true
	text.Text = "🛡️ DEFENSE ASSIGNED: " .. pathTheme.Label:upper() .. " 🛡️"
	text.Parent = text.Parent or banner
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Thickness = 2.5
	stroke.Parent = text
	
	local textConstraint = Instance.new("UITextSizeConstraint")
	textConstraint.MaxTextSize = 22
	textConstraint.MinTextSize = 12
	textConstraint.Parent = text

	TriggerLocalSound(UIStyleConfig.Sounds.Click)
	
	TweenService:Create(banner, TweenInfo.new(0.4), {BackgroundTransparency = 0.2}):Play()
	
	task.delay(4, function()
		if bannerGui.Parent then
			TweenService:Create(banner, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
			TweenService:Create(text, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
			task.wait(0.4)
			bannerGui:Destroy()
		end
	end)
end

-- ============================================
local function OpenMainMenuScreen()
	local old = playerGui:FindFirstChild("MainMenuGui")
	if old then old:Destroy() end

	local lobbyGui = Instance.new("ScreenGui")
	lobbyGui.Name = "MainMenuGui"
	lobbyGui.ResetOnSpawn = false
	lobbyGui.Parent = playerGui
	
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = UIStyleConfig.Colors.PanelBgDark
	background.Parent = lobbyGui
	
	-- Center Board (Perfect Symmetry!)
	local mainBoard = Instance.new("Frame")
	mainBoard.Size = UDim2.new(0.9, 0, 0.85, 0)
	mainBoard.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainBoard.AnchorPoint = Vector2.new(0.5, 0.5)
	mainBoard.BackgroundColor3 = UIStyleConfig.Colors.PanelBg
	mainBoard.Parent = background
	
	local mainConstraint = Instance.new("UISizeConstraint")
	mainConstraint.MaxSize = Vector2.new(460, 400)
	mainConstraint.MinSize = Vector2.new(300, 340)
	mainConstraint.Parent = mainBoard
	
	StylePanelFrame(mainBoard, true)
	AddGothicOrnaments(mainBoard)
	
	-- Content wrapper for layout isolation (prevents background layers from pushing main menu contents!)
	local mainContent = Instance.new("Frame")
	mainContent.Name = "MainContent"
	mainContent.Size = UDim2.new(1, 0, 1, 0)
	mainContent.BackgroundTransparency = 1
	mainContent.ZIndex = 2
	mainContent.Parent = mainBoard

	-- Vertical list layout for the main board contents
	local boardLayout = Instance.new("UIListLayout")
	boardLayout.FillDirection = Enum.FillDirection.Vertical
	boardLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	boardLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	boardLayout.Padding = UDim.new(0, 12)
	boardLayout.Parent = mainContent
	
	-- Swords Emblem backdrop for Title (Faint background details!)
	local emblem = Instance.new("ImageLabel")
	emblem.Name = "TitleEmblem"
	emblem.Size = UDim2.new(0, 120, 0, 120)
	emblem.Position = UDim2.new(0.5, 0, 0.2, 0)
	emblem.AnchorPoint = Vector2.new(0.5, 0.5)
	emblem.BackgroundTransparency = 1
	emblem.Image = "rbxassetid://568600104"
	emblem.ImageColor3 = UIStyleConfig.Colors.BorderBronze
	emblem.ImageTransparency = 0.84
	emblem.ZIndex = 0
	emblem.Parent = mainBoard
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.9, 0, 0, 50)
	title.BackgroundTransparency = 1
	title.Font = UIStyleConfig.Fonts.Title
	title.TextColor3 = UIStyleConfig.Colors.RedDanger
	title.TextScaled = true
	title.Text = "KINGDOM SIEGE"
	title.ZIndex = 2
	title.Parent = mainContent

	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = UIStyleConfig.Colors.BorderGold
	titleStroke.Thickness = 2
	titleStroke.Parent = title
	
	local titleConstraint = Instance.new("UITextSizeConstraint")
	titleConstraint.MaxTextSize = 32
	titleConstraint.MinTextSize = 16
	titleConstraint.Parent = title
	
	-- Profile Banner Plaque (Textured and stylized)
	local profileBanner = Instance.new("Frame")
	profileBanner.Name = "ProfileBanner"
	profileBanner.Size = UDim2.new(0.85, 0, 0, 80)
	profileBanner.BackgroundColor3 = UIStyleConfig.Colors.PanelBgDark
	profileBanner.ZIndex = 2
	profileBanner.Parent = mainContent
	
	StylePanelFrame(profileBanner, false)
	
	-- Content wrapper for layout isolation
	local profileContent = Instance.new("Frame")
	profileContent.Size = UDim2.new(1, 0, 1, 0)
	profileContent.BackgroundTransparency = 1
	profileContent.ZIndex = 2
	profileContent.Parent = profileBanner
	
	local avatar = Instance.new("ImageLabel")
	avatar.Size = UDim2.new(0, 48, 0, 48)
	avatar.Position = UDim2.new(0.06, 0, 0.5, 0)
	avatar.AnchorPoint = Vector2.new(0, 0.5)
	avatar.BackgroundColor3 = UIStyleConfig.Colors.PanelBg
	avatar.BorderSizePixel = 0
	avatar.Parent = profileContent
	
	local avCorner = Instance.new("UICorner")
	avCorner.CornerRadius = UDim.new(1, 0)
	avCorner.Parent = avatar
	
	task.spawn(function()
		local success, contentImg = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		end)
		if success then avatar.Image = contentImg end
	end)
	
	-- Text block inside banner
	local textContainer = Instance.new("Frame")
	textContainer.Size = UDim2.new(0.7, 0, 0.8, 0)
	textContainer.Position = UDim2.new(0.24, 0, 0.5, 0)
	textContainer.AnchorPoint = Vector2.new(0, 0.5)
	textContainer.BackgroundTransparency = 1
	textContainer.Parent = profileContent
	
	local textLayout = Instance.new("UIListLayout")
	textLayout.FillDirection = Enum.FillDirection.Vertical
	textLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	textLayout.Padding = UDim.new(0, 2)
	textLayout.Parent = textContainer
	
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 16)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = UIStyleConfig.Fonts.Title
	nameLabel.TextColor3 = UIStyleConfig.Colors.GoldAccent
	nameLabel.TextSize = 11
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text = player.DisplayName:upper()
	nameLabel.Parent = textContainer
	
	local lvlLbl = Instance.new("TextLabel")
	lvlLbl.Size = UDim2.new(1, 0, 0, 14)
	lvlLbl.BackgroundTransparency = 1
	lvlLbl.Font = UIStyleConfig.Fonts.BodyBold
	lvlLbl.TextColor3 = UIStyleConfig.Colors.TextParchment
	lvlLbl.TextSize = 10
	lvlLbl.TextXAlignment = Enum.TextXAlignment.Left
	lvlLbl.Text = "Level: -"
	lvlLbl.Parent = textContainer
	
	local winsLbl = Instance.new("TextLabel")
	winsLbl.Size = UDim2.new(1, 0, 0, 14)
	winsLbl.BackgroundTransparency = 1
	winsLbl.Font = UIStyleConfig.Fonts.BodyRegular
	winsLbl.TextColor3 = UIStyleConfig.Colors.TextSilver
	winsLbl.TextSize = 9
	winsLbl.TextXAlignment = Enum.TextXAlignment.Left
	winsLbl.Text = "Wins: -  |  Gems: -"
	winsLbl.Parent = textContainer
	
	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(0.85, 0, 0, 32)
	subtitle.BackgroundTransparency = 1
	subtitle.Font = UIStyleConfig.Fonts.BodyRegular
	subtitle.TextColor3 = UIStyleConfig.Colors.TextSilver
	subtitle.TextSize = 10
	subtitle.TextWrapped = true
	subtitle.Text = "Defend the Kingdom Crystal from waves of monsters."
	subtitle.ZIndex = 2
	subtitle.Parent = mainContent
	
	local playBtn = Instance.new("TextButton")
	playBtn.Size = UDim2.new(0, 200, 0, 54) -- spacious touch target!
	playBtn.BackgroundColor3 = UIStyleConfig.Colors.GreenSuccess
	playBtn.BorderSizePixel = 0
	playBtn.Font = UIStyleConfig.Fonts.Title
	playBtn.TextColor3 = UIStyleConfig.Colors.TextParchment
	playBtn.TextSize = 14
	playBtn.Text = "PLAY ⚔️"
	playBtn.ZIndex = 2
	playBtn.Parent = mainContent
	
	StylePanelFrame(playBtn, true)
	ApplyHoverTransitions(playBtn)
	
	local function sync()
		local lvl = player:GetAttribute("Level") or 1
		local wins = player:GetAttribute("TotalWins") or 0
		local gems = player:GetAttribute("Gems") or 0
		
		lvlLbl.Text = "⭐ LEVEL " .. lvl
		winsLbl.Text = "WINS: " .. wins .. "   💎 GEMS: " .. gems
	end
	
	player:GetAttributeChangedSignal("Level"):Connect(sync)
	player:GetAttributeChangedSignal("TotalWins"):Connect(sync)
	player:GetAttributeChangedSignal("Gems"):Connect(sync)
	sync()
	
	playBtn.MouseButton1Click:Connect(function()
		playBtn.Active = false
		TriggerLocalSound(UIStyleConfig.Sounds.Click)
		
		local tween = TweenService:Create(background, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(0, 0, -1, 0)})
		tween:Play()
		tween.Completed:Wait()
		lobbyGui:Destroy()
		
		OpenClassSelectionScreen()
	end)
end

-- ============================================
-- CLASS SELECTION OVERLAY REDESIGN
-- ============================================
function OpenClassSelectionScreen()
	local old = playerGui:FindFirstChild("ClassSelectionGui")
	if old then old:Destroy() end

	local selectGui = Instance.new("ScreenGui")
	selectGui.Name = "ClassSelectionGui"
	selectGui.ResetOnSpawn = false
	selectGui.Parent = playerGui

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = UIStyleConfig.Colors.PanelBgDark
	background.Parent = selectGui

	local selectBoard = Instance.new("Frame")
	selectBoard.Name = "SelectBoard"
	selectBoard.Size = UDim2.new(0.92, 0, 0.82, 0)
	selectBoard.Position = UDim2.new(0.5, 0, 0.5, 0)
	selectBoard.AnchorPoint = Vector2.new(0.5, 0.5)
	selectBoard.BackgroundColor3 = UIStyleConfig.Colors.PanelBg
	selectBoard.Parent = background
	
	local selectConstraint = Instance.new("UISizeConstraint")
	selectConstraint.MaxSize = Vector2.new(900, 440)
	selectConstraint.MinSize = Vector2.new(320, 360)
	selectConstraint.Parent = selectBoard
	
	StylePanelFrame(selectBoard, true)
	AddGothicOrnaments(selectBoard)

	local mainTitle = Instance.new("TextLabel")
	mainTitle.Size = UDim2.new(0.9, 0, 0, 40)
	mainTitle.Position = UDim2.new(0.5, 0, 0.04, 0)
	mainTitle.AnchorPoint = Vector2.new(0.5, 0)
	mainTitle.BackgroundTransparency = 1
	mainTitle.Font = UIStyleConfig.Fonts.Title
	mainTitle.TextColor3 = UIStyleConfig.Colors.TextParchment
	mainTitle.TextSize = 16
	mainTitle.Text = "CHOOSE YOUR HERO CLASS"
	mainTitle.Parent = selectBoard

	-- Pinned static height scroll view (prevents card distortion!)
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "ClassScroll"
	scrollFrame.Size = UDim2.new(0.96, 0, 0, 275)
	scrollFrame.Position = UDim2.new(0.5, 0, 0.58, 0)
	scrollFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.CanvasSize = UDim2.new(0, 1120, 0, 0)
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.ScrollBarImageColor3 = UIStyleConfig.Colors.BorderGold
	scrollFrame.Parent = selectBoard
	
	local scrollPadding = Instance.new("UIPadding")
	scrollPadding.PaddingLeft = UDim.new(0, 14)
	scrollPadding.PaddingRight = UDim.new(0, 14)
	scrollPadding.Parent = scrollFrame

	local gridLayout = Instance.new("UIListLayout")
	gridLayout.FillDirection = Enum.FillDirection.Horizontal
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	gridLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	gridLayout.Padding = UDim.new(0, 14)
	gridLayout.Parent = scrollFrame

	for className, details in pairs(HeroConfig.Classes) do
		local spec = UIStyleConfig.ClassThemes[className] or { Color = Color3.fromRGB(120, 120, 120), Icon = "⚔️" }

		local card = Instance.new("Frame")
		card.Name = className .. "Card"
		card.Size = UDim2.new(0, 160, 0, 250)
		card.BackgroundColor3 = UIStyleConfig.Colors.PanelBg
		card.Parent = scrollFrame

		StylePanelFrame(card, false)
		local cardStroke = card:FindFirstChildOfClass("UIStroke")
		if cardStroke then cardStroke.Color = spec.Color end

		-- CONTENT CONTAINER (isolates children from background decoration layers!)
		local content = Instance.new("Frame")
		content.Name = "Content"
		content.Size = UDim2.new(1, 0, 1, 0)
		content.BackgroundTransparency = 1
		content.ZIndex = 2
		content.Parent = card

		local cardLayout = Instance.new("UIListLayout")
		cardLayout.FillDirection = Enum.FillDirection.Vertical
		cardLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		cardLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		cardLayout.Padding = UDim.new(0, 5)
		cardLayout.Parent = content

		local iconLbl = Instance.new("TextLabel")
		iconLbl.Size = UDim2.new(0.9, 0, 0, 36)
		iconLbl.BackgroundTransparency = 1
		iconLbl.Font = UIStyleConfig.Fonts.Title
		iconLbl.TextSize = 24
		iconLbl.Text = spec.Icon
		iconLbl.Parent = content

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size = UDim2.new(0.9, 0, 0, 20)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Font = UIStyleConfig.Fonts.Title
		nameLbl.TextColor3 = spec.Color
		nameLbl.TextSize = 12
		nameLbl.Text = details.Name
		nameLbl.Parent = content

		local hpLbl = Instance.new("TextLabel")
		hpLbl.Size = UDim2.new(0.9, 0, 0, 14)
		hpLbl.BackgroundTransparency = 1
		hpLbl.Font = UIStyleConfig.Fonts.BodyBold
		hpLbl.TextColor3 = UIStyleConfig.Colors.TextSilver
		hpLbl.TextSize = 9
		hpLbl.Text = "❤️ HP: " .. details.HP .. "  👟 SPD: " .. details.Speed
		hpLbl.Parent = content

		local abNameLbl = Instance.new("TextLabel")
		abNameLbl.Size = UDim2.new(0.9, 0, 0, 14)
		abNameLbl.BackgroundTransparency = 1
		abNameLbl.Font = UIStyleConfig.Fonts.BodyBold
		abNameLbl.TextColor3 = UIStyleConfig.Colors.TextParchment
		abNameLbl.TextSize = 10
		abNameLbl.Text = details.Ability.Name
		abNameLbl.Parent = content

		local abDescLbl = Instance.new("TextLabel")
		abDescLbl.Size = UDim2.new(0.94, 0, 0, 68)
		abDescLbl.BackgroundTransparency = 1
		abDescLbl.Font = UIStyleConfig.Fonts.BodyRegular
		abDescLbl.TextColor3 = UIStyleConfig.Colors.TextSilver
		abDescLbl.TextSize = 8
		abDescLbl.TextWrapped = true
		abDescLbl.TextYAlignment = Enum.TextYAlignment.Top
		abDescLbl.Text = details.Ability.Description
		abDescLbl.Parent = content

		local selectBtn = Instance.new("TextButton")
		selectBtn.Size = UDim2.new(0.85, 0, 0, 38)
		selectBtn.BorderSizePixel = 0
		selectBtn.Font = UIStyleConfig.Fonts.Title
		selectBtn.TextSize = 12
		selectBtn.Parent = content

		StylePanelFrame(selectBtn, true)

		local function UpdateButtonState()
			local isFree = details.Cost == "Free"
			local attrName = "Owns" .. className .. "Class"
			local isOwned = isFree or (player:GetAttribute(attrName) == true)

			if isOwned then
				selectBtn.Text = "SELECT"
				selectBtn.BackgroundColor3 = spec.Color
				selectBtn.TextColor3 = UIStyleConfig.Colors.PanelBgDark
			else
				selectBtn.Text = "BUY (" .. details.Cost .. " R$)"
				selectBtn.BackgroundColor3 = UIStyleConfig.Colors.RedDanger
				selectBtn.TextColor3 = UIStyleConfig.Colors.TextParchment
			end
		end

		UpdateButtonState()

		local attrName = "Owns" .. className .. "Class"
		if details.Cost ~= "Free" then
			player:GetAttributeChangedSignal(attrName):Connect(UpdateButtonState)
		end

		ApplyHoverTransitions(card)
		ApplyHoverTransitions(selectBtn)

		selectBtn.MouseButton1Click:Connect(function()
			local isFree = details.Cost == "Free"
			local isOwned = isFree or (player:GetAttribute(attrName) == true)

			if isOwned then
				print("[UIController] Selecting class: " .. className)
				SelectClass:FireServer(className)
				TriggerLocalSound(UIStyleConfig.Sounds.Click)
				
				local tween = TweenService:Create(background, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(0, 0, -1, 0)})
				tween:Play()
				tween.Completed:Wait()
				selectGui:Destroy()
				
				InitializeHeroHUD(className)
			else
				local ClassPassKeys = {
					Mage = "MAGE_PASS_ID",
					Necromancer = "NECRO_PASS_ID",
					StormCaller = "STORM_PASS_ID",
					DragonKnight = "DRAGON_PASS_ID"
				}
				local passKey = ClassPassKeys[className]
				if passKey then
					TriggerLocalSound(UIStyleConfig.Sounds.Click)
					PurchaseItem:FireServer("GamePass", passKey)
				end
			end
		end)
	end
end

-- ============================================
-- UNIFIED SYMMETRICAL ACTION HUD
-- ============================================
local function CreateHUDSegment(name, layoutOrder, parent)
	local seg = Instance.new("Frame")
	seg.Name = name
	seg.Size = UDim2.new(1/3, 0, 0, isMobile and 62 or 54)
	seg.BackgroundTransparency = 1
	seg.BorderSizePixel = 0
	seg.LayoutOrder = layoutOrder
	seg.Parent = parent
	return seg
end

local hudConnections = {}
local function ClearHeroHUD()
	for _, conn in ipairs(hudConnections) do
		if conn and conn.Connected then
			conn:Disconnect()
		end
	end
	table.clear(hudConnections)
	
	crystalHpFill = nil
	crystalHpText = nil
	currentCrystalHP = EconomyConfig.CRYSTAL_MAX_HP
	
	if screenGui then
		screenGui:Destroy()
		screenGui = nil
	end
	if activeConsole then
		activeConsole:Destroy()
		activeConsole = nil
	end
end

local function ShowEndgameOverlay(isVictory)
	local old = playerGui:FindFirstChild("EndgameGui")
	if old then old:Destroy() end
	
	local endgameGui = Instance.new("ScreenGui")
	endgameGui.Name = "EndgameGui"
	endgameGui.ResetOnSpawn = false
	endgameGui.DisplayOrder = 20
	endgameGui.Parent = playerGui
	
	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	bg.BackgroundTransparency = 1
	bg.BorderSizePixel = 0
	bg.Parent = endgameGui
	
	local card = Instance.new("Frame")
	card.Size = UDim2.new(0.85, 0, 0, 200)
	card.Position = UDim2.new(0.5, 0, 0.5, 0)
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.BackgroundColor3 = UIStyleConfig.Colors.PanelBg
	card.Parent = bg
	
	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MaxSize = Vector2.new(450, 200)
	sizeConstraint.MinSize = Vector2.new(280, 150)
	sizeConstraint.Parent = card
	
	StylePanelFrame(card, true)
	
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 12)
	layout.Parent = card
	
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.9, 0, 0, 48)
	title.BackgroundTransparency = 1
	title.Font = UIStyleConfig.Fonts.Title
	title.TextColor3 = isVictory and UIStyleConfig.Colors.GreenSuccess or UIStyleConfig.Colors.RedDanger
	title.TextScaled = true
	title.Text = isVictory and "VICTORY" or "DEFEAT"
	title.Parent = card
	
	local titleConstraint = Instance.new("UITextSizeConstraint")
	titleConstraint.MaxTextSize = 36
	titleConstraint.MinTextSize = 18
	titleConstraint.Parent = title
	
	local subText = Instance.new("TextLabel")
	subText.Size = UDim2.new(0.9, 0, 0, 24)
	subText.BackgroundTransparency = 1
	subText.Font = UIStyleConfig.Fonts.BodyBold
	subText.TextColor3 = UIStyleConfig.Colors.TextSilver
	subText.TextSize = 12
	subText.Text = isVictory and "The crystal has been defended!" or "The crystal was shattered..."
	subText.Parent = card
	
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 140, 0, 36)
	closeBtn.BackgroundColor3 = UIStyleConfig.Colors.PanelBgDark
	closeBtn.BorderSizePixel = 0
	closeBtn.Font = UIStyleConfig.Fonts.Title
	closeBtn.TextColor3 = UIStyleConfig.Colors.TextParchment
	closeBtn.TextSize = 11
	closeBtn.Text = "RETURN TO LOBBY"
	closeBtn.Parent = card
	
	StylePanelFrame(closeBtn, false)
	ApplyHoverTransitions(closeBtn)
	
	closeBtn.MouseButton1Click:Connect(function()
		TriggerLocalSound(UIStyleConfig.Sounds.Click)
		endgameGui:Destroy()
	end)
	
	task.spawn(function()
		task.wait(0.1)
		TriggerLocalSound(isVictory and UIStyleConfig.Sounds.Victory or UIStyleConfig.Sounds.Defeat, 0.5)
	end)
	
	TweenService:Create(bg, TweenInfo.new(0.5), {BackgroundTransparency = 0.55}):Play()
end

local function OpenShopScreen()
	local old = playerGui:FindFirstChild("ShopGui")
	if old then old:Destroy() end

	local shopGui = Instance.new("ScreenGui")
	shopGui.Name = "ShopGui"
	shopGui.ResetOnSpawn = false
	shopGui.Parent = playerGui

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	background.BackgroundTransparency = 0.55
	background.Parent = shopGui

	local board = Instance.new("Frame")
	board.Name = "ShopBoard"
	board.Size = UDim2.new(0.9, 0, 0.8, 0)
	board.Position = UDim2.new(0.5, 0, 0.5, 0)
	board.AnchorPoint = Vector2.new(0.5, 0.5)
	board.BackgroundColor3 = UIStyleConfig.Colors.PanelBg
	board.Parent = background

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MaxSize = Vector2.new(500, 360)
	sizeConstraint.MinSize = Vector2.new(300, 240)
	sizeConstraint.Parent = board

	StylePanelFrame(board, true)
	AddGothicOrnaments(board)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.8, 0, 0, 40)
	title.Position = UDim2.new(0.5, 0, 0.04, 0)
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.BackgroundTransparency = 1
	title.Font = UIStyleConfig.Fonts.Title
	title.TextColor3 = UIStyleConfig.Colors.SelectionGlow
	title.TextSize = 15
	title.Text = "💎 TREASURY & UPGRADE SHOP 💎"
	title.Parent = board

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 36, 0, 36)
	closeBtn.Position = UDim2.new(0.95, -36, 0.04, 0)
	closeBtn.BackgroundColor3 = UIStyleConfig.Colors.RedDanger
	closeBtn.BorderSizePixel = 0
	closeBtn.Font = UIStyleConfig.Fonts.Title
	closeBtn.TextColor3 = UIStyleConfig.Colors.TextParchment
	closeBtn.TextSize = 14
	closeBtn.Text = "X"
	closeBtn.Parent = board

	StylePanelFrame(closeBtn, false)
	closeBtn.MouseButton1Click:Connect(function()
		TriggerLocalSound(UIStyleConfig.Sounds.Click)
		shopGui:Destroy()
	end)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(0.9, 0, 0.72, 0)
	scroll.Position = UDim2.new(0.5, 0, 0.58, 0)
	scroll.AnchorPoint = Vector2.new(0.5, 0.5)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.CanvasSize = UDim2.new(0, 0, 0, 380)
	scroll.ScrollBarThickness = 5
	scroll.ScrollBarImageColor3 = UIStyleConfig.Colors.BorderGold
	scroll.Parent = board

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroll

	local items = {
		{ Key = "GEMS_500_ID", Name = "500 Gems", Desc = "Pocketful of gems for session purchases.", Cost = "Robux Mocked", Type = "Product" },
		{ Key = "GEMS_1500_ID", Name = "1500 Gems", Desc = "Chest of gems. Gain massive upgrades.", Cost = "Robux Mocked", Type = "Product" },
		{ Key = "GEMS_5000_ID", Name = "5000 Gems", Desc = "Royal vault of gems. Max out defenses.", Cost = "Robux Mocked", Type = "Product" },
		{ Key = "TOWER_SLOT_ID", Name = "Extra Tower Slot", Desc = "Permanently expand tower slots by +1.", Cost = "Robux Mocked", Type = "Product" },
		{ Key = "VIP_PASS_ID", Name = "VIP Gold Badge", Desc = "Gold crown tag, bonus daily gold multiplier.", Cost = "Pass Mocked", Type = "GamePass" },
		{ Key = "XP_PASS_ID", Name = "Double XP Boost", Desc = "Double leveling speed rewards on all maps.", Cost = "Pass Mocked", Type = "GamePass" },
	}

	for i, item in ipairs(items) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(0.98, 0, 0, 48)
		row.BackgroundColor3 = UIStyleConfig.Colors.PanelBgDark
		row.LayoutOrder = i
		row.Parent = scroll

		StylePanelFrame(row, false)

		-- Isolating content container
		local content = Instance.new("Frame")
		content.Size = UDim2.new(1, 0, 1, 0)
		content.BackgroundTransparency = 1
		content.ZIndex = 2
		content.Parent = row

		local nameTxt = Instance.new("TextLabel")
		nameTxt.Size = UDim2.new(0.5, 0, 0.45, 0)
		nameTxt.Position = UDim2.new(0.04, 0, 0.1, 0)
		nameTxt.BackgroundTransparency = 1
		nameTxt.Font = UIStyleConfig.Fonts.Title
		nameTxt.TextColor3 = UIStyleConfig.Colors.TextParchment
		nameTxt.TextSize = 10
		nameTxt.TextXAlignment = Enum.TextXAlignment.Left
		nameTxt.Text = item.Name:upper()
		nameTxt.Parent = content

		local descTxt = Instance.new("TextLabel")
		descTxt.Size = UDim2.new(0.55, 0, 0.4, 0)
		descTxt.Position = UDim2.new(0.04, 0, 0.52, 0)
		descTxt.BackgroundTransparency = 1
		descTxt.Font = UIStyleConfig.Fonts.BodyRegular
		descTxt.TextColor3 = UIStyleConfig.Colors.TextSilver
		descTxt.TextSize = 8
		descTxt.TextXAlignment = Enum.TextXAlignment.Left
		descTxt.Text = item.Desc
		descTxt.Parent = content

		local buyBtn = Instance.new("TextButton")
		buyBtn.Size = UDim2.new(0, 84, 0, 28)
		buyBtn.Position = UDim2.new(0.96, -84, 0.5, 0)
		buyBtn.AnchorPoint = Vector2.new(0, 0.5)
		buyBtn.BackgroundColor3 = UIStyleConfig.Colors.GreenSuccess
		buyBtn.BorderSizePixel = 0
		buyBtn.Font = UIStyleConfig.Fonts.Title
		buyBtn.TextColor3 = UIStyleConfig.Colors.TextParchment
		buyBtn.TextSize = 8
		buyBtn.Text = "PURCHASE"
		buyBtn.Parent = content

		StylePanelFrame(buyBtn, true)
		ApplyHoverTransitions(buyBtn)

		buyBtn.MouseButton1Click:Connect(function()
			TriggerLocalSound(UIStyleConfig.Sounds.Click)
			PurchaseItem:FireServer(item.Type, item.Key)
		end)
	end

	scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 15)
end

local function UpdateCrystalHP(hp)
	if not crystalHpFill or not crystalHpText then return end
	local maxHP = EconomyConfig.CRYSTAL_MAX_HP or 1000
	hp = math.clamp(hp or maxHP, 0, maxHP)
	local pct = hp / maxHP
	
	TweenService:Create(crystalHpFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(pct, 0, 1, 0)
	}):Play()
	
	crystalHpText.Text = "🛡️ CRYSTAL HP: " .. hp .. "/" .. maxHP
end

function InitializeHeroHUD(className)
	local classConfig = HeroConfig.Classes[className]
	if not classConfig then return end
	
	ClearHeroHUD()
	
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GameHUD"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	
	-- Master HUD Bar (Centered bottom, occupies and extends to the corners of the screen)
	local masterHUD = Instance.new("Frame")
	masterHUD.Name = "MasterHUD"
	masterHUD.Size = UDim2.new(1, 0, 0, isMobile and 72 or 64)
	masterHUD.Position = UDim2.new(0.5, 0, 1, 10)
	masterHUD.AnchorPoint = Vector2.new(0.5, 1)
	masterHUD.BackgroundTransparency = 1
	masterHUD.Parent = screenGui
	
	StylePanelFrame(masterHUD, true)
	AddGothicOrnaments(masterHUD)
	
	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MaxSize = Vector2.new(9999, 100)
	sizeConstraint.MinSize = Vector2.new(320, 40)
	sizeConstraint.Parent = masterHUD
	
	-- Content container to isolate columns from master HUD background elements and list layout
	local hudContent = Instance.new("Frame")
	hudContent.Name = "HUDContent"
	hudContent.Size = UDim2.new(1, 0, 1, 0)
	hudContent.BackgroundTransparency = 1
	hudContent.BorderSizePixel = 0
	hudContent.ZIndex = 2
	hudContent.Parent = masterHUD
	
	-- Symmetric 3-column Layout (Columns are distributed evenly!)
	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Horizontal
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	listLayout.Padding = UDim.new(0, 0)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = hudContent
	
	-- 1. LEFT COLUMN: HERO SHIELD CONSOLE
	local leftCol = CreateHUDSegment("LeftCol", 1, hudContent)
	
	local avatar = Instance.new("ImageLabel")
	avatar.Size = UDim2.new(0, isMobile and 44 or 38, 0, isMobile and 44 or 38)
	avatar.Position = UDim2.new(0, 12, 0.5, 0)
	avatar.AnchorPoint = Vector2.new(0, 0.5)
	avatar.BackgroundColor3 = UIStyleConfig.Colors.PanelBgDark
	avatar.BorderSizePixel = 0
	avatar.Parent = leftCol
	
	local avCorner = Instance.new("UICorner")
	avCorner.CornerRadius = UDim.new(1, 0)
	avCorner.Parent = avatar
	
	task.spawn(function()
		local success, content = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		end)
		if success then avatar.Image = content end
	end)
	
	local hsColor = UIStyleConfig.ClassThemes[className] and UIStyleConfig.ClassThemes[className].Color or Color3.fromRGB(150, 150, 150)
	
	local heroName = Instance.new("TextLabel")
	heroName.Size = UDim2.new(0.5, 0, 0.35, 0)
	heroName.Position = UDim2.new(0, isMobile and 64 or 58, 0.15, 0)
	heroName.BackgroundTransparency = 1
	heroName.Font = UIStyleConfig.Fonts.Title
	heroName.TextColor3 = hsColor
	heroName.TextSize = isMobile and 10 or 11
	heroName.TextXAlignment = Enum.TextXAlignment.Left
	heroName.Text = classConfig.Name:upper()
	heroName.Parent = leftCol
	
	local hpBg = Instance.new("Frame")
	hpBg.Size = UDim2.new(0.52, 0, 0, isMobile and 12 or 10)
	hpBg.Position = UDim2.new(0, isMobile and 64 or 58, 0.65, 0)
	hpBg.AnchorPoint = Vector2.new(0, 1)
	hpBg.BackgroundColor3 = UIStyleConfig.Colors.PanelBgDark
	hpBg.BorderSizePixel = 0
	hpBg.Parent = leftCol
	
	local hpc = Instance.new("UICorner"); hpc.CornerRadius = UDim.new(0, 3); hpc.Parent = hpBg
	
	local hpFill = Instance.new("Frame")
	hpFill.Size = UDim2.new(1, 0, 1, 0)
	hpFill.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
	hpFill.BorderSizePixel = 0
	hpFill.Parent = hpBg
	
	local hpfc = Instance.new("UICorner"); hpfc.CornerRadius = UDim.new(0, 3); hpfc.Parent = hpFill
	
	local hpText = Instance.new("TextLabel")
	hpText.Size = UDim2.new(1, 0, 1, 0)
	hpText.BackgroundTransparency = 1
	hpText.Font = UIStyleConfig.Fonts.Stats
	hpText.TextColor3 = UIStyleConfig.Colors.TextParchment
	hpText.TextSize = isMobile and 8 or 9
	hpText.Text = "HP: 100/100"
	hpText.Parent = hpBg
	
	local function SyncHeroHP()
		local char = player.Character
		local hum = char and char:FindFirstChild("Humanoid")
		if hum then
			local hp = math.max(0, math.floor(hum.Health))
			local maxHP = math.floor(hum.MaxHealth)
			local pct = math.clamp(hp / maxHP, 0, 1)
			TweenService:Create(hpFill, TweenInfo.new(0.2), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
			hpText.Text = "HP: " .. hp .. "/" .. maxHP
		end
	end
	
	local healthChangedConn = nil
	local function ConnectHumanoid()
		if healthChangedConn then healthChangedConn:Disconnect() end
		local char = player.Character
		local hum = char and char:WaitForChild("Humanoid", 5)
		if hum then
			healthChangedConn = hum.HealthChanged:Connect(SyncHeroHP)
			SyncHeroHP()
		end
	end
	table.insert(hudConnections, player.CharacterAdded:Connect(function()
		task.wait(0.2)
		ConnectHumanoid()
	end))
	ConnectHumanoid()
	
	-- E Ability Button Embedded on Right side of Left segment (highly responsive!)
	local abilityBtn = Instance.new("TextButton")
	abilityBtn.Name = "AbilityBtn"
	abilityBtn.Size = UDim2.new(0, isMobile and 44 or 38, 0, isMobile and 44 or 38)
	abilityBtn.Position = UDim2.new(0, isMobile and 254 or 218, 0.5, 0)
	abilityBtn.AnchorPoint = Vector2.new(0, 0.5)
	abilityBtn.BackgroundColor3 = hsColor
	abilityBtn.BorderSizePixel = 0
	abilityBtn.Font = UIStyleConfig.Fonts.Title
	abilityBtn.TextColor3 = UIStyleConfig.Colors.PanelBgDark
	abilityBtn.TextSize = isMobile and 15 or 14
	abilityBtn.Text = "E"
	abilityBtn.Parent = leftCol

	local abCorner = Instance.new("UICorner"); abCorner.CornerRadius = UDim.new(1, 0); abCorner.Parent = abilityBtn
	local abStroke = Instance.new("UIStroke"); abStroke.Thickness = 1.5; abStroke.Color = UIStyleConfig.Colors.BorderGold; abStroke.Parent = abilityBtn
	
	local cdOverlay = Instance.new("Frame")
	cdOverlay.Size = UDim2.new(1, 0, 0, 0)
	cdOverlay.Position = UDim2.new(0, 0, 1, 0)
	cdOverlay.AnchorPoint = Vector2.new(0, 1)
	cdOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	cdOverlay.BackgroundTransparency = 0.6
	cdOverlay.BorderSizePixel = 0
	cdOverlay.Parent = abilityBtn
	
	local cdc = Instance.new("UICorner"); cdc.CornerRadius = UDim.new(1, 0); cdc.Parent = cdOverlay

	local cdText = Instance.new("TextLabel")
	cdText.Size = UDim2.new(1, 0, 1, 0)
	cdText.BackgroundTransparency = 1
	cdText.Font = UIStyleConfig.Fonts.Title
	cdText.TextColor3 = UIStyleConfig.Colors.TextParchment
	cdText.TextSize = 13
	cdText.Text = ""
	cdText.Parent = abilityBtn

	local onCooldown = false
	local cooldownDuration = classConfig.Ability.Cooldown

	local function TriggerAbility()
		if onCooldown or currentGameState == "Lobby" then return end
		UseAbility:FireServer()
		TriggerLocalSound(UIStyleConfig.Sounds.Cast)
		onCooldown = true
		abilityBtn.Active = false
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
	abilityBtn.MouseButton1Click:Connect(TriggerAbility)
	table.insert(hudConnections, UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.E then TriggerAbility() end
	end))
	
	-- 2. CENTER COLUMN: WAVE & DEFEND BADGE CONSOLE
	local centerCol = CreateHUDSegment("CenterCol", 2, hudContent)
	
	local waveText = Instance.new("TextLabel")
	waveText.Size = UDim2.new(1, 0, 0.35, 0)
	waveText.Position = UDim2.new(0, 0, 0.08, 0)
	waveText.BackgroundTransparency = 1
	waveText.Font = UIStyleConfig.Fonts.Title
	waveText.TextColor3 = UIStyleConfig.Colors.TextParchment
	waveText.TextSize = isMobile and 10 or 11
	waveText.Text = "WAVE: 0/20"
	waveText.TextXAlignment = Enum.TextXAlignment.Center
	waveText.Parent = centerCol
	
	local crystalHpBg = Instance.new("Frame")
	crystalHpBg.Name = "CrystalHpBg"
	crystalHpBg.Size = UDim2.new(0, isMobile and 280 or 240, 0, isMobile and 14 or 12)
	crystalHpBg.Position = UDim2.new(0.5, 0, 0.45, 0)
	crystalHpBg.AnchorPoint = Vector2.new(0.5, 0)
	crystalHpBg.BackgroundColor3 = UIStyleConfig.Colors.PanelBgDark
	crystalHpBg.BorderSizePixel = 0
	crystalHpBg.Parent = centerCol
	
	local cchc = Instance.new("UICorner"); cchc.CornerRadius = UDim.new(0, 3); cchc.Parent = crystalHpBg
	
	local crystalHpFillFrame = Instance.new("Frame")
	crystalHpFillFrame.Name = "CrystalHpFill"
	crystalHpFillFrame.Size = UDim2.new(1, 0, 1, 0)
	crystalHpFillFrame.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
	crystalHpFillFrame.BorderSizePixel = 0
	crystalHpFillFrame.Parent = crystalHpBg
	
	local cfhc = Instance.new("UICorner"); cfhc.CornerRadius = UDim.new(0, 3); cfhc.Parent = crystalHpFillFrame
	
	local fillGrad = Instance.new("UIGradient")
	fillGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 100, 220)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 220, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 220)),
	})
	fillGrad.Parent = crystalHpFillFrame
	
	local crystalHpTextLabel = Instance.new("TextLabel")
	crystalHpTextLabel.Name = "CrystalHpText"
	crystalHpTextLabel.Size = UDim2.new(1, 0, 1, 0)
	crystalHpTextLabel.BackgroundTransparency = 1
	crystalHpTextLabel.Font = UIStyleConfig.Fonts.Stats
	crystalHpTextLabel.TextColor3 = UIStyleConfig.Colors.TextParchment
	crystalHpTextLabel.TextSize = isMobile and 8 or 9
	crystalHpTextLabel.Text = "🛡️ CRYSTAL HP: 1000/1000"
	crystalHpTextLabel.TextXAlignment = Enum.TextXAlignment.Center
	crystalHpTextLabel.Parent = crystalHpBg
	
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Color = UIStyleConfig.Colors.BorderBronze
	stroke.Transparency = 0.5
	stroke.Parent = crystalHpBg
	
	crystalHpFill = crystalHpFillFrame
	crystalHpText = crystalHpTextLabel
	
	UpdateCrystalHP(currentCrystalHP)
	
	local pathStatus = Instance.new("TextLabel")
	pathStatus.Size = UDim2.new(1, 0, 0.25, 0)
	pathStatus.Position = UDim2.new(0, 0, 0.72, 0)
	pathStatus.BackgroundTransparency = 1
	pathStatus.Font = UIStyleConfig.Fonts.BodyBold
	pathStatus.TextColor3 = UIStyleConfig.Colors.TextSilver
	pathStatus.TextSize = isMobile and 8 or 9
	pathStatus.Text = "🛡️ DEFENDING: ALLOTTING PATH..."
	pathStatus.TextXAlignment = Enum.TextXAlignment.Center
	pathStatus.Parent = centerCol
	
	local function SyncWave()
		local wave = workspace:GetAttribute("CurrentWave") or 0
		waveText.Text = "🚩 WAVE: " .. wave .. "/20"
	end
	workspace:GetAttributeChangedSignal("CurrentWave"):Connect(SyncWave)
	SyncWave()
	
	local function SyncAssignedPath()
		assignedPath = player:GetAttribute("AssignedPath")
		local theme = UIStyleConfig.PathThemes[assignedPath]
		if theme then
			pathStatus.Text = "🛡️ DEFENDING: " .. theme.Label:upper()
			pathStatus.TextColor3 = theme.Color
			ShowPathAssignmentBanner(assignedPath)
			DrawGuideBeam(assignedPath)
		else
			pathStatus.Text = "🛡️ DEFENDING: ALLOTTING PATH..."
			pathStatus.TextColor3 = UIStyleConfig.Colors.TextSilver
		end
	end
	player:GetAttributeChangedSignal("AssignedPath"):Connect(SyncAssignedPath)
	SyncAssignedPath()

	-- 3. RIGHT COLUMN: TREASURY & SHOP
	local rightCol = CreateHUDSegment("RightCol", 3, hudContent)
	
	-- Container for Gold and Gems balance labels
	local statsContainer = Instance.new("Frame")
	statsContainer.Name = "StatsContainer"
	statsContainer.Size = UDim2.new(0, 100, 0.8, 0)
	statsContainer.Position = UDim2.new(1, isMobile and -202 or -222, 0.5, 0)
	statsContainer.AnchorPoint = Vector2.new(1, 0.5)
	statsContainer.BackgroundTransparency = 1
	statsContainer.BorderSizePixel = 0
	statsContainer.Parent = rightCol
	
	local goldText = Instance.new("TextLabel")
	goldText.Size = UDim2.new(1, 0, 0.45, 0)
	goldText.Position = UDim2.new(0, 0, 0.05, 0)
	goldText.BackgroundTransparency = 1
	goldText.Font = UIStyleConfig.Fonts.Stats
	goldText.TextColor3 = UIStyleConfig.Colors.GoldAccent
	goldText.TextSize = isMobile and 11 or 12
	goldText.Text = "🪙 0"
	goldText.TextXAlignment = Enum.TextXAlignment.Right
	goldText.Parent = statsContainer
	
	local gemsText = Instance.new("TextLabel")
	gemsText.Size = UDim2.new(1, 0, 0.45, 0)
	gemsText.Position = UDim2.new(0, 0, 0.5, 0)
	gemsText.BackgroundTransparency = 1
	gemsText.Font = UIStyleConfig.Fonts.Stats
	gemsText.TextColor3 = UIStyleConfig.Colors.SelectionGlow
	gemsText.TextSize = isMobile and 11 or 12
	gemsText.Text = "💎 0"
	gemsText.TextXAlignment = Enum.TextXAlignment.Right
	gemsText.Parent = statsContainer
	
	local function SyncGold()
		local gold = player:GetAttribute("Gold") or 0
		goldText.Text = "🪙 " .. gold
	end
	local function SyncGems()
		local gems = player:GetAttribute("Gems") or 0
		gemsText.Text = "💎 " .. gems
	end
	player:GetAttributeChangedSignal("Gold"):Connect(SyncGold)
	player:GetAttributeChangedSignal("Gems"):Connect(SyncGems)
	SyncGold()
	SyncGems()
	
	-- Segmented buttons on far right: Shop & Console (Placed side-by-side!)
	local btnContainer = Instance.new("Frame")
	btnContainer.Size = UDim2.new(0, isMobile and 180 or 190, 0, isMobile and 44 or 38)
	btnContainer.Position = UDim2.new(1, -12, 0.5, 0)
	btnContainer.AnchorPoint = Vector2.new(1, 0.5)
	btnContainer.BackgroundTransparency = 1
	btnContainer.Parent = rightCol
	
	local btnLayout = Instance.new("UIListLayout")
	btnLayout.FillDirection = Enum.FillDirection.Horizontal
	btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	btnLayout.Padding = UDim.new(0, 6)
	btnLayout.Parent = btnContainer
	
	local gemsShopBtn = Instance.new("TextButton")
	gemsShopBtn.Size = UDim2.new(0.48, 0, 1, 0)
	gemsShopBtn.BackgroundColor3 = UIStyleConfig.Colors.BorderGold
	gemsShopBtn.BorderSizePixel = 0
	gemsShopBtn.Font = UIStyleConfig.Fonts.Title
	gemsShopBtn.TextColor3 = UIStyleConfig.Colors.PanelBgDark
	gemsShopBtn.TextSize = isMobile and 10 or 11
	gemsShopBtn.Text = "SHOP 💎"
	gemsShopBtn.Parent = btnContainer
	
	StylePanelFrame(gemsShopBtn, true)
	ApplyHoverTransitions(gemsShopBtn)
	gemsShopBtn.MouseButton1Click:Connect(function()
		TriggerLocalSound(UIStyleConfig.Sounds.Click)
		OpenShopScreen()
	end)
	
	local consoleToggle = Instance.new("TextButton")
	consoleToggle.Size = UDim2.new(0.48, 0, 1, 0)
	consoleToggle.BackgroundColor3 = UIStyleConfig.Colors.PanelBgDark
	consoleToggle.BorderSizePixel = 0
	consoleToggle.Font = UIStyleConfig.Fonts.Title
	consoleToggle.TextColor3 = UIStyleConfig.Colors.BorderGold
	consoleToggle.TextSize = isMobile and 10 or 11
	consoleToggle.Text = "DEFENSES"
	consoleToggle.Parent = btnContainer
	
	StylePanelFrame(consoleToggle, true)
	ApplyHoverTransitions(consoleToggle)

	-- 5. BUILD THE TACTICAL DEFENSE CONSOLE PANEL (FULLSCREEN OVERLAY)
	local consoleGui = Instance.new("ScreenGui")
	consoleGui.Name = "DefenseGridConsole"
	consoleGui.ResetOnSpawn = false
	consoleGui.Parent = playerGui
	activeConsole = consoleGui
	consoleGui.Enabled = false
	
	-- Centered Board Frame (FullScreen Symmetrical Board)
	local consoleFrame = Instance.new("Frame")
	consoleFrame.Name = "ConsoleFrame"
	consoleFrame.Size = UDim2.new(0.85, 0, 0.8, 0)
	consoleFrame.Position = UDim2.new(0.5, 0, 1.5, 0) -- start below the screen
	consoleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	consoleFrame.BackgroundColor3 = UIStyleConfig.Colors.PanelBg
	consoleFrame.Parent = consoleGui
	
	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MaxSize = Vector2.new(900, 600)
	sizeConstraint.MinSize = Vector2.new(500, 400)
	sizeConstraint.Parent = consoleFrame
	
	StylePanelFrame(consoleFrame, true)
	AddGothicOrnaments(consoleFrame)
	
	-- Content Wrapper to isolate background layers from layout
	local consoleContent = Instance.new("Frame")
	consoleContent.Name = "ConsoleContent"
	consoleContent.Size = UDim2.new(1, 0, 1, 0)
	consoleContent.BackgroundTransparency = 1
	consoleContent.ZIndex = 2
	consoleContent.Parent = consoleFrame
	
	-- Header Area
	local headerFrame = Instance.new("Frame")
	headerFrame.Name = "HeaderFrame"
	headerFrame.Size = UDim2.new(0.96, 0, 0, 40)
	headerFrame.Position = UDim2.new(0.02, 0, 0.02, 0)
	headerFrame.BackgroundTransparency = 1
	headerFrame.Parent = consoleContent
	
	local consoleTitle = Instance.new("TextLabel")
	consoleTitle.Size = UDim2.new(0.5, 0, 1, 0)
	consoleTitle.Position = UDim2.new(0, 0, 0, 0)
	consoleTitle.BackgroundTransparency = 1
	consoleTitle.Font = UIStyleConfig.Fonts.Title
	consoleTitle.TextColor3 = UIStyleConfig.Colors.GoldAccent
	consoleTitle.TextSize = 12
	consoleTitle.TextXAlignment = Enum.TextXAlignment.Left
	consoleTitle.Text = "🛡️ TACTICAL DEFENSE CONSOLE"
	consoleTitle.Parent = headerFrame
	
	-- Slots/Capacity Tracker Frame (Visual Gems/Pips)
	local slotsTracker = Instance.new("Frame")
	slotsTracker.Name = "SlotsTracker"
	slotsTracker.Size = UDim2.new(0.35, 0, 1, 0)
	slotsTracker.Position = UDim2.new(0.52, 0, 0, 0)
	slotsTracker.BackgroundTransparency = 1
	slotsTracker.Parent = headerFrame
	
	local slotsLayout = Instance.new("UIListLayout")
	slotsLayout.FillDirection = Enum.FillDirection.Horizontal
	slotsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	slotsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	slotsLayout.Padding = UDim.new(0, 6)
	slotsLayout.Parent = slotsTracker
	
	local slotsText = Instance.new("TextLabel")
	slotsText.Size = UDim2.new(0, 100, 1, 0)
	slotsText.BackgroundTransparency = 1
	slotsText.Font = UIStyleConfig.Fonts.BodyBold
	slotsText.TextColor3 = UIStyleConfig.Colors.TextSilver
	slotsText.TextSize = 9
	slotsText.TextXAlignment = Enum.TextXAlignment.Right
	slotsText.Text = "TOWERS: 0/5"
	slotsText.Parent = slotsTracker
	
	local pipsContainer = Instance.new("Frame")
	pipsContainer.Name = "PipsContainer"
	pipsContainer.Size = UDim2.new(0, 80, 1, 0)
	pipsContainer.BackgroundTransparency = 1
	pipsContainer.Parent = slotsTracker
	
	local pipsLayout = Instance.new("UIListLayout")
	pipsLayout.FillDirection = Enum.FillDirection.Horizontal
	pipsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	pipsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	pipsLayout.Padding = UDim.new(0, 4)
	pipsLayout.Parent = pipsContainer
	
	-- Close button
	local closeConsole = Instance.new("TextButton")
	closeConsole.Size = UDim2.new(0, 32, 0, 32)
	closeConsole.Position = UDim2.new(0.98, -32, 0.5, 0)
	closeConsole.AnchorPoint = Vector2.new(0, 0.5)
	closeConsole.BackgroundColor3 = UIStyleConfig.Colors.RedDanger
	closeConsole.BorderSizePixel = 0
	closeConsole.Font = UIStyleConfig.Fonts.Title
	closeConsole.TextColor3 = UIStyleConfig.Colors.TextParchment
	closeConsole.TextSize = 12
	closeConsole.Text = "X"
	closeConsole.Parent = headerFrame
	
	StylePanelFrame(closeConsole, false)
	
	-- Main Body Area (Split Layout: Map on left, Details on right)
	local bodyFrame = Instance.new("Frame")
	bodyFrame.Name = "BodyFrame"
	bodyFrame.Size = UDim2.new(0.96, 0, 0.68, 0)
	bodyFrame.Position = UDim2.new(0.02, 0, 0.1, 0)
	bodyFrame.BackgroundTransparency = 1
	bodyFrame.Parent = consoleContent
	
	-- Left Side: Tactical Map Canvas
	local mapContainer = Instance.new("Frame")
	mapContainer.Name = "MapContainer"
	mapContainer.Size = UDim2.new(0.58, 0, 1, 0)
	mapContainer.BackgroundColor3 = UIStyleConfig.Colors.PanelBgDark
	mapContainer.Parent = bodyFrame
	
	StylePanelFrame(mapContainer, false)
	
	local mapAspect = Instance.new("UIAspectRatioConstraint")
	mapAspect.AspectRatio = 1.0
	mapAspect.AspectType = Enum.AspectType.FitWithinMaxSize
	mapAspect.DominantAxis = Enum.DominantAxis.Height
	mapAspect.Parent = mapContainer
	
	local mapCanvas = Instance.new("Frame")
	mapCanvas.Name = "MapCanvas"
	mapCanvas.Size = UDim2.new(0.92, 0, 0.92, 0)
	mapCanvas.Position = UDim2.new(0.5, 0, 0.5, 0)
	mapCanvas.AnchorPoint = Vector2.new(0.5, 0.5)
	mapCanvas.BackgroundTransparency = 1
	mapCanvas.Parent = mapContainer
	
	-- Draw visual path segment backdrops on MapCanvas
	-- Castle Keep Center Square (Y Keep height is small, maps to center)
	local keepCenterUI = Instance.new("Frame")
	keepCenterUI.Name = "KeepCenterUI"
	keepCenterUI.Size = UDim2.new(0.24, 0, 0.24, 0)
	keepCenterUI.Position = UDim2.new(0.5, 0, 0.5, 0)
	keepCenterUI.AnchorPoint = Vector2.new(0.5, 0.5)
	keepCenterUI.BackgroundColor3 = UIStyleConfig.Colors.PanelBg
	keepCenterUI.Parent = mapCanvas
	StylePanelFrame(keepCenterUI, false)
	local keepStroke = keepCenterUI:FindFirstChildOfClass("UIStroke")
	if keepStroke then keepStroke.Color = UIStyleConfig.PathThemes.Interior.Color end
	
	local keepLabel = Instance.new("TextLabel")
	keepLabel.Size = UDim2.new(1, 0, 1, 0)
	keepLabel.BackgroundTransparency = 1
	keepLabel.Font = UIStyleConfig.Fonts.BodyBold
	keepLabel.TextColor3 = UIStyleConfig.PathThemes.Interior.Color
	keepLabel.TextSize = 8
	keepLabel.Text = "🏰\nKEEP"
	keepLabel.Parent = keepCenterUI
	
	-- Forest Path line (runs West/Left)
	local forestLine = Instance.new("Frame")
	forestLine.Name = "ForestLine"
	forestLine.Size = UDim2.new(0.38, 0, 0.04, 0)
	forestLine.Position = UDim2.new(0.06, 0, 0.5, 0)
	forestLine.AnchorPoint = Vector2.new(0, 0.5)
	forestLine.BackgroundColor3 = UIStyleConfig.PathThemes.ForestPath.Color
	forestLine.BorderSizePixel = 0
	forestLine.Parent = mapCanvas
	
	local forestGrad = Instance.new("UIGradient")
	forestGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, UIStyleConfig.Colors.PanelBgDark),
		ColorSequenceKeypoint.new(1, UIStyleConfig.PathThemes.ForestPath.Color)
	})
	forestGrad.Parent = forestLine
	
	local forestLbl = Instance.new("TextLabel")
	forestLbl.Size = UDim2.new(0, 60, 0, 14)
	forestLbl.Position = UDim2.new(0.05, 0, 0.44, 0)
	forestLbl.BackgroundTransparency = 1
	forestLbl.Font = UIStyleConfig.Fonts.BodyBold
	forestLbl.TextColor3 = UIStyleConfig.PathThemes.ForestPath.Color
	forestLbl.TextSize = 7
	forestLbl.TextXAlignment = Enum.TextXAlignment.Left
	forestLbl.Text = "🌲 FOREST"
	forestLbl.Parent = mapCanvas
	
	-- Undead Path line (runs East/Right)
	local undeadLine = Instance.new("Frame")
	undeadLine.Name = "UndeadLine"
	undeadLine.Size = UDim2.new(0.38, 0, 0.04, 0)
	undeadLine.Position = UDim2.new(0.94, 0, 0.5, 0)
	undeadLine.AnchorPoint = Vector2.new(1, 0.5)
	undeadLine.BackgroundColor3 = UIStyleConfig.PathThemes.UndeadPath.Color
	undeadLine.BorderSizePixel = 0
	undeadLine.Parent = mapCanvas
	
	local undeadGrad = Instance.new("UIGradient")
	undeadGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, UIStyleConfig.PathThemes.UndeadPath.Color),
		ColorSequenceKeypoint.new(1, UIStyleConfig.Colors.PanelBgDark)
	})
	undeadGrad.Rotation = 0
	undeadGrad.Parent = undeadLine
	
	local undeadLbl = Instance.new("TextLabel")
	undeadLbl.Size = UDim2.new(0, 60, 0, 14)
	undeadLbl.Position = UDim2.new(0.95, -60, 0.44, 0)
	undeadLbl.BackgroundTransparency = 1
	undeadLbl.Font = UIStyleConfig.Fonts.BodyBold
	undeadLbl.TextColor3 = UIStyleConfig.PathThemes.UndeadPath.Color
	undeadLbl.TextSize = 7
	undeadLbl.TextXAlignment = Enum.TextXAlignment.Right
	undeadLbl.Text = "💀 GRAVEYARD"
	undeadLbl.Parent = mapCanvas
	
	-- Dragon Pass line (runs South/Down)
	local dragonLine = Instance.new("Frame")
	dragonLine.Name = "DragonLine"
	dragonLine.Size = UDim2.new(0.04, 0, 0.38, 0)
	dragonLine.Position = UDim2.new(0.5, 0, 0.94, 0)
	dragonLine.AnchorPoint = Vector2.new(0.5, 1)
	dragonLine.BackgroundColor3 = UIStyleConfig.PathThemes.DragonPass.Color
	dragonLine.BorderSizePixel = 0
	dragonLine.Parent = mapCanvas
	
	local dragonGrad = Instance.new("UIGradient")
	dragonGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, UIStyleConfig.PathThemes.DragonPass.Color),
		ColorSequenceKeypoint.new(1, UIStyleConfig.Colors.PanelBgDark)
	})
	dragonGrad.Rotation = 90
	dragonGrad.Parent = dragonLine
	
	local dragonLbl = Instance.new("TextLabel")
	dragonLbl.Size = UDim2.new(0, 60, 0, 14)
	dragonLbl.Position = UDim2.new(0.5, 0, 0.95, -14)
	dragonLbl.AnchorPoint = Vector2.new(0.5, 0)
	dragonLbl.BackgroundTransparency = 1
	dragonLbl.Font = UIStyleConfig.Fonts.BodyBold
	dragonLbl.TextColor3 = UIStyleConfig.PathThemes.DragonPass.Color
	dragonLbl.TextSize = 7
	dragonLbl.Text = "🔥 DRAGON"
	dragonLbl.Parent = mapCanvas
	
	-- Right Side: Detail Panel Frame
	local detailPanel = Instance.new("Frame")
	detailPanel.Name = "DetailPanel"
	detailPanel.Size = UDim2.new(0.38, 0, 1, 0)
	detailPanel.Position = UDim2.new(0.62, 0, 0, 0)
	detailPanel.BackgroundColor3 = UIStyleConfig.Colors.PanelBgDark
	detailPanel.Parent = bodyFrame
	
	StylePanelFrame(detailPanel, false)
	
	-- Content Wrapper inside detail panel
	local detailContent = Instance.new("Frame")
	detailContent.Name = "DetailContent"
	detailContent.Size = UDim2.new(1, 0, 1, 0)
	detailContent.BackgroundTransparency = 1
	detailContent.ZIndex = 2
	detailContent.Parent = detailPanel
	
	-- Bottom Area: Horizontal Tower Selection Cards
	local footerFrame = Instance.new("Frame")
	footerFrame.Name = "FooterFrame"
	footerFrame.Size = UDim2.new(0.96, 0, 0, 80)
	footerFrame.Position = UDim2.new(0.02, 0, 0.82, 0)
	footerFrame.BackgroundTransparency = 1
	footerFrame.Parent = consoleContent
	
	local cardsScroll = Instance.new("ScrollingFrame")
	cardsScroll.Name = "CardsScroll"
	cardsScroll.Size = UDim2.new(1, 0, 1, 0)
	cardsScroll.BackgroundTransparency = 1
	cardsScroll.BorderSizePixel = 0
	cardsScroll.CanvasSize = UDim2.new(0, 520, 0, 0)
	cardsScroll.ScrollBarThickness = 4
	cardsScroll.ScrollBarImageColor3 = UIStyleConfig.Colors.BorderGold
	cardsScroll.Parent = footerFrame
	
	local cardsLayout = Instance.new("UIListLayout")
	cardsLayout.FillDirection = Enum.FillDirection.Horizontal
	cardsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	cardsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	cardsLayout.Padding = UDim.new(0, 12)
	cardsLayout.Parent = cardsScroll
	
	local RefreshConsole
	local UpdateDetailPanel
	
	function UpdateDetailPanel()
		-- Clear old content
		for _, child in ipairs(detailContent:GetChildren()) do
			if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("UIPadding") or child:IsA("UIListLayout") then
				child:Destroy()
			end
		end
		
		if not selectedBaseZone then
			-- No selection instructions
			local instructions = Instance.new("TextLabel")
			instructions.Size = UDim2.new(0.9, 0, 0.8, 0)
			instructions.Position = UDim2.new(0.5, 0, 0.5, 0)
			instructions.AnchorPoint = Vector2.new(0.5, 0.5)
			instructions.BackgroundTransparency = 1
			instructions.Font = UIStyleConfig.Fonts.BodyBold
			instructions.TextColor3 = UIStyleConfig.Colors.TextSilver
			instructions.TextSize = 10
			instructions.TextWrapped = true
			instructions.Text = "SELECT A PLACEMENT SPOT ON THE TACTICAL MAP TO MANAGE DEFENSES\n\n🟢 VACANT SPOT\n🟡 YOUR TOWER\n🔵 CO-OP TOWER"
			instructions.Parent = detailContent
			return
		end
		
		-- Zone is selected!
		local zone = selectedBaseZone
		local name = zone.Name
		local cleanName = GetCleanBaseName(name)
		local isOccupied = zone:GetAttribute("Occupied") == true
		
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Vertical
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.VerticalAlignment = Enum.VerticalAlignment.Top
		layout.Padding = UDim.new(0, 8)
		layout.Parent = detailContent
		
		local padding = Instance.new("UIPadding")
		padding.PaddingTop = UDim.new(0, 12)
		padding.PaddingLeft = UDim.new(0, 12)
		padding.PaddingRight = UDim.new(0, 12)
		padding.Parent = detailContent
		
		-- Zone title
		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, 0, 0, 20)
		title.BackgroundTransparency = 1
		title.Font = UIStyleConfig.Fonts.Title
		title.TextColor3 = UIStyleConfig.Colors.TextParchment
		title.TextSize = 11
		title.Text = cleanName:upper()
		title.Parent = detailContent
		
		if not isOccupied then
			-- Vacant zone details
			local status = Instance.new("TextLabel")
			status.Size = UDim2.new(1, 0, 0, 14)
			status.BackgroundTransparency = 1
			status.Font = UIStyleConfig.Fonts.BodyBold
			status.TextColor3 = UIStyleConfig.Colors.GreenSuccess
			status.TextSize = 9
			status.Text = "STATUS: VACANT"
			status.Parent = detailContent
			
			if selectedTowerToPlace then
				local towerName = selectedTowerToPlace
				local tConfig = TowerConfig.Towers[towerName]
				local lvl1 = tConfig.Levels[1]
				
				local tName = Instance.new("TextLabel")
				tName.Size = UDim2.new(1, 0, 0, 16)
				tName.BackgroundTransparency = 1
				tName.Font = UIStyleConfig.Fonts.Title
				tName.TextColor3 = UIStyleConfig.Colors.GoldAccent
				tName.TextSize = 10
				tName.Text = tConfig.Name:upper()
				tName.Parent = detailContent
				
				local desc = Instance.new("TextLabel")
				desc.Size = UDim2.new(1, 0, 0, 45)
				desc.BackgroundTransparency = 1
				desc.Font = UIStyleConfig.Fonts.BodyRegular
				desc.TextColor3 = UIStyleConfig.Colors.TextSilver
				desc.TextSize = 8
				desc.TextWrapped = true
				desc.Text = tConfig.Description
				desc.Parent = detailContent
				
				-- Big PLACE button
				local placeBtn = Instance.new("TextButton")
				placeBtn.Size = UDim2.new(0.9, 0, 0, 32)
				placeBtn.BorderSizePixel = 0
				placeBtn.Font = UIStyleConfig.Fonts.Title
				placeBtn.TextSize = 9
				placeBtn.Text = "BUILD (" .. lvl1.Cost .. "G)"
				placeBtn.Parent = detailContent
				
				local gold = player:GetAttribute("Gold") or 0
				if gold >= lvl1.Cost then
					placeBtn.BackgroundColor3 = UIStyleConfig.Colors.GreenSuccess
					placeBtn.TextColor3 = UIStyleConfig.Colors.TextParchment
					StylePanelFrame(placeBtn, true)
					ApplyHoverTransitions(placeBtn)
					placeBtn.MouseButton1Click:Connect(function()
						TriggerLocalSound(UIStyleConfig.Sounds.Build)
						PlaceTower:FireServer(selectedTowerToPlace, zone)
						selectedTowerToPlace = nil
						task.wait(0.1)
						RefreshConsole()
					end)
				else
					placeBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
					placeBtn.TextColor3 = UIStyleConfig.Colors.TextSilver
					StylePanelFrame(placeBtn, false)
					placeBtn.Active = false
				end
			else
				local hint = Instance.new("TextLabel")
				hint.Size = UDim2.new(1, 0, 0, 70)
				hint.BackgroundTransparency = 1
				hint.Font = UIStyleConfig.Fonts.BodyRegular
				hint.TextColor3 = UIStyleConfig.Colors.TextSilver
				hint.TextSize = 9
				hint.TextWrapped = true
				hint.Text = "Select a tower card from the bottom bar to construct a defense here."
				hint.Parent = detailContent
			end
		else
			-- Occupied zone details
			local towerVal = zone:FindFirstChild("TowerModel")
			local towerModel = towerVal and towerVal.Value
			
			if towerModel then
				local towerType = towerModel:GetAttribute("Type") or "Tower"
				local level = towerModel:GetAttribute("Level") or 1
				local ownerId = towerModel:GetAttribute("Owner")
				
				local typeConfig = TowerConfig.Towers[towerType]
				local currentLvlData = typeConfig.Levels[level]
				local nextLvlData = typeConfig.Levels[level + 1]
				
				local tName = Instance.new("TextLabel")
				tName.Size = UDim2.new(1, 0, 0, 16)
				tName.BackgroundTransparency = 1
				tName.Font = UIStyleConfig.Fonts.Title
				tName.TextColor3 = UIStyleConfig.Colors.GoldAccent
				tName.TextSize = 10
				tName.Text = (typeConfig.Name .. " LV. " .. level):upper()
				tName.Parent = detailContent
				
				-- Resolve owner name
				local ownerText = "Owner: Unknown"
				if ownerId == player.UserId then
					ownerText = "Owner: You"
				else
					local p = Players:GetPlayerByUserId(ownerId)
					ownerText = "Owner: " .. (p and p.DisplayName or "Player " .. tostring(ownerId))
				end
				
				local ownerLbl = Instance.new("TextLabel")
				ownerLbl.Size = UDim2.new(1, 0, 0, 12)
				ownerLbl.BackgroundTransparency = 1
				ownerLbl.Font = UIStyleConfig.Fonts.BodyBold
				ownerLbl.TextColor3 = UIStyleConfig.Colors.TextSilver
				ownerLbl.TextSize = 8
				ownerLbl.Text = ownerText
				ownerLbl.Parent = detailContent
				
				-- Stat Bar Helper
				local function CreateStatBar(name, val, maxVal, color)
					local row = Instance.new("Frame")
					row.Size = UDim2.new(1, 0, 0, 16)
					row.BackgroundTransparency = 1
					row.Parent = detailContent
					
					local lbl = Instance.new("TextLabel")
					lbl.Size = UDim2.new(0.35, 0, 1, 0)
					lbl.BackgroundTransparency = 1
					lbl.Font = UIStyleConfig.Fonts.Stats
					lbl.TextColor3 = UIStyleConfig.Colors.TextParchment
					lbl.TextSize = 8
					lbl.TextXAlignment = Enum.TextXAlignment.Left
					lbl.Text = name .. ": " .. val
					lbl.Parent = row
					
					local barBg = Instance.new("Frame")
					barBg.Size = UDim2.new(0.63, 0, 0, 6)
					barBg.Position = UDim2.new(0.37, 0, 0.5, 0)
					barBg.AnchorPoint = Vector2.new(0, 0.5)
					barBg.BackgroundColor3 = UIStyleConfig.Colors.PanelBgDark
					barBg.BorderSizePixel = 0
					barBg.Parent = row
					
					local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 2); bc.Parent = barBg
					
					local pct = math.clamp(val / maxVal, 0, 1)
					local barFill = Instance.new("Frame")
					barFill.Size = UDim2.new(pct, 0, 1, 0)
					barFill.BackgroundColor3 = color
					barFill.BorderSizePixel = 0
					barFill.Parent = barBg
					
					local bfc = Instance.new("UICorner"); bfc.CornerRadius = UDim.new(0, 2); bfc.Parent = barFill
				end
				
				-- Render active stats (normalized for bars)
				CreateStatBar("DAMAGE", currentLvlData.Damage or 0, 150, Color3.fromRGB(220, 50, 50))
				CreateStatBar("RANGE", currentLvlData.Range or 0, 70, Color3.fromRGB(50, 150, 250))
				CreateStatBar("RATE", currentLvlData.Cooldown and math.round(10/currentLvlData.Cooldown)/10 or 1, 5, Color3.fromRGB(50, 200, 50))
				
				-- Only allow operations if player owns the tower
				if ownerId == player.UserId then
					-- Action buttons container
					local actContainer = Instance.new("Frame")
					actContainer.Size = UDim2.new(1, 0, 0, 32)
					actContainer.BackgroundTransparency = 1
					actContainer.Parent = detailContent
					
					local actLayout = Instance.new("UIListLayout")
					actLayout.FillDirection = Enum.FillDirection.Horizontal
					actLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
					actLayout.VerticalAlignment = Enum.VerticalAlignment.Center
					actLayout.Padding = UDim.new(0, 8)
					actLayout.Parent = actContainer
					
					-- Upgrade Button
					local upgradeBtn = Instance.new("TextButton")
					upgradeBtn.Size = UDim2.new(0.6, -4, 1, 0)
					upgradeBtn.BorderSizePixel = 0
					upgradeBtn.Font = UIStyleConfig.Fonts.Title
					upgradeBtn.TextSize = 8
					upgradeBtn.Parent = actContainer
					
					if nextLvlData then
						local cost = nextLvlData.Cost
						upgradeBtn.Text = "UPGRADE (" .. cost .. "G)"
						local gold = player:GetAttribute("Gold") or 0
						
						if gold >= cost then
							upgradeBtn.BackgroundColor3 = UIStyleConfig.Colors.GreenSuccess
							upgradeBtn.TextColor3 = UIStyleConfig.Colors.TextParchment
							StylePanelFrame(upgradeBtn, true)
							ApplyHoverTransitions(upgradeBtn)
							upgradeBtn.MouseButton1Click:Connect(function()
								TriggerLocalSound(UIStyleConfig.Sounds.Build)
								UpgradeTower:FireServer(towerModel)
								task.wait(0.1)
								RefreshConsole()
							end)
						else
							upgradeBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
							upgradeBtn.TextColor3 = UIStyleConfig.Colors.TextSilver
							StylePanelFrame(upgradeBtn, false)
							upgradeBtn.Active = false
						end
					else
						upgradeBtn.Text = "MAX LEVEL"
						upgradeBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
						upgradeBtn.TextColor3 = UIStyleConfig.Colors.TextSilver
						StylePanelFrame(upgradeBtn, false)
						upgradeBtn.Active = false
					end
					
					-- Sell Button
					local sellBtn = Instance.new("TextButton")
					sellBtn.Size = UDim2.new(0.38, -4, 1, 0)
					sellBtn.BackgroundColor3 = UIStyleConfig.Colors.RedDanger
					sellBtn.BorderSizePixel = 0
					sellBtn.Font = UIStyleConfig.Fonts.Title
					sellBtn.TextColor3 = UIStyleConfig.Colors.TextParchment
					sellBtn.TextSize = 8
					
					local totalSpent = 0
					for l = 1, level do
						local lData = typeConfig.Levels[l]
						if lData then totalSpent = totalSpent + lData.Cost end
					end
					local refund = math.floor(totalSpent * 0.75)
					sellBtn.Text = "SELL (+" .. refund .. ")"
					sellBtn.Parent = actContainer
					
					StylePanelFrame(sellBtn, false)
					ApplyHoverTransitions(sellBtn)
					
					sellBtn.MouseButton1Click:Connect(function()
						TriggerLocalSound(UIStyleConfig.Sounds.Sell)
						SellTower:FireServer(towerModel)
						selectedBaseZone = nil
						task.wait(0.1)
						RefreshConsole()
					end)
				end
			else
				local loading = Instance.new("TextLabel")
				loading.Size = UDim2.new(1, 0, 0, 40)
				loading.BackgroundTransparency = 1
				loading.Font = UIStyleConfig.Fonts.BodyBold
				loading.TextColor3 = UIStyleConfig.Colors.TextSilver
				loading.TextSize = 9
				loading.Text = "OCCUPIED (LOADING...)"
				loading.Parent = detailContent
			end
		end
	end
	
	function RefreshConsole()
		-- 1. Refresh Slots Tracker
		local currentCount = 0
		local towersFolder = workspace:FindFirstChild("Towers")
		if towersFolder then
			for _, child in ipairs(towersFolder:GetChildren()) do
				if child:GetAttribute("Owner") == player.UserId then
					currentCount = currentCount + 1
				end
			end
		end
		
		local slotLimit = player:GetAttribute("TowerSlots") or TowerConfig.DEFAULT_MAX_TOWERS
		slotsText.Text = "TOWERS: " .. currentCount .. "/" .. slotLimit
		
		-- Clear and rebuild pips
		for _, child in ipairs(pipsContainer:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end
		
		for i = 1, slotLimit do
			local pip = Instance.new("Frame")
			pip.Size = UDim2.new(0, 8, 0, 8)
			pip.BackgroundColor3 = (i <= currentCount) and UIStyleConfig.Colors.GoldAccent or Color3.fromRGB(40, 40, 45)
			pip.BorderSizePixel = 0
			pip.Parent = pipsContainer
			
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(1, 0)
			corner.Parent = pip
			
			if i <= currentCount then
				local stroke = Instance.new("UIStroke")
				stroke.Thickness = 1
				stroke.Color = UIStyleConfig.Colors.BorderGold
				stroke.Parent = pip
			end
		end
		
		-- 2. Refresh Tower Browser (Footer Cards)
		for _, child in ipairs(cardsScroll:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end
		
		local currentWave = workspace:GetAttribute("CurrentWave") or 0
		local gold = player:GetAttribute("Gold") or 0
		
		local sortedTowers = {}
		for name, config in pairs(TowerConfig.Towers) do
			table.insert(sortedTowers, {Name = name, Config = config})
		end
		table.sort(sortedTowers, function(a, b)
			return a.Config.Levels[1].Cost < b.Config.Levels[1].Cost
		end)
		
		for _, item in ipairs(sortedTowers) do
			local name = item.Name
			local config = item.Config
			local cost = config.Levels[1].Cost
			local isLocked = config.UnlockWave and currentWave < config.UnlockWave
			
			local card = Instance.new("Frame")
			card.Name = "Card_" .. name
			card.Size = UDim2.new(0, 85, 0, 65)
			card.BackgroundColor3 = (selectedTowerToPlace == name) and UIStyleConfig.Colors.PanelBgDark or UIStyleConfig.Colors.PanelBg
			card.Parent = cardsScroll
			
			StylePanelFrame(card, selectedTowerToPlace == name)
			
			-- Content inside card
			local cardContent = Instance.new("Frame")
			cardContent.Size = UDim2.new(1, 0, 1, 0)
			cardContent.BackgroundTransparency = 1
			cardContent.ZIndex = 2
			cardContent.Parent = card
			
			local cardLayout = Instance.new("UIListLayout")
			cardLayout.FillDirection = Enum.FillDirection.Vertical
			cardLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			cardLayout.VerticalAlignment = Enum.VerticalAlignment.Center
			cardLayout.Padding = UDim.new(0, 2)
			cardLayout.Parent = cardContent
			
			-- Visual emoji
			local emojis = { Archer = "🏹", Mage = "🔮", Catapult = "💣", FrostSpire = "❄️", LightningRod = "⚡" }
			local emojiText = Instance.new("TextLabel")
			emojiText.Size = UDim2.new(1, 0, 0, 16)
			emojiText.BackgroundTransparency = 1
			emojiText.Font = UIStyleConfig.Fonts.Title
			emojiText.TextSize = 14
			emojiText.Text = emojis[name] or "🗼"
			emojiText.Parent = cardContent
			
			local nameText = Instance.new("TextLabel")
			nameText.Size = UDim2.new(0.9, 0, 0, 12)
			nameText.BackgroundTransparency = 1
			nameText.Font = UIStyleConfig.Fonts.BodyBold
			nameText.TextColor3 = isLocked and UIStyleConfig.Colors.TextSilver or UIStyleConfig.Colors.TextParchment
			nameText.TextSize = 8
			nameText.Text = config.Name:upper()
			nameText.Parent = cardContent
			
			local costText = Instance.new("TextLabel")
			costText.Size = UDim2.new(0.9, 0, 0, 10)
			costText.BackgroundTransparency = 1
			costText.Font = UIStyleConfig.Fonts.Stats
			costText.TextColor3 = isLocked and UIStyleConfig.Colors.TextSilver or UIStyleConfig.Colors.GoldAccent
			costText.TextSize = 8
			costText.Text = isLocked and "WAVE " .. config.UnlockWave or cost .. "G"
			costText.Parent = cardContent
			
			local selectBtn = Instance.new("TextButton")
			selectBtn.Size = UDim2.new(1, 0, 1, 0)
			selectBtn.BackgroundTransparency = 1
			selectBtn.Text = ""
			selectBtn.Parent = card
			
			if isLocked then
				card.BackgroundTransparency = 0.6
				-- Overlay dark lock panel
				local lockOverlay = Instance.new("Frame")
				lockOverlay.Size = UDim2.new(1, 0, 1, 0)
				lockOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				lockOverlay.BackgroundTransparency = 0.5
				lockOverlay.ZIndex = 3
				lockOverlay.Parent = card
				
				local lockLabel = Instance.new("TextLabel")
				lockLabel.Size = UDim2.new(1, 0, 1, 0)
				lockLabel.BackgroundTransparency = 1
				lockLabel.Font = UIStyleConfig.Fonts.Title
				lockLabel.TextColor3 = UIStyleConfig.Colors.RedDanger
				lockLabel.TextSize = 16
				lockLabel.Text = "🔒"
				lockLabel.ZIndex = 4
				lockLabel.Parent = lockOverlay
			else
				ApplyHoverTransitions(card)
				selectBtn.MouseButton1Click:Connect(function()
					TriggerLocalSound(UIStyleConfig.Sounds.Click)
					if selectedTowerToPlace == name then
						selectedTowerToPlace = nil
					else
						selectedTowerToPlace = name
					end
					RefreshConsole()
				end)
			end
		end
		
		-- 3. Rebuild Tactical Map Markers
		-- Clear old markers
		for _, child in ipairs(mapCanvas:GetChildren()) do
			if child.Name == "ZoneMarker" then child:Destroy() end
		end
		
		local mapModel = workspace:FindFirstChild("Map")
		local placementFolder = mapModel and mapModel:FindFirstChild("PlacementZones")
		
		if placementFolder then
			local mapScale = 220
			for _, zone in ipairs(placementFolder:GetChildren()) do
				if CollectionService:HasTag(zone, "PlacementZone") then
					local name = zone.Name
					local isInterior = string.find(name, "Interior") ~= nil
					local isAssignedPath = assignedPath and string.find(name, assignedPath) ~= nil
					local isAssigned = isInterior or isAssignedPath
					
					local isOccupied = zone:GetAttribute("Occupied") == true
					local pos = zone.Position
					
					-- Math mapping
					local rx = pos.X / mapScale
					local rz = pos.Z / mapScale
					local ux = 0.5 + (rx * 0.5)
					local uy = 0.5 + (rz * 0.5)
					
					-- Create Marker Button
					local marker = Instance.new("ImageButton")
					marker.Name = "ZoneMarker"
					marker.Size = UDim2.new(0, isAssigned and 18 or 12, 0, isAssigned and 18 or 12)
					marker.Position = UDim2.new(ux, 0, uy, 0)
					marker.AnchorPoint = Vector2.new(0.5, 0.5)
					marker.ZIndex = 5
					marker.Parent = mapCanvas
					
					local mCorner = Instance.new("UICorner")
					mCorner.CornerRadius = UDim.new(1, 0)
					mCorner.Parent = marker
					
					local mStroke = Instance.new("UIStroke")
					mStroke.Thickness = 1.5
					mStroke.Parent = marker
					
					local markerLabel = Instance.new("TextLabel")
					markerLabel.Size = UDim2.new(1, 0, 1, 0)
					markerLabel.BackgroundTransparency = 1
					markerLabel.Font = UIStyleConfig.Fonts.Title
					markerLabel.TextColor3 = UIStyleConfig.Colors.TextParchment
					markerLabel.TextSize = 8
					markerLabel.Parent = marker
					
					-- Style marker based on status
					if isAssigned then
						-- Active interactive marker
						if isOccupied then
							local towerVal = zone:FindFirstChild("TowerModel")
							local towerModel = towerVal and towerVal.Value
							
							if towerModel then
								local tType = towerModel:GetAttribute("Type") or "Tower"
								local ownerId = towerModel:GetAttribute("Owner")
								
								local abbreviations = { Archer = "A", Mage = "M", Catapult = "C", FrostSpire = "F", LightningRod = "L" }
								markerLabel.Text = abbreviations[tType] or "T"
								
								if ownerId == player.UserId then
									-- Player's own tower: Gold accent
									marker.BackgroundColor3 = UIStyleConfig.Colors.GoldAccent
									markerLabel.TextColor3 = UIStyleConfig.Colors.PanelBgDark
									mStroke.Color = UIStyleConfig.Colors.BorderGold
								else
									-- Other player's tower on our path: Blue accent
									marker.BackgroundColor3 = Color3.fromRGB(0, 120, 240)
									markerLabel.TextColor3 = UIStyleConfig.Colors.TextParchment
									mStroke.Color = Color3.fromRGB(0, 180, 255)
								end
							else
								marker.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
								mStroke.Color = Color3.fromRGB(120, 120, 120)
								markerLabel.Text = "..."
							end
						else
							-- Vacant
							if selectedTowerToPlace then
								-- Green pulsing to denote placement target
								marker.BackgroundColor3 = UIStyleConfig.Colors.GreenSuccess
								mStroke.Color = UIStyleConfig.Colors.BorderGold
								markerLabel.Text = "+"
								
								-- Subtle bounce tween on active placement markers
								local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
								local scaleTween = TweenService:Create(marker, tweenInfo, {Size = UDim2.new(0, 22, 0, 22)})
								scaleTween:Play()
							else
								marker.BackgroundColor3 = Color3.fromRGB(40, 35, 30)
								mStroke.Color = UIStyleConfig.Colors.BorderBronze
								markerLabel.Text = ""
							end
						end
						
						-- Selected outline highlight
						if selectedBaseZone == zone then
							mStroke.Thickness = 2.5
							mStroke.Color = Color3.fromRGB(255, 255, 255)
							
							-- High visibility white/gold outline pulsing
							local pulseStroke = TweenService:Create(mStroke, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true), {
								Color = UIStyleConfig.Colors.SelectionGlow
							})
							pulseStroke:Play()
						end
						
						-- Interaction connections
						marker.MouseEnter:Connect(function()
							HighlightZone(zone)
						end)
						marker.MouseLeave:Connect(function()
							ClearHighlight()
						end)
						
						marker.MouseButton1Click:Connect(function()
							TriggerLocalSound(UIStyleConfig.Sounds.Click)
							
							if isOccupied then
								-- Clicking occupied zone selects it
								selectedBaseZone = zone
								selectedTowerToPlace = nil
								RefreshConsole()
							else
								-- Clicking vacant zone
								if selectedTowerToPlace then
									-- Place tower!
									local cost = TowerConfig.Towers[selectedTowerToPlace].Levels[1].Cost
									local pGold = player:GetAttribute("Gold") or 0
									if pGold >= cost then
										TriggerLocalSound(UIStyleConfig.Sounds.Build)
										PlaceTower:FireServer(selectedTowerToPlace, zone)
										selectedBaseZone = zone
										selectedTowerToPlace = nil
										task.wait(0.1)
										RefreshConsole()
									else
										TriggerLocalSound(UIStyleConfig.Sounds.Error)
									end
								else
									selectedBaseZone = zone
									RefreshConsole()
								end
							end
						end)
					else
						-- Dimmed non-interactive dots for structural context
						marker.Active = false
						markerLabel.Text = ""
						if isOccupied then
							-- Other player's tower: Small dimmed blue dot
							marker.BackgroundColor3 = Color3.fromRGB(30, 80, 120)
							mStroke.Color = Color3.fromRGB(40, 100, 140)
							mStroke.Transparency = 0.5
						else
							-- Vacant: Small dark grey dot
							marker.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
							mStroke.Color = Color3.fromRGB(40, 40, 45)
							mStroke.Transparency = 0.7
						end
					end
				end
			end
		end
		
		-- 4. Refresh Detail Panel
		UpdateDetailPanel()
	end
	
	local function SetupZoneListeners()
		local mapModel = workspace:WaitForChild("Map", 5)
		local placementFolder = mapModel and mapModel:WaitForChild("PlacementZones", 5)
		
		if placementFolder then
			for _, zone in ipairs(placementFolder:GetChildren()) do
				zone.AttributeChanged:Connect(function(attr)
					if attr == "Occupied" or attr == "Level" then
						if consoleGui.Enabled then
							RefreshConsole()
						end
					end
				end)
			end
		end
	end
	SetupZoneListeners()
	
	consoleToggle.MouseButton1Click:Connect(function()
		TriggerLocalSound(UIStyleConfig.Sounds.Click)
		if consoleGui.Enabled then
			local tween = TweenService:Create(consoleFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, 1.5, 0)})
			tween:Play()
			task.delay(0.35, function()
				consoleGui.Enabled = false
			end)
		else
			consoleGui.Enabled = true
			selectedTowerToPlace = nil
			selectedBaseZone = nil
			RefreshConsole()
			consoleFrame.Position = UDim2.new(0.5, 0, 1.5, 0)
			TweenService:Create(consoleFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
		end
	end)
	
	closeConsole.MouseButton1Click:Connect(function()
		TriggerLocalSound(UIStyleConfig.Sounds.Click)
		local tween = TweenService:Create(consoleFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, 1.5, 0)})
		tween:Play()
		task.delay(0.35, function()
			consoleGui.Enabled = false
		end)
	end)
	
	player:GetAttributeChangedSignal("Gold"):Connect(function()
		if consoleGui.Enabled then
			RefreshConsole()
		end
	end)
end

-- ============================================
-- GAME STATE LISTENERS
-- ============================================
SyncGameState.OnClientEvent:Connect(function(data)
	currentGameState = data.State
	
	if data.CrystalHP then
		currentCrystalHP = data.CrystalHP
		UpdateCrystalHP(currentCrystalHP)
	end
	
	if data.State ~= "Lobby" then
		local mainLobby = playerGui:FindFirstChild("MainMenuGui")
		if mainLobby then mainLobby:Destroy() end
		
		local selectGui = playerGui:FindFirstChild("ClassSelectionGui")
		if selectGui then selectGui:Destroy() end
	end

	if data.State == "Victory" then
		ShowEndgameOverlay(true)
	elseif data.State == "GameOver" then
		ShowEndgameOverlay(false)
	elseif data.State == "Lobby" then
		local endgameGui = playerGui:FindFirstChild("EndgameGui")
		if endgameGui then endgameGui:Destroy() end
		
		ClearHeroHUD()
		
		local selectGui = playerGui:FindFirstChild("ClassSelectionGui")
		if selectGui then selectGui:Destroy() end
		
		local mainLobby = playerGui:FindFirstChild("MainMenuGui")
		if not mainLobby then
			OpenMainMenuScreen()
		end
	end
end)

task.spawn(OpenMainMenuScreen)
task.spawn(PlayAmbientMusic)

print("[UIController] core interface and console controllers initialized.")
