# operation-taklamakan

一个基于 Godot 4.6 的俯视角陆行舰塔防 Roguelike 原型。

## 你应该先看哪里

- 产品预期：`docs/what-expected-behavior.md`
- 项目知识基线：`AGENTS.md`
- 运行入口：`project.godot` → `scenes/main.tscn`
- 主要逻辑：`scripts/`
- 场景装配：`scenes/`

## 目录说明

- `scripts/`：核心玩法、UI、资源脚本
- `scenes/`：Godot 场景文件
- `resources/`：波次等 `.tres` 数据资源
- `addons/godot_mcp/`：Godot MCP 运行时控制插件
- `docs/`：产品行为与项目说明文档

## 当前状态

- 有可运行的原型主流程
- 没有传统自动化测试框架
- 验证主要依赖 Godot MCP / 人工清单

## 子目录导航

- `scripts/README.md`
- `scenes/README.md`
- `addons/godot_mcp/AGENTS.md`
