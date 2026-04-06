# WHAT EXPECTED BEHAVIOR

## Purpose

This document describes the **expected behavior of the current product build** in this repository. It is not an ideal future design doc. It is a practical baseline for QA, iteration, and archival reference.

## Product Summary

The current product is a Godot 4 top-down landship defense roguelike prototype. The player moves on a fixed landship, manages turrets, survives combat waves, and progresses through a 3-layer route-selection structure with combat, rest, and shop nodes.

## Expected Runtime Flow

1. Launching the project should start a run immediately and show the **map screen**.
2. Selecting a combat-related node should enter a **combat session**.
3. Combat should run as a **wave-based defense encounter** around the landship.
4. Completing a combat session should return the player to the **map flow** for the next layer or node.
5. Entering a shop node should show the **shop UI**, allow purchases, then return to the map.
6. Destroying the ship should trigger **game over**.
7. Completing the layer-3 boss combat should trigger **victory**.

## Expected Core Player Behavior

### 1. Player Movement

- The player character exists on the landship as a child object.
- Movement uses WASD-style directional input.
- The player should remain constrained to the ship play area and not freely leave the hull.

### 2. Landship

- The landship is a fixed combat platform during battle.
- The ship has visible HP state and can take damage from enemies.
- The ship can be repaired when the player stays near the hull and holds the repair input long enough.
- When ship HP reaches zero, the run should end in failure.

### 3. Turrets

- The ship exposes 8 turret slots around the hull.
- A new run should begin with starter turrets already installed on some slots.
- Turrets should support:
  - manual control when the player is close enough,
  - autonomous fire once fire-control is unlocked,
  - toughness/paralysis behavior,
  - repair after paralysis.

#### Manual Turret Behavior

- If the player moves into a turret interaction zone and activates it, the turret should enter manual mode.
- In manual mode, the turret barrel should rotate toward the mouse position.
- Firing input should launch projectiles toward the aim point.
- Leaving turret range or entering paralysis should exit manual mode.

#### Auto-Fire Behavior

- Auto-fire is not active by default at run start.
- Buying the fire-control upgrade should unlock auto-fire globally for turrets.
- When auto-fire is unlocked and a turret is not in manual mode or paralyzed, it should target the nearest valid enemy and fire automatically.

#### Turret Toughness Behavior

- Nearby ship damage events should reduce turret toughness.
- If toughness is depleted, the turret should become paralyzed and stop functioning.
- Toughness should recover over time.
- A paralyzed turret should be repairable by the player after holding repair input nearby.

## Expected Enemy Behavior

### Tank

- Tanks should spawn from designated spawn points.
- Tanks should move toward the ship.
- On reaching the ship, they should damage it.
- On death, they should emit death flow and reward currency.

### Mechanical Dog

- Mechanical dogs should spawn from designated spawn points.
- They should act as ranged enemies.
- Their attacks should pressure the ship during combat waves.

### Boss Tank

- The final layer should contain boss combat pressure via the boss tank setup.
- Clearing the final combat session is expected to represent the run’s victory condition.

## Expected Wave System Behavior

- Combat should be split into multiple waves per layer session.
- Before the first wave, there should be a short preparation/intermission period.
- During active waves, enemies spawn over time from spawn markers.
- When all enemies in a wave are defeated, the game should enter intermission.
- Intermission UI should support:
  - continue to next wave,
  - repair the ship,
  - jump to upgrade/shop flow when applicable.
- Completing all waves for a non-final combat should return the run to map progression.
- Completing all waves for the final layer should end the run with victory.

## Expected Map / Progression Behavior

- The run uses a 3-layer progression structure.
- The map should show reachable nodes and allow selecting the next valid node.
- Node types currently expected in flow include:
  - combat,
  - elite,
  - shop,
  - rest,
  - boss/end progression nodes.
- Rest nodes should heal part of the ship HP.
- Shop nodes should pause combat flow and open the shop screen.

## Expected Shop Behavior

The shop is expected to show fixed upgrade items rather than a random pool.

Current expected purchasable effects:

- **Turret Damage +10%**: increases turret damage output.
- **Fire Control System**: unlocks automatic turret fire.
- **Hull Repair Kit**: restores part of ship HP.
- **New Turret**: installs a turret into an empty slot.

Additional expectations:

- Purchases should cost currency.
- Unaffordable items should not be purchasable.
- Purchased one-time items should not be repeatedly buyable in the same run where that would break progression.

## Expected State / Reset Behavior

- A new run should initialize with baseline currency, layer, level-display, kills, and upgrade state.
- Ending a run should transition to a terminal state (victory or defeat).
- Resetting a run should restore default progression state, clear upgrades, reset map progress, and restore ship HP.

## Expected UI Behavior

- HUD should show ship health.
- Wave UI should appear during intermission or completion states and hide during active combat.
- Map UI should be the primary navigation layer between combats.
- Shop UI should be modal enough to clearly separate shopping from combat/map flow.
- Turret visual state should communicate:
  - idle,
  - interactable,
  - manual control,
  - paralyzed.

## Expected Non-Goals For Current Build

The current archived product is **not expected** to provide:

- multiple turret archetypes,
- relic/collection systems,
- persistent metaprogression,
- out-of-run unlock trees,
- multiplayer,
- save/load mid-run,
- polished art/audio production.

## QA-Oriented Acceptance View

For the current archived product, the most important expected outcomes are:

1. The project launches successfully.
2. The player can move on the ship.
3. The ship can take damage and be repaired.
4. Turrets can be manually controlled.
5. Auto-fire can be unlocked and then works.
6. Waves spawn enemies and resolve correctly.
7. Map progression, shop flow, and rest flow are connected.
8. Losing the ship causes game over.
9. Clearing the final layer combat causes victory.

## Document Intent

This file is the archival reference for **what the build is supposed to do right now**. If implementation and runtime behavior diverge from this document, either the code should be fixed or this document should be updated to match the intentional product baseline.
