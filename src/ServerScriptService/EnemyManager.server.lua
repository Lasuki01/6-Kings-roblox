-- ============================================
-- EnemyManager.server.lua — Kingdom Siege
-- Manages spawning, pathfinding, movement, health, and economic rewards of all enemy classes.
-- Side: Server
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

-- Configuration modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Config = Modules:WaitForChild("Config")
local EnemyConfig = require(Config:WaitForChild("EnemyConfig"))
local Signals = require(Modules:WaitForChild("Shared"):WaitForChild("Signals"))

-- Remote / Bindable Signals
local SpawnEnemySignal = Signals.Get("SpawnEnemySignal")
local RewardGoldSignal = Signals.Get("RewardGoldSignal")

-- Helper: Weld two parts together
local function WeldParts(part0, part1, c0, c1)
	local weld = Instance.new("Weld")
	weld.Part0 = part0
	weld.Part1 = part1
	weld.C0 = c0 or CFrame.new()
	weld.C1 = c1 or CFrame.new()
	weld.Parent = part0
	return weld
end

-- Helper: Create a basic styled part for procedural models
local function CreateRigPart(name, size, color, material, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material
	part.Anchored = false
	part.CanCollide = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- Helper: Damage Kingdom Crystal on reach
local function ApplyCrystalDamage(damage)
	local crystal = workspace:FindFirstChild("KingdomCrystal")
	if crystal then
		local hpVal = crystal:FindFirstChild("CrystalHP")
		if hpVal then
			hpVal.Value = math.max(0, hpVal.Value - damage)
			print("[EnemyManager] Enemy reached Crystal! Damage dealt: " .. damage .. ", Crystal HP: " .. hpVal.Value)
		end
	end
end

-- Procedurally construct enemy model assembly based on class configurations
-- hpScale/speedScale: player-count scaling multipliers from GameManager
local function CreateEnemyModel(enemyType, config, hpScale, speedScale)
	hpScale = hpScale or 1.0
	speedScale = speedScale or 1.0
	local model = Instance.new("Model")
	model.Name = enemyType

	local sizeMult = 1.0
	local mainColor = Color3.fromRGB(100, 100, 100)
	local mainMaterial = Enum.Material.SmoothPlastic
	local skinColor = Color3.fromRGB(150, 150, 150)
	local isSkeletal = false

	-- Configure visual details based on enemy type
	if enemyType == "Goblin" then
		sizeMult = 0.7
		mainColor = Color3.fromRGB(120, 80, 50) -- leather jerkin
		skinColor = Color3.fromRGB(50, 200, 50) -- lime green skin
		mainMaterial = Enum.Material.Slate
	elseif enemyType == "Orc" then
		sizeMult = 1.2
		mainColor = Color3.fromRGB(60, 60, 65)  -- iron scrap armor
		skinColor = Color3.fromRGB(30, 100, 30) -- dark green skin
		mainMaterial = Enum.Material.Basalt
	elseif enemyType == "DarkKnight" then
		sizeMult = 1.15
		mainColor = Color3.fromRGB(15, 15, 18)  -- black steel armor
		skinColor = Color3.fromRGB(40, 40, 45)  -- dark helm
		mainMaterial = Enum.Material.Metal
	elseif enemyType == "SkeletonMage" then
		sizeMult = 1.0
		mainColor = Color3.fromRGB(80, 0, 120)  -- tattered purple robes
		skinColor = Color3.fromRGB(230, 225, 210) -- bone white skull
		mainMaterial = Enum.Material.Fabric
		isSkeletal = true
	elseif enemyType == "Troll" then
		sizeMult = 2.2
		mainColor = Color3.fromRGB(40, 38, 40)  -- rocky back plating
		skinColor = Color3.fromRGB(90, 110, 70) -- mossy skin
		mainMaterial = Enum.Material.Basalt
	elseif enemyType == "LichKing" then
		sizeMult = 1.6
		mainColor = Color3.fromRGB(25, 25, 30)  -- ornate shadow steel
		skinColor = Color3.fromRGB(130, 220, 255) -- frozen blue skin
		mainMaterial = Enum.Material.Metal
		isSkeletal = true
	end

	-- 1. Create Core HumanoidRootPart
	local rootSize = Vector3.new(2, 2, 2) * sizeMult
	local root = CreateRigPart("HumanoidRootPart", rootSize, skinColor, Enum.Material.SmoothPlastic, model)
	root.Transparency = 1.0 -- Root is invisible
	root.CanCollide = true
	model.PrimaryPart = root

	-- 2. Create Torso
	local torsoSize = isSkeletal and Vector3.new(0.8, 2, 0.8) * sizeMult or Vector3.new(2, 2, 1) * sizeMult
	local torso = CreateRigPart("Torso", torsoSize, mainColor, mainMaterial, model)
	torso.CanCollide = false
	torso.CastShadow = true
	WeldParts(root, torso, CFrame.new(), CFrame.new(0, 0, 0))

	-- 3. Create Head
	local headSize = Vector3.new(1.2, 1.2, 1.2) * sizeMult
	local head = CreateRigPart("Head", headSize, skinColor, Enum.Material.SmoothPlastic, model)
	head.CanCollide = false
	head.CastShadow = true
	WeldParts(torso, head, CFrame.new(0, 1.6 * sizeMult, 0), CFrame.new())

	-- 4. Add visual extensions & weapons
	if enemyType == "Orc" then
		-- Wooden club welded to side of Torso
		local club = CreateRigPart("WeaponClub", Vector3.new(0.6, 3.5, 0.6) * sizeMult, Color3.fromRGB(101, 67, 33), Enum.Material.Wood, model)
		club.CanCollide = false
		WeldParts(torso, club, CFrame.new(1.2 * sizeMult, 0.2 * sizeMult, -0.6 * sizeMult) * CFrame.Angles(math.rad(-15), 0, math.rad(25)), CFrame.new())
	elseif enemyType == "DarkKnight" then
		-- Crimson red glowing visor eyes
		local eyeL = CreateRigPart("EyeL", Vector3.new(0.15, 0.15, 0.15), Color3.fromRGB(255, 0, 0), Enum.Material.Neon, model)
		local eyeR = CreateRigPart("EyeR", Vector3.new(0.15, 0.15, 0.15), Color3.fromRGB(255, 0, 0), Enum.Material.Neon, model)
		eyeL.CanCollide = false
		eyeR.CanCollide = false
		WeldParts(head, eyeL, CFrame.new(-0.25 * sizeMult, 0.1 * sizeMult, -0.55 * sizeMult), CFrame.new())
		WeldParts(head, eyeR, CFrame.new(0.25 * sizeMult, 0.1 * sizeMult, -0.55 * sizeMult), CFrame.new())
		
		-- Slate shield on left arm/torso side
		local shield = CreateRigPart("Shield", Vector3.new(0.4, 2.5, 1.8) * sizeMult, Color3.fromRGB(70, 70, 75), Enum.Material.Metal, model)
		shield.CanCollide = false
		WeldParts(torso, shield, CFrame.new(-1.2 * sizeMult, 0, 0), CFrame.new())
	elseif enemyType == "SkeletonMage" then
		-- Wooden Mage staff with glowing purple top
		local staff = CreateRigPart("StaffPole", Vector3.new(0.4, 5.0, 0.4) * sizeMult, Color3.fromRGB(110, 80, 50), Enum.Material.Wood, model)
		local crystal = CreateRigPart("StaffGem", Vector3.new(0.8, 1.0, 0.8) * sizeMult, Color3.fromRGB(180, 0, 255), Enum.Material.Neon, model)
		staff.CanCollide = false
		crystal.CanCollide = false
		WeldParts(torso, staff, CFrame.new(1.2 * sizeMult, 0.4 * sizeMult, -0.4 * sizeMult) * CFrame.Angles(math.rad(-10), 0, math.rad(15)), CFrame.new())
		WeldParts(staff, crystal, CFrame.new(0, 2.6 * sizeMult, 0), CFrame.new())
	elseif enemyType == "LichKing" then
		-- Dark spiky crown on head
		local crown = CreateRigPart("CrownBase", Vector3.new(1.3, 0.4, 1.3) * sizeMult, Color3.fromRGB(15, 15, 20), Enum.Material.Metal, model)
		crown.CanCollide = false
		WeldParts(head, crown, CFrame.new(0, 0.7 * sizeMult, 0), CFrame.new())
		
		-- Spikes
		for i = 1, 4 do
			local spike = CreateRigPart("CrownSpike_" .. i, Vector3.new(0.3, 0.8, 0.3) * sizeMult, Color3.fromRGB(15, 15, 20), Enum.Material.Metal, model)
			spike.CanCollide = false
			local theta = (i - 1) * (math.pi / 2)
			local offset = Vector3.new(math.cos(theta) * 0.5, 0.4, math.sin(theta) * 0.5) * sizeMult
			WeldParts(crown, spike, CFrame.new(offset) * CFrame.Angles(math.rad(offset.X * 30), 0, math.rad(offset.Z * 30)), CFrame.new())
		end

		-- Glowing cyan eyes
		local eyeL = CreateRigPart("EyeL", Vector3.new(0.18, 0.18, 0.18), Color3.fromRGB(0, 255, 255), Enum.Material.Neon, model)
		local eyeR = CreateRigPart("EyeR", Vector3.new(0.18, 0.18, 0.18), Color3.fromRGB(0, 255, 255), Enum.Material.Neon, model)
		eyeL.CanCollide = false
		eyeR.CanCollide = false
		WeldParts(head, eyeL, CFrame.new(-0.25 * sizeMult, 0.15 * sizeMult, -0.55 * sizeMult), CFrame.new())
		WeldParts(head, eyeR, CFrame.new(0.25 * sizeMult, 0.15 * sizeMult, -0.55 * sizeMult), CFrame.new())

		-- Frosted glowing blue broadsword on back/torso
		local sword = CreateRigPart("FrostSword", Vector3.new(0.4, 4.5, 1.0) * sizeMult, Color3.fromRGB(0, 180, 255), Enum.Material.Neon, model)
		sword.CanCollide = false
		WeldParts(torso, sword, CFrame.new(0, 0, 0.8 * sizeMult) * CFrame.Angles(0, 0, math.rad(45)), CFrame.new())
	elseif enemyType == "Dragon" then
		-- Custom flying Dragon shape (doesn't use ground welds)
		-- Clean up the standard parts since Dragon is built entirely customized
		torso:Destroy()
		head:Destroy()
		
		-- Red dragon body cylinder (rotated forward along Z)
		local body = CreateRigPart("DragonBody", Vector3.new(3, 3, 7), Color3.fromRGB(200, 40, 20), Enum.Material.Basalt, model)
		WeldParts(root, body, CFrame.new(), CFrame.new())
		
		-- Head and neck
		local neck = CreateRigPart("DragonNeck", Vector3.new(1.8, 1.8, 3.5), Color3.fromRGB(200, 40, 20), Enum.Material.Basalt, model)
		local dHead = CreateRigPart("DragonHead", Vector3.new(2.2, 2, 2.5), Color3.fromRGB(220, 50, 25), Enum.Material.Basalt, model)
		neck.CanCollide = false
		dHead.CanCollide = false
		WeldParts(body, neck, CFrame.new(0, 1, -4.5) * CFrame.Angles(math.rad(-30), 0, 0), CFrame.new())
		WeldParts(neck, dHead, CFrame.new(0, 0.5, -2), CFrame.new())

		-- Glowing yellow/orange eyes
		local eyeL = CreateRigPart("EyeL", Vector3.new(0.25, 0.25, 0.25), Color3.fromRGB(255, 150, 0), Enum.Material.Neon, model)
		local eyeR = CreateRigPart("EyeR", Vector3.new(0.25, 0.25, 0.25), Color3.fromRGB(255, 150, 0), Enum.Material.Neon, model)
		eyeL.CanCollide = false
		eyeR.CanCollide = false
		WeldParts(dHead, eyeL, CFrame.new(-0.8, 0.4, -1), CFrame.new())
		WeldParts(dHead, eyeR, CFrame.new(0.8, 0.4, -1), CFrame.new())

		-- Massive glowing wings
		local wingL = CreateRigPart("WingL", Vector3.new(9, 0.4, 4), Color3.fromRGB(255, 80, 0), Enum.Material.Neon, model)
		local wingR = CreateRigPart("WingR", Vector3.new(9, 0.4, 4), Color3.fromRGB(255, 80, 0), Enum.Material.Neon, model)
		wingL.CanCollide = false
		wingR.CanCollide = false
		WeldParts(body, wingL, CFrame.new(-5, 1, 0) * CFrame.Angles(0, 0, math.rad(15)), CFrame.new())
		WeldParts(body, wingR, CFrame.new(5, 1, 0) * CFrame.Angles(0, 0, math.rad(-15)), CFrame.new())

		-- Tail
		local tail = CreateRigPart("DragonTail", Vector3.new(1.2, 1.2, 5), Color3.fromRGB(180, 30, 20), Enum.Material.Basalt, model)
		tail.CanCollide = false
		WeldParts(body, tail, CFrame.new(0, -0.5, 4.5) * CFrame.Angles(math.rad(15), 0, 0), CFrame.new())
	end

	-- Calculate Infinite Mode scaling factors
	local currentWave = workspace:GetAttribute("CurrentWave") or 0
	local hpMult = 1.0
	local speedMult = 1.0
	local goldMult = 1.0
	
	if currentWave > 20 then
		local wavesAbove = currentWave - 20
		hpMult = 1.0 + wavesAbove * 0.15
		speedMult = math.min(1.6, 1.0 + wavesAbove * 0.02)
		goldMult = 1.0 + wavesAbove * 0.10
	end

	-- Stack player-count scaling on top of infinite mode scaling
	hpMult = hpMult * hpScale
	speedMult = speedMult * speedScale
	
	local finalHP = math.round(config.HP * hpMult)
	local finalSpeed = math.round(config.Speed * speedMult)
	local finalGold = math.round(config.GoldReward * goldMult)

	-- 5. Add Humanoid instance
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = finalHP
	humanoid.Health = finalHP
	humanoid.WalkSpeed = finalSpeed
	humanoid.HipHeight = 1.4 * sizeMult
	humanoid.Parent = model

	-- Set up custom name tags
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

	-- 6. Add Attributes to Model
	model:SetAttribute("HP", finalHP)
	model:SetAttribute("MaxHP", finalHP)
	model:SetAttribute("Speed", finalSpeed)
	model:SetAttribute("ArmorType", config.ArmorType)
	model:SetAttribute("GoldReward", finalGold)
	model:SetAttribute("CrystalDamage", config.CrystalDamage)
	model:SetAttribute("IsBoss", config.IsBoss or false)
	model:SetAttribute("IsFlying", config.IsFlying or false)
	model:SetAttribute("CurrentWaypointIndex", 0)
	model:SetAttribute("SizeMultiplier", sizeMult)

	if config.RegenHP then
		local finalRegen = math.round(config.RegenHP * hpMult)
		model:SetAttribute("RegenHP", finalRegen)
	end

	return model
end

-- Procedural UI: Build and update enemy visual health bar above head
local function SetupEnemyHealthBar(model, humanoid, sizeMult, enemyType)
	local rootPart = model.PrimaryPart
	if not rootPart then return end

	-- 1. Create BillboardGui
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "HealthBarGui"
	billboard.Size = UDim2.new(0, 75, 0, 6)
	
	-- Adjust height offset based on enemy dimensions
	local heightOffset = 5.2 * sizeMult
	if enemyType == "Dragon" then
		heightOffset = 7.5
	elseif enemyType == "LichKing" then
		heightOffset = 7.2
	elseif enemyType == "Troll" then
		heightOffset = 6.4
	end
	
	billboard.StudsOffset = Vector3.new(0, heightOffset, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 180
	billboard.Adornee = rootPart
	billboard.Parent = model

	-- 2. Create Background Frame
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	background.BackgroundTransparency = 0.4
	background.BorderSizePixel = 0
	background.Parent = billboard

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0.5, 0) -- Pill shaped
	bgCorner.Parent = background

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Thickness = 1.0
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = background

	-- 3. Create Fill Frame
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(230, 40, 40) -- Sleek Crimson Red
	fill.BorderSizePixel = 0
	fill.Parent = background

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0.5, 0) -- Pill shaped
	fillCorner.Parent = fill

	-- 4. Function to update HP display
	local function UpdateHPDisplay()
		local hp = math.max(0, humanoid.Health)
		local maxHp = humanoid.MaxHealth
		if maxHp <= 0 then return end
		
		local ratio = math.clamp(hp / maxHp, 0, 1)
		
		-- Scale the fill width smoothly
		fill.Size = UDim2.new(ratio, 0, 1, 0)

		-- Synchronize server-side model attribute
		model:SetAttribute("HP", math.round(hp))
	end

	-- 6. Connect humanoid health changes
	local connection
	connection = humanoid.HealthChanged:Connect(function()
		if not model.Parent or humanoid.Health <= 0 then
			if connection then
				connection:Disconnect()
				connection = nil
			end
			return
		end
		UpdateHPDisplay()
	end)

	-- Clean up connection when model is destroyed
	local destroyConn
	destroyConn = model.Destroying:Connect(function()
		if connection then
			connection:Disconnect()
			connection = nil
		end
		if destroyConn then
			destroyConn:Disconnect()
			destroyConn = nil
		end
	end)
end

-- Distribute gold to nearby path players or keep defenders upon death
local function DistributeKillGold(model, goldReward)
	if goldReward <= 0 then return end
	local rootPart = model.PrimaryPart
	if not rootPart then return end

	local deathPos = rootPart.Position

	for _, player in ipairs(Players:GetPlayers()) do
		local deservesGold = false

		if player.Character and player.Character.PrimaryPart then
			local playerPos = player.Character.PrimaryPart.Position
			local distToEnemy = (playerPos - deathPos).Magnitude
			
			-- Center Keep is at Y ~ 4.0, calculate horizontal distance from center
			local distToCenter = Vector3.new(playerPos.X, 4.0, playerPos.Z).Magnitude

			-- Close to enemy (120 studs) or protecting Central Keep (60 studs)
			if distToEnemy <= 120 or distToCenter <= 60 then
				deservesGold = true
			end
		end

		if deservesGold then
			RewardGoldSignal:Fire(player, goldReward)
			print("[EnemyManager] Rewarding " .. goldReward .. " Gold to player " .. player.Name)
		end
	end
end

-- Visual and mechanical cleanup when enemy dies
local function HandleEnemyDeath(model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local rootPart = model.PrimaryPart
	if not rootPart then return end

	local goldReward = model:GetAttribute("GoldReward") or 0
	
	-- Award Gold
	DistributeKillGold(model, goldReward)

	-- Run death visual sequence
	task.spawn(function()
		-- Break welds to cause parts to collapse (simulate ragdoll/shatter)
		for _, child in ipairs(model:GetDescendants()) do
			if child:IsA("Weld") or child:IsA("Motor6D") then
				child:Destroy()
			elseif child:IsA("Part") and child.Name ~= "HumanoidRootPart" then
				-- Let parts fall
				child.CanCollide = true
				-- Add subtle drift velocity
				child.AssemblyLinearVelocity = Vector3.new(math.random(-5, 5), 10, math.random(-5, 5))
			end
		end

		-- Fade out parts
		task.wait(1.2)
		local startTime = os.clock()
		while (os.clock() - startTime) < 0.8 do
			local t = (os.clock() - startTime) / 0.8
			for _, child in ipairs(model:GetDescendants()) do
				if child:IsA("BasePart") then
					child.Transparency = math.min(1.0, t)
				end
			end
			task.wait(0.05)
		end

		model:Destroy()
	end)
end

-- Ground enemy movement loop (waypoint by waypoint)
local function MoveGroundEnemy(model, waypoints)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local rootPart = model.PrimaryPart
	if not humanoid or not rootPart then return end

	local pathLength = #waypoints

	for i = 1, pathLength do
		if not model.Parent or humanoid.Health <= 0 then break end
		local wp = waypoints[i]
		model:SetAttribute("CurrentWaypointIndex", i)

		local reached = false
		local connection
		connection = humanoid.MoveToFinished:Connect(function()
			reached = true
		end)

		humanoid:MoveTo(wp.Position)

		-- Yield until waypoint reached or segment timeout
		local startTime = os.clock()
		local segmentTimeout = 18 -- safety threshold if stuck
		while not reached and model.Parent and humanoid.Health > 0 and (os.clock() - startTime) < segmentTimeout do
			-- Proactive nudge if stuck
			if os.clock() - startTime > 4 and not reached then
				humanoid:MoveTo(wp.Position)
			end
			task.wait(0.15)
		end

		if connection then connection:Disconnect() end
	end

	-- If reached crystal unscathed
	if model.Parent and humanoid.Health > 0 then
		local crystalDamage = model:GetAttribute("CrystalDamage") or 10
		ApplyCrystalDamage(crystalDamage)
		model:Destroy()
	end
end

-- Flying enemy movement loop (ignores ground waypoints, files over map)
local function MoveFlyingEnemy(model, waypoints, speed)
	local rootPart = model.PrimaryPart
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not rootPart or not humanoid then return end

	local speedStudsPerSec = speed or 12
	local pathLength = #waypoints

	for i = 1, pathLength do
		if not model.Parent or humanoid.Health <= 0 then break end
		local wp = waypoints[i]
		model:SetAttribute("CurrentWaypointIndex", i)

		local startPos = rootPart.Position
		-- Fly exactly 22 studs above normal path height
		local targetPos = wp.Position + Vector3.new(0, 22, 0)
		local distance = (targetPos - startPos).Magnitude
		local duration = distance / speedStudsPerSec

		local startTime = os.clock()
		while (os.clock() - startTime) < duration do
			if not model.Parent or humanoid.Health <= 0 then break end
			local t = (os.clock() - startTime) / duration
			local currentPos = startPos:Lerp(targetPos, t)

			-- Look towards target waypoint
			if (targetPos - currentPos).Magnitude > 0.5 then
				rootPart.CFrame = CFrame.lookAt(currentPos, targetPos)
			else
				rootPart.CFrame = CFrame.new(currentPos)
			end

			task.wait(0.03) -- 30 FPS interpolation updates
		end

		if model.Parent and humanoid.Health > 0 then
			rootPart.CFrame = CFrame.new(targetPos)
		end
	end

	-- If flyer reached crystal unscathed
	if model.Parent and humanoid.Health > 0 then
		local crystalDamage = model:GetAttribute("CrystalDamage") or 20
		ApplyCrystalDamage(crystalDamage)
		model:Destroy()
	end
end

-- Initialize Troll HP regen tick loop
local function StartTrollRegeneration(model, humanoid, regenAmount)
	task.spawn(function()
		while model.Parent and humanoid.Health > 0 do
			task.wait(1.0)
			if humanoid.Health > 0 and humanoid.Health < humanoid.MaxHealth then
				humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + regenAmount)
			end
		end
	end)
end

-- Spawning logic orchestrator
-- hpScale/speedScale come from GameManager (player-count scaling)
local function SpawnEnemy(enemyType, pathName, hpScale, speedScale)
	hpScale = hpScale or 1.0
	speedScale = speedScale or 1.0

	local config = EnemyConfig.Enemies[enemyType]
	if not config then
		warn("[EnemyManager] Unknown enemy type requested: " .. tostring(enemyType))
		return
	end

	-- Fetch and validate path folder structure
	local pathFolder = workspace:FindFirstChild("Map")
		and workspace.Map:FindFirstChild("Paths")
		and workspace.Map.Paths:FindFirstChild(pathName)
	
	if not pathFolder then
		warn("[EnemyManager] Path folder not found for: " .. tostring(pathName))
		return
	end

	local waypointsFolder = pathFolder:FindFirstChild("Waypoints")
	local spawnPointPart = pathFolder:FindFirstChild("SpawnPoint")
	if not waypointsFolder or not spawnPointPart then
		warn("[EnemyManager] Waypoints or SpawnPoint missing on path " .. pathName)
		return
	end

	-- Retrieve sorted list of waypoints
	local waypointsList = {}
	for _, wp in ipairs(waypointsFolder:GetChildren()) do
		table.insert(waypointsList, wp)
	end
	
	table.sort(waypointsList, function(a, b)
		local numA = tonumber(a.Name:match("Waypoint_(%d+)")) or 0
		local numB = tonumber(b.Name:match("Waypoint_(%d+)")) or 0
		return numA < numB
	end)

	if #waypointsList == 0 then
		warn("[EnemyManager] No waypoints found in paths folder for: " .. pathName)
		return
	end

	-- Construct procedural character and place at spawn portal
	local enemyModel = CreateEnemyModel(enemyType, config, hpScale, speedScale)
	enemyModel:SetAttribute("PathName", pathName)
	
	-- Enemies parented to workspace/Enemies folder
	local enemiesFolder = workspace:FindFirstChild("Enemies")
	if not enemiesFolder then
		enemiesFolder = Instance.new("Folder")
		enemiesFolder.Name = "Enemies"
		enemiesFolder.Parent = workspace
	end
	
	enemyModel.Parent = enemiesFolder
	CollectionService:AddTag(enemyModel, "Enemy")

	-- Initial placing
	local startSpawnCF = spawnPointPart.CFrame + Vector3.new(0, 2, 0)
	if config.IsFlying then
		startSpawnCF = startSpawnCF + Vector3.new(0, 22, 0)
	end
	enemyModel.PrimaryPart.CFrame = startSpawnCF

	-- Setup health bar and death handling
	local humanoid = enemyModel:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local sizeMult = enemyModel:GetAttribute("SizeMultiplier") or 1.0
		SetupEnemyHealthBar(enemyModel, humanoid, sizeMult, enemyType)
	end
	
	local isDead = false
	if humanoid then
		humanoid.Died:Connect(function()
			if not isDead then
				isDead = true
				HandleEnemyDeath(enemyModel)
			end
		end)
	end

	-- Handle Troll regeneration ability
	if config.RegenHP then
		StartTrollRegeneration(enemyModel, humanoid, config.RegenHP)
	end

	-- Start path movement in a separate thread
	if config.IsFlying then
		task.spawn(function()
			MoveFlyingEnemy(enemyModel, waypointsList, config.Speed)
		end)
	else
		task.spawn(function()
			MoveGroundEnemy(enemyModel, waypointsList)
		end)
	end
end

-- Connect signals
SpawnEnemySignal.Event:Connect(SpawnEnemy)

print("[EnemyManager] System loaded and listening to SpawnEnemySignal.")
