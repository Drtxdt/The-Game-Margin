# 实机验证与验收边界

本记录将实现检查、自动操作和首次玩家体验分开。脚本通过不等于体验时长、难度和美术品质已经验收。

2026-10-08 最终独立 EXE：**167 项检查全部通过，0 失败**（集成 62、路线与战斗夹具 11、死亡恢复 34、正常受伤战斗 2、首回环 16、连续路线 36、显示 6）。具体构建哈希以 `builds/delivery-manifest.json` 为准。打包器要求每份独立 EXE 测试报告晚于当前 EXE、全部通过且 stderr 为空，拒绝混用较早构建的通过记录。

## 已运行的检查

| 检查 | 证据 | 边界 |
|---|---|---|
| 集成测试 | `tests/output/exe-integration-report.json` | 移动、16 房间实例、书籍、死亡债务底线、路线机关、输入残响、障碍拒播、提前归还、备份恢复、暂停；部分测试用显式房间和位置夹具 |
| 隐藏路线与战斗 | `tests/output/exe-traversal-report.json` | 隐藏攀升使用真实连续按键，无坐标/速度强推；战斗测试使用明确的摆位和硬直夹具，不代表实战难度 |
| 正常流程与两种主修 | `tests/output/exe-routes-report.json` | 从校门开始使用真实移动和交互；屏蔽受伤以单独审计通路，Boss 净化为已单独验证的夹具；文理分支从中央连廊重新开始 |
| 死亡恢复专项 | `tests/output/exe-recovery-report.json` | 34 项：实际敌袭死亡、实际坠坑后步行取书；多本书、超过三次死亡、5/6 次边界、首次会面合并升级、一次交互回书与债务、读档防重复；边界用例有明确夹具 |
| 正常受伤战斗 | `tests/output/exe-combat-report.json` | 2 项：初始竞技场和持尺为夹具，随后正常 HP、碰撞、前摇、闪避、尺击与敲铃；本机控制器最低剩 3 点生命后胜利，不代表真人难度 |
| 首个回环专项 | `tests/output/exe-loop-report.json` | 16 项：可选上层登记簿、四个升降台初相位、楼梯展开后地面返程及读档；为几何审计，屏蔽受伤 |
| 显示与镜头 | `tests/output/exe-visual-report.json` | 6 项：地图、书包、数学读数、左右前视、站立落点和跳跃；截图另经目视检查，修复了读数被平台遮挡的问题 |
| Forge MCP 往返（历史） | `tests/output/forge-keyboard-scenario.json` | 前轮已实际完成 STDIO、改节点、模拟输入、截图和错误查询；本轮不将它计入新的 EXE 通过数 |
| 1080p 独立渲染 | `tests/output/standalone-performance.json` | 图书馆、活动守兽所在钟庭、档案井各采样 5 秒；不是全程性能保证 |

### 性能环境与结果

Godot 4.7.2 release，OpenGL Compatibility，NVIDIA GeForce RTX 4070 Laptop GPU。独立窗口为 1920×1080，逻辑画布为 1280×720，导出的截图为 1920×1080。

| 场景 | 平均 FPS | 平均帧时间 | 95% 帧时间 | 最慢帧 |
|---|---:|---:|---:|---:|
| 图书馆 | 240.1 | 4.165 ms | 4.597 ms | 5.185 ms |
| 钟庭 | 240.1 | 4.165 ms | 4.596 ms | 5.778 ms |
| 档案井 | 239.9 | 4.168 ms | 4.670 ms | 6.536 ms |

切房调用到第二个显示帧的采样：图书馆 60.2 ms、钟庭 11.6 ms、档案井 8.5 ms。这是包含加载与帧等待的首访计时，不等同于单帧 CPU 耗时。图书馆预载前曾测得约 176 ms，预载后明显降低，但首访仍有短暂峰值，不宣称所有切房均小于 16.7 ms。

稳定运行的这组采样满足本机 60 FPS 目标。release 模板的静态内存监控返回 0，视为该计数器不可用，不能解读为游戏没有内存消耗。编辑器嵌入窗口的 720p 采样不混入上述表格。

### 截图

- `tests/output/standalone-library-before.png`：尚未归还基础书。
- `library-basic.png`、`library-guardian-first.png`、`library-archive-first.png`：基础归书、先守兽、先档案的独立状态。
- `tests/output/standalone-library.png`：暖光、归还和守兽回家状态。
- `tests/output/standalone-bell.png`、`standalone-archive.png`：活动关卡。
- `recovery-parcel.png`、`recovery-map.png`：书包、书名提示与地图。
- `measure-observation.png`：装置实时周期、方向和到站时间。
- `library-walk-left.png`、`library-walk-right.png`、`library-jump.png`：左右前视与跳跃落点。

## 可复现命令

```powershell
# 工程中的逻辑与路线检查，再构建
.\tools\verify.ps1 -Routes -Export

# 验证真正导出的 EXE，包括正常流程和 1080p 渲染
.\tools\verify_export.ps1 -Routes -Render
```

所有自测使用独立 `*_qa.json` 文件，不替换 `journey.json`。release 模板不支持编辑器的 `--script` 入口，因此 EXE 内有显式、固定白名单的 `--self-test` 入口。普通双击不会进入测试。

## 仍需试玩确认

- **8–12 分钟首个回环、45–75 分钟全流程均未取得首次玩家计时证据。** 当前关卡有完整流程，但探索内容密度仍需根据首轮试玩扩展和打磨；不能宣称已达到正式时长验收。
- 图书馆是侧视手绘可运行样板，角色仍为 cutout 加程序姿态；其他房间和敌人保持占位美术。
- 三种普通敌人和守兽动作均已实现；前摇辨识、难度、攻击手感和音效质感需要玩家反馈。
- 直接战斗与环境解法均存在；自动测试不是一次无辅助的真人通关。
- 缝页作为录响器升级已经开放；后续学科、完整追查系统和后期结局未开放。

历史试跑日志可能包含已经修复的失败。以最新 `exe-*-report.json`、对应 `exe-*-stderr.log` 和最终打包记录为准，不把早期失败报告混称为最终通过。
