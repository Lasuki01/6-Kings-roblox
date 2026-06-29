# CLAUDE.md — Kingdom Siege (Roblox)
always use caveman skill
always use KINGDOM_SIEGE_GDD.md file for general game design reference
update progress (changes made/reverted) in PROGRESS.md file, and read/update this file for project rules.

> Context and behavior rules for AI coding assistants (Claude, Cursor, Antigravity).
> Every model response must follow these guidelines strictly.

---

## 0. SESSION START PROTOCOL (DO THIS FIRST — EVERY SESSION)
Before writing a single line of code:
1. Read `PROGRESS.md` — understand current state, last changes, and any blocked tasks
2. Read `KINGDOM_SIEGE_GDD.md` — confirm design intent before implementing any mechanic
3. Confirm which file you are editing and its Side (Server / Client / Shared)
4. Never assume the state of a system not shown to you — ask if it's undocumented

---

## 1. TECH STACK & ARCHITECTURE
- **Game Name:** Kingdom Siege (Medieval Fantasy Active Tower Defense)
- **Engine/Language:** Luau (Roblox Studio + Rojo)
- **Pattern:** ModuleScript architecture (strict client-server separation)
- **Rerouting System:** Wave-spawned enemies reroute if assigned path is closed.
- **Dynamic Path Scaling:** Paths unlock based on player count at wave start (1-2p: Forest; 3-4p: Forest + Undead; 5-6p: All).
- **Map Architecture:** CollectionService-based tagging for towers, enemies, waypoints, and altars. Never use workspace loops to find these.

### 1.1 Core Systems at a Glance
| File | Responsibility |
|---|---|
| GameManager.server.lua | Wave state machine, path control, win/lose |
| EnemyManager.server.lua | Spawn, waypoint walk, scale, reroute |
| TowerManager.server.lua | Place, target, fire, sell, upgrade |
| HeroManager.server.lua | Class stats, abilities, hero combat |
| MonetizationManager.server.lua | ProcessReceipt, game pass checks |
| MapManager.server.lua | Procedural map, gates, altars |
| DataManager.server.lua | Save/load, DataStore with pcall |

### 1.2 Hero Classes (Six Total)
| Class | Role |
|---|---|
| Knight | Front-line melee tank |
| Ranger | Ranged single-target DPS |
| Mage | AoE spell damage |
| Cleric | Support / team heal |
| Rogue | High burst, single-target |
| Warden | Hybrid melee + buff |

### 1.3 Tower Types (Five Total)
| Tower | Function |
|---|---|
| Archer Tower | Basic ranged, single-target |
| Cannon Tower | AoE splash damage |
| Frost Tower | Slow + damage |
| Magic Tower | High damage, low fire rate |
| Support Tower | Buffs nearby towers |

### 1.4 Enemy Categories
| Type | Notes |
|---|---|
| Infantry | Standard ground unit |
| Armored | High HP, reduced physical damage |
| Flying | Only targetable by specific towers/heroes |
| Boss | High HP, special abilities, wave milestone |
| Dragon | Elite flying boss, has dedicated behavior template |

---

## 2. THE GOLDEN RULES (NEVER BREAK)
1. **Server-Authoritative:** Gameplay logic, HP, damage, gold, and game loop run on **server** (`ServerScriptService`). LocalScripts only handle client rendering, user input, visual tweens, and remote requests.
2. **Modern APIs:** Use `task.wait()` (never `wait()`). Use `task.spawn()` for non-blocking calls. Use `:Connect()` (never `:connect()`).
3. **No Hardcoding:** Balance variables (HP, damage, costs) must live in Config modules in `ReplicatedStorage/Modules/Config/`.
4. **Data Safety:** Wrap all `DataStore` calls in `pcall` and handle errors.
5. **No Memory Leaks:** Clean up connections on respawn/destruction. Destroy visual instances (`Debris` or `:Destroy()`). Use table-based cleanup (see Section 4.2).
6. **Validate All Remotes:** Every `RemoteEvent` and `RemoteFunction` handler must validate all arguments server-side before executing. Never trust client input. (See Section 7.)
7. **No Pay-to-Win:** Gems and game passes may only unlock cosmetics or QoL features. Never sell damage boosts, HP buffs, or mechanically superior heroes/towers. (See Section 5.2.)
8. **CollectionService for Tags:** Tag enemies, towers, waypoints, and altars via `CollectionService`. Never use `workspace:GetChildren()` loops to find these objects.

---

## 3. PROJECT DIRECTORY STRUCTURE
```
KingdomSiege/
├── default.project.json             ← Rojo configuration
├── CLAUDE.md                        ← This file (AI rules)
├── PROGRESS.md                      ← Session log — read and update every session
├── KINGDOM_SIEGE_GDD.md             ← Game Design Document — source of truth for design
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

### 4.2 Scripting Patterns

#### Service and Module Retrieval
```lua
-- ✅ CORRECT
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Signals = require(ReplicatedStorage.Modules.Shared.Signals)

-- ❌ INCORRECT
local Players = game.Players
local Signals = require(workspace.Signals)
```

#### Event Connection Cleanup — Multiple Connections (Preferred Pattern)
```lua
-- ✅ CORRECT: Table-based cleanup scales to any number of connections
local connections = {}

local function CleanupConnections()
	for _, conn in ipairs(connections) do
		conn:Disconnect()
	end
	table.clear(connections)
end

table.insert(connections, humanoid.HealthChanged:Connect(function(health)
	-- Handle health change
end))
table.insert(connections, humanoid.Died:Connect(function()
	CleanupConnections()
end))

-- ❌ INCORRECT: Infinite connection stacking (Memory Leak)
humanoid.HealthChanged:Connect(function(health)
	-- Leaks every time character respawns
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

#### CollectionService Iteration (Enemies / Towers / Waypoints)
```lua
-- ✅ CORRECT
local CollectionService = game:GetService("CollectionService")

for _, enemy in ipairs(CollectionService:GetTagged("Enemy")) do
	-- Process enemy
end

-- ❌ INCORRECT: Slow and fragile
for _, obj in ipairs(workspace:GetChildren()) do
	if obj.Name == "Enemy" then
		-- Never do this
	end
end
```

---

## 5. MONETIZATION & DATABASE SCHEMA

### 5.1 Currency Rules
- **Gold** — Session currency. Earned by killing enemies and completing waves. Cannot be purchased with real money. Never expose Gold amounts via RemoteEvents.
- **Gems** — Premium currency. Purchasable. **Cosmetics and QoL only** — see Rule 7 and Section 5.2.
- Never mix Gold and Gem logic in the same function.

### 5.2 Allowed vs. Forbidden Premium Purchases
| Purchase Type | Allowed? |
|---|---|
| Cosmetic hero/tower skins | ✅ Yes |
| Extra tower placement slots | ✅ Yes (QoL) |
| Cosmetic XP boost (rate only, no stat change) | ✅ Yes |
| Damage or HP buffs of any kind | ❌ Never |
| Mechanically exclusive heroes or towers | ❌ Never |
| Wave-skipping or instant-win mechanics | ❌ Never |
| Exclusive content unavailable to free players | ❌ Never |

### 5.3 Pass Checks
Query asynchronously via `MarketplaceService:UserOwnsGamePassAsync()`.

### 5.4 Database Schema
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
Context: [External components and remotes this file interacts with]
Rules: Follow CLAUDE.md
```

---

## 7. REMOTE EVENT SECURITY & VALIDATION

All `RemoteEvent` and `RemoteFunction` handlers on the server **must validate every argument**. A client can send anything — never execute based on unvalidated input.

### 7.1 Validation Template
```lua
-- ✅ CORRECT: Full server-side validation before any execution
PlaceTowerRemote.OnServerEvent:Connect(function(player, towerType, position)
	-- 1. Type checks
	if type(towerType) ~= "string" then return end
	if typeof(position) ~= "Vector3" then return end

	-- 2. Config existence check (prevents unknown tower injection)
	local towerData = TowerConfig[towerType]
	if not towerData then return end

	-- 3. Bounds check
	if not IsWithinMapBounds(position) then return end

	-- 4. Server-side resource check (NEVER use a client-sent gold value)
	local playerGold = GetPlayerGold(player)
	if playerGold < towerData.Cost then return end

	-- 5. Game state check (e.g., can't place during boss cutscene)
	if GameState ~= "Active" then return end

	-- 6. Execute
	PlaceTower(player, towerType, position)
end)
```

### 7.2 Validation Checklist
Run through this before finalizing any RemoteEvent handler:
- [ ] Player reference exists and is still in `game.Players`
- [ ] All arguments pass `type()` / `typeof()` checks
- [ ] Numeric arguments are within sane min/max ranges
- [ ] String arguments are checked against a whitelist (Config tables), not just existence
- [ ] Resource costs are validated against **server-side** state only
- [ ] The action is legal in the current `GameState`

---

## 8. KNOWN AI PITFALLS — CHECK BEFORE FINALIZING ANY RESPONSE
> Recurring mistakes AI models make in this codebase. Review this list before submitting code.

| # | Mistake | Correct Approach |
|---|---|---|
| 1 | Using `wait()` | Always `task.wait()` |
| 2 | Using `:connect()` | Always `:Connect()` — Luau is case-sensitive |
| 3 | Hardcoding HP, damage, cost values | Pull from Config modules in ReplicatedStorage |
| 4 | Single-variable connection cleanup | Use table-based `CleanupConnections()` pattern (Section 4.2) |
| 5 | No validation on RemoteEvent handlers | Always validate server-side (Section 7) |
| 6 | `workspace:GetChildren()` loops for enemies/towers | Use `CollectionService:GetTagged()` (Section 4.2) |
| 7 | Mixing Gold and Gem logic | Keep in separate functions; never combine |
| 8 | Raw DataStore calls without `pcall` | Every DataStore operation needs error handling |
| 9 | Writing gameplay logic in a LocalScript | Client = input + rendering only |
| 10 | Missing the Section 4.1 header block | Every file needs the header |
| 11 | Suggesting P2W purchases | Only cosmetics and QoL — see Section 5.2 |
| 12 | Not reading PROGRESS.md before starting | Always read it first — it holds current state |
