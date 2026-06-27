-- ============================================
-- MonetizationManager.server.lua — Kingdom Siege
-- Side: Server
-- Manages game passes checking, developer product purchases receipt processing, VIP multipliers, and purchase prompts.
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

-- Configuration modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Config = Modules:WaitForChild("Config")
local EconomyConfig = require(Config:WaitForChild("EconomyConfig"))

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PurchaseItem = Remotes:WaitForChild("PurchaseItem")

-- Initialize Gem and Revive balances on player join
local function InitializePlayerAttributes(player)
	player:SetAttribute("Gems", player:GetAttribute("Gems") or 0)
	player:SetAttribute("ReviveTokens", player:GetAttribute("ReviveTokens") or 0)
end

-- Check game pass ownership for all classes and perks
local function CheckPassOwnership(player)
	local userId = player.UserId
	
	local function checkPass(passId, attributeName)
		if passId == 0 then
			-- Mocking: default to false in Studio/test environment so developers can trigger purchase prompts
			player:SetAttribute(attributeName, false)
			return
		end
		
		local success, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(userId, passId)
		end)
		
		if success then
			player:SetAttribute(attributeName, owns)
		else
			warn("[MonetizationManager] Failed to check game pass ownership for " .. attributeName)
			player:SetAttribute(attributeName, false)
		end
	end

	checkPass(EconomyConfig.PassIds.MAGE_PASS_ID, "OwnsMageClass")
	checkPass(EconomyConfig.PassIds.NECRO_PASS_ID, "OwnsNecromancerClass")
	checkPass(EconomyConfig.PassIds.STORM_PASS_ID, "OwnsStormCallerClass")
	checkPass(EconomyConfig.PassIds.DRAGON_PASS_ID, "OwnsDragonKnightClass")
	checkPass(EconomyConfig.PassIds.VIP_PASS_ID, "IsVIP")
	checkPass(EconomyConfig.PassIds.XP_PASS_ID, "HasDoubleXP")
	checkPass(EconomyConfig.PassIds.INFINITE_PASS_ID, "HasInfiniteAccess")
	
	-- Additional helper attributes for alternative naming conventions
	player:SetAttribute("OwnsStormClass", player:GetAttribute("OwnsStormCallerClass"))
	player:SetAttribute("OwnsDragonClass", player:GetAttribute("OwnsDragonKnightClass"))
end

-- Process completed Developer Product purchases
local function ProcessReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- Player left the server before granting reward, try again next join
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
	local productId = receiptInfo.ProductId
	local granted = false
	
	if productId == EconomyConfig.ProductIds.GEMS_500_ID then
		local current = player:GetAttribute("Gems") or 0
		player:SetAttribute("Gems", current + 500)
		granted = true
	elseif productId == EconomyConfig.ProductIds.GEMS_1500_ID then
		local current = player:GetAttribute("Gems") or 0
		player:SetAttribute("Gems", current + 1500)
		granted = true
	elseif productId == EconomyConfig.ProductIds.GEMS_5000_ID then
		local current = player:GetAttribute("Gems") or 0
		player:SetAttribute("Gems", current + 5000)
		granted = true
	elseif productId == EconomyConfig.ProductIds.REVIVE_TOKEN_ID then
		local revives = player:GetAttribute("ReviveTokens") or 0
		player:SetAttribute("ReviveTokens", revives + 1)
		granted = true
	elseif productId == EconomyConfig.ProductIds.TOWER_SLOT_ID then
		local current = player:GetAttribute("TowerSlots") or 5
		player:SetAttribute("TowerSlots", current + 1)
		granted = true
	end
	
	if granted then
		print("[MonetizationManager] Receipt processed. Granted ProductID: " .. productId .. " to " .. player.Name)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	else
		warn("[MonetizationManager] Receipt failed to match any developer products: " .. productId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

-- Register ProcessReceipt callback
MarketplaceService.ProcessReceipt = ProcessReceipt

-- Handle real-time purchase finish event for Game Passes
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
	if wasPurchased then
		print("[MonetizationManager] Player " .. player.Name .. " purchased game pass: " .. passId)
		local AddOwnedClassSignal = ReplicatedStorage:FindFirstChild("AddOwnedClassSignal")
		
		if passId == EconomyConfig.PassIds.MAGE_PASS_ID then
			player:SetAttribute("OwnsMageClass", true)
			if AddOwnedClassSignal then AddOwnedClassSignal:Fire(player, "Mage") end
		elseif passId == EconomyConfig.PassIds.NECRO_PASS_ID then
			player:SetAttribute("OwnsNecromancerClass", true)
			if AddOwnedClassSignal then AddOwnedClassSignal:Fire(player, "Necromancer") end
		elseif passId == EconomyConfig.PassIds.STORM_PASS_ID then
			player:SetAttribute("OwnsStormCallerClass", true)
			player:SetAttribute("OwnsStormClass", true)
			if AddOwnedClassSignal then AddOwnedClassSignal:Fire(player, "StormCaller") end
		elseif passId == EconomyConfig.PassIds.DRAGON_PASS_ID then
			player:SetAttribute("OwnsDragonKnightClass", true)
			player:SetAttribute("OwnsDragonClass", true)
			if AddOwnedClassSignal then AddOwnedClassSignal:Fire(player, "DragonKnight") end
		elseif passId == EconomyConfig.PassIds.VIP_PASS_ID then
			player:SetAttribute("IsVIP", true)
		elseif passId == EconomyConfig.PassIds.XP_PASS_ID then
			player:SetAttribute("HasDoubleXP", true)
		elseif passId == EconomyConfig.PassIds.INFINITE_PASS_ID then
			player:SetAttribute("HasInfiniteAccess", true)
		end
	end
end)

-- Handle incoming PurchaseItem remote events (mock testing + triggering prompts)
PurchaseItem.OnServerEvent:Connect(function(player, itemType, itemKey)
	if itemType == "GamePass" then
		local passId = EconomyConfig.PassIds[itemKey]
		if not passId then
			warn("[MonetizationManager] Unknown game pass key: " .. tostring(itemKey))
			return
		end
		
		if passId == 0 then
			-- Simulating mock purchase success in Roblox Studio
			print("[MonetizationManager] Mocking game pass purchase: " .. itemKey .. " for " .. player.Name)
			local AddOwnedClassSignal = ReplicatedStorage:FindFirstChild("AddOwnedClassSignal")
			
			if itemKey == "MAGE_PASS_ID" then
				player:SetAttribute("OwnsMageClass", true)
				if AddOwnedClassSignal then AddOwnedClassSignal:Fire(player, "Mage") end
			elseif itemKey == "NECRO_PASS_ID" then
				player:SetAttribute("OwnsNecromancerClass", true)
				if AddOwnedClassSignal then AddOwnedClassSignal:Fire(player, "Necromancer") end
			elseif itemKey == "STORM_PASS_ID" then
				player:SetAttribute("OwnsStormCallerClass", true)
				player:SetAttribute("OwnsStormClass", true)
				if AddOwnedClassSignal then AddOwnedClassSignal:Fire(player, "StormCaller") end
			elseif itemKey == "DRAGON_PASS_ID" then
				player:SetAttribute("OwnsDragonKnightClass", true)
				player:SetAttribute("OwnsDragonClass", true)
				if AddOwnedClassSignal then AddOwnedClassSignal:Fire(player, "DragonKnight") end
			elseif itemKey == "VIP_PASS_ID" then
				player:SetAttribute("IsVIP", true)
			elseif itemKey == "XP_PASS_ID" then
				player:SetAttribute("HasDoubleXP", true)
			elseif itemKey == "INFINITE_PASS_ID" then
				player:SetAttribute("HasInfiniteAccess", true)
			end
			print("[MonetizationManager] Granted pass mock reward to " .. player.Name .. " (" .. itemKey .. ")")
		else
			-- Trigger official gamepass prompt
			MarketplaceService:PromptGamePassPurchase(player, passId)
		end
		
	elseif itemType == "Product" then
		local productId = EconomyConfig.ProductIds[itemKey]
		if not productId then
			warn("[MonetizationManager] Unknown developer product key: " .. tostring(itemKey))
			return
		end
		
		if productId == 0 then
			-- Simulating mock product purchase success in Roblox Studio
			print("[MonetizationManager] Mocking developer product purchase: " .. itemKey .. " for " .. player.Name)
			if itemKey == "GEMS_500_ID" then
				local current = player:GetAttribute("Gems") or 0
				player:SetAttribute("Gems", current + 500)
			elseif itemKey == "GEMS_1500_ID" then
				local current = player:GetAttribute("Gems") or 0
				player:SetAttribute("Gems", current + 1500)
			elseif itemKey == "GEMS_5000_ID" then
				local current = player:GetAttribute("Gems") or 0
				player:SetAttribute("Gems", current + 5000)
			elseif itemKey == "REVIVE_TOKEN_ID" then
				local revives = player:GetAttribute("ReviveTokens") or 0
				player:SetAttribute("ReviveTokens", revives + 1)
			elseif itemKey == "TOWER_SLOT_ID" then
				local current = player:GetAttribute("TowerSlots") or 5
				player:SetAttribute("TowerSlots", current + 1)
			end
			print("[MonetizationManager] Granted product mock reward to " .. player.Name .. " (" .. itemKey .. ")")
		else
			-- Trigger official developer product prompt
			MarketplaceService:PromptProductPurchase(player, productId)
		end
	end
end)

-- Hook setup for joining players
local function OnPlayerAdded(player)
	InitializePlayerAttributes(player)
	CheckPassOwnership(player)
end

Players.PlayerAdded:Connect(OnPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(OnPlayerAdded, player)
end

print("[MonetizationManager] System active and listening to purchase events.")
