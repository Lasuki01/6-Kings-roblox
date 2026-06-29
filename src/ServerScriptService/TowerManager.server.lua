-- ============================================
-- TowerManager.server.lua — Kingdom Siege
-- Handles tower placement, upgrading, selling, targeting logic, and combat interactions.
-- Side: Server
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

-- Configuration modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Config = Modules:WaitForChild("Config")
local TowerConfig = require(Config:WaitForChild("TowerConfig"))
local EconomyConfig = require(Config:WaitForChild("EconomyConfig"))

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PlaceTower = Remotes:WaitForChild("PlaceTower")
local UpgradeTower = Remotes:WaitForChild("UpgradeTower")
local SellTower = Remotes:WaitForChild("SellTower")

-- Track rate limits on server
local rateLimits = {}

-- Simple early-exit rate limiter (max requests per second)
local function IsRateLimited(player, maxPerSecond)
	local now = os.clock()
	local limit = rateLimits[player]
	if not limit then
		rateLimits[player] = {count = 1, lastReset = now}
		return false
	end
	
	if now - limit.lastReset >= 1.0 then
		limit.count = 1
		limit.lastReset = now
		return false
	end
	
	limit.count = limit.count + 1
	if limit.count > maxPerSecond then
		return true
	end
	
	return false
end

-- Helper: Create a styled part
local function CreateTowerPart(name, size, pos, color, material, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = pos
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- Helper: Draw a physical projectile moving towards target
local function SpawnArrowProjectile(startPos, targetPart, duration)
	local arrow = Instance.new("Part")
	arrow.Name = "Arrow"
	arrow.Size = Vector3.new(0.4, 0.4, 1.8)
	arrow.Color = Color3.fromRGB(139, 90, 43)
	arrow.Material = Enum.Material.Wood
	arrow.Anchored = true
	arrow.CanCollide = false
	arrow.CFrame = CFrame.new(startPos, targetPart.Position)
	arrow.Parent = workspace
	
	task.spawn(function()
		local elapsed = 0
		while elapsed < duration and targetPart.Parent do
			elapsed = elapsed + task.wait()
			local t = math.min(1.0, elapsed / duration)
			local currentPos = startPos:Lerp(targetPart.Position, t)
			arrow.CFrame = CFrame.new(currentPos, targetPart.Position)
		end
		arrow:Destroy()
	end)
end

-- Helper: Draw a magical bolt projectile arcing up
local function SpawnCatapultBoulder(startPos, targetPos, duration)
	local boulder = Instance.new("Part")
	boulder.Name = "Boulder"
	boulder.Size = Vector3.new(2.2, 2.2, 2.2)
	boulder.Shape = Enum.PartType.Ball
	boulder.Color = Color3.fromRGB(110, 110, 115)
	boulder.Material = Enum.Material.Slate
	boulder.Anchored = true
	boulder.CanCollide = false
	boulder.Position = startPos
	boulder.Parent = workspace

	task.spawn(function()
		local elapsed = 0
		local peakHeight = 25
		while elapsed < duration do
			elapsed = elapsed + task.wait()
			local t = math.min(1.0, elapsed / duration)
			-- Linear horizontal lerp
			local horizontalPos = startPos:Lerp(targetPos, t)
			-- Parabolic height arch
			local yHeight = startPos.Y + (targetPos.Y - startPos.Y) * t + math.sin(t * math.pi) * peakHeight
			boulder.Position = Vector3.new(horizontalPos.X, yHeight, horizontalPos.Z)
		end
		
		-- Small blast effect
		local blast = Instance.new("Part")
		blast.Name = "Blast"
		blast.Size = Vector3.new(1, 1, 1)
		blast.Color = Color3.fromRGB(255, 100, 0)
		blast.Material = Enum.Material.Neon
		blast.Shape = Enum.PartType.Ball
		blast.Anchored = true
		blast.CanCollide = false
		blast.Position = targetPos
		blast.Parent = workspace
		
		TweenService:Create(blast, TweenInfo.new(0.3), {Size = Vector3.new(12, 12, 12), Transparency = 1.0}):Play()
		task.wait(0.3)
		blast:Destroy()
		boulder:Destroy()
	end)
end

-- Helper: Draw a neon magic laser beam
local function SpawnMagicBeam(startPos, endPos, color)
	local beam = Instance.new("Part")
	local dist = (endPos - startPos).Magnitude
	beam.Name = "MagicBeam"
	beam.Size = Vector3.new(0.3, 0.3, dist)
	beam.Color = color
	beam.Material = Enum.Material.Neon
	beam.Anchored = true
	beam.CanCollide = false
	beam.CFrame = CFrame.lookAt(startPos, endPos) * CFrame.new(0, 0, -dist / 2)
	beam.Parent = workspace

	task.spawn(function()
		local tween = TweenService:Create(beam, TweenInfo.new(0.2), {Size = Vector3.new(0, 0, dist), Transparency = 1.0})
		tween:Play()
		tween.Completed:Wait()
		beam:Destroy()
	end)
end

-- Procedurally spawn a tower model structure on top of a PlacementZone
local function SpawnTowerModel(towerType, level, position, placementZone, ownerPlayer)
	local levelData = TowerConfig.Towers[towerType].Levels[level]
	local sizeMult = 1.0 + (level - 1) * 0.25
	
	local model = Instance.new("Model")
	model.Name = towerType .. "_L" .. level

	-- Base cylinder
	local base = CreateTowerPart("TowerBase", Vector3.new(7 * sizeMult, 2 * sizeMult, 7 * sizeMult), position + Vector3.new(0, 1 * sizeMult, 0), Color3.fromRGB(80, 80, 85), Enum.Material.Slate, model)
	base.Shape = Enum.PartType.Cylinder
	base.CFrame = base.CFrame * CFrame.Angles(0, 0, math.rad(90)) -- lay cylinder flat
	model.PrimaryPart = base

	-- Spindle/Shaft pillar
	local pillar = CreateTowerPart("TowerPillar", Vector3.new(4.5 * sizeMult, 8 * sizeMult, 4.5 * sizeMult), position + Vector3.new(0, 6 * sizeMult, 0), Color3.fromRGB(110, 110, 115), Enum.Material.Slate, model)

	-- Top Platform
	local platform = CreateTowerPart("TowerPlatform", Vector3.new(6 * sizeMult, 1 * sizeMult, 6 * sizeMult), position + Vector3.new(0, 10.5 * sizeMult, 0), Color3.fromRGB(90, 90, 95), Enum.Material.Slate, model)

	-- Style visual extensions per tower type
	if towerType == "Archer" then
		-- Wooden parapet and post
		local roof = CreateTowerPart("TowerRoof", Vector3.new(6.5 * sizeMult, 1.5 * sizeMult, 6.5 * sizeMult), position + Vector3.new(0, 12 * sizeMult, 0), Color3.fromRGB(139, 90, 43), Enum.Material.Wood, model)
		roof.Shape = Enum.PartType.Block
		
		-- Small target bow holder
		local weapon = CreateTowerPart("BowHolder", Vector3.new(1.2 * sizeMult, 2 * sizeMult, 1.2 * sizeMult), position + Vector3.new(0, 11.5 * sizeMult, 0), Color3.fromRGB(100, 100, 100), Enum.Material.Metal, model)
	elseif towerType == "Mage" then
		-- Floating neon magic sphere
		local sphere = CreateTowerPart("MageCrystal", Vector3.new(3 * sizeMult, 3 * sizeMult, 3 * sizeMult), position + Vector3.new(0, 12.5 * sizeMult, 0), Color3.fromRGB(0, 180, 255), Enum.Material.Neon, model)
		sphere.Shape = Enum.PartType.Ball
		sphere.CanCollide = false
		
		-- Add point light
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(0, 200, 255)
		light.Range = 20 * sizeMult
		light.Brightness = 2.0
		light.Parent = sphere
	elseif towerType == "Catapult" then
		-- Wooden swing arm
		local arm = CreateTowerPart("LaunchArm", Vector3.new(1 * sizeMult, 1 * sizeMult, 7 * sizeMult), position + Vector3.new(0, 11.5 * sizeMult, 0.5 * sizeMult), Color3.fromRGB(101, 67, 33), Enum.Material.Wood, model)
		arm.CanCollide = false
		
		-- Stone bucket
		local bucket = CreateTowerPart("Bucket", Vector3.new(2 * sizeMult, 1.2 * sizeMult, 2 * sizeMult), position + Vector3.new(0, 12 * sizeMult, 3.5 * sizeMult), Color3.fromRGB(50, 50, 50), Enum.Material.Basalt, model)
	elseif towerType == "FrostSpire" then
		-- Floating ice crystal tip
		local crystal = CreateTowerPart("IceCrystal", Vector3.new(2.5 * sizeMult, 4 * sizeMult, 2.5 * sizeMult), position + Vector3.new(0, 13 * sizeMult, 0), Color3.fromRGB(0, 240, 255), Enum.Material.Neon, model)
		crystal.CanCollide = false
		
		-- Small orbital ice rings
		local ring1 = CreateTowerPart("IceOrb1", Vector3.new(0.8, 0.8, 0.8), position + Vector3.new(-2.2 * sizeMult, 12 * sizeMult, 0), Color3.fromRGB(150, 245, 255), Enum.Material.Neon, model)
		local ring2 = CreateTowerPart("IceOrb2", Vector3.new(0.8, 0.8, 0.8), position + Vector3.new(2.2 * sizeMult, 12 * sizeMult, 0), Color3.fromRGB(150, 245, 255), Enum.Material.Neon, model)
		ring1.CanCollide = false
		ring2.CanCollide = false
	elseif towerType == "LightningRod" then
		-- Metallic copper rings and battery coil
		local pole = CreateTowerPart("CopperPole", Vector3.new(0.8 * sizeMult, 4 * sizeMult, 0.8 * sizeMult), position + Vector3.new(0, 12.5 * sizeMult, 0), Color3.fromRGB(184, 115, 51), Enum.Material.Metal, model)
		local coil = CreateTowerPart("CoilTip", Vector3.new(2.2 * sizeMult, 1.5 * sizeMult, 2.2 * sizeMult), position + Vector3.new(0, 15 * sizeMult, 0), Color3.fromRGB(255, 220, 50), Enum.Material.Neon, model)
		coil.Shape = Enum.PartType.Ball
		coil.CanCollide = false
	end

	-- Configure attributes for combat loop
	model:SetAttribute("Type", towerType)
	model:SetAttribute("Level", level)
	model:SetAttribute("Owner", ownerPlayer.UserId)
	model:SetAttribute("Damage", levelData.Damage)
	model:SetAttribute("Range", levelData.Range)
	model:SetAttribute("Cooldown", levelData.Cooldown)
	model:SetAttribute("Class", TowerConfig.Towers[towerType].Class)
	
	if levelData.SlowPercentage then
		model:SetAttribute("SlowPercentage", levelData.SlowPercentage)
		model:SetAttribute("SlowDuration", levelData.SlowDuration)
	end
	if levelData.SplashRadius then
		model:SetAttribute("SplashRadius", levelData.SplashRadius)
	end
	if levelData.FreezeDuration then
		model:SetAttribute("FreezeDuration", levelData.FreezeDuration)
	end
	if levelData.MaxChains then
		model:SetAttribute("MaxChains", levelData.MaxChains)
	end

	return model
end

-- Select standard "First" target in range, filtering class and flying parameters
local function FindBestTarget(towerModel)
	if not towerModel or not towerModel.Parent or not towerModel.PrimaryPart then return nil end
	local towerType = towerModel:GetAttribute("Type")
	local range = towerModel:GetAttribute("Range") or 30
	local towerPos = towerModel.PrimaryPart.Position
	
	local bestEnemy = nil
	local bestScore = -math.huge
	local activeEnemies = CollectionService:GetTagged("Enemy")

	for _, enemy in ipairs(activeEnemies) do
		if enemy.Parent and enemy:FindFirstChildOfClass("Humanoid") and enemy.Humanoid.Health > 0 then
			local rootPart = enemy.PrimaryPart
			if rootPart then
				local distToTower = (rootPart.Position - towerPos).Magnitude
				if distToTower <= range then
					local isFlying = enemy:GetAttribute("IsFlying") == true
					if isFlying and (towerType == "Archer" or towerType == "Catapult") then
						-- Ground towers cannot target flying drakes
						continue
					end
					
					local wpIndex = enemy:GetAttribute("CurrentWaypointIndex") or 0
					local pathName = enemy:GetAttribute("PathName")
					
					local nextWpDistance = 0
					local nextWp = pathName and workspace:FindFirstChild("Map") 
						and workspace.Map.Paths:FindFirstChild(pathName)
						and workspace.Map.Paths[pathName].Waypoints:FindFirstChild("Waypoint_" .. (wpIndex + 1))
					
					if nextWp then
						nextWpDistance = (rootPart.Position - nextWp.Position).Magnitude
					end
					
					-- Priority Score: Higher waypoint index + closer distance to next waypoint
					local score = (wpIndex * 1000) - nextWpDistance
					if score > bestScore then
						bestScore = score
						bestEnemy = enemy
					end
				end
			end
		end
	end
	
	return bestEnemy
end

-- Apply damage and modifiers based on armor and spell types
local function DamageEnemy(enemy, damage, towerClass)
	local humanoid = enemy:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	
	local armor = enemy:GetAttribute("ArmorType") or "None"
	local finalDamage = damage

	if towerClass == "Physical" then
		if armor == "Heavy" or armor == "Undead" then
			finalDamage = damage * 0.5 -- resists arrows/boulders
		end
	elseif towerClass == "Magic" then
		if armor == "Undead" then
			finalDamage = damage * 1.5 -- magic deals extra to undead
		end
	end

	humanoid:TakeDamage(finalDamage)
end

-- Execute tower fire routines
local function FireTower(towerModel, targetEnemy)
	local towerType = towerModel:GetAttribute("Type")
	local damage = towerModel:GetAttribute("Damage") or 10
	local towerClass = towerModel:GetAttribute("Class") or "Physical"
	local startPos = towerModel.PrimaryPart.Position + Vector3.new(0, 11, 0) -- platform top level

	local targetRoot = targetEnemy.PrimaryPart
	local targetHumanoid = targetEnemy:FindFirstChildOfClass("Humanoid")
	if not targetRoot or not targetHumanoid then return end

	if towerType == "Archer" then
		-- Spawn arrow moving toward enemy
		SpawnArrowProjectile(startPos, targetRoot, 0.15)
		task.wait(0.15) -- wait for hit
		if targetEnemy.Parent and targetHumanoid.Health > 0 then
			DamageEnemy(targetEnemy, damage, towerClass)
		end
		
	elseif towerType == "Mage" then
		-- Laser Bolt beam with slow modifier
		SpawnMagicBeam(startPos, targetRoot.Position, Color3.fromRGB(0, 180, 255))
		DamageEnemy(targetEnemy, damage, towerClass)
		
		-- Slow logic
		local slowPct = towerModel:GetAttribute("SlowPercentage") or 0.3
		local slowDur = towerModel:GetAttribute("SlowDuration") or 2
		local baseSpeed = targetEnemy:GetAttribute("Speed") or 10
		
		targetHumanoid.WalkSpeed = baseSpeed * (1.0 - slowPct)
		
		task.spawn(function()
			task.wait(slowDur)
			if targetEnemy.Parent and targetHumanoid.Health > 0 then
				targetHumanoid.WalkSpeed = targetEnemy:GetAttribute("Speed") or baseSpeed
			end
		end)

	elseif towerType == "Catapult" then
		-- Heavy boulder with AoE blast radius
		local targetPos = targetRoot.Position
		local splashRad = towerModel:GetAttribute("SplashRadius") or 15
		
		SpawnCatapultBoulder(startPos, targetPos, 0.6)
		task.wait(0.6) -- boulder flight
		
		-- Apply area-of-effect damage to nearby ground enemies
		local allEnemies = CollectionService:GetTagged("Enemy")
		for _, enemy in ipairs(allEnemies) do
			if enemy.Parent and enemy:FindFirstChildOfClass("Humanoid") and enemy.Humanoid.Health > 0 then
				local eRoot = enemy.PrimaryPart
				if eRoot and (not enemy:GetAttribute("IsFlying")) then
					local dist = (eRoot.Position - targetPos).Magnitude
					if dist <= splashRad then
						DamageEnemy(enemy, damage, towerClass)
					end
				end
			end
		end

	elseif towerType == "FrostSpire" then
		-- Area freezing burst pulse
		local range = towerModel:GetAttribute("Range") or 30
		local freezeDur = towerModel:GetAttribute("FreezeDuration") or 1.5
		
		-- Pulse visual ring
		local pulse = Instance.new("Part")
		pulse.Name = "FrostPulse"
		pulse.Size = Vector3.new(1, 1, 1)
		pulse.Color = Color3.fromRGB(150, 240, 255)
		pulse.Material = Enum.Material.Neon
		pulse.Shape = Enum.PartType.Ball
		pulse.Anchored = true
		pulse.CanCollide = false
		pulse.Position = towerModel.PrimaryPart.Position
		pulse.Parent = workspace
		
		TweenService:Create(pulse, TweenInfo.new(0.4), {Size = Vector3.new(range * 2, range * 2, range * 2), Transparency = 1.0}):Play()
		task.wait(0.4)
		pulse:Destroy()
		
		-- Slow speed to 0 for duration
		local allEnemies = CollectionService:GetTagged("Enemy")
		for _, enemy in ipairs(allEnemies) do
			if enemy.Parent and enemy:FindFirstChildOfClass("Humanoid") and enemy.Humanoid.Health > 0 then
				local eRoot = enemy.PrimaryPart
				if eRoot then
					local dist = (eRoot.Position - towerModel.PrimaryPart.Position).Magnitude
					if dist <= range then
						local eh = enemy.Humanoid
						DamageEnemy(enemy, damage, towerClass)
						eh.WalkSpeed = 0
						
						task.spawn(function()
							task.wait(freezeDur)
							if enemy.Parent and eh.Health > 0 then
								eh.WalkSpeed = enemy:GetAttribute("Speed") or 10
							end
						end)
					end
				end
			end
		end

	elseif towerType == "LightningRod" then
		-- Chain lightning jumping between nearby enemies
		local maxChains = towerModel:GetAttribute("MaxChains") or 3
		local chainRange = 25
		
		local currentTarget = targetEnemy
		local currentStart = startPos
		local chainedSet = {}
		
		for chainCount = 1, maxChains do
			if not currentTarget or not currentTarget.Parent then break end
			local targetRootPart = currentTarget.PrimaryPart
			local targetHum = currentTarget:FindFirstChildOfClass("Humanoid")
			if not targetRootPart or not targetHum or targetHum.Health <= 0 then break end
			
			-- Draw yellow electricity bolt
			SpawnMagicBeam(currentStart, targetRootPart.Position, Color3.fromRGB(255, 230, 50))
			DamageEnemy(currentTarget, damage, towerClass)
			
			chainedSet[currentTarget] = true
			
			-- Find next closest unchained enemy
			local nextTarget = nil
			local closestDist = chainRange
			local allEnemies = CollectionService:GetTagged("Enemy")
			
			for _, enemy in ipairs(allEnemies) do
				if enemy.Parent and (not chainedSet[enemy]) and enemy:FindFirstChildOfClass("Humanoid") and enemy.Humanoid.Health > 0 then
					local eRoot = enemy.PrimaryPart
					if eRoot then
						local dist = (eRoot.Position - targetRootPart.Position).Magnitude
						if dist < closestDist then
							closestDist = dist
							nextTarget = enemy
						end
					end
				end
			end
			
			currentStart = targetRootPart.Position
			currentTarget = nextTarget
			task.wait(0.08) -- brief delay between jumps
		end
	end
end

-- Thread loop governing tower firing interval
local function StartTowerAttackLoop(towerModel)
	task.spawn(function()
		while towerModel.Parent do
			local cooldown = towerModel:GetAttribute("Cooldown") or 1.0
			task.wait(cooldown)
			
			if not towerModel.Parent or not towerModel.PrimaryPart then break end
			
			-- Search for best target
			local bestTarget = FindBestTarget(towerModel)
			if bestTarget then
				task.spawn(FireTower, towerModel, bestTarget)
			end
		end
	end)
end

-- Path validation helper
local function GetZonePath(zone)
	local name = zone.Name
	if string.find(name, "ForestPath") then
		return "ForestPath"
	elseif string.find(name, "UndeadPath") then
		return "UndeadPath"
	elseif string.find(name, "DragonPass") then
		return "DragonPass"
	elseif string.find(name, "Interior") then
		return "Interior"
	end
	return nil
end

local function IsPlayerAuthorizedForZone(player, zone)
	local zonePath = GetZonePath(zone)
	if not zonePath then return false end
	if zonePath == "Interior" then return true end -- Keep Interior is shared
	
	local assignedPath = player:GetAttribute("AssignedPath")
	return assignedPath == zonePath
end

-- REMOTE EVENT HANDLERS

-- 1. Handle tower placement request
PlaceTower.OnServerEvent:Connect(function(player, towerType, placementZone)
	if IsRateLimited(player, 5) then return end
	-- Basic input validations
	if not towerType or not placementZone then return end
	if not TowerConfig.Towers[towerType] then return end
	if not placementZone:IsDescendantOf(workspace) or not CollectionService:HasTag(placementZone, "PlacementZone") then return end
	
	-- Verify path assignment authorization
	if not IsPlayerAuthorizedForZone(player, placementZone) then
		warn("[TowerManager] Player " .. player.Name .. " is not assigned to path of zone: " .. placementZone.Name)
		return
	end
	
	-- Verify zone occupation
	if placementZone:GetAttribute("Occupied") == true then
		warn("[TowerManager] Placement zone already occupied.")
		return
	end
	
	-- Verify slots availability
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
	if currentCount >= slotLimit then
		warn("[TowerManager] Player " .. player.Name .. " reached tower slot limit (" .. slotLimit .. ")")
		return
	end
	
	-- Verify wave requirements
	local currentWave = workspace:GetAttribute("CurrentWave") or 0
	local unlockWave = TowerConfig.Towers[towerType].UnlockWave
	if unlockWave and currentWave < unlockWave then
		warn("[TowerManager] " .. towerType .. " unlocks at wave " .. unlockWave .. " (Current: " .. currentWave .. ")")
		return
	end
	
	-- Verify gold funds
	local cost = TowerConfig.Towers[towerType].Levels[1].Cost
	local currentGold = player:GetAttribute("Gold") or 0
	if currentGold < cost then
		warn("[TowerManager] Insufficient gold funds. Required: " .. cost .. ", Has: " .. currentGold)
		return
	end
	
	-- Deduct Gold
	player:SetAttribute("Gold", currentGold - cost)
	
	-- Spawn Tower
	local spawnPos = placementZone.Position + Vector3.new(0, placementZone.Size.Y / 2, 0) -- top face
	local towerModel = SpawnTowerModel(towerType, 1, spawnPos, placementZone, player)
	
	-- Parent and Tag
	if not towersFolder then
		towersFolder = Instance.new("Folder")
		towersFolder.Name = "Towers"
		towersFolder.Parent = workspace
	end
	
	towerModel.Parent = towersFolder
	CollectionService:AddTag(towerModel, "Tower")
	
	-- Mark zone occupied
	placementZone:SetAttribute("Occupied", true)
	
	local towerModelVal = placementZone:FindFirstChild("TowerModel")
	if not towerModelVal then
		towerModelVal = Instance.new("ObjectValue")
		towerModelVal.Name = "TowerModel"
		towerModelVal.Parent = placementZone
	end
	towerModelVal.Value = towerModel

	towerModel:SetAttribute("PlacementZoneName", placementZone.Name)

	-- Initiate firing loop
	StartTowerAttackLoop(towerModel)
	print("[TowerManager] " .. player.Name .. " placed " .. towerType .. " Tower Level 1.")
end)

-- 2. Handle tower upgrade request
UpgradeTower.OnServerEvent:Connect(function(player, towerModel)
	if IsRateLimited(player, 5) then return end
	if not towerModel or not towerModel:IsDescendantOf(workspace) or not CollectionService:HasTag(towerModel, "Tower") then return end
	if towerModel:GetAttribute("Owner") ~= player.UserId then return end
	
	local towerType = towerModel:GetAttribute("Type")
	local currentLevel = towerModel:GetAttribute("Level") or 1
	local nextLevel = currentLevel + 1
	
	local typeConfig = TowerConfig.Towers[towerType]
	if not typeConfig then return end
	
	local levelData = typeConfig.Levels[nextLevel]
	if not levelData then
		warn("[TowerManager] Tower already at max level: " .. currentLevel)
		return
	end
	
	-- Verify gold funds
	local cost = levelData.Cost
	local currentGold = player:GetAttribute("Gold") or 0
	if currentGold < cost then
		warn("[TowerManager] Insufficient gold to upgrade. Required: " .. cost .. ", Has: " .. currentGold)
		return
	end
	
	-- Find zone and verify authorization
	local mapModel = workspace:FindFirstChild("Map")
	local placementZoneName = towerModel:GetAttribute("PlacementZoneName")
	local placementZone = placementZoneName and mapModel and mapModel.PlacementZones:FindFirstChild(placementZoneName)
	if not placementZone then return end
	if not IsPlayerAuthorizedForZone(player, placementZone) then
		warn("[TowerManager] Player " .. player.Name .. " unauthorized to upgrade on path of zone: " .. placementZone.Name)
		return
	end
	
	-- Deduct Gold
	player:SetAttribute("Gold", currentGold - cost)
	
	-- Re-spawn upgraded tower model
	local spawnPos = placementZone.Position + Vector3.new(0, placementZone.Size.Y / 2, 0)
	local upgradedModel = SpawnTowerModel(towerType, nextLevel, spawnPos, placementZone, player)
	
	-- Carry over placement zone name
	upgradedModel:SetAttribute("PlacementZoneName", placementZoneName)
	
	-- Destroy old, register new
	towerModel:Destroy()
	upgradedModel.Parent = workspace.Towers
	CollectionService:AddTag(upgradedModel, "Tower")
	
	local towerModelVal = placementZone:FindFirstChild("TowerModel")
	if not towerModelVal then
		towerModelVal = Instance.new("ObjectValue")
		towerModelVal.Name = "TowerModel"
		towerModelVal.Parent = placementZone
	end
	towerModelVal.Value = upgradedModel
	
	-- Initiate attack loop
	StartTowerAttackLoop(upgradedModel)
	print("[TowerManager] " .. player.Name .. " upgraded " .. towerType .. " Tower to Level " .. nextLevel)
end)

-- 3. Handle tower sell request
SellTower.OnServerEvent:Connect(function(player, towerModel)
	if IsRateLimited(player, 5) then return end
	if not towerModel or not towerModel:IsDescendantOf(workspace) or not CollectionService:HasTag(towerModel, "Tower") then return end
	if towerModel:GetAttribute("Owner") ~= player.UserId then return end
	
	local towerType = towerModel:GetAttribute("Type")
	local currentLevel = towerModel:GetAttribute("Level") or 1
	
	-- Calculate refund (75% of cumulative spent gold)
	local totalSpent = 0
	local typeConfig = TowerConfig.Towers[towerType]
	if typeConfig then
		for lvl = 1, currentLevel do
			local lvlData = typeConfig.Levels[lvl]
			if lvlData then
				totalSpent = totalSpent + lvlData.Cost
			end
		end
	end
	
	local refund = math.floor(totalSpent * 0.75)
	
	-- Find zone and verify authorization
	local mapModel = workspace:FindFirstChild("Map")
	local placementZoneName = towerModel:GetAttribute("PlacementZoneName")
	local placementZone = placementZoneName and mapModel and mapModel.PlacementZones:FindFirstChild(placementZoneName)
	if placementZone and not IsPlayerAuthorizedForZone(player, placementZone) then
		warn("[TowerManager] Player " .. player.Name .. " unauthorized to sell on path of zone: " .. placementZone.Name)
		return
	end
	
	-- Grant Gold refund
	local currentGold = player:GetAttribute("Gold") or 0
	player:SetAttribute("Gold", currentGold + refund)
	
	-- Clear occupation and destroy
	if placementZone then
		placementZone:SetAttribute("Occupied", nil)
		local towerModelVal = placementZone:FindFirstChild("TowerModel")
		if towerModelVal then
			towerModelVal.Value = nil
		end
	end
	
	towerModel:Destroy()
	print("[TowerManager] " .. player.Name .. " sold " .. towerType .. " Tower for " .. refund .. " Gold refund.")
end)

Players.PlayerRemoving:Connect(function(player)
	rateLimits[player] = nil
end)

print("[TowerManager] System loaded and listening to Place/Upgrade/Sell remotes.")
