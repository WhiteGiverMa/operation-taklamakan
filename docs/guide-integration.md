# GUIDE 接入与落地清单

## 文档目的

这份文档描述 `operation-taklamakan` 当前项目中 **G.U.I.D.E**（Godot Universal Input Definition Engine）的接入现状、目标结构、扩展步骤与验证方式。

它服务于以下场景：

- 继续完成当前 GUIDE 接入工作；
- 新成员快速理解输入系统结构；
- 后续把更多玩法输入迁到 GUIDE；
- 为 GUT / MCP / 人工验证提供统一输入基线。

---

## 官方参考

- 官方文档：<https://godotneers.github.io/G.U.I.D.E/>
- GitHub 仓库：<https://github.com/godotneers/G.U.I.D.E>
- 触发器参考：<https://godotneers.github.io/G.U.I.D.E/reference/triggers>
- 修饰器参考：<https://godotneers.github.io/G.U.I.D.E/reference/modifiers>

---

## 当前项目状态

截至当前仓库状态，GUIDE **已经不是“未接入”**，而是 **基础接入已完成，仍需继续扩展**。

### 已经完成的部分

- `project.godot` 已注册 GUIDE autoload：
  - `GUIDE="*res://addons/guide/guide.gd"`
- 项目已经有统一输入包装层：
  - `scripts/input_manager.gd`
- 已有 GUIDE Action 资源：
  - `resources/input/actions/move.tres`
  - `resources/input/actions/repair.tres`
  - `resources/input/actions/interact.tres`
  - `resources/input/actions/fire.tres`
  - `resources/input/actions/pause_toggle.tres`
  - `resources/input/actions/ui_back.tres`
- `resources/input/actions/map_pan_hold.tres`
- `resources/input/actions/map_pan_delta.tres`
- `resources/input/actions/upgrade_toggle.tres`
- 已有 GUIDE Mapping Context：
  - `resources/input/contexts/combat.tres`
  - `resources/input/contexts/turret_manual.tres`
  - `resources/input/contexts/map.tres`
  - `resources/input/contexts/shop.tres`
  - `resources/input/contexts/overlay_back.tres`
- 部分业务逻辑已经改为通过 `InputManager` 读取 GUIDEAction：
  - `scripts/turret.gd`
  - `scripts/ship/landship.gd`
  - `scripts/main.gd` 负责在地图 / 战斗 / 菜单流之间切换输入上下文

### 还没有完成的部分

- 还没有一份项目级接入说明，导致后续扩展容易失去一致性；
- 尚未确认所有 UI、菜单、暂停、设置页输入都完成统一迁移；
- 尚未建立 GUIDE 接入后的自动化回归测试；
- 尚未形成“新增输入功能必须补 Action / Context / 验证”的固定流程。

---

## 目标结构

本项目推荐坚持以下输入架构：

```text
业务脚本
  ↓
scripts/input_manager.gd
  ↓
GUIDEAction / GUIDEMappingContext 资源
  ↓
GUIDE autoload
```

设计原则：

1. **业务代码不直接散落调用 GUIDE**；
2. **所有输入能力先沉淀为 Action 资源**；
3. **不同运行流通过 Context 切换**；
4. **场景流切换由 `InputManager` 统一管理**。

---

## 当前关键文件

| 位置 | 作用 |
|------|------|
| `project.godot` | 注册 GUIDE 和 `InputManager` autoload |
| `scripts/input_manager.gd` | 项目输入包装层，按 FlowContext 管理 context |
| `resources/input/actions/` | 输入能力定义 |
| `resources/input/contexts/` | 场景/流程上下文定义 |
| `scripts/main.gd` | 地图 / 战斗 / 商店 / 暂停流切换时调用 `InputManager.activate_*()` |
| `scripts/turret.gd` | 使用 `InputManager.fire_action / interact_action / repair_action` |
| `scripts/ship/landship.gd` | 使用 `InputManager.repair_action` |

---

## 当前输入上下文设计

`scripts/input_manager.gd` 里已经建立了以下流转上下文：

- `MENU`
- `MAP`
- `COMBAT`
- `SHOP`
- `PAUSE`
- `SETTINGS`

其中实际启用的 GUIDE context 包括：

- `combat.tres`
- `turret_manual.tres`
- `map.tres`
- `overlay_back.tres`

当前逻辑特点：

- 进入地图流：`InputManager.activate_map()`
- 进入战斗流：`InputManager.activate_combat()`
- 进入炮台手操：`InputManager.activate_turret_manual()`
- 进入暂停/设置：`InputManager.activate_pause()` / `activate_settings()`
- 底层通过 `GUIDE.set_enabled_mapping_contexts(contexts)` 原子切换上下文集合

这意味着项目当前不是“push/pop 叠栈式”管理，而是“**按当前流状态重建一组生效 context**”。这个选择是合理的，优点是可预测、调试简单。

---

## 新增输入能力时的标准流程

以后凡是新增一个玩法输入，不要直接在脚本里写死 `Input.is_action_pressed("xxx")`。标准步骤如下。

### 第 1 步：定义 Action

在 `resources/input/actions/` 下创建一个新的 `GUIDEAction` 资源。

建议命名：

- `dash.tres`
- `confirm.tres`
- `cancel.tres`
- `weapon_cycle.tres`

关键字段：

- `name`
- `action_value_type`
- `display_name`
- `display_category`
- `is_remappable`

常见类型建议：

| 输入类型 | action_value_type |
|------|------|
| 单次触发按钮 | Bool |
| 扳机/强度 | Axis 1D |
| 移动方向 | Axis 2D |

### 第 2 步：把 Action 加入合适的 Context

在 `resources/input/contexts/*.tres` 里选择正确的上下文添加 mapping：

- 战斗内动作 → `combat.tres`
- 炮台手操专属动作 → `turret_manual.tres`
- 地图拖拽/路线选择 → `map.tres`
- 菜单返回/取消 → `overlay_back.tres`

如果现有 context 语义不清晰，就新建 context，而不是把所有东西都塞到 `combat.tres`。

### 第 3 步：在 `InputManager` 暴露访问入口

按现有风格在 `scripts/input_manager.gd` 中：

1. 预加载新的 action 资源；
2. 如有需要，预加载新的 context；
3. 提供只读 getter；
4. 更新 `_activate_for_current_state()` 中的 context 组合。

目标是让业务层只认识：

```gdscript
InputManager.some_action
```

而不是到处 `preload("res://resources/input/actions/...")`。

### 第 4 步：业务脚本接入

业务脚本统一通过 `InputManager` 读动作：

```gdscript
if InputManager.fire_action.is_triggered():
	_fire()
```

不要重新退回到原生：

```gdscript
if Input.is_action_pressed("fire"):
	# 不推荐
```

### 第 5 步：补验证

每新增一个输入能力，至少补一项验证：

- 手工验证步骤；
- MCP 复现场景；
- 后续若已接入 GUT，则补单元/运行时测试。

---

## 当前项目推荐的 Context 划分原则

### 1. Combat Context

只保留“玩家在正常战斗态一定可用”的动作，例如：

- 移动
- 维修
- 炮台交互
- 暂停

### 2. Turret Manual Context

只放“进入炮台接管后才应生效”的动作，例如：

- 开火
- 退出手操（若后续加入）
- 手操视角专属动作

### 3. Map Context

只放地图节点选择、拖拽、滚轮缩放等输入。

### 4. Overlay Back Context

只放暂停、设置、弹窗类界面的返回/取消动作。

这样做的价值是：

- 减少不同界面抢输入；
- 让 `main.gd` 的流转和输入状态一一对应；
- 后续调试时可以直接定位是“流状态错了”还是“mapping 错了”。

---

## 当前已知风险与注意事项

### 1. 不要绕过 `InputManager`

项目已经有输入包装层，继续接 GUIDE 时应保持这一层作为唯一入口。否则很快会出现：

- 一部分逻辑读 GUIDE；
- 一部分逻辑读原生 InputMap；
- 一部分逻辑从资源取 action；

最后导致无法判断某个输入为什么只在某些状态下生效。

### 2. 不要把原生 InputMap 和 GUIDE 双轨长期并存且语义重叠

短期迁移阶段可以并存；
但同一个能力不要长期同时维护：

- `move_left` 原生 action 一套；
- `move.tres` GUIDEAction 再一套。

长期应该收敛到 GUIDE 为主。

### 3. Action 语义优先，不要直接按物理键命名

推荐：

- `interact`
- `pause_toggle`
- `map_pan_hold`

不推荐：

- `space_key`
- `left_mouse`
- `esc_key`

这样未来重映射、手柄支持和 UI 提示才不会崩。

### 4. 修改 Context 后要实际跑场景验证

GUIDE 的问题常常不是脚本报错，而是：

- 上下文没切对；
- 触发器没选对；
- 修饰器导致值方向反了；
- 同一动作被更高优先级 context 吞掉。

这些必须跑场景才能确认。

### 5. 键盘方向键映射必须显式表达目标轴

对于 GUIDE 里的键盘方向输入，本项目固定采用下面的可读性约束，避免后续出现“看起来没问题、实际依赖隐式轴语义”的漂移：

- `GUIDEInputKey` 的原始键值可视为先落在 `x` 分量；
- 映射到垂直方向时，必须先用 `InputSwizzle(YXZ)` 把值搬到 `y` 轴，再按需要只对 `y` 轴做取反；
- 映射到水平方向时，默认保留 `x` 轴，只在需要时只对 `x` 轴做取反；
- 不再使用“`x/y/z` 全部取反”的 `Negate` 资源去间接达成方向语义；
- 资源命名必须体现意图，例如 `SwizzleToY`、`NegateY`、`NegateX`，不要再使用含糊名称如 `Negate`、`SwizzleYPositive`。

这样做的目标不是改变 GUIDE 的能力，而是让 `combat.tres` 这类 context 文件在纯文本审查时也能一眼看出：

- 哪个键映射到 `x`；
- 哪个键映射到 `y`；
- 哪个方向被取反；
- 修改后是否仍保持上下左右的对称性。

### 6. 消费 2D 移动输入时统一归一化

无论输入来源是键盘、未来的摇杆，还是多个 context 的组合，消费 `value_axis_2d` 的移动逻辑都应在业务层统一归一化，避免对角线速度或输入设备切换带来速度漂移。

例如：

```gdscript
var input_direction := InputManager.move_action.value_axis_2d.normalized()
velocity = input_direction * speed
```

如果未来需要保留模拟量幅值（例如手柄轻推慢走），再单独为该玩法设计不同 action / context，不要在当前战斗步行输入上混用“方向语义”和“幅值语义”。

---

## 推荐验证流程

### 方式一：编辑器直接运行

适合验证：

- 场景切换是否触发正确 context；
- 菜单 / 地图 / 战斗之间的输入隔离；
- 炮台接管与退出；
- 地图拖拽、暂停、返回等 UI 行为。

### 方式二：Godot MCP 驱动

当前项目已经有 `godot_mcp`，这是非常适合 GUIDE 验证的手段。

推荐检查项：

- 主菜单时，战斗输入不应生效；
- 进入地图时，仅地图相关输入生效；
- 进入战斗时，移动/维修/交互/暂停可用；
- 进入炮台手操后，开火输入生效；
- 暂停页打开后，返回类输入生效，战斗输入被屏蔽。

### 方式三：后续接入 GUT 后补基础回归

GUT 不负责替代所有运行时输入验证，但可以补：

- `InputManager` 在不同 FlowContext 下启用的 context 集是否正确；
- 某些动作资源是否存在并能被加载；
- 某些关键流程是否正确调用 `activate_*()`。

---

## GUIDE 扩展落地清单

### A. 基线检查

- [x] GUIDE autoload 已注册
- [x] 已存在 `InputManager`
- [x] 已存在 action 资源目录
- [x] 已存在 context 资源目录
- [x] 已有战斗 / 地图 / 覆盖层基础 context

### B. 结构完善

- [ ] 明确列出每个 FlowContext 对应哪些 GUIDE context
- [ ] 确认暂停、设置、主菜单输入是否都走 `InputManager`
- [ ] 统一梳理仍在直接使用原生 `Input` 的位置
- [ ] 为新增功能约定“先加 Action，再改逻辑”流程

### C. 功能扩展

- [ ] 为后续手柄支持补充 mapping
- [ ] 为地图操作补充更细粒度动作（缩放、拖拽结束、确认）
- [ ] 为菜单/设置页补充确认、返回、切页等输入动作
- [ ] 评估是否需要输入重绑定 UI

### D. 验证与回归

- [ ] 为 GUIDE 流转补一份人工验收清单
- [ ] 用 MCP 固化一套基础输入回归流程
- [ ] GUT 接入后，为 `InputManager` 补最小单测

---

## 建议的下一步

从当前状态出发，最值得做的不是再“安装一次 GUIDE”，而是做这三件事：

1. **梳理所有仍然直接读原生 Input 的脚本并迁到 `InputManager`**；
2. **把主菜单 / 暂停 / 设置 / 地图 / 战斗的 context 切换验证跑通**；
3. **为 `InputManager` 建立最小 GUT 测试和 MCP 回归脚本**。

这样 GUIDE 才算真正从“资源接上了”进入“项目可维护了”。
