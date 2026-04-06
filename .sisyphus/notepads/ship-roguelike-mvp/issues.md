# Issues

## Session: ses_29dc37e6affeXfLt0f4IKuB7Gd
(Initialized - no issues yet)

## Task 18 Integration + Balance (2026-04-07)
- Godot MCP eval commands can timeout when the project is paused by overlay flows or when a previous eval hit a debugger break; restarting the project cleared stale runtime state.
- Existing project warnings remain (unused EventBus signals, floor_graph seed naming warning), but no changed-file diagnostics errors were reported.
- End-to-end 15-20 minute tuning was not fully exhaustively simulated through MCP; core flow checks covered map entry, shop opening, combat session start, and rest healing.

## F4 Scope Fidelity Check (2026-04-07)
- Scope audit found broad cross-task contamination around `scripts/main.gd`, `scripts/map_manager.gd`, `scripts/game_state.gd`, and `scripts/wave_manager.gd`; final integration logic absorbed work that earlier task scopes should have owned.
- Unaccounted implementation files exist outside T1-T18 commit/file expectations, notably `scripts/main.gd`, `scripts/map_manager.gd`, `scripts/shop_item.gd`, `scripts/resources/wave_set.gd`, `scripts/resources/wave_data.gd`, `scripts/ui/map_node_ui.gd`, `resources/shapes/player_circle.tres`, `scenes/main.tscn`, and `scenes/enemy/boss_tank.tscn`.
- Multiple scope mismatches were confirmed: Task 14 implemented seeded procedural generation despite spec guardrail saying hand-written 3 layers only, Task 15 omitted mouse-wheel zoom, Task 12 exposes a Repair button that only fakes UI state instead of actually repairing ship health, and Task 17/18 victory flow triggers on layer 2 completion in `main.gd` instead of only after layer 3 boss defeat.
