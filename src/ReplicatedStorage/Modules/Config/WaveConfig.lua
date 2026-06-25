-- ============================================
-- WaveConfig.lua — Kingdom Siege
-- Definitions for all 20 waves including enemy types, counts, and paths.
-- Side: Shared (Server / Client)
-- ============================================

local WaveConfig = {}

-- Spawning helpers
local function createGroup(enemyType, path, count, interval)
	local spawns = {}
	for i = 1, count do
		table.insert(spawns, {
			EnemyType = enemyType,
			Path = path,
			Delay = interval
		})
	end
	return spawns
end

-- Wave definitions from 1 to 20
WaveConfig.Waves = {
	-- Wave 1: Forest introductory path (Goblins)
	[1] = {
		Spawns = {
			{ EnemyType = "Goblin", Path = "ForestPath", Delay = 2 },
			{ EnemyType = "Goblin", Path = "ForestPath", Delay = 2 },
			{ EnemyType = "Goblin", Path = "ForestPath", Delay = 2 },
			{ EnemyType = "Goblin", Path = "ForestPath", Delay = 2 },
			{ EnemyType = "Goblin", Path = "ForestPath", Delay = 2 }
		}
	},
	-- Wave 2: Introduce Graveyard path
	[2] = {
		Spawns = {
			{ EnemyType = "Goblin", Path = "ForestPath", Delay = 1.5 },
			{ EnemyType = "Goblin", Path = "UndeadPath", Delay = 1.5 },
			{ EnemyType = "Goblin", Path = "ForestPath", Delay = 1.5 },
			{ EnemyType = "Goblin", Path = "UndeadPath", Delay = 1.5 },
			{ EnemyType = "Goblin", Path = "ForestPath", Delay = 1.5 },
			{ EnemyType = "Goblin", Path = "UndeadPath", Delay = 1.5 }
		}
	},
	-- Wave 3: Introduce Orcs
	[3] = {
		Spawns = {
			{ EnemyType = "Orc", Path = "ForestPath", Delay = 3 },
			{ EnemyType = "Goblin", Path = "ForestPath", Delay = 1 },
			{ EnemyType = "Goblin", Path = "ForestPath", Delay = 1 },
			{ EnemyType = "Orc", Path = "UndeadPath", Delay = 3 },
			{ EnemyType = "Goblin", Path = "UndeadPath", Delay = 1 },
			{ EnemyType = "Goblin", Path = "UndeadPath", Delay = 1 }
		}
	},
	-- Wave 4: Combined assault
	[4] = {
		Spawns = {
			{ EnemyType = "Orc", Path = "ForestPath", Delay = 2 },
			{ EnemyType = "Orc", Path = "UndeadPath", Delay = 2 },
			{ EnemyType = "Goblin", Path = "ForestPath", Delay = 0.8 },
			{ EnemyType = "Goblin", Path = "UndeadPath", Delay = 0.8 },
			{ EnemyType = "Orc", Path = "ForestPath", Delay = 2 },
			{ EnemyType = "Orc", Path = "UndeadPath", Delay = 2 }
		}
	},
	-- Wave 5: MINI-BOSS Troll (Wave 5, 10, 15, 20 are mini-boss/boss waves)
	[5] = {
		Spawns = {
			{ EnemyType = "Troll", Path = "ForestPath", Delay = 5 }, -- Mini-boss
			{ EnemyType = "Orc", Path = "ForestPath", Delay = 2 },
			{ EnemyType = "Orc", Path = "UndeadPath", Delay = 2 },
			{ EnemyType = "Goblin", Path = "ForestPath", Delay = 1 },
			{ EnemyType = "Goblin", Path = "UndeadPath", Delay = 1 }
		}
	},
	-- Wave 6: Introduce Skeleton Mage (Graveyard magic)
	[6] = {
		Spawns = {
			{ EnemyType = "SkeletonMage", Path = "UndeadPath", Delay = 3 },
			{ EnemyType = "SkeletonMage", Path = "UndeadPath", Delay = 2 },
			{ EnemyType = "Orc", Path = "ForestPath", Delay = 2 },
			{ EnemyType = "Goblin", Path = "ForestPath", Delay = 1 },
			{ EnemyType = "SkeletonMage", Path = "UndeadPath", Delay = 2 }
		}
	},
	-- Wave 7: Heavy Armored Dark Knights
	[7] = {
		Spawns = {
			{ EnemyType = "DarkKnight", Path = "ForestPath", Delay = 4 },
			{ EnemyType = "Orc", Path = "ForestPath", Delay = 2 },
			{ EnemyType = "DarkKnight", Path = "UndeadPath", Delay = 4 },
			{ EnemyType = "Orc", Path = "UndeadPath", Delay = 2 },
			{ EnemyType = "SkeletonMage", Path = "UndeadPath", Delay = 2 }
		}
	},
	-- Wave 8: Heavy and magic mix
	[8] = {
		Spawns = {
			{ EnemyType = "DarkKnight", Path = "ForestPath", Delay = 3 },
			{ EnemyType = "SkeletonMage", Path = "UndeadPath", Delay = 1 },
			{ EnemyType = "DarkKnight", Path = "UndeadPath", Delay = 3 },
			{ EnemyType = "SkeletonMage", Path = "ForestPath", Delay = 1 },
			{ EnemyType = "Orc", Path = "ForestPath", Delay = 2 },
			{ EnemyType = "Orc", Path = "UndeadPath", Delay = 2 }
		}
	},
	-- Wave 9: Prep wave before boss
	[9] = {
		Spawns = {
			{ EnemyType = "DarkKnight", Path = "ForestPath", Delay = 2 },
			{ EnemyType = "DarkKnight", Path = "UndeadPath", Delay = 2 },
			{ EnemyType = "Troll", Path = "ForestPath", Delay = 4 },
			{ EnemyType = "SkeletonMage", Path = "UndeadPath", Delay = 1.5 },
			{ EnemyType = "SkeletonMage", Path = "ForestPath", Delay = 1.5 }
		}
	},
	-- Wave 10: MINI-BOSS Dragon + Dragon Pass unlocks!
	[10] = {
		Spawns = {
			{ EnemyType = "Dragon", Path = "DragonPass", Delay = 6 }, -- Boss (Unlocks Dragon Pass!)
			{ EnemyType = "Orc", Path = "DragonPass", Delay = 2 },
			{ EnemyType = "Orc", Path = "DragonPass", Delay = 2 },
			{ EnemyType = "Troll", Path = "ForestPath", Delay = 3 },
			{ EnemyType = "DarkKnight", Path = "UndeadPath", Delay = 3 }
		}
	},
	-- Wave 11: All three paths fully active
	[11] = {
		Spawns = {
			{ EnemyType = "Goblin", Path = "DragonPass", Delay = 0.5 },
			{ EnemyType = "Goblin", Path = "ForestPath", Delay = 0.5 },
			{ EnemyType = "Goblin", Path = "UndeadPath", Delay = 0.5 },
			{ EnemyType = "Orc", Path = "DragonPass", Delay = 2 },
			{ EnemyType = "Orc", Path = "ForestPath", Delay = 2 },
			{ EnemyType = "Orc", Path = "UndeadPath", Delay = 2 }
		}
	},
	-- Wave 12: Magic & Flight
	[12] = {
		Spawns = {
			{ EnemyType = "Dragon", Path = "DragonPass", Delay = 5 },
			{ EnemyType = "SkeletonMage", Path = "UndeadPath", Delay = 1 },
			{ EnemyType = "SkeletonMage", Path = "DragonPass", Delay = 1 },
			{ EnemyType = "DarkKnight", Path = "ForestPath", Delay = 2 }
		}
	},
	-- Wave 13: Armored push on all lanes
	[13] = {
		Spawns = {
			{ EnemyType = "DarkKnight", Path = "ForestPath", Delay = 3 },
			{ EnemyType = "DarkKnight", Path = "UndeadPath", Delay = 3 },
			{ EnemyType = "DarkKnight", Path = "DragonPass", Delay = 3 },
			{ EnemyType = "Orc", Path = "ForestPath", Delay = 1 },
			{ EnemyType = "Orc", Path = "UndeadPath", Delay = 1 },
			{ EnemyType = "Orc", Path = "DragonPass", Delay = 1 }
		}
	},
	-- Wave 14: Troll horde
	[14] = {
		Spawns = {
			{ EnemyType = "Troll", Path = "ForestPath", Delay = 4 },
			{ EnemyType = "Troll", Path = "UndeadPath", Delay = 4 },
			{ EnemyType = "Troll", Path = "DragonPass", Delay = 4 },
			{ EnemyType = "SkeletonMage", Path = "UndeadPath", Delay = 1 }
		}
	},
	-- Wave 15: MINI-BOSS Two Dragons!
	[15] = {
		Spawns = {
			{ EnemyType = "Dragon", Path = "DragonPass", Delay = 6 },
			{ EnemyType = "Dragon", Path = "DragonPass", Delay = 2 },
			{ EnemyType = "Troll", Path = "ForestPath", Delay = 2 },
			{ EnemyType = "Troll", Path = "UndeadPath", Delay = 2 },
			{ EnemyType = "DarkKnight", Path = "DragonPass", Delay = 2 }
		}
	},
	-- Wave 16: Elite wave
	[16] = {
		Spawns = {
			{ EnemyType = "DarkKnight", Path = "ForestPath", Delay = 2 },
			{ EnemyType = "SkeletonMage", Path = "UndeadPath", Delay = 1 },
			{ EnemyType = "Dragon", Path = "DragonPass", Delay = 3 },
			{ EnemyType = "Troll", Path = "ForestPath", Delay = 2 },
			{ EnemyType = "DarkKnight", Path = "UndeadPath", Delay = 2 }
		}
	},
	-- Wave 17: Triple Dragon threat
	[17] = {
		Spawns = {
			{ EnemyType = "Dragon", Path = "DragonPass", Delay = 4 },
			{ EnemyType = "Dragon", Path = "DragonPass", Delay = 3 },
			{ EnemyType = "Dragon", Path = "DragonPass", Delay = 3 },
			{ EnemyType = "Orc", Path = "ForestPath", Delay = 1 },
			{ EnemyType = "Orc", Path = "UndeadPath", Delay = 1 }
		}
	},
	-- Wave 18: Armored assault
	[18] = {
		Spawns = {
			{ EnemyType = "Troll", Path = "ForestPath", Delay = 3 },
			{ EnemyType = "DarkKnight", Path = "ForestPath", Delay = 1 },
			{ EnemyType = "Troll", Path = "UndeadPath", Delay = 3 },
			{ EnemyType = "DarkKnight", Path = "UndeadPath", Delay = 1 },
			{ EnemyType = "Troll", Path = "DragonPass", Delay = 3 },
			{ EnemyType = "DarkKnight", Path = "DragonPass", Delay = 1 }
		}
	},
	-- Wave 19: Full army pre-boss
	[19] = {
		Spawns = {
			{ EnemyType = "Dragon", Path = "DragonPass", Delay = 3 },
			{ EnemyType = "Troll", Path = "ForestPath", Delay = 2 },
			{ EnemyType = "Troll", Path = "UndeadPath", Delay = 2 },
			{ EnemyType = "DarkKnight", Path = "DragonPass", Delay = 2 },
			{ EnemyType = "SkeletonMage", Path = "UndeadPath", Delay = 1 },
			{ EnemyType = "SkeletonMage", Path = "ForestPath", Delay = 1 },
			{ EnemyType = "Goblin", Path = "DragonPass", Delay = 0.5 },
			{ EnemyType = "Goblin", Path = "DragonPass", Delay = 0.5 }
		}
	},
	-- Wave 20: FINAL BOSS Lich King + Undead Vanguard!
	[20] = {
		Spawns = {
			{ EnemyType = "LichKing", Path = "UndeadPath", Delay = 8 }, -- Final Boss
			{ EnemyType = "Dragon", Path = "DragonPass", Delay = 3 },
			{ EnemyType = "Troll", Path = "ForestPath", Delay = 2 },
			{ EnemyType = "DarkKnight", Path = "UndeadPath", Delay = 2 },
			{ EnemyType = "SkeletonMage", Path = "UndeadPath", Delay = 1 },
			{ EnemyType = "SkeletonMage", Path = "UndeadPath", Delay = 1 },
			{ EnemyType = "DarkKnight", Path = "UndeadPath", Delay = 1 },
			{ EnemyType = "DarkKnight", Path = "UndeadPath", Delay = 1 }
		}
	}
}

return WaveConfig
