# Operation Taklamakan 塔克拉玛干行动

> 基于 Godot 4.6 的俯视角陆行舰塔防 Roguelike 原型

[![Godot](https://img.shields.io/badge/Godot-4.6-478cbf?logo=godot-engine)](https://godotengine.org/)
[![GDScript](https://img.shields.io/badge/Language-GDScript-478cbf)](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/index.html)

## 目录

- [概述](#概述)
- [快速开始](#快速开始)
- [项目结构](#项目结构)
- [核心系统](#核心系统)
- [技术架构](#技术架构)
- [开发指南](#开发指南)
- [验证方法](#验证方法)
- [文档索引](#文档索引)
- [已知限制](#已知限制)
- [待优化项](#待优化项)

---

## 概述

玩家在固定的陆行舰上活动，通过移动、接管炮台、购买升级、承受并击退敌方波次，完成 3 层结构的路线推进流程。

### 核心玩法

- **地图推进**：3 层 Roguelike 结构，包含战斗、精英、商店、休整、Boss 节点
- **炮塔系统**：手动接管 / 自动火控、韧性瘫痪机制、三种炮塔类型
- **玩家行为**：WASD 移动、炮台交互、船体/炮台维修
- **商店系统**：固定升级商品 + 随机炮塔商品

### 技术特点

- 运行时场景驱动架构
- Autoload 单例 + 类型化 EventBus 信号协调
- GUIDE 输入系统（支持键鼠 / 手柄 / 触屏）
- Godot MCP 运行时验证支持

---

## 快速开始

### 环境要求

- **Godot 4.6+**（标准版，非 .NET 版）
- 操作系统：Windows / Linux / macOS

### 运行项目

```bash
# 克隆仓库
git clone <repository-url>
cd operation-taklamakan

# 使用 Godot 编辑器打开
godot4 --path .

# 或直接运行
godot4 --path . --editor
```

### 主入口

- **运行入口**：`project.godot` → `scenes/main.tscn`
- **产品基线**：`docs/what-expected-behavior.md`

---

## 项目结构

```
operation-taklamakan/
├── project.godot              # 项目配置、Autoload、碰撞层定义
├── AGENTS.md                  # 项目知识基线（开发者手册）
│
├── scripts/                   # GDScript 逻辑层
│   ├── main.gd               # 主流程编排
│   ├── game_state.gd         # 全局状态（货币、层数、升级）
│   ├── event_bus.gd          # 类型化跨系统信号
│   ├── wave_manager.gd       # 波次生成与完成逻辑
│   ├── map_manager.gd        # 地图状态与层推进
│   ├── floor_graph.gd        # 层图数据结构
│   ├── map_node.gd           # 地图节点数据类
│   ├── player.gd             # 玩家角色控制
│   ├── turret.gd             # 炮台控制（手动/自动/韧性）
│   ├── tank.gd               # 坦克敌人
│   ├── mechanical_dog.gd     # 机械狗敌人
│   ├── projectile.gd         # 我方投射物
│   ├── enemy_projectile.gd   # 敌方投射物
│   ├── health_component.gd   # 血量组件
│   ├── toughness_component.gd# 韧性组件
│   ├── damage_data.gd        # 伤害数据结构
│   ├── shop_screen.gd        # 商店界面
│   ├── shop_item.gd          # 商店商品数据
│   ├── input_manager.gd      # GUIDE 输入包装层
│   ├── settings_manager.gd   # 设置持久化
│   ├── localization.gd       # 本地化支持
│   │
│   ├── ship/
│   │   └── landship.gd       # 陆行舰主控脚本
│   │
│   ├── ui/
│   │   ├── hud.gd            # 战斗 HUD
│   │   ├── map_screen.gd     # 地图选择界面
│   │   ├── map_node_ui.gd    # 地图节点 UI 组件
│   │   ├── wave_ui.gd        # 波次/波间期 UI
│   │   ├── game_over.gd      # 失败界面
│   │   ├── victory_screen.gd # 胜利界面
│   │   ├── main_menu.gd      # 主菜单
│   │   ├── pause_menu.gd     # 暂停菜单
│   │   ├── settings_menu.gd  # 设置菜单
│   │   ├── turret_ui.gd      # 炮塔信息展示
│   │   └── encounter_overlay.gd
│   │
│   └── resources/
│       ├── wave_data.gd      # 波次数据类
│       ├── wave_set.gd       # 波次集合
│       ├── turret_definition.gd    # 炮塔定义
│       └── turret_palette.gd # 炮塔调色板
│
├── scenes/                    # Godot 场景文件
│   ├── main.tscn             # 根运行时场景
│   ├── projectile.tscn       # 我方投射物预制体
│   │
│   ├── ship/
│   │   ├── landship.tscn     # 陆行舰（含炮位）
│   │   └── player_character.tscn
│   │
│   ├── turret/
│   │   └── turret.tscn       # 炮台预制体
│   │
│   ├── enemy/
│   │   ├── tank.tscn         # 坦克
│   │   ├── mechanical_dog.tscn
│   │   ├── boss_tank.tscn    # Boss
│   │   └── enemy_projectile.tscn
│   │
│   ├── ui/
│   │   ├── hud.tscn
│   │   ├── map_screen.tscn
│   │   ├── wave_ui.tscn
│   │   ├── game_over.tscn
│   │   ├── victory_screen.tscn
│   │   ├── main_menu.tscn
│   │   ├── pause_menu.tscn
│   │   ├── settings_menu.tscn
│   │   ├── turret_ui.tscn
│   │   ├── toughness_bar.tscn
│   │   └── encounter_overlay.tscn
│   │
│   └── map/
│       └── shop_screen.tscn  # 商店场景
│
├── resources/                 # .tres 数据资源
│   ├── waves/
│   │   ├── wave_data.tres    # 波次集合
│   │   ├── wave_01.tres      # 第 1 波
│   │   ├── wave_02.tres
│   │   ├── wave_03.tres
│   │   ├── wave_04.tres
│   │   └── wave_05.tres
│   │
│   ├── turret/
│   │   ├── standard_turret.tres
│   │   ├── rapid_turret.tres
│   │   ├── sniper_turret.tres
│   │   └── turret_palette.tres
│   │
│   ├── enemies/
│   │   └── tank_data.tres
│   │
│   ├── shapes/
│   │   └── player_circle.tres
│   │
│   └── input/
│       ├── actions/          # GUIDE 输入动作
│       │   ├── move.tres
│       │   ├── fire.tres
│       │   ├── interact.tres
│       │   ├── repair.tres
│       │   ├── pause_toggle.tres
│       │   ├── ui_back.tres
│       │   ├── map_pan_hold.tres
│       │   ├── map_pan_delta.tres
│       │   └── input_hints_toggle.tres
│       │
│       └── contexts/         # GUIDE 输入上下文
│           ├── combat.tres
│           ├── map.tres
│           ├── turret_manual.tres
│           └── overlay_back.tres
│
├── addons/                    # 插件
│   ├── guide/                # GUIDE 输入系统
│   │   └── plugin.cfg
│   │
│   └── godot_mcp/            # Godot MCP 运行时控制
│       ├── plugin.cfg
│       ├── mcp_interaction_server.gd
│       ├── godot_operations.gd
│       ├── mcp_editor_plugin.gd
│       ├── AGENTS.md
│       └── README.md
│
├── config/
│   └── mcp_server.json       # MCP 服务配置
│
└── docs/                      # 文档
    ├── what-expected-behavior.md  # 产品行为基线
    ├── collision-layers.md        # 碰撞层规范
    ├── guide-integration.md       # GUIDE 接入说明
    └── gut-integration.md         # GUT 测试框架（预留）
```

---

## 核心系统

### Autoload 单例

| 单例名 | 脚本路径 | 职责 |
|--------|----------|------|
| `GUIDE` | `addons/guide/guide.gd` | 输入系统核心 |
| `InputManager` | `scripts/input_manager.gd` | 输入包装层 |
| `Localization` | `scripts/localization.gd` | 多语言支持 |
| `SettingsManager` | `scripts/settings_manager.gd` | 设置持久化 |
| `MapManager` | `scripts/map_manager.gd` | 地图状态管理 |
| `EventBus` | `scripts/event_bus.gd` | 类型化信号中心 |
| `GameState` | `scripts/game_state.gd` | 全局游戏状态 |
| `WaveManager` | `scripts/wave_manager.gd` | 波次流程控制 |
| `McpInteractionServer` | `addons/godot_mcp/mcp_interaction_server.gd` | MCP 运行时服务 |

### 碰撞层

| 层号 | 名称 | 对象类型 | 检测目标 |
|------|------|----------|----------|
| 1 | `ship` | 陆行舰 | `enemy`, `enemy_projectile` |
| 2 | `turret` | 炮塔本体 | `enemy`, `enemy_projectile` |
| 3 | `enemy` | 敌方单位 | `ship`, `turret`, `player` |
| 4 | `player_projectile` | 我方投射物 | `enemy` |
| 5 | `enemy_projectile` | 敌方投射物 | `ship`, `turret`, `player` |
| 6 | `player` | 玩家角色 | `enemy`, `enemy_projectile` |

> 详细规范见 `docs/collision-layers.md`

### 节点组

- `"ship"` - 陆行舰发现点
- `"enemies"` - 敌人发现点

---

## 技术架构

### 运行时流程

```
启动 → main.tscn
  │
  ├── 主菜单 (main_menu.tscn)
  │     │
  │     └── 新游戏/继续 → GameState.reset() / GameState.load()
  │
  ├── 地图流程 (map_screen.tscn)
  │     │
  │     ├── 选择战斗节点 → 进入战斗
  │     ├── 选择商店节点 → shop_screen.tscn
  │     └── 选择休整节点 → 修理船体
  │
  └── 战斗流程
        │
        ├── WaveManager 启动波次
        ├── 敌人生成 → 炮塔防御
        ├── 船体受伤 → EventBus.ship_damaged
        ├── 波间期 (wave_ui.tscn)
        └── 战斗完成 → 返回地图 或 胜利/失败
```

### 信号流

```
EventBus (类型化信号中心)
  │
  ├── ship_damaged(damage: int)
  ├── ship_repaired(amount: int)
  ├── ship_destroyed()
  ├── wave_started(wave_number: int)
  ├── wave_completed()
  ├── combat_ended()
  ├── map_node_selected(node: MapNode)
  ├── floor_completed()
  ├── game_victory()
  └── game_over()
```

---

## 开发指南

### 编码约定

- **文件命名**：`snake_case.gd` / `snake_case.tscn` / `snake_case.tres`
- **类命名**：`PascalCase`
- **组件后缀**：`*Component`（如 `HealthComponent`、`ToughnessComponent`）
- **UI 辅助类后缀**：`*UI`（如 `MapNodeUI`）
- **私有字段**：前导下划线（如 `_can_fire`、`_repair_timer`）
- **信号**：优先类型化，跨系统通信用信号流而非轮询
- **代码注释**：使用中文

### 关键模式

1. **信号驱动架构**：`EventBus` 作为跨系统通信中心
2. **组件化设计**：`HealthComponent`、`ToughnessComponent` 可复用
3. **资源类分离**：`.gd` 定义类型，`.tres` 存储数据
4. **输入系统包装**：通过 `InputManager` 调用 GUIDE，不直接访问 InputMap

### 反模式（避免）

- 不要把 `turret_ui.gd` 当作升级流程的权威来源
- 不要硬编码波次/层数映射
- 不要在更多地方硬编码父相对 UI 节点查找
- 不要假设 `WaveSet.get_wave()` 是零基数（它是 1 基数）
- 不要在 EventBus 或 GameState 已有职责时添加隐藏全局耦合

---

## 验证方法

### 当前状态

- ✅ 有可运行的原型主流程
- ❌ 没有传统自动化测试框架
- ✅ 验证主要依赖 Godot MCP / 人工清单

### 人工验证优先级

详见 `docs/what-expected-behavior.md` 第十二节，简要如下：

**P0（阻塞级）**
1. 项目能否成功启动
2. 地图 → 战斗 → 地图主循环是否打通
3. 船体受伤与失败是否正确
4. 最终胜利是否正确触发
5. 炮台手动模式是否可进入且可开火

**P1（核心玩法级）**
1. 自动火控升级是否能解锁并生效
2. 炮台韧性/瘫痪/修理链路是否完整
3. 波间期 UI 是否可用
4. 商店购买结果是否真实落地
5. 休整节点是否能正确回血

### Godot MCP 验证

```bash
# 项目内置 MCP 服务，端口 127.0.0.1:9090
# 可通过 MCP 客户端进行运行时验证
```

---

## 文档索引

| 文档 | 用途 |
|------|------|
| `AGENTS.md` | 项目知识基线，开发者手册 |
| `docs/what-expected-behavior.md` | 产品行为归档基线 |
| `docs/collision-layers.md` | 碰撞层规范与扩层流程 |
| `docs/guide-integration.md` | GUIDE 输入系统接入说明 |
| `docs/gut-integration.md` | GUT 测试框架（预留） |
| `scripts/README.md` | 脚本目录说明 |
| `scripts/AGENTS.md` | 脚本详细约定与风险热点 |
| `scenes/README.md` | 场景目录说明 |
| `scenes/AGENTS.md` | 场景装配约定与风险热点 |
| `addons/godot_mcp/README.md` | MCP 插件说明 |

---

## 已知限制

- 无传统单元测试框架
- 无 CI/CD 流水线
- 无导出预设与打包测试
- 波次/层数映射存在硬编码
- `wave_manager.gd` 结构较脆弱
- 存档/读档功能未实现

---

## 待优化项

### 代码质量

- [ ] 提取波次/层数映射为配置资源
- [ ] 重构 `wave_manager.gd`，降低硬编码依赖
- [ ] 统一 UI 节点查找模式，减少父相对依赖
- [ ] 添加单元测试框架（GUT 或 gdUnit4）

### 架构改进

- [ ] 引入状态机管理游戏流程状态
- [ ] 解耦 `main.gd` 的中心流程粘合
- [ ] 将商店升级逻辑从 `shop_screen.gd` 提取为独立系统
- [ ] 考虑引入依赖注入模式减少单例耦合

### 功能完善

- [ ] 实现存档/读档功能
- [ ] 添加更多敌人类型和 Boss 行为模式
- [ ] 完善炮塔升级树
- [ ] 添加局外永久成长系统
- [ ] 完善音频反馈系统

### 工程化

- [ ] 添加 CI/CD 流水线
- [ ] 配置导出预设
- [ ] 添加性能监控和调试工具
- [ ] 完善错误处理和边界情况

---

## 贡献

个人项目，按高技术标准执行。对潜在问题零妥协，必要时敢于推倒重构。

---

## 许可证

本项目采用双重许可策略：

- **源代码** — [MIT License](LICENSE_CODE)
- **艺术资产** — [CC-BY 4.0](LICENSE_ASSETS)

详见 [LICENSE](LICENSE)
