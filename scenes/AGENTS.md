# SCENES KNOWLEDGE BASE

## OVERVIEW

`scenes/` 是运行时装配层。这里定义视觉层级、节点关系、脚本挂载点和预制体边界。

## 查找指南

| 任务 | 位置 | 说明 |
|------|----------|-------|
| 根运行时场景 | `main.tscn` | 整个运行的根场景 |
| 舰船装配 | `ship/landship.tscn`, `ship/player_character.tscn` | 船体、槽位、玩家 |
| 炮塔预制体 | `turret/turret.tscn` | 炮管、交互区、韧性 |
| 敌人预制体 | `enemy/*.tscn` | 坦克、狗、Boss、敌人弹药 |
| UI 场景 | `ui/*.tscn` | HUD、地图、波次、胜利/失败 |
| 商店场景 | `map/shop_screen.tscn` | 商店布局 |
| 弹药预制体 | `projectile.tscn`, `enemy/enemy_projectile.tscn` | 友军/敌人弹药 |

## 约定

- 场景文件按玩法域分组，而非引擎节点类型
- UI 场景放在 `scenes/ui/`，但某些类 UI 域场景在外部（如 `scenes/map/shop_screen.tscn`）
- `.tscn` 文件通常与 `scripts/` 下同名脚本配对
- 主场景包含玩法根、舰船、UI 层和生成点

## 反模式

- 不要随意移动节点——脚本可能依赖 `$Path` 绑定或父相对查找
- 不要重命名舰船/炮塔/玩家节点——需检查脚本发现假设
- 不要在场景中重复预制体行为——配对脚本已拥有该职责
- 不要假设所有 UI 场景都是纯展示——若干包含流程关键脚本

## 风险热点

- `main.tscn`：运行时装配的场景粘合
- `ui/map_screen.tscn`：大型导航面，与 `map_screen.gd` 绑定
- `ship/landship.tscn`：炮塔槽位和舰船玩法锚点的来源

## 验证

- 场景变更应在运行项目中检查，不能只读文本场景文件
- 场景层级变更时，重新检查配对脚本中所有 `$NodePath` 和 `get_node_or_null()` 查找
