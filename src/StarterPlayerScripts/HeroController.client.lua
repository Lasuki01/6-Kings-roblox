-- ============================================
-- HeroController.client.lua — Kingdom Siege
-- Governs local basic attack triggers, input bindings, and click attacks.
-- Side: Client
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Configuration modules
local Config = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Config")
local HeroConfig = require(Config:WaitForChild("HeroConfig"))

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local BasicAttack = Remotes:WaitForChild("BasicAttack")

-- Local references
local player = Players.LocalPlayer
local lastAttackTime = 0

-- Handle click/touch attack input triggers
UserInputService.InputBegan:Connect(function(input, processed)
	-- If they tapped a button, text field, or HUD, do not fire basic attacks
	if processed then return end

	local className = player:GetAttribute("SelectedClass")
	if not className then return end

	local classConfig = HeroConfig.Classes[className]
	if not classConfig then return end

	-- Check click or mobile touch tap
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		-- Skip attacking if clicking a PlacementZone or a Tower model to avoid dual-fire with menus
		local mouse = player:GetMouse()
		local target = mouse.Target
		if target then
			local CollectionService = game:GetService("CollectionService")
			if CollectionService:HasTag(target, "PlacementZone") or target:IsDescendantOf(workspace:FindFirstChild("Towers")) then
				return
			end
		end
		
		local now = os.clock()
		if now - lastAttackTime >= classConfig.AttackCooldown then
			lastAttackTime = now
			
			-- Fire attack to server
			BasicAttack:FireServer()
		end
	end
end)

print("[HeroController] Basic attack controller active.")
