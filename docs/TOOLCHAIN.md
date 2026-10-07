# 已接入的开发工具

- Godot：`D:\Godot_v4.7.2\Godot_v4.7.2-stable_win64.exe`，已查询到 `4.7.2.stable.official.ed1daf0bf`。
- 命令行：同目录 `Godot_v4.7.2-stable_win64_console.exe`。
- Windows x86_64 导出模板：本机 `%APPDATA%\Godot\export_templates\4.7.2.stable`。
- Node.js 24：`D:\nodejs\node.exe`。
- Python：`D:\python\python.exe`，仅内容生成工具使用，正常编辑、运行不需要 Python。
- 五项 Godot 基础技能已安装：project-setup、gdscript-patterns、debugging、animation、ui。

## Forge

源码仓库：[Tann2019/godot-mcp-server](https://github.com/Tann2019/godot-mcp-server/tree/b0da85fac67dd067c16bfe791227c0e7edb56d7e)。固定提交：

```text
b0da85fac67dd067c16bfe791227c0e7edb56d7e
```

`godot-forge-mcp` npm 查询曾返回 404，因此使用 `tools/godot-forge` 的固定源码，`npm ci` 后 `npm run build`。编辑器插件安装在 `addons/godot_forge`，不依赖 `@latest`。在其他电脑重建：

```powershell
git clone https://github.com/Tann2019/godot-mcp-server.git tools/godot-forge
git -C tools/godot-forge checkout b0da85fac67dd067c16bfe791227c0e7edb56d7e
Set-Location tools/godot-forge
npm ci
npm run build
```

Codex 的 `C:\Users\dell\.codex\config.toml` 已增加独立 `godot_margin` 条目，保留原有其他条目；备份为相邻 `config.toml.before-margin`。条目通过本地 Node 启动固定构建，指定新工程及 Godot exe，STDIO 连接。

```toml
[mcp_servers.godot_margin]
command = "D:/nodejs/node.exe"
args = ["E:/my_game/Margin/tools/godot-forge/dist/index.js", "--project", "E:/my_game/Margin", "--godot", "D:/Godot_v4.7.2/Godot_v4.7.2-stable_win64.exe", "--launch", "gui"]
startup_timeout_sec = 120
tool_timeout_sec = 180
```

当前会话工具清单不会因配置文件修改自动刷新，因此本轮实际通过 `tools/forge_call.mjs` 使用 MCP SDK 连接同一 STDIO 服务完成往返验证。后续 Codex 会话加载 `godot_margin` 后可直接调用。

已实际验证：场景读取、树查看、灯光节点属性修改、运行主场景、发送动作输入、读取玩家状态、截取游戏画面、读取运行错误、保存并运行键盘 scenario。证据在 `tests/output/`，请求在 `tests/forge_*.json`。

批处理导入、导出时设置 `GODOT_FORGE_NO_SERVER=1`。这是插件源码支持的入口，避免无界面批处理再创建一个 Forge 编辑器服务；首次未设置时出现的插件退出资源警告已通过此方式消除。

Godot 编辑器嵌入运行窗口固定为 1280×720，远程请求改窗口尺寸未生效，因此这类采样不作为 1080p 性能证据。独立 EXE 的 `render` 自测在独立窗口中设置 1920×1080，并保存真实尺寸及采样结果。
