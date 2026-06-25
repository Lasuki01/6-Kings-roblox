-- ============================================
-- MapManager.server.lua — Kingdom Siege
-- Procedurally sets up the game map, Castle Keep, crenellated walls, watchtowers, altars, gates, portals, lit torches, tombstones, hills, and lava cracks.
-- Side: Server
-- ============================================

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

-- Configuration Constants
local CRYSTAL_MAX_HP = 1000
local PATH_WIDTH = 16
local PATH_HEIGHT = 1.0

-- Helper: Create a styled part
local function CreatePart(name, size, position, color, material, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- Helper: Add golden SelectionBox highlight
local function AddHighlight(part)
	local highlight = Instance.new("SelectionBox")
	highlight.Color3 = Color3.fromRGB(230, 180, 50)
	highlight.Adornee = part
	highlight.Parent = part
end

-- Helper: Create visual path segments aligned along cardinal axes
local function CreateGridSegment(name, p1, p2, color, material, parent)
	local x1, z1 = p1.X, p1.Z
	local x2, z2 = p2.X, p2.Z

	local dx = math.abs(x2 - x1)
	local dz = math.abs(z2 - z1)

	local size, center

	if dx < 0.1 then
		-- North/South segment (runs along Z)
		size = Vector3.new(PATH_WIDTH, 1, dz)
		center = Vector3.new(x1, PATH_HEIGHT, (z1 + z2) / 2)
	else
		-- East/West segment (runs along X)
		size = Vector3.new(dx, 1, PATH_WIDTH)
		center = Vector3.new((x1 + x2) / 2, PATH_HEIGHT, z1)
	end

	local pathFloor = CreatePart(name, size, center, color, material, parent)
	pathFloor.CastShadow = false
	return pathFloor
end

-- Helper: Spawn medieval torches flanking a path segment
local function SpawnTorch(name, position, parent)
	local base = CreatePart(
		"TorchBase", 
		Vector3.new(2, 1.5, 2), 
		position + Vector3.new(0, 0.75, 0), -- Y top = 1.5
		Color3.fromRGB(100, 100, 105), 
		Enum.Material.Slate, 
		parent
	)
	base.CastShadow = true

	local pole = CreatePart(
		"TorchPole", 
		Vector3.new(0.6, 4.0, 0.6), 
		position + Vector3.new(0, 3.5, 0), -- Y center = 3.5
		Color3.fromRGB(101, 67, 33), 
		Enum.Material.Wood, 
		parent
	)

	local bracket = CreatePart(
		"TorchBracket", 
		Vector3.new(1.2, 0.6, 1.2), 
		position + Vector3.new(0, 5.8, 0), 
		Color3.fromRGB(50, 50, 50), 
		Enum.Material.Metal, 
		parent
	)

	local flame = CreatePart(
		"TorchFlame", 
		Vector3.new(1.0, 1.5, 1.0), 
		position + Vector3.new(0, 6.8, 0), 
		Color3.fromRGB(255, 120, 0), 
		Enum.Material.Neon, 
		parent
	)
	flame.CanCollide = false

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 160, 50)
	light.Range = 25
	light.Brightness = 2.5
	light.Shadows = true
	light.Parent = flame
	
	local fire = Instance.new("Fire")
	fire.Color = Color3.fromRGB(255, 100, 0)
	fire.SecondaryColor = Color3.fromRGB(255, 200, 50)
	fire.Heat = 9
	fire.Size = 4
	fire.Parent = flame
end

-- Helper: Add detailed battlements/crenellations on top of walls
local function AddWallCrenellations(wallPart, parent)
	local size = wallPart.Size
	local pos = wallPart.Position
	local height = size.Y
	local topY = pos.Y + height / 2

	local isZAxis = size.Z > size.X
	local length = isZAxis and size.Z or size.X
	local wallWidth = isZAxis and size.X or size.Z

	local blockLength = 4
	local gapLength = 4
	local step = blockLength + gapLength
	
	local halfL = length / 2
	local current = -halfL + blockLength / 2

	while current < halfL do
		local cPos
		local cSize
		if isZAxis then
			cPos = Vector3.new(pos.X, topY + 1.25, pos.Z + current)
			cSize = Vector3.new(wallWidth, 2.5, blockLength)
		else
			cPos = Vector3.new(pos.X + current, topY + 1.25, pos.Z)
			cSize = Vector3.new(blockLength, 2.5, wallWidth)
		end

		local block = CreatePart("WallCrenellation", cSize, cPos, wallPart.Color, wallPart.Material, parent)
		block.CastShadow = true
		current = current + step
	end
end

-- Helper: Add watchtower peaks and crystal frames
local function DecorateWatchtower(towerPart, parent)
	local size = towerPart.Size
	local pos = towerPart.Position
	local topY = pos.Y + size.Y / 2 -- Top Y is 24

	-- Stacked slate roof structure
	local r1 = CreatePart("TowerRoofTier1", Vector3.new(14, 2, 14), Vector3.new(pos.X, topY + 1, pos.Z), towerPart.Color, Enum.Material.Slate, parent)
	local r2 = CreatePart("TowerRoofTier2", Vector3.new(10, 2, 10), Vector3.new(pos.X, topY + 3, pos.Z), towerPart.Color, Enum.Material.Slate, parent)
	local r3 = CreatePart("TowerRoofTier3", Vector3.new(6, 2, 6), Vector3.new(pos.X, topY + 5, pos.Z), towerPart.Color, Enum.Material.Slate, parent)
	
	r1.CastShadow = true
	r2.CastShadow = true
	r3.CastShadow = true

	local crystal = CreatePart(
		"WatchtowerCrystal",
		Vector3.new(2, 4, 2),
		Vector3.new(pos.X, topY + 8, pos.Z),
		Color3.fromRGB(0, 255, 255),
		Enum.Material.Neon,
		parent
	)
	crystal.CanCollide = false
	
	local selectionBox = Instance.new("SelectionBox")
	selectionBox.Color3 = Color3.fromRGB(0, 180, 255)
	selectionBox.Adornee = crystal
	selectionBox.Parent = crystal

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(0, 255, 255)
	light.Range = 30
	light.Brightness = 1.5
	light.Parent = crystal
end

-- Helper: Spawn environment props offset from paths without overlaps
local function SpawnBiomeProps(posL, posR, dir, pathName, segmentIndex, detailsFolder)
	if pathName == "ForestPath" then
		-- Parallel wooden fence on the Right
		local fence = CreatePart(
			"ForestFence_" .. segmentIndex,
			Vector3.new(2, 4, 16),
			posR + Vector3.new(0, 2, 0),
			Color3.fromRGB(139, 90, 43),
			Enum.Material.Wood,
			detailsFolder
		)
		fence.CastShadow = true
		-- Align fence rotation parallel to path direction
		fence.CFrame = CFrame.new(fence.Position, fence.Position + dir)

	elseif pathName == "UndeadPath" then
		-- Slanted slate grave marker on Left
		local headstoneL = CreatePart(
			"TombstoneL_" .. segmentIndex,
			Vector3.new(1.5, 4, 3),
			posL + Vector3.new(0, 2, 0),
			Color3.fromRGB(90, 90, 95),
			Enum.Material.Slate,
			detailsFolder
		)
		headstoneL.CastShadow = true
		headstoneL.CFrame = CFrame.new(headstoneL.Position, headstoneL.Position + dir) 
			* CFrame.Angles(math.rad(10), math.rad(math.random(-25, 25)), 0)

		-- Slate grave cross on Right
		local crossPos = posR + Vector3.new(0, 2, 0)
		local crossV = CreatePart("CrossV_" .. segmentIndex, Vector3.new(0.6, 3.5, 0.6), crossPos, Color3.fromRGB(70, 70, 75), Enum.Material.Slate, detailsFolder)
		local crossH = CreatePart("CrossH_" .. segmentIndex, Vector3.new(0.6, 0.6, 2.0), crossPos + Vector3.new(0, 0.8, 0), Color3.fromRGB(70, 70, 75), Enum.Material.Slate, detailsFolder)
		crossV.CastShadow = true
		crossH.CastShadow = true
		
		local cf = CFrame.new(crossPos, crossPos + dir) * CFrame.Angles(0, math.rad(math.random(-15, 15)), math.rad(5))
		crossV.CFrame = cf
		crossH.CFrame = cf * CFrame.new(0, 0.8, 0)

	elseif pathName == "DragonPass" then
		-- Glowing lava crack parallel to the path on Left
		local crack = CreatePart(
			"LavaCrack_" .. segmentIndex,
			Vector3.new(4, 0.2, 16),
			posL + Vector3.new(0, 0.05, 0),
			Color3.fromRGB(255, 60, 0),
			Enum.Material.Neon,
			detailsFolder
		)
		crack.CanCollide = false
		crack.CastShadow = false
		crack.CFrame = CFrame.new(crack.Position, crack.Position + dir)

		-- Slanted dark volcanic basalt column on Right
		local basalt = CreatePart(
			"BasaltColumn_" .. segmentIndex,
			Vector3.new(4, 12, 4),
			posR + Vector3.new(0, 6, 0),
			Color3.fromRGB(30, 25, 25),
			Enum.Material.Basalt,
			detailsFolder
		)
		basalt.CastShadow = true
		basalt.CFrame = CFrame.new(basalt.Position, basalt.Position + dir) 
			* CFrame.Angles(math.rad(math.random(-15, 15)), 0, math.rad(math.random(-15, 15)))
	end
end

-- Mathematically place pedestals and torches flanking segments at non-overlapping distances
local function DecoratePathSegment(p1, p2, pathName, segmentIndex, pathFolder, placementFolder, detailsFolder)
	local x1, z1 = p1.X, p1.Z
	local x2, z2 = p2.X, p2.Z

	local dx = x2 - x1
	local dz = z2 - z1
	local length = math.sqrt(dx * dx + dz * dz)
	local dir = Vector3.new(dx, 0, dz).Unit
	local perp = Vector3.new(-dir.Z, 0, dir.X)

	local pedestalOffset = PATH_WIDTH / 2 + 6
	local torchOffset = PATH_WIDTH / 2 + 1.5
	local propOffset = PATH_WIDTH / 2 + 15

	-- Alternating longitudinal positions along the segment length to prevent overlapping
	if length >= 80 then
		-- Torches at 10, 45, 70
		local torchDists = {10, 45, 70}
		for _, td in ipairs(torchDists) do
			local centerPos = p1 + dir * td
			SpawnTorch("Torch_L_" .. math.floor(td), centerPos + perp * torchOffset, pathFolder)
			SpawnTorch("Torch_R_" .. math.floor(td), centerPos - perp * torchOffset, pathFolder)
		end

		local spawnTwoPairsOfPedestals = (segmentIndex == 1)

		if spawnTwoPairsOfPedestals then
			-- Pedestals at 25 and 55
			local pedDists = {25, 55}
			for _, pd in ipairs(pedDists) do
				local centerPos = p1 + dir * pd
				local pedL = CreatePart("PlacementZone_" .. pathName .. "_" .. segmentIndex .. "_L_" .. math.floor(pd), Vector3.new(12, 3, 12), centerPos + perp * pedestalOffset + Vector3.new(0, 1.0, 0), Color3.fromRGB(195, 175, 145), Enum.Material.Cobblestone, placementFolder)
				CollectionService:AddTag(pedL, "PlacementZone")
				pedL.CastShadow = true
				AddHighlight(pedL)

				local pedR = CreatePart("PlacementZone_" .. pathName .. "_" .. segmentIndex .. "_R_" .. math.floor(pd), Vector3.new(12, 3, 12), centerPos - perp * pedestalOffset + Vector3.new(0, 1.0, 0), Color3.fromRGB(195, 175, 145), Enum.Material.Cobblestone, placementFolder)
				CollectionService:AddTag(pedR, "PlacementZone")
				pedR.CastShadow = true
				AddHighlight(pedR)
			end

			-- Environment details at 40 (perfectly in between pedestals)
			local propDist = 40
			local centerPos = p1 + dir * propDist
			SpawnBiomeProps(centerPos + perp * propOffset, centerPos - perp * propOffset, dir, pathName, segmentIndex, detailsFolder)
		else
			-- Spawn only 1 pair of pedestals at the midpoint (40)
			local pedDist = length / 2
			local centerPos = p1 + dir * pedDist
			local pedL = CreatePart("PlacementZone_" .. pathName .. "_" .. segmentIndex .. "_L_mid", Vector3.new(12, 3, 12), centerPos + perp * pedestalOffset + Vector3.new(0, 1.0, 0), Color3.fromRGB(195, 175, 145), Enum.Material.Cobblestone, placementFolder)
			CollectionService:AddTag(pedL, "PlacementZone")
			pedL.CastShadow = true
			AddHighlight(pedL)

			local pedR = CreatePart("PlacementZone_" .. pathName .. "_" .. segmentIndex .. "_R_mid", Vector3.new(12, 3, 12), centerPos - perp * pedestalOffset + Vector3.new(0, 1.0, 0), Color3.fromRGB(195, 175, 145), Enum.Material.Cobblestone, placementFolder)
			CollectionService:AddTag(pedR, "PlacementZone")
			pedR.CastShadow = true
			AddHighlight(pedR)

			-- Environment details at 25 and 55 (clear of the center pedestal)
			local propDists = {25, 55}
			for _, pd in ipairs(propDists) do
				local propPos = p1 + dir * pd
				SpawnBiomeProps(propPos + perp * propOffset, propPos - perp * propOffset, dir, pathName, segmentIndex, detailsFolder)
			end
		end

	else
		-- Short segment (< 80 studs)
		-- Torches at 8 and length - 8
		if length > 20 then
			SpawnTorch("Torch_L_start", p1 + dir * 8 + perp * torchOffset, pathFolder)
			SpawnTorch("Torch_R_start", p1 + dir * 8 - perp * torchOffset, pathFolder)
			SpawnTorch("Torch_L_end", p1 + dir * (length - 8) + perp * torchOffset, pathFolder)
			SpawnTorch("Torch_R_end", p1 + dir * (length - 8) - perp * torchOffset, pathFolder)
		end

		-- Pedestals at midpoint
		local pd = length / 2
		local centerPos = p1 + dir * pd
		local pedL = CreatePart("PlacementZone_" .. pathName .. "_" .. segmentIndex .. "_L_mid", Vector3.new(12, 3, 12), centerPos + perp * pedestalOffset + Vector3.new(0, 1.0, 0), Color3.fromRGB(195, 175, 145), Enum.Material.Cobblestone, placementFolder)
		CollectionService:AddTag(pedL, "PlacementZone")
		pedL.CastShadow = true
		AddHighlight(pedL)

		local pedR = CreatePart("PlacementZone_" .. pathName .. "_" .. segmentIndex .. "_R_mid", Vector3.new(12, 3, 12), centerPos - perp * pedestalOffset + Vector3.new(0, 1.0, 0), Color3.fromRGB(195, 175, 145), Enum.Material.Cobblestone, placementFolder)
		CollectionService:AddTag(pedR, "PlacementZone")
		pedR.CastShadow = true
		AddHighlight(pedR)

		-- Environment details at 12 and length - 12 (if length >= 40)
		if length >= 40 then
			SpawnBiomeProps(p1 + dir * 12 + perp * propOffset, p1 + dir * (length - 12) - perp * propOffset, dir, pathName, segmentIndex, detailsFolder)
		end
	end
end

-- Setup lighting and atmosphere for a medieval fantasy aesthetic
local function SetupAtmosphere()
	Lighting.Ambient = Color3.fromRGB(28, 25, 38)
	Lighting.OutdoorAmbient = Color3.fromRGB(48, 38, 52)
	Lighting.Brightness = 1.8
	Lighting.ClockTime = 18.0
	Lighting.GlobalShadows = true

	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Parent = Lighting
	end
	atmosphere.Density = 0.28
	atmosphere.Color = Color3.fromRGB(150, 110, 80)
	atmosphere.Glare = 0.05
	atmosphere.Haze = 1.2

	Lighting.FogColor = Color3.fromRGB(28, 25, 35)
	Lighting.FogEnd = 600
	Lighting.FogStart = 50
end

-- Setup the map
local function InitializeMap()
	-- Prevent double creation
	local existingMap = workspace:FindFirstChild("Map")
	if existingMap then
		existingMap:Destroy()
	end
	
	local existingCrystal = workspace:FindFirstChild("KingdomCrystal")
	if existingCrystal then
		existingCrystal:Destroy()
	end

	print("Rebuilding Mathematically Perfect Kingdom Siege Map...")

	local mapModel = Instance.new("Model")
	mapModel.Name = "Map"
	mapModel.Parent = workspace

	-- 1. Create The Castle Keep (Center raised stone base, Y top = 4)
	local keepBase = CreatePart(
		"CastleKeepBase",
		Vector3.new(100, 4, 100),
		Vector3.new(0, 2, 0),
		Color3.fromRGB(110, 110, 115),
		Enum.Material.Rock,
		mapModel
	)
	keepBase.CastShadow = true

	-- Castle Walls around the Keep (Y = 4 to Y = 16)
	local wallColor = Color3.fromRGB(90, 90, 95)
	local wallMaterial = Enum.Material.Slate
	
	-- North Wall (solid, no entrances)
	local wallN = CreatePart("WallNorth", Vector3.new(100, 12, 6), Vector3.new(0, 10, -47), wallColor, wallMaterial, mapModel)
	AddWallCrenellations(wallN, mapModel)
	
	-- West Wall (leaves gap at Z = -15 to Z = 15 for Forest Path entrance)
	local wallWN = CreatePart("WallWestNorth", Vector3.new(6, 12, 35), Vector3.new(-47, 10, -32.5), wallColor, wallMaterial, mapModel)
	local wallWS = CreatePart("WallWestSouth", Vector3.new(6, 12, 35), Vector3.new(-47, 10, 32.5), wallColor, wallMaterial, mapModel)
	AddWallCrenellations(wallWN, mapModel)
	AddWallCrenellations(wallWS, mapModel)
	
	-- East Wall (leaves gap at Z = -15 to Z = 15 for Undead Path entrance)
	local wallEN = CreatePart("WallEastNorth", Vector3.new(6, 12, 35), Vector3.new(47, 10, -32.5), wallColor, wallMaterial, mapModel)
	local wallES = CreatePart("WallEastSouth", Vector3.new(6, 12, 35), Vector3.new(47, 10, 32.5), wallColor, wallMaterial, mapModel)
	AddWallCrenellations(wallEN, mapModel)
	AddWallCrenellations(wallES, mapModel)
	
	-- South Wall (leaves gap at X = -15 to X = 15 for Dragon Pass entrance)
	local wallSW = CreatePart("WallSouthWest", Vector3.new(35, 12, 6), Vector3.new(-32.5, 10, 47), wallColor, wallMaterial, mapModel)
	local wallSE = CreatePart("WallSouthEast", Vector3.new(35, 12, 6), Vector3.new(32.5, 10, 47), wallColor, wallMaterial, mapModel)
	AddWallCrenellations(wallSW, mapModel)
	AddWallCrenellations(wallSE, mapModel)
	
	-- Keep Corners Watchtowers
	local towerColor = Color3.fromRGB(70, 70, 75)
	local tNW = CreatePart("CornerTowerNW", Vector3.new(12, 24, 12), Vector3.new(-45, 12, -45), towerColor, Enum.Material.Slate, mapModel)
	local tNE = CreatePart("CornerTowerNE", Vector3.new(12, 24, 12), Vector3.new(45, 12, -45), towerColor, Enum.Material.Slate, mapModel)
	local tSW = CreatePart("CornerTowerSW", Vector3.new(12, 24, 12), Vector3.new(-45, 12, 45), towerColor, Enum.Material.Slate, mapModel)
	local tSE = CreatePart("CornerTowerSE", Vector3.new(12, 24, 12), Vector3.new(45, 12, 45), towerColor, Enum.Material.Slate, mapModel)
	
	DecorateWatchtower(tNW, mapModel)
	DecorateWatchtower(tNE, mapModel)
	DecorateWatchtower(tSW, mapModel)
	DecorateWatchtower(tSE, mapModel)

	-- 2. Create the tiered Altar for the Kingdom Crystal (Center of Keep, Y top = 10)
	local altarColor = Color3.fromRGB(150, 150, 160)
	local altarMaterial = Enum.Material.Marble
	
	local altar1 = CreatePart("AltarTier1", Vector3.new(36, 2, 36), Vector3.new(0, 5, 0), altarColor, altarMaterial, mapModel)
	local altar2 = CreatePart("AltarTier2", Vector3.new(24, 2, 24), Vector3.new(0, 7, 0), altarColor, altarMaterial, mapModel)
	local altar3 = CreatePart("AltarTier3", Vector3.new(12, 2, 12), Vector3.new(0, 9, 0), altarColor, altarMaterial, mapModel)
	
	altar1.CastShadow = true
	altar2.CastShadow = true
	altar3.CastShadow = true

	-- Kingdom Crystal (Y bottom = 10, center Y = 16)
	local crystal = CreatePart(
		"KingdomCrystal",
		Vector3.new(6, 12, 6),
		Vector3.new(0, 16, 0),
		Color3.fromRGB(0, 200, 255),
		Enum.Material.Neon,
		workspace
	)
	crystal.CanCollide = true
	crystal.CastShadow = false

	-- Crystal HP IntValue
	local hpValue = Instance.new("IntValue")
	hpValue.Name = "CrystalHP"
	hpValue.Value = CRYSTAL_MAX_HP
	hpValue.Parent = crystal

	local selectionBox = Instance.new("SelectionBox")
	selectionBox.Color3 = Color3.fromRGB(0, 255, 255)
	selectionBox.Adornee = crystal
	selectionBox.Parent = crystal

	-- 3. Setup Paths, Pedestals, Torches, and Environmental details
	local pathsFolder = Instance.new("Folder")
	pathsFolder.Name = "Paths"
	pathsFolder.Parent = mapModel

	local placementFolder = Instance.new("Folder")
	placementFolder.Name = "PlacementZones"
	placementFolder.Parent = mapModel

	local detailsFolder = Instance.new("Folder")
	detailsFolder.Name = "EnvironmentDetails"
	detailsFolder.Parent = mapModel

	-- Clean, grid-aligned paths
	local forestWaypoints = {
		Vector3.new(-200, 0.5, 0),
		Vector3.new(-120, 0.5, 0),
		Vector3.new(-50, 0.5, 0),
		Vector3.new(-30, 2.5, 0),
		Vector3.new(0, 8.5, 0)
	}

	local undeadWaypoints = {
		Vector3.new(200, 0.5, 0),
		Vector3.new(120, 0.5, 0),
		Vector3.new(50, 0.5, 0),
		Vector3.new(30, 2.5, 0),
		Vector3.new(0, 8.5, 0)
	}

	local dragonWaypoints = {
		Vector3.new(0, 0.5, 200),
		Vector3.new(0, 0.5, 120),
		Vector3.new(0, 0.5, 50),
		Vector3.new(0, 2.5, 30),
		Vector3.new(0, 8.5, 0)
	}

	local pathData = {
		ForestPath = {
			Color = Color3.fromRGB(56, 108, 62),
			Material = Enum.Material.Pebble,
			Waypoints = forestWaypoints,
			Spawn = forestWaypoints[1],
			PortalColor = Color3.fromRGB(121, 85, 72)
		},
		UndeadPath = {
			Color = Color3.fromRGB(64, 72, 80),
			Material = Enum.Material.Slate,
			Waypoints = undeadWaypoints,
			Spawn = undeadWaypoints[1],
			PortalColor = Color3.fromRGB(103, 58, 183)
		},
		DragonPass = {
			Color = Color3.fromRGB(130, 30, 10),
			Material = Enum.Material.CrackedLava,
			Waypoints = dragonWaypoints,
			Spawn = dragonWaypoints[1],
			PortalColor = Color3.fromRGB(244, 67, 54)
		}
	}

	for pathName, data in pairs(pathData) do
		local pathFolder = Instance.new("Folder")
		pathFolder.Name = pathName
		pathFolder.Parent = pathsFolder

		-- Waypoints folder
		local waypointsFolder = Instance.new("Folder")
		waypointsFolder.Name = "Waypoints"
		waypointsFolder.Parent = pathFolder

		-- Spawn point part
		local spawnPart = CreatePart(
			"SpawnPoint",
			Vector3.new(16, 2, 16),
			data.Spawn + Vector3.new(0, 1.0, 0),
			data.PortalColor,
			Enum.Material.Neon,
			pathFolder
		)
		spawnPart.Transparency = 0.4
		CollectionService:AddTag(spawnPart, "EnemySpawn")
		spawnPart:SetAttribute("PathName", pathName)

		-- Generate visual path segments (outside keep)
		local rampStartIdx = 3
		for i = 1, rampStartIdx - 1 do
			local p1 = data.Waypoints[i]
			local p2 = data.Waypoints[i + 1]
			CreateGridSegment("PathSegment_" .. i, p1, p2, data.Color, data.Material, pathFolder)
			
			-- Decorate this segment symmetrically
			DecoratePathSegment(p1, p2, pathName, i, pathFolder, placementFolder, detailsFolder)
		end

		-- Create Ramp rising through the wall opening to the Keep
		local pStart = data.Waypoints[rampStartIdx]
		local pEnd = data.Waypoints[rampStartIdx + 1]
		local distance = (pEnd - pStart).Magnitude
		local center = (pStart + pEnd) / 2 + Vector3.new(0, 0.75, 0)
		
		local isZAxis = math.abs(pEnd.X - pStart.X) < 0.1

		local ramp = Instance.new("WedgePart")
		ramp.Name = "KeepEntranceRamp"
		ramp.Color = data.Color
		ramp.Material = data.Material
		ramp.Size = Vector3.new(PATH_WIDTH, 3.0, distance)
		ramp.Anchored = true
		ramp.CanCollide = true
		ramp.Parent = pathFolder

		if isZAxis then
			if pEnd.Z > pStart.Z then
				ramp.CFrame = CFrame.new(center) * CFrame.Angles(0, math.pi, 0)
			else
				ramp.CFrame = CFrame.new(center)
			end
		else
			if pEnd.X > pStart.X then
				ramp.CFrame = CFrame.new(center) * CFrame.Angles(0, -math.pi / 2, 0)
			else
				ramp.CFrame = CFrame.new(center) * CFrame.Angles(0, math.pi / 2, 0)
			end
		end

		-- Flat visual path segments inside Keep
		local pRampExit = data.Waypoints[rampStartIdx + 1]
		local pAltarBase = data.Waypoints[#data.Waypoints]
		
		local keepSegmentLength = (pAltarBase - pRampExit).Magnitude - 18
		local keepPathDirection = (pAltarBase - pRampExit).Unit
		local keepPathEnd = pRampExit + keepPathDirection * keepSegmentLength
		
		local keepPathCenter = (pRampExit + keepPathEnd) / 2 + Vector3.new(0, 1.5, 0)
		local keepPathFloorSize
		if isZAxis then
			keepPathFloorSize = Vector3.new(PATH_WIDTH, 0.1, keepSegmentLength)
		else
			keepPathFloorSize = Vector3.new(keepSegmentLength, 0.1, PATH_WIDTH)
		end
		
		local keepPathFloor = CreatePart("KeepInsidePath", keepPathFloorSize, keepPathCenter, data.Color, data.Material, pathFolder)
		keepPathFloor.CastShadow = false

		-- Generate Waypoint parts (for script movements)
		for i, pointPos in ipairs(data.Waypoints) do
			local wp = CreatePart(
				"Waypoint_" .. i,
				Vector3.new(4, 4, 4),
				pointPos + Vector3.new(0, 2.5, 0),
				Color3.fromRGB(255, 255, 255),
				Enum.Material.SmoothPlastic,
				waypointsFolder
			)
			wp.Transparency = 0.9
			wp.CanCollide = false
			wp.CastShadow = false
		end

		-- Portal Gatehouses
		local portalCenter = data.Spawn + Vector3.new(0, 8, 0)
		if pathName == "ForestPath" then
			-- Rustic Log Gatehouse
			CreatePart("ForestPillarLeft", Vector3.new(4, 16, 4), portalCenter + Vector3.new(0, 0, -10), Color3.fromRGB(93, 64, 55), Enum.Material.Wood, pathFolder)
			CreatePart("ForestPillarRight", Vector3.new(4, 16, 4), portalCenter + Vector3.new(0, 0, 10), Color3.fromRGB(93, 64, 55), Enum.Material.Wood, pathFolder)
			CreatePart("ForestLintel", Vector3.new(4, 4, 24), portalCenter + Vector3.new(0, 8, 0), Color3.fromRGB(141, 110, 99), Enum.Material.Wood, pathFolder)
		elseif pathName == "UndeadPath" then
			-- Crypt Arch Portal
			CreatePart("CryptPillarLeft", Vector3.new(4, 16, 4), portalCenter + Vector3.new(0, 0, -10), Color3.fromRGB(50, 50, 55), Enum.Material.Slate, pathFolder)
			CreatePart("CryptPillarRight", Vector3.new(4, 16, 4), portalCenter + Vector3.new(0, 0, 10), Color3.fromRGB(50, 50, 55), Enum.Material.Slate, pathFolder)
			local lintel = CreatePart("CryptArch", Vector3.new(4, 4, 24), portalCenter + Vector3.new(0, 8, 0), Color3.fromRGB(50, 50, 55), Enum.Material.Slate, pathFolder)
			local glow = CreatePart("CryptGlow", Vector3.new(2, 1, 20), portalCenter + Vector3.new(0, 6, 0), Color3.fromRGB(150, 50, 255), Enum.Material.Neon, pathFolder)
			glow.CanCollide = false
		elseif pathName == "DragonPass" then
			-- Obsidian volcanic portal (at Z = 200)
			CreatePart("DragonPillarLeft", Vector3.new(6, 18, 6), portalCenter + Vector3.new(-12, 0, 0), Color3.fromRGB(20, 20, 25), Enum.Material.Basalt, pathFolder)
			CreatePart("DragonPillarRight", Vector3.new(6, 18, 6), portalCenter + Vector3.new(12, 0, 0), Color3.fromRGB(20, 20, 25), Enum.Material.Basalt, pathFolder)
			CreatePart("DragonLintel", Vector3.new(30, 6, 6), portalCenter + Vector3.new(0, 9, 0), Color3.fromRGB(20, 20, 25), Enum.Material.Basalt, pathFolder)
			
			-- The massive iron gate portcullis blocking the portal (destructible at Wave 10, size 18 wide, 18 tall, 2 thick)
			local gate = CreatePart(
				"DragonGate",
				Vector3.new(18, 18, 2),
				portalCenter + Vector3.new(0, 1, 0), -- Y center = 8.5 + 1.0 = 9.5 -> bottom rests on path floor (Y = 0.5)
				Color3.fromRGB(70, 30, 30),
				Enum.Material.CorrodedMetal,
				pathFolder
			)
			gate.Name = "DragonGate"
			gate.CastShadow = true
		end
	end

	-- 4. Create Castle Interior Corner Pedestals (Symmetrical inside Keep floor)
	local interiorPedestals = {
		Vector3.new(-35, 4.5, -35),
		Vector3.new(35, 4.5, -35),
		Vector3.new(-35, 4.5, 35),
		Vector3.new(35, 4.5, 35)
	}

	for i, pos in ipairs(interiorPedestals) do
		local ped = CreatePart(
			"PlacementZone_Interior_" .. i,
			Vector3.new(12, 1, 12), -- flat on Keep floor
			pos,
			Color3.fromRGB(195, 175, 145),
			Enum.Material.Cobblestone,
			placementFolder
		)
		CollectionService:AddTag(ped, "PlacementZone")
		ped.CastShadow = true
		AddHighlight(ped)
	end

	print("Symmetrical High-Quality Map Rebuild Complete!")
end

-- Run Setup
SetupAtmosphere()
InitializeMap()
