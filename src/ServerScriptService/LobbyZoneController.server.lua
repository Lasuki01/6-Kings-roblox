-- ============================================
-- LobbyZoneController.server.lua — Kingdom Siege
-- Spawns the physical Lobby with 4 independent party pads, lighting, and safety systems.
-- Side: Server
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

local LobbyConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Config"):WaitForChild("LobbyConfig"))
local PartyManager = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("PartyManager"))

local mapModel = workspace:FindFirstChild("Map") or Instance.new("Model", workspace)
mapModel.Name = "Map"

local lobbyCenter = LobbyConfig.LobbyCenter
local lobbySize = LobbyConfig.LobbySize

-- ============================
-- Helper Functions
-- ============================

local function CreatePart(name, size, pos, color, material, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = pos
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = true
	part.CastShadow = true
	part.Parent = parent
	return part
end

-- ============================
-- Lobby Platform
-- ============================

local lobbyFloor = workspace:FindFirstChild("LobbyPlatform")
if lobbyFloor then
	lobbyFloor.Parent = mapModel
	lobbyFloor.Color = Color3.fromRGB(30, 28, 35)
	lobbyFloor.Material = Enum.Material.Slate
	lobbyFloor.Size = lobbySize
	lobbyFloor.Position = lobbyCenter
else
	lobbyFloor = CreatePart(
		"LobbyPlatform",
		lobbySize,
		lobbyCenter,
		Color3.fromRGB(30, 28, 35),
		Enum.Material.Slate,
		mapModel
	)
end

-- Floor accent border ring
local borderParts = {
	{ Size = Vector3.new(lobbySize.X + 4, 0.5, 3), Offset = Vector3.new(0, 1.2, lobbySize.Z / 2 + 1.5) },
	{ Size = Vector3.new(lobbySize.X + 4, 0.5, 3), Offset = Vector3.new(0, 1.2, -lobbySize.Z / 2 - 1.5) },
	{ Size = Vector3.new(3, 0.5, lobbySize.Z + 4), Offset = Vector3.new(lobbySize.X / 2 + 1.5, 1.2, 0) },
	{ Size = Vector3.new(3, 0.5, lobbySize.Z + 4), Offset = Vector3.new(-lobbySize.X / 2 - 1.5, 1.2, 0) },
}

for i, def in ipairs(borderParts) do
	local border = CreatePart(
		"LobbyBorder_" .. i,
		def.Size,
		lobbyCenter + def.Offset,
		Color3.fromRGB(0, 100, 200),
		Enum.Material.Neon,
		mapModel
	)
	border.Transparency = 0.4
	border.CanCollide = false
end

-- ============================
-- Spawn Location
-- ============================

local spawnLoc = Instance.new("SpawnLocation")
spawnLoc.Name = "LobbySpawnLocation"
spawnLoc.Size = Vector3.new(14, 1, 14)
spawnLoc.Position = lobbyCenter + LobbyConfig.SpawnLocationOffset
spawnLoc.Color = Color3.fromRGB(0, 150, 255)
spawnLoc.Material = Enum.Material.Neon
spawnLoc.Transparency = 0.5
spawnLoc.Anchored = true
spawnLoc.CanCollide = true
spawnLoc.Neutral = true
spawnLoc.Duration = 0
spawnLoc.Parent = mapModel

-- ============================
-- Walls (taller, well-lit)
-- ============================

local wallHeight = 22
local wallThickness = 3
local wallDefs = {
	{ Size = Vector3.new(lobbySize.X + wallThickness * 2, wallHeight, wallThickness), Offset = Vector3.new(0, wallHeight / 2, lobbySize.Z / 2 + wallThickness / 2) },
	{ Size = Vector3.new(lobbySize.X + wallThickness * 2, wallHeight, wallThickness), Offset = Vector3.new(0, wallHeight / 2, -lobbySize.Z / 2 - wallThickness / 2) },
	{ Size = Vector3.new(wallThickness, wallHeight, lobbySize.Z), Offset = Vector3.new(lobbySize.X / 2 + wallThickness / 2, wallHeight / 2, 0) },
	{ Size = Vector3.new(wallThickness, wallHeight, lobbySize.Z), Offset = Vector3.new(-lobbySize.X / 2 - wallThickness / 2, wallHeight / 2, 0) },
}

for i, wDef in ipairs(wallDefs) do
	CreatePart(
		"LobbyWall_" .. i,
		wDef.Size,
		lobbyCenter + wDef.Offset,
		Color3.fromRGB(35, 35, 40),
		Enum.Material.Cobblestone,
		mapModel
	)
end

-- ============================
-- Wall Sconce Lights (every 25 studs along walls)
-- ============================

local function SpawnWallSconce(name, pos)
	local bracket = CreatePart(
		name,
		Vector3.new(1.5, 1.5, 1.5),
		pos,
		Color3.fromRGB(80, 70, 60),
		Enum.Material.Basalt,
		mapModel
	)
	
	local sconceFire = Instance.new("Fire")
	sconceFire.Size = 3
	sconceFire.Heat = 6
	sconceFire.Color = Color3.fromRGB(255, 180, 60)
	sconceFire.SecondaryColor = Color3.fromRGB(255, 100, 20)
	sconceFire.Parent = bracket
	
	local sconceLight = Instance.new("PointLight")
	sconceLight.Color = Color3.fromRGB(255, 200, 100)
	sconceLight.Range = 30
	sconceLight.Brightness = 2.0
	sconceLight.Parent = bracket
end

-- Place sconces along all 4 walls
local halfX = lobbySize.X / 2
local halfZ = lobbySize.Z / 2
local sconceY = lobbyCenter.Y + 10
local sconceSpacing = 25
local sconceIdx = 0

-- North and South walls
for x = -halfX + sconceSpacing, halfX - sconceSpacing, sconceSpacing do
	sconceIdx = sconceIdx + 1
	SpawnWallSconce("Sconce_N_" .. sconceIdx, Vector3.new(lobbyCenter.X + x, sconceY, lobbyCenter.Z + halfZ - 2))
	SpawnWallSconce("Sconce_S_" .. sconceIdx, Vector3.new(lobbyCenter.X + x, sconceY, lobbyCenter.Z - halfZ + 2))
end

-- East and West walls
for z = -halfZ + sconceSpacing, halfZ - sconceSpacing, sconceSpacing do
	sconceIdx = sconceIdx + 1
	SpawnWallSconce("Sconce_E_" .. sconceIdx, Vector3.new(lobbyCenter.X + halfX - 2, sconceY, lobbyCenter.Z + z))
	SpawnWallSconce("Sconce_W_" .. sconceIdx, Vector3.new(lobbyCenter.X - halfX + 2, sconceY, lobbyCenter.Z + z))
end

-- ============================
-- Ambient Overhead Lights (4 ceiling clusters)
-- ============================

local ceilingOffsets = {
	Vector3.new(-30, 25, -30),
	Vector3.new(30, 25, -30),
	Vector3.new(-30, 25, 30),
	Vector3.new(30, 25, 30),
}

for i, offset in ipairs(ceilingOffsets) do
	local ceilingLight = Instance.new("PointLight")
	ceilingLight.Color = Color3.fromRGB(200, 220, 255)
	ceilingLight.Range = 60
	ceilingLight.Brightness = 1.5
	
	local anchor = CreatePart(
		"CeilingLight_" .. i,
		Vector3.new(2, 1, 2),
		lobbyCenter + offset,
		Color3.fromRGB(200, 220, 255),
		Enum.Material.Neon,
		mapModel
	)
	anchor.Transparency = 0.6
	anchor.CanCollide = false
	ceilingLight.Parent = anchor
end

-- Central ambient uplighter
local centerLight = Instance.new("PointLight")
centerLight.Color = Color3.fromRGB(180, 200, 255)
centerLight.Range = 80
centerLight.Brightness = 1.0

local centerAnchor = CreatePart(
	"CenterAmbientLight",
	Vector3.new(3, 0.5, 3),
	lobbyCenter + Vector3.new(0, 1.5, 0),
	Color3.fromRGB(180, 200, 255),
	Enum.Material.Neon,
	mapModel
)
centerAnchor.Transparency = 0.7
centerAnchor.CanCollide = false
centerLight.Parent = centerAnchor

-- ============================
-- Central Decorative Brazier
-- ============================

local brazier = CreatePart(
	"LobbyBrazier",
	Vector3.new(5, 4, 5),
	lobbyCenter + Vector3.new(0, 3, 0),
	Color3.fromRGB(120, 110, 100),
	Enum.Material.Basalt,
	mapModel
)

local fire = Instance.new("Fire")
fire.Size = 10
fire.Heat = 14
fire.Color = Color3.fromRGB(0, 180, 255)
fire.SecondaryColor = Color3.fromRGB(0, 80, 255)
fire.Parent = brazier

local brazierLight = Instance.new("PointLight")
brazierLight.Color = Color3.fromRGB(0, 180, 255)
brazierLight.Range = 40
brazierLight.Brightness = 2.5
brazierLight.Parent = brazier

-- ============================
-- Safety Floor (catches falling players)
-- ============================

local safetyFloor = CreatePart(
	"SafetyFloor",
	Vector3.new(1000, 1, 1000),
	Vector3.new(lobbyCenter.X, LobbyConfig.SafetyFloorY, lobbyCenter.Z),
	Color3.fromRGB(255, 0, 0),
	Enum.Material.Neon,
	mapModel
)
safetyFloor.Transparency = 1
safetyFloor.CanCollide = false

local safetyTouchConn = safetyFloor.Touched:Connect(function(hit)
	local character = hit.Parent
	if not character then return end
	
	-- Only process safety teleport during Lobby phase
	local gameState = workspace:GetAttribute("GameState") or "Lobby"
	if gameState ~= "Lobby" then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end
	
	-- Teleport back to lobby spawn
	rootPart.CFrame = CFrame.new(lobbyCenter + LobbyConfig.SpawnLocationOffset + Vector3.new(0, 3, 0))
	print("[LobbyZoneController] Safety floor caught falling player, teleported back to lobby.")
end)

-- ============================
-- Party Pads (4 independent pads)
-- ============================

local padData = {} -- [padId] = { part, ring, billboard, statusLabel, detailsLabel }

for padId = 1, LobbyConfig.NUM_PARTY_PADS do
	local padOffset = LobbyConfig.PartyPadOffsets[padId]
	local padColor = LobbyConfig.PadColors[padId]
	local padPos = lobbyCenter + padOffset
	
	-- Main pad
	local pad = CreatePart(
		"PartyZonePad_" .. padId,
		LobbyConfig.PadSize,
		padPos,
		padColor,
		Enum.Material.Neon,
		mapModel
	)
	pad.CanCollide = false
	pad.Transparency = 0.3
	
	-- Pad edge glow ring
	local ring = CreatePart(
		"PadRing_" .. padId,
		Vector3.new(LobbyConfig.PadSize.X + 2, 0.2, LobbyConfig.PadSize.Z + 2),
		padPos - Vector3.new(0, 0.1, 0),
		Color3.new(padColor.R * 0.6, padColor.G * 0.6, padColor.B * 0.6),
		Enum.Material.Neon,
		mapModel
	)
	ring.CanCollide = false
	ring.Transparency = 0.5
	
	-- Pad number indicator on floor
	local numIndicator = Instance.new("SurfaceGui")
	numIndicator.Name = "PadNumber"
	numIndicator.Face = Enum.NormalId.Top
	numIndicator.Parent = pad
	
	local numLabel = Instance.new("TextLabel")
	numLabel.Size = UDim2.new(1, 0, 1, 0)
	numLabel.BackgroundTransparency = 1
	numLabel.Font = Enum.Font.GothamBold
	numLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	numLabel.TextSize = 80
	numLabel.Text = tostring(padId)
	numLabel.TextTransparency = 0.6
	numLabel.Parent = numIndicator
	
	-- Particle emitter
	local particles = Instance.new("ParticleEmitter")
	particles.Rate = 12
	particles.Lifetime = NumberRange.new(1.5, 3)
	particles.Speed = NumberRange.new(1, 3)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Color = ColorSequence.new(padColor, Color3.new(
		math.min(padColor.R + 0.3, 1),
		math.min(padColor.G + 0.3, 1),
		math.min(padColor.B + 0.3, 1)
	))
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.5, 0.4),
		NumberSequenceKeypoint.new(1, 0),
	})
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	particles.LightEmission = 1
	particles.Parent = pad
	
	-- Billboard
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PadBillboard_" .. padId
	billboard.Adornee = pad
	billboard.Size = UDim2.new(0, 260, 0, 90)
	billboard.StudsOffset = Vector3.new(0, 7, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = pad
	
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, 0, 0.5, 0)
	statusLabel.Position = UDim2.new(0, 0, 0, 0)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	statusLabel.TextSize = 18
	statusLabel.Text = "⚔️ PARTY PAD #" .. padId
	statusLabel.Parent = billboard
	
	local detailsLabel = Instance.new("TextLabel")
	detailsLabel.Size = UDim2.new(1, 0, 0.5, 0)
	detailsLabel.Position = UDim2.new(0, 0, 0.5, 0)
	detailsLabel.BackgroundTransparency = 1
	detailsLabel.Font = Enum.Font.Gotham
	detailsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	detailsLabel.TextSize = 13
	detailsLabel.Text = "STEP HERE TO JOIN"
	detailsLabel.Parent = billboard
	
	-- Corner pillars for this pad (2 front corners)
	local pillarOffsets = {
		Vector3.new(-LobbyConfig.PadSize.X / 2 - 2, 0, -LobbyConfig.PadSize.Z / 2 - 2),
		Vector3.new(LobbyConfig.PadSize.X / 2 + 2, 0, -LobbyConfig.PadSize.Z / 2 - 2),
	}
	
	for pIdx, pOff in ipairs(pillarOffsets) do
		local pillar = CreatePart(
			"PadPillar_" .. padId .. "_" .. pIdx,
			Vector3.new(2, 8, 2),
			padPos + pOff + Vector3.new(0, 4.5, 0),
			Color3.fromRGB(50, 45, 45),
			Enum.Material.Basalt,
			mapModel
		)
		
		local bowl = CreatePart(
			"PadBowl_" .. padId .. "_" .. pIdx,
			Vector3.new(3, 1.2, 3),
			padPos + pOff + Vector3.new(0, 9, 0),
			Color3.fromRGB(70, 60, 55),
			Enum.Material.Basalt,
			mapModel
		)
		bowl.Shape = Enum.PartType.Cylinder
		bowl.Orientation = Vector3.new(0, 0, 90)
		
		local pillarFire = Instance.new("Fire")
		pillarFire.Size = 4
		pillarFire.Heat = 7
		pillarFire.Color = padColor
		pillarFire.SecondaryColor = Color3.new(
			math.max(padColor.R - 0.2, 0),
			math.max(padColor.G - 0.2, 0),
			math.max(padColor.B - 0.2, 0)
		)
		pillarFire.Parent = bowl
		
		local pillarLight = Instance.new("PointLight")
		pillarLight.Color = padColor
		pillarLight.Range = 16
		pillarLight.Brightness = 1.5
		pillarLight.Parent = bowl
	end
	
	-- Pulsing glow animation
	task.spawn(function()
		local pulseUp = TweenService:Create(pad, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.15})
		local pulseDown = TweenService:Create(pad, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.5})
		local ringUp = TweenService:Create(ring, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.3})
		local ringDown = TweenService:Create(ring, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.7})
		
		while true do
			pulseUp:Play()
			ringUp:Play()
			pulseUp.Completed:Wait()
			pulseDown:Play()
			ringDown:Play()
			pulseDown.Completed:Wait()
		end
	end)
	
	padData[padId] = {
		part = pad,
		ring = ring,
		billboard = billboard,
		statusLabel = statusLabel,
		detailsLabel = detailsLabel,
		baseColor = padColor,
	}
end

-- ============================
-- Proximity Checking Loop (all 4 pads)
-- ============================

task.spawn(function()
	while true do
		task.wait(1)
		
		for padId = 1, LobbyConfig.NUM_PARTY_PADS do
			local pd = padData[padId]
			local pad = pd.part
			local party = PartyManager:GetParty(padId)
			
			-- Bounding box check for this pad
			local padPos = pad.Position
			local halfX = pad.Size.X / 2
			local halfZ = pad.Size.Z / 2
			
			for _, p in ipairs(Players:GetPlayers()) do
				local char = p.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if root then
					local pos = root.Position
					local diffX = math.abs(pos.X - padPos.X)
					local diffZ = math.abs(pos.Z - padPos.Z)
					local diffY = pos.Y - padPos.Y
					
					if diffX <= halfX + 1 and diffZ <= halfZ + 1 and diffY >= -3 and diffY <= 6 then
						-- Player is standing on this pad
						local existingPad = PartyManager:GetPlayerParty(p)
						
						if not existingPad then
							-- Not in any party — try joining this one
							if not party then
								PartyManager:CreateParty(padId, p)
								party = PartyManager:GetParty(padId)
							else
								if party.Status == "Starting" then
									p:SetAttribute("LobbyError", "Match Starting")
									local character = p.Character
									local rootPart = character and character:FindFirstChild("HumanoidRootPart")
									if rootPart then
										rootPart.CFrame = CFrame.new(lobbyCenter + LobbyConfig.ExitTeleportOffset)
									end
								elseif #party.Members >= party.MaxPlayers then
									p:SetAttribute("LobbyError", "Party Full")
									local character = p.Character
									local rootPart = character and character:FindFirstChild("HumanoidRootPart")
									if rootPart then
										rootPart.CFrame = CFrame.new(lobbyCenter + LobbyConfig.ExitTeleportOffset)
									end
								else
									PartyManager:JoinParty(padId, p)
								end
							end
						end
						-- If player already in THIS pad's party, do nothing (good)
						-- If player in ANOTHER pad's party, do nothing (they need to leave first)
					end
				end
			end
			
			-- Update billboard for this pad
			party = PartyManager:GetParty(padId)
			if party then
				pd.statusLabel.Text = "👑 " .. (party.Host.DisplayName or party.Host.Name)
				pd.detailsLabel.Text = #party.Members .. " / " .. party.MaxPlayers .. "  •  PAD #" .. padId .. "  •  " .. party.Status:upper()
				
				if party.Status == "Countdown" then
					pd.part.Color = Color3.fromRGB(255, 180, 0)
					pd.ring.Color = Color3.fromRGB(200, 140, 0)
				elseif party.Status == "Starting" then
					pd.part.Color = Color3.fromRGB(255, 60, 60)
					pd.ring.Color = Color3.fromRGB(200, 40, 40)
				else
					pd.part.Color = Color3.fromRGB(0, 200, 80) -- Active green
					pd.ring.Color = Color3.fromRGB(0, 140, 60)
				end
			else
				pd.statusLabel.Text = "⚔️ PARTY PAD #" .. padId
				pd.detailsLabel.Text = "STEP HERE TO JOIN"
				pd.part.Color = pd.baseColor
				pd.ring.Color = Color3.new(pd.baseColor.R * 0.6, pd.baseColor.G * 0.6, pd.baseColor.B * 0.6)
			end
		end
	end
end)

print("[LobbyZoneController] Multi-pad lobby spawned (" .. LobbyConfig.NUM_PARTY_PADS .. " pads). Monitoring proximity.")
