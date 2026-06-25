-- ============================================
-- TowerConfig.lua — Kingdom Siege
-- Definitions and stats for all towers and their upgrade levels.
-- Side: Shared (Server / Client)
-- ============================================

local TowerConfig = {}

-- Tower stats mapped by type and upgrade levels (1, 2, 3)
TowerConfig.Towers = {
	Archer = {
		Name = "Archer Tower",
		Description = "Shoots single physical arrows. Fast attack speed.",
		Class = "Physical",
		Levels = {
			[1] = { Cost = 100, Damage = 10, Range = 40, Cooldown = 0.8 },
			[2] = { Cost = 150, Damage = 18, Range = 45, Cooldown = 0.7 },
			[3] = { Cost = 250, Damage = 32, Range = 50, Cooldown = 0.6 }
		}
	},
	Mage = {
		Name = "Mage Tower",
		Description = "Shoots magic bolts that deal damage and slow enemies by 30% for 2s.",
		Class = "Magic",
		Levels = {
			[1] = { Cost = 150, Damage = 15, Range = 35, Cooldown = 1.5, SlowPercentage = 0.3, SlowDuration = 2 },
			[2] = { Cost = 200, Damage = 25, Range = 40, Cooldown = 1.3, SlowPercentage = 0.4, SlowDuration = 2 },
			[3] = { Cost = 350, Damage = 45, Range = 45, Cooldown = 1.1, SlowPercentage = 0.5, SlowDuration = 3 }
		}
	},
	Catapult = {
		Name = "Catapult",
		Description = "Launches heavy boulders dealing high AoE damage. Slow attack speed.",
		Class = "Physical",
		Levels = {
			[1] = { Cost = 200, Damage = 40, Range = 50, Cooldown = 3.5, SplashRadius = 15 },
			[2] = { Cost = 300, Damage = 75, Range = 55, Cooldown = 3.2, SplashRadius = 18 },
			[3] = { Cost = 450, Damage = 130, Range = 60, Cooldown = 2.8, SplashRadius = 22 }
		}
	},
	FrostSpire = {
		Name = "Frost Spire",
		Description = "Periodically freezes all enemies in range. Unlocked at Wave 5.",
		Class = "Magic",
		UnlockWave = 5,
		Levels = {
			[1] = { Cost = 250, Damage = 5, Range = 30, Cooldown = 4.5, FreezeDuration = 1.5 },
			[2] = { Cost = 350, Damage = 12, Range = 35, Cooldown = 4.0, FreezeDuration = 2.0 },
			[3] = { Cost = 500, Damage = 25, Range = 40, Cooldown = 3.5, FreezeDuration = 3.0 }
		}
	},
	LightningRod = {
		Name = "Lightning Rod",
		Description = "Chains electrical shocks across multiple targets. Unlocked at Wave 10.",
		Class = "Magic",
		UnlockWave = 10,
		Levels = {
			[1] = { Cost = 300, Damage = 20, Range = 40, Cooldown = 2.0, MaxChains = 3 },
			[2] = { Cost = 450, Damage = 35, Range = 45, Cooldown = 1.8, MaxChains = 4 },
			[3] = { Cost = 600, Damage = 55, Range = 50, Cooldown = 1.5, MaxChains = 6 }
		}
	}
}

-- Check if tower slot limits are configurable
TowerConfig.DEFAULT_MAX_TOWERS = 5

return TowerConfig
