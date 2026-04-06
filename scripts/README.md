# scripts/

这里放项目的主要 GDScript 逻辑。

## 子域

- 根目录：全局逻辑、战斗逻辑、地图逻辑
- `ui/`：界面控制脚本
- `ship/`：陆行舰相关脚本
- `resources/`：资源类型脚本（对应 `.tres`）

## 重点文件

- `main.gd`：主流程编排
- `game_state.gd`：全局状态
- `wave_manager.gd`：波次战斗
- `map_manager.gd`：地图推进
- `turret.gd`：炮台控制

更细的约定见：`scripts/AGENTS.md`
