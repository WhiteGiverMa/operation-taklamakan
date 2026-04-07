# godot_mcp/

这是项目内置的 Godot MCP 插件目录。

## 来源

本目录中的运行时脚本采用 **vendor** 方式同步自统一 fork，而不是在本项目里单独长期维护：

- Fork 仓库：`https://github.com/WhiteGiverMa/godot-mcp-full-control-adaptive`
- 本地工作目录：`G:\dev\godot-mcp-fc-a`

当前主要同步的文件是：

- `godot_operations.gd`
- `mcp_interaction_server.gd`

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

## 如何同步

推荐从 fork 仓库执行同步脚本：

```powershell
cd G:\dev\godot-mcp-fc-a
.\scripts\sync-downstream.ps1
```

脚本会先构建 fork，再把 `build/scripts/*.gd` 覆盖同步到下游项目。

## 本地保留文件

以下文件属于项目本地说明或插件壳，不应被整目录替换：

- `plugin.cfg`
- `mcp_editor_plugin.gd`
- `*.uid`
- 本目录 README / `AGENTS.md`

## 注意

- 这是高权限目录，不应把它当成普通 UI/工具脚本处理
- 详细约定与风险说明见：`AGENTS.md`
- 如果需要修改 `godot_operations.gd` 或 `mcp_interaction_server.gd`，应优先回到 fork 仓库修改，再重新 vendor 到本项目
