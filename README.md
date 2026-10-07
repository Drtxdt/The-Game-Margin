# 余页 / Margin

Godot 4.7.2 · GDScript · 2D Compatibility · 简体中文 · Windows 键盘版。

本工程从零建立在 `E:\my_game\Margin`。旧工程、旧代码和旧存档均未迁移。

## 运行

- 独立程序：`builds/windows/Margin.exe`。资源嵌入 EXE，运行不需要 Node、Forge 或 Godot 编辑器。
- 编辑工程：用 Godot 4.7.2 打开 `project.godot`，按 F6 检查单个场景、F5 运行主场景。
- 主场景：`scenes/main.tscn`；16 个房间：`scenes/rooms/`；角色和敌人：`scenes/entities/`；界面：`scenes/ui/game_ui.tscn`。
- 按键可在标题或暂停菜单中修改。方向键、Enter 可操作菜单。

| 操作 | 默认按键 |
|---|---|
| 移动 / 跳跃 | A、D / Space；松开 Space 可降低跳高 |
| 闪避 / 折尺攻击 | Shift / J |
| 空中下劈 | 空中按住 S，再按 J |
| 交互 | E；推车需要按住 |
| 知识观察 | Q |
| 录制 / 调用主动残响 | R / F；需在锚点旁站稳录制 |
| 地图 / 暂停 | Tab / Esc |

普通移动、攻击和维护通道不消耗理智。主动残响每次花费 12 点当前理智，最长 8 秒。检查点补回身体和当前理智，不恢复死亡损失的上限。

## 本次可玩范围

开场施救、折尺、数学与语言试读、图书馆归还和主修切换、真实输入残响、文理及维护路线、钟庭守兽、地下档案、回图书馆收束均已接入。支持提前取得档案的顺序。两条地图回环和额外路线保留，普通提示不揭露额外路线的位置。

图书馆使用手绘背景、独立角色素材、灯光与音乐层次；其他房间是统一的占位关卡。当前角色动画仍以程序驱动的姿态、呼吸、位移和攻击提示为主，尚非完整逐帧手绘动画。

**45–75 分钟仍是首次正常探索的验收目标，并非已测得的游玩时长。** 自动测试不代表新玩家体验验收。请将这次构建作为完整流程的首轮试玩版：先确认移动、地图辨识、因果理解与守兽难度，再据实际试玩调整内容密度和节奏。

## 存档

Windows 独立目录：`%APPDATA%\MarginDemo\`。

- `journey.json`：版本化进度；`journey.json.bak`：最近有效备份。
- `settings.json`：音量、全屏、改键；不受语言知识影响。
- QA 使用不同文件名，不替换正式旅程。正式程序不会读取旧工程存档。
- 自动保存：拾书、归还、死亡、换主修、永久机关、净化守兽、房间切换、暂停及定时保存。
- 未结束的守兽战斗不保存临时血量；重新开始旅程或继续游戏从检查点恢复。

## 开发与验证

集中数值：`scripts/balance.gd`。保存对象以 `stable_id` 标识，不依赖临时节点路径。

```powershell
.\tools\verify.ps1 -Routes -Export
```

脚本默认使用本机 Godot 路径，迁移机器时用 `-Godot` 参数覆盖。测试报告及截图在 `tests/output/`。Forge 往返测试在 `tests/forge_release_check.json`，可复用键盘场景在 `tests/scenarios/keyboard_smoke.json`。

`tools/build_content.py` 是**显式运行的内容生成工具**，重新生成会覆盖房间、实体与 UI 场景。直接在编辑器修改场景后，不要无意重跑它；核心 GDScript 不会被它生成或覆盖。

更多细节：[架构](docs/ARCHITECTURE.md)、[工具链](docs/TOOLCHAIN.md)、[素材来源](docs/CREDITS.md)、[测试与验收](docs/VALIDATION.md)、[试玩记录](docs/PLAYTEST.md)。
