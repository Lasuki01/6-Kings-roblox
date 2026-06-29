-- ============================================
-- PartyManager.lua — Kingdom Siege
-- Manages multiple independent party instances, one per pad.
-- Side: Server / ModuleScript
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LobbyConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Config"):WaitForChild("LobbyConfig"))
local SyncPartyData = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SyncPartyData")

local PartyManager = {}

-- Dictionary of active parties keyed by padId (1..NUM_PARTY_PADS)
local parties = {}

-- ============================
-- Party Accessors
-- ============================

function PartyManager:GetParty(padId)
	return parties[padId]
end

-- Find which party a player belongs to. Returns padId, party or nil.
function PartyManager:GetPlayerParty(player)
	for padId, party in pairs(parties) do
		for _, m in ipairs(party.Members) do
			if m == player then
				return padId, party
			end
		end
	end
	return nil, nil
end

-- ============================
-- Party Lifecycle
-- ============================

function PartyManager:CreateParty(padId, hostPlayer)
	if parties[padId] then return nil end
	
	-- Player can only be in one party at a time
	local existingPad = self:GetPlayerParty(hostPlayer)
	if existingPad then return nil end
	
	parties[padId] = {
		PadId = padId,
		Host = hostPlayer,
		Members = {hostPlayer},
		MaxPlayers = 3,
		Difficulty = "Normal",
		Privacy = "Public",
		Status = "Lobby", -- Lobby, Countdown, Starting
		Countdown = LobbyConfig.CountdownDuration,
	}
	
	print("[PartyManager] Party created on Pad " .. padId .. ". Host: " .. hostPlayer.Name)
	self:SyncToClients()
	return parties[padId]
end

function PartyManager:JoinParty(padId, player)
	-- Player can only be in one party at a time
	local existingPad = self:GetPlayerParty(player)
	if existingPad then
		if existingPad == padId then
			return parties[padId] -- Already in this party
		end
		return nil, "Already in Party"
	end
	
	if not parties[padId] then
		return self:CreateParty(padId, player)
	end
	
	local party = parties[padId]
	
	-- Allow joining during Lobby or Countdown (not Starting)
	if party.Status == "Starting" then
		warn("[PartyManager] Join rejected on Pad " .. padId .. ": Match is starting.")
		return nil, "Match Starting"
	end
	
	if #party.Members >= party.MaxPlayers then
		warn("[PartyManager] Join rejected on Pad " .. padId .. ": Party Full.")
		return nil, "Party Full"
	end
	
	-- Check duplicates
	for _, m in ipairs(party.Members) do
		if m == player then return party end
	end
	
	table.insert(party.Members, player)
	print("[PartyManager] Player " .. player.Name .. " joined Pad " .. padId)
	self:SyncToClients()
	return party
end

function PartyManager:LeaveParty(player)
	local padId, party = self:GetPlayerParty(player)
	if not padId or not party then return end
	
	local foundIndex = nil
	for i, m in ipairs(party.Members) do
		if m == player then
			foundIndex = i
			break
		end
	end
	
	if not foundIndex then return end
	
	table.remove(party.Members, foundIndex)
	player:SetAttribute("IsReadyUI", nil)
	player:SetAttribute("IsReady", nil)
	print("[PartyManager] Player " .. player.Name .. " left Pad " .. padId)
	
	-- Handle host transfer
	if party.Host == player then
		if #party.Members > 0 then
			party.Host = party.Members[1]
			print("[PartyManager] Host transferred to: " .. party.Host.Name .. " on Pad " .. padId)
			-- Notify new host via attribute
			party.Host:SetAttribute("BecameHost", true)
			task.delay(3, function()
				if parties[padId] and parties[padId].Host then
					parties[padId].Host:SetAttribute("BecameHost", nil)
				end
			end)
		else
			print("[PartyManager] Pad " .. padId .. " party empty. Destroying.")
			parties[padId] = nil
		end
	end
	
	self:SyncToClients()
	return padId
end

function PartyManager:KickPlayer(hostPlayer, targetPlayer)
	local padId, party = self:GetPlayerParty(hostPlayer)
	if not padId or not party then return end
	if party.Host ~= hostPlayer then return end
	if targetPlayer == hostPlayer then return end
	
	-- Verify target is in same party
	local targetPad = self:GetPlayerParty(targetPlayer)
	if targetPad ~= padId then return end
	
	-- Set error toast attribute so client shows feedback
	targetPlayer:SetAttribute("LobbyError", "Kicked by Host")
	
	self:LeaveParty(targetPlayer)
	
	-- Teleport target player out of pad area
	local character = targetPlayer.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		rootPart.CFrame = CFrame.new(LobbyConfig.LobbyCenter + LobbyConfig.ExitTeleportOffset)
	end
end

function PartyManager:SetSettings(hostPlayer, maxPlayers, difficulty, privacy)
	local padId, party = self:GetPlayerParty(hostPlayer)
	if not padId or not party then return end
	if party.Host ~= hostPlayer then return end
	
	-- Validate max players
	local validMax = false
	for _, opt in ipairs(LobbyConfig.MaxPlayersOptions) do
		if opt == maxPlayers then
			validMax = true
			break
		end
	end
	
	if validMax then
		party.MaxPlayers = maxPlayers
		-- Trim overflow members if reduced below current count
		while #party.Members > maxPlayers do
			local overflowPlayer = party.Members[#party.Members]
			print("[PartyManager] Removing overflow player: " .. overflowPlayer.Name .. " from Pad " .. padId)
			overflowPlayer:SetAttribute("LobbyError", "Party Size Reduced")
			self:LeaveParty(overflowPlayer)
			
			local character = overflowPlayer.Character
			local rootPart = character and character:FindFirstChild("HumanoidRootPart")
			if rootPart then
				rootPart.CFrame = CFrame.new(LobbyConfig.LobbyCenter + LobbyConfig.ExitTeleportOffset)
			end
		end
	end
	
	-- Validate difficulty
	local validDiff = false
	for _, diff in ipairs(LobbyConfig.Difficulties) do
		if diff == difficulty then
			validDiff = true
			break
		end
	end
	if validDiff then
		party.Difficulty = difficulty
	end
	
	if privacy == "Public" or privacy == "Private" then
		party.Privacy = privacy
	end
	
	print("[PartyManager] Pad " .. padId .. " settings: MaxPlayers=" .. party.MaxPlayers .. ", Diff=" .. party.Difficulty .. ", Privacy=" .. party.Privacy)
	self:SyncToClients()
end

function PartyManager:SetStatus(padId, status)
	if not parties[padId] then return end
	parties[padId].Status = status
	self:SyncToClients()
end

function PartyManager:SetCountdown(padId, countdown)
	if not parties[padId] then return end
	parties[padId].Countdown = countdown
	self:SyncToClients()
end

function PartyManager:DestroyParty(padId)
	parties[padId] = nil
	self:SyncToClients()
end

-- Clean reset for post-match lobby return
function PartyManager:ResetAllParties()
	print("[PartyManager] Resetting all party data for lobby return.")
	parties = {}
	self:SyncToClients()
end

-- ============================
-- Client Sync
-- ============================

function PartyManager:SyncToClients()
	local allPartiesData = {}
	
	for padId, party in pairs(parties) do
		local membersData = {}
		for _, m in ipairs(party.Members) do
			table.insert(membersData, {
				UserId = m.UserId,
				Name = m.Name,
				DisplayName = m.DisplayName,
				IsHost = (m == party.Host)
			})
		end
		
		allPartiesData[padId] = {
			PadId = padId,
			HostName = party.Host.Name,
			HostDisplayName = party.Host.DisplayName,
			Members = membersData,
			MaxPlayers = party.MaxPlayers,
			Difficulty = party.Difficulty,
			Privacy = party.Privacy,
			Status = party.Status,
			Countdown = party.Countdown,
		}
	end
	
	SyncPartyData:FireAllClients(allPartiesData)
end

-- Monitor player disconnects
Players.PlayerRemoving:Connect(function(player)
	local padId = PartyManager:GetPlayerParty(player)
	if padId then
		PartyManager:LeaveParty(player)
	end
end)

return PartyManager
