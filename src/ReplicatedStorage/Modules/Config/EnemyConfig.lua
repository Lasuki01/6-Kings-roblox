-- ============================================
-- EnemyConfig.lua — Kingdom Siege
-- Definitions and stats for all enemy types.
-- Side: Shared (Server / Client)
-- ============================================

local EnemyConfig = {}

-- Armor type descriptions:
-- "None": Takes full damage from all sources
-- "Heavy": Takes 50% damage from physical arrows (Ranger/Archer)
-- "Undead": Takes 150% damage from Mage spells, 50% from physical
-- "Flying": Can only be hit by Mage Towers, Lightning Rods, and Hero abilities. Ignores other ground defenses.

EnemyConfig.Enemies = {
	Goblin = {
		HP = 50,
		Speed = 16,
		Damage = 10,             -- Damage to heroes
		CrystalDamage = 5,       -- Damage to Crystal on reach
		GoldReward = 10,
		ArmorType = "None",
		Description = "Fast but weak thief."
	},
	Orc = {
		HP = 200,
		Speed = 8,
		Damage = 25,
		CrystalDamage = 20,
		GoldReward = 25,
		ArmorType = "None",
		Description = "Sturdy foot soldier."
	},
	DarkKnight = {
		HP = 350,
		Speed = 7,
		Damage = 35,
		CrystalDamage = 35,
		GoldReward = 45,
		ArmorType = "Heavy",
		Description = "Heavily armored knight. Resists arrows."
	},
	SkeletonMage = {
		HP = 120,
		Speed = 10,
		Damage = 20,
		CrystalDamage = 15,
		GoldReward = 20,
		ArmorType = "Undead",
		Description = "Ranged magical attacker. Takes extra magic damage."
	},
	Troll = {
		HP = 500,
		Speed = 6,
		Damage = 40,
		CrystalDamage = 40,
		GoldReward = 60,
		ArmorType = "None",
		RegenHP = 6,             -- Regenerates HP per second
		Description = "Giant beast that heals over time."
	},
	Dragon = {
		HP = 900,
		Speed = 12,
		Damage = 60,
		CrystalDamage = 60,
		GoldReward = 120,
		ArmorType = "None",
		IsFlying = true,         -- Flying unit, ignores standard ground towers
		Description = "Flying drake that strikes from the skies."
	},
	LichKing = {
		HP = 6000,
		Speed = 4,
		Damage = 100,
		CrystalDamage = 150,
		GoldReward = 500,
		ArmorType = "Undead",
		IsBoss = true,
		Description = "The Dark Lord. Boss of Wave 20."
	}
}

return EnemyConfig
