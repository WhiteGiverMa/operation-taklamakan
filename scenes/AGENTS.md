# SCENES KNOWLEDGE BASE

## OVERVIEW

`scenes/` 是运行时装配层。这里定义视觉层级、节点关系、脚本挂载点和预制体边界。

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Root runtime scene | `main.tscn` | Root scene for the whole run |
| Ship composition | `ship/landship.tscn`, `ship/player_character.tscn` | Hull, slots, player |
| Turret prefab | `turret/turret.tscn` | Barrel, interaction area, toughness |
| Enemy prefabs | `enemy/*.tscn` | Tank, dog, boss, enemy projectile |
| UI scenes | `ui/*.tscn` | HUD, map, wave, victory/game-over |
| Shop scene | `map/shop_screen.tscn` | Shop layout |
| Projectile prefabs | `projectile.tscn`, `enemy/enemy_projectile.tscn` | Friendly/enemy shots |

## CONVENTIONS

- Scene files are grouped by gameplay domain, not by engine node type
- UI scenes live in `scenes/ui/`, but some UI-like domain scenes live outside (`scenes/map/shop_screen.tscn`)
- `.tscn` files generally pair with a script under `scripts/` using mirrored names
- Main scene holds gameplay root, ship, UI layer, and spawn points together

## ANTI-PATTERNS

- Do not move nodes casually when scripts rely on `$Path` bindings or parent-relative lookups
- Do not rename ship/turret/player nodes without checking script discovery assumptions
- Do not duplicate prefab behavior into scenes when a paired script already owns it
- Do not assume all UI scenes are pure presentation; several contain flow-critical scripts

## HOTSPOTS

- `main.tscn`: scene glue for runtime composition
- `ui/map_screen.tscn`: large navigation surface tied to `map_screen.gd`
- `ship/landship.tscn`: source of turret slots and ship gameplay anchors

## VALIDATION

- Scene changes should be checked in running project, not only by reading text scene files
- When scene hierarchy changes, re-check all `$NodePath` and `get_node_or_null()` lookups in paired scripts
