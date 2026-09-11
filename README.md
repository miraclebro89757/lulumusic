# LoveSong

现场向的 iPhone 音乐播放器（v0.1 P0）。显示名 **LoveSong**；仓库路径仍为 `lulumusic`。把本机 / 隔空投送 / 同一 Wi‑Fi 网页上传的音频拷进沙盒，离线播放，并在封面上发弹幕。

> Linux 云环境无法运行 Xcode。请在 **Mac + Xcode 15+** 打开工程；单元测试在 iPhone 15 模拟器上用 `xcodebuild test` 跑。

---

## 相对上一版 LuluMusic 的变化

- 产品名改为 LoveSong；主界面收成 **演唱会回忆 + 播放** 两页（深色演唱会风）。
- 播放模式三态：顺序 / 单曲循环 / 随机（去掉列表循环）。
- Wi‑Fi 导入展示 `http://IP:port`，**4 位配对码** 首次必填；进入页自动开服、离开自动停服；网页不能删歌。
- 演唱会回忆列：歌名 / 歌手 / 现场 / 时长；可搜索现场标签。
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
| F08 演唱会回忆列 + 单击播放 + 搜索 | 完成 |
| F09 演唱会回忆/进度/弹幕开关持久化 | 完成 |
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
- 演唱会回忆搜索与 `venueTag`
- 弹幕存储、提前 500ms 生成、±300ms、1–3 轨道、密度 5
- Wi‑Fi 地址偏好（en0 / 192.168，排除蜂窝与环回）
- AVPlayer 毫秒时钟、真实波形峰值、乐观弹幕发送

本 Linux 环境没有 `xcodebuild`。提交前跑了 `python3 scripts/verify_lovesong_logic.py`（对照 Swift 源码与 XCTest 接线）。**以 Mac 上 `xcodebuild test` 为绿灯标准。**

---

## 真机安装（免费 Apple ID）

1. Xcode › Settings › Accounts 登录 Apple ID。  
2. Target **LuluMusic** › Signing：自动签名 + Personal Team。  
3. USB 连 iPhone（iOS 17+），必要时打开开发者模式。  
4. ⌘R 装到手机。  
5. **设置 › 通用 › VPN 与设备管理** 信任该 Apple ID。  
6. 网页上传：同一 Wi‑Fi，打开 **演唱会回忆** › Wi‑Fi 图标。进入该页会自动开服并弹出「本地网络」授权；电脑浏览器打开显示的 `http://IP:port`（不要用 127.0.0.1），输入 4 位配对码。上传时请保持本页打开，不要关闭或切走。

---

## 视觉（演唱会舞台）

深色优先：舞台近黑 `#0A0A0C`、追光橙 `#FF8A3D`。大封面 ZStack 舞台 + 封面色 LinearGradient；弹幕叠在封面上。播放页波形来自音频文件采样峰值（AVAssetReader），随 AVPlayer 进度着色。玻璃卡片约 24pt 圆角。MiniPlayer 为底部 `.thinMaterial` 胶囊，点按 morph 到全屏播放器。弹幕输入为底部固定栏（不可拖动）。iOS 26 Tab accessory，更早系统回落自定义胶囊。Scheme / target 未改。

---

## 真机 Wi‑Fi 网页上传核对

手机与电脑必须连**同一个 Wi‑Fi**（不要用个人热点当电脑侧网络，除非电脑也连这台 iPhone 热点）。

1. 打开 LoveSong → **演唱会回忆** → Wi‑Fi 导入。服务应自动开始，无「开始 / 停止」按钮。
2. 首次进入若弹出 **本地网络** 权限，选允许。
3. 页面显示 `http://192.168.x.x:端口` 或 `http://10.x.x.x:端口`（应是 Wi‑Fi IPv4，不是蜂窝、不是 `127.0.0.1`）。链接与配对码都可长按/复制。
4. 电脑浏览器打开该地址（明文 HTTP）。第一次输入 4 位配对码。
5. 拖入 mp3 / m4a / aac / wav / flac。进度出现在手机本页。
6. 离开本页或切走 App，服务会停；传输会中断。再进来会自动开服，配对码保持不变。

---

## 工程

```
LuluMusic/LuluMusic.xcodeproj     # scheme: LoveSong / LuluMusic
LuluMusic/LuluMusic/Theme/        # LoveSongTheme 演唱会色板与字体
LuluMusic/LuluMusic/Core/         # 可单测逻辑（格式、配对、模式、弹幕、恢复）
LuluMusic/LuluMusic/Views/        # 演唱会回忆、播放器、网页上传、舞台组件、PlayerChrome
LuluMusic/LoveSongTests/          # XCTest
```

数据：SwiftData `Track`（含 `venueTag`、`lastPositionMS`）与 `DanmakuComment`（`trackId` + `timestampMS`）。无后端。
