
### Task 11: Enemy AI (Pathfinding + Attack)

#### Implementation
- Updated tank.gd with:
  - Dynamic target finding: Uses `get_tree().get_first_node_in_group("ship")` to find Landship
  - Collision damage with cooldown (0.5s) to prevent instant-kill on contact
  - Currency drop on death: `EventBus.enemy_died.emit(self, global_position, currency_reward)`
- Created mechanical_dog.gd with:
  - Ranged attack: Spawns enemy_projectile.tscn at intervals
  - Stops moving when within attack_range (400px) to shoot
  - Higher speed (150 vs 100) but lower health (50 vs 75)
- Created enemy_projectile.gd:
  - Area2D projectile that damages ship/turrets on contact
  - Auto-destroy after 5 seconds to prevent memory leaks
  - Uses collision layer 5 (enemy_projectile), mask 1+2 (ship+turret)
- Added 4 spawn points to main.tscn using Marker2D nodes:
  - Left (100, 540), Right (1820, 540)
  - Top (960, 100), Bottom (960, 980)
- Updated landship.tscn to add `groups=["ship"]` for enemy targeting

#### Key Patterns
- Enemy AI uses simple "move toward target" with `(_target.global_position - global_position).normalized()`
- Collision damage cooldown prevents frame-perfect damage: `_collision_damage_timer` checks before reapplying
- Ranged enemies stop at attack range: `if distance_to_target > attack_range: move else: attack`
- Enemy death currency: EventBus.enemy_died(enemy, position, reward) for WaveManager to track
- Using groups for target finding is cleaner than name-based lookups

#### Collision Layers Setup
```
Layer 1: Ship (player/landship)
Layer 2: Turrets
Layer 3: Enemies (tank, mechanical_dog)
Layer 4: Player Projectiles
Layer 5: Enemy Projectiles
```

#### Verified
- Project runs without errors (only expected EventBus unused signal warnings)
- Both enemy scenes properly configured with scripts and collision shapes
- Tank uses collision damage, MechanicalDog uses ranged projectiles
- Spawn points placed at 4 corners around 1920x1080 screen

### Task 10 Turret Toughness (2026-04-06)
- ToughnessComponent mirrors HealthComponent as a Node with typed signals, auto-recovery in _physics_process, and a recovery threshold that ends paralysis before full restore.
- Turret toughness uses EventBus.ship_damaged distance filtering, so nearby ship hits drain turret toughness without altering turret damage output or enemy damage pipelines.
- Repair stays simple and local to turret: when player remains in interaction range and holds the existing repair action for 2 seconds, the paralyzed turret fully restores toughness and exits paralysis.
- The toughness UI is safest as a lightweight ProgressBar scene instanced by turret.gd, which keeps UI changes scoped to turret behavior and avoids broad scene edits.


### Task 14 Map Generation (2026-04-06)
- FloorGraph uses seeded RandomNumberGenerator and row-based node counts to keep each floor deterministic while still varying between 10-15 nodes.
- Map nodes are plain RefCounted data objects with string ids, forward/incoming connections, and JSON serialization so map equality checks can use to_string() safely.
- MapManager is an autoload that mirrors FloorGraph traversal state and emits EventBus map/shop/layer signals, keeping map generation decoupled from upcoming UI work.

### Task 18 Integration + Balance (2026-04-07)
- Main scene now orchestrates the run loop by layering map UI and shop UI over the combat scene instead of swapping scenes, which keeps autoload state and ship/turret instances stable across node visits.
- WaveManager now supports per-layer wave sequences and boss_tank_count in WaveData, letting one 5-wave resource set drive Layer 1 (waves 1-2), Layer 2 (waves 3-4), and Layer 3 boss finale (wave 5).
- Economy balance is centralized through EventBus.enemy_died reward values and GameState._on_enemy_died(), so kill rewards automatically update currency without each caller needing separate bookkeeping.
- Auto-fire balance remains simple: turrets reuse their manual projectile pipeline, nearest-enemy targeting, and GameState.turret_damage_multiplier so shop upgrades affect both manual and auto modes consistently.
