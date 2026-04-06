# SCRIPTS KNOWLEDGE BASE

## OVERVIEW

`scripts/` 是项目主逻辑层：全局状态、战斗、地图、商店、UI 控制器和资源脚本都在这里。

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Main orchestration | `main.gd` | Map / combat / shop / transition glue |
| Global state | `game_state.gd` | Currency, level, reset, auto-fire unlock |
| Global events | `event_bus.gd` | Typed cross-system signals |
| Wave flow | `wave_manager.gd` | Spawn queue, intermission, victory trigger |
| Map state | `map_manager.gd`, `floor_graph.gd`, `map_node.gd` | Layer graph and traversal |
| Player / ship | `player.gd`, `ship/landship.gd` | Movement, repair, ship HP |
| Combat actors | `tank.gd`, `mechanical_dog.gd`, `turret.gd`, `projectile*.gd` | Core combat behavior |
| Shop | `shop_screen.gd`, `shop_item.gd` | Fixed upgrades |
| UI controllers | `ui/*.gd` | HUD, map, wave, end screens |
| Data resources | `resources/wave_data.gd`, `resources/wave_set.gd` | Resource script types |

## CONVENTIONS

- `class_name` is used on gameplay/resource classes, except MCP autoload plugin code outside this tree
- Use `@onready` for node binding, `preload()` for linked scenes/resources
- Keep gameplay discovery loose through autoloads and node groups (`ship`, `enemies`)
- `scripts/ui/` is controller logic for `.tscn` files in `scenes/ui/`
- `scripts/resources/` defines typed resource classes consumed by `.tres` files under `resources/`

## ANTI-PATTERNS

- Do not assume `turret_ui.gd` is authoritative for progression; it is still placeholder-heavy
- Do not scatter new wave logic across files; extend wave/resource flow carefully
- Do not hardcode parent-relative UI node lookups in more places unless scene structure is stable
- Do not treat `WaveSet.get_wave()` as zero-based; it is explicitly 1-based
- Do not add hidden global coupling when EventBus or GameState already owns the concern

## HOTSPOTS

- `wave_manager.gd`: hardcoded layer/wave mapping and scene spawn assumptions
- `main.gd`: central flow glue; changes here ripple across map/combat/shop
- `shop_screen.gd`: modifies ship state, upgrades, and turret installation in one place
- `ui/map_screen.gd`: large UI controller with selection + panning + traversal behavior

## VALIDATION

- No unit test harness in this tree
- Validate against `docs/what-expected-behavior.md`
- Prefer runtime verification via Godot MCP for flow changes
