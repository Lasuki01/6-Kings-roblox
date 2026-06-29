-- ============================================
-- LobbyConfig.lua — Kingdom Siege
-- Lobby matchmaking configuration settings
-- Side: Shared
-- ============================================

local LobbyConfig = {
	-- Battle Place ID in the Roblox game universe (set to 0 for local simulation testing in Studio)
	BattlePlaceId = 0,
	
	-- Mode defaults
	CountdownDuration = 5, -- 5-second countdown
	
	-- Max players option list (GDD supports 2-6 co-op, solo = 1)
	MaxPlayersOptions = {1, 2, 3, 4, 5, 6},
	
	-- Difficulty levels
	Difficulties = {"Normal", "Hard", "Infinite"},
	
	-- Remote event rate limiting (seconds between allowed calls per player)
	RATE_LIMIT_SECONDS = 0.5,
	
	-- Number of independent party pads
	NUM_PARTY_PADS = 4,
	
	-- Physical layout constants
	LobbyCenter = Vector3.new(0, 150, 0),
	LobbySize = Vector3.new(160, 2, 160), -- expanded from 80x80
	
	-- Spawn location (safe area away from pads)
	SpawnLocationOffset = Vector3.new(0, 1.5, 55),
	
	-- Exit teleport (back to spawn area)
	ExitTeleportOffset = Vector3.new(0, 1.5, 55),
	
	-- Safety floor height (catches falling players)
	SafetyFloorY = 120,
	
	-- 4 party pad positions (spread across lobby, offset from center)
	PartyPadOffsets = {
		Vector3.new(-30, 1.2, -20),  -- Pad 1: northwest
		Vector3.new(30, 1.2, -20),   -- Pad 2: northeast
		Vector3.new(-30, 1.2, 20),   -- Pad 3: southwest
		Vector3.new(30, 1.2, 20),    -- Pad 4: southeast
	},
	
	-- Pad visual properties
	PadSize = Vector3.new(18, 0.4, 18),
	PadColors = {
		Color3.fromRGB(0, 150, 255),   -- Pad 1: Blue
		Color3.fromRGB(180, 0, 255),   -- Pad 2: Purple
		Color3.fromRGB(0, 200, 100),   -- Pad 3: Green
		Color3.fromRGB(255, 140, 0),   -- Pad 4: Orange
	},
}

return LobbyConfig
