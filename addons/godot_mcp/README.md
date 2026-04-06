# godot_mcp/

这是项目内置的 Godot MCP 插件目录。

## 作用

- 在游戏运行时启动本地 TCP 控制服务
- 供外部 MCP 客户端 / 自动化工具连接
- 支持截图、输入、场景操作、脚本执行等能力

## 关键文件

- `mcp_interaction_server.gd`：运行时服务主入口
- `godot_operations.gd`：底层操作实现
- `plugin.cfg`：插件元信息

## 配置来源

- 运行配置位于：`../../config/mcp_server.json`

## 注意

- 这是高权限目录，不应把它当成普通 UI/工具脚本处理
- 详细约定与风险说明见：`AGENTS.md`
