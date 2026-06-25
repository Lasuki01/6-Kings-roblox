# PROGRESS.md — Kingdom Siege
> Single source of truth for all project progress.
> Updated on every GitHub push, feature change, bug fix, or rollback.
> Maintained by Gemini automatically — do not edit manually unless noted.

---

## 📍 Current Status

| Field | Value |
|---|---|
| **Current Version** | v0.3.7 |
| **Phase** | ⚙️ Core Systems |
| **Last Updated** | June 2026 |
| **Last GitHub Commit** | feat: straighten forest and undead paths to match dragon pass |
| **Branch** | `main` |
| **Active Feature** | Straight Map Paths and Symmetrical Pedestals |
| **Blocking Issues** | None |

---

## 🗺️ Master Feature Checklist

Track every planned feature here. Status updates as development progresses.

### 🏗️ Phase 1 — Foundation
- [x] Rojo project structure created
- [x] `default.project.json` configured
- [x] GitHub repository initialized
- [x] `GEMINI.md` rules file added
- [x] `PROGRESS.md` tracking file added
- [x] Folder structure synced to Roblox Studio

### 🗺️ Phase 2 — Map & World
- [x] Base map layout built (castle center + 3 paths)
- [x] Forest Path with waypoints
- [x] Undead Graveyard Path with waypoints
- [x] Dragon Pass (locked until Wave 10)
- [x] Kingdom Crystal placed with HP IntValue
- [x] PlacementZones tagged with CollectionService
- [x] EnemySpawn points tagged per path
- [x] Skybox and atmosphere set (medieval fantasy)

### ⚙️ Phase 3 — Core Systems
- [x] `GameManager.server.lua` — master game loop
- [x] `WaveConfig.lua` — all 20 wave definitions
- [x] `EnemyConfig.lua` — all enemy stats
- [x] `TowerConfig.lua` — all tower stats
- [x] `HeroConfig.lua` — all hero class stats
- [x] `EconomyConfig.lua` — gold, gem prices
- [x] RemoteEvents scaffolded in ReplicatedStorage

### 👹 Phase 4 — Enemy System
- [ ] `EnemyManager.server.lua` created
- [ ] Enemy spawning logic
- [ ] Waypoint pathfinding (enemies walk the 3 paths)
- [ ] Enemy HP, damage, death logic
- [ ] Gold reward on kill
- [ ] Crystal damage on reach
- [ ] Goblin implemented
- [ ] Orc implemented
- [ ] Dark Knight implemented (Heavy armor)
- [ ] Skeleton Mage implemented (ranged attacker)
- [ ] Troll implemented (HP regen)
- [ ] Dragon Boss implemented (flies over towers)
- [ ] Lich King final boss (Wave 20)

### 🗼 Phase 5 — Tower System
- [ ] `TowerManager.server.lua` created
- [ ] Tower placement on PlacementZones
- [ ] Tower targeting (First = closest to Crystal)
- [ ] Archer Tower (3 upgrade levels)
- [ ] Mage Tower — slow + damage (3 upgrade levels)
- [ ] Catapult — AoE, slow fire rate (3 upgrade levels)
- [ ] Frost Spire — freeze (unlocks Wave 5, 3 levels)
- [ ] Lightning Rod — chain damage (unlocks Wave 10, 3 levels)
- [ ] Tower sell / refund system
- [ ] Per-player tower slot limit (default 5)

### 🧙 Phase 6 — Hero System
- [ ] `HeroManager.server.lua` created
- [ ] `HeroController.client.lua` — input & movement
- [ ] `AbilityController.client.lua` — casting spells/shooting
- [ ] Class select UI on match join
- [ ] Knight — Sword melee + Shield Bash stun
- [ ] Ranger — Bow + Rain of Arrows AoE
- [ ] Mage — Staff + Fireball / Ice Nova
- [ ] Necromancer — Dark Magic + Raise Dead
- [ ] Storm Caller — Thunder Spear + Chain Lightning
- [ ] Dragon Knight — Dragon Breath AoE cone
- [ ] Hero HP, respawn timer
- [ ] Ability cooldowns (server-side)

### 💰 Phase 7 — Economy & UI
- [ ] `GoldManager.server.lua` — gold per player
- [ ] Gold HUD display (synced via RemoteEvent)
- [ ] Wave counter HUD
- [ ] Kingdom Crystal HP bar
- [ ] Hero HP bar
- [ ] Tower upgrade UI
- [ ] Gem currency system (separate from gold)

### 💎 Phase 8 — Monetization
- [ ] `MonetizationManager.server.lua` created
- [ ] `ProcessReceipt` handler for Developer Products
- [ ] Mage Class game pass (149 R$)
- [ ] Necromancer Class game pass (199 R$)
- [ ] Storm Caller game pass (249 R$)
- [ ] Dragon Knight game pass (299 R$)
- [ ] VIP Pass — +25% gold, exclusive tower (199 R$)
- [ ] 2x XP Pass (99 R$)
- [ ] Infinite Mode Access (149 R$)
- [ ] 500 Gems dev product (49 R$)
- [ ] 1500 Gems dev product (129 R$)
- [ ] 5000 Gems dev product (399 R$)
- [ ] Revive Token dev product (25 R$)
- [ ] Tower Slot +1 dev product (59 R$)
- [ ] Gem Shop UI

### 💾 Phase 9 — Data & Persistence
- [ ] `DataManager.server.lua` created
- [ ] DataStore save on PlayerRemoving
- [ ] DataStore save on game:BindToClose
- [ ] Default player data schema
- [ ] XP & Level system
- [ ] Owned classes save/load
- [ ] Gems balance save/load
- [ ] Tower slot count save/load
- [ ] Cosmetics save/load

### 🎮 Phase 10 — Polish & Launch
- [ ] Main menu / lobby UI
- [ ] Class select screen
- [ ] Victory screen
- [ ] Game over screen
- [ ] Sound effects (enemy death, tower fire, crystal hit)
- [ ] Background music
- [ ] Particle effects (spells, explosions)
- [ ] Infinite Mode (endless waves post Wave 20)
- [ ] Playtesting (2–6 players)
- [ ] Roblox publish (first public release)

---

## 📋 Version History

Every GitHub push gets logged here. Most recent at the top.

---

### v0.3.7 — Straight Paths and Symmetry Alignment
**Date:** June 2026
**GitHub Commit:** `feat: straighten forest and undead paths to match dragon pass`
**Branch:** `main`
**Type:** 🗺️ Map Perfection

**What was added:**
- Straightened the Forest Path and Undead Graveyard Path to run linearly along `Z = 0`.
- Reduced waypoint counts for both paths from 6 to 5, matching the Dragon Pass layout exactly.
- Unified `rampStartIdx` to `3` for all paths.
- Symmetrized pedestal generation so all paths spawn 4 pedestals on Segment 1 and 2 pedestals on Segment 2, yielding 6 pedestals total.
- Aligned spawn gatehouses, fences, tombstones, and torches symmetrically along the straightened roads.

**What was removed:**
- Turn waypoints on Forest and Undead paths.

**Rollbacks:** None

**Notes:** All three ingress paths are now perfectly straight and balanced.

---

### v0.3.6 — Pedestal Equalization
**Date:** June 2026
**GitHub Commit:** `fix: equalize tower placement blocks across all paths`
**Branch:** `main`
**Type:** 🗺️ Map Balance

**What was added:**
- Equalized the number of tower placement pedestals to exactly 6 outside the Castle Keep on all three paths.
- Adjusted Forest and Undead paths (3 segments) to spawn exactly 1 pair of pedestals per segment at the midpoint (total 6).
- Set Dragon Pass (2 segments) to spawn 2 pairs on Segment 1 and 1 pair on Segment 2 (total 6).
- Programmed biome props to spawn at alternating locations (25 and 55 studs) on segments with single midpoint pedestals to prevent overlaps.

**What was removed:**
- Extra 4 pedestals from Forest Path (reduced from 10 to 6).
- Extra 4 pedestals from Undead Graveyard Path (reduced from 10 to 6).

**Rollbacks:** None

**Notes:** Pedestals are now perfectly balanced and symmetric across all entry roads.

---

### v0.3.5 — Path and Gate Adjustments
**Date:** June 2026
**GitHub Commit:** `fix: relocate dragon gate and remove forest hill blocks`
**Branch:** `main`
**Type:** 🗺️ Map Polish

**What was added:**
- Relocated the destructible `"DragonGate"` portcullis wall to the main spawn portal at `Z = 200`.
- Closed the volcanic portal at the spawn point using the gate, and opened up the checkpoint at `Z = 120` to allow players to traverse the entire road.

**What was removed:**
- Removed the second gatehouse checkpoint structure at `Z = 120`.
- Removed the green grassy hill spheres (`ForestHill_` parts) from the Forest Path margins to clear the way for tower placements.

**Rollbacks:** None

**Notes:** Paths are now completely clear of unintended blockages, and tower placements are uninhibited by decorative spheres.

---

### v0.3.4 — Symmetrical Alignment Perfection
**Date:** June 2026
**GitHub Commit:** `fix: resolve prop overlaps and add fortified gatehouse`
**Branch:** `main`
**Type:** 🗺️ Map Bugfix

**What was added:**
- Overhauled `DecoratePathSegment` to alternate longitudinal spacing, preventing any overlapping or clipping between environmental props and placement pedestals.
- Set placement pedestals strictly at 25 and 55 studs, and grass hills, fences, tombstones, and lava cracks strictly at 40 studs on long segments.
- Built a detailed fortified Basalt Gatehouse checkpoint (two tall pillars + lintel arch) around `DragonGate` at `Z = 120` along the lava path.
- Enclosed the destructible portcullis `DragonGate` part within the gatehouse archway structure.

**What was removed:** Undefined local variables that triggered nil arithmetic errors during environment detailing.

**Rollbacks:** None

**Notes:** Delivers flawless, professional-grade layout symmetry with zero structural overlapping.

---

### v0.3.3 — Symmetrical Map Detailing
**Date:** June 2026
**GitHub Commit:** `feat: symmetrical path decorations and vector math alignment`
**Branch:** `main`
**Type:** 🗺️ Map Perfection

**What was added:**
- Replaced hardcoded decoration and pedestal arrays with dynamic vector math calculations based on path segments.
- Programmed `DecoratePathSegment` to compute path directions (`dir`) and perpendicular lines (`perp`).
- Positioned all placement pedestals (sandstone blocks) flanking path midpoints and segment intervals, parallel and symmetrical to the road borders.
- Dynamically aligned environmental details parallel to path directions (hills and fences for Forest, tombstones and slate crosses for Graveyard, lava cracks and basalt columns for Dragon Pass).
- Added rotation alignment to fences, tombstones, and cracks so they run parallel to path lines.
- Refined watchtower peak coordinates and castle wall crenellations.

**What was removed:** Hardcoded coordinate tables for props and pedestals.

**Rollbacks:** None

**Notes:** Delivers a mathematically perfect, visually cohesive, and balanced map layout.

---

### v0.3.2 — Map Aesthetics Overhaul
**Date:** June 2026
**GitHub Commit:** `feat: map visual quality and props`
**Branch:** `main`
**Type:** 🗺️ Map Aesthetics

**What was added:**
- Overhauled path segments to remove blocking curbs.
- Added detailed crenellations (battlements) along the top edges of all Castle Keep walls.
- Decorated watchtowers with stone tiers, conical peaks, and glowing cyan magical crystals that cast light.
- Implemented `SpawnTorchesAlongSegment` to build detailed wooden torch posts on stone bases with glowing neon flames, fire particles, and orange light sources flanking all roads.
- Added Forest biomization props: grass hills (green spheres) and wooden fences.
- Added Graveyard biomization props: procedurally generated slate tombstones and stone cross markers (slanted at angles).
- Added Volcanic biomization props: flat glowing neon orange lava cracks and slanted black basalt columns.

**What was removed:** Long continuous stone curbs that blocked intersection turns.

**Rollbacks:** None

**Notes:** Delivers a high-fidelity Roblox fantasy atmosphere with real light propagation and detailed models.

---

### v0.3.1 — Map Rebuild & Grid-Alignment
**Date:** June 2026
**GitHub Commit:** `fix: complete map rebuild and alignment`
**Branch:** `main`
**Type:** 🗺️ Map Fix

**What was added:**
- Completely overhauled `MapManager.server.lua` to spawn a highly structured map.
- Built a massive `100x4x100` Castle Keep with surrounding grey stone walls and Tall Corner Watchtowers.
- Built a 3-tier marble altar for the `KingdomCrystal`.
- Reconfigured paths to run strictly along cardinal grid axes, removing overlaps and aligning joints cleanly.
- Added visual stone curbs flanking all paths.
- Added thematic gatehouses/portals at spawning points: a wooden gatehouse (Forest), purple neon crypt arch (Graveyard), and black basalt portal with the `DragonGate` (Dragon Pass).
- Positioned 18 raised sandstone cobblestone placement pedestals with golden highlight borders flanking the paths.

**What was removed:** Legacy floating-point diagonal path calculations.

**Rollbacks:** None

**Notes:** Resolves all overlap, visual alignment, and structural layout issues.

---

### v0.3.0 — Core Systems Setup
**Date:** June 2026
**GitHub Commit:** `feat: core systems and config modules`
**Branch:** `main`
**Type:** ⚙️ Core

**What was added:**
- Created 5 configuration ModuleScripts in `ReplicatedStorage.Modules.Config`:
  - `EconomyConfig.lua` (Starting gold, multiplier values, placeholder gamepass/product IDs).
  - `EnemyConfig.lua` (HP, speed, armor types, and descriptions for all 7 enemies).
  - `TowerConfig.lua` (Cost, damage, range, splash, and unlock requirements for 3 upgrade levels).
  - `HeroConfig.lua` (HP, speed, base damage, and special abilities for 6 hero classes).
  - `WaveConfig.lua` (Structured spawn lists for all 20 game waves, incorporating paths).
- Configured four central `RemoteEvent` instances in `default.project.json` under `ReplicatedStorage.Remotes`: `PlaceTower`, `UseAbility`, `PurchaseItem`, and `SyncGameState`.
- Implemented `GameManager.server.lua` master loop handling state transitions (Lobby, Intermission, Active, Victory, GameOver), wave intermission countdowns, wave rewards distribution, and Dragon Pass gate destruction.

**What was removed:** Nothing

**Rollbacks:** None

**Notes:** This configures all fundamental mathematical structures and loop controls.

---

### v0.2.0 — Map & World Setup
**Date:** June 2026
**GitHub Commit:** `feat: map setup script`
**Branch:** `main`
**Type:** 🗺️ Map

**What was added:**
- Created `src/ServerScriptService/MapManager.server.lua` to procedurally scaffold the map.
- Implemented `KingdomCrystal` with `CrystalHP` (1000 HP).
- Configured 3 enemy paths (`ForestPath`, `UndeadPath`, `DragonPass`) with Waypoints.
- Placed and tagged `PlacementZone` parts for towers.
- Configured dramatic medieval skybox and lighting settings.

**What was removed:** Legacy default template scripts.

**Rollbacks:** None

**Notes:** Dynamic server-side map generation ensures instant playability on start.

---

### v0.1.0 — Project Initialization
**Date:** June 2026
**GitHub Commit:** `init: project setup`
**Branch:** `main`
**Type:** 🏗️ Setup

**What was added:**
- Created Rojo project structure
- Added `GEMINI.md` rules file
- Added `PROGRESS.md` tracking file

**What was removed:** Nothing

**Rollbacks:** None

**Notes:** Project scaffolding only. No game code yet.

---

*Future versions will be logged above this line in the same format.*

---

## 🐛 Bug Tracker

All bugs go here — open and resolved.

| # | Status | Description | Introduced In | Resolved In | Notes |
|---|---|---|---|---|---|
| — | — | No bugs logged yet | — | — | — |

**Status legend:** 🔴 Open &nbsp;|&nbsp; 🟡 In Progress &nbsp;|&nbsp; 🟢 Resolved &nbsp;|&nbsp; ⚫ Rolled Back

---

## ⏪ Rollback Log

When a version is rolled back on GitHub, log it here.

| Date | Rolled Back From | Rolled Back To | Reason |
|---|---|---|---|
| — | — | — | No rollbacks yet |

---

## 🏆 Milestones

Big moments in the project's life.

| Milestone | Target | Achieved |
|---|---|---|
| Project created | Phase 1 | ✅ June 2026 |
| First enemy walks a path | Phase 4 | ⬜ |
| First tower shoots an enemy | Phase 5 | ⬜ |
| Full wave 1 playable | Phase 4–5 | ⬜ |
| All 6 hero classes working | Phase 6 | ⬜ |
| First multiplayer co-op test | Phase 6 | ⬜ |
| Monetization live on Roblox | Phase 8 | ⬜ |
| First public release | Phase 10 | ⬜ |
| 1,000 visits | Post-launch | ⬜ |
| 10,000 visits | Post-launch | ⬜ |

---

## 📌 How Gemini Updates This File

> These are instructions for Gemini — not the developer.

When the developer says any of the following, update PROGRESS.md:

| Trigger phrase | What to do |
|---|---|
| "I pushed to GitHub" / "I committed" | Add a new version block in Version History, update Current Status table |
| "I finished [feature]" | Check off the matching item in Master Feature Checklist |
| "I rolled back" / "I reverted" | Add entry to Rollback Log, update Current Version in status table |
| "I found a bug" | Add new row to Bug Tracker with 🔴 Open status |
| "Bug [#] is fixed" | Update Bug Tracker row to 🟢 Resolved, log in Version History |
| "I removed [feature]" | Uncheck it in checklist, note in Version History as "removed" |
| "Update progress" | Ask what changed, then update all relevant sections |

**Version numbering rule:**
- `v0.X.0` — new phase completed (e.g. enemy system done = v0.4.0)
- `v0.X.Y` — bug fixes or small additions within a phase (e.g. v0.4.1)
- `v1.0.0` — first public Roblox release

---

*Last updated: June 2026 | Kingdom Siege | Maintained by Gemini via Google Antigravity*
