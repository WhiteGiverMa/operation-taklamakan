# 塔克拉玛干行动项目手册
- 项目名：Operation Taklamakan（OT/塔克拉玛干行动）
> 这是个人项目，要求agent有**owner意识**，敢于重构、发现潜在问题，0容忍屎山

> 工作中尽量使用中文

## 概述

Godot 4.6 俯视角陆行舰塔防 Roguelike 原型。运行时场景驱动，游戏状态通过 autoload 单例和类型化 EventBus 信号协调。

## 结构

```text
./
├── project.godot          # main scene, autoloads, input map
├── scenes/                # scene composition by gameplay domain
├── scripts/               # gameplay logic, UI logic, resources
├── resources/             # .tres gameplay data
├── addons/godot_mcp/      # runtime TCP control plugin/autoload (vendored from shared fork)
├── config/                # MCP server config
└── docs/                  # product behavior baseline
```

## 查找指南

| 任务 | 位置 | 说明 |
|------|----------|-------|
| 启动流程 | `project.godot`, `scenes/main.tscn`, `scripts/main.gd` | 主场景直接引导整个运行 |
| 全局状态 | `scripts/game_state.gd` | 货币、层数、升级、重置 |
| 全局事件 | `scripts/event_bus.gd` | 类型化信号中心 |
| 地图推进 | `scripts/map_manager.gd`, `scripts/floor_graph.gd`, `scripts/ui/map_screen.gd` | 路线选择与层流程 |
| 战斗波次 | `scripts/wave_manager.gd` | 生成、间歇、完成 |
| 舰船 / 玩家 / 炮塔 | `scripts/ship/landship.gd`, `scripts/player.gd`, `scripts/turret.gd` | 核心实时玩法 |
| 商店 | `scripts/shop_screen.gd` | 固定升级列表 |
| 验证基线 | `docs/what-expected-behavior.md` | 当前预期产品行为（中文） |
| 碰撞层规范 | `docs/collision-layers.md`, `project.godot` | 2D physics layer 语义、交互边界、命名登记 |
| MCP 运行时控制 | `addons/godot_mcp/mcp_interaction_server.gd` | Autoload TCP 服务，端口 127.0.0.1:9090，脚本 vendor 自统一 fork |

## ENTRY POINTS

- `project.godot` → `run/main_scene="res://scenes/main.tscn"`
- Autoloads:
  - `GUIDE`
  - `InputManager`
  - `MapManager`
  - `EventBus`
  - `GameState`
  - `WaveManager`
  - `McpInteractionServer`

## 约定

- 文件命名：`snake_case.gd`、`snake_case.tscn`、`snake_case.tres`
- 类命名：`PascalCase`
- 组件后缀：`*Component`（如 `HealthComponent`、`ToughnessComponent`）
- UI 辅助类后缀：`*UI`（如 `MapNodeUI`）
- 私有运行时字段：前导下划线（如 `_can_fire`、`_repair_timer`）
- 信号尽量类型化；跨系统通信优先用信号流而非直接轮询
- 代码注释、产品文档尽量用中文
- 输入系统通过 **GUIDE + `InputManager` 包装层**工作
- 碰撞层统一以 `docs/collision-layers.md` 为准；编辑器层名登记在 `project.godot`

### 简要碰撞表

| 层号 | 名称 | 主要对象 | 主要检测目标 |
|---|---|---|---|
| 1 | `ship` | 陆行舰 | `enemy`、`enemy_projectile` |
| 2 | `turret` | 炮塔本体 | `enemy`、`enemy_projectile` |
| 3 | `enemy` | 敌方单位 | `ship`、`turret`、`player` |
| 4 | `player_projectile` | 我方投射物 | `enemy` |
| 5 | `enemy_projectile` | 敌方投射物 | `ship`、`turret`、`player` |
| 6 | `player` | 玩家角色 | `enemy`、`enemy_projectile` |

详细规则、交互区约束、扩层流程见：`docs/collision-layers.md`

## 反模式（本项目）

- 不要假设存在真正的自动化测试套件——没有
- 不要把 `.sisyphus/` 文件重新加入 git 历史——这是本地工作区元数据
- 不要依赖 `turret_ui.gd` 实现真正的升级流程——当前升级路径在商店/游戏状态
- 不要在更多地方硬编码波次/层数映射——`wave_manager.gd` 已够脆弱
- 不要在未审查 `_cmd_eval()` 风险的情况下将 MCP 服务暴露到本地调试范围之外

## 特殊风格

- 主玩法循环直接进入地图流程——无传统主菜单门
- 验证预期通过 Godot-MCP 驱动或人工清单驱动，非单元测试驱动
- `addons/godot_mcp/` 的运行时脚本来自 `G:\dev\godot-mcp-fc-a` / `WhiteGiverMa/godot-mcp-full-control-adaptive`
- 波次资源使用 1 基数查找（`WaveSet.get_wave()`）
- 舰船和敌人使用节点组（`ship`、`enemies`）作为松散发现点

## 命令

```bash
# 从仓库根目录运行项目
godot4 --path .

# 本环境下，首选运行时验证方式是 Godot MCP
# 项目主路径：G:\dev\operation-taklamakan
```

## 备注

- `addons/godot_mcp/` 不是被动工具——它作为 autoload 在运行时运行
- 下游同步优先使用 fork 仓库中的 `scripts/sync-downstream.ps1`，不要在项目内长期分叉维护 runtime 脚本
- `docs/what-expected-behavior.md` 是产品基线——保持代码与文档一致
- 当前无 CI、无导出预设、无打包测试运行器

## 外部文档

[GUIDE速查表](docs\GUIDE_CHEAT_SHEET.md)