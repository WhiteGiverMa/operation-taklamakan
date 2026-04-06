# Decisions

## Session: ses_29dc37e6affeXfLt0f4IKuB7Gd

### Tech Stack
- Engine: Godot 4.6.1
- Language: GDScript primary, C# secondary
- View: Top-down 2D

### Architecture
- Autoloads: GameState, WaveManager, EventBus
- Player is child of ship (local space movement)
- Turrets are children of ship
- Enemies exist in world space
- Resources (.tres) for all data configuration

### Design Decisions
- Single turret type + upgrades (MVP)
- Fire control system is upgrade (default manual)
- Turret toughness auto-recovers, ship HP manual repair only
- Fixed turret positions (8-10 slots)
- 360° turret rotation
- Enemy spawn at fixed points
- Repair = channeled (hold R, 2 seconds)
- Auto-targeting = nearest enemy
- Map: Slay the Spire style, 3 layers
- Death = complete reset

### Task 18 Decisions (2026-04-07)
- Keep combat scene always loaded and toggle visibility/process state for map/combat/shop transitions instead of introducing a new scene manager late in MVP.
- Treat layer progression as wave subsets from one shared wave set: [1,2] for layer 1, [3,4] for layer 2, [5] for layer 3 boss.
- Add placeholder boss by reusing tank.gd with larger scene scale and overridden stats rather than introducing a new AI script.
- Return to next layer's start node directly after clearing a layer so the map remains explorable without auto-consuming the first encounter on the new floor.
