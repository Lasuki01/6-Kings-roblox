-- ============================================
-- UIStyleConfig.lua — Kingdom Siege
-- Definitions for game colors, fonts, tweens, and sound effects.
-- Side: Shared (Server / Client)
-- ============================================

local UIStyleConfig = {}

-- Main Theme Colors
UIStyleConfig.Colors = {
	PanelBg = Color3.fromRGB(14, 14, 18),
	PanelBgDark = Color3.fromRGB(6, 6, 8),
	BorderGold = Color3.fromRGB(218, 165, 32),
	BorderBronze = Color3.fromRGB(139, 69, 19),
	TextParchment = Color3.fromRGB(245, 242, 235),
	TextSilver = Color3.fromRGB(180, 180, 185),
	GreenSuccess = Color3.fromRGB(40, 150, 60),
	RedDanger = Color3.fromRGB(150, 40, 40),
	GoldAccent = Color3.fromRGB(255, 215, 0),
	SelectionGlow = Color3.fromRGB(255, 200, 50),
}

-- Class Specific Glowing Theme Colors
UIStyleConfig.ClassThemes = {
	Knight = {
		Color = Color3.fromRGB(190, 195, 200),
		Icon = "🛡️",
	},
	Ranger = {
		Color = Color3.fromRGB(46, 139, 87),
		Icon = "🏹",
	},
	Mage = {
		Color = Color3.fromRGB(30, 144, 255),
		Icon = "🔮",
	},
	Necromancer = {
		Color = Color3.fromRGB(138, 43, 226),
		Icon = "☠️",
	},
	StormCaller = {
		Color = Color3.fromRGB(255, 215, 0),
		Icon = "⚡",
	},
	DragonKnight = {
		Color = Color3.fromRGB(220, 20, 60),
		Icon = "🔥",
	}
}

-- Path Specific Colors
UIStyleConfig.PathThemes = {
	ForestPath = {
		Color = Color3.fromRGB(46, 139, 87),
		Icon = "🌲",
		Label = "Forest Path",
	},
	UndeadPath = {
		Color = Color3.fromRGB(138, 43, 226),
		Icon = "💀",
		Label = "Undead Graveyard",
	},
	DragonPass = {
		Color = Color3.fromRGB(220, 20, 60),
		Icon = "🔥",
		Label = "Dragon Pass",
	},
	Interior = {
		Color = Color3.fromRGB(120, 130, 140),
		Icon = "🏰",
		Label = "Castle Keep",
	}
}

-- Helper function to safely get font with fallback to avoid crashes on different clients
local function SafeGetFont(fontName, fallback)
	local success, font = pcall(function()
		return Enum.Font[fontName]
	end)
	if success and font then
		return font
	end
	return fallback
end

-- Custom Fonts (safely loaded to prevent client loading crashes)
UIStyleConfig.Fonts = {
	Title = SafeGetFont("Cinzel", SafeGetFont("Balthazar", SafeGetFont("Fantasy", Enum.Font.SourceSansBold))),
	BodyBold = SafeGetFont("Balthazar", SafeGetFont("Merriweather", SafeGetFont("Garamond", Enum.Font.SourceSansBold))),
	BodyRegular = SafeGetFont("Garamond", SafeGetFont("Cardo", SafeGetFont("SourceSans", Enum.Font.SourceSans))),
	Stats = SafeGetFont("Spectral", SafeGetFont("Cardo", SafeGetFont("GothamSemibold", Enum.Font.SourceSansBold))),
}

-- Audio Assets
UIStyleConfig.Sounds = {
	Click = 12222247,         -- UI click sound
	Build = 286522724,        -- placement hammer sound
	Sell = 9072709117,        -- cash sound
	Cast = 138084705,         -- ability sound
	Tick = 12222247,          -- countdown beep
	Error = 12222244,         -- buzzer
	Victory = 9072709214,     -- fanfare
	Defeat = 9072709087,      -- skull laugh/crying sound
}

return UIStyleConfig
