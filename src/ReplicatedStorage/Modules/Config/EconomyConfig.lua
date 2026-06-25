-- ============================================
-- EconomyConfig.lua — Kingdom Siege
-- Global economy configuration including starting balances, rewards, and monetization IDs.
-- Side: Shared (Server / Client)
-- ============================================

local EconomyConfig = {}

-- Base gameplay economy settings
EconomyConfig.STARTING_GOLD = 400
EconomyConfig.BASE_WAVE_BONUS = 100
EconomyConfig.WAVE_BONUS_INCREMENT = 20 -- Bonus is: BASE_WAVE_BONUS + (currentWave * WAVE_BONUS_INCREMENT)

-- Monetization multipliers
EconomyConfig.VIP_GOLD_MULTIPLIER = 1.25 -- +25% Gold
EconomyConfig.XP_MULTIPLIER = 2.00       -- 2x XP Pass

-- Gamepass Product ID placeholders (to be updated by developer)
EconomyConfig.PassIds = {
	MAGE_PASS_ID = 0,         -- Mage Class Pass
	STORM_PASS_ID = 0,        -- Storm Caller Class Pass
	DRAGON_PASS_ID = 0,       -- Dragon Knight Class Pass
	VIP_PASS_ID = 0,          -- VIP Gold Multiplier Pass
	XP_PASS_ID = 0,           -- 2x XP Pass
	INFINITE_PASS_ID = 0,     -- Infinite Mode Access
}

-- Developer Product ID placeholders (repeatable purchases)
EconomyConfig.ProductIds = {
	GEMS_500_ID = 0,
	GEMS_1500_ID = 0,
	GEMS_5000_ID = 0,
	REVIVE_TOKEN_ID = 0,
	TOWER_SLOT_ID = 0,        -- Adds +1 permanently
}

return EconomyConfig
