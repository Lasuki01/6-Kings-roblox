-- ============================================
-- PartyUIController.client.lua — Kingdom Siege
-- Symmetrical, mobile-optimized matchmaking lobby GUI and runic loaders.
-- Side: Client
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Configuration modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Config = Modules:WaitForChild("Config")
local LobbyConfig = require(Config:WaitForChild("LobbyConfig"))
local UIStyleConfig = require(Config:WaitForChild("UIStyleConfig"))

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ExitParty = Remotes:WaitForChild("ExitParty")
local KickPlayer = Remotes:WaitForChild("KickPlayer")
local StartPartyRun = Remotes:WaitForChild("StartPartyRun")
local UpdatePartySettings = Remotes:WaitForChild("UpdatePartySettings")
local SyncPartyData = Remotes:WaitForChild("SyncPartyData")
local SyncGameState = Remotes:WaitForChild("SyncGameState")

-- Player references
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- UI state
local partyGui = nil
local countdownOverlay = nil
local loadingOverlay = nil
local toastLabel = nil

local isMobile = UserInputService.TouchEnabled

-- Connection tracking to prevent leaks
local activeConnections = {}

local function CleanupConnections()
	for _, conn in ipairs(activeConnections) do
		if conn and conn.Connected then conn:Disconnect() end
	end
	activeConnections = {}
end

local function TrackConnection(conn)
	table.insert(activeConnections, conn)
	return conn
end

-- Sound effect helper
local function TriggerLocalSound(soundId)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. tostring(soundId)
	sound.Volume = 0.4
	sound.Parent = playerGui
	sound:Play()
	sound.Ended:Connect(function() sound:Destroy() end)
end

-- Sleek border styler
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
		f.ZIndex = 2
		f.Parent = frame
	end
end

local function StylePanelFrame(frame, hasGoldBorder)
	frame.BackgroundTransparency = 1
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
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
	bgSolidCorner.CornerRadius = UDim.new(0, 12)
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
	bgTextureCorner.CornerRadius = UDim.new(0, 12)
	bgTextureCorner.Parent = bgTexture
end

-- Hover animation decorator
local function ApplyHoverTransitions(btn)
	local stroke = btn:FindFirstChildOfClass("UIStroke")
	local originalSize = btn.Size
	
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(originalSize.X.Scale * 1.02, originalSize.X.Offset * 1.02, originalSize.Y.Scale * 1.02, originalSize.Y.Offset * 1.02)
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
end

-- Sleek Toast Notification
local function ShowToast(message, color)
	color = color or UIStyleConfig.Colors.RedDanger
	
	if not toastLabel then
		local toastGui = Instance.new("ScreenGui")
		toastGui.Name = "LobbyToastGui"
		toastGui.ResetOnSpawn = false
		toastGui.DisplayOrder = 25
		toastGui.Parent = playerGui
		
		toastLabel = Instance.new("TextLabel")
		toastLabel.Name = "ToastLabel"
		toastLabel.Size = UDim2.new(0, 360, 0, 48)
		toastLabel.Position = UDim2.new(0.5, 0, 0.12, 0)
		toastLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		toastLabel.BackgroundColor3 = color
		toastLabel.TextColor3 = UIStyleConfig.Colors.TextParchment
		toastLabel.Font = UIStyleConfig.Fonts.Title
		toastLabel.TextSize = 12
		toastLabel.BorderSizePixel = 0
		toastLabel.BackgroundTransparency = 1
		toastLabel.TextTransparency = 1
		toastLabel.Parent = toastGui
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = toastLabel
		
		local stroke = Instance.new("UIStroke")
		stroke.Color = UIStyleConfig.Colors.BorderGold
		stroke.Thickness = 1.2
		stroke.Transparency = 1
		stroke.Parent = toastLabel
	end
	
	toastLabel.BackgroundColor3 = color
	toastLabel.Text = "🛡️  " .. message:upper()
	TriggerLocalSound(UIStyleConfig.Sounds.Error)
	
	TweenService:Create(toastLabel, TweenInfo.new(0.3), {BackgroundTransparency = 0.1, TextTransparency = 0}):Play()
	local stroke = toastLabel:FindFirstChildOfClass("UIStroke")
	if stroke then
		TweenService:Create(stroke, TweenInfo.new(0.3), {Transparency = 0.2}):Play()
	end
	
	task.delay(3, function()
		if toastLabel then
			TweenService:Create(toastLabel, TweenInfo.new(0.3), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
			if stroke then
				TweenService:Create(stroke, TweenInfo.new(0.3), {Transparency = 1}):Play()
			end
		end
	end)
end

-- Get player avatar thumbnail
local function GetAvatarThumbnail(userId)
	local success, content = pcall(function()
		return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
	end)
	if success then return content end
	return ""
end

-- Renders the members list with avatars
local function PopulateMembers(membersListFrame, members, isLocalHost)
	for _, child in ipairs(membersListFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	
	for i, member in ipairs(members) do
		local frame = Instance.new("Frame")
		frame.Name = "Member_" .. member.Name
		frame.Size = UDim2.new(0.96, 0, 0, 46)
		frame.BackgroundColor3 = UIStyleConfig.Colors.PanelBgDark
		frame.Parent = membersListFrame
		
		StylePanelFrame(frame, member.IsHost)
		
		local avatar = Instance.new("ImageLabel")
		avatar.Name = "Avatar"
		avatar.Size = UDim2.new(0, 36, 0, 36)
		avatar.Position = UDim2.new(0, 8, 0.5, 0)
		avatar.AnchorPoint = Vector2.new(0, 0.5)
		avatar.BackgroundColor3 = UIStyleConfig.Colors.PanelBg
		avatar.BorderSizePixel = 0
		avatar.Parent = frame
		
		local avatarCorner = Instance.new("UICorner")
		avatarCorner.CornerRadius = UDim.new(1, 0)
		avatarCorner.Parent = avatar
		
		task.spawn(function()
			local thumbUrl = GetAvatarThumbnail(member.UserId)
			if thumbUrl and thumbUrl ~= "" then avatar.Image = thumbUrl end
		end)
		
		local displayText = member.DisplayName or member.Name
		if member.IsHost then displayText = "👑 " .. displayText end
		
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.55, 0, 1, 0)
		nameLabel.Position = UDim2.new(0, 52, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = UIStyleConfig.Fonts.BodyBold
		nameLabel.TextColor3 = member.IsHost and UIStyleConfig.Colors.GoldAccent or UIStyleConfig.Colors.TextParchment
		nameLabel.TextSize = 12
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		nameLabel.Text = displayText
		nameLabel.Parent = frame
		
		if isLocalHost and member.Name ~= player.Name then
			local kickBtn = Instance.new("TextButton")
			kickBtn.Name = "KickButton"
			kickBtn.Size = UDim2.new(0, 56, 0, 26)
			kickBtn.Position = UDim2.new(0.96, -56, 0.5, 0)
			kickBtn.AnchorPoint = Vector2.new(0, 0.5)
			kickBtn.BackgroundColor3 = UIStyleConfig.Colors.RedDanger
			kickBtn.BorderSizePixel = 0
			kickBtn.Font = UIStyleConfig.Fonts.Title
			kickBtn.TextColor3 = UIStyleConfig.Colors.TextParchment
			kickBtn.TextSize = 9
			kickBtn.Text = "KICK"
			kickBtn.Parent = frame
			
			StylePanelFrame(kickBtn, false)
			ApplyHoverTransitions(kickBtn)
			
			TrackConnection(kickBtn.MouseButton1Click:Connect(function()
				TriggerLocalSound(UIStyleConfig.Sounds.Click)
				local pObj = Players:FindFirstChild(member.Name)
				if pObj then KickPlayer:FireServer(pObj) end
			end))
		end
	end
end

-- Renders the party setup controls
local function BuildSettingsControls(settingsFrame, data, isLocalHost)
	for _, child in ipairs(settingsFrame:GetChildren()) do child:Destroy() end
	
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 12)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = settingsFrame
	
	local function CreateSettingLabel(text, order)
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(0.95, 0, 0, 16)
		lbl.BackgroundTransparency = 1
		lbl.Font = UIStyleConfig.Fonts.Title
		lbl.TextColor3 = UIStyleConfig.Colors.TextSilver
		lbl.TextSize = 10
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Text = text:upper()
		lbl.LayoutOrder = order
		lbl.Parent = settingsFrame
		return lbl
	end
	
	-- Max Players Selector
	CreateSettingLabel("Max Players:", 1)
	
	local maxContainer = Instance.new("Frame")
	maxContainer.Size = UDim2.new(0.95, 0, 0, 34) -- taller for mobile touch
	maxContainer.BackgroundTransparency = 1
	maxContainer.LayoutOrder = 2
	maxContainer.Parent = settingsFrame
	
	local maxLayout = Instance.new("UIListLayout")
	maxLayout.FillDirection = Enum.FillDirection.Horizontal
	maxLayout.Padding = UDim.new(0, 6)
	maxLayout.Parent = maxContainer
	
	for _, opt in ipairs(LobbyConfig.MaxPlayersOptions) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 34, 1, 0) -- square touch targets
		btn.BorderSizePixel = 0
		btn.Font = UIStyleConfig.Fonts.Title
		btn.TextSize = 11
		btn.Text = tostring(opt)
		btn.Parent = maxContainer
		
		if data.MaxPlayers == opt then
			btn.BackgroundColor3 = UIStyleConfig.Colors.GreenSuccess
			btn.TextColor3 = UIStyleConfig.Colors.TextParchment
			StylePanelFrame(btn, true)
		else
			btn.BackgroundColor3 = UIStyleConfig.Colors.PanelBgDark
			btn.TextColor3 = UIStyleConfig.Colors.TextSilver
			StylePanelFrame(btn, false)
		end
		
		if isLocalHost then
			ApplyHoverTransitions(btn)
			TrackConnection(btn.MouseButton1Click:Connect(function()
				TriggerLocalSound(UIStyleConfig.Sounds.Click)
				UpdatePartySettings:FireServer(opt, data.Difficulty, data.Privacy)
			end))
		else
			btn.Active = false
		end
	end
	
	-- Difficulty Selector
	CreateSettingLabel("Difficulty:", 3)
	
	local diffContainer = Instance.new("Frame")
	diffContainer.Size = UDim2.new(0.95, 0, 0, 34)
	diffContainer.BackgroundTransparency = 1
	diffContainer.LayoutOrder = 4
	diffContainer.Parent = settingsFrame
	
	local diffLayout = Instance.new("UIListLayout")
	diffLayout.FillDirection = Enum.FillDirection.Horizontal
	diffLayout.Padding = UDim.new(0, 6)
	diffLayout.Parent = diffContainer
	
	for _, diff in ipairs(LobbyConfig.Difficulties) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 68, 1, 0) -- wider for mobile fingers
		btn.BorderSizePixel = 0
		btn.Font = UIStyleConfig.Fonts.Title
		btn.TextSize = 9
		btn.Text = diff:upper()
		btn.Parent = diffContainer
		
		if data.Difficulty == diff then
			btn.BackgroundColor3 = UIStyleConfig.Colors.BorderGold
			btn.TextColor3 = UIStyleConfig.Colors.PanelBgDark
			StylePanelFrame(btn, true)
		else
			btn.BackgroundColor3 = UIStyleConfig.Colors.PanelBgDark
			btn.TextColor3 = UIStyleConfig.Colors.TextSilver
			StylePanelFrame(btn, false)
		end
		
		if isLocalHost then
			ApplyHoverTransitions(btn)
			TrackConnection(btn.MouseButton1Click:Connect(function()
				TriggerLocalSound(UIStyleConfig.Sounds.Click)
				UpdatePartySettings:FireServer(data.MaxPlayers, diff, data.Privacy)
			end))
		else
			btn.Active = false
		end
	end
	
	-- Privacy Toggle
	CreateSettingLabel("Privacy:", 5)
	
	local privBtn = Instance.new("TextButton")
	privBtn.Size = UDim2.new(0.95, 0, 0, 34)
	privBtn.BorderSizePixel = 0
	privBtn.Font = UIStyleConfig.Fonts.Title
	privBtn.TextSize = 10
	privBtn.Text = "🔒 ACCESS: " .. data.Privacy:upper()
	privBtn.LayoutOrder = 6
	privBtn.Parent = settingsFrame
	
	if data.Privacy == "Public" then
		privBtn.BackgroundColor3 = UIStyleConfig.Colors.GreenSuccess
		privBtn.TextColor3 = UIStyleConfig.Colors.TextParchment
		StylePanelFrame(privBtn, true)
	else
		privBtn.BackgroundColor3 = UIStyleConfig.Colors.RedDanger
		privBtn.TextColor3 = UIStyleConfig.Colors.TextParchment
		StylePanelFrame(privBtn, true)
	end
	
	if isLocalHost then
		ApplyHoverTransitions(privBtn)
		TrackConnection(privBtn.MouseButton1Click:Connect(function()
			TriggerLocalSound(UIStyleConfig.Sounds.Click)
			local newPrivacy = (data.Privacy == "Public") and "Private" or "Public"
			UpdatePartySettings:FireServer(data.MaxPlayers, data.Difficulty, newPrivacy)
		end))
	else
		privBtn.Active = false
	end
	
	if not isLocalHost then
		local waitLabel = Instance.new("TextLabel")
		waitLabel.Size = UDim2.new(0.95, 0, 0, 24)
		waitLabel.BackgroundTransparency = 1
		waitLabel.Font = UIStyleConfig.Fonts.BodyBold
		waitLabel.TextColor3 = UIStyleConfig.Colors.GoldAccent
		waitLabel.TextSize = 10
		waitLabel.Text = "⏳ WAITING FOR HOST..."
		waitLabel.LayoutOrder = 7
		waitLabel.Parent = settingsFrame
	end
end

local previousMemberCount = 0

-- Symmetrical Party Board Assembly
local function SyncPartyUI(allPartiesData)
	local activePartyData = nil
	for padId, party in pairs(allPartiesData) do
		for _, member in ipairs(party.Members) do
			if member.Name == player.Name then
				activePartyData = party
				break
			end
		end
		if activePartyData then break end
	end
	
	if not activePartyData then
		CleanupConnections()
		if partyGui then partyGui:Destroy(); partyGui = nil end
		if countdownOverlay then countdownOverlay:Destroy(); countdownOverlay = nil end
		if loadingOverlay then loadingOverlay:Destroy(); loadingOverlay = nil end
		previousMemberCount = 0
		return
	end
	
	local data = activePartyData
	
	local newMemberCount = #data.Members
	if previousMemberCount > 0 then
		if newMemberCount > previousMemberCount then
			TriggerLocalSound(UIStyleConfig.Sounds.Click)
		elseif newMemberCount < previousMemberCount then
			TriggerLocalSound(UIStyleConfig.Sounds.Error)
		end
	end
	previousMemberCount = newMemberCount
	
	local isLocalHost = (data.HostName == player.Name)
	
	if not partyGui then
		CleanupConnections()
		
		partyGui = Instance.new("ScreenGui")
		partyGui.Name = "PartyLobbyGui"
		partyGui.ResetOnSpawn = false
		partyGui.DisplayOrder = 10
		partyGui.Parent = playerGui
		
		-- Center board Frame (Perfect Symmetry & mobile friendly!)
		local frame = Instance.new("Frame")
		frame.Name = "MainFrame"
		frame.Size = UDim2.new(0.92, 0, 0.8, 0)
		frame.Position = UDim2.new(0.5, 0, 0.45, 0)
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.BackgroundColor3 = UIStyleConfig.Colors.PanelBg
		frame.Parent = partyGui
		
		local frameConstraint = Instance.new("UISizeConstraint")
		frameConstraint.MaxSize = Vector2.new(520, 380)
		frameConstraint.MinSize = Vector2.new(300, 240)
		frameConstraint.Parent = frame
		
		StylePanelFrame(frame, true)
		AddGothicOrnaments(frame)
		
		-- Title (Symmetrical top)
		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.Size = UDim2.new(0.9, 0, 0.1, 0)
		title.Position = UDim2.new(0.5, 0, 0.04, 0)
		title.AnchorPoint = Vector2.new(0.5, 0)
		title.BackgroundTransparency = 1
		title.Font = UIStyleConfig.Fonts.Title
		title.TextColor3 = UIStyleConfig.Colors.TextParchment
		title.TextSize = 15
		title.Text = "⚔️  PARTY PAD #" .. tostring(data.PadId)
		title.Parent = frame
		
		local divider = Instance.new("Frame")
		divider.Size = UDim2.new(0.9, 0, 0, 1)
		divider.Position = UDim2.new(0.5, 0, 0.14, 0)
		divider.AnchorPoint = Vector2.new(0.5, 0)
		divider.BackgroundColor3 = UIStyleConfig.Colors.BorderBronze
		divider.BorderSizePixel = 0
		divider.Parent = frame
		
		-- Equal columns
		local membersFrame = Instance.new("Frame")
		membersFrame.Name = "MembersFrame"
		membersFrame.Size = UDim2.new(0.46, 0, 0.65, 0)
		membersFrame.Position = UDim2.new(0.04, 0, 0.18, 0)
		membersFrame.BackgroundTransparency = 1
		membersFrame.Parent = frame
		
		local mLayout = Instance.new("UIListLayout")
		mLayout.Padding = UDim.new(0, 6)
		mLayout.Parent = membersFrame
		
		local settingsFrame = Instance.new("Frame")
		settingsFrame.Name = "SettingsFrame"
		settingsFrame.Size = UDim2.new(0.46, 0, 0.65, 0)
		settingsFrame.Position = UDim2.new(0.5, 0, 0.18, 0)
		settingsFrame.BackgroundTransparency = 1
		settingsFrame.Parent = frame
		
		-- Bottom action buttons (Large and symmetric!)
		local bottomBar = Instance.new("Frame")
		bottomBar.Name = "BottomBar"
		bottomBar.Size = UDim2.new(0.92, 0, 0, 46) -- taller for fingers
		bottomBar.Position = UDim2.new(0.5, 0, 0.96, 0)
		bottomBar.AnchorPoint = Vector2.new(0.5, 1)
		bottomBar.BackgroundTransparency = 1
		bottomBar.Parent = frame
		
		local exitBtn = Instance.new("TextButton")
		exitBtn.Name = "ExitButton"
		exitBtn.Size = UDim2.new(0.46, 0, 1, 0)
		exitBtn.BackgroundColor3 = UIStyleConfig.Colors.RedDanger
		exitBtn.BorderSizePixel = 0
		exitBtn.Font = UIStyleConfig.Fonts.Title
		exitBtn.TextColor3 = UIStyleConfig.Colors.TextParchment
		exitBtn.TextSize = 12
		exitBtn.Text = "LEAVE PARTY ❌"
		exitBtn.Parent = bottomBar
		
		StylePanelFrame(exitBtn, false)
		ApplyHoverTransitions(exitBtn)
		TrackConnection(exitBtn.MouseButton1Click:Connect(function()
			TriggerLocalSound(UIStyleConfig.Sounds.Click)
			ExitParty:FireServer()
		end))
		
		local startBtn = Instance.new("TextButton")
		startBtn.Name = "StartButton"
		startBtn.Size = UDim2.new(0.46, 0, 1, 0)
		startBtn.Position = UDim2.new(0.54, 0, 0, 0)
		startBtn.BackgroundColor3 = UIStyleConfig.Colors.GreenSuccess
		startBtn.BorderSizePixel = 0
		startBtn.Font = UIStyleConfig.Fonts.Title
		startBtn.TextColor3 = UIStyleConfig.Colors.TextParchment
		startBtn.TextSize = 12
		startBtn.Text = "START RUN ⚔️"
		startBtn.Parent = bottomBar
		
		StylePanelFrame(startBtn, true)
		ApplyHoverTransitions(startBtn)
		TrackConnection(startBtn.MouseButton1Click:Connect(function()
			TriggerLocalSound(UIStyleConfig.Sounds.Click)
			StartPartyRun:FireServer()
		end))
	end
	
	local frame = partyGui:FindFirstChild("MainFrame")
	if frame then
		local membersFrame = frame:FindFirstChild("MembersFrame")
		local settingsFrame = frame:FindFirstChild("SettingsFrame")
		local bottomBar = frame:FindFirstChild("BottomBar")
		
		if membersFrame then PopulateMembers(membersFrame, data.Members, isLocalHost) end
		if settingsFrame then BuildSettingsControls(settingsFrame, data, isLocalHost) end
		if bottomBar then
			local startBtn = bottomBar:FindFirstChild("StartButton")
			if startBtn then startBtn.Visible = isLocalHost end
			local exitBtn = bottomBar:FindFirstChild("ExitButton")
			if exitBtn then
				exitBtn.Visible = true
				if not isLocalHost then
					exitBtn.Size = UDim2.new(1, 0, 1, 0)
				else
					exitBtn.Size = UDim2.new(0.46, 0, 1, 0)
				end
			end
		end
	end
	
	-- COUNTDOWN POP SCREEN
	if data.Status == "Countdown" then
		if not countdownOverlay then
			countdownOverlay = Instance.new("ScreenGui")
			countdownOverlay.Name = "PartyCountdownOverlay"
			countdownOverlay.ResetOnSpawn = false
			countdownOverlay.DisplayOrder = 12
			countdownOverlay.Parent = playerGui
			
			local bg = Instance.new("Frame")
			bg.Size = UDim2.new(1, 0, 1, 0)
			bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			bg.BackgroundTransparency = 0.65
			bg.BorderSizePixel = 0
			bg.Active = false
			bg.Selectable = false
			bg.Parent = countdownOverlay
			
			local overlayLabel = Instance.new("TextLabel")
			overlayLabel.Name = "CountdownNumber"
			overlayLabel.Size = UDim2.new(1, 0, 0.35, 0)
			overlayLabel.Position = UDim2.new(0, 0, 0.08, 0)
			overlayLabel.BackgroundTransparency = 1
			overlayLabel.Font = UIStyleConfig.Fonts.Title
			overlayLabel.TextColor3 = UIStyleConfig.Colors.GoldAccent
			overlayLabel.TextSize = 100
			overlayLabel.Parent = bg
			
			local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(0,0,0); stroke.Thickness = 3; stroke.Parent = overlayLabel

			local sub = Instance.new("TextLabel")
			sub.Name = "SubText"
			sub.Size = UDim2.new(1, 0, 0.08, 0)
			sub.Position = UDim2.new(0, 0, 0.45, 0)
			sub.BackgroundTransparency = 1
			sub.Font = UIStyleConfig.Fonts.BodyBold
			sub.TextColor3 = UIStyleConfig.Colors.TextParchment
			sub.TextSize = 14
			sub.Text = "PREPARING BATTLEFIELD..."
			sub.Parent = bg
		end
		
		local bg = countdownOverlay:FindFirstChildOfClass("Frame")
		local overlayLabel = bg and bg:FindFirstChild("CountdownNumber")
		if overlayLabel then
			overlayLabel.Text = tostring(data.Countdown)
			TriggerLocalSound(UIStyleConfig.Sounds.Tick)
			
			overlayLabel.TextSize = 120
			TweenService:Create(overlayLabel, TweenInfo.new(0.35, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {TextSize = 96}):Play()
		end
	else
		if countdownOverlay then countdownOverlay:Destroy(); countdownOverlay = nil end
	end
	
	-- SPINNING RUNIC LOADER Starting Screen
	if data.Status == "Starting" then
		if not loadingOverlay then
			loadingOverlay = Instance.new("ScreenGui")
			loadingOverlay.Name = "PartyLoadingOverlay"
			loadingOverlay.ResetOnSpawn = false
			loadingOverlay.DisplayOrder = 15
			loadingOverlay.Parent = playerGui
			
			local bg = Instance.new("Frame")
			bg.Size = UDim2.new(1, 0, 1, 0)
			bg.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
			bg.BorderSizePixel = 0
			bg.Parent = loadingOverlay
			
			local loader = Instance.new("ImageLabel")
			loader.Name = "RunicLoader"
			loader.Size = UDim2.new(0, 120, 0, 120)
			loader.Position = UDim2.new(0.5, 0, 0.4, 0)
			loader.AnchorPoint = Vector2.new(0.5, 0.5)
			loader.BackgroundTransparency = 1
			loader.Image = "rbxassetid://6071575923"
			loader.ImageColor3 = UIStyleConfig.Colors.BorderGold
			loader.Parent = bg
			
			task.spawn(function()
				while loader.Parent do
					loader.Rotation = (loader.Rotation + 1.5) % 360
					task.wait(0.01)
				end
			end)

			local text = Instance.new("TextLabel")
			text.Size = UDim2.new(0.8, 0, 0.1, 0)
			text.Position = UDim2.new(0.5, 0, 0.58, 0)
			text.AnchorPoint = Vector2.new(0.5, 0.5)
			text.BackgroundTransparency = 1
			text.Font = UIStyleConfig.Fonts.Title
			text.TextColor3 = UIStyleConfig.Colors.TextParchment
			text.TextSize = 16
			text.Text = "TELEPORTING TO BATTLEFIELD..."
			text.Parent = bg
			
			local subText = Instance.new("TextLabel")
			subText.Size = UDim2.new(0.6, 0, 0.05, 0)
			subText.Position = UDim2.new(0.5, 0, 0.65, 0)
			subText.AnchorPoint = Vector2.new(0.5, 0.5)
			subText.BackgroundTransparency = 1
			subText.Font = UIStyleConfig.Fonts.BodyRegular
			subText.TextColor3 = UIStyleConfig.Colors.TextSilver
			subText.TextSize = 11
			subText.Text = "DO NOT CLOSE THE GAME"
			subText.Parent = bg
		end
	else
		if loadingOverlay then loadingOverlay:Destroy(); loadingOverlay = nil end
	end
end

-- Hook Sync Remotes
SyncPartyData.OnClientEvent:Connect(SyncPartyUI)

player:GetAttributeChangedSignal("LobbyError"):Connect(function()
	local err = player:GetAttribute("LobbyError")
	if err and err ~= "" then
		ShowToast(err)
		player:SetAttribute("LobbyError", nil)
	end
end)

player:GetAttributeChangedSignal("BecameHost"):Connect(function()
	local became = player:GetAttribute("BecameHost")
	if became then
		ShowToast("YOU ARE NOW THE HOST", UIStyleConfig.Colors.GreenSuccess)
	end
end)

SyncGameState.OnClientEvent:Connect(function(data)
	if data.State == "Intermission" or data.State == "Active" then
		CleanupConnections()
		if partyGui then partyGui:Destroy(); partyGui = nil end
		if countdownOverlay then countdownOverlay:Destroy(); countdownOverlay = nil end
		if loadingOverlay then loadingOverlay:Destroy(); loadingOverlay = nil end
		previousMemberCount = 0
	end
end)

print("[PartyUIController] Medieval Lobby matching UI controllers initialized.")
