-- ============================================
-- TeleportManager.lua — Kingdom Siege
-- Handles matchmaking teleportation to Battle Place or local simulation fallback.
-- Side: Server / ModuleScript
-- ============================================

local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LobbyConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Config"):WaitForChild("LobbyConfig"))
local Signals = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Shared"):WaitForChild("Signals"))

local TeleportManager = {}

function TeleportManager:TeleportParty(partyData)
	local playersList = partyData.Members
	if #playersList == 0 then return end
	
	print("[TeleportManager] Preparing teleportation for " .. #playersList .. " players...")
	
	local placeId = LobbyConfig.BattlePlaceId
	if placeId and placeId > 0 and not RunService:IsStudio() then
		-- Actual reserved server matchmaking teleport
		local success, err = pcall(function()
			local reservedCode = TeleportService:ReserveServer(placeId)
			local teleportData = {
				Difficulty = partyData.Difficulty,
				MaxPlayers = partyData.MaxPlayers,
				GameMode = (partyData.MaxPlayers == 1) and "SinglePlayer" or "Multiplayer"
			}
			
			-- Fire teleport on players list
			TeleportService:TeleportToPrivateServer(placeId, reservedCode, playersList, nil, teleportData)
		end)
		
		if success then
			print("[TeleportManager] Teleport initiated successfully!")
		else
			warn("[TeleportManager] Teleport failed: " .. tostring(err))
			-- Fallback to local simulation on failure
			self:LocalTeleportFallback(partyData)
		end
	else
		-- Local Studio / Single-Place simulation fallback
		self:LocalTeleportFallback(partyData)
	end
end

function TeleportManager:LocalTeleportFallback(partyData)
	print("[TeleportManager] Running local simulation fallback. Initializing map spawning...")
	
	-- 1. Fire StartMatchSignal to change game state, which enables the MapSpawnLocation on the keep
	local startSignal = Signals.Get("StartMatchSignal")
	if startSignal then
		local matchData = {
			MaxPlayers = partyData.MaxPlayers,
			Difficulty = partyData.Difficulty,
		}
		startSignal:Fire(matchData)
	end
	
	-- 2. Wait a brief moment to ensure state change and spawn locations replicate
	task.wait(0.1)

	-- 3. Reload character for each player in the match to spawn them directly on the map Keep Spawn
	local playersList = partyData.Members
	for _, player in ipairs(playersList) do
		task.spawn(function()
			player:LoadCharacter()
		end)
	end
end

return TeleportManager
