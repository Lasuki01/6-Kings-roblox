-- ============================================
-- HeroManager.server.lua — Kingdom Siege
-- Manages hero class attributes, weapons, basic attacks, special abilities, and respawn timers.
-- Side: Server
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

-- Configuration modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Config = Modules:WaitForChild("Config")
local HeroConfig = require(Config:WaitForChild("HeroConfig"))
local EnemyConfig = require(Config:WaitForChild("EnemyConfig"))
local LobbyConfig = require(Config:WaitForChild("LobbyConfig"))

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local SelectClass = Remotes:WaitForChild("SelectClass")
local UseAbility = Remotes:WaitForChild("UseAbility")
local BasicAttack = Remotes:WaitForChild("BasicAttack")

-- Track cooldowns on server
local lastAttackTimes = {}
local lastAbilityTimes = {}
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

-- Set global respawn timing
Players.RespawnTime = HeroConfig.RESPAWN_TIME

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

-- Helper: Create visual projectiles / trails
local function DrawMagicBeam(startPos, endPos, color)
	local beam = Instance.new("Part")
	local dist = (endPos - startPos).Magnitude
	beam.Name = "MagicBeam"
	beam.Size = Vector3.new(0.2, 0.2, dist)
	beam.Color = color
	beam.Material = Enum.Material.Neon
	beam.Anchored = true
	beam.CanCollide = false
	beam.CFrame = CFrame.lookAt(startPos, endPos) * CFrame.new(0, 0, -dist / 2)
	beam.Parent = workspace

	task.spawn(function()
		local tween = TweenService:Create(beam, TweenInfo.new(0.15), {Size = Vector3.new(0, 0, dist), Transparency = 1.0})
		tween:Play()
		tween.Completed:Wait()
		beam:Destroy()
	end)
end

-- Procedurally construct and weld weapons/accessories to character
local function WeldClassWeapons(character, className)
	-- Clear pre-existing accessories
	for _, child in ipairs(character:GetChildren()) do
		if child.Name == "ClassWeapon" or child.Name == "ClassAccessory" then
			child:Destroy()
		end
	end

	local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	if not hand or not torso then return end

	local function CreateAccessoryPart(name, size, color, material)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.Color = color
		part.Material = material
		part.CanCollide = false
		part.CastShadow = true
		part.Parent = character
		return part
	end

	if className == "Knight" then
		local sword = CreateAccessoryPart("ClassWeapon", Vector3.new(0.5, 3.8, 0.5), Color3.fromRGB(180, 180, 185), Enum.Material.Metal)
		WeldParts(hand, sword, CFrame.new(0, -1.0, 0) * CFrame.Angles(math.rad(90), 0, 0), CFrame.new())
		
		local shield = CreateAccessoryPart("ClassAccessory", Vector3.new(0.4, 2.6, 2.0), Color3.fromRGB(60, 60, 65), Enum.Material.Metal)
		WeldParts(torso, shield, CFrame.new(0, 0, 0.8) * CFrame.Angles(0, math.rad(180), 0), CFrame.new())
	elseif className == "Ranger" then
		local bow = CreateAccessoryPart("ClassWeapon", Vector3.new(0.4, 4.2, 0.8), Color3.fromRGB(139, 90, 43), Enum.Material.Wood)
		WeldParts(hand, bow, CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(90)), CFrame.new())
	elseif className == "Mage" then
		local staff = CreateAccessoryPart("ClassWeapon", Vector3.new(0.5, 4.8, 0.5), Color3.fromRGB(110, 80, 50), Enum.Material.Wood)
		WeldParts(hand, staff, CFrame.new(0, -0.6, 0) * CFrame.Angles(math.rad(90), 0, 0), CFrame.new())
		
		local crystal = CreateAccessoryPart("ClassAccessory", Vector3.new(0.8, 0.8, 0.8), Color3.fromRGB(0, 180, 255), Enum.Material.Neon)
		WeldParts(staff, crystal, CFrame.new(0, 2.4, 0), CFrame.new())
	elseif className == "Necromancer" then
		local staff = CreateAccessoryPart("ClassWeapon", Vector3.new(0.5, 4.8, 0.5), Color3.fromRGB(25, 25, 30), Enum.Material.Basalt)
		WeldParts(hand, staff, CFrame.new(0, -0.6, 0) * CFrame.Angles(math.rad(90), 0, 0), CFrame.new())
		
		local gem = CreateAccessoryPart("ClassAccessory", Vector3.new(0.8, 0.8, 0.8), Color3.fromRGB(180, 0, 255), Enum.Material.Neon)
		WeldParts(staff, gem, CFrame.new(0, 2.4, 0), CFrame.new())
	elseif className == "StormCaller" then
		local spear = CreateAccessoryPart("ClassWeapon", Vector3.new(0.4, 5.5, 0.4), Color3.fromRGB(255, 220, 50), Enum.Material.Neon)
		WeldParts(hand, spear, CFrame.new(0, -0.8, 0) * CFrame.Angles(math.rad(90), 0, 0), CFrame.new())
	elseif className == "DragonKnight" then
		local sword = CreateAccessoryPart("ClassWeapon", Vector3.new(0.8, 5.0, 0.8), Color3.fromRGB(220, 50, 0), Enum.Material.Neon)
		WeldParts(hand, sword, CFrame.new(0, -1.2, 0) * CFrame.Angles(math.rad(90), 0, 0), CFrame.new())
	end
end

-- Apply class stats to character humanoid
local function ConfigureCharacter(player, character, className)
	local config = HeroConfig.Classes[className]
	if not config then return end

	local humanoid = character:WaitForChild("Humanoid", 10)
	local rootPart = character:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not rootPart then return end

	humanoid.MaxHealth = config.HP
	humanoid.Health = config.HP
	humanoid.WalkSpeed = config.Speed

	-- Teleport player based on current game state
	local gameState = workspace:GetAttribute("GameState") or "Lobby"
	if gameState == "Lobby" then
		rootPart.CFrame = CFrame.new(LobbyConfig.LobbyCenter + LobbyConfig.SpawnLocationOffset + Vector3.new(0, 3, 0))
	else
		rootPart.CFrame = CFrame.new(0, 6, -25)
	end

	-- Spawn visual class gear
	WeldClassWeapons(character, className)
	print("[HeroManager] Styled and positioned " .. player.Name .. " as a " .. className .. ".")
end

-- Handle class select request
SelectClass.OnServerEvent:Connect(function(player, className)
	local gameState = workspace:GetAttribute("GameState") or "Lobby"
	if gameState ~= "Lobby" then
		warn("[HeroManager] Class selection rejected mid-match: " .. player.Name)
		return
	end

	local classConfig = HeroConfig.Classes[className]
	if not classConfig then return end

	-- Monetization check for premium classes
	if classConfig.Cost ~= "Free" then
		local attributeName = "Owns" .. className .. "Class"
		if player:GetAttribute(attributeName) ~= true then
			warn("[HeroManager] Player " .. player.Name .. " attempted to select locked class: " .. className)
			return
		end
	end

	player:SetAttribute("SelectedClass", className)
	
	-- Force respawn character
	player:LoadCharacter()
end)

-- Ground target helper: Select closest enemy within range
local function GetClosestEnemy(playerPos, range)
	local closestEnemy = nil
	local closestDist = range
	local activeEnemies = CollectionService:GetTagged("Enemy")

	for _, enemy in ipairs(activeEnemies) do
		if enemy.Parent and enemy:FindFirstChildOfClass("Humanoid") and enemy.Humanoid.Health > 0 then
			local root = enemy.PrimaryPart
			if root then
				local dist = (root.Position - playerPos).Magnitude
				if dist < closestDist then
					closestDist = dist
					closestEnemy = enemy
				end
			end
		end
	end
	
	return closestEnemy
end

-- Handle Hero Basic Attack
BasicAttack.OnServerEvent:Connect(function(player)
	local gameState = workspace:GetAttribute("GameState") or "Lobby"
	if gameState ~= "Active" and gameState ~= "Intermission" then return end
	
	if IsRateLimited(player, 5) then return end -- max 5 attacks per second
	
	local className = player:GetAttribute("SelectedClass")
	if not className then return end

	local character = player.Character
	local rootPart = character and character.PrimaryPart
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not rootPart or not humanoid or humanoid.Health <= 0 then return end

	-- Check attack cooldown
	local lastAttack = lastAttackTimes[player] or 0
	local classConfig = HeroConfig.Classes[className]
	if os.clock() - lastAttack < classConfig.AttackCooldown then return end
	lastAttackTimes[player] = os.clock()

	-- Query target
	local target = GetClosestEnemy(rootPart.Position, classConfig.AttackRange)
	if target then
		local tRoot = target.PrimaryPart
		local tHum = target:FindFirstChildOfClass("Humanoid")
		if tRoot and tHum then
			-- Visual attack effect
			local startHandPos = rootPart.Position + Vector3.new(0, 1, 0)
			if className == "Ranger" then
				DrawMagicBeam(startHandPos, tRoot.Position, Color3.fromRGB(150, 110, 80))
			elseif className == "Mage" or className == "Necromancer" then
				DrawMagicBeam(startHandPos, tRoot.Position, Color3.fromRGB(0, 200, 255))
			else
				-- Melee visual slash block
				local slash = Instance.new("Part")
				slash.Size = Vector3.new(3, 1, 3)
				slash.Color = Color3.fromRGB(240, 240, 250)
				slash.Material = Enum.Material.Neon
				slash.Transparency = 0.4
				slash.CanCollide = false
				slash.Anchored = true
				slash.CFrame = rootPart.CFrame * CFrame.new(0, 0, -2) * CFrame.Angles(0, math.rad(45), 0)
				slash.Parent = workspace
				
				TweenService:Create(slash, TweenInfo.new(0.12), {Size = Vector3.new(0,0,0), Transparency = 1.0}):Play()
				task.spawn(function()
					task.wait(0.12)
					slash:Destroy()
				end)
			end

			-- Deal damage
			local arm = target:GetAttribute("ArmorType") or "None"
			local finalDmg = classConfig.Damage
			
			if className == "Ranger" or className == "Knight" or className == "DragonKnight" then
				-- Physical
				if arm == "Heavy" or arm == "Undead" then
					finalDmg = classConfig.Damage * 0.5
				end
			else
				-- Magical
				if arm == "Undead" then
					finalDmg = classConfig.Damage * 1.5
				end
			end

			tHum:TakeDamage(finalDmg)
		end
	end
end)

-- Handle Hero Special Abilities
UseAbility.OnServerEvent:Connect(function(player)
	local gameState = workspace:GetAttribute("GameState") or "Lobby"
	if gameState ~= "Active" and gameState ~= "Intermission" then return end
	
	if IsRateLimited(player, 3) then return end -- max 3 ability requests per second
	
	local className = player:GetAttribute("SelectedClass")
	if not className then return end

	local character = player.Character
	local rootPart = character and character.PrimaryPart
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not rootPart or not humanoid or humanoid.Health <= 0 then return end

	local classConfig = HeroConfig.Classes[className]
	local abConfig = classConfig.Ability

	-- Cooldown validation
	local lastAb = lastAbilityTimes[player] or 0
	if os.clock() - lastAb < abConfig.Cooldown then return end
	lastAbilityTimes[player] = os.clock()

	print("[HeroManager] " .. player.Name .. " casted " .. abConfig.Name)

	if className == "Knight" then
		-- Shield Bash: Forward cone Stun and Damage
		local radius = abConfig.Radius or 8
		local damage = abConfig.Damage or 45
		local stunDur = abConfig.StunDuration or 3

		-- Visual bash ring
		local ring = Instance.new("Part")
		ring.Size = Vector3.new(1, 0.4, 1)
		ring.Color = Color3.fromRGB(150, 150, 160)
		ring.Material = Enum.Material.Metal
		ring.Transparency = 0.5
		ring.CanCollide = false
		ring.Anchored = true
		ring.CFrame = rootPart.CFrame * CFrame.new(0, -1, 0)
		ring.Parent = workspace
		TweenService:Create(ring, TweenInfo.new(0.35), {Size = Vector3.new(radius*2, 0.4, radius*2), Transparency = 1.0}):Play()
		task.spawn(function() task.wait(0.35) ring:Destroy() end)

		local activeEnemies = CollectionService:GetTagged("Enemy")
		for _, enemy in ipairs(activeEnemies) do
			if enemy.Parent and enemy:FindFirstChildOfClass("Humanoid") and enemy.Humanoid.Health > 0 then
				local eRoot = enemy.PrimaryPart
				if eRoot then
					local offset = eRoot.Position - rootPart.Position
					if offset.Magnitude <= radius then
						-- Check front angle
						local dot = rootPart.CFrame.LookVector:Dot(offset.Unit)
						if dot >= 0.25 then
							local eh = enemy.Humanoid
							eh:TakeDamage(damage)
							
							-- Apply Stun
							local baseSpd = enemy:GetAttribute("Speed") or 10
							eh.WalkSpeed = 0
							task.spawn(function()
								task.wait(stunDur)
								if enemy.Parent and eh.Health > 0 then
									eh.WalkSpeed = enemy:GetAttribute("Speed") or baseSpd
								end
							end)
						end
					end
				end
			end
		end

	elseif className == "Ranger" then
		-- Rain of Arrows: AoE Storm centered at closest enemy
		local radius = abConfig.Radius or 15
		local damage = abConfig.Damage or 60
		local duration = abConfig.Duration or 4

		local closest = GetClosestEnemy(rootPart.Position, 50)
		local centerPos = closest and closest.PrimaryPart.Position or rootPart.Position + rootPart.CFrame.LookVector * 15

		-- visual storm boundary ring
		local stormRing = Instance.new("Part")
		stormRing.Size = Vector3.new(radius * 2, 0.2, radius * 2)
		stormRing.Color = Color3.fromRGB(100, 200, 100)
		stormRing.Material = Enum.Material.Neon
		stormRing.Transparency = 0.75
		stormRing.CanCollide = false
		stormRing.Anchored = true
		stormRing.Position = Vector3.new(centerPos.X, 4.05, centerPos.Z)
		stormRing.Parent = workspace
		
		task.spawn(function()
			local elapsed = 0
			local tickInterval = 0.5
			local damagePerTick = (damage / (duration / tickInterval))

			while elapsed < duration do
				elapsed = elapsed + task.wait(tickInterval)
				
				-- visual dropping arrow parts
				for aCount = 1, 5 do
					local arrow = Instance.new("Part")
					arrow.Size = Vector3.new(0.3, 1.5, 0.3)
					arrow.Color = Color3.fromRGB(120, 80, 40)
					arrow.Anchored = true
					arrow.CanCollide = false
					local offset = Vector3.new(math.random(-radius, radius), 25, math.random(-radius, radius))
					arrow.Position = stormRing.Position + offset
					arrow.CFrame = CFrame.new(arrow.Position) * CFrame.Angles(math.rad(-90), 0, 0)
					arrow.Parent = workspace
					
					TweenService:Create(arrow, TweenInfo.new(0.25), {Position = arrow.Position - Vector3.new(0, 25, 0)}):Play()
					task.spawn(function() task.wait(0.25) arrow:Destroy() end)
				end

				-- Damage
				local activeEnemies = CollectionService:GetTagged("Enemy")
				for _, enemy in ipairs(activeEnemies) do
					if enemy.Parent and enemy:FindFirstChildOfClass("Humanoid") and enemy.Humanoid.Health > 0 then
						local eRoot = enemy.PrimaryPart
						if eRoot and (not enemy:GetAttribute("IsFlying")) then
							local dist = (Vector3.new(eRoot.Position.X, 0, eRoot.Position.Z) - Vector3.new(stormRing.Position.X, 0, stormRing.Position.Z)).Magnitude
							if dist <= radius then
								enemy.Humanoid:TakeDamage(damagePerTick)
							end
						end
					end
				end
			end
			
			stormRing:Destroy()
		end)

	elseif className == "Mage" then
		-- Fireball: Massive explosion projectile
		local radius = abConfig.Radius or 12
		local damage = abConfig.Damage or 100

		local closest = GetClosestEnemy(rootPart.Position, 50)
		local targetPos = closest and closest.PrimaryPart.Position or rootPart.Position + rootPart.CFrame.LookVector * 25
		
		-- Spawn sphere
		local fb = Instance.new("Part")
		fb.Size = Vector3.new(3, 3, 3)
		fb.Color = Color3.fromRGB(255, 60, 0)
		fb.Material = Enum.Material.Neon
		fb.Shape = Enum.PartType.Ball
		fb.CanCollide = false
		fb.Anchored = true
		fb.Position = rootPart.Position + Vector3.new(0, 2, 0)
		fb.Parent = workspace

		task.spawn(function()
			local travelDur = 0.5
			local startTime = os.clock()
			local startPos = fb.Position
			while (os.clock() - startTime) < travelDur do
				local t = (os.clock() - startTime) / travelDur
				fb.Position = startPos:Lerp(targetPos, t)
				task.wait()
			end
			
			-- Explosion
			local blast = Instance.new("Explosion")
			blast.Position = targetPos
			blast.BlastRadius = radius
			blast.BlastPressure = 0
			blast.Parent = workspace
			
			fb:Destroy()

			-- Splash damage
			local activeEnemies = CollectionService:GetTagged("Enemy")
			for _, enemy in ipairs(activeEnemies) do
				if enemy.Parent and enemy:FindFirstChildOfClass("Humanoid") and enemy.Humanoid.Health > 0 then
					local eRoot = enemy.PrimaryPart
					if eRoot then
						local dist = (eRoot.Position - targetPos).Magnitude
						if dist <= radius then
							enemy.Humanoid:TakeDamage(damage)
						end
					end
				end
			end
		end)

	elseif className == "Necromancer" then
		-- Raise Skeletons: Summons 3 skeletal minions
		local minionHP = abConfig.MinionHP or 60
		local minionDmg = abConfig.MinionDamage or 12
		local minionDur = abConfig.MinionDuration or 15

		for m = 1, 3 do
			local skel = Instance.new("Model")
			skel.Name = "Skeleton Minion"
			
			-- Simple visual block rigs
			local skelRoot = Instance.new("Part")
			skelRoot.Name = "HumanoidRootPart"
			skelRoot.Size = Vector3.new(1.5, 1.5, 1.5)
			skelRoot.Color = Color3.fromRGB(230, 225, 210)
			skelRoot.Material = Enum.Material.Basalt
			skelRoot.CanCollide = true
			skelRoot.Parent = skel
			skel.PrimaryPart = skelRoot

			local skelTorso = Instance.new("Part")
			skelTorso.Name = "Torso"
			skelTorso.Size = Vector3.new(1.2, 1.5, 0.8)
			skelTorso.Color = Color3.fromRGB(20, 20, 20)
			skelTorso.Parent = skel
			WeldParts(skelRoot, skelTorso, CFrame.new(), CFrame.new())

			local skelHead = Instance.new("Part")
			skelHead.Name = "Head"
			skelHead.Size = Vector3.new(1.0, 1.0, 1.0)
			skelHead.Color = Color3.fromRGB(230, 225, 210)
			skelHead.Parent = skel
			WeldParts(skelTorso, skelHead, CFrame.new(0, 1.25, 0), CFrame.new())

			local skelHum = Instance.new("Humanoid")
			skelHum.MaxHealth = minionHP
			skelHum.Health = minionHP
			skelHum.WalkSpeed = 12
			skelHum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			skelHum.Parent = skel

			local minionsFolder = workspace:FindFirstChild("Minions")
			if not minionsFolder then
				minionsFolder = Instance.new("Folder")
				minionsFolder.Name = "Minions"
				minionsFolder.Parent = workspace
			end
			
			skel.Parent = minionsFolder
			skelRoot.CFrame = rootPart.CFrame * CFrame.new(math.random(-5, 5), 1, math.random(-5, 5))

			-- minion thread AI
			task.spawn(function()
				local mElapsed = 0
				local attackCooldown = 0.8
				local lastAttack = 0

				while mElapsed < minionDur and skel.Parent and skelHum.Health > 0 do
					mElapsed = mElapsed + task.wait(0.2)
					
					local activeEnemy = GetClosestEnemy(skelRoot.Position, 80)
					if activeEnemy and activeEnemy.Parent then
						local eRoot = activeEnemy.PrimaryPart
						local eHum = activeEnemy:FindFirstChildOfClass("Humanoid")
						if eRoot and eHum then
							skelHum:MoveTo(eRoot.Position)
							
							local dist = (eRoot.Position - skelRoot.Position).Magnitude
							if dist <= 6 and os.clock() - lastAttack >= attackCooldown then
								lastAttack = os.clock()
								eHum:TakeDamage(minionDmg)
								
								-- Attack swing indicator
								local swing = Instance.new("Part")
								swing.Size = Vector3.new(1.5, 0.4, 1.5)
								swing.Color = Color3.fromRGB(180, 0, 255)
								swing.Material = Enum.Material.Neon
								swing.CanCollide = false
								swing.Anchored = true
								swing.CFrame = skelRoot.CFrame * CFrame.new(0, 0, -1.2)
								swing.Parent = workspace
								TweenService:Create(swing, TweenInfo.new(0.12), {Size = Vector3.new(0,0,0)}):Play()
								task.spawn(function() task.wait(0.12) swing:Destroy() end)
							end
						end
					end
				end
				skel:Destroy()
			end)
		end

	elseif className == "StormCaller" then
		-- Chain Lightning: Jumps to 5 targets
		local damage = abConfig.Damage or 45
		local maxChains = abConfig.MaxChains or 5
		local range = 45

		local closest = GetClosestEnemy(rootPart.Position, range)
		if closest then
			local currentStart = rootPart.Position + Vector3.new(0, 2, 0)
			local currentTarget = closest
			local chained = {}
			
			for chainCount = 1, maxChains do
				if not currentTarget or not currentTarget.Parent then break end
				local targetRoot = currentTarget.PrimaryPart
				local targetHum = currentTarget:FindFirstChildOfClass("Humanoid")
				if not targetRoot or not targetHum or targetHum.Health <= 0 then break end

				-- Visual electric bolt
				DrawMagicBeam(currentStart, targetRoot.Position, Color3.fromRGB(255, 240, 0))
				targetHum:TakeDamage(damage)
				chained[currentTarget] = true

				-- Jump to next closest unchained
				local nextTarget = nil
				local closestDist = range
				local activeEnemies = CollectionService:GetTagged("Enemy")
				for _, enemy in ipairs(activeEnemies) do
					if enemy.Parent and (not chained[enemy]) and enemy:FindFirstChildOfClass("Humanoid") and enemy.Humanoid.Health > 0 then
						local eRoot = enemy.PrimaryPart
						if eRoot then
							local dist = (eRoot.Position - targetRoot.Position).Magnitude
							if dist < closestDist then
								closestDist = dist
								nextTarget = enemy
							end
						end
					end
				end
				
				currentStart = targetRoot.Position
				currentTarget = nextTarget
				task.wait(0.08)
			end
		end

	elseif className == "DragonKnight" then
		-- Dragon Breath: Cone spray of flame parts
		local damage = abConfig.Damage or 80
		local duration = abConfig.Duration or 3
		local range = abConfig.Range or 15

		task.spawn(function()
			local elapsed = 0
			local tickInterval = 0.3
			local damagePerTick = (damage / (duration / tickInterval))

			while elapsed < duration and rootPart.Parent and humanoid.Health > 0 do
				elapsed = elapsed + task.wait(tickInterval)

				-- Spray 4 flame balls forward
				for f = 1, 4 do
					local flame = Instance.new("Part")
					flame.Shape = Enum.PartType.Ball
					flame.Size = Vector3.new(1.5, 1.5, 1.5)
					flame.Color = Color3.fromRGB(255, math.random(80, 150), 0)
					flame.Material = Enum.Material.Neon
					flame.CanCollide = false
					flame.Anchored = true
					flame.Position = rootPart.Position + Vector3.new(0, 1.5, 0)
					flame.Parent = workspace

					local forwardOffset = rootPart.CFrame.LookVector * range
					local spread = Vector3.new(math.random(-5, 5), math.random(-2, 2), math.random(-5, 5))
					local targetPos = flame.Position + forwardOffset + spread

					TweenService:Create(flame, TweenInfo.new(0.3), {Position = targetPos, Size = Vector3.new(4, 4, 4), Transparency = 1.0}):Play()
					task.spawn(function() task.wait(0.3) flame:Destroy() end)
				end

				-- Damage enemies in cone
				local activeEnemies = CollectionService:GetTagged("Enemy")
				for _, enemy in ipairs(activeEnemies) do
					if enemy.Parent and enemy:FindFirstChildOfClass("Humanoid") and enemy.Humanoid.Health > 0 then
						local eRoot = enemy.PrimaryPart
						if eRoot then
							local offset = eRoot.Position - rootPart.Position
							if offset.Magnitude <= range then
								local dot = rootPart.CFrame.LookVector:Dot(offset.Unit)
								if dot >= 0.5 then -- 60 degree cone (~0.5 dot product)
									enemy.Humanoid:TakeDamage(damagePerTick)
								end
							end
						end
					end
				end
			end
		end)
	end
end)

-- Player joining connections
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local className = player:GetAttribute("SelectedClass")
		if className then
			task.wait(0.5) -- wait for model load
			ConfigureCharacter(player, character, className)
		end
	end)
end)

-- Handle players already joined during studio testing startup
for _, player in ipairs(Players:GetPlayers()) do
	player.CharacterAdded:Connect(function(character)
		local className = player:GetAttribute("SelectedClass")
		if className then
			task.wait(0.5)
			ConfigureCharacter(player, character, className)
		end
	end)
end

-- Clean up player data references on leaving
Players.PlayerRemoving:Connect(function(player)
	rateLimits[player] = nil
	lastAttackTimes[player] = nil
	lastAbilityTimes[player] = nil
end)

print("[HeroManager] System loaded and listening to SelectClass/UseAbility/BasicAttack.")
