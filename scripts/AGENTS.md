# SCRIPTS KNOWLEDGE BASE

## OVERVIEW

`scripts/` 是项目主逻辑层：全局状态、战斗、地图、商店、UI 控制器和资源脚本都在这里。

## 查找指南

| 任务 | 位置 | 说明 |
|------|----------|-------|
| 主控编排 | `main.gd` | 地图/战斗/商店/过渡粘合 |
| 全局状态 | `game_state.gd` | 货币、层数、重置、自动开火解锁 |
| 全局事件 | `event_bus.gd` | 类型化跨系统信号 |
| 波次流程 | `wave_manager.gd` | 生成队列、间歇、胜利触发 |
| 地图状态 | `map_manager.gd`, `floor_graph.gd`, `map_node.gd` | 层图与遍历 |
| 玩家/舰船 | `player.gd`, `ship/landship.gd` | 移动、维修、舰船 HP |
| 战斗单元 | `tank.gd`, `mechanical_dog.gd`, `turret.gd`, `projectile*.gd` | 核心战斗行为 |
| 商店 | `shop_screen.gd`, `shop_item.gd` | 固定升级 |
| UI 控制器 | `ui/*.gd` | HUD、地图、波次、结算屏 |
| 数据资源 | `resources/wave_data.gd`, `resources/wave_set.gd` | 资源脚本类型 |

## 约定

- 玩法/资源类使用 `class_name`（MCP autoload 插件代码除外）
- 节点绑定用 `@onready`，关联场景/资源用 `preload()`
- 通过 autoload 和节点组（`ship`、`enemies`）松散发现玩法对象
- `scripts/ui/` 是 `scenes/ui/` 下 `.tscn` 文件的控制器逻辑
- `scripts/resources/` 定义类型化资源类，被 `resources/` 下的 `.tres` 文件使用

## 反模式

- 不要把 `turret_ui.gd` 当作进度的权威来源——它仍有很多占位
- 不要把波次逻辑散落到多个文件——谨慎扩展波次/资源流程
- 不要在更多地方硬编码父相对 UI 节点查找——除非场景结构稳定
- 不要把 `WaveSet.get_wave()` 当作零基数——它明确是 1 基数
- 不要在 EventBus 或 GameState 已拥有该职责时添加隐藏的全局耦合

## 风险热点

- `wave_manager.gd`：硬编码的层/波次映射和场景生成假设
- `main.gd`：中心流程粘合；改动会影响地图/战斗/商店
- `shop_screen.gd`：在一处修改舰船状态、升级和炮塔安装
- `ui/map_screen.gd`：大型 UI 控制器，包含选择 + 平移 + 遍历行为

## 验证

- 本目录无单元测试框架
- 对照 `docs/what-expected-behavior.md` 验证
- 流程变更优先用 Godot MCP 进行运行时验证
