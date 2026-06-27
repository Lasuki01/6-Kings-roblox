-- ============================================
-- MapManager.server.lua — Kingdom Siege
-- Procedurally sets up the game map, Castle Keep, crenellated walls, watchtowers, altars, gates, portals, lit torches, tombstones, hills, and lava cracks.
-- Side: Server
-- ============================================

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration modules
local Config = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Config")
local EconomyConfig = require(Config:WaitForChild("EconomyConfig"))

-- Configuration Constants
local CRYSTAL_MAX_HP = EconomyConfig.CRYSTAL_MAX_HP
local PATH_WIDTH = 16
local PATH_HEIGHT = 3.5

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

-- Helper: Setup portal plane with particles and light
local function CreatePortalEffects(name, size, cf, color, particleColor1, particleColor2, parent)
	local portalPlane = Instance.new("Part")
	portalPlane.Name = name
	portalPlane.Size = size
	portalPlane.CFrame = cf
	portalPlane.Color = color
	portalPlane.Material = Enum.Material.Neon
	portalPlane.Transparency = 0.5
	portalPlane.CanCollide = false
	portalPlane.CastShadow = false
	portalPlane.TopSurface = Enum.SurfaceType.Smooth
	portalPlane.BottomSurface = Enum.SurfaceType.Smooth
	portalPlane.Anchored = true
	portalPlane.Parent = parent

	-- Point light
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 24
	light.Brightness = 3.0
	light.Shadows = true
	light.Parent = portalPlane

	-- Particle emitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(particleColor1, particleColor2)
	emitter.LightEmission = 1.0
	emitter.Rate = 75 -- High rate for active look
	emitter.Speed = NumberRange.new(4, 9) -- Shoots outwards
	emitter.Lifetime = NumberRange.new(1.0, 2.0)
	
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.15, 1.5),
		NumberSequenceKeypoint.new(0.8, 1.0),
		NumberSequenceKeypoint.new(1, 0)
	})
	
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.15, 0.2),
		NumberSequenceKeypoint.new(0.8, 0.2),
		NumberSequenceKeypoint.new(1, 1)
	})
	
	emitter.SpreadAngle = Vector2.new(25, 25)
	emitter.Acceleration = Vector3.new(0, 3, 0) -- floats up slightly as it moves out
	emitter.EmissionDirection = Enum.NormalId.Front -- shoot out from flat front face
	emitter.Texture = "rbxassetid://258122325"
	emitter.Parent = portalPlane

	return portalPlane
end

-- Helper: Interpolate between two colors
local function InterpolateColor(c1, c2, fraction)
	return Color3.new(
		c1.R + (c2.R - c1.R) * fraction,
		c1.G + (c2.G - c1.G) * fraction,
		c1.B + (c2.B - c1.B) * fraction
	)
end

-- Helper: Spawn corner basalt fortress towers with magma veins and themed glowing crystal tridents
local function SpawnCornerTower(pos, crystalColor, parent)
	local tower = CreatePart("OuterCornerTower", Vector3.new(10, 32, 10), pos + Vector3.new(0, 14, 0), Color3.fromRGB(20, 20, 25), Enum.Material.Basalt, parent)
	tower.CastShadow = true
	
	local spire = CreatePart("OuterCornerSpire", Vector3.new(6, 10, 6), pos + Vector3.new(0, 35, 0), Color3.fromRGB(15, 15, 18), Enum.Material.Basalt, parent)
	
	-- Veins on the corner tower match the crystal/trident color of the tower
	local veinColor = crystalColor
	CreatePart("MagmaVein", Vector3.new(0.6, 26, 0.6), pos + Vector3.new(4.8, 11, 0), veinColor, Enum.Material.Neon, parent)
	CreatePart("MagmaVein", Vector3.new(0.6, 26, 0.6), pos + Vector3.new(-4.8, 11, 0), veinColor, Enum.Material.Neon, parent)
	CreatePart("MagmaVein", Vector3.new(0.6, 26, 0.6), pos + Vector3.new(0, 11, 4.8), veinColor, Enum.Material.Neon, parent)
	CreatePart("MagmaVein", Vector3.new(0.6, 26, 0.6), pos + Vector3.new(0, 11, -4.8), veinColor, Enum.Material.Neon, parent)

	-- Spindle/base of the trident crystal (Y top of spire is Y = 42)
	-- Use CFrame.lookAt to align the trident's local front face (-Z axis) directly facing the central crystal
	local tridentPos = pos + Vector3.new(0, 40, 0)
	local tridentBaseCF = CFrame.lookAt(tridentPos, Vector3.new(0, tridentPos.Y, 0))

	-- Helper to create parts relative to the trident's local CFrame
	local function CreateTridentPart(name, size, relativeCF, color, material)
		local part = CreatePart(name, size, Vector3.new(0, 0, 0), color, material, parent)
		part.CFrame = tridentBaseCF * relativeCF
		part.CanCollide = false
		part.CastShadow = false
		return part
	end

	-- Helper to create wedges relative to the trident's local CFrame
	local function CreateTridentWedge(name, size, relativeCF, color, material)
		local wedge = Instance.new("WedgePart")
		wedge.Name = name
		wedge.Size = size
		wedge.Color = color
		wedge.Material = material
		wedge.Anchored = true
		wedge.CanCollide = false
		wedge.CastShadow = false
		wedge.CFrame = tridentBaseCF * relativeCF
		wedge.Parent = parent
		return wedge
	end

	-- 1. Shaft / Spindle (tall cylinders/blocks rising from spire)
	CreateTridentPart("TridentShaftLower", Vector3.new(2.5, 6, 2.5), CFrame.new(0, 3, 0), crystalColor, Enum.Material.Neon)
	CreateTridentPart("TridentShaftRing", Vector3.new(3.5, 1, 3.5), CFrame.new(0, 5.5, 0), crystalColor, Enum.Material.Neon)

	-- 2. Central Core (large glowing sphere)
	local core = CreateTridentPart("TridentCore", Vector3.new(4, 4, 4), CFrame.new(0, 8, 0), crystalColor, Enum.Material.Neon)
	core.Shape = Enum.PartType.Ball

	-- 3. Winged/Curved Crossbar (angled upward arms)
	CreateTridentPart("TridentCrossbarL", Vector3.new(6, 2, 2), CFrame.new(-2.5, 8.5, 0) * CFrame.Angles(0, 0, math.rad(15)), crystalColor, Enum.Material.Neon)
	CreateTridentPart("TridentCrossbarR", Vector3.new(6, 2, 2), CFrame.new(2.5, 8.5, 0) * CFrame.Angles(0, 0, math.rad(-15)), crystalColor, Enum.Material.Neon)

	-- 4. Central Prong (massive vertical middle spike)
	CreateTridentPart("TridentProngCenterLower", Vector3.new(2.5, 18, 2.5), CFrame.new(0, 17, 0), crystalColor, Enum.Material.Neon)
	-- Wedge tip pointing straight up (WedgePart slants along its local Z, so rotate 90 deg around Y)
	CreateTridentWedge("TridentProngCenterTip", Vector3.new(2.5, 5, 2.5), CFrame.new(0, 28.5, 0) * CFrame.Angles(0, math.rad(90), 0), crystalColor, Enum.Material.Neon)

	-- 5. Left Prong (curves out and up, with outer spike barb)
	-- Base angled out
	CreateTridentPart("TridentProngLBase", Vector3.new(2.2, 8, 2.2), CFrame.new(-6, 13, 0) * CFrame.Angles(0, 0, math.rad(-25)), crystalColor, Enum.Material.Neon)
	-- Mid angled back in slightly to point up
	CreateTridentPart("TridentProngLMid", Vector3.new(1.8, 12, 1.8), CFrame.new(-7.5, 22, 0) * CFrame.Angles(0, 0, math.rad(5)), crystalColor, Enum.Material.Neon)
	-- Wedge tip pointing straight up
	CreateTridentWedge("TridentProngLTip", Vector3.new(1.8, 5, 1.8), CFrame.new(-7, 30.5, 0) * CFrame.Angles(0, math.rad(90), 0), crystalColor, Enum.Material.Neon)
	-- Evil outer barb pointing out
	CreateTridentPart("TridentProngLBarb", Vector3.new(1.2, 4, 1.2), CFrame.new(-8.5, 17, 0) * CFrame.Angles(0, 0, math.rad(-60)), crystalColor, Enum.Material.Neon)

	-- 6. Right Prong (curves out and up, with outer spike barb)
	-- Base angled out
	CreateTridentPart("TridentProngRBase", Vector3.new(2.2, 8, 2.2), CFrame.new(6, 13, 0) * CFrame.Angles(0, 0, math.rad(25)), crystalColor, Enum.Material.Neon)
	-- Mid angled back in slightly to point up
	CreateTridentPart("TridentProngRMid", Vector3.new(1.8, 12, 1.8), CFrame.new(7.5, 22, 0) * CFrame.Angles(0, 0, math.rad(-5)), crystalColor, Enum.Material.Neon)
	-- Wedge tip pointing straight up
	CreateTridentWedge("TridentProngRTip", Vector3.new(1.8, 5, 1.8), CFrame.new(7, 30.5, 0) * CFrame.Angles(0, math.rad(90), 0), crystalColor, Enum.Material.Neon)
	-- Evil outer barb pointing out
	CreateTridentPart("TridentProngRBarb", Vector3.new(1.2, 4, 1.2), CFrame.new(8.5, 17, 0) * CFrame.Angles(0, 0, math.rad(60)), crystalColor, Enum.Material.Neon)
end

-- Helper: Spawn devilish lamps on outer walls
local function SpawnDevilishLamp(position, direction, parent)
	local bracket = CreatePart("LampBracket", Vector3.new(1.2, 1.2, 1.2), position + direction * 0.6, Color3.fromRGB(30, 25, 25), Enum.Material.Basalt, parent)
	local bulb = CreatePart("LampBulb", Vector3.new(1.0, 1.6, 1.0), position + direction * 1.5, Color3.fromRGB(255, 80, 0), Enum.Material.Neon, parent)
	bulb.CanCollide = false
	
	local fire = Instance.new("Fire")
	fire.Color = Color3.fromRGB(255, 60, 0)
	fire.SecondaryColor = Color3.fromRGB(255, 150, 0)
	fire.Size = 3
	fire.Heat = 5
	fire.Parent = bulb
	
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 100, 0)
	light.Range = 25
	light.Brightness = 2.0
	light.Shadows = true
	light.Parent = bulb
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

	-- Castle-themed stone fire brazier
	local base = CreatePart(
		"BrazierBase",
		Vector3.new(3.5, 1.5, 3.5),
		Vector3.new(pos.X, topY + 6.75, pos.Z),
		Color3.fromRGB(40, 40, 45),
		Enum.Material.Slate,
		parent
	)
	base.CastShadow = true

	local bowl = CreatePart(
		"BrazierBowl",
		Vector3.new(2.5, 0.8, 2.5),
		Vector3.new(pos.X, topY + 7.5, pos.Z),
		Color3.fromRGB(20, 20, 22),
		Enum.Material.CorrodedMetal,
		parent
	)
	bowl.CanCollide = false
	bowl.CastShadow = false

	local fire = Instance.new("Fire")
	fire.Color = Color3.fromRGB(255, 100, 20)
	fire.SecondaryColor = Color3.fromRGB(255, 200, 50)
	fire.Size = 4
	fire.Heat = 6
	fire.Parent = bowl

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 120, 30)
	light.Range = 35
	light.Brightness = 2.0
	light.Shadows = true
	light.Parent = bowl
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

	-- Outer Enclosing Walls (400x400 perimeter, Y height = 24, Y center = 12, thickness = 6)
	local outerWallColor = Color3.fromRGB(80, 80, 85)
	local outerWallMaterial = Enum.Material.Slate
	local outerWallHeight = 24
	local outerWallY = 12
	local outerWallThickness = 6

	-- Helper: Create and crenellate an outer wall segment, with glowing magma veins on the inner face
	-- Helper: Create and crenellate an outer wall segment, with devilish lamps on the inner face
	local function BuildOuterWallSegment(name, size, position, isZAxis)
		local wall = CreatePart(name, size, position, outerWallColor, outerWallMaterial, mapModel)
		wall.CastShadow = true
		AddWallCrenellations(wall, mapModel)
		
		-- Generate devilish lamps on the inner face of the wall segment
		local wallHeight = size.Y
		local wallLength = isZAxis and size.Z or size.X
		local thickness = size.X > size.Z and size.Z or size.X
		
		-- Place lamps spaced along the wall length
		local step = 35
		local current = -wallLength / 2 + 15
		while current < wallLength / 2 - 10 do
			local lampOffset
			local lampDirection
			
			if isZAxis then
				-- If X < 0 (West Wall), points in +X direction. If X > 0 (East Wall), points in -X direction.
				local directionSign = (position.X < 0) and 1 or -1
				lampDirection = Vector3.new(directionSign, 0, 0)
				
				local xOffset = directionSign * (thickness / 2)
				lampOffset = Vector3.new(xOffset, 0, current)
			else
				-- If Z < 0 (North Wall), points in +Z direction. If Z > 0 (South Wall), points in -Z direction.
				local directionSign = (position.Z < 0) and 1 or -1
				lampDirection = Vector3.new(0, 0, directionSign)
				
				local zOffset = directionSign * (thickness / 2)
				lampOffset = Vector3.new(current, 0, zOffset)
			end
			
			-- Position is Y = 12 (halfway up the wall)
			local lampPos = position + lampOffset
			SpawnDevilishLamp(lampPos, lampDirection, mapModel)
			
			current = current + step
		end
		
		return wall
	end

	-- 1. North Wall (Solid, Z = -200)
	BuildOuterWallSegment(
		"OuterWallNorth",
		Vector3.new(406, outerWallHeight, outerWallThickness),
		Vector3.new(0, outerWallY, -200),
		false
	)

	-- 2. South Wall (Z = 200, splits at X = -15 to 15 for Dragon Gate)
	BuildOuterWallSegment(
		"OuterWallSouthWest",
		Vector3.new(188, outerWallHeight, outerWallThickness),
		Vector3.new(-109, outerWallY, 200),
		false
	)
	BuildOuterWallSegment(
		"OuterWallSouthEast",
		Vector3.new(188, outerWallHeight, outerWallThickness),
		Vector3.new(109, outerWallY, 200),
		false
	)

	-- 3. West Wall (X = -200, splits at Z = -12 to 12 for Forest Gate)
	BuildOuterWallSegment(
		"OuterWallWestNorth",
		Vector3.new(outerWallThickness, outerWallHeight, 185),
		Vector3.new(-200, outerWallY, -104.5),
		true
	)
	BuildOuterWallSegment(
		"OuterWallWestSouth",
		Vector3.new(outerWallThickness, outerWallHeight, 185),
		Vector3.new(-200, outerWallY, 104.5),
		true
	)

	-- 4. East Wall (X = 200, splits at Z = -12 to 12 for Undead Gate)
	BuildOuterWallSegment(
		"OuterWallEastNorth",
		Vector3.new(outerWallThickness, outerWallHeight, 185),
		Vector3.new(200, outerWallY, -104.5),
		true
	)
	BuildOuterWallSegment(
		"OuterWallEastSouth",
		Vector3.new(outerWallThickness, outerWallHeight, 185),
		Vector3.new(200, outerWallY, 104.5),
		true
	)

	-- Spawn 4 corner basalt spires with magma veins and themed glowing crystal tridents
	-- NW: Violet/Magenta, NE: Corrupt Green, SW: Crimson Red, SE: Cyan Ice Blue
	SpawnCornerTower(Vector3.new(-200, 2, -200), Color3.fromRGB(150, 0, 255), mapModel)
	SpawnCornerTower(Vector3.new(200, 2, -200), Color3.fromRGB(0, 220, 50), mapModel)
	SpawnCornerTower(Vector3.new(-200, 2, 200), Color3.fromRGB(255, 30, 0), mapModel)
	SpawnCornerTower(Vector3.new(200, 2, 200), Color3.fromRGB(0, 180, 255), mapModel)

	-- 2. Create the tiered Altar for the Kingdom Crystal (Center of Keep, Y top = 10)
	local altarColor = Color3.fromRGB(150, 150, 160)
	local altarMaterial = Enum.Material.Marble
	
	local altar1 = CreatePart("AltarTier1", Vector3.new(36, 2, 36), Vector3.new(0, 5, 0), altarColor, altarMaterial, mapModel)
	local altar2 = CreatePart("AltarTier2", Vector3.new(24, 2, 24), Vector3.new(0, 7, 0), altarColor, altarMaterial, mapModel)
	local altar3 = CreatePart("AltarTier3", Vector3.new(12, 2, 12), Vector3.new(0, 9, 0), altarColor, altarMaterial, mapModel)
	
	altar1.CastShadow = true
	altar2.CastShadow = true
	altar3.CastShadow = true

	-- Spawn invisible ramps over the altar stairs so Goblins and other enemies climb physically
	local rampsFolder = Instance.new("Folder")
	rampsFolder.Name = "AltarRamps"
	rampsFolder.Parent = mapModel

	local function CreateRamp(name, size, pos, rotationY)
		local ramp = Instance.new("WedgePart")
		ramp.Name = name
		ramp.Size = size
		ramp.Position = pos
		ramp.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(rotationY), 0)
		ramp.Transparency = 1 -- completely invisible
		ramp.CanCollide = true
		ramp.Anchored = true
		ramp.CastShadow = false
		ramp.TopSurface = Enum.SurfaceType.Smooth
		ramp.BottomSurface = Enum.SurfaceType.Smooth
		ramp.Parent = rampsFolder
		return ramp
	end

	-- West Ramp: climbs from West (-X) to East (+X), thin end at X = -21, thick end at X = -5
	CreateRamp("AltarRampWest", Vector3.new(16, 6, 16), Vector3.new(-13, 7, 0), 90)

	-- East Ramp: climbs from East (+X) to West (-X), thin end at X = 21, thick end at X = 5
	CreateRamp("AltarRampEast", Vector3.new(16, 6, 16), Vector3.new(13, 7, 0), -90)

	-- South Ramp: climbs from South (+Z) to North (-Z), thin end at Z = 21, thick end at Z = 5
	CreateRamp("AltarRampSouth", Vector3.new(16, 6, 16), Vector3.new(0, 7, 13), 180)

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

	-- Add subtle blue glow to the Kingdom Crystal
	local crystalLight = Instance.new("PointLight")
	crystalLight.Color = Color3.fromRGB(0, 200, 255)
	crystalLight.Range = 45
	crystalLight.Brightness = 1.5
	crystalLight.Shadows = true
	crystalLight.Parent = crystal

	-- Add 4 torches at the corners of the Castle Keep floor for subtle illumination
	local keepTorches = {
		Vector3.new(-42, 4.0, -42),
		Vector3.new(42, 4.0, -42),
		Vector3.new(-42, 4.0, 42),
		Vector3.new(42, 4.0, 42)
	}
	for i, pos in ipairs(keepTorches) do
		SpawnTorch("KeepTorch_" .. i, pos, mapModel)
	end

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

	-- Clean, grid-aligned paths (elevated to Keep floor level Y = 4.0)
	local forestWaypoints = {
		Vector3.new(-200, 4.0, 0),
		Vector3.new(-120, 4.0, 0),
		Vector3.new(-50, 4.0, 0),
		Vector3.new(-30, 4.0, 0),
		Vector3.new(0, 8.5, 0)
	}

	local undeadWaypoints = {
		Vector3.new(200, 4.0, 0),
		Vector3.new(120, 4.0, 0),
		Vector3.new(50, 4.0, 0),
		Vector3.new(30, 4.0, 0),
		Vector3.new(0, 8.5, 0)
	}

	local dragonWaypoints = {
		Vector3.new(0, 4.0, 200),
		Vector3.new(0, 4.0, 120),
		Vector3.new(0, 4.0, 50),
		Vector3.new(0, 4.0, 30),
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

		-- Visual paths end at Castle Keep entrances. Waypoints are retained for logic.

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
			-- Corrupted Log Pillars and Lintel
			local pL = CreatePart("ForestPillarLeft", Vector3.new(4, 18, 4), portalCenter + Vector3.new(0, 1, -10), Color3.fromRGB(40, 30, 25), Enum.Material.Wood, pathFolder)
			local pR = CreatePart("ForestPillarRight", Vector3.new(4, 18, 4), portalCenter + Vector3.new(0, 1, 10), Color3.fromRGB(40, 30, 25), Enum.Material.Wood, pathFolder)
			local lintel = CreatePart("ForestLintel", Vector3.new(4, 4, 24), portalCenter + Vector3.new(0, 10, 0), Color3.fromRGB(50, 40, 35), Enum.Material.Wood, pathFolder)
			
			-- Glowing neon green thorns protruding outwards
			local thornSpecs = {
				-- Left pillar thorns
				{Pos = portalCenter + Vector3.new(0, -2, -11.5), Size = Vector3.new(1.2, 4, 1.2), Rot = CFrame.Angles(0, 0, math.rad(-35))},
				{Pos = portalCenter + Vector3.new(0, 3, -11.5), Size = Vector3.new(1.0, 3.5, 1.0), Rot = CFrame.Angles(math.rad(15), 0, math.rad(-50))},
				-- Right pillar thorns
				{Pos = portalCenter + Vector3.new(0, -2, 11.5), Size = Vector3.new(1.2, 4, 1.2), Rot = CFrame.Angles(0, 0, math.rad(35))},
				{Pos = portalCenter + Vector3.new(0, 3, 11.5), Size = Vector3.new(1.0, 3.5, 1.0), Rot = CFrame.Angles(math.rad(-15), 0, math.rad(50))},
				-- Lintel top thorns
				{Pos = portalCenter + Vector3.new(0, 12, -6), Size = Vector3.new(1.0, 4, 1.0), Rot = CFrame.Angles(0, 0, math.rad(-25))},
				{Pos = portalCenter + Vector3.new(0, 12, 6), Size = Vector3.new(1.0, 4, 1.0), Rot = CFrame.Angles(0, 0, math.rad(25))}
			}
			for i, spec in ipairs(thornSpecs) do
				local thorn = CreatePart("ForestThorn_" .. i, spec.Size, spec.Pos, Color3.fromRGB(50, 255, 50), Enum.Material.Neon, pathFolder)
				thorn.CanCollide = false
				thorn.CFrame = CFrame.new(spec.Pos) * spec.Rot
			end

			-- Portal Plane (facing down the path: +X direction)
			local spawnDir = Vector3.new(1, 0, 0)
			local cf = CFrame.lookAt(portalCenter - spawnDir * 0.5, portalCenter + spawnDir * 0.5)
			CreatePortalEffects(
				"ForestPortalPlane",
				Vector3.new(16, 16, 0.5),
				cf,
				Color3.fromRGB(0, 220, 50),
				Color3.fromRGB(50, 255, 100),
				Color3.fromRGB(0, 120, 30),
				pathFolder
			)
		elseif pathName == "UndeadPath" then
			-- Crypt Pillars, Lintel and Spires
			local pL = CreatePart("CryptPillarLeft", Vector3.new(4, 18, 4), portalCenter + Vector3.new(0, 1, -10), Color3.fromRGB(25, 25, 30), Enum.Material.Slate, pathFolder)
			local pR = CreatePart("CryptPillarRight", Vector3.new(4, 18, 4), portalCenter + Vector3.new(0, 1, 10), Color3.fromRGB(25, 25, 30), Enum.Material.Slate, pathFolder)
			local lintel = CreatePart("CryptArch", Vector3.new(4, 4, 24), portalCenter + Vector3.new(0, 10, 0), Color3.fromRGB(30, 30, 35), Enum.Material.Slate, pathFolder)
			
			-- Gothic pointed stone spires on top of pillars
			local spireL = CreatePart("CryptSpireLeft", Vector3.new(3, 6, 3), portalCenter + Vector3.new(0, 13, -10), Color3.fromRGB(20, 20, 25), Enum.Material.Slate, pathFolder)
			local spireR = CreatePart("CryptSpireRight", Vector3.new(3, 6, 3), portalCenter + Vector3.new(0, 13, 10), Color3.fromRGB(20, 20, 25), Enum.Material.Slate, pathFolder)
			
			-- Bone rib cage decorations flanking the gate
			local ribColor = Color3.fromRGB(220, 215, 200)
			local ribMaterial = Enum.Material.SmoothPlastic
			local ribSpecs = {
				-- Left ribs curving towards the keep (X is negative direction)
				{Pos = portalCenter + Vector3.new(-2, -3, -9), Size = Vector3.new(4, 1.2, 1.2), Rot = CFrame.Angles(0, math.rad(-30), math.rad(25))},
				{Pos = portalCenter + Vector3.new(-3, 1, -9), Size = Vector3.new(5, 1.2, 1.2), Rot = CFrame.Angles(0, math.rad(-45), math.rad(15))},
				{Pos = portalCenter + Vector3.new(-2, 5, -9), Size = Vector3.new(4, 1.2, 1.2), Rot = CFrame.Angles(0, math.rad(-30), math.rad(5))},
				
				-- Right ribs curving towards the keep
				{Pos = portalCenter + Vector3.new(-2, -3, 9), Size = Vector3.new(4, 1.2, 1.2), Rot = CFrame.Angles(0, math.rad(30), math.rad(25))},
				{Pos = portalCenter + Vector3.new(-3, 1, 9), Size = Vector3.new(5, 1.2, 1.2), Rot = CFrame.Angles(0, math.rad(45), math.rad(15))},
				{Pos = portalCenter + Vector3.new(-2, 5, 9), Size = Vector3.new(4, 1.2, 1.2), Rot = CFrame.Angles(0, math.rad(30), math.rad(5))}
			}
			for i, spec in ipairs(ribSpecs) do
				local rib = CreatePart("CryptBone_" .. i, spec.Size, spec.Pos, ribColor, ribMaterial, pathFolder)
				rib.CanCollide = false
				rib.CFrame = CFrame.new(spec.Pos) * spec.Rot
			end

			-- Portal Plane (facing down the path: -X direction)
			local spawnDir = Vector3.new(-1, 0, 0)
			local cf = CFrame.lookAt(portalCenter - spawnDir * 0.5, portalCenter + spawnDir * 0.5)
			CreatePortalEffects(
				"CryptPortalPlane",
				Vector3.new(16, 16, 0.5),
				cf,
				Color3.fromRGB(130, 0, 255),
				Color3.fromRGB(220, 100, 255),
				Color3.fromRGB(80, 0, 150),
				pathFolder
			)
		elseif pathName == "DragonPass" then
			-- Volcanic Basalt Pillars, Lintel, and Magma Cracks
			local pL = CreatePart("DragonPillarLeft", Vector3.new(6, 20, 6), portalCenter + Vector3.new(-12, 1, 0), Color3.fromRGB(15, 15, 18), Enum.Material.Basalt, pathFolder)
			local pR = CreatePart("DragonPillarRight", Vector3.new(6, 20, 6), portalCenter + Vector3.new(12, 1, 0), Color3.fromRGB(15, 15, 18), Enum.Material.Basalt, pathFolder)
			local lintel = CreatePart("DragonLintel", Vector3.new(30, 6, 6), portalCenter + Vector3.new(0, 11, 0), Color3.fromRGB(20, 18, 20), Enum.Material.Basalt, pathFolder)
			
			-- Glowing magma veins on pillars
			local veinColor = Color3.fromRGB(255, 60, 0)
			CreatePart("MagmaVeinL1", Vector3.new(0.6, 14, 0.2), portalCenter + Vector3.new(-12, 1, -3.1), veinColor, Enum.Material.Neon, pathFolder)
			CreatePart("MagmaVeinL2", Vector3.new(0.6, 10, 0.2), portalCenter + Vector3.new(-13.5, -1, -3.1), veinColor, Enum.Material.Neon, pathFolder)
			CreatePart("MagmaVeinR1", Vector3.new(0.6, 14, 0.2), portalCenter + Vector3.new(12, 1, -3.1), veinColor, Enum.Material.Neon, pathFolder)
			CreatePart("MagmaVeinR2", Vector3.new(0.6, 10, 0.2), portalCenter + Vector3.new(13.5, -1, -3.1), veinColor, Enum.Material.Neon, pathFolder)

			-- Left Demon Horn
			local hL1 = CreatePart("HornL1", Vector3.new(4, 6, 4), portalCenter + Vector3.new(-10, 16.5, 0), Color3.fromRGB(15, 15, 18), Enum.Material.Basalt, pathFolder)
			hL1.CFrame = CFrame.new(portalCenter + Vector3.new(-10, 16.5, 0)) * CFrame.Angles(0, 0, math.rad(-20))
			local hL2 = CreatePart("HornL2", Vector3.new(3, 5, 3), portalCenter + Vector3.new(-8, 21.5, 0), Color3.fromRGB(15, 15, 18), Enum.Material.Basalt, pathFolder)
			hL2.CFrame = hL1.CFrame * CFrame.new(0, 5, 0) * CFrame.Angles(0, 0, math.rad(-20))
			local hL3 = CreatePart("HornL3", Vector3.new(2, 4, 2), portalCenter + Vector3.new(-5, 25.5, 0), Color3.fromRGB(255, 60, 0), Enum.Material.Neon, pathFolder)
			hL3.CFrame = hL2.CFrame * CFrame.new(0, 4, 0) * CFrame.Angles(0, 0, math.rad(-25))

			-- Right Demon Horn
			local hR1 = CreatePart("HornR1", Vector3.new(4, 6, 4), portalCenter + Vector3.new(10, 16.5, 0), Color3.fromRGB(15, 15, 18), Enum.Material.Basalt, pathFolder)
			hR1.CFrame = CFrame.new(portalCenter + Vector3.new(10, 16.5, 0)) * CFrame.Angles(0, 0, math.rad(20))
			local hR2 = CreatePart("HornR2", Vector3.new(3, 5, 3), portalCenter + Vector3.new(8, 21.5, 0), Color3.fromRGB(15, 15, 18), Enum.Material.Basalt, pathFolder)
			hR2.CFrame = hR1.CFrame * CFrame.new(0, 5, 0) * CFrame.Angles(0, 0, math.rad(20))
			local hR3 = CreatePart("HornR3", Vector3.new(2, 4, 2), portalCenter + Vector3.new(5, 25.5, 0), Color3.fromRGB(255, 60, 0), Enum.Material.Neon, pathFolder)
			hR3.CFrame = hR2.CFrame * CFrame.new(0, 4, 0) * CFrame.Angles(0, 0, math.rad(25))

			-- Portal Plane (facing down the path: -Z direction)
			local spawnDir = Vector3.new(0, 0, -1)
			local cf = CFrame.lookAt(portalCenter - spawnDir * 0.5, portalCenter + spawnDir * 0.5)
			CreatePortalEffects(
				"DragonPortalPlane",
				Vector3.new(18, 16, 0.5),
				cf,
				Color3.fromRGB(255, 50, 0),
				Color3.fromRGB(255, 150, 0),
				Color3.fromRGB(180, 0, 0),
				pathFolder
			)

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
