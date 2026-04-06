# GODOT MCP ADDON KNOWLEDGE BASE

## OVERVIEW

这是一个运行时 Godot MCP 插件目录，不只是编辑器辅助代码。项目通过 autoload 的 `McpInteractionServer` 在游戏运行时暴露本地 TCP 控制能力。

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Plugin registration | `plugin.cfg` | Metadata for editor plugin |
| Runtime TCP server | `mcp_interaction_server.gd` | Local command server, JSON over TCP |
| Editor-side plugin hook | `mcp_editor_plugin.gd` | Editor plugin shell |
| Operations helpers | `godot_operations.gd` | File/scene helper operations |
| Runtime config | `../../config/mcp_server.json` | Host, port, fallback policy |

## CONVENTIONS

- `McpInteractionServer` is autoloaded via `project.godot`
- No `class_name` on `mcp_interaction_server.gd`; this is deliberate to avoid autoload conflict
- Default endpoint is `127.0.0.1:9090`, with fallback to nearby ports
- Runtime metadata is written to `user://mcp_server_runtime.json`

## ANTI-PATTERNS

- Do not expose this server outside trusted local workflows without reviewing security implications
- Do not forget `_cmd_eval()` executes arbitrary GDScript; treat it as privileged
- Do not assume the configured port is guaranteed; fallback may change actual listen port
- Do not depend on this addon in headless mode unless the enabling env var is explicitly set

## GOTCHAS

- Busy-state recovery exists because commands can hang; watch `_busy` timeout behavior
- Invalid JSON config falls back silently with warnings, not hard failure
- Any command-layer change should be tested against both runtime and external client expectations
