-- ============================================
-- HeroConfig.lua — Kingdom Siege
-- Definitions and stats for all playable Hero classes and their abilities.
-- Side: Shared (Server / Client)
-- ============================================

local HeroConfig = {}

-- Classes configuration
HeroConfig.Classes = {
	Knight = {
		Name = "Knight",
		HP = 200,
		Speed = 16,
		Damage = 18,
		AttackRange = 5,
		AttackCooldown = 0.6,
		Cost = "Free",
		Ability = {
			Name = "Shield Bash",
			Description = "Stuns and damages all enemies in front of the Knight.",
			Cooldown = 12,
			Damage = 45,
			StunDuration = 3,
			Radius = 8
		}
	},
	Ranger = {
		Name = "Ranger",
		HP = 120,
		Speed = 18,
		Damage = 12,
		AttackRange = 45,
		AttackCooldown = 0.5,
		Cost = "Free",
		Ability = {
			Name = "Rain of Arrows",
			Description = "Fires a volley of arrows in an area, dealing high physical damage.",
			Cooldown = 15,
			Damage = 60, -- Total damage over duration
			Radius = 15,
			Duration = 4
		}
	},
	Mage = {
		Name = "Mage",
		HP = 100,
		Speed = 15,
		Damage = 22,
		AttackRange = 40,
		AttackCooldown = 1.0,
		Cost = 149, -- Robux game pass cost
		Ability = {
			Name = "Fireball",
			Description = "Launches an exploding ball of fire that deals massive AoE magic damage.",
			Cooldown = 10,
			Damage = 100,
			Radius = 12
		}
	},
	Necromancer = {
		Name = "Necromancer",
		HP = 110,
		Speed = 15,
		Damage = 16,
		AttackRange = 35,
		AttackCooldown = 0.8,
		Cost = 199,
		Ability = {
			Name = "Raise Dead",
			Description = "Summons 3 Skeleton minions that march and fight enemies.",
			Cooldown = 20,
			MinionHP = 60,
			MinionDamage = 12,
			MinionDuration = 15
		}
	},
	StormCaller = {
		Name = "Storm Caller",
		HP = 120,
		Speed = 16,
		Damage = 15,
		AttackRange = 40,
		AttackCooldown = 0.7,
		Cost = 249,
		Ability = {
			Name = "Chain Lightning",
			Description = "Fires a lightning bolt that chains up to 5 targets.",
			Cooldown = 8,
			Damage = 45,
			MaxChains = 5
		}
	},
	DragonKnight = {
		Name = "Dragon Knight",
		HP = 250,
		Speed = 14,
		Damage = 25,
		AttackRange = 6,
		AttackCooldown = 0.8,
		Cost = 299,
		Ability = {
			Name = "Dragon Breath",
			Description = "Spews fire in a cone dealing fire damage over time.",
			Cooldown = 14,
			Damage = 80, -- Total over duration
			Duration = 3,
			Angle = 60, -- Cone angle in degrees
			Range = 15
		}
	}
}

-- Global Hero Respawn config
HeroConfig.RESPAWN_TIME = 10 -- seconds

return HeroConfig
