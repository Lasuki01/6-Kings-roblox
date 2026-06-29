-- ============================================
-- DataManager.server.lua — Kingdom Siege
-- Side: Server
-- Handles persistent saving and loading of player statistics, owned classes, gems, and levels via DataStoreService.
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

-- Configuration modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Config = Modules:WaitForChild("Config")
local EconomyConfig = require(Config:WaitForChild("EconomyConfig"))
local Signals = require(Modules:WaitForChild("Shared"):WaitForChild("Signals"))

-- Data Store Name
local PlayerDataStore = DataStoreService:GetDataStore("KingdomSiege_PlayerData_v1")

-- Remote / Bindable Signals
local RewardXPSignal = Signals.Get("RewardXPSignal")
local AddOwnedClassSignal = Signals.Get("AddOwnedClassSignal")

-- Default player data schema
local DEFAULT_DATA = {
	XP = 0,
	Level = 1,
	Gems = 0,
	TowerSlots = 5,
	OwnedClasses = {"Knight", "Ranger"},
	TotalWins = 0,
	TotalMatches = 0,
}

-- In-memory session cache for non-primitive tables (e.g. OwnedClasses list)
local sessionData = {}
local activeSaves = {}

-- Load player data
local function LoadPlayerData(player)
	local userId = player.UserId
	local dataKey = "PlayerData_" .. userId
	
	local success, data = pcall(function()
		return PlayerDataStore:GetAsync(dataKey)
	end)
	
	if not success or not data then
		if not success then
			warn("[DataManager] DataStore GetAsync failed for player " .. player.Name .. ". Using defaults.")
		else
			print("[DataManager] No previous data found for " .. player.Name .. ". Initializing default profile.")
		end
		
		-- Deep copy default profile
		data = {}
		for k, v in pairs(DEFAULT_DATA) do
			if type(v) == "table" then
				data[k] = {unpack(v)}
			else
				data[k] = v
			end
		end
	end
	
	-- Verify and load schema fields into session cache
	for k, v in pairs(DEFAULT_DATA) do
		if data[k] == nil then
			if type(v) == "table" then
				data[k] = {unpack(v)}
			else
				data[k] = v
			end
		end
	end
	
	sessionData[player] = data
	
	-- Load parameters into player attributes
	player:SetAttribute("XP", data.XP)
	player:SetAttribute("Level", data.Level)
	player:SetAttribute("Gems", data.Gems)
	player:SetAttribute("TowerSlots", data.TowerSlots)
	player:SetAttribute("TotalWins", data.TotalWins)
	player:SetAttribute("TotalMatches", data.TotalMatches)
	
	-- Sync owned classes attributes
	for _, className in ipairs(data.OwnedClasses) do
		player:SetAttribute("Owns" .. className .. "Class", true)
	end
	
	-- Support alternate names for class passes
	player:SetAttribute("OwnsStormClass", player:GetAttribute("OwnsStormCallerClass"))
	player:SetAttribute("OwnsDragonClass", player:GetAttribute("OwnsDragonKnightClass"))
	
	print("[DataManager] Successfully loaded profile for: " .. player.Name .. " (Level: " .. data.Level .. ")")
end

-- Save player data
local function SavePlayerData(player)
	if activeSaves[player] then
		while activeSaves[player] do
			task.wait(0.1)
		end
		return
	end
	
	local data = sessionData[player]
	if not data then return end
	
	activeSaves[player] = true
	
	-- Sync current values from player attributes back to table
	data.XP = player:GetAttribute("XP") or 0
	data.Level = player:GetAttribute("Level") or 1
	data.Gems = player:GetAttribute("Gems") or 0
	data.TowerSlots = player:GetAttribute("TowerSlots") or 5
	data.TotalWins = player:GetAttribute("TotalWins") or 0
	data.TotalMatches = player:GetAttribute("TotalMatches") or 0
	
	local dataKey = "PlayerData_" .. player.UserId
	
	local success, err = pcall(function()
		PlayerDataStore:SetAsync(dataKey, data)
	end)
	
	if success then
		print("[DataManager] Saved data successfully for player: " .. player.Name)
	else
		warn("[DataManager] Failed to save player data for " .. player.Name .. ". Error: " .. tostring(err))
	end
	
	activeSaves[player] = nil
end

-- Hook up XP and Leveling Up logic
RewardXPSignal.Event:Connect(function(player, amount)
	if amount <= 0 then return end
	
	-- Apply double XP multiplier if pass is owned
	local mult = 1.0
	if player:GetAttribute("HasDoubleXP") == true then
		mult = EconomyConfig.XP_MULTIPLIER or 2.0
	end
	
	local xpReward = math.round(amount * mult)
	local currentXP = player:GetAttribute("XP") or 0
	local currentLevel = player:GetAttribute("Level") or 1
	
	local newXP = currentXP + xpReward
	local neededXP = currentLevel * 100
	
	while newXP >= neededXP do
		newXP = newXP - neededXP
		currentLevel = currentLevel + 1
		neededXP = currentLevel * 100
		print("[DataManager] " .. player.Name .. " LEVELED UP to Level " .. currentLevel .. "!")
		-- Trigger cosmetic / leveling celebration events here if wanted
	end
	
	player:SetAttribute("XP", newXP)
	player:SetAttribute("Level", currentLevel)
	print("[DataManager] Granted " .. xpReward .. " XP to " .. player.Name .. ". Progress: " .. newXP .. "/" .. neededXP)
end)

-- Hook up class unlock logic
AddOwnedClassSignal.Event:Connect(function(player, className)
	local data = sessionData[player]
	if not data then return end
	
	-- Check if class is already owned
	local alreadyOwned = false
	for _, name in ipairs(data.OwnedClasses) do
		if name == className then
			alreadyOwned = true
			break
		end
	end
	
	if not alreadyOwned then
		table.insert(data.OwnedClasses, className)
		player:SetAttribute("Owns" .. className .. "Class", true)
		
		-- Synchronize potential class aliases
		if className == "StormCaller" then
			player:SetAttribute("OwnsStormClass", true)
		elseif className == "DragonKnight" then
			player:SetAttribute("OwnsDragonClass", true)
		end
		
		print("[DataManager] Class locked/purchased added persistently: " .. className .. " for " .. player.Name)
		
		-- Autosave on important purchases immediately
		task.spawn(SavePlayerData, player)
	end
end)

-- Hook events
Players.PlayerAdded:Connect(LoadPlayerData)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(LoadPlayerData, player)
end

Players.PlayerRemoving:Connect(function(player)
	SavePlayerData(player)
	sessionData[player] = nil
end)

-- Safeguard saving when server shuts down
game:BindToClose(function()
	print("[DataManager] Server shutting down. Saving all player data...")
	local threads = {}
	
	for _, player in ipairs(Players:GetPlayers()) do
		local t = task.spawn(function()
			SavePlayerData(player)
		end)
		table.insert(threads, t)
	end
	
	-- Wait for all saving threads to complete safely before closing
	for _, thread in ipairs(threads) do
		while coroutine.status(thread) ~= "dead" do
			task.wait(0.1)
		end
	end
	
	print("[DataManager] Shutdown saving complete.")
end)

print("[DataManager] Persistence system loaded.")
