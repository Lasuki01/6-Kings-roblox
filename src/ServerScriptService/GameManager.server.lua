-- ============================================
-- GameManager.server.lua — Kingdom Siege
-- Master game loop orchestrating game states, wave preparation, spawning triggers, and win/loss conditions.
-- Side: Server
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

-- Configuration modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Config = Modules:WaitForChild("Config")
local WaveConfig = require(Config:WaitForChild("WaveConfig"))
local EconomyConfig = require(Config:WaitForChild("EconomyConfig"))
local TowerConfig = require(Config:WaitForChild("TowerConfig"))
local Signals = require(Modules:WaitForChild("Shared"):WaitForChild("Signals"))


-- Remote Events
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local SyncGameState = Remotes:WaitForChild("SyncGameState")

-- Game State Variables
local currentGameState = "Lobby" -- States: Lobby, Intermission, Active, Victory, GameOver
local currentWaveIndex = 0
local INTERMISSION_DURATION = 15 -- Duration between waves in seconds
local activeEnemiesFolder = nil

-- References
local KingdomCrystal = workspace:WaitForChild("KingdomCrystal")
local CrystalHPValue = KingdomCrystal:WaitForChild("CrystalHP")

-- Keep track of spawned enemies in this wave
local totalEnemiesToSpawn = 0
local enemiesSpawnedSoFar = 0
local isSpawningWave = false

-- Initialize game workspace containers
local function InitializeContainers()
	activeEnemiesFolder = workspace:FindFirstChild("Enemies")
	if not activeEnemiesFolder then
		activeEnemiesFolder = Instance.new("Folder")
		activeEnemiesFolder.Name = "Enemies"
		activeEnemiesFolder.Parent = workspace
	end

	-- Clear all towers
	local towersFolder = workspace:FindFirstChild("Towers")
	if towersFolder then
		towersFolder:ClearAllChildren()
	else
		towersFolder = Instance.new("Folder")
		towersFolder.Name = "Towers"
		towersFolder.Parent = workspace
	end

	-- Clear placement zone occupations
	local mapModel = workspace:FindFirstChild("Map")
	if mapModel then
		local placementZones = mapModel:FindFirstChild("PlacementZones")
		if placementZones then
			for _, zone in ipairs(placementZones:GetChildren()) do
				zone:SetAttribute("Occupied", nil)
				local towerModelVal = zone:FindFirstChild("TowerModel")
				if towerModelVal then
					towerModelVal.Value = nil
				end
			end
		end
	end

	-- Reset Crystal HP
	local crystal = workspace:FindFirstChild("KingdomCrystal")
	if crystal then
		local hpVal = crystal:FindFirstChild("CrystalHP")
		if hpVal then
			hpVal.Value = EconomyConfig.CRYSTAL_MAX_HP
		end
	end
end

-- Sync current game state to all players
local function BroadcastGameState()
	workspace:SetAttribute("CurrentWave", currentWaveIndex)
	workspace:SetAttribute("GameState", currentGameState)
	SyncGameState:FireAllClients({
		State = currentGameState,
		Wave = currentWaveIndex,
		CrystalHP = CrystalHPValue.Value,
		MaxWaves = #WaveConfig.Waves
	})
end

-- Open/destroy Dragon Pass gate at Wave 10
local function HandleDragonPassUnlock()
	local dragonGate = workspace:FindFirstChild("DragonGate", true)
	if dragonGate then
		print("Wave 10 reached! Unlocking Dragon Pass. Destroying Dragon Gate...")
		
		-- Simple visual explosion effect at the gate
		local explosion = Instance.new("Explosion")
		explosion.Position = dragonGate.Position
		explosion.BlastRadius = 15
		explosion.BlastPressure = 0 -- No physical knockback to base parts
		explosion.Parent = workspace
		
		dragonGate:Destroy()
	end
end

-- Trigger an enemy spawn (this communicates with EnemyManager when we write it in Phase 4)
local function TriggerEnemySpawn(enemyType, pathName)
	local spawnEvent = Signals.Get("SpawnEnemySignal")
	spawnEvent:Fire(enemyType, pathName)
end

-- Helper to fetch config wave or generate procedural infinite wave
local function GetWaveData(waveIndex)
	local waveData = WaveConfig.Waves[waveIndex]
	if waveData then return waveData end
	
	-- Generate procedurally for Infinite Mode (waveIndex > 20)
	local generated = { Spawns = {} }
	local enemyCount = 15 + (waveIndex - 20) * 3
	
	local baseEnemies = {"Goblin", "Orc", "DarkKnight", "SkeletonMage", "Troll"}
	local paths = {"ForestPath", "UndeadPath", "DragonPass"}
	
	local isBossWave = (waveIndex % 5 == 0)
	
	for i = 1, enemyCount do
		local enemyType = baseEnemies[math.random(1, #baseEnemies)]
		local path = paths[math.random(1, #paths)]
		local delay = math.random(5, 15) / 10 -- 0.5s to 1.5s delay
		
		table.insert(generated.Spawns, {
			EnemyType = enemyType,
			Path = path,
			Delay = delay
		})
	end
	
	-- Append a boss if it is a boss wave
	if isBossWave then
		local bossType = (math.random(1, 2) == 1) and "Dragon" or "LichKing"
		local path = paths[math.random(1, #paths)]
		table.insert(generated.Spawns, {
			EnemyType = bossType,
			Path = path,
			Delay = 2.0
		})
	end
	
	return generated
end

-- Run the wave spawning sequence
local function SpawnWave(waveIndex)
	isSpawningWave = true
	enemiesSpawnedSoFar = 0
	
	local waveData = GetWaveData(waveIndex)
	totalEnemiesToSpawn = #waveData.Spawns
	print("Starting Spawning for Wave " .. waveIndex .. ". Total Enemies: " .. totalEnemiesToSpawn)
	
	for _, spawnEntry in ipairs(waveData.Spawns) do
		if currentGameState ~= "Active" then break end
		
		-- Yield for specified delay before spawning this enemy
		task.wait(spawnEntry.Delay)
		
		-- Trigger spawn
		TriggerEnemySpawn(spawnEntry.EnemyType, spawnEntry.Path)
		enemiesSpawnedSoFar = enemiesSpawnedSoFar + 1
	end
	
	isSpawningWave = false
	print("Wave " .. waveIndex .. " spawning complete.")
end

-- Calculate and distribute wave completion rewards to all players
local function DistributeWaveRewards(waveIndex)
	local baseReward = EconomyConfig.BASE_WAVE_BONUS + (waveIndex * EconomyConfig.WAVE_BONUS_INCREMENT)
	local baseXP = 20 + (waveIndex * 5)
	print("Wave " .. waveIndex .. " completed! Distributing " .. baseReward .. " base Gold and " .. baseXP .. " base XP reward.")
	
	local rewardEvent = Signals.Get("RewardGoldSignal")
	local rewardXPEvent = Signals.Get("RewardXPSignal")
	
	for _, player in ipairs(Players:GetPlayers()) do
		rewardEvent:Fire(player, baseReward)
		rewardXPEvent:Fire(player, baseXP)
	end
end

-- Main state machine loop
local function RunGameLoop()
	InitializeContainers()
	
	-- Connect Crystal death logic
	CrystalHPValue.Changed:Connect(function(newHP)
		if newHP <= 0 and currentGameState ~= "GameOver" then
			currentGameState = "GameOver"
			BroadcastGameState()
			print("Kingdom Crystal destroyed! Game Over!")
		else
			BroadcastGameState()
		end
	end)

	-- Initialize gold system connections
	local rewardEvent = Signals.Get("RewardGoldSignal")
	
	rewardEvent.Event:Connect(function(player, amount)
		local multiplier = 1.0
		if player:GetAttribute("IsVIP") == true then
			multiplier = EconomyConfig.VIP_GOLD_MULTIPLIER or 1.25
		end
		local finalAmount = math.round(amount * multiplier)
		local currentGold = player:GetAttribute("Gold") or 0
		player:SetAttribute("Gold", currentGold + finalAmount)
		print("[GameManager] Credited " .. finalAmount .. " Gold to " .. player.Name .. " (Base: " .. amount .. ", Mult: " .. multiplier .. "). Total: " .. (currentGold + finalAmount))
	end)
	
	-- Sync game state and attributes when players join
	Players.PlayerAdded:Connect(function(player)
		player:SetAttribute("Gold", player:GetAttribute("Gold") or EconomyConfig.STARTING_GOLD)
		player:SetAttribute("TowerSlots", player:GetAttribute("TowerSlots") or TowerConfig.DEFAULT_MAX_TOWERS)
		BroadcastGameState()
	end)

	-- Handle already joined players (for studio testing)
	for _, player in ipairs(Players:GetPlayers()) do
		player:SetAttribute("Gold", player:GetAttribute("Gold") or EconomyConfig.STARTING_GOLD)
		player:SetAttribute("TowerSlots", player:GetAttribute("TowerSlots") or TowerConfig.DEFAULT_MAX_TOWERS)
	end

	while true do
		task.wait(1)
		
		if currentGameState == "Lobby" then
			-- Wait for at least 1 player to join (or developer testing)
			if #Players:GetPlayers() > 0 then
				print("Player joined. Starting intermission...")
				currentGameState = "Intermission"
				BroadcastGameState()
			end
			
		elseif currentGameState == "Intermission" then
			-- Intermission countdown before next wave
			local countdown = INTERMISSION_DURATION
			while countdown > 0 and currentGameState == "Intermission" do
				print("Wave " .. (currentWaveIndex + 1) .. " starts in " .. countdown .. " seconds...")
				task.wait(1)
				countdown = countdown - 1
			end
			
			if currentGameState == "Intermission" then
				currentWaveIndex = currentWaveIndex + 1
				currentGameState = "Active"
				BroadcastGameState()
				
				-- First wave start: increment match count for all players
				if currentWaveIndex == 1 then
					for _, player in ipairs(Players:GetPlayers()) do
						local matches = player:GetAttribute("TotalMatches") or 0
						player:SetAttribute("TotalMatches", matches + 1)
					end
				end
				
				-- Wave 10 special check (Dragon Pass path unlock)
				if currentWaveIndex == 10 then
					HandleDragonPassUnlock()
				end
				
				-- Run wave spawning in a separate thread so loop doesn't freeze
				task.spawn(function()
					SpawnWave(currentWaveIndex)
				end)
			end
			
		elseif currentGameState == "Active" then
			-- Wait for wave spawning to complete and all active enemies to be destroyed
			local activeCount = #activeEnemiesFolder:GetChildren()
			
			if not isSpawningWave and activeCount == 0 then
				print("All enemies defeated for Wave " .. currentWaveIndex)
				
				-- Award gold
				DistributeWaveRewards(currentWaveIndex)
				
				-- Check for win condition (finished 20 waves)
				if currentWaveIndex == #WaveConfig.Waves then
					-- Check if any player has Infinite Mode access pass
					local hasInfiniteAccess = false
					for _, player in ipairs(Players:GetPlayers()) do
						if player:GetAttribute("HasInfiniteAccess") == true then
							hasInfiniteAccess = true
							break
						end
					end
					
					currentGameState = "Victory"
					BroadcastGameState()
					
					-- Victory: increment win count for all players
					for _, player in ipairs(Players:GetPlayers()) do
						local wins = player:GetAttribute("TotalWins") or 0
						player:SetAttribute("TotalWins", wins + 1)
					end
					
					if hasInfiniteAccess then
						print("Victory! Advancing to Infinite Mode in 10s...")
						task.wait(10) -- display victory screen
						currentGameState = "Intermission"
						BroadcastGameState()
					else
						print("Victory! No players have Infinite Mode access. Game ends.")
					end
				else
					currentGameState = "Intermission"
					BroadcastGameState()
				end
			end
			
		elseif currentGameState == "Victory" or currentGameState == "GameOver" then
			if currentGameState == "Victory" then
				print("Victory achieved! Returning players to lobby in 10s...")
			else
				print("Crystal destroyed! Game Over! Returning players to lobby in 10s...")
			end
			
			task.wait(10)
			
			-- Reset all players and reload characters
			for _, player in ipairs(Players:GetPlayers()) do
				player:SetAttribute("SelectedClass", nil)
				player:SetAttribute("Gold", EconomyConfig.STARTING_GOLD)
				task.spawn(function()
					player:LoadCharacter()
				end)
			end
			
			-- Reset wave and state back to Lobby
			currentWaveIndex = 0
			currentGameState = "Lobby"
			BroadcastGameState()
			
			-- Re-initialize all containers
			InitializeContainers()
		end
	end
end

-- Start game master loop
task.spawn(RunGameLoop)
