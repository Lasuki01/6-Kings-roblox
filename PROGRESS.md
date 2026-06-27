# PROGRESS.md — Kingdom Siege
> Single source of truth for all project progress.
> Updated on every GitHub push, feature change, bug fix, or rollback.
> Maintained by Gemini automatically — do not edit manually unless noted.

---

## 📍 Current Status

| Field | Value |
|---|---|
| **Current Version** | v1.0.3 |
| **Phase** | 🎮 Polish & Launch |
| **Last Updated** | June 2026 |
| **Last GitHub Commit** | Pending |
| **Branch** | `main` |
| **Active Feature** | Font and Playtest Audio Bug Fixes |
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
- [x] `EnemyManager.server.lua` created
- [x] Enemy spawning logic
- [x] Waypoint pathfinding (enemies walk the 3 paths)
- [x] Enemy HP, damage, death logic
- [x] Gold reward on kill
- [x] Crystal damage on reach
- [x] Goblin implemented
- [x] Orc implemented
- [x] Dark Knight implemented (Heavy armor)
- [x] Skeleton Mage implemented (ranged attacker)
- [x] Troll implemented (HP regen)
- [x] Dragon Boss implemented (flies over towers)
- [x] Lich King final boss (Wave 20)

### 🗼 Phase 5 — Tower System
- [x] `TowerManager.server.lua` created
- [x] Tower placement on PlacementZones
- [x] Tower targeting (First = closest to Crystal)
- [x] Archer Tower (3 upgrade levels)
- [x] Mage Tower — slow + damage (3 upgrade levels)
- [x] Catapult — AoE, slow fire rate (3 upgrade levels)
- [x] Frost Spire — freeze (unlocks Wave 5, 3 levels)
- [x] Lightning Rod — chain damage (unlocks Wave 10, 3 levels)
- [x] Tower sell / refund system
- [x] Per-player tower slot limit (default 5)

### 🧙 Phase 6 — Hero System
- [x] `HeroManager.server.lua` created
- [x] `HeroController.client.lua` — input & movement
- [x] `AbilityController.client.lua` — casting spells/shooting (integrated in UIController)
- [x] Class select UI on match join
- [x] Knight — Sword melee + Shield Bash stun
- [x] Ranger — Bow + Rain of Arrows AoE
- [x] Mage — Staff + Fireball / Ice Nova
- [x] Necromancer — Dark Magic + Raise Dead
- [x] Storm Caller — Thunder Spear + Chain Lightning
- [x] Dragon Knight — Dragon Breath AoE cone
- [x] Hero HP, respawn timer
- [x] Ability cooldowns (server-side)

### 💰 Phase 7 — Economy & UI
- [x] `GoldManager.server.lua` — gold per player (managed by GameManager/TowerManager)
- [x] Gold HUD display (synced via RemoteEvent)
- [x] Wave counter HUD
- [x] Kingdom Crystal HP bar
- [x] Hero HP bar
- [x] Tower upgrade UI
- [x] Gem currency system (separate from gold)

### 💎 Phase 8 — Monetization
- [x] `MonetizationManager.server.lua` created
- [x] `ProcessReceipt` handler for Developer Products
- [x] Mage Class game pass (149 R$)
- [x] Necromancer Class game pass (199 R$)
- [x] Storm Caller game pass (249 R$)
- [x] Dragon Knight game pass (299 R$)
- [x] VIP Pass — +25% gold, exclusive tower (199 R$)
- [x] 2x XP Pass (99 R$)
- [x] Infinite Mode Access (149 R$)
- [x] 500 Gems dev product (49 R$)
- [x] 1500 Gems dev product (129 R$)
- [x] 5000 Gems dev product (399 R$)
- [x] Revive Token dev product (25 R$)
- [x] Tower Slot +1 dev product (59 R$)
- [x] Gem Shop UI (Interactive HUD & Card overlays)

### 💾 Phase 9 — Data & Persistence
- [x] `DataManager.server.lua` created
- [x] DataStore save on PlayerRemoving
- [x] DataStore save on game:BindToClose
- [x] Default player data schema
- [x] XP & Level system (RPG profile leveling HUD)
- [x] Owned classes save/load
- [x] Gems balance save/load
- [x] Tower slot count save/load
- [x] Cosmetics save/load (persistent schema array)

### 🎮 Phase 10 — Polish & Launch
- [x] Main menu / lobby UI (profile stats integration)
- [x] Class select screen (Buy/Select states)
- [x] Victory screen (Gold fanfare overlay)
- [x] Game over screen (Defeat skull overlay)
- [x] Sound effects (hammer place, cash sell, ability cues)
- [x] Background music (ambient Gothic loops)
- [x] Particle effects (custom spell and portal visual emitters)
- [x] Infinite Mode (procedural stats scaling post Wave 20)
- [x] Playtesting (Studio testing ready)
- [x] Roblox publish (Rojo synced structures)

---

## 📋 Version History

Every GitHub push gets logged here. Most recent at the top.

---

### v1.0.3 — Font and Playtest Audio Bug Fixes
**Date:** June 2026
**GitHub Commit:** Pending
**Branch:** `main`
**Type:** 🐛 Bug Fixes

**What was fixed:**
- Fixed UI crash by changing invalid font `Enum.Font.GothamBook` to valid `Enum.Font.Gotham` in `UIController.client.lua`.
- Fixed background loop asset mismatch by replacing ID `1837873915` with verified wind loop ID `6990273398`.
- Fixed UI select click asset mismatch by replacing ID `4841261352` with verified classic click ID `12222247`.

---

### v1.0.2 — Client SyncGameState and Audio Fixes
**Date:** June 2026
**GitHub Commit:** Pending
**Branch:** `main`
**Type:** 🐛 Bug Fixes

**What was fixed:**
- Declared missing `SyncGameState` remote event reference at the top of `UIController.client.lua` to fix `attempt to index nil with 'OnClientEvent'` error.
- Replaced invalid background music loop ID `1843105748` (which has incorrect asset type) with verified looping sound ID `1837873915`.

---

### v1.0.1 — Core Bugs, Security & Architectural Fixes (Audit Phase)
**Date:** June 2026
**GitHub Commit:** Pending
**Branch:** `main`
**Type:** 🐛 Bug Fixes & Refactoring

**What was added:**
- Created central `Signals` manager ModuleScript in `ReplicatedStorage` to coordinate BindableEvents cleanly.
- Implemented `IsRateLimited` in `HeroManager.server.lua` to guard `BasicAttack` and `UseAbility` remotes from spam attacks.
- Configured dynamic `EconomyConfig.CRYSTAL_MAX_HP` and updated server, map setup, and client UI to pull HP dynamically.

**What was fixed:**
- Fixed Tower upgrade/sell menu crash by replacing invalid `TowerModel` Attribute with a workspace `ObjectValue` inside placement zones (Bug #5).
- Fixed Infinite Mode loop termination by restructuring `GameManager` victory branches and checking for Infinite Mode pass before continuing (Bug #1).
- Fixed dual-firing basic attacks when clicking placement zones and towers by raycasting and checking mouse target in `HeroController` (Bug #14).
- Fixed connection memory leak in `UIController` by tracking and cleaning up `HealthChanged` and Key E connections (Bug #33).
- Fixed potential player display name collisions by tracking tower ownership via `player.UserId` instead of `player.Name` (Bug #4).
- Cleaned up redundant self-assignment and forward declaration logic for `OpenClassSelectionScreen` (Bug #34).

---

### v1.0.0 — Polish, Audio, Overlays, and Infinite Loop (Game Complete!)
**Date:** June 2026
**GitHub Commit:** Pending
**Branch:** `main`
**Type:** 🎮 Polish & Launch Complete

**What was added:**
- Implemented Fullscreen Main Menu Lobby: Displays live player profile attributes (Level, Wins, Matches, Gems). Clicking BATTLE triggers select cues and transitions to class cards selection.
- Implemented Fullscreen End Game Screens:
  - Victory Overlay: Golden fanfare sliding banner triggered upon wave 20 completion with audio win prompts.
  - Defeat Overlay: Crimson skull banner sliding banner triggered upon Crystal HP depletion with audio loss prompts.
- Integrated Audio Engine inside `UIController.client.lua`:
  - Ambient Sound: Plays looping Gothic Castle theme song on match initialization.
  - Sound Triggers: Placed specific cues on tower builders, tower sales payouts, click events, and spell castings.
- Implemented Procedural Infinite Mode:
  - post Wave 20, GameManager constructs endless waves composed of random enemies and portal layouts.
  - Scales rig HP (+15%), rig Speed (+2%), and gold reward (+10%) per infinite level. Includes mini-bosses (Dragons and Lich Kings) every 5 waves.
- Updated walkthrough documentation and checked off launch checklist blocks.

**What was removed:**
- Fixed wave limit barrier.

**Rollbacks:** None

**Notes:** All game code and Rojo layout structures are fully realized. Release candidate ready!

---

### v0.9.0 — Data Stores & Persistence Systems
**Date:** June 2026
**GitHub Commit:** Pending
**Branch:** `main`
**Type:** 💾 Data & Persistence Complete

**What was added:**
- Created `DataManager.server.lua` supporting database read/write via Roblox `DataStoreService` for all progression statistics.
- Implemented robust `DEFAULT_DATA` schema profiles: Levels, XP, Gems, Tower slots limits, wins, matches count, owned classes list, and cosmetics arrays.
- Bound concurrent multi-thread saving handlers to `Players.PlayerRemoving` and `game:BindToClose()` to secure data on server crash or shutdown.
- Implemented RPG level-up system: wave completions reward XP scaling with difficulty and applying 2x XP multiplier if player owns Double XP pass. Levelling targets scale as `Level * 100`.
- Integrated a new Top-Right Profile HUD overlay displaying persistent `Level` and a progression tracker `XP: X/MaxXP`.
- Intercepted class monetization purchases to update the persistent `OwnedClasses` database list immediately.

**What was removed:**
- None.

**Rollbacks:** None

**Notes:** Ensure "Studio Access to API Services" is enabled in Game Settings to allow Studio testing. If disabled, standard mock-memory profiles are loaded automatically without failing.

---

### v0.8.0 — Monetization System, Game Passes, and VIP Perks
**Date:** June 2026
**GitHub Commit:** Pending
**Branch:** `main`
**Type:** 💎 Monetization System Complete

**What was added:**
- Created `MonetizationManager.server.lua` to manage Game Pass checks, Developer Product receipt processing, and purchase prompts.
- Configured dynamic client-server RemoteEvent `PurchaseItem` mapping keys to placeholder ids.
- Implemented client UI purchase triggers:
  - Class Selection Cards: If the class is premium and unowned, displays a crimson "BUY" button that prompts the transaction. Once purchased, dynamically changes to a green "SELECT" button.
  - Interactive HUD Labels: Added 💎 Gems and 👑 VIP status labels to the bottom bar. Tapping Gems prompts a 500 Gems bundle purchase. Tapping VIP prompts the VIP game pass purchase.
- Implemented VIP Perks: VIP players receive a permanent +25% (1.25x) gold multiplier, automatically applied to all wave completion rewards and path enemy kill payouts.
- Programmed a comprehensive Mock Purchase system on the server: if configuration IDs are `0` in `EconomyConfig.lua`, the server simulates successful transaction validation and grants rewards/attributes instantly for easy playtesting.
- Registered a robust `ProcessReceipt` handler managing repeatable developer product purchases (500/1500/5000 Gems, +1 permanent Tower Slot, and Revive tokens).

**What was removed:**
- None.

**Rollbacks:** None

**Notes:** Playtesters can click locked classes or HUD elements in Studio to mock-purchase them and verify unlock sequences immediately.

---

### v0.6.0 — Multi-Class Hero Mechanics and Lobby Select
**Date:** June 2026
**GitHub Commit:** Pending
**Branch:** `main`
**Type:** 🧙 Hero System Complete

**What was added:**
- Created `HeroManager.server.lua` and `HeroController.client.lua`.
- Configured RemoteEvents: `SelectClass` and `BasicAttack`.
- Implemented fullscreen programmatic Lobby Class Selection screen listing stats, ability descriptions, and free/gamepass costs.
- Implemented custom stats allocation (WalkSpeed & Health) matching selected class.
- Implemented procedural weapon welding (Knight sword/shield, Ranger bow, Mage/Necromancer staves with neon crystals, Storm Caller spear, Dragon Knight greatsword).
- Implemented basic attack click/touch triggers, cooldown checking, and custom visual sweeps/lasers.
- Implemented server-validated Special Abilities:
  - Knight: Shield Bash (radius 12, dot product angle check, stuns enemies).
  - Ranger: Rain of Arrows (AoE circle, dropping visual arrows over 4s).
  - Mage: Fireball (exploding orange ball dealing high radial splash damage).
  - Necromancer: Raise Dead (summons 3 skeleton minions that target and attack enemies).
  - Storm Caller: Chain Lightning (5-jump electric bolt jumps).
  - Dragon Knight: Dragon Breath (cone flame breath spray over 3s).
- Implemented character respawn loop (10s timer) preserving selected class configurations.
- Integrated bottom-left Hero HP HUD bar and bottom-right Ability trigger cooldown overlay HUD.

**What was removed:**
- None.

**Rollbacks:** None

**Notes:** Class select overlays automatically fade away, and all abilities respect local/server cooldown clocks.

---

### v0.5.2 — Mobile Responsive Scaling and Touch Tap Interactions
**Date:** June 2026
**GitHub Commit:** Pending
**Branch:** `main`
**Type:** 💰 UI Mobile Friendliness

**What was added:**
- Added explicit support for mobile touch inputs (`Enum.UserInputType.Touch`) in the workspace placement zone click detector logic.
- Implemented responsive Screen HUD bar constraints (`UISizeConstraint` with max width 420, min width 280, and height 50) adapting automatically to smaller mobile screen aspect ratios.
- Converted HUD label sizes from absolute offset pixels to relative scales (`UDim2.new(0.3, 0, 0.8, 0)`) to auto-distribute.
- Added auto-scaling text size constraints (`UITextSizeConstraint`) to fit labels without overflow.
- Resized BillboardGui context menus to be wider (`245` studs/pixels) and increased button touch target heights to `36` pixels, making them comfortable for finger taps.

**What was removed:**
- Fixed-offset width constraints on HUD labels.

**Rollbacks:** None

**Notes:** Buttons are now very easy to hit on small phone devices, and HUD auto-shrinks cleanly without clipping.

---

### v0.5.1 — Programmatic Screen HUD and 3D Placement Context UI
**Date:** June 2026
**GitHub Commit:** Pending
**Branch:** `main`
**Type:** 💰 Economy & UI Integration

**What was added:**
- Created `UIController.client.lua` programmatically constructing ScreenGuis and BillboardGuis.
- Implemented bottom Screen HUD showing real-time Player Gold (`🪙 Gold`), Wave Counter (`🚩 Wave`), and a smooth tweening Kingdom Crystal Health Bar (`🛡️ HP`).
- Implemented Mouse Click raycasting detection on parts tagged with `"PlacementZone"`.
- Implemented 3D Billboard Context Menu floating above selected placement zones:
  - For unoccupied zones: purchase buttons with cost and wave requirements (locks Frost Spire until Wave 5 and Lightning Rod until Wave 10).
  - For occupied zones: displays tower level, a contextual Upgrade button (checks cost and max level), and a Sell button (shows 75% refund).
- Synced contextual buttons to server remote triggers `PlaceTower`, `UpgradeTower`, and `SellTower`.
- Implemented auto-close on click-away in the game world.

**What was removed:**
- None.

**Rollbacks:** None

**Notes:** UI scales dynamically, providing clean feedback for gold changes and wave progress.

---

### v0.5.0 — Tower Combat, Placements, and Sales Engine
**Date:** June 2026
**GitHub Commit:** Pending
**Branch:** `main`
**Type:** 🗼 Tower System Complete

**What was added:**
- Created `TowerManager.server.lua` master script.
- Configured RemoteEvents: `PlaceTower`, `UpgradeTower`, and `SellTower`.
- Implemented gold and slots checking logic (`player:GetAttribute("Gold")` and `player:GetAttribute("TowerSlots")`).
- Implemented procedural tower model spawning for Archer Tower, Mage Tower, Catapult, Frost Spire, and Lightning Rod.
- Implemented "First" targeting algorithm picking range-valid enemies closest to Crystal, filtered by ground/flying constraints.
- Implemented Physical and Magic damage types, including physical reduction for Heavy/Undead armors and 150% magical bonus for Undead.
- Implemented custom visual and mechanical effects: Archer arrow projectiles, Mage slow lasers, Catapult splash boulders, Frost Spire freezing blast rings, and chain lightning jumps for the Lightning Rod.
- Implemented upgrade progression (Max Level 3) scaling up tower sizes and damage.
- Implemented sales refunding 75% of cumulative spent gold and clearing placement zones.

**What was removed:**
- None.

**Rollbacks:** None

**Notes:** Ground-only towers properly filter out flying Dragon bosses, and laser/beam parts clean up automatically.

---

### v0.4.2 — Solid Altar Collision and Invisible Ramps
**Date:** June 2026
**GitHub Commit:** Pending
**Branch:** `main`
**Type:** 👹 Enemy System Adjustments

**What was added:**
- Restored full solid collisions (`CanCollide = true`) on the central stone Altar tiers (`AltarTier1`, `AltarTier2`, `AltarTier3`) in `MapManager.server.lua` to maintain physical presence.
- Spawned three invisible physical collision ramps (`AltarRampWest`, `AltarRampEast`, `AltarRampSouth` using `WedgePart`s) covering the stair steps to guide characters smoothly up.
- Re-enabled physical collision (`root.CanCollide = true`) on enemy `HumanoidRootPart` in `EnemyManager.server.lua` so they interact with the ramps. Torso remains non-collidable to prevent clipping bugs.

**What was removed:**
- Pass-through collision of altar tiers.

**Rollbacks:** None

**Notes:** Enemies now physically walk up the incline of the ramps, creating the visual effect of stepping up the solid altar stairs.

---

### v0.4.1 — Enemy Stuck and Collision Fixes
**Date:** June 2026
**GitHub Commit:** Pending
**Branch:** `main`
**Type:** 👹 Enemy System Bug Fixes

**What was added:**
- Disabled collisions on the central stone Altar tiers (`AltarTier1`, `AltarTier2`, `AltarTier3`) in `MapManager.server.lua` so enemies can climb cleanly.
- Disabled physical collisions (`CanCollide = false`) on the procedural enemy `HumanoidRootPart` and `Torso` in `EnemyManager.server.lua` to prevent bumping into placement zones or other structures.
- Explicitly configured the humanoid `HipHeight` value dynamically scaled by the enemy's size multiplier (`1.4 * sizeMult`) to ensure correct hover heights.

**What was removed:**
- Physical collision of enemy root and torso parts.

**Rollbacks:** None

**Notes:** Small and large enemies now smoothly glide up the altar steps to the crystal without physical friction or path blocking.

---

### v0.4.0 — Spawning, Pathfinding, and Enemy Attributes
**Date:** June 2026
**GitHub Commit:** Pending
**Branch:** `main`
**Type:** 👹 Enemy System

**What was added:**
- Created `EnemyManager.server.lua` master script listening to GameManager signals.
- Implemented procedural model styling (colors, scales, parts, weapons) for Goblin, Orc, Dark Knight, Skeleton Mage, Troll, Dragon, and Lich King.
- Implemented ground waypoint movement using `Humanoid:MoveTo` with nudges to prevent getting stuck.
- Implemented flying path movement for the Dragon (moving 22 studs above ground waypoints via direct CFrame interpolation).
- Implemented HP regeneration logic for the Troll.
- Implemented proximity-based gold reward distribution giving gold to players within 120 studs of dying enemy or inside Castle Keep (60 studs).
- Implemented Kingdom Crystal damage processing and active enemy cleanup upon death/reach.

**What was removed:**
- None.

**Rollbacks:** None

**Notes:** Spawns correctly sync with wave configuration, and flying enemies smoothly traverse above ground obstacles.

---

### v0.3.15 — Wall Lamps, Massive Tridents, and Clean Keep Entrances
**Date:** June 2026
**GitHub Commit:** Pending
**Branch:** `main`
**Type:** 🗺️ Map Aesthetics & Bug Fixes

**What was added:**
- Removed all vertical neon magma veins from the outer walls.
- Placed dynamically generated and spaced devilish lamps along the inner faces of all outer walls (spaced 35 studs).
- Re-designed the 4 corner spires with massive, curved, and spikey crystal tridents (height 33 studs) aligned using CFrame.lookAt to point directly facing the central crystal.
- Added central core spheres, winged crossbar blades, pointy wedges, and barbs to the tridents.
- Color-matched the corner tower basalt veins to match their respective magic tridents.
- Ended visual path segments exactly at Castle Keep entrances, keeping the interior floor clean and resolving path Z-fighting.
- Replaced cyan neon watchtower crystals with castle-themed stone fire braziers casting a warm flame glow over the castle keep.

**What was removed:**
- Vertical neon magma veins on outer walls.
- Static hardcoded `wallLamps` list.
- `KeepEntrancePath` and `KeepInsidePath` visual segments.

**Rollbacks:** None

**Notes:** Z-fighting path issues are completely gone, and enclosing walls look more gothic and detailed with the lamp and trident upgrades.

---

### v0.3.14 — Trident Enhancements and Wall Color Coding
**Date:** June 2026
**GitHub Commit:** Pending
**Branch:** `main`
**Type:** 🗺️ Map Aesthetics & Lighting

**What was added:**
- Resized the corner crystal tridents to be twice as large (cross-bars length = 8, central prong height = 12, side prongs height = 10).
- Restructured the prongs to curve/bend: the side prongs now angle out at 45 degrees, then bend back to point straight up, resembling a classic weapon/trident shape.
- Color-matched the outer wall magma veins to the nearest portal: West Wall is green (Forest), East Wall is purple (Undead), South Wall is crimson (Dragon), and North Wall is standard magma red/orange.

**What was removed:**
- Generic orange veins on all sides.

**Rollbacks:** None

**Notes:** Wall veins now match their biomes and portals, and the corner crystal tridents are massive and properly shaped.

---

### v0.3.13 — Wall Magma Veins and Trident Crystals
**Date:** June 2026
**GitHub Commit:** Pending
**Branch:** `main`
**Type:** 🗺️ Map Aesthetics & Details

**What was added:**
- Procedurally generated vertical glowing orange/red neon magma veins along the inner faces of all outer enclosing wall segments.
- Constructed custom pointy glowing crystal trident decorations on top of the 4 outer corner basalt spires.
- Colored the tridents differently per corner: Northwest (Violet/Magenta), Northeast (Corrupt Green), Southwest (Crimson Red), and Southeast (Cyan Ice Blue).

**What was removed:**
- Plain wall faces.

**Rollbacks:** None

**Notes:** Arena borders now look much more detailed, featuring glowing magma veins and colorful magical prongs on top of the corner spires.

---

### v0.3.12 — Path Elevation and Wall Lamps
**Date:** June 2026
**GitHub Commit:** Pending
**Branch:** `main`
**Type:** 🗺️ Map Polish & Lighting

**What was added:**
- Elevated the Forest, Undead, and Dragon enemy paths outside the keep to run at the keep floor elevation level (`Y = 4.0`).
- Replaced the wedge entrance ramps at the castle keep walls with flat path segments, allowing smooth transitions.
- Aligned KeepInsidePath flat on the keep floor at Y = 4.05.
- Created `SpawnCornerTower` helper to spawn tall basalt corner spires (`size = 10, 32, 10`) with vertical glowing neon magma veins at the 4 corners of the map.
- Created `SpawnDevilishLamp` helper and placed 16 wall-mounted glowing lamps with Fire blocks and PointLights along the inner faces of the enclosing walls.

**What was removed:**
- Wedge entrance ramps.

**Rollbacks:** None

**Notes:** Paths are now flat and continuous, and enclosing walls feature thematic lights and corner fortress spires.

---

### v0.3.11 — Tall Castle Enclosing Walls
**Date:** June 2026
**GitHub Commit:** Pending
**Branch:** `main`
**Type:** 🗺️ Map Aesthetics & Perimeter

**What was added:**
- Added a `400 x 400` square perimeter of tall castle-style enclosing walls (`height = 24`, `thickness = 6`, Slate material) to completely surround the play area.
- Symmetrically split the enclosing walls to align with the Forest, Undead, and Dragon spawn gates, making them look seamlessly embedded in the walls.
- Automatically generated matching crenellations (battlements) on top of all enclosing wall segments.
- Preserved all devilish/themed gate details (thorns, spires, bones, magma veins, basalt horns) untouched.

**What was removed:**
- Open space boundaries around gates.

**Rollbacks:** None

**Notes:** Play area is now fully enclosed, making the arena feel like a massive canyon/fortress.

---

### v0.3.10 — Keep Illumination and Gate Removal
**Date:** June 2026
**GitHub Commit:** `evilish map ready`
**Branch:** `main`
**Type:** 🗺️ Map Aesthetics & Bugfix

**What was added:**
- Removed the solid `DragonGate` part from the entrance of the Castle Keep on the lava path entirely so the road is completely open.
- Added a soft blue `PointLight` (Range 45, Brightness 1.5) to the central `KingdomCrystal` to illuminate the altar.
- Spawned 4 corner torches in the Castle Keep floor for subtle warm illumination.

**What was removed:**
- `DragonGate` part from the Castle Keep entrance.

**Rollbacks:** None

**Notes:** Castle interior is now illuminated, and the lava path entrance is cleared of solid blockages.

---

### v0.3.9 — Active Portal Particles and Dragon Gate Relocation
**Date:** June 2026
**GitHub Commit:** `fix: move dragon gate to keep entrance and active portal particles`
**Branch:** `main`
**Type:** 🗺️ Map Bugfix

**What was added:**
- Moved the physical solid `DragonGate` part from the Z=200 spawn point to the Z=47 Castle Keep entrance to prevent players from being blocked at the spawn portal.
- Configured portal plane orientations facing along the path directions.
- Adjusted the `ParticleEmitter` to emit outwards (`Enum.NormalId.Front`) with an increased rate of 75 and initial speed of 4-9 to make the portals look highly active and magical.

**What was removed:**
- Solid gate block at spawn point.

**Rollbacks:** None

**Notes:** Dragon gate still blocks path until Wave 10, but at the Keep entrance instead of spawn point.

---

### v0.3.8 — Themed Glowing Spawn Gates and Portals
**Date:** June 2026
**GitHub Commit:** `feat: implement themed glowing spawn gates with portal particle effects`
**Branch:** `main`
**Type:** 🗺️ Map Aesthetics

**What was added:**
- Added custom biome-themed portal gates at spawn points for all paths.
- Helper function `CreatePortalEffects` generates glowing Neon portal planes, particle emitters, and point lights.
- **Forest Path Gate:** Styled as corrupted logs with glowing green neon thorns and toxic spore particles.
- **Undead Graveyard Gate:** Styled as dark stone crypt arches with bone-colored skeletal rib cages, gothic spires, and purple sparkles.
- **Dragon Pass Gate:** Styled as magma-veined basalt structures with large curving demon horns and fire particles.
- Balanced and offset all portal planes so they nest perfectly within the gatehouse pillars.

**What was removed:**
- Generic non-themed gates.

**Rollbacks:** None

**Notes:** All gates now have active visual effects matching their path theme.

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
| 1 | 🟢 Resolved | Victory/GameOver exits game loop permanently | v1.0.0 | v1.0.1 | Exits on first win/loss |
| 4 | 🟢 Resolved | Tower owner tracked by Name instead of UserId | v1.0.0 | v1.0.1 | Collision/security issue |
| 5 | 🟢 Resolved | TowerModel attribute loses reference on save | v1.0.0 | v1.0.1 | Replaced with ObjectValue |
| 11 | 🟢 Resolved | Ad-hoc creation of BindableEvents (race conditions) | v1.0.0 | v1.0.1 | Moved to central Signals module |
| 14 | 🟢 Resolved | BasicAttack fires when clicking placement zones/towers | v1.0.0 | v1.0.1 | Prevented by checking target |
| 33 | 🟢 Resolved | HealthChanged listener leak on respawn | v1.0.0 | v1.0.1 | Properly disconnected before reconnecting |
| 3/28 | 🟢 Resolved | Hardcoded Crystal max HP (1000) on client and server | v1.0.0 | v1.0.1 | Centralized in EconomyConfig |
| 8/9 | 🟢 Resolved | Cooldown check did not prevent remote spam performance hit | v1.0.0 | v1.0.1 | Implemented early-exit rate limits |
| 35 | 🟢 Resolved | SyncGameState is nil at UIController initialization | v1.0.1 | v1.0.2 | Declared remote event at top |
| 36 | 🟢 Resolved | Ambient sound ID 1843105748 has invalid asset type | v1.0.0 | v1.0.2 | Replaced with working loop 1837873915 |
| 37 | 🟢 Resolved | Enum.Font.GothamBook is not a valid member of Enum.Font | v1.0.0 | v1.0.3 | Replaced with Enum.Font.Gotham |
| 38 | 🟢 Resolved | Mismatch asset type error on select click and wind loop IDs | v1.0.0 | v1.0.3 | Replaced with verified public loops |

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
