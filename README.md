# 陆陆音乐 / LuluMusic

本地优先的 iPhone 音乐播放器：把手机文件、苹果音乐曲库和电脑网页上传的音频拷进 App 沙盒，离线播放，并支持锁屏 / 控制中心。

A native SwiftUI music player for iPhone 15 (iOS 17+). Import from Files, Apple Music / the on-device library, or a same-Wi‑Fi browser upload page. No backend.

> 本仓库在 Linux 云环境中完成工程脚手架与全部源码。请在 **Mac + Xcode** 上打开工程编译；无法在此 Linux 虚拟机里运行 iOS Simulator。

---

## 功能 Features

- **曲库**：SwiftData 持久化标题、歌手、专辑、时长、封面、导入时间与来源；音频与封面复制到 App 沙盒。
- **文件导入**：`UIDocumentPicker`，支持 mp3 / m4a / aac / wav / flac（以及 aiff / caf）。
- **苹果音乐 / 本机曲库**：`MediaPlayer` 选歌后导出拷贝（受 DRM 保护的流媒体无法复制）。
- **网页上传**：手机开一个轻量 HTTP 服务（`NWListener`），电脑浏览器打开局域网地址或扫码即可上传；App 内显示进度；离开该页即关闭服务。
- **播放**：`AVPlayer` + `AVAudioSession` `.playback`；顺序 / 随机 / 列表循环 / 单曲循环；迷你播放条 + 全屏播放页 / Sheet；进度条、上一首 / 下一首。
- **系统控件**：后台音频、锁屏与控制中心（`MPNowPlayingInfoCenter` + Remote Commands）。
- **界面**：曲库 | 播放 | 导入；中文文案；搜索、滑动删除；深色模式；iPhone 15 安全区（灵动岛 / 刘海）。

---

## 工程结构

```
LuluMusic/
  LuluMusic.xcodeproj
  LuluMusic/
    LuluMusicApp.swift          # SwiftData + Player / Library 注入
    ContentView.swift           # 三个 Tab + 迷你播放器
    Models/                     # Track、PlaybackItem、循环模式
    Services/                   # 曲库、播放器、元数据、网页上传服务器
    Views/                      # 曲库 / 播放器 / 导入 / 网页上传
    Representables/             # 文件选择、苹果音乐选择
    Info.plist                  # 音乐库、本地网络、后台音频、ATS、UTType
    LuluMusic.entitlements
    PrivacyInfo.xcprivacy
```

可选：若已安装 [XcodeGen](https://github.com/yonaskolb/XcodeGen)，可用根目录 `LuluMusic/project.yml` 重新生成工程（已提交的 `.xcodeproj` 可直接打开）。

---

## 在 Mac 上用 Xcode 打开并跑 iPhone 15 模拟器

1. 安装 **Xcode 15 或更新**（App Store 或 [developer.apple.com](https://developer.apple.com/xcode/)），打开一次并同意许可：
   ```bash
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   xcodebuild -license accept
   ```
2. 克隆本仓库：
   ```bash
   git clone https://github.com/miraclebro89757/lulumusic.git
   cd lulumusic
   open LuluMusic/LuluMusic.xcodeproj
   ```
3. 顶部 Scheme 选 **LuluMusic**，模拟器选 **iPhone 15**（或 iPhone 15 Pro，系统 iOS 17+）。
4. 菜单 **Product › Run**（⌘R）。
5. 模拟器里可在「文件」中放入音频，或用网页上传（模拟器与电脑同一网络时，用显示的 LAN 地址）。模拟器没有完整的「苹果音乐」本机库时，请用真机验证该入口。

首次打开若提示缺少 Team：在 Target **LuluMusic › Signing & Capabilities** 里选你的 Apple ID 团队即可。模拟器通常不强制签名。

---

## 安装到实体 iPhone（免费 Apple ID 签名）

不需要付费 Developer Program。免费账号签名的 App 大约 **7 天** 后需在 Xcode 里重新 Run 一次。

### 1. 准备

- Mac 已装 Xcode 15+。
- iPhone 系统 **iOS 17+**（iPhone 15 已满足）。
- 一根 USB 线；Apple ID（普通 iCloud 账号即可）。
- iPhone 与 Mac 能互相信任。

### 2. 在 Xcode 登录 Apple ID

1. 打开 Xcode → **Xcode › Settings… › Accounts**。
2. 点 **+** → **Apple ID**，登录。
3. 选中账号，确认出现个人 Team（**Personal Team**）。

### 3. 修改签名与 Bundle ID

1. 打开 `LuluMusic/LuluMusic.xcodeproj`。
2. 左侧选中工程 → Target **LuluMusic** → **Signing & Capabilities**。
3. 勾选 **Automatically manage signing**。
4. **Team** 选你的个人团队。
5. 若 Bundle Identifier `com.lulumusic.app` 被占用，改成全球唯一值，例如 `com.你的名字.lulumusic`。

### 4. 连接 iPhone 并信任电脑

1. USB 连接 iPhone。若弹出「要信任此电脑吗？」，点 **信任** 并输入锁屏密码。
2. iPhone 上如提示开发者模式：**设置 › 隐私与安全性 › 开发者模式** → 打开并重启（iOS 16+ 真机调试需要）。
3. Xcode 顶部设备列表选你的 **iPhone**（不要选模拟器）。

### 5. 编译安装

1. **Product › Run**（⌘R）。
2. 若失败，看 Signing 错误：多半是 Bundle ID 冲突或未选 Team。
3. 成功后主屏幕会出现 **陆陆音乐**。

### 6. 在 iPhone 上「信任开发者」（必做）

免费签名的 App 第一次打不开，系统会提示未受信任：

1. 打开 **设置 › 通用 › VPN 与设备管理**（有的系统是 **描述文件与设备管理**）。
2. 在「开发者 App」里点你的 **Apple ID**。
3. 点 **信任 “xxx@…”** → 确认信任。
4. 回到主屏幕再打开 **陆陆音乐**。

若仍提示开发者模式，回到 **设置 › 隐私与安全性 › 开发者模式** 打开。

### 7. 权限与真机功能

| 能力 | 操作 |
| --- | --- |
| 本机 / 苹果音乐导入 | 首次点「打开音乐库」时允许访问；也可在 **设置 › 隐私与安全性 › 媒体与 Apple Music** 打开。 |
| 网页上传 | 手机与电脑连 **同一 Wi‑Fi**。打开 **导入 › 网页上传**，用电脑浏览器打开显示的 `http://192.168.x.x:端口/t/令牌/` 或扫码。上传时保持该页面在前台。若弹出本地网络权限，请允许。 |
| 后台与锁屏 | 开始播放后切到锁屏 / 控制中心即可看到封面与上一首 / 下一首。 |
| 文件 App / Finder | 工程开启了文件共享，可用 Finder 把音频拷进 App 容器后再在「文件」中导入。 |

### 8. 证书过期后

约一周后 App 可能变灰打不开：用 USB 连回 Mac，Xcode 再 **Run** 一次即可续期。

---

## 网页上传说明

- 服务绑定在手机局域网端口（默认 8787，被占用则换端口）。
- URL 带随机 token，降低同网段误传。
- 离开「网页上传」页会 **停止服务**。
- 浏览器页支持拖放与多文件；App 显示接收 / 导入进度。
- iOS 在后台会挂起监听套接字，上传请保持 App 在前台。

---

## 权限与 Info.plist

- `NSAppleMusicUsageDescription`：访问音乐库。
- `NSLocalNetworkUsageDescription` + `NSBonjourServices`：局域网网页上传。
- `UIBackgroundModes` = `audio`。
- `NSAppTransportSecurity` → `NSAllowsLocalNetworking`（本地 HTTP）。
- 文档类型 / `UTImportedTypeDeclarations`：mp3、m4a、aac、wav、flac 等。
- 纵向优先：`UISupportedInterfaceOrientations` = Portrait。

---

## English (short)

1. On a Mac: `open LuluMusic/LuluMusic.xcodeproj`, scheme **LuluMusic**, destination **iPhone 15**, ⌘R.
2. On a physical iPhone (free Apple ID):
   - Xcode › Settings › Accounts › add Apple ID.
   - Signing: your Personal Team + unique Bundle ID.
   - Enable Developer Mode on the phone if asked.
   - ⌘R onto the device.
   - Settings › General › VPN & Device Management › trust your developer Apple ID.
3. Import audio via Files, Apple Music (non‑DRM), or the in-app LAN upload page (same Wi‑Fi, keep that screen open).
4. This Linux environment cannot run Xcode; the project is a complete iOS app target for Xcode 15+ / iOS 17+.

---

## 许可

个人 / 学习用途。第三方音频版权由你自行负责。
