# PROJECT KNOWLEDGE BASE

**Generated:** 2026-04-07
**Commit:** fdc695b
**Branch:** master

## OVERVIEW

Godot 4.6 top-down landship defense roguelike prototype. Runtime is scene-driven; gameplay state is coordinated through autoload singletons and typed EventBus signals.

## STRUCTURE

```text
./
├── project.godot          # main scene, autoloads, input map
├── scenes/                # scene composition by gameplay domain
├── scripts/               # gameplay logic, UI logic, resources
├── resources/             # .tres gameplay data
├── addons/godot_mcp/      # runtime TCP control plugin/autoload
├── config/                # MCP server config
└── docs/                  # product behavior baseline
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Startup flow | `project.godot`, `scenes/main.tscn`, `scripts/main.gd` | Main scene bootstraps the whole run directly |
| Global state | `scripts/game_state.gd` | Currency, layer, upgrades, reset |
| Global events | `scripts/event_bus.gd` | Typed signal hub |
| Map progression | `scripts/map_manager.gd`, `scripts/floor_graph.gd`, `scripts/ui/map_screen.gd` | Route selection and layer flow |
| Combat waves | `scripts/wave_manager.gd` | Spawning, intermission, completion |
| Ship / player / turrets | `scripts/ship/landship.gd`, `scripts/player.gd`, `scripts/turret.gd` | Core moment-to-moment gameplay |
| Shop | `scripts/shop_screen.gd` | Fixed upgrade list |
| Validation baseline | `docs/what-expected-behavior.md` | Current expected product behavior in Chinese |
| MCP runtime control | `addons/godot_mcp/mcp_interaction_server.gd` | Autoload TCP server on 127.0.0.1:9090 |

## ENTRY POINTS

- `project.godot` → `run/main_scene="res://scenes/main.tscn"`
- Autoloads:
  - `MapManager`
  - `EventBus`
  - `GameState`
  - `WaveManager`
  - `McpInteractionServer`

## CONVENTIONS

- Files: `snake_case.gd`, `snake_case.tscn`, `snake_case.tres`
- Classes: `PascalCase`
- Components: `*Component` suffix (`HealthComponent`, `ToughnessComponent`)
- UI helper classes: `*UI` suffix (`MapNodeUI`)
- Private runtime fields: leading underscore (`_can_fire`, `_repair_timer`)
- Signals are typed where possible; prefer signal flow over direct polling across systems
- Product docs are written in Chinese; code comments are mixed but mostly English

## ANTI-PATTERNS (THIS PROJECT)

- Do not assume there is a real automated test suite; there is none
- Do not add `.sisyphus/` files back into git history; local-only workspace metadata
- Do not rely on `turret_ui.gd` for real upgrade flow; current upgrade path lives in shop/game state
- Do not hardcode new wave/layer mappings in more places; `wave_manager.gd` is already brittle here
- Do not expose MCP server beyond local debugging assumptions without reviewing `_cmd_eval()` risk

## UNIQUE STYLES

- Main gameplay loop starts directly into map flow; no traditional main menu gate
- Validation is expected to be Godot-MCP driven or manual checklist driven, not unit-test driven
- Wave resources use 1-based wave lookup (`WaveSet.get_wave()`)
- Ship and enemies use node groups (`ship`, `enemies`) as loose discovery points

## COMMANDS

```bash
# Run project from repo root
godot4 --path .

# In this environment, preferred runtime verification is via Godot MCP
# Main project path: G:\dev\operation-taklamakan
```

## NOTES

- `addons/godot_mcp/` is not passive tooling; it runs as an autoload at runtime
- `docs/what-expected-behavior.md` is the product baseline; keep code and doc aligned
- There is no CI, no export preset, and no packaged test runner right now
