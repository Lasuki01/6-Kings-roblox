# AGENTS.md — Kingdom Siege (Roblox)
always use caveman skill 
always use KINGDOM_SIEGE_GDD.md file for general game design reference 
update progress (changes made/reverted) in PROGRESS.md file, and read/update this file for project rules.

> Context and behavior rules for AI coding assistants (Gemini, Antigravity).
> Every model response must follow these guidelines strictly.

---

## 1. TECH STACK & ARCHITECTURE
- **Game Name:** Kingdom Siege (Medieval Fantasy Active Tower Defense)
- **Engine/Language:** Luau (Roblox Studio + Rojo)
- **Pattern:** ModuleScript architecture (strict client-server separation)
- **Rerouting System:** Wave-spawned enemies reroute if assigned path is closed.
- **Dynamic Path Scaling:** Paths unlock based on player count at wave start (1-2p: Forest; 3-4p: Forest + Undead; 5-6p: All).

---

## 2. THE GOLDEN RULES (NEVER BREAK)
1. **Server-Authoritative:** Gameplay logic, HP, damage, gold, and game loop run on **server** (`ServerScriptService`). LocalScripts only handle client rendering, user input, visual tweens, and remote requests.
2. **Modern APIs:** Use `task.wait()` (never `wait()`). Use `:Connect()` (never `:connect()`).
3. **No Hardcoding:** Balance variables (HP, damage, costs) must live in Config modules in `ReplicatedStorage/Modules/Config/`.
4. **Data Safety:** Wrap all `DataStore` calls in `pcall` and handle errors.
5. **No Memory Leaks:** Clean up connections on respawn/destruction. Destroy visual instances (`Debris` or `:Destroy()`).

---

## 3. PROJECT DIRECTORY STRUCTURE
```
KingdomSiege/
├── default.project.json             ← Rojo configuration
├── src/
│   ├── ServerScriptService/
│   │   ├── GameManager.server.lua   ← State loop, wave spawning, path control
│   │   ├── EnemyManager.server.lua  ← Spawning, waypoint walking, scaling
│   │   ├── TowerManager.server.lua  ← Placements, targeting, firing
│   │   ├── HeroManager.server.lua   ← Class attributes, skills, weapons
│   │   ├── MonetizationManager.server.lua ← ProcessReceipt, passes checks
│   │   ├── MapManager.server.lua    ← Procedural map, gates, altars
│   │   └── DataManager.server.lua   ← Save/load progression data
│   │
│   ├── ReplicatedStorage/
│   │   ├── Remotes/                 ← Rojo remote models
│   │   │   ├── PlaceTower.model.json
│   │   │   ├── UseAbility.model.json
│   │   │   ├── PurchaseItem.model.json
│   │   │   ├── SyncGameState.model.json
│   │   │   ├── BasicAttack.model.json
│   │   │   ├── SelectClass.model.json
│   │   │   ├── SellTower.model.json
│   │   │   └── UpgradeTower.model.json
│   │   └── Modules/
│   │       ├── Config/
│   │       │   ├── EnemyConfig.lua
│   │       │   ├── TowerConfig.lua
│   │       │   ├── HeroConfig.lua
│   │       │   ├── WaveConfig.lua
│   │       │   └── EconomyConfig.lua
│   │       └── Shared/
│   │           ├── Signals.lua       ← Bindable coordinator
│   │           ├── Types.lua
│   │           └── Utilities.lua
│   │
│   └── StarterPlayerScripts/
│       ├── HeroController.client.lua  ← Input capture, client-side attacks
│       └── UIController.client.lua    ← HUD, contextual 3D Billboard menus
```

---

## 4. CODING STANDARDS & STYLES

### 4.1 Header Format
Every script must start with:
```lua
-- ============================================
-- [FILE NAME] — Kingdom Siege
-- [BRIEF DESCRIPTION]
-- Side: Server / Client / Shared
-- ============================================
```

### 4.2 Scripting Patterns (Correct vs. Incorrect)

#### Service and Module Retrieval
```lua
-- ✅ CORRECT
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signals = require(ReplicatedStorage.Modules.Shared.Signals)

-- ❌ INCORRECT
local Players = game.Players
local Signals = require(workspace.Signals)
```

#### Event Connection Cleanup
```lua
-- ✅ CORRECT: Disconnect connection references before overwriting
local connection
local function SetupConnection()
	if connection then
		connection:Disconnect()
		connection = nil
	end
	connection = humanoid.HealthChanged:Connect(function(health)
		-- Update display
	end)
end

-- ❌ INCORRECT: Infinite connection stacking (Memory Leak)
humanoid.HealthChanged:Connect(function(health)
	-- Updates display, but leaks when character respawns
end)
```

#### Early-Exit / Guard Clauses
```lua
-- ✅ CORRECT
local function ProcessAttack(player, target)
	if not target or not target:FindFirstChild("Humanoid") then return end
	if target.Humanoid.Health <= 0 then return end
	-- Process attack logic...
end

-- ❌ INCORRECT: Deeply nested conditions
local function ProcessAttack(player, target)
	if target then
		if target:FindFirstChild("Humanoid") then
			if target.Humanoid.Health > 0 then
				-- Process attack logic...
			end
		end
	end
end
```

---

## 5. MONETIZATION & DATABASE SHEMAS
- **Gems vs Gold:** Gold is session currency. Gems are premium. Do not combine logic.
- **Pass checks:** Query asynchronously via `MarketplaceService:UserOwnsGamePassAsync()`.
- **Database shape:** Keep keys consistent with standard schema:
```lua
local DEFAULT_DATA = {
	XP = 0,
	Level = 1,
	Gems = 0,
	TowerSlots = 5,
	OwnedClasses = {"Knight", "Ranger"},
	Cosmetics = {},
	TotalWins = 0,
	TotalMatches = 0,
}
```

---

## 6. SYSTEM INTERACTION TEMPLATE
For code prompts, format as:
```
Task: [Goal]
File: [Target Path]
Context: [External components and remotes]
Rules: Follow GEMINI.md
```
