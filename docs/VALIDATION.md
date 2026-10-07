# 实机验证与验收边界

本记录将实现检查、自动操作和首次玩家体验分开。脚本通过不等于体验时长、难度和美术品质已经验收。

最终 Windows EXE：**105 项检查通过，0 项失败**（集成 62、隐藏路线与战斗 11、连续路线 32）。对应三个测试及独立渲染的 stderr 均为空，导出日志无未处理错误。

## 已运行的检查

| 检查 | 证据 | 边界 |
|---|---|---|
| 集成测试 | `tests/output/exe-integration-report.json` | 移动、16 房间实例、书籍、死亡债务底线、路线机关、输入残响、障碍拒播、提前归还、备份恢复、暂停；部分测试用显式房间和位置夹具 |
| 隐藏路线与战斗 | `tests/output/exe-traversal-report.json` | 隐藏攀升使用真实连续按键，无坐标/速度强推；战斗测试使用明确的摆位和硬直夹具，不代表实战难度 |
| 正常流程与两种主修 | `tests/output/exe-routes-report.json` | 从校门开始使用真实移动和交互；屏蔽受伤以单独审计通路，Boss 净化为已单独验证的夹具；文理分支从中央连廊重新开始 |
| Forge MCP 往返 | `tests/output/forge-keyboard-scenario.json` | STDIO 服务实际运行、改节点、模拟输入、暂停、截图、错误查询；并非只写配置 |
| 1080p 独立渲染 | `tests/output/standalone-performance.json` | 图书馆、活动守兽所在钟庭、档案井各采样 5 秒；不是全程性能保证 |

### 性能环境与结果

Godot 4.7.2 release，OpenGL Compatibility，NVIDIA GeForce RTX 4070 Laptop GPU。独立窗口为 1920×1080，逻辑画布为 1280×720，导出的截图为 1920×1080。

| 场景 | 平均 FPS | 平均帧时间 | 95% 帧时间 | 最慢帧 |
|---|---:|---:|---:|---:|
| 图书馆 | 232.0 | 4.311 ms | 8.334 ms | 10.087 ms |
| 钟庭 | 227.9 | 4.389 ms | 8.289 ms | 9.476 ms |
| 档案井 | 224.4 | 4.456 ms | 7.661 ms | 9.545 ms |

这组采样满足本机 60 FPS 目标。release 模板的静态内存监控返回 0，视为该计数器不可用，不能解读为游戏没有内存消耗。编辑器嵌入窗口的 720p 采样不混入上述表格。

### 截图

- `tests/output/standalone-library-before.png`：归还档案前。
- `tests/output/standalone-library.png`：暖光、归还和守兽回家状态。
- `tests/output/standalone-bell.png`、`standalone-archive.png`：活动关卡。
- `tests/output/library-before.png`、`library-after.png`：Forge 返回的编辑器运行画面。

## 可复现命令

```powershell
# 工程中的逻辑与路线检查，再构建
.\tools\verify.ps1 -Routes -Export

# 验证真正导出的 EXE，包括正常流程和 1080p 渲染
.\tools\verify_export.ps1 -Routes -Render
```

所有自测使用独立 `*_qa.json` 文件，不替换 `journey.json`。release 模板不支持编辑器的 `--script` 入口，因此 EXE 内有显式、固定白名单的 `--self-test` 入口。普通双击不会进入测试。

## 仍需试玩确认

- **45–75 分钟未取得首次玩家计时证据。** 当前关卡有完整流程，但探索内容密度仍需根据首轮试玩扩展和打磨；不能宣称已达到正式时长验收。
- 图书馆是手绘方向的可运行样板，角色仍为 cutout 加程序姿态，交互道具仍有明显占位外观，离统一的最终成品美术还有修整空间。
- 三种普通敌人和守兽动作均已实现；前摇辨识、难度、攻击手感和音效质感需要玩家反馈。
- 直接战斗与环境解法均存在；自动测试不是一次无辅助的真人通关。
- 后续学科、缝页器、完整追查系统和后期结局按计划未开放。

历史试跑日志可能包含已经修复的失败。以最新 `exe-*-report.json`、对应 `exe-*-stderr.log` 和最终打包记录为准，不把早期失败报告混称为最终通过。
