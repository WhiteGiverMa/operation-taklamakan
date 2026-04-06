# GODOT MCP ADDON KNOWLEDGE BASE

## OVERVIEW

这是一个运行时 Godot MCP 插件目录，不只是编辑器辅助代码。项目通过 autoload 的 `McpInteractionServer` 在游戏运行时暴露本地 TCP 控制能力。

## 查找指南

| 任务 | 位置 | 说明 |
|------|----------|-------|
| 插件注册 | `plugin.cfg` | 编辑器插件元数据 |
| 运行时 TCP 服务 | `mcp_interaction_server.gd` | 本地命令服务，TCP 上 JSON |
| 编辑器侧插件钩子 | `mcp_editor_plugin.gd` | 编辑器插件壳 |
| 操作辅助 | `godot_operations.gd` | 文件/场景辅助操作 |
| 运行时配置 | `../../config/mcp_server.json` | 主机、端口、回退策略 |

## 约定

- `McpInteractionServer` 通过 `project.godot` 自动加载
- `mcp_interaction_server.gd` 不使用 `class_name`——避免 autoload 冲突
- 默认端点 `127.0.0.1:9090`，可回退到附近端口
- 运行时元数据写入 `user://mcp_server_runtime.json`

## 反模式

- 不要在未审查安全影响的情况下将此服务暴露到受信任的本地工作流之外
- 不要忘记 `_cmd_eval()` 执行任意 GDScript——视为特权操作
- 不要假设配置的端口有保证——回退可能改变实际监听端口
- 不要在无头模式下依赖此插件——除非显式设置了启用环境变量

## 注意事项

- 存在忙状态恢复——命令可能挂起；关注 `_busy` 超时行为
- 无效 JSON 配置会静默回退并发出警告，而非硬失败
- 任何命令层变更应针对运行时和外部客户端预期进行测试
