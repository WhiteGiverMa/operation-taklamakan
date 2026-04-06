# 解放军演习陆行舰塔防 Roguelike MVP

## TL;DR

> **Quick Summary**: 开发一个俯视角塔防 Roguelike MVP，玩家在陆行舰上布置和操控炮台，抵御坦克和机械狗的攻击。核心玩法验证：手动/自动炮台切换 + 炮台韧性系统 + Roguelike 路线选择。
>
> **Deliverables**:
> - 可玩的 MVP 原型（15-20 分钟完整游戏循环）
> - 陆行舰 + 角色移动系统
> - 炮台系统（布置、升级、火控、韧性）
> - 波次战斗系统（3-5 波）
> - 地图路线选择（《杀戮尖塔》式，3 层）
> - 基础敌人 AI（坦克、机械狗占位符）
>
> **Estimated Effort**: Medium (8-9 days)
> **Parallel Execution**: YES - 4 waves
> **Critical Path**: Godot 项目初始化 → 陆行舰场景 → 炮台系统 → 波次战斗 → 地图系统

---

## Context

### Original Request
用户希望做一个类似《同舟共济》的俯视角开船 Roguelike，但更休闲，玩家不需要手忙脚乱开船，而是布置自动化火炮抵御敌人。技术栈选择 Godot 4.6.1 + GDScript 主 / C# 辅。世界观设定为中国现代解放军演习，敌人是坦克、机械狗等军事装备。

### Interview Summary
**Key Discussions**:
- **技术栈**: Godot 4.6.1，GDScript 为主，C# 为辅
- **核心玩法**: 布置炮台 + 角色操控，炮台可手动或自动开火
- **炮台系统**: 单一类型 + 升级，火控系统是升级项，炮台有韧性系统（自动恢复，保护船体）
- **船只系统**: 8-10 炮位，简单矩形，有生命值，需角色修理
- **地图系统**: 3 层，《杀戮尖塔》式路线选择，6 种节点类型
- **敌人系统**: 坦克、机械狗占位符，固定生成点
- **项目范围**: MVP，验证核心玩法

**Research Findings**:
- 参考《杀戮尖塔》的路线选择和地图生成算法
- 参考《同舟共济》的角色操控和击飞机制
- Godot 4.6.1 适合 2D 开发，GDScript 原型效率高
- 炮台韧性系统是创新点，需要重点验证

### Metis Review
**Identified Gaps** (addressed):
- **炮台射界**: 确认为 360° 自由旋转
- **敌人生成**: 确认为固定生成点
- **修理机制**: 确认为读条修理（需时间）
- **自动瞄准**: 确认为优先攻击最近敌人
- **核心风险**: 手动炮台操作可能不够有趣，需要优先验证

**Guardrails Applied**:
- MVP 锁定：只有 1 种炮台类型，无藏品系统，无角色成长
- 无局外解锁，无多人，无保存/退出
- 先验证核心玩法，再做美术资源

---

## Work Objectives

### Core Objective
在 8-9 天内开发一个可玩的 MVP 原型，验证"手动/自动炮台切换 + 炮台韧性系统"的核心玩法是否有趣。

### Concrete Deliverables
- Godot 4.6.1 项目，可运行于 Windows PC
- 陆行舰场景（白色矩形，8-10 炮位）
- 角色移动系统（WASD，局部坐标）
- 炮台系统（布置、升级、火控、韧性、瘫痪/维修）
- 敌人 AI（坦克、机械狗占位符，固定生成点）
- 波次战斗系统（3-5 波，间隙可修理）
- 地图路线选择（3 层，6 种节点）
- 商店系统（3-5 固定物品）
- 船体生命值 + 修理机制
- 死亡/重置流程

### Definition of Done
- [ ] 玩家可以完成一次完整的 3 层游戏循环（15-20 分钟）
- [ ] 炮台可以手动操作（鼠标瞄准 + 点击射击）
- [ ] 炮台可以自动开火（升级火控后，优先攻击最近敌人）
- [ ] 炮台韧性系统工作正常（自动恢复，超过韧性则瘫痪）
- [ ] 角色可以修理船体和瘫痪的炮台（读条 2 秒）
- [ ] 敌人从固定生成点出现，攻击船体
- [ ] 地图路线选择工作正常（《杀戮尖塔》式）
- [ ] 死亡后完全重置

### Must Have
- 陆行舰 + 角色移动
- 炮台系统（布置、升级、火控、韧性）
- 敌人 AI（坦克、机械狗占位符）
- 波次战斗系统
- 地图路线选择
- 资源系统（单一货币）
- 船体生命值 + 修理机制

### Must NOT Have (Guardrails)
- ❌ 多种炮台类型（MVP = 1 种）
- ❌ 藏品/遗物系统（UI 占位符）
- ❌ 角色成长/技能系统（等级显示占位符）
- ❌ 局外解锁/元进度
- ❌ 中途保存/退出
- ❌ 天气/环境效果（占位符）
- ❌ 教程系统
- ❌ Steam 成就/集成
- ❌ 本地化
- ❌ 多人/联网
- ❌ 自定义编辑器/工具
- ❌ 语音、复杂音效
- ❌ ECS 架构（使用简单节点系统）
- ❌ 基础投射物之外的粒子效果
- ❌ 多种船只类型
- ❌ 程序化地图生成（手写 3 层）

---

## Verification Strategy (MANDATORY)

> **ZERO HUMAN INTERVENTION** - ALL verification is agent-executed. No exceptions.
> Acceptance criteria requiring "user manually tests/confirms" are FORBIDDEN.

### Test Decision
- **Infrastructure exists**: NO（Godot 项目，需要创建测试框架）
- **Automated tests**: NO（MVP 阶段，使用 Agent-Executed QA）
- **Framework**: N/A
- **QA Policy**: Agent-Executed QA Scenarios（使用 godot-mcp 工具）

### QA Policy
Every task MUST include agent-executed QA scenarios (see TODO template below).
Evidence saved to `.sisyphus/evidence/task-{N}-{scenario-slug}.{ext}`.

- **Frontend/UI**: Use Playwright (playwright skill) - Navigate, interact, assert DOM, screenshot
- **Godot Game**: Use godot-mcp tools - Run project, spawn nodes, set properties, call methods, assert state
- **API/Backend**: Use Bash (curl) - Send requests, assert status + response fields
- **Library/Module**: Use Bash (bun/node REPL) - Import, call functions, compare output

---

## Execution Strategy

### Parallel Execution Waves

> Maximize throughput by grouping independent tasks into parallel waves.
> Each wave completes before the next begins.
> Target: 5-8 tasks per wave. Fewer than 3 per wave (except final) = under-splitting.

```
Wave 1 (Start Immediately - 项目初始化 + 基础架构):
├── Task 1: Godot 项目初始化 + autoloads [quick]
├── Task 2: DamageData + HealthComponent 类 [quick]
├── Task 3: EventBus 信号架构 [quick]
└── Task 4: 项目目录结构 + 配置文件 [quick]

Wave 2 (After Wave 1 - 核心场景 + 移动):
├── Task 5: 陆行舰场景（白色矩形，8-10 炮位）[quick]
├── Task 6: 角色移动系统（WASD，局部坐标）[quick]
├── Task 7: 炮台场景（基础版，手动开火）[quick]
└── Task 8: 敌人场景（坦克占位符）[quick]

Wave 3 (After Wave 2 - 战斗系统):
├── Task 9: 炮台自动瞄准 + 开火 [unspecified-high]
├── Task 10: 炮台韧性系统 [deep]
├── Task 11: 敌人 AI（寻路 + 攻击）[unspecified-high]
├── Task 12: 波次战斗系统（WaveManager）[unspecified-high]
└── Task 13: 船体生命值 + 修理机制 [quick]

Wave 4 (After Wave 3 - 地图 + 进程):
├── Task 14: 地图生成系统（《杀戮尖塔》式）[deep]
├── Task 15: 地图 UI（节点选择）[visual-engineering]
├── Task 16: 商店系统（3-5 固定物品）[quick]
├── Task 17: 死亡/重置流程 [quick]
└── Task 18: 整合 + 平衡 [deep]

Critical Path: Task 1 → Task 5 → Task 7 → Task 9 → Task 12 → Task 14 → Task 18
Parallel Speedup: ~60% faster than sequential
Max Concurrent: 5 (Wave 3)
```

### Dependency Matrix (abbreviated)

- **1-4**: - - 5-18, all depend on project init
- **5**: 1 - 6-8, 10, 13, ship is foundation
- **6**: 1, 5 - 7-8, character needed for manual control
- **7**: 1, 5 - 9-10, turret foundation
- **8**: 1 - 11-12, enemy foundation
- **9**: 7 - 10, 12, auto-fire depends on turret
- **10**: 5, 7 - 12, toughness system
- **11**: 8 - 12, enemy AI
- **12**: 8, 11 - 14, 17, wave system
- **13**: 5 - 14, 17, ship HP
- **14**: 1 - 15-16, map generation
- **15**: 14 - 16, 17, map UI
- **16**: 14 - 17, shop
- **17**: 5, 12, 13 - 18, death flow
- **18**: ALL - -, final integration

> This is abbreviated for reference. YOUR generated plan must include the FULL matrix for ALL tasks.

### Agent Dispatch Summary

- **Wave 1**: **4** - T1-T4 → `quick`
- **Wave 2**: **4** - T5-T8 → `quick`
- **Wave 3**: **5** - T9, T11-T12 → `unspecified-high`, T10 → `deep`, T13 → `quick`
- **Wave 4**: **5** - T14 → `deep`, T15 → `visual-engineering`, T16-T17 → `quick`, T18 → `deep`

---

## TODOs

> Implementation + Test = ONE Task. Never separate.
> EVERY task MUST have: Recommended Agent Profile + Parallelization info + QA Scenarios.
> **A task WITHOUT QA Scenarios is INCOMPLETE. No exceptions.**

### Wave 1: 项目初始化 + 基础架构

- [x] 1. Godot 项目初始化 + autoloads

  **What to do**:
  - 使用 `godot-mcp_create_project` 创建 Godot 4.6.1 项目
  - 创建 autoload 单例：`GameState.gd`（游戏状态管理）、`WaveManager.gd`（波次管理）、`EventBus.gd`（信号总线）
  - 配置 `project.godot` 文件（autoload 注册、窗口大小 1920x1080）
  - 创建基础目录结构：`scenes/`, `scripts/`, `resources/`, `assets/`

  **Must NOT do**:
  - 不要创建 ECS 架构（使用简单节点系统）
  - 不要添加自定义编辑器/工具
  - 不要配置 Steam 集成

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 标准项目初始化任务，步骤清晰
  - **Skills**: []
    - Godot MCP 工具已内置必要功能

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 2-4)
  - **Parallel Group**: Wave 1 (with Tasks 2, 3, 4)
  - **Blocks**: Tasks 5-18 (all depend on project init)
  - **Blocked By**: None (can start immediately)

  **References**:
  - **Pattern References**: None (greenfield project)
  - **External References**: Godot 4.6.1 docs - Project structure best practices
  - **WHY**: 项目初始化是所有后续任务的基础

  **Acceptance Criteria**:
  - [ ] Godot 项目文件存在：`project.godot`
  - [ ] autoloads 已注册：`GameState`, `WaveManager`, `EventBus`
  - [ ] 目录结构创建完成：`scenes/`, `scripts/`, `resources/`, `assets/`

  **QA Scenarios**:
  ```
  Scenario: Godot 项目可运行
    Tool: godot-mcp_run_project
    Steps:
      1. Run project with godot-mcp_run_project
      2. godot-mcp_game_wait(frames=10)
      3. Check for errors: godot-mcp_get_debug_output()
    Expected Result: No errors, project runs successfully
    Evidence: .sisyphus/evidence/task-01-project-runs.log
  ```

  **Commit**: YES (isolated commit)
  - Message: `feat: initialize Godot project with autoloads`
  - Files: `project.godot`, `scripts/game_state.gd`, `scripts/wave_manager.gd`, `scripts/event_bus.gd`

- [x] 2. DamageData + HealthComponent 类

  **What to do**:
  - 创建 `DamageData` 类（RefCounted，包含伤害值、伤害类型、来源）
  - 创建 `HealthComponent` 节点（包含当前血量、最大血量、受伤、死亡信号）
  - 实现伤害计算逻辑（考虑防御、暴击等占位符）
  - 编写单元测试验证伤害计算

  **Must NOT do**:
  - 不要过度设计（MVP 只需基础伤害/血量）
  - 不要添加复杂的 Buff/Debuff 系统

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 标准组件实现，逻辑清晰
  - **Skills**: [`godot-combat-system`]
    - `godot-combat-system`: 提供伤害/血量系统的标准模式

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 1, 3, 4)
  - **Parallel Group**: Wave 1
  - **Blocks**: Tasks 5, 10, 13 (depend on HealthComponent)
  - **Blocked By**: None

  **References**:
  - **Pattern References**: `godot-combat-system` skill - DamageData class pattern
  - **External References**: Godot docs - RefCounted for data classes
  - **WHY**: 伤害/血量是战斗系统的基础，需要先实现

  **Acceptance Criteria**:
  - [ ] `DamageData` 类存在：`scripts/damage_data.gd`
  - [ ] `HealthComponent` 节点存在：`scripts/health_component.gd`
  - [ ] HealthComponent 信号：`health_changed`, `died`
  - [ ] 单元测试通过（基础伤害计算）

  **QA Scenarios**:
  ```
  Scenario: HealthComponent 受伤后血量减少
    Tool: godot-mcp_game_eval
    Steps:
      1. Create test node with HealthComponent
      2. Set max_health = 100
      3. Call take_damage(DamageData.new(30))
      4. Assert current_health == 70
    Expected Result: Health correctly reduced
    Evidence: .sisyphus/evidence/task-02-health-component.log
  ```

  **Commit**: YES
  - Message: `feat: add DamageData and HealthComponent classes`
  - Files: `scripts/damage_data.gd`, `scripts/health_component.gd`

- [x] 3. EventBus 信号架构

  **What to do**:
  - 创建 `EventBus.gd` autoload（全局信号总线）
  - 定义核心信号：`enemy_spawned`, `enemy_died`, `wave_started`, `wave_complete`, `ship_damaged`
  - 实现信号的类型安全连接/断开
  - 编写测试验证信号传递

  **Must NOT do**:
  - 不要创建过于复杂的信号系统
  - 不要使用字符串信号名（使用 Signal 类型）

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 标准 Godot 信号架构实现
  - **Skills**: [`godot-signal-architecture`]
    - `godot-signal-architecture`: 提供"Signal Up, Call Down"模式

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 1, 2, 4)
  - **Parallel Group**: Wave 1
  - **Blocks**: Tasks 5-18 (many systems use EventBus)
  - **Blocked By**: None

  **References**:
  - **Pattern References**: `godot-signal-architecture` skill - Signal bus pattern
  - **WHY**: 全局信号总线用于解耦系统（WaveManager、Enemy、Ship 等）

  **Acceptance Criteria**:
  - [ ] EventBus autoload 存在
  - [ ] 核心信号定义完成
  - [ ] 信号连接/断开类型安全

  **QA Scenarios**:
  ```
  Scenario: EventBus 信号正确传递
    Tool: godot-mcp_game_eval
    Steps:
      1. Connect to EventBus.enemy_died signal
      2. Emit signal with enemy data
      3. Assert callback received correct data
    Expected Result: Signal correctly transmitted
    Evidence: .sisyphus/evidence/task-03-event-bus.log
  ```

  **Commit**: YES
  - Message: `feat: create EventBus signal architecture`
  - Files: `scripts/event_bus.gd`

- [x] 4. 项目目录结构 + 配置文件

  **What to do**:
  - 创建目录：`scenes/ship/`, `scenes/turret/`, `scenes/enemy/`, `scenes/map/`, `scenes/ui/`
  - 创建资源目录：`resources/waves/`, `resources/enemies/`, `resources/turrets/`
  - 创建占位符资源文件：默认波次配置、默认敌人配置、默认炮台配置
  - 添加 `.gitignore` 文件

  **Must NOT do**:
  - 不要创建过多占位符资源（只创建必要的）
  - 不要添加美术资源（使用几何占位符）

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 标准项目结构设置
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 1-3)
  - **Parallel Group**: Wave 1
  - **Blocks**: Tasks 5-18 (depend on directory structure)
  - **Blocked By**: None

  **References**:
  - **Pattern References**: None
  - **WHY**: 清晰的目录结构有助于项目管理

  **Acceptance Criteria**:
  - [ ] 所有目录创建完成
  - [ ] 占位符资源文件存在：`resources/waves/default_wave.tres`
  - [ ] `.gitignore` 文件存在

  **QA Scenarios**:
  ```
  Scenario: 目录结构正确
    Tool: Bash (ls)
    Steps:
      1. List project directories
      2. Assert all expected directories exist
    Expected Result: All directories present
    Evidence: .sisyphus/evidence/task-04-directory-structure.log
  ```

  **Commit**: YES
  - Message: `feat: setup project directory structure`
  - Files: `.gitignore`, resource files

---

### Wave 2: 核心场景 + 移动

- [x] 5. 陆行舰场景（白色矩形，8-10 炮位）

  **What to do**:
  - 创建 `Landship` 场景（StaticBody2D 或 CharacterBody2D）
  - 实现白色矩形船体（Sprite2D + CollisionShape2D）
  - 创建 8-10 个炮位节点（TurretSlot，位置固定）
  - 炮位分布在船体四周（均匀分布）
  - 添加 HealthComponent 到船体
  - 创建船体血量 UI（HUD）

  **Must NOT do**:
  - 不要创建复杂形状的船体（保持简单矩形）
  - 不要实现船体移动（阶段式移动，战斗时固定）

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 基础场景创建，结构清晰
  - **Skills**: [`godot-2d-physics`]
    - `godot-2d-physics`: 碰撞层/碰撞掩码设置

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 6-8)
  - **Parallel Group**: Wave 2
  - **Blocks**: Tasks 6-8, 10, 13, 17 (depend on ship scene)
  - **Blocked By**: Tasks 1, 2, 4

  **References**:
  - **Pattern References**: Metis analysis - Scene hierarchy
  - **API References**: `HealthComponent` from Task 2
  - **WHY**: 船体是所有战斗系统的基础

  **Acceptance Criteria**:
  - [ ] `Landship.tscn` 场景存在
  - [ ] 船体显示为白色矩形
  - [ ] 8-10 个炮位节点存在（TurretSlot）
  - [ ] HealthComponent 附加到船体
  - [ ] 血量 UI 显示在屏幕左上角

  **QA Scenarios**:
  ```
  Scenario: 陆行舰正确渲染
    Tool: godot-mcp_run_project
    Steps:
      1. Run project with Landship as main scene
      2. Screenshot game window
      3. Assert ship sprite visible
      4. Assert 8-10 turret slots visible
    Expected Result: Ship renders correctly
    Evidence: .sisyphus/evidence/task-05-ship-renders.png

  Scenario: 船体受伤后血量 UI 更新
    Tool: godot-mcp_game_eval
    Steps:
      1. Set ship health to 100
      2. Call take_damage(30)
      3. Check UI displays 70/100
    Expected Result: UI correctly shows 70/100
    Evidence: .sisyphus/evidence/task-05-ship-health-ui.png
  ```

  **Commit**: YES
  - Message: `feat: create Landship scene with turret slots`
  - Files: `scenes/ship/landship.tscn`, `scripts/ship.gd`, `scenes/ui/hud.tscn`

- [x] 6. 角色移动系统（WASD，局部坐标）

  **What to do**:
  - 创建 `PlayerCharacter` 场景（CharacterBody2D）
  - 实现 WASD 移动（使用 `move_and_slide()`）
  - 角色作为船体的子节点（局部坐标移动）
  - 实现碰撞边界（角色不能离开船体范围）
  - 添加角色视觉（简单几何形状占位符）

  **Must NOT do**:
  - 不要实现角色血量（角色无血量）
  - 不要实现角色技能系统（MVP 无技能）
  - 不要让角色离开船体范围

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 标准角色移动实现
  - **Skills**: [`godot-characterbody-2d`]
    - `godot-characterbody-2d`: 提供角色移动模式

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 5, 7, 8)
  - **Parallel Group**: Wave 2
  - **Blocks**: Tasks 7, 8, 13, 17 (character needed for interaction)
  - **Blocked By**: Tasks 1, 5

  **References**:
  - **Pattern References**: `godot-characterbody-2d` skill - Top-down movement
  - **API References**: Metis analysis - Player as child of ship
  - **WHY**: 角色移动是手动操作炮台的基础

  **Acceptance Criteria**:
  - [ ] `PlayerCharacter.tscn` 场景存在
  - [ ] WASD 移动工作正常（局部坐标）
  - [ ] 角色不能离开船体边界
  - [ ] 角色作为船体子节点

  **QA Scenarios**:
  ```
  Scenario: 角色WASD移动正常
    Tool: godot-mcp_run_project
    Steps:
      1. Get character initial position
      2. godot-mcp_game_key_hold(key="W")
      3. godot-mcp_game_wait(frames=30)
      4. Get character new position
      5. Assert position.y decreased (moved up)
    Expected Result: Character moves up when W pressed
    Evidence: .sisyphus/evidence/task-06-character-movement.log

  Scenario: 角色不能离开船体
    Tool: godot-mcp_game_eval
    Steps:
      1. Hold W for 100 frames
      2. Check character position still within ship bounds
    Expected Result: Character constrained to ship
    Evidence: .sisyphus/evidence/task-06-character-bounds.log
  ```

  **Commit**: YES
  - Message: `feat: implement character WASD movement on ship`
  - Files: `scenes/ship/player_character.tscn`, `scripts/player.gd`

- [x] 7. 炮台场景（基础版，手动开火）

  **What to do**:
  - 创建 `Turret` 场景（Node2D）
  - 实现炮台基座和炮管（Sprite2D 占位符）
  - 实现手动开火：角色靠近 → 点击炮台 → 进入手动模式 → 鼠标瞄准 + 点击射击
  - 实现投射物（Projectile，Area2D）
  - 360° 自由旋转（跟随鼠标）
  - 添加 ToughnessComponent（韧性系统占位符）

  **Must NOT do**:
  - 不要实现自动开火（Wave 3 任务）
  - 不要添加多种炮台类型（MVP = 1 种）

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 基础炮台场景实现
  - **Skills**: [`godot-combat-system`, `godot-2d-physics`]
    - `godot-combat-system`: 投射物模式
    - `godot-2d-physics`: 碰撞检测

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 5, 6, 8)
  - **Parallel Group**: Wave 2
  - **Blocks**: Tasks 9, 10, 12, 16 (turret foundation)
  - **Blocked By**: Tasks 1, 2, 5

  **References**:
  - **Pattern References**: `godot-combat-system` skill - Hitbox/Hurtbox
  - **API References**: `ToughnessComponent` (to be created in Task 10)
  - **WHY**: 炮台是战斗系统的核心

  **Acceptance Criteria**:
  - [ ] `Turret.tscn` 场景存在
  - [ ] 炮台可 360° 旋转
  - [ ] 手动开火工作正常（角色靠近 + 点击进入 + 鼠标瞄准 + 点击射击）
  - [ ] 投射物正确飞行和碰撞

  **QA Scenarios**:
  ```
  Scenario: 炮台手动开火
    Tool: godot-mcp_run_project
    Steps:
      1. Move character near turret
      2. Click on turret to enter manual mode
      3. Move mouse to aim
      4. Click to fire
      5. Assert projectile spawned
    Expected Result: Projectile fires toward mouse position
    Evidence: .sisyphus/evidence/task-07-turret-manual-fire.png

  Scenario: 炮台360度旋转
    Tool: godot-mcp_game_eval
    Steps:
      1. Enter manual mode
      2. Move mouse to all 4 quadrants
      3. Assert barrel rotates correctly
    Expected Result: Turret rotates 360 degrees
    Evidence: .sisyphus/evidence/task-07-turret-rotation.log
  ```

  **Commit**: YES
  - Message: `feat: add basic turret scene with manual fire control`
  - Files: `scenes/turret/turret.tscn`, `scripts/turret.gd`, `scenes/projectile.tscn`

- [x] 8. 敌人场景（坦克占位符）

  **What to do**:
  - 创建 `Tank` 场景（CharacterBody2D 或 StaticBody2D）
  - 实现简单几何形状占位符（绿色矩形）
  - 实现基础移动（向船体移动）
  - 添加 HealthComponent
  - 实现基础攻击（近战冲撞或远程射击占位符）
  - 创建敌人数据资源（`TankData.tres`）

  **Must NOT do**:
  - 不要实现复杂 AI（Wave 3 任务）
  - 不要添加多种敌人类型（先实现坦克）

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 基础敌人场景创建
  - **Skills**: [`godot-characterbody-2d`, `godot-combat-system`]
    - `godot-characterbody-2d`: 敌人移动
    - `godot-combat-system`: 敌人攻击

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 5-7)
  - **Parallel Group**: Wave 2
  - **Blocks**: Tasks 11, 12 (enemy foundation)
  - **Blocked By**: Tasks 1, 2

  **References**:
  - **Pattern References**: `godot-characterbody-2d` skill - Top-down enemy movement
  - **API References**: `HealthComponent` from Task 2
  - **WHY**: 敌人是战斗系统的目标

  **Acceptance Criteria**:
  - [ ] `Tank.tscn` 场景存在
  - [ ] 敌人显示为绿色矩形占位符
  - [ ] 敌人向船体移动
  - [ ] HealthComponent 附加到敌人

  **QA Scenarios**:
  ```
  Scenario: 敌人正确生成和移动
    Tool: godot-mcp_game_spawn_node
    Steps:
      1. Spawn Tank at world position (500, 0)
      2. Wait 60 frames
      3. Check enemy position moved toward ship
    Expected Result: Enemy moves toward ship
    Evidence: .sisyphus/evidence/task-08-enemy-movement.log

  Scenario: 敌人可被击杀
    Tool: godot-mcp_game_eval
    Steps:
      1. Spawn Tank
      2. Call take_damage(9999)
      3. Assert enemy emits died signal
    Expected Result: Enemy dies when health reaches 0
    Evidence: .sisyphus/evidence/task-08-enemy-death.log
  ```

  **Commit**: YES
  - Message: `feat: create Tank enemy placeholder`
  - Files: `scenes/enemy/tank.tscn`, `scripts/tank.gd`, `resources/enemies/tank_data.tres`

---

### Wave 3: 战斗系统

- [x] 9. 炮台自动瞄准 + 开火

  **What to do**:
  - 实现自动瞄准逻辑：寻找最近敌人（使用 `get_node_or_null` 和距离计算）
  - 实现火控系统切换：手动/自动模式（炮台 UI 按钮）
  - 实现自动开火逻辑：瞄准后自动射击
  - 实现火控系统升级：购买后解锁自动开火
  - 添加炮台 UI：显示当前模式、升级按钮

  **Must NOT do**:
  - 不要实现复杂的目标优先级（MVP 只需最近敌人）
  - 不要实现多种火控系统（只有一种升级）

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: 需要实现 AI 瞄准逻辑和状态机
  - **Skills**: [`godot-combat-system`]
    - `godot-combat-system`: 目标选择模式

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 10-13)
  - **Parallel Group**: Wave 3
  - **Blocks**: Tasks 12, 16 (auto-fire needed for combat)
  - **Blocked By**: Tasks 1, 7

  **References**:
  - **Pattern References**: `godot-combat-system` skill - Target acquisition
  - **API References**: `Turret` from Task 7
  - **WHY**: 自动开火是休闲向玩法的关键

  **Acceptance Criteria**:
  - [ ] 炮台可切换手动/自动模式
  - [ ] 自动模式优先攻击最近敌人
  - [ ] 火控系统可升级（解锁自动开火）
  - [ ] 炮台 UI 显示当前模式

  **QA Scenarios**:
  ```
  Scenario: 炮台自动瞄准最近敌人
    Tool: godot-mcp_run_project
    Steps:
      1. Spawn 3 tanks at different distances
      2. Enable auto-fire on turret
      3. Wait 60 frames
      4. Check turret barrel aims at nearest enemy
    Expected Result: Turret aims at nearest tank
    Evidence: .sisyphus/evidence/task-09-auto-aim.png

  Scenario: 火控系统可升级
    Tool: godot-mcp_game_eval
    Steps:
      1. Set GameState.currency = 100
      2. Click upgrade button on turret
      3. Assert currency decreased
      4. Assert auto-fire unlocked
    Expected Result: Upgrade unlocks auto-fire
    Evidence: .sisyphus/evidence/task-09-upgrade-fire-control.log
  ```

  **Commit**: YES
  - Message: `feat: implement auto-fire targeting for turrets`
  - Files: `scripts/turret.gd`, `scenes/ui/turret_ui.tscn`

- [x] 10. 炮台韧性系统

  **What to do**:
  - 创建 `ToughnessComponent` 节点（当前韧性、最大韧性、自动恢复速率）
  - 实现韧性逻辑：炮台 X 距离内的伤害 → 削减韧性
  - 实现韧性耗尽 → 炮台瘫痪（无法开火）
  - 实现韧性自动恢复（每秒恢复 Y 点）
  - 实现炮台维修：角色靠近瘫痪炮台 → 按住 R 键 2 秒 → 恢复韧性
  - 添加韧性 UI：炮台上方显示韧性条

  **Must NOT do**:
  - 不要让韧性影响炮台伤害（只影响瘫痪状态）
  - 不要实现复杂维修系统（只需读条）

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: 核心创新系统，需要仔细设计
  - **Skills**: [`godot-2d-physics`, `godot-combat-system`]
    - `godot-2d-physics`: 检测炮台附近的伤害
    - `godot-combat-system`: 伤害系统扩展

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 9, 11-13)
  - **Parallel Group**: Wave 3
  - **Blocks**: Tasks 12, 13, 17 (toughness affects gameplay)
  - **Blocked By**: Tasks 1, 5, 7

  **References**:
  - **Pattern References**: Metis analysis - Turret toughness system
  - **API References**: `HealthComponent` from Task 2
  - **WHY**: 韧性系统是核心玩法创新

  **Acceptance Criteria**:
  - [ ] `ToughnessComponent` 存在
  - [ ] 韧性自动恢复工作正常
  - [ ] 韧性耗尽 → 炮台瘫痪
  - [ ] 角色可维修瘫痪炮台（读条 2 秒）
  - [ ] 韧性 UI 正确显示

  **QA Scenarios**:
  ```
  Scenario: 炮台韧性耗尽后瘫痪
    Tool: godot-mcp_game_eval
    Steps:
      1. Set turret toughness to 10
      2. Deal 15 damage near turret
      3. Assert turret is paralyzed
      4. Assert turret cannot fire
    Expected Result: Turret paralyzed when toughness depleted
    Evidence: .sisyphus/evidence/task-10-toughness-paralysis.log

  Scenario: 炮台韧性自动恢复
    Tool: godot-mcp_game_eval
    Steps:
      1. Set turret toughness to 50
      2. Wait 5 seconds
      3. Assert toughness recovered to 100
    Expected Result: Toughness auto-recovers
    Evidence: .sisyphus/evidence/task-10-toughness-recovery.log

  Scenario: 角色维修瘫痪炮台
    Tool: godot-mcp_run_project
    Steps:
      1. Paralyze turret (reduce toughness to 0)
      2. Move character near turret
      3. Hold R key for 2 seconds
      4. Assert turret toughness restored
    Expected Result: Turret repaired after hold R
    Evidence: .sisyphus/evidence/task-10-toughness-repair.log
  ```

  **Commit**: YES
  - Message: `feat: add turret toughness and paralysis system`
  - Files: `scripts/toughness_component.gd`, `scripts/turret.gd`, `scenes/ui/toughness_bar.tscn`

- [x] 11. 敌人 AI（寻路 + 攻击）

  **What to do**:
  - 实现敌人寻路：向船体移动（简单直线或避障）
  - 实现敌人攻击逻辑：
  - 坦克：近战冲撞（碰撞造成伤害）
  - 机械狗：远程射击（发射投射物）
  - 创建 `MechanicalDog` 场景（蓝色矩形占位符）
  - 实现敌人固定生成点（屏幕四周 4 个生成点）
  - 敌人击杀后掉落货币

  **Must NOT do**:
  - 不要实现复杂 AI（只需向船体移动 + 攻击）
  - 不要添加过多敌人类型（坦克 + 机械狗即可）

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: 需要实现 AI 行为和攻击逻辑
  - **Skills**: [`godot-characterbody-2d`, `godot-combat-system`]
    - `godot-characterbody-2d`: 敌人移动和寻路
    - `godot-combat-system`: 敌人攻击模式

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 9, 10, 12, 13)
  - **Parallel Group**: Wave 3
  - **Blocks**: Tasks 12, 17 (enemy AI needed for combat)
  - **Blocked By**: Tasks 1, 8

  **References**:
  - **Pattern References**: `godot-characterbody-2d` skill - Enemy AI
  - **API References**: `Tank` from Task 8
  - **WHY**: 敌人 AI 是战斗的核心

  **Acceptance Criteria**:
  - [ ] 敌人寻路工作正常（向船体移动）
  - [ ] 坦克近战攻击工作正常（碰撞伤害）
  - [ ] 机械狗远程攻击工作正常（发射投射物）
  - [ ] 敌人从固定生成点出现
  - [ ] 敌人击杀后掉落货币

  **QA Scenarios**:
  ```
  Scenario: 坦克冲撞造成伤害
    Tool: godot-mcp_run_project
    Steps:
      1. Spawn Tank near ship
      2. Let Tank reach ship
      3. Assert ship health decreased
    Expected Result: Tank damages ship on collision
    Evidence: .sisyphus/evidence/task-11-tank-attack.log

  Scenario: 机械狗远程攻击
    Tool: godot-mcp_game_eval
    Steps:
      1. Spawn MechanicalDog
      2. Wait for attack cooldown
      3. Assert projectile spawned
      4. Assert projectile damages ship
    Expected Result: Dog shoots at ship
    Evidence: .sisyphus/evidence/task-11-dog-attack.log
  ```

  **Commit**: YES
  - Message: `feat: implement enemy AI (pathfinding + attack)`
  - Files: `scripts/tank.gd`, `scripts/mechanical_dog.gd`, `scenes/enemy/mechanical_dog.tscn`

- [x] 12. 波次战斗系统（WaveManager）

  **What to do**:
  - 实现 `WaveManager` autoload：
    - 状态机：INACTIVE, BETWEEN_WAVES, ACTIVE_WAVE, COMPLETE
    - 波次数据：每波敌人数量、类型、生成间隔
  - 实现波次生成逻辑：
    - 每场战斗 3-5 波
    - 每波清空后进入间隙（可修理）
  - 实现波次间隙 UI："继续" + "修理" + "升级"（如果在商店）
  - 创建波次数据资源（`WaveData.tres`）

  **Must NOT do**:
  - 不要实现复杂波次生成（使用固定配置）
  - 不要实现 Boss 波次（Wave 4 任务）

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: 需要实现状态机和波次逻辑
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 9-11, 13)
  - **Parallel Group**: Wave 3
  - **Blocks**: Tasks 14, 17 (wave system needed for game loop)
  - **Blocked By**: Tasks 1, 8, 11

  **References**:
  - **Pattern References**: Metis analysis - Wave phases
  - **API References**: `EventBus` from Task 3
  - **WHY**: 波次系统是战斗循环的核心

  **Acceptance Criteria**:
  - [ ] `WaveManager` autoload 存在
  - [ ] 波次状态机工作正常
  - [ ] 每场战斗 3-5 波
  - [ ] 波次间隙 UI 正确显示

  **QA Scenarios**:
  ```
  Scenario: 波次正确生成敌人
    Tool: godot-mcp_game_eval
    Steps:
      1. Call WaveManager.start_waves()
      2. Wait for first wave
      3. Assert enemies spawned
    Expected Result: Enemies spawn in waves
    Evidence: .sisyphus/evidence/task-12-wave-spawn.log

  Scenario: 波次间隙可修理
    Tool: godot-mcp_run_project
    Steps:
      1. Complete wave 1
      2. Assert BETWEEN_WAVES state
      3. Click "Repair" button
      4. Assert ship health restored
    Expected Result: Can repair between waves
    Evidence: .sisyphus/evidence/task-12-wave-intermission.png
  ```

  **Commit**: YES
  - Message: `feat: build wave spawning system`
  - Files: `scripts/wave_manager.gd`, `resources/waves/wave_data.tres`, `scenes/ui/wave_ui.tscn`

- [x] 13. 船体生命值 + 修理机制

  **What to do**:
  - 实现船体受伤逻辑：
    - 敌人攻击 → 船体血量减少
    - 船体血量为 0 → 游戏结束
  - 实现角色修理机制：
    - 角色靠近船体损坏处 → 按住 R 键 2 秒 → 恢复血量
  - 添加船体血量 UI（左上角大血条）
  - 添加损坏指示器（船体上有红色闪烁区域）

  **Must NOT do**:
  - 不要实现复杂损坏系统（只需血量）
  - 不要实现资源消耗修理（只需时间）

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 基础修理机制实现
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 9-12)
  - **Parallel Group**: Wave 3
  - **Blocks**: Tasks 17, 18 (ship HP needed for game over)
  - **Blocked By**: Tasks 1, 2, 5

  **References**:
  - **Pattern References**: `HealthComponent` from Task 2
  - **WHY**: 船体血量是游戏结束条件

  **Acceptance Criteria**:
  - [ ] 船体受伤后血量减少
  - [ ] 角色可修理船体（读条 2 秒）
  - [ ] 船体血量为 0 → 游戏结束
  - [ ] 血量 UI 正确显示

  **QA Scenarios**:
  ```
  Scenario: 船体受伤后可修理
    Tool: godot-mcp_game_eval
    Steps:
      1. Set ship health to 50
      2. Move character near ship hull
      3. Hold R for 2 seconds
      4. Assert health restored to 100
    Expected Result: Ship repaired after hold R
    Evidence: .sisyphus/evidence/task-13-ship-repair.log

  Scenario: 船体血量为0游戏结束
    Tool: godot-mcp_run_project
    Steps:
      1. Set ship health to 10
      2. Deal 20 damage to ship
      3. Assert game over screen appears
    Expected Result: Game over when ship destroyed
    Evidence: .sisyphus/evidence/task-13-game-over.png
  ```

  **Commit**: YES
  - Message: `feat: add ship HP and visual indicator`
  - Files: `scripts/ship.gd`, `scenes/ui/game_over.tscn`

---

### Wave 4: 地图 + 进程

- [x] 14. 地图生成系统（《杀戮尖塔》式）

  **What to do**:
  - 实现地图节点类：`MapNode`（位置、类型、连接、状态）
  - 实现地图图类：`FloorGraph`（3 层，每层 10-15 节点）
  - 实现地图生成算法：
    - 固定起点和终点
    - 随机连接节点（确保可达）
    - 节点类型分配：战斗、精英、商店、事件、休息
  - 实现地图状态：当前层、当前节点、已访问节点
  - 使用种子 RNG（可重现生成）

  **Must NOT do**:
  - 不要实现程序化地图（手写 3 层即可）
  - 不要实现复杂地图逻辑（只需简单连接）

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: 地图生成算法需要仔细设计
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 15-17)
  - **Parallel Group**: Wave 4
  - **Blocks**: Tasks 15, 16, 17, 18 (map generation foundation)
  - **Blocked By**: Tasks 1, 4

  **References**:
  - **Pattern References**: Metis analysis - Slay the Spire map generation
  - **External References**: Slay the Spire random walk algorithm
  - **WHY**: 地图系统是 Roguelike 结构的基础

  **Acceptance Criteria**:
  - [ ] `FloorGraph` 类存在
  - [ ] 地图生成算法工作正常（3 层，每层 10-15 节点）
  - [ ] 节点连接正确（从起点可达终点）
  - [ ] 地图状态可保存和加载

  **QA Scenarios**:
  ```
  Scenario: 地图正确生成
    Tool: godot-mcp_game_eval
    Steps:
      1. Generate floor graph with seed 12345
      2. Assert 3 layers created
      3. Assert start and end nodes exist
      4. Assert all nodes reachable from start
    Expected Result: Valid map generated
    Evidence: .sisyphus/evidence/task-14-map-generation.log

  Scenario: 地图种子可重现
    Tool: godot-mcp_game_eval
    Steps:
      1. Generate map with seed 12345
      2. Generate map with seed 12345 again
      3. Assert maps are identical
    Expected Result: Same seed produces same map
    Evidence: .sisyphus/evidence/task-14-map-seed.log
  ```

  **Commit**: YES
  - Message: `feat: implement map generation with seeded RNG`
  - Files: `scripts/floor_graph.gd`, `scripts/map_node.gd`

- [x] 15. 地图 UI（节点选择）

  **What to do**:
  - 创建地图屏幕场景：`MapScreen.tscn`
  - 实现节点可视化：
    - 节点图标（战斗=剑，商店=钱袋，休息=帐篷等）
    - 节点状态（可达、已访问、锁定）
  - 实现节点选择：
    - 点击可达节点 → 高亮选择
    - 确认按钮 → 进入该节点场景
  - 实现层切换 UI（当前层 / 下一层）
  - 实现地图缩放/平移（鼠标滚轮 + 拖拽）

  **Must NOT do**:
  - 不要实现复杂动画（基础过渡即可）
  - 不要实现地图编辑器（只需显示和选择）

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
    - Reason: UI/UX 设计和实现
  - **Skills**: [`frontend-ui-ux`]
    - `frontend-ui-ux`: UI 设计模式

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 14, 16, 17)
  - **Parallel Group**: Wave 4
  - **Blocks**: Tasks 17, 18 (map UI needed for navigation)
  - **Blocked By**: Tasks 1, 14

  **References**:
  - **Pattern References**: Slay the Spire map UI
  - **API References**: `FloorGraph` from Task 14
  - **WHY**: 地图 UI 是玩家导航的界面

  **Acceptance Criteria**:
  - [ ] 地图屏幕场景存在
  - [ ] 节点正确可视化
  - [ ] 节点选择工作正常
  - [ ] 层切换工作正常

  **QA Scenarios**:
  ```
  Scenario: 地图UI正确显示节点
    Tool: godot-mcp_run_project
    Steps:
      1. Open map screen
      2. Screenshot map
      3. Assert all nodes visible
      4. Assert node icons correct
    Expected Result: Map displays correctly
    Evidence: .sisyphus/evidence/task-15-map-ui.png

  Scenario: 可选择可达节点
    Tool: godot-mcp_run_project
    Steps:
      1. Open map screen
      2. Click reachable node
      3. Assert node highlighted
      4. Click confirm button
      5. Assert transition to combat scene
    Expected Result: Can select and enter nodes
    Evidence: .sisyphus/evidence/task-15-node-selection.log
  ```

  **Commit**: YES
  - Message: `feat: build map screen UI with node selection`
  - Files: `scenes/map/map_screen.tscn`, `scripts/map_screen.gd`

- [x] 16. 商店系统（3-5 固定物品）

  **What to do**:
  - 创建商店场景：`ShopScreen.tscn`
  - 实现商店物品：
    - 炮台升级（伤害 +10%、射速 +20% 等）
    - 火控系统（解锁自动开火）
    - 船体修理（恢复 50% 血量）
    - 新炮台（安装到空闲炮位）
  - 实现购买逻辑：
    - 点击物品 → 扣除货币 → 添加效果
  - 实现商店 UI：物品列表、价格、购买按钮

  **Must NOT do**:
  - 不要实现随机物品池（固定 3-5 个物品）
  - 不要实现复杂经济系统（只显示货币和价格）

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 基础商店系统实现
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 14, 15, 17)
  - **Parallel Group**: Wave 4
  - **Blocks**: Tasks 18 (shop needed for progression)
  - **Blocked By**: Tasks 1, 14

  **References**:
  - **Pattern References**: Slay the Spire shop
  - **API References**: `GameState.currency`
  - **WHY**: 商店是玩家成长的关键节点

  **Acceptance Criteria**:
  - [ ] 商店场景存在
  - [ ] 3-5 个固定物品显示
  - [ ] 购买逻辑工作正常
  - [ ] 商店 UI 正确显示

  **QA Scenarios**:
  ```
  Scenario: 商店物品可购买
    Tool: godot-mcp_run_project
    Steps:
      1. Open shop
      2. Set currency to 100
      3. Click "Turret Damage +10%" (cost 50)
      4. Assert currency decreased to 50
      5. Assert turret damage increased
    Expected Result: Can purchase items
    Evidence: .sisyphus/evidence/task-16-shop-purchase.log

  Scenario: 货币不足无法购买
    Tool: godot-mcp_game_eval
    Steps:
      1. Open shop
      2. Set currency to 10
      3. Click item costing 50
      4. Assert purchase denied
      5. Assert currency unchanged
    Expected Result: Cannot afford items without currency
    Evidence: .sisyphus/evidence/task-16-shop-no-currency.log
  ```

  **Commit**: YES
  - Message: `feat: add shop scene with basic items`
  - Files: `scenes/map/shop_screen.tscn`, `scripts/shop_screen.gd`

- [x] 17. 死亡/重置流程

  **What to do**:
  - 实现游戏结束检测：
    - 船体血量为 0 → 死亡
    - 第 3 层 Boss 击杀 → 胜利
  - 实现死亡流程：
    - 显示游戏结束屏幕
    - "重新开始" 按钮 → 重置所有状态 → 返回地图起点
  - 实现胜利流程：
    - 显示胜利屏幕
    - "再来一局" 按钮 → 重置所有状态 → 返回地图起点
  - 实现等级系统占位符：显示击杀数、等级（无实际效果）

  **Must NOT do**:
  - 不要实现局外解锁（MVP 无永久进度）
  - 不要实现中途保存（经典 Roguelike 完全重置）

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 基础游戏流程实现
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 14-16)
  - **Parallel Group**: Wave 4
  - **Blocks**: Tasks 18 (death flow needed for game loop)
  - **Blocked By**: Tasks 1, 5, 12, 13

  **References**:
  - **API References**: `GameState`, `WaveManager`
  - **WHY**: 死亡/重置是 Roguelike 的核心

  **Acceptance Criteria**:
  - [ ] 游戏结束检测工作正常
  - [ ] 死亡后可重置游戏
  - [ ] 胜利后可重置游戏
  - [ ] 等级系统占位符显示

  **QA Scenarios**:
  ```
  Scenario: 死亡后重置游戏
    Tool: godot-mcp_run_project
    Steps:
      1. Start new game
      2. Purchase turret and upgrade
      3. Kill ship (set health to 0)
      4. Click "Restart" button
      5. Assert all progress reset
    Expected Result: Game fully resets on death
    Evidence: .sisyphus/evidence/task-17-death-reset.log

  Scenario: 胜利后重置游戏
    Tool: godot-mcp_game_eval
    Steps:
      1. Set game to layer 3 boss fight
      2. Kill boss (set health to 0)
      3. Click "Play Again" button
      4. Assert returned to layer 1
    Expected Result: Game resets after victory
    Evidence: .sisyphus/evidence/task-17-victory-reset.log
  ```

  **Commit**: YES
  - Message: `feat: implement death/reset flow`
  - Files: `scripts/game_state.gd`, `scenes/ui/victory_screen.tscn`

- [x] 18. 整合 + 平衡

  **What to do**:
  - 整合所有系统：
    - 主菜单 → 地图 → 战斗 → 商店 → 死亡/胜利 → 主菜单
  - 实现完整游戏循环：
    - 第 1 层 → 第 2 层 → 第 3 层 Boss → 胜利
  - 平衡调整：
    - 敌人血量、伤害、生成数量
    - 炮台伤害、射速、韧性
    - 货币获取、物品价格
  - 添加简单占位符 Boss（第 3 层结尾）
  - 端到端测试：完整 15-20 分钟游戏体验

  **Must NOT do**:
  - 不要过度打磨（MVP 阶段，功能 > 完美）
  - 不要添加新系统（只整合现有系统）

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: 系统整合和平衡需要全局视角
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO (依赖所有前置任务)
  - **Parallel Group**: Final integration
  - **Blocks**: Final Verification Wave
  - **Blocked By**: Tasks 1-17 (all tasks)

  **References**:
  - **API References**: All systems from Tasks 1-17
  - **WHY**: 最终整合和平衡确保游戏可玩

  **Acceptance Criteria**:
  - [ ] 完整游戏循环工作正常
  - [ ] 可完成 3 层游戏（15-20 分钟）
  - [ ] 平衡合理（不会太简单或太难）
  - [ ] Boss 存在（第 3 层）

  **QA Scenarios**:
  ```
  Scenario: 完整游戏循环
    Tool: godot-mcp_run_project
    Steps:
      1. Start new game from main menu
      2. Navigate map (3 layers)
      3. Complete all combat and shop nodes
      4. Defeat layer 3 boss
      5. See victory screen
      6. Click "Play Again"
      7. Assert returned to main menu
    Expected Result: Complete 15-20 minute run
    Evidence: .sisyphus/evidence/task-18-full-run.mp4

  Scenario: 死亡后游戏可重玩
    Tool: godot-mcp_run_project
    Steps:
      1. Start game
      2. Let ship be destroyed
      3. Click "Restart"
      4. Play another full run
      5. Assert no carryover from previous run
    Expected Result: Game fully replayable
    Evidence: .sisyphus/evidence/task-18-replay.log
  ```

  **Commit**: YES
  - Message: `feat: balance wave difficulty and costs`
  - Files: Multiple files (balance adjustments)

---

## Final Verification Wave (MANDATORY — after ALL implementation tasks)

> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and get explicit "okay" before completing.
>
> **Do NOT auto-proceed after verification. Wait for user's explicit approval before marking work complete.**
> **Never mark F1-F4 as checked before getting user's okay.** Rejection or user feedback -> fix -> re-run -> present again -> wait for okay.

- [ ] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists (read file, curl endpoint, run command). For each "Must NOT Have": search codebase for forbidden patterns — reject with file:line if found. Check evidence files exist in .sisyphus/evidence/. Compare deliverables against plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [ ] F2. **Code Quality Review** — `unspecified-high`
  Run `tsc --noEmit` + linter + `bun test`. Review all changed files for: `as any`/`@ts-ignore`, empty catches, console.log in prod, commented-out code, unused imports. Check AI slop: excessive comments, over-abstraction, generic names (data/result/item/temp).
  Output: `Build [PASS/FAIL] | Lint [PASS/FAIL] | Tests [N pass/N fail] | Files [N clean/N issues] | VERDICT`

- [ ] F3. **Real Manual QA** — `unspecified-high` (+ `playwright` skill if UI)
  Start from clean state. Execute EVERY QA scenario from EVERY task — follow exact steps, capture evidence. Test cross-task integration (features working together, not isolation). Test edge cases: empty state, invalid input, rapid actions. Save to `.sisyphus/evidence/final-qa/`.
  Output: `Scenarios [N/N pass] | Integration [N/N] | Edge Cases [N tested] | VERDICT`

- [ ] F4. **Scope Fidelity Check** — `deep`
  For each task: read "What to do", read actual diff (git log/diff). Verify 1:1 — everything in spec was built (no missing), nothing beyond spec was built (no creep). Check "Must NOT do" compliance. Detect cross-task contamination: Task N touching Task M's files. Flag unaccounted changes.
  Output: `Tasks [N/N compliant] | Contamination [CLEAN/N issues] | Unaccounted [CLEAN/N files] | VERDICT`

---

## Commit Strategy

Atomic commits for each major feature:

1. `feat: initialize Godot project with autoloads (GameState, WaveManager, EventBus)`
2. `feat: add DamageData and HealthComponent classes`
3. `feat: create EventBus signal architecture`
4. `feat: setup project directory structure`
5. `feat: create Landship scene with turret slots`
6. `feat: implement character WASD movement on ship`
7. `feat: add basic turret scene with manual fire control`
8. `feat: create Tank enemy placeholder`
9. `feat: implement auto-fire targeting for turrets`
10. `feat: add turret toughness and paralysis system`
11. `feat: implement enemy AI (pathfinding + attack)`
12. `feat: build wave spawning system`
13. `feat: add ship HP and visual indicator`
14. `feat: implement map generation with seeded RNG`
15. `feat: build map screen UI with node selection`
16. `feat: add shop scene with basic items`
17. `feat: implement turret toughness and paralysis`
18. `feat: add repair mechanics for ship and turrets`
19. `feat: balance wave difficulty and costs`
20. `feat: polish UI and add win/lose conditions`

---

## Success Criteria

### Verification Commands
```bash
# Run Godot project
godot-mcp_run_project --project-path="G:/dev/operation-taklamakan"

# Test character movement
godot-mcp_game_key_hold(key="W")
godot-mcp_game_wait(frames=30)
# Assert character moved

# Test turret placement
godot-mcp_game_click(x=slot_x, y=slot_y)
# Assert turret appears

# Test wave spawning
godot-mcp_game_call_method("/root/WaveManager", "start_waves")
godot-mcp_game_wait(frames=60)
# Assert enemies spawned
```

### Final Checklist
- [ ] All "Must Have" present
- [ ] All "Must NOT Have" absent
- [ ] Core gameplay validated (manual/auto turret switching is fun)
- [ ] Turret toughness system works (visual feedback + paralysis)
- [ ] Complete 3-layer run possible (15-20 minutes)
- [ ] Death leads to reset, not frustration
- [ ] No AI slop patterns
- [ ] Code follows Godot best practices
