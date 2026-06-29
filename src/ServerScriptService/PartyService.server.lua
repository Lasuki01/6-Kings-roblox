-- ============================================
-- PartyService.server.lua — Kingdom Siege
-- Coordinates remote events and triggers teleportation countdowns per pad.
-- Side: Server
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Modules = ServerScriptService:WaitForChild("Modules")
local PartyManager = require(Modules:WaitForChild("PartyManager"))
local TeleportManager = require(Modules:WaitForChild("TeleportManager"))

local LobbyConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Config"):WaitForChild("LobbyConfig"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ExitParty = Remotes:WaitForChild("ExitParty")
local KickPlayer = Remotes:WaitForChild("KickPlayer")
local StartPartyRun = Remotes:WaitForChild("StartPartyRun")
local UpdatePartySettings = Remotes:WaitForChild("UpdatePartySettings")

-- Rate limiting per player
local rateLimits = {} -- [player] = lastActionTick
local RATE_LIMIT = LobbyConfig.RATE_LIMIT_SECONDS or 0.5

local function IsRateLimited(player)
	local now = os.clock()
	local last = rateLimits[player]
	if last and (now - last) < RATE_LIMIT then
		return true
	end
	rateLimits[player] = now
	return false
end

Players.PlayerRemoving:Connect(function(player)
	rateLimits[player] = nil
end)

-- Countdown threads per pad
local countdownThreads = {} -- [padId] = thread

local function CancelCountdown(padId)
	if countdownThreads[padId] then
		task.cancel(countdownThreads[padId])
		countdownThreads[padId] = nil
	end
	
	local party = PartyManager:GetParty(padId)
	if party then
		PartyManager:SetStatus(padId, "Lobby")
		PartyManager:SetCountdown(padId, LobbyConfig.CountdownDuration)
		print("[PartyService] Countdown cancelled on Pad " .. padId)
	end
end

local function StartCountdown(padId)
	local party = PartyManager:GetParty(padId)
	if not party or party.Status ~= "Lobby" then return end
	
	PartyManager:SetStatus(padId, "Countdown")
	local duration = LobbyConfig.CountdownDuration
	PartyManager:SetCountdown(padId, duration)
	
	-- Use task.delay so task.cancel works correctly
	countdownThreads[padId] = task.delay(0, function()
		while duration > 0 do
			task.wait(1)
			duration = duration - 1
			
			party = PartyManager:GetParty(padId)
			if not party or #party.Members == 0 or party.Status ~= "Countdown" then
				CancelCountdown(padId)
				return
			end
			
			PartyManager:SetCountdown(padId, duration)
		end
		
		-- Teleport players
		party = PartyManager:GetParty(padId)
		if party and #party.Members > 0 then
			PartyManager:SetStatus(padId, "Starting")
			TeleportManager:TeleportParty(party)
			PartyManager:DestroyParty(padId)
		end
		countdownThreads[padId] = nil
	end)
end

-- Hook up RemoteEvents

-- Exit Party: auto-detects which party player is in
ExitParty.OnServerEvent:Connect(function(player)
	if IsRateLimited(player) then return end
	
	print("[PartyService] " .. player.Name .. " requested exit party.")
	local padId = PartyManager:LeaveParty(player)
	
	-- Teleport player back to Lobby spawn
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		rootPart.CFrame = CFrame.new(LobbyConfig.LobbyCenter + LobbyConfig.ExitTeleportOffset)
	end
	
	-- Cancel countdown if party emptied or host left during countdown
	if padId then
		local party = PartyManager:GetParty(padId)
		if party and party.Status == "Countdown" then
			if #party.Members == 0 or not party.Host then
				CancelCountdown(padId)
			end
		end
	end
end)

KickPlayer.OnServerEvent:Connect(function(player, targetPlayer)
	if IsRateLimited(player) then return end
	
	local padId = PartyManager:GetPlayerParty(player)
	PartyManager:KickPlayer(player, targetPlayer)
	
	if padId then
		local party = PartyManager:GetParty(padId)
		if party and party.Status == "Countdown" then
			if #party.Members == 0 then
				CancelCountdown(padId)
			end
		end
	end
end)

UpdatePartySettings.OnServerEvent:Connect(function(player, maxPlayers, difficulty, privacy)
	if IsRateLimited(player) then return end
	
	PartyManager:SetSettings(player, maxPlayers, difficulty, privacy)
end)

StartPartyRun.OnServerEvent:Connect(function(player)
	if IsRateLimited(player) then return end
	
	local padId, party = PartyManager:GetPlayerParty(player)
	if party and party.Host == player and party.Status == "Lobby" then
		StartCountdown(padId)
	end
end)

print("[PartyService] Multi-pad matching service active and listening to remotes.")
