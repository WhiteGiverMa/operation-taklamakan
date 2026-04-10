# G.U.I.D.E 速查表

快速参考 G.U.I.D.E (Godot Universal Input Definition Engine) 在本项目中的常用 API 和用法。

> **注意**：本项目通过 `InputManager` 包装层使用 GUIDE，不直接访问 `GUIDE` 单例。

---

## 官方文档链接

- [G.U.I.D.E 文档](https://godotneers.github.io/G.U.I.D.E/)
- [GitHub 仓库](https://github.com/godotneers/G.U.I.D.E)
- [触发器参考](https://godotneers.github.io/G.U.I.D.E/reference/triggers)
- [修饰器参考](https://godotneers.github.io/G.U.I.D.E/reference/modifiers)

---

## 输入动作引用

本项目所有 GUIDE 动作都通过 `InputManager` 单例预加载访问：

| 动作名称 | 访问路径 | 用途 |
|---------|----------|------|
| `move` | `InputManager.move_action` | 玩家移动（WASD/左摇杆） |
| `fire` | `InputManager.fire_action` | 射击/炮台开火 |
| `interact` | `InputManager.interact_action` | 与炮台交互（接管/离开） |
| `repair` | `InputManager.repair_action` | 维修船体或炮台 |
| `pause_toggle` | `InputManager.pause_toggle_action` | 暂停菜单开关 |
| `ui_back` | `InputManager.ui_back_action` | UI 返回/取消 |
| `map_pan_hold` | `InputManager.map_pan_hold_action` | 地图平移按住 |
| `map_pan_delta` | `InputManager.map_pan_delta_action` | 地图平移方向 |
| `camera_zoom_in` | `InputManager.camera_zoom_in_action` | 相机放大 |
| `camera_zoom_out` | `InputManager.camera_zoom_out_action` | 相机缩小 |
| `camera_zoom_reset` | `InputManager.camera_zoom_reset_action` | 相机重置 |
| `input_hints_toggle` | `InputManager.input_hints_toggle_action` | 显示/隐藏输入提示 |

### 资源路径

```
res://resources/input/
├── actions/
│   ├── move.tres              # 2D 轴移动
│   ├── fire.tres              # 开火（持续/单击）
│   ├── interact.tres          # 交互（E键/手柄X）
│   ├── repair.tres            # 维修（R键/手柄Y）
│   ├── pause_toggle.tres      # 暂停（Esc/Start）
│   ├── ui_back.tres           # UI返回（Esc/B键）
│   ├── map_pan_hold.tres      # 地图平移按住（中键/右键）
│   ├── map_pan_delta.tres     # 地图平移方向（鼠标/右摇杆）
│   ├── camera_zoom_in.tres    # 放大（滚轮上/RT）
│   ├── camera_zoom_out.tres   # 缩小（滚轮下/LT）
│   ├── camera_zoom_reset.tres # 重置（中键点击/L3）
│   └── input_hints_toggle.tres # 输入提示开关（Tab/Select）
│
└── contexts/
    ├── combat.tres            # 战斗玩法上下文
    ├── turret_manual.tres     # 炮台手动模式（叠加）
    ├── map.tres               # 地图导航上下文
    └── overlay_back.tres      # 覆盖层返回上下文
```

---

## InputManager 包装层 API

### 动作检测方法

```gdscript
# 检测动作是否按下（持续）
if GUIDE.is_action_pressed(InputManager.fire_action):
    try_shoot()

# 检测动作是否刚按下（一帧）
if GUIDE.is_action_just_pressed(InputManager.interact_action):
    interact_with_turret()

# 检测动作是否刚释放
if GUIDE.is_action_just_released(InputManager.map_pan_hold_action):
    stop_panning()

# 获取动作强度 (0-1)
var strength := GUIDE.get_action_strength(InputManager.repair_action)
```

### 2D 轴输入

```gdscript
# 获取移动输入向量（已应用死区和归一化）
var input_vector := GUIDE.get_action_value(InputManager.move_action)
velocity = input_vector * move_speed
```

---

## 常见用法示例

### 玩家移动处理

```gdscript
# player.gd - _physics_process
func _physics_process(delta: float) -> void:
    # 获取移动输入（已处理死区和归一化）
    var input_vector := GUIDE.get_action_value(InputManager.move_action)
    
    # 应用移动
    velocity = input_vector * move_speed
    move_and_slide()
```

### 射击处理

```gdscript
# 自动射击（按住时持续）
func _process(delta: float) -> void:
    if GUIDE.is_action_pressed(InputManager.fire_action):
        try_shoot()

# 单发射击（每次刚按下触发一次）
func _process(delta: float) -> void:
    if GUIDE.is_action_just_pressed(InputManager.fire_action):
        fire_single_shot()
```

### 炮台交互

```gdscript
# 检测交互键
if GUIDE.is_action_just_pressed(InputManager.interact_action):
    if _in_turret_range:
        enter_turret_manual_mode()
    elif _manual_mode_active:
        exit_turret_manual_mode()
```

### 维修处理

```gdscript
# 持续维修（按住时）
func _process(delta: float) -> void:
    if GUIDE.is_action_pressed(InputManager.repair_action):
        if _can_repair_ship:
            repair_ship(delta)
        elif _can_repair_turret:
            repair_turret(delta)
```

### 地图平移

```gdscript
# map_screen.gd - 处理地图平移
func _process(delta: float) -> void:
    # 检测平移激活
    if GUIDE.is_action_pressed(InputManager.map_pan_hold_action):
        # 获取平移方向（鼠标移动或右摇杆）
        var pan_delta := GUIDE.get_action_value(InputManager.map_pan_delta_action)
        camera.position -= pan_delta * pan_speed * delta
```

---

## 输入上下文管理

### FlowContext 枚举

输入状态分为两个层级：流程上下文和覆盖层上下文。

```gdscript
enum FlowContext {
    NONE,      # 无上下文
    MENU,      # 主菜单
    MAP,       # 地图界面
    COMBAT,    # 战斗玩法
    SHOP,      # 商店界面
    PAUSE,     # 暂停菜单
    SETTINGS,  # 设置菜单
}

enum OverlayContext {
    NONE,      # 无覆盖层
    PAUSE,     # 暂停覆盖层
    SETTINGS,  # 设置覆盖层
}
```

### 上下文切换 API

```gdscript
# 激活特定流程上下文
InputManager.activate_menu()          # 主菜单
InputManager.activate_map()           # 地图界面
InputManager.activate_combat()          # 战斗
InputManager.activate_shop()          # 商店
InputManager.activate_pause()         # 暂停（覆盖层）
InputManager.activate_settings()      # 设置（覆盖层）

# 炮台手动模式（战斗下的子状态）
InputManager.activate_turret_manual()   # 进入手动炮台控制
InputManager.deactivate_turret_manual() # 退出手动炮台控制

# 恢复流程上下文（关闭覆盖层后）
InputManager.restore_flow_context()
```

### 上下文实际映射

| 流程上下文 | 激活的 GUIDE 上下文 | 说明 |
|-----------|-------------------|------|
| MENU | 无 | 主菜单使用 Control 焦点系统 |
| MAP | `map` | 支持移动、地图平移、相机缩放 |
| COMBAT | `combat` (+ `turret_manual` 可选) | 基础战斗输入 |
| COMBAT + 手动炮台 | `combat` + `turret_manual` | 叠加手动瞄准 |
| SHOP | 无 | 商店使用按钮驱动 UI |
| 覆盖层（暂停/设置） | `overlay_back` | 仅返回操作可用 |

---

## 快速参考：本项目触发器类型

| 触发器 | 说明 | 本项目用法 |
|--------|------|-----------|
| `Pressed` | 按下时触发 | 跳跃、交互 |
| `Hold` | 按住持续触发 | 持续射击、维修 |
| `Released` | 释放时触发 | 停止动作 |
| `Chord` | 组合键触发 | 复杂快捷操作 |

---

## 快速参考：本项目修饰器

| 修饰器 | 说明 | 本项目用法 |
|--------|------|-----------|
| `DeadZone` | 设置死区阈值 | 所有轴输入（摇杆默认 0.2） |
| `Scale` | 缩放输入值 | 相机缩放灵敏度 |
| `SwizzleAxis` | 交换/重排轴 | 根据需要调整 |
| `Negate` | 反转输入值 | 反向控制 |

---

## 提示

1. **通过 InputManager 访问**：始终使用 `InputManager.xxx_action` 而不是直接 `preload()`
2. **使用 `GUIDE.is_action_pressed()`**：不要用 Godot 内置 `Input` 类检测 GUIDE 动作
3. **缓存输入向量**：在 `_physics_process` 中每帧获取输入向量，不要在 `_process` 中处理移动
4. **上下文自动管理**：调用 `InputManager.activate_xxx()` 后，GUIDE 上下文会自动切换
5. **叠加上下文**：`turret_manual` 是叠加在 `combat` 之上的，不是替代
6. **覆盖层优先级**：暂停/设置覆盖层会禁用所有玩法输入，仅保留 `ui_back`

---

## 故障排除

### 动作没有响应
- 检查当前激活的 `FlowContext` 是否正确
- 确认是否有覆盖层（PAUSE/SETTINGS）阻塞了输入
- 验证 `.tres` 资源文件在 `resources/input/actions/` 中正确配置

### 移动输入有延迟或漂移
- 检查 `move.tres` 的 DeadZone 修饰器设置
- 确认在 `_physics_process` 而非 `_process` 中处理移动

### 炮台手动模式不生效
- 确保先调用了 `InputManager.activate_combat()`
- 然后调用 `InputManager.activate_turret_manual()`
- 退出时调用 `InputManager.deactivate_turret_manual()` 而非直接切上下文
