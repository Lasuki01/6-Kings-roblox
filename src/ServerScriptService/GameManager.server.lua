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
end

-- Sync current game state to all players
local function BroadcastGameState()
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
-- For now, we will print and prepare to spawn, which will connect cleanly with Phase 4
local function TriggerEnemySpawn(enemyType, pathName)
	-- BindableEvent or tag system to communicate to EnemyManager
	-- We'll fire a BindableEvent or tag it for the EnemyManager to pick up
	local spawnEvent = ReplicatedStorage:FindFirstChild("SpawnEnemySignal")
	if not spawnEvent then
		spawnEvent = Instance.new("BindableEvent")
		spawnEvent.Name = "SpawnEnemySignal"
		spawnEvent.Parent = ReplicatedStorage
	end
	spawnEvent:Fire(enemyType, pathName)
end

-- Run the wave spawning sequence
local function SpawnWave(waveIndex)
	isSpawningWave = true
	enemiesSpawnedSoFar = 0
	
	local waveData = WaveConfig.Waves[waveIndex]
	if not waveData then
		warn("No wave configuration found for wave " .. waveIndex)
		isSpawningWave = false
		return
	end
	
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
	print("Wave " .. waveIndex .. " completed! Distributing " .. baseReward .. " base Gold reward.")
	
	-- We will fire a bindable event for the GoldManager (Phase 7)
	local rewardEvent = ReplicatedStorage:FindFirstChild("RewardGoldSignal")
	if not rewardEvent then
		rewardEvent = Instance.new("BindableEvent")
		rewardEvent.Name = "RewardGoldSignal"
		rewardEvent.Parent = ReplicatedStorage
	end
	
	for _, player in ipairs(Players:GetPlayers()) do
		-- Trigger gold addition (GoldManager handles multipliers for VIP passes)
		rewardEvent:Fire(player, baseReward)
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
	
	-- Sync game state when players join
	Players.PlayerAdded:Connect(function(player)
		BroadcastGameState()
	end)

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
				if currentWaveIndex >= #WaveConfig.Waves then
					currentGameState = "Victory"
					BroadcastGameState()
					print("Victory! Survives all 20 waves!")
				else
					currentGameState = "Intermission"
					BroadcastGameState()
				end
			end
			
		elseif currentGameState == "Victory" then
			-- End loop / handles rewards or return to lobby logic
			print("Game finished. Victory achieved!")
			break
			
		elseif currentGameState == "GameOver" then
			-- End loop / game over sequence
			print("Game finished. Crystal destroyed!")
			break
		end
	end
end

-- Start game master loop
task.spawn(RunGameLoop)
