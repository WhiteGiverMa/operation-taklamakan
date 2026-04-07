# GUT 接入与落地清单

## 文档目的

这份文档描述 `operation-taklamakan` 项目如何接入 **GUT**（Godot Unit Test），以及接入后应如何与当前项目的 MCP / 人工验证方式协同工作。

它不是泛泛而谈的测试框架介绍，而是面向本项目实际状态的落地方案。

---

## 官方参考

- 官方文档：<https://gut.readthedocs.io/>
- GitHub 仓库：<https://github.com/bitwes/Gut>
- Godot Asset Library：搜索 `GUT - Godot Unit Test`

适配关系：

- GUT 9.x → Godot 4.x

本项目当前是 Godot 4.6，因此应使用 **GUT 9.x**。

---

## 当前项目状态

截至当前仓库状态：

- 项目 **还没有传统自动化测试框架**；
- 当前验证主要依赖：
  - Godot MCP；
  - 人工清单；
- 仓库内 **还没有项目级 `tests/` 目录**；
- 也 **还没有 `addons/gut/`**。

所以本项目当前的目标不是“重构全部验证体系”，而是：

1. 先把 **最小 GUT 基建** 接进来；
2. 先覆盖最值得单元化的逻辑；
3. 继续保留 MCP 作为运行时验证手段。

---

## GUT 在本项目里的职责边界

GUT 很有价值，但它不该被误用成“万能端到端测试器”。

### 适合交给 GUT 的内容

- 纯逻辑方法；
- 状态转换；
- 资源/配置加载；
- `InputManager` 这类包装层；
- 商店购买规则；
- 波次/层数计算；
- 事件触发前后的状态变化。

### 不适合优先交给 GUT 的内容

- 复杂场景装配；
- 强依赖真实鼠标/键盘/帧循环手感的输入验证；
- 依赖 Godot MCP 运行时交互的完整回放；
- 真正的端到端“打一局”流程。

这类仍应主要通过：

- 编辑器运行；
- MCP 驱动；
- 人工验收清单。

---

## 推荐接入目标

建议把本项目的测试体系分成三层：

### 第一层：GUT Unit Tests

目录：`tests/unit/`

用于验证：

- 输入包装逻辑；
- 游戏状态变更；
- 商店规则；
- 资源脚本行为；
- 可纯逻辑运行的战斗规则。

### 第二层：GUT Integration Tests（轻量）

目录：`tests/integration/`

用于验证：

- 若干节点组合行为；
- 重要信号链；
- 小型场景行为。

### 第三层：MCP / Runtime Verification

用于验证：

- 真实输入链路；
- 菜单到地图到战斗的完整流；
- 视觉与交互反馈；
- GUIDE context 切换；
- 暂停/设置/商店这种运行时 UI。

---

## 推荐目录结构

接入 GUT 后，建议项目结构新增：

```text
addons/
  gut/

tests/
  unit/
  integration/
  helpers/
  gut_config.json 或 .gutconfig.json
```

建议再补一个项目内测试说明：

```text
tests/
  README.md
```

---

## 接入步骤

## 一、安装 GUT addon

### 方式 A：Godot AssetLib

1. 打开项目；
2. 打开 AssetLib；
3. 搜索 `Gut`；
4. 安装到 `addons/gut/`。

### 方式 B：手动复制

1. 从官方仓库或 release 获取 GUT；
2. 把 `addons/gut/` 放进项目；
3. 确认存在：
   - `addons/gut/plugin.cfg`
   - `addons/gut/gut_cmdln.gd`

---

## 二、启用编辑器插件

在 Godot 中：

`Project Settings -> Plugins -> Gut -> Enable`

启用后应能在编辑器看到 GUT 相关面板/入口。

---

## 三、建立测试目录

建议至少创建：

- `tests/unit/`
- `tests/integration/`
- `tests/helpers/`

初始阶段可以先只用 `tests/unit/`。

---

## 四、补最小配置

建议在仓库根目录增加 `.gutconfig.json`，最小示例：

```json
{
  "dirs": [
    "res://tests/unit",
    "res://tests/integration"
  ],
  "include_subdirs": true,
  "prefix": "test_",
  "suffix": ".gd",
  "should_exit": true
}
```

这样以后本地运行和 CI 都更稳定。

---

## 五、先写一个 smoke test

接入 GUT 的第一目标不是马上覆盖所有逻辑，而是验证整个框架接通。

推荐第一个测试文件：

`tests/unit/test_smoke.gd`

最小内容示例：

```gdscript
extends GutTest

func test_smoke() -> void:
	assert_true(true)
```

跑通这个用例，说明：

- GUT 已安装；
- 测试发现成功；
- CLI 工作正常。

---

## 六、把项目最适合的逻辑优先纳入测试

本项目建议优先级如下。

### P0：`InputManager`

原因：

- GUIDE 已接入；
- 多 flow/context 切换容易退化；
- 很适合做纯逻辑回归。

建议覆盖：

- `activate_map()`
- `activate_combat()`
- `activate_pause()`
- `activate_turret_manual()`
- `deactivate_turret_manual()`

至少验证：

- 内部 flow 状态正确；
- 启用的 context 集合正确；
- 战斗态与暂停态不会串输入。

### P1：`GameState`

建议覆盖：

- 新局初始化；
- 暂停 / 恢复；
- 层推进；
- 游戏结束状态。

### P1：商店规则与升级规则

建议覆盖：

- 金币不足不可购买；
- 一次性升级不会重复购买；
- 购买后状态正确落到 `GameState`。

### P2：波次与资源逻辑

建议覆盖：

- 波次索引规则；
- 空波次 / 越界情况；
- 完成条件判断。

---

## 推荐命令

### 运行所有单元测试

```bash
godot4 --headless -s addons/gut/gut_cmdln.gd -- -gdir=res://tests/unit -ginclude_subdirs -gexit
```

### 运行单元 + 集成测试

```bash
godot4 --headless -s addons/gut/gut_cmdln.gd -- -gdir=res://tests/unit,res://tests/integration -ginclude_subdirs -gexit
```

### 使用配置文件

```bash
godot4 --headless -s addons/gut/gut_cmdln.gd -- -gconfig=res://.gutconfig.json -gexit
```

如果本机命令不是 `godot4`，请替换为当前环境下可用的 Godot 可执行文件。

---

## 推荐的第一批测试文件

建议第一批不要贪多，先用最小投入建立回归护栏：

- `tests/unit/test_smoke.gd`
- `tests/unit/test_input_manager.gd`
- `tests/unit/test_game_state.gd`
- `tests/unit/test_shop_rules.gd`

如果后面需要场景级验证，再补：

- `tests/integration/test_pause_flow.gd`
- `tests/integration/test_turret_manual_mode.gd`

---

## 当前项目下的注意事项

### 1. 不要指望 GUT 立即替代 MCP

当前仓库的真实强项是 MCP 运行时控制。GUT 进入后应该补的是“**稳定回归**”，不是替换“**实时交互验证**”。

### 2. GUIDE 相关验证要分层

对于 GUIDE：

- `InputManager` 的 flow/context 切换 → 适合 GUT；
- 真正按键、鼠标、菜单交互 → 更适合 MCP / 运行时。

### 3. 不要一开始就把脆弱场景流全塞进 GUT

例如主菜单 → 地图 → 战斗 → 商店 → 暂停的完整链路，第一阶段不适合直接用 GUT 端到端覆盖。那会让测试维护成本高于收益。

### 4. 先用 smoke test 证明基建，再谈覆盖率

本项目当前从零接入 GUT，第一目标是：

- 能跑；
- 能稳定发现测试；
- 能给核心逻辑加少量高价值回归。

不是去追求形式上的“测试很多”。

---

## GUT 扩展落地清单

### A. 基建

- [ ] 安装 `addons/gut/`
- [ ] 启用 GUT 插件
- [ ] 新建 `tests/unit/`
- [ ] 新建 `tests/integration/`
- [ ] 新建 `.gutconfig.json`
- [ ] 跑通 `test_smoke.gd`

### B. 第一批回归

- [ ] 为 `InputManager` 编写单测
- [ ] 为 `GameState` 编写单测
- [ ] 为商店购买规则编写单测
- [ ] 为波次/层推进编写基础单测

### C. 与现有验证体系协同

- [ ] 保留 MCP 作为运行时主验证方式
- [ ] 为 GUIDE 关键输入流补 MCP 清单
- [ ] 约定：逻辑回归优先 GUT，运行时交互优先 MCP

### D. 后续增强

- [ ] 增加 `tests/README.md`
- [ ] 支持 JUnit XML 输出
- [ ] 评估接入 CI
- [ ] 对脆弱 bug 补回归测试后再修复

---

## 建议的下一步

从当前项目状态出发，最合理的落地顺序是：

1. **先把 GUT 基建接入并跑通 smoke test**；
2. **第一批只测 `InputManager`、`GameState`、商店规则**；
3. **继续把运行时交互验证交给 MCP**；
4. **等 GUIDE 流程稳定后，再补更高层的 integration tests**。

这样投入最小，但能最快获得可持续收益。
