# 碰撞层规范

## 目的

统一项目内 2D 物理碰撞层（collision layer）与碰撞掩码（collision mask）的语义，避免继续用裸数字在脚本和场景里各自约定，导致敌我命中、交互检测和后续扩展互相污染。

本规范基于当前项目已落地实现收敛，并包含玩家受击击退所需的独立层语义。

## 当前落地结论

项目当前实际使用了 6 个 2D 物理层：

| 层号 | 名称 | 当前承担职责 | 典型节点 |
|---|---|---|---|
| 1 | `ship` | 陆行舰船体实体碰撞 | `Landship` |
| 2 | `turret` | 炮塔实体碰撞 | 各炮塔本体 |
| 3 | `enemy` | 敌方单位实体碰撞 | `Tank`、`MechanicalDog`、Boss |
| 4 | `player_projectile` | 我方投射物命中层 | `Projectile` |
| 5 | `enemy_projectile` | 敌方投射物命中层 | `EnemyProjectile` |
| 6 | `player` | 玩家实体碰撞 / 击退接收 | `PlayerCharacter` |

玩家角色当前使用独立的 `player` 层参与物理碰撞，但**不承担血量与死亡职责**；敌人和敌弹可对其施加击退，炮塔交互范围通过 mask 监听玩家进入。

## 标准层表

后续所有 2D 碰撞实现统一按下表执行：

| 层号 | 名称 | 谁挂在这一层 | 应该检测谁 |
|---|---|---|---|
| 1 | `ship` | 陆行舰 hull、本体承伤静态实体 | `enemy`、`enemy_projectile` |
| 2 | `turret` | 炮塔承伤实体 | `enemy`、`enemy_projectile` |
| 3 | `enemy` | 敌方单位本体 | `ship`、`turret` |
| 4 | `player_projectile` | 我方所有投射物 | `enemy` |
| 5 | `enemy_projectile` | 敌方所有投射物 | `ship`、`turret`、`player` |
| 6 | `player` | 玩家角色本体 | `enemy`、`enemy_projectile` |

## 交互规则

### 1. 舰船 / 炮塔 / 敌方本体

- `ship` 只承担“被敌人本体撞击”和“被敌方弹体命中”的目标角色。
- `turret` 只承担“被敌人本体撞击”和“被敌方弹体命中”的目标角色。
- `enemy` 只承担“撞击舰船/炮塔/玩家”和“被我方弹体命中”的角色；敌人移动目标仍应保持为舰船，而不是主动索敌玩家。

### 2. 投射物

- 我方投射物固定放在 `player_projectile`，mask 只开 `enemy`。
- 敌方投射物固定放在 `enemy_projectile`，mask 开 `ship`、`turret` 与 `player`。
- 投射物不互相碰撞，也不与发射者阵营本体碰撞。

### 3. 玩家与交互区

- 玩家角色当前占用 `player` 层，只监听 `enemy` 与 `enemy_projectile`，用于接收实体阻挡与击退。
- 玩家当前不承受血量伤害；敌人本体和敌方弹体命中玩家时，只应触发击退与动作打断，不应引入玩家血条。
- 炮塔交互范围属于**玩法触发区**，不是承伤/阻挡实体；应保持 `Area2D.collision_layer = 0`，仅通过 `collision_mask` 监听 `player`。

## 使用约束

### 禁止事项

- 禁止继续在脚本里写“Layer 3 = bit 2 = value 4”这种一次性注释式约定，而不在文档和项目设置中登记。
- 禁止把交互 `Area2D`、承伤实体、投射物混挂到同一层，仅靠业务代码区分。
- 禁止在新功能里随意复用 1~5 层做临时检测用途。
- 禁止只在 `.tscn` 或只在脚本里改层/掩码而不检查另一侧是否有覆盖逻辑。

### 推荐做法

- 优先在 `project.godot` 维护 2D physics layer names，让编辑器内直接显示语义名。
- 同类对象保持统一：同一阵营、同一职责的对象使用同一层语义。
- 新增碰撞参与者前，先判断它是“实体阻挡/承伤”“投射物”“交互触发区”中的哪一类，再决定是否要新层。

## 当前代码映射

| 对象 | 当前文件 | 规范归属 |
|---|---|---|
| 陆行舰 | `scripts/ship/landship.gd` | `ship` |
| 炮塔本体 | 敌方弹体通过 layer 2 命中 | `turret` |
| 炮塔交互区 | `scripts/turret.gd` + `scenes/turret/turret.tscn` | 非独立层，`Area2D` 仅监听玩家 |
| 坦克 / Boss / 机械狗 | `scripts/tank.gd`、`scripts/mechanical_dog.gd` | `enemy` |
| 我方投射物 | `scripts/projectile.gd` | `player_projectile` |
| 敌方投射物 | `scripts/enemy_projectile.gd` | `enemy_projectile` |
| 玩家 | `scripts/player.gd` | `player` |

## 变更流程

当需要新增第 6 层及以上语义时，必须同时完成以下三件事：

1. 在 `project.godot` 注册 layer name。
2. 更新本文档中的标准层表与交互规则。
3. 在 `AGENTS.md` 的碰撞层摘要里同步简表，避免知识库和项目设置脱节。
