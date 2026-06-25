# GEMINI.md — Kingdom Siege (Roblox)
always use caveman skill 
always use KINGDOM_SIEGE_GDD.md file for general game design refernece 
update progress(changes made/reverted) in PROGRESS.md file ana read and change this file for progress . 

> AI assistant rules for Google Antigravity + Gemini.
> This file tells Gemini exactly how to think, code, and behave for this project.
> Every response must follow these rules without exception.

---

## 1. PROJECT IDENTITY

- **Game Name:** Kingdom Siege
- **Genre:** Medieval Fantasy Active Tower Defense (Co-op, 2–6 players)
- **Platform:** Roblox (Roblox Studio + Rojo + Google Antigravity)
- **Engine Language:** Luau (Roblox's version of Lua 5.1+)
- **Scripting Pattern:** ModuleScript architecture (client/server separation)
- **Version Control:** Rojo project synced to Roblox Studio
- **Developer Skill Level:** Beginner (vibe coding with AI — explain everything clearly)

---

## 2. THE GOLDEN RULES (NEVER BREAK THESE)

1. **Never write code that runs gameplay logic on the client.** All damage, gold, HP, wave logic, and enemy state live on the **server** (Script inside ServerScriptService).
2. **Never use `wait()`.** Always use `task.wait()` instead — it is the modern Roblox standard.
3. **Never use deprecated Roblox APIs** like `game.Players.PlayerAdded:connect()` — always use `:Connect()` with a capital C.
4. **Never put logic inside LocalScript that the server should own.** LocalScripts only handle: UI, camera, input, visual effects, and sending RemoteEvents to the server.
5. **Always use RemoteEvents and RemoteFunctions** to communicate between client and server. Never trust data sent from the client.
6. **Never hardcode values** that will need balancing (enemy HP, tower damage, gold rewards). Put them in a ModuleScript config file instead.
7. **Never break Roblox's Terms of Service.** No exploits, no bypasses, no fake currency manipulation.

---

## 3. ROJO PROJECT STRUCTURE

This is the folder layout Rojo syncs to Roblox Studio. Always generate files that match this structure.

```
KingdomSiege/
├── GEMINI.md                        ← You are here (AI rules)
├── PROGRESS.md                      ← Project progress tracker (update on every change)
├── default.project.json             ← Rojo config
├── src/
│   ├── ServerScriptService/
│   │   ├── GameManager.server.lua   ← Master game loop (waves, win/lose)
│   │   ├── EnemyManager.server.lua  ← Spawning & pathfinding enemies
│   │   ├── TowerManager.server.lua  ← Tower placement & attacking
│   │   ├── HeroManager.server.lua   ← Hero abilities, damage, classes
│   │   ├── GoldManager.server.lua   ← Gold economy & rewards
│   │   ├── MonetizationManager.server.lua ← Game passes, dev products
│   │   └── DataManager.server.lua   ← Player data save/load (DataStore)
│   │
│   ├── ReplicatedStorage/
│   │   ├── Remotes/
│   │   │   ├── PlaceTower.RemoteEvent
│   │   │   ├── UseAbility.RemoteEvent
│   │   │   ├── PurchaseItem.RemoteEvent
│   │   │   └── SyncGameState.RemoteEvent
│   │   └── Modules/
│   │       ├── Config/
│   │       │   ├── EnemyConfig.lua   ← All enemy stats live here
│   │       │   ├── TowerConfig.lua   ← All tower stats live here
│   │       │   ├── HeroConfig.lua    ← All hero class stats live here
│   │       │   ├── WaveConfig.lua    ← Wave definitions live here
│   │       │   └── EconomyConfig.lua ← Gold, gem prices live here
│   │       └── Shared/
│   │           ├── Types.lua         ← Shared type definitions
│   │           └── Utilities.lua     ← Shared helper functions
│   │
│   ├── StarterPlayerScripts/
│   │   ├── HeroController.client.lua  ← Player input & movement
│   │   ├── AbilityController.client.lua ← Casting spells / shooting
│   │   └── UIController.client.lua    ← All HUD and menu logic
│   │
│   └── StarterGui/
│       ├── HUD/                       ← In-match UI (HP, gold, wave)
│       ├── MainMenu/                  ← Lobby / class select
│       └── ShopGui/                   ← Gem shop & game passes UI
```

> When generating a new script, always ask: "Where does this file live in this structure?" and place it accordingly.

---

## 4. SCRIPTING STANDARDS

### 4.1 File Header
Every `.lua` file must start with this comment block:

```lua
-- ============================================
-- [FILE NAME] — Kingdom Siege
-- [BRIEF DESCRIPTION OF WHAT THIS FILE DOES]
-- Side: Server / Client / Shared
-- ============================================
```

### 4.2 Naming Conventions

| Thing | Convention | Example |
|---|---|---|
| Variables | camelCase | `enemyHealth`, `currentWave` |
| Constants | UPPER_SNAKE_CASE | `MAX_WAVES`, `BASE_GOLD` |
| Functions | PascalCase | `SpawnEnemy()`, `CalculateDamage()` |
| ModuleScripts | PascalCase | `EnemyConfig`, `TowerManager` |
| RemoteEvents | PascalCase verb | `PlaceTower`, `UseAbility` |
| Folders | PascalCase | `Remotes`, `Modules`, `Config` |

### 4.3 Code Style Rules

```lua
-- ✅ CORRECT
local task = task
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ✅ Use task.wait(), not wait()
task.wait(1)

-- ✅ Use :Connect(), not :connect()
Players.PlayerAdded:Connect(function(player)
    -- logic here
end)

-- ✅ Always declare services at the top of the file
-- ✅ Always use local variables unless global is truly needed
-- ✅ Always disconnect events when no longer needed (use :Disconnect())
```

```lua
-- ❌ NEVER do this
wait(1)                         -- deprecated
event:connect(function() end)   -- lowercase c is deprecated
game.Workspace.Part             -- use game:GetService() or workspace
_G.SomeVariable = true          -- avoid global state
```

### 4.4 ModuleScript Pattern
All shared logic lives in ModuleScripts. Always use this pattern:

```lua
-- Example: Modules/Config/EnemyConfig.lua
local EnemyConfig = {}

EnemyConfig.Enemies = {
    Goblin = {
        HP = 50,
        Speed = 18,
        Damage = 5,
        GoldReward = 10,
        ArmorType = "None",
    },
    Orc = {
        HP = 200,
        Speed = 8,
        Damage = 20,
        GoldReward = 25,
        ArmorType = "None",
    },
    DarkKnight = {
        HP = 300,
        Speed = 10,
        Damage = 30,
        GoldReward = 40,
        ArmorType = "Heavy",   -- resists arrows
    },
}

return EnemyConfig
```

---

## 5. GAME SYSTEMS — HOW THEY WORK

Reference this section before coding any system so Gemini understands the full design.

### 5.1 Wave System
- Total waves: **20**
- Mini-boss every **5 waves** (Wave 5, 10, 15, 20)
- Wave 20 final boss: **Lich King**
- Dragon Pass path unlocks at **Wave 10**
- Wave data lives in `WaveConfig.lua` — never hardcode wave contents in scripts

### 5.2 Crystal (Lose Condition)
- The **Kingdom Crystal** has HP (e.g. 1000 HP)
- When an enemy reaches the Crystal, it deals damage equal to its `CrystalDamage` stat
- If Crystal HP reaches 0 → trigger Game Over for all players
- Crystal HP is server-authoritative only

### 5.3 Tower Placement Rules
- Players spend gold to place towers
- Max towers per player = configurable (default 5, expandable via "Tower Slot +1" purchase)
- Towers can only be placed on designated **PlacementZone** parts in the map
- Tower targeting priority: **First** (closest to Crystal) by default
- Towers attack automatically once placed — no player input needed after placement

### 5.4 Hero Classes
- Each player picks one class at match start
- Classes: Knight (free), Ranger (free), Mage (149R$), Necromancer (199R$), StormCaller (249R$), DragonKnight (299R$)
- Abilities have **cooldowns** — managed server-side
- Hero HP is server-authoritative; death triggers a respawn timer (not a revive purchase)
- Revive Token (25R$) allows mid-death instant revive

### 5.5 Enemy Armor Types
- `None` — takes full damage from all sources
- `Heavy` — takes 50% damage from Archer/Ranger arrows
- `Undead` — takes 150% damage from Mage spells, 50% from physical
- `Flying` — ignores ground towers (only Mage Tower, Lightning Rod, and hero spells hit)

### 5.6 Gold Economy
- Gold is **per-player**, not shared
- Sources: killing enemies (GoldReward stat), wave completion bonus
- Sinks: placing towers, upgrading towers, upgrading hero stats
- Gems are a **separate premium currency** — never mix with Gold logic

### 5.7 Multiplayer (Co-op)
- 2–6 players in one server
- Each player controls their own hero
- Tower placement is individual (players can't sell each other's towers)
- Shared win/lose condition — if Crystal dies, everyone loses

---

## 6. MONETIZATION RULES (CRITICAL)

> Never write code that gives paying players an unfair gameplay advantage over free players. Cosmetics and convenience only — not power.

### 6.1 Game Passes (one-time)
| Pass | ProductId Placeholder | What to code |
|---|---|---|
| Mage Class | `MAGE_PASS_ID` | Check `MarketplaceService:UserOwnsGamePassAsync()` on join |
| Storm Caller | `STORM_PASS_ID` | Same pattern |
| Dragon Knight | `DRAGON_PASS_ID` | Same pattern |
| VIP Pass | `VIP_PASS_ID` | +25% gold multiplier flag on PlayerData |
| 2x XP Pass | `XP_PASS_ID` | Double XP flag on PlayerData |
| Infinite Mode | `INFINITE_PASS_ID` | Gate the Infinite Mode lobby |

### 6.2 Developer Products (repeatable)
Handle in `MonetizationManager.server.lua` using `MarketplaceService.ProcessReceipt`.
| Product | ProductId Placeholder |
|---|---|
| 500 Gems | `GEMS_500_ID` |
| 1500 Gems | `GEMS_1500_ID` |
| 5000 Gems | `GEMS_5000_ID` |
| Revive Token | `REVIVE_TOKEN_ID` |
| Tower Slot +1 | `TOWER_SLOT_ID` |

> Always use placeholder constant names like `MAGE_PASS_ID`. Never hardcode actual Roblox IDs in logic — store them in `EconomyConfig.lua`.

---

## 7. DATA SAVING (DataStore RULES)

- Use `DataStoreService` for persistent player data
- Save on: `Players.PlayerRemoving`, `game:BindToClose()`
- **Never** save every frame or every kill — it will hit rate limits
- Data schema lives in `DataManager.server.lua`

```lua
-- Default player data shape
local DEFAULT_DATA = {
    XP = 0,
    Level = 1,
    Gems = 0,
    TowerSlots = 5,
    OwnedClasses = {"Knight", "Ranger"},  -- free classes always unlocked
    Cosmetics = {},
    TotalWins = 0,
    TotalMatches = 0,
}
```

---

## 8. PERFORMANCE RULES

These matter a lot for Roblox — bad performance = players leave.

- **No infinite loops without `task.wait()`** — always yield
- **Destroy enemies properly** when they die or reach the Crystal — no memory leaks
- **Use `CollectionService` tags** to manage enemies and towers instead of searching the workspace every frame
- **Never use `FindFirstChild` in a loop** — cache references at the top of the script
- **Limit raycasts** — don't raycast every frame; use heartbeat with intervals
- **Tween GUI animations** using `TweenService` — never manually animate in a loop
- **Pool projectiles** (arrows, fireballs) if possible — destroy and recreate is fine for early development

---


---

## 10. MAP & WORLD RULES

- **Three enemy paths:** Forest Path, Undead Graveyard Path, Dragon Pass
- Dragon Pass is **disabled / blocked** until Wave 10 — use a gate Part that destroys/moves
- All paths must have **Waypoint** parts named `Waypoint_1`, `Waypoint_2`... that enemies follow
- The **Kingdom Crystal** is a Part in workspace named `KingdomCrystal` with a `CrystalHP` IntValue inside it
- PlacementZones are Parts with the `CollectionService` tag `"PlacementZone"`
- Enemy spawn points are Parts tagged `"EnemySpawn"` — one per path

---

## 11. WHAT GEMINI SHOULD ALWAYS DO

- ✅ Write full, working Luau code — not pseudocode or skeletons
- ✅ Add comments explaining every major block of code (beginner-friendly)
- ✅ Follow the folder structure in Section 3 exactly
- ✅ Ask "does this belong on server or client?" before writing any script
- ✅ Use constants from Config modules instead of hardcoded numbers
- ✅ Remind the developer to replace placeholder IDs before publishing
- ✅ Suggest which file to put new code in if unsure where it belongs

## 12. WHAT GEMINI SHOULD NEVER DO

- ❌ Never use `wait()` — always `task.wait()`
- ❌ Never run game logic on the client
- ❌ Never hardcode enemy stats, tower stats, or prices inside logic scripts
- ❌ Never use `game.Players` directly — use `game:GetService("Players")`
- ❌ Never write code that bypasses Roblox's economy or exploits the platform
- ❌ Never generate placeholder code that doesn't actually run — all code must be functional
- ❌ Never skip error handling on DataStore calls (always wrap in `pcall`)

---

## 13. PROGRESS.MD — YOUR RESPONSIBILITY

`PROGRESS.md` lives in the root of this project alongside this file. Gemini is responsible for keeping it accurate and up to date.

### When to update PROGRESS.md

| The developer says... | What Gemini must do |
|---|---|
| "I pushed to GitHub" / "I committed" | Add a new version block to Version History, bump version number, update Current Status table |
| "I finished [feature]" | Check off ✅ that item in the Master Feature Checklist |
| "I rolled back" / "I reverted to [version]" | Add row to Rollback Log, update Current Version in status table, uncheck affected features |
| "I found a bug" | Add new 🔴 Open row to Bug Tracker with description |
| "Bug [#] is fixed" | Update Bug Tracker row to 🟢 Resolved, note the fix in Version History |
| "I removed [feature]" | Uncheck it in checklist, note reason in Version History under "What was removed" |
| "Update my progress" | Ask what changed since last update, then update all relevant sections |
| "Update progress — I pushed v[X]" | Log version, update checklist, update status table — all in one go |

### Version numbering rule (always follow this)
- `v0.X.0` — a full phase is complete (e.g. enemy system done = v0.4.0)
- `v0.X.Y` — small fix or partial feature within a phase (e.g. v0.4.1)
- `v1.0.0` — first public Roblox release

### GitHub sync rule
PROGRESS.md must always reflect the **current state of the main branch**. If a rollback happens on GitHub, PROGRESS.md rolls back with it — uncheck features that were removed and log the rollback clearly.

### Never do this in PROGRESS.md
- ❌ Never mark a feature complete unless the developer confirmed it works
- ❌ Never skip logging a rollback — it is the most important record to keep
- ❌ Never delete old version history entries — always keep the full log

