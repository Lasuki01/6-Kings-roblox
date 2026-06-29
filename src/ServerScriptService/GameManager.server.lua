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

-- Party cleanup module (for post-match reset)
local ServerScriptService = game:GetService("ServerScriptService")
local PartyManager = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("PartyManager"))


-- Remote Events
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local SyncGameState = Remotes:WaitForChild("SyncGameState")

-- Game State Variables
local currentGameState = "Lobby" -- States: Lobby, Intermission, Active, Victory, GameOver
local isReservedServer = (game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0)
if isReservedServer then
	currentGameState = "Intermission"
end

local currentWaveIndex = 0
local INTERMISSION_DURATION = 15 -- Duration between waves in seconds
local activeEnemiesFolder = nil
local chosenGameMode = "Multiplayer" -- Modes: SinglePlayer, Multiplayer

-- References
local KingdomCrystal = workspace:WaitForChild("KingdomCrystal")
local CrystalHPValue = KingdomCrystal:WaitForChild("CrystalHP")

-- Keep track of spawned enemies in this wave
local totalEnemiesToSpawn = 0
local enemiesSpawnedSoFar = 0
local isSpawningWave = false

-- Dynamic path scaling state
local activePaths = { "ForestPath", "UndeadPath", "DragonPass" }
local playerScaleHP = 1.0
local playerScaleSpeed = 1.0

-- Dynamically distribute players across active paths
local function AssignPlayerPaths()
	local players = Players:GetPlayers()
	local activePathsCount = #activePaths
	if activePathsCount == 0 then return end
	
	table.sort(players, function(a, b)
		return a.UserId < b.UserId
	end)

	for i, player in ipairs(players) do
		local pathIndex = ((i - 1) % activePathsCount) + 1
		local assignedPath = activePaths[pathIndex]
		player:SetAttribute("AssignedPath", assignedPath)
		print("[GameManager] Assigned player " .. player.Name .. " to path: " .. assignedPath)
	end
end

-- Determine which paths should be active based on current player count
local function DetermineActivePaths()
	local playerCount = #Players:GetPlayers()
	if chosenGameMode == "SinglePlayer" then
		playerCount = 1
	end
	local paths = { "ForestPath", "UndeadPath", "DragonPass" } -- fallback: all open

	for _, tier in ipairs(WaveConfig.PATH_THRESHOLDS) do
		if playerCount <= tier.MaxPlayers then
			paths = tier.ActivePaths
			break
		end
	end

	activePaths = paths
	print("[GameManager] Active paths for " .. playerCount .. " players: " .. table.concat(activePaths, ", "))
	
	-- Assign players to paths
	AssignPlayerPaths()
	
	return paths
end

-- Calculate enemy HP and Speed scaling multipliers based on player count
local function CalculatePlayerScaling()
	local playerCount = #Players:GetPlayers()
	if chosenGameMode == "SinglePlayer" then
		playerCount = 1
	end
	local extraPlayers = math.max(0, playerCount - 1)

	playerScaleHP = 1.0 + extraPlayers * WaveConfig.PLAYER_SCALING.HP_PER_PLAYER
	playerScaleSpeed = 1.0 + extraPlayers * WaveConfig.PLAYER_SCALING.SPEED_PER_PLAYER

	print("[GameManager] Player scaling — HP: x" .. string.format("%.2f", playerScaleHP) .. ", Speed: x" .. string.format("%.2f", playerScaleSpeed))
end

-- Check if a path is currently active
local function IsPathActive(pathName)
	if pathName == "DragonPass" and currentWaveIndex < 10 then
		return false
	end
	for _, p in ipairs(activePaths) do
		if p == pathName then return true end
	end
	return false
end

-- Reroute an enemy from a closed path to the first available active path
local function ReroutePath(originalPath)
	for _, candidate in ipairs(WaveConfig.PATH_PRIORITY) do
		if IsPathActive(candidate) then
			return candidate
		end
	end
	-- Fallback: if nothing active, use ForestPath (should never happen)
	return "ForestPath"
end

-- Manage path gate visibility — show gates on closed paths, hide on open ones
local function UpdatePathGates()
	local gateMap = {
		ForestPath = "ForestGate",
		UndeadPath = "UndeadGate",
		DragonPass = "DragonGate",
	}

	local playerCount = #Players:GetPlayers()
	if chosenGameMode == "SinglePlayer" then
		playerCount = 1
	end

	for pathName, gateName in pairs(gateMap) do
		local gate = workspace:FindFirstChild(gateName, true)
		if gate then
			local isOpen = IsPathActive(pathName)
			-- Toggle main gate part (0 = solid/opaque, 1 = open/invisible)
			gate.Transparency = isOpen and 1 or 0
			gate.CanCollide = not isOpen

			-- Toggle child parts, light, and surface notices using descendants
			for _, desc in ipairs(gate:GetDescendants()) do
				if desc:IsA("BasePart") and desc ~= gate then
					desc.Transparency = isOpen and 1 or 0
				elseif desc:IsA("SurfaceGui") then
					desc.Enabled = not isOpen
					-- Update requirement notice text dynamically
					local label = desc:FindFirstChildOfClass("TextLabel")
					if label then
						local noticeText = "LOCKED"
						if pathName == "ForestPath" then
							noticeText = "LOCKED\nREQUIRES 1+ PLAYERS"
						elseif pathName == "UndeadPath" then
							noticeText = "LOCKED\nREQUIRES 3+ PLAYERS"
						elseif pathName == "DragonPass" then
							if currentWaveIndex < 10 then
								if playerCount < 5 and chosenGameMode ~= "SinglePlayer" then
									noticeText = "LOCKED\nREQ. 5+ PLAYERS & WAVE 10"
								else
									noticeText = "LOCKED\nUNLOCKS AT WAVE 10"
								end
							else
								noticeText = "LOCKED\nREQUIRES 5+ PLAYERS"
							end
						end
						label.Text = noticeText
					end
				elseif desc:IsA("PointLight") then
					desc.Enabled = not isOpen
				end
			end
		end
	end
end

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

	-- Clear all skeleton minions
	local minionsFolder = workspace:FindFirstChild("Minions")
	if minionsFolder then
		minionsFolder:ClearAllChildren()
	else
		minionsFolder = Instance.new("Folder")
		minionsFolder.Name = "Minions"
		minionsFolder.Parent = workspace
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

	-- Reset path gates to default closed state (transparency 0, CanCollide true)
	local gateMap = {
		ForestGate = true,
		UndeadGate = true,
		DragonGate = true,
	}
	for gateName in pairs(gateMap) do
		local gate = workspace:FindFirstChild(gateName, true)
		if gate then
			gate:SetAttribute("Unlocked", nil)
			gate.Transparency = 0
			gate.CanCollide = true
			for _, desc in ipairs(gate:GetDescendants()) do
				if desc:IsA("BasePart") and desc ~= gate then
					desc.Transparency = 0
				elseif desc:IsA("SurfaceGui") then
					desc.Enabled = true
				elseif desc:IsA("PointLight") then
					desc.Enabled = true
				end
			end
		end
	end
end

-- Toggle Enabled states of Lobby/Map SpawnLocations based on current GameState
local function UpdateSpawnLocations(state)
	local lobbySpawn1 = workspace:FindFirstChild("LobbySpawnLocation", true)
	local lobbySpawn2 = workspace:FindFirstChild("LobbySpawnFallback", true)
	local mapSpawn = workspace:FindFirstChild("MapSpawnLocation", true)
	
	local isLobby = (state == "Lobby")
	
	if lobbySpawn1 then
		lobbySpawn1.Enabled = isLobby
	end
	if lobbySpawn2 then
		lobbySpawn2.Enabled = isLobby
	end
	if mapSpawn then
		mapSpawn.Enabled = not isLobby
	end
	print("[GameManager] Spawns updated for State: " .. state .. ". Lobby Spawns Enabled: " .. tostring(isLobby) .. ", Map Spawn Enabled: " .. tostring(not isLobby))
end

-- Sync current game state to all players
local function BroadcastGameState()
	workspace:SetAttribute("CurrentWave", currentWaveIndex)
	workspace:SetAttribute("GameState", currentGameState)
	
	-- Update active spawn locations
	UpdateSpawnLocations(currentGameState)
	
	local payload = {
		State = currentGameState,
		Wave = currentWaveIndex,
		CrystalHP = CrystalHPValue.Value,
		MaxWaves = #WaveConfig.Waves,
		ActivePaths = activePaths,
	}
	
	SyncGameState:FireAllClients(payload)
end

-- Open Dragon Pass gate at Wave 10
local function HandleDragonPassUnlock()
	local dragonGate = workspace:FindFirstChild("DragonGate", true)
	if dragonGate then
		print("Wave 10 reached! Unlocking Dragon Pass. Disabling Dragon Gate...")
		
		-- Simple visual explosion effect at the gate
		local explosion = Instance.new("Explosion")
		explosion.Position = dragonGate.Position
		explosion.BlastRadius = 15
		explosion.BlastPressure = 0 -- No physical knockback to base parts
		explosion.Parent = workspace
		
		dragonGate:SetAttribute("Unlocked", true)
		
		-- Disable gate visually and physically
		dragonGate.Transparency = 1
		dragonGate.CanCollide = false
		for _, child in ipairs(dragonGate:GetChildren()) do
			if child:IsA("BasePart") then
				child.Transparency = 1
			end
			local light = child:FindFirstChildOfClass("PointLight")
			if light then
				light.Enabled = false
			end
		end
	end
end

-- Trigger an enemy spawn with scaling data
-- EnemyManager reads hpScale/speedScale to multiply base stats
local function TriggerEnemySpawn(enemyType, pathName)
	local spawnEvent = Signals.Get("SpawnEnemySignal")
	spawnEvent:Fire(enemyType, pathName, playerScaleHP, playerScaleSpeed)
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
-- Enemies on closed paths get rerouted to the first available active path
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
		
		-- Reroute enemy if its path is closed
		local finalPath = spawnEntry.Path
		if not IsPathActive(finalPath) then
			local rerouted = ReroutePath(finalPath)
			print("[GameManager] Rerouting " .. spawnEntry.EnemyType .. " from " .. finalPath .. " -> " .. rerouted)
			finalPath = rerouted
		end
		
		-- Dragon Pass special: even if active, only allow after Wave 10
		if finalPath == "DragonPass" and waveIndex < 10 then
			finalPath = ReroutePath("DragonPass")
		end
		
		-- Trigger spawn on the resolved path
		TriggerEnemySpawn(spawnEntry.EnemyType, finalPath)
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

-- Start match transition (defined before RunGameLoop so signal handler can reference it)
local function StartMatch()
	currentGameState = "Intermission"
	DetermineActivePaths()
	CalculatePlayerScaling()
	UpdatePathGates()
	BroadcastGameState()
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
	
	-- Listen for local matchmaking start signal
	local startSignal = Signals.Get("StartMatchSignal")
	if startSignal then
		startSignal.Event:Connect(function(matchData)
			if currentGameState ~= "Lobby" then return end
			
			if matchData and matchData.Difficulty then
				print("[GameManager] Match started from lobby with difficulty: " .. matchData.Difficulty)
			end
			
			chosenGameMode = (matchData.MaxPlayers == 1) and "SinglePlayer" or "Multiplayer"
			
			StartMatch()
		end)
	end

	-- Sync state when players leave
	Players.PlayerRemoving:Connect(function(player)
		task.defer(function()
			if currentGameState == "Active" or currentGameState == "Intermission" then
				DetermineActivePaths()
			end
			BroadcastGameState()
		end)
	end)
	
	-- Sync game state and attributes when players join
	Players.PlayerAdded:Connect(function(player)
		player:SetAttribute("Gold", player:GetAttribute("Gold") or EconomyConfig.STARTING_GOLD)
		player:SetAttribute("TowerSlots", player:GetAttribute("TowerSlots") or TowerConfig.DEFAULT_MAX_TOWERS)
		if currentGameState == "Active" or currentGameState == "Intermission" then
			DetermineActivePaths()
		end
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
			-- Proximity joins, countdowns, and teleports are managed by LobbyZoneController and PartyService.
			-- GameManager simply waits for the GameState to change.
			task.wait(1)
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
				
				-- Recalculate active paths and player scaling each wave
				DetermineActivePaths()
				CalculatePlayerScaling()
				UpdatePathGates()
				
				currentGameState = "Active"
				BroadcastGameState()
				
				-- First wave start: increment match count for all players
				if currentWaveIndex == 1 then
					for _, player in ipairs(Players:GetPlayers()) do
						local matches = player:GetAttribute("TotalMatches") or 0
						player:SetAttribute("TotalMatches", matches + 1)
					end
				end
				
				-- Dragon Pass unlock check: if wave >= 10 and path active, unlock it
				if currentWaveIndex >= 10 and IsPathActive("DragonPass") then
					local dragonGate = workspace:FindFirstChild("DragonGate", true)
					if dragonGate and not dragonGate:GetAttribute("Unlocked") then
						HandleDragonPassUnlock()
					end
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
			
			-- Reset wave and state back to Lobby first to enable Lobby SpawnLocation
			currentWaveIndex = 0
			currentGameState = "Lobby"
			chosenGameMode = "Multiplayer"
			workspace:SetAttribute("GameMode", nil)
			BroadcastGameState()
			
			-- Reset all players and reload characters (now they spawn in the lobby)
			for _, player in ipairs(Players:GetPlayers()) do
				player:SetAttribute("SelectedClass", nil)
				player:SetAttribute("IsReady", nil)
				player:SetAttribute("IsReadyUI", nil)
				player:SetAttribute("Gold", EconomyConfig.STARTING_GOLD)
				task.spawn(function()
					player:LoadCharacter()
				end)
			end
			
			-- Clean up any stale party data from previous match
			PartyManager:ResetAllParties()
			
			-- Re-initialize all containers
			InitializeContainers()
		end
	end
end

-- Start game master loop
task.spawn(RunGameLoop)
