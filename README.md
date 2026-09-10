# LoveSong

现场向的 iPhone 音乐播放器（v0.1 P0）。显示名 **LoveSong**；仓库路径仍为 `lulumusic`。把本机 / 隔空投送 / 同一 Wi‑Fi 网页上传的音频拷进沙盒，离线播放，并在封面上发弹幕。

> Linux 云环境无法运行 Xcode。请在 **Mac + Xcode 15+** 打开工程；单元测试在 iPhone 15 模拟器上用 `xcodebuild test` 跑。

---

## 相对上一版 LuluMusic 的变化

- 产品名改为 LoveSong；主界面收成 **曲库 + 播放** 两页（深色演唱会风）。
- 播放模式三态：顺序 / 单曲循环 / 随机（去掉列表循环）。
- Wi‑Fi 导入展示 `http://IP:port`，**4 位配对码** 首次必填；离开页面或锁屏停服；网页不能删歌。
- 曲库列：歌名 / 歌手 / 现场 / 时长；可搜索现场标签。
- 播放器常驻弹幕输入；按 `trackId + 毫秒时间戳` 本地回放（误差目标 ±300ms）。
- 杀掉 App 后恢复当前曲、进度、弹幕开关、播放模式。
- 新增 `LoveSongTests`（纯逻辑，不依赖 UI）。

---

## P0 功能（F01–F10）

| ID | 状态 |
| --- | --- |
| F01 多选文件 + AirDrop | 完成（格式白名单） |
| F02 Wi‑Fi 网页导入 + 配对码 | 完成 |
| F03 mp3/m4a/aac/wav/flac，无 ogg | 完成 |
| F04 播放/暂停/上一首/下一首/进度条 | 完成 |
| F05 后台音频 + 锁屏 / 控制中心 | 完成（沿用） |
| F06 发弹幕，右→左飞过封面 | 完成 |
| F07 弹幕按曲目+时间回放 | 完成 |
| F08 曲库列 + 单击播放 + 搜索 | 完成 |
| F09 曲库/进度/弹幕开关持久化 | 完成 |
| F10 三态播放模式 | 完成 |

未做（按产品确认）：F14 长录音章节；F17–F21（含 F18 长图导出，以后再做）；账号 / 流媒体 / 社交。

---

## 在 Mac 上运行

```bash
git clone https://github.com/miraclebro89757/lulumusic.git
cd lulumusic
open LuluMusic/LuluMusic.xcodeproj
```

Scheme 选 **LoveSong**（或 **LuluMusic**，同一 App target），模拟器 **iPhone 15**，⌘R。

Signing：选你的 Apple ID Team；Bundle ID `com.lulumusic.app` 冲突时改成自己的。

---

## 跑单元测试

在装好 Xcode 的 Mac 上：

```bash
xcodebuild test \
  -project LuluMusic/LuluMusic.xcodeproj \
  -scheme LoveSong \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:LoveSongTests
```

Xcode：**Product › Test**（⌘U），scheme **LoveSong**。

测试覆盖（无 UI）：

- 导入格式白名单（含拒绝 OGG）
- 4 位配对码与上传鉴权
- 播放模式状态机
- 进度 / 弹幕开关恢复
- 曲库搜索与 `venueTag`
- 弹幕存储、提前 500ms 生成、±300ms、1–3 轨道、密度 5

本 Linux 环境没有 `xcodebuild`。提交前跑了 `python3 scripts/verify_lovesong_logic.py`（对照 Swift 源码与 XCTest 接线）。**以 Mac 上 `xcodebuild test` 为绿灯标准。**

---

## 真机安装（免费 Apple ID）

1. Xcode › Settings › Accounts 登录 Apple ID。  
2. Target **LuluMusic** › Signing：自动签名 + Personal Team。  
3. USB 连 iPhone（iOS 17+），必要时打开开发者模式。  
4. ⌘R 装到手机。  
5. **设置 › 通用 › VPN 与设备管理** 信任该 Apple ID。  
6. 网页上传：同一 Wi‑Fi，打开曲库 › Wi‑Fi 图标，电脑访问显示的 `http://IP:port`，输入 4 位配对码。保持该页在前台。

---

## 工程

```
LuluMusic/LuluMusic.xcodeproj     # scheme: LoveSong / LuluMusic
LuluMusic/LuluMusic/Core/         # 可单测逻辑（格式、配对、模式、弹幕、恢复）
LuluMusic/LuluMusic/Views/        # 曲库、播放器、网页上传
LuluMusic/LoveSongTests/          # XCTest
```

数据：SwiftData `Track`（含 `venueTag`、`lastPositionMS`）与 `DanmakuComment`（`trackId` + `timestampMS`）。无后端。
