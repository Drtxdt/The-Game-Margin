# 素材来源与许可记录

## 手绘图像

以下图像由本轮 Codex 内置 image generation 工具根据项目原创描述生成，未使用外部作品或艺术家风格名称。运行资源为项目内 PNG，透明角色保留 Alpha，Godot 负责缩放、裁切取样和姿态动画。

| 资源 | 内容与生成记录 |
|---|---|
| `assets/art/library.png` | 寂静破败的校园图书馆，侧视探索场景，手绘纸本质感，冷青与温暖琥珀灯光，书架、书桌、纵向窗，无人物、文字；生成 ID `865e090e-eb9d-416e-9e46-9e22b4af1f22` |
| `assets/art/cooper.png` | 黑白边牧库珀，朝右完整侧身，温和警觉、赤陶布项圈，透明底水粉手绘；生成 ID `d9948ff9-d61d-40c3-a79d-5c283061a208` |
| `assets/art/student_clean.png` | 短发学生探索者、青色校服、围巾、帆布包与折尺，侧身手绘；初稿 ID `87a0621e-0ed9-4a3d-8bcc-2ec10e406472`，透明背景清理版 ID `7f19bd43-18f3-46e8-9f5e-934d282ba15b` |
| `assets/art/guardian_clean.png` | 净化后蜷伏休息的象牙白守兽，苔绿纹样与旧铜铃项圈，透明底手绘；初稿 ID `1ffd885f-3379-437f-bcf0-d760551524dc`，清理版 ID `5accdec4-3cf0-4395-941d-7a063b6795a2` |

图书馆恢复状态由 Godot 的颜色调制、独立灯光层、尘埃、暖色地面光和角色显隐组合实现。背景不是覆盖界面和人物的整屏截图。

AI 生成角色目前为静态手绘 cutout 配合程序动画；尚未提供完整逐帧步行和攻击画稿。其他场景、敌人和机关以项目原生几何绘制作为清晰占位素材。

## 字体

Noto Sans SC variable font，来自 [Google Fonts 的 Noto Sans SC 目录](https://github.com/google/fonts/tree/main/ofl/notosanssc)，许可为 SIL Open Font License 1.1。随工程保留 `assets/fonts/OFL.txt`。UI 使用可编辑 FontVariation 调整字重。

## 音频和图标

`assets/audio/*.wav` 是 `tools/build_content.py` 合成的原创提示声和环境和弦，不含外部录音。图标 `assets/icon.svg` 为本项目原生矢量书本图形。环境音乐以循环基础声部与图书馆暖色声部叠加，属于原型配乐。

## 第三方工具

Godot Engine，MIT License；相关引擎许可见 [Godot license](https://godotengine.org/license/)。Godot Forge，MIT License，版权信息与完整文本保留在 `docs/licenses/GodotForge-LICENSE.txt`。独立发行附带字体与工具许可；Node 源码工具不打进 EXE。
