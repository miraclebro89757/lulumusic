# LoveSong UI Spec · UI Refresh MVP

| 项 | 内容 |
|---|---|
| 产品 | LoveSong（演唱会录音本地播放 + 弹幕回忆） |
| 文档 | UI Spec v1.0 |
| 日期 | 2026-09-11 |
| 设备 | iPhone 15（393×852 pt @3x；Safe Area 必须） |
| 上游 | `/workspace/lulumusic-prd/CHANGE-SPEC-lovesong-ui-refresh.md` |
| 作者 | Senior iOS Product Designer（IOS UI） |
| 交接 | IOS DEV → IOS TEST |
| 目标 | DEV 可仅凭本文 + Change Spec 用 SwiftUI 实现，无需打开 music-UI 仓库 |

---

## 1. Design Direction

**一句话**：黑紫白沉浸舞台上，用三 Tab 把「选歌 / 听+飞幕 / 现场气泡」拆清，去掉一切社交壳与暖橙噪音，让时间戳回忆成为唯一视觉主角。

---

## 2. Design Principles（最多 5）

1. **Clarity first**：一眼知道现在听什么、能不能发回忆、怎么导入。去掉 Like / 飘心 / 他人身份。
2. **Hierarchy over decoration**：大紫播放键 > 进度 > 封面飞幕 > 次要入口；毛玻璃只服务可读与分层，不做氛围堆叠。
3. **iOS-native surfaces**：`TabView` + `NavigationStack` + `sheet` + `List` + `ProgressView`；不发明第三层全屏 Overlay 播放器。
4. **One data, two skins**：弹幕只有 `trackId+timestampMS`；Player = 右→左飞幕，Live = 左下气泡；禁止第二套聊天模型。
5. **Cut ruthlessly**：参考里有但不成立的（手账、Setlist、假多人）本轮零像素。

---

## 3. Information Architecture

```
Root: TabView (MobileTab)
│
├── Tab[0] Playlist  「歌单」  SF Symbol: list.music
│     ├── NavigationStack
│     │     ├── S1_Playlist（列表 / 搜索 / 空态）
│     │     └── push/sheet → S4_WifiImport
│     └── MiniPlayerBar（有 currentTrack 时贴在 Tab 上方）→ 点按切到 Player Tab
│
├── Tab[1] Player    「播放」  SF Symbol: opticaldisc（fallback: play.circle.fill）
│     └── S2_Player
│           ├── tap cover / venue strip → select Live Tab（同进度）
│           ├── toolbar → Playlist Tab
│           └── 常驻简输入 +（Should）smile → S5_DanmakuModal
│
└── Tab[2] Live      「现场」  SF Symbol: bubble.left.and.bubble.right（fallback: message.fill）
      └── S3_Live
            ├── back 「返回播放」→ Player Tab
            ├── smile → S5_DanmakuModal（sheet）
            └── 无 track → Empty 引导回 Playlist
```

### Navigation rules

| From | Action | To | Notes |
|---|---|---|---|
| Any | Tab tap | 对应 Tab | 播放不中断；Live/Player 共享 `PlayerEngine` |
| S1 row tap | 选歌 | Player Tab + play | 设 currentTrack，开始/续播 |
| S1 MiniPlayer | tap | Player Tab | **不**再推 FullPlayerOverlay（CH-14 / §13 Q3） |
| S1 | Wi‑Fi 按钮 | S4 sheet/push | 离开即停服 |
| S1 | 本地导入 | system picker | 权限失败 → Permission Denied 态 |
| S2 | cover / venue | Live Tab | 同曲同进度 |
| S2 | list 入口 | Playlist Tab | |
| S3 | 返回播放 | Player Tab | |
| S3 / S2 | smile | S5 sheet | 点短语立即发送（ASSUMPTION） |
| S5 | dismiss / 发送后 | 原屏 | |

**禁止**：Playlist 上再叠第三层 morph 全屏播放器；Live 作为独立「多人直播」路由。

---

## 4. Screen Map

| Screen ID | 中文名 | Tab / Present | Priority |
|---|---|---|---|
| `S1_Playlist` | 我的歌单 | Tab Playlist | Must |
| `S2_Player` | 播放 | Tab Player | Must |
| `S3_Live` | 现场 | Tab Live | Must |
| `S4_WifiImport` | Wi‑Fi 导入 | sheet/push from S1 | Must |
| `S5_DanmakuModal` | 快捷弹幕 | sheet from S3（S2 Should） | Should |
| `C0_TabBar` | 底栏 | 全局 | Must |
| `C1_MiniPlayerBar` | 迷你播放条 | S1 底（Tab 上） | Must（有曲时） |

---

## 5. Screen Specifications

### 5.0 C0 · Bottom Tab Bar

| 字段 | 内容 |
|---|---|
| Screen ID | `C0_TabBar` |
| Purpose | 三态导航：选歌 / 播放 / 沉浸 |
| Hierarchy | 选中态 accent 紫 > 未选中 secondary text > 毛玻璃底 |
| Layout | 系统 `TabView` 底栏；高度随 Safe Area（约 49 + home indicator）；图标 24–28pt；标签 Caption |
| Components | TabItem ×3：歌单 `list.music` / 播放 `opticaldisc` / 现场 `bubble.left.and.bubble.right` |
| Primary CTA | 当前上下文 Tab |
| Secondary CTA | N/A |
| Navigation | 切 Tab 不重置播放 |
| States | Selected / Unselected；无 Disabled |
| Interaction | Tap → haptic light（可选）→ Tab 内容切换 → 播放继续 |
| Animation | 系统默认 Tab 切换；Reduce Motion 时无额外过渡 |

**选中视觉**：icon + title 使用 `accent` `#8B5CF6`；未选中 `text.secondary`。背景：`ultraThinMaterial` 或 `bg.elevated` 实底 + 顶部分割线 `border` 白 8%。

**Copy**：`歌单` / `播放` / `现场`

---

### 5.1 S1 · Playlist

| 字段 | 内容 |
|---|---|
| Screen ID | `S1_Playlist` |
| Purpose | 选听什么；本地 / Wi‑Fi 导入；轻编辑 venueTag |
| Hierarchy | 导航标题与导入动作 > 搜索 > 列表行（封面·标题·venue·时长）> MiniPlayer > Tab |
| Layout（top→bottom，iPhone 15） | |

```
SafeArea top
├── NavBar 56pt
│     leading: 标题「我的歌单」 Title/Bold 20–22pt
│     trailing: HStack spacing 16
│       · Button 本地导入  SF: plus.circle.fill  28pt hit ≥44
│       · Button Wi‑Fi     SF: wifi  28pt hit ≥44
├── SearchBar 36pt + vertical padding 8 → 总占位 ~52pt
│     placeholder「搜索歌曲或现场」
├── List / Scroll content
│     section inset：horizontal 16
│     row height ≈ 72pt；row spacing 8；cornerRadius 12 glass
│     [cover 56×56 r12] [VStack title/artist/venue] [duration Caption]
├── Spacer → MiniPlayerBar 64pt（有 currentTrack 时）
└── TabBar
```

**Approximate spacing**：Nav bottom → Search top = 8；Search → first row = 12；row internal H = 12；list bottom inset = MiniPlayer ? 72 : 16。

#### Components

| Name | Role | Key size |
|---|---|---|
| `PlaylistNavBar` | 标题 + 导入入口 | 高 56 |
| `PlaylistSearchField` | 过滤列表 | 高 36，r12 |
| `TrackRow` | 选歌主单元 | 高 72，cover 56 |
| `VenueTagChip` | 行内弱标签 | 高 18–20，Caption |
| `EmptyPlaylistView` | 空库 CTA | 全屏中部 |
| `MiniPlayerBar` | 当前曲捷径 | 高 64，宽满屏-0 |

#### Primary CTA
- **有曲**：点 `TrackRow` → 播放并切 Player Tab  
- **空库**：主按钮「导入现场录音」（触发本地文件选择；旁链 Wi‑Fi）

#### Secondary CTA
- 本地导入（+）  
- Wi‑Fi 导入  
- 搜索  
- 长按 / swipe：编辑 `venueTag`（Keep 现有能力，不新手账页）

#### Navigation
- → `S2_Player`（选歌 / MiniPlayer）  
- → `S4_WifiImport`  
- Tab 切换

#### States

| State | UI |
|---|---|
| First Use / Empty | 居中插画位（简单 disc SF 大图标 48pt，secondary）+ 文案「还没有现场录音」+ Primary「导入现场录音」+ TextButton「Wi‑Fi 从电脑导入」 |
| Loading | 列表区 `ProgressView` 或 6 行 skeleton（紫灰 shimmer 弱） |
| Loaded | TrackRow 列表 |
| Searching | 过滤结果；无匹配：「没有找到相关歌曲」Caption |
| Error | toast「导入失败，请重试」（不挡列表） |
| Offline | 本地库仍可用；Wi‑Fi 入口可点，进 S4 再解释 |
| Disabled | N/A（导入按钮不因 offline 禁用） |
| Long Content | 标准懒加载 List；标题 1 行 truncate；venue 1 行 |
| Permission Denied | 本地文件：alert +「去设置」；见 Interaction |
| Importing | Nav 旁小 Progress 或行顶 banner「正在导入…」 |

#### Interaction

| User Action | Visual Feedback | State Change | Result |
|---|---|---|---|
| Tap row | row highlight 白 8% 120ms | currentTrack=row；playback→playing | 切 Player Tab |
| Tap + | 系统 document picker | picking→importing | 成功刷新列表 |
| Tap wifi | push/sheet S4 | serverOn | 见 S4 |
| Submit search | 列表即时过滤 | Searching | 结果或空 |
| Long-press venue | 弹出编辑（TextField） | venueTag 更新 | 行刷新 |
| Tap MiniPlayer | bar press scale 0.98 | — | 切 Player Tab |

#### Animation
- 行插入：opacity 0→1 + offsetY 8→0，200ms easeOut  
- MiniPlayer 出现：从 Tab 上滑入 250ms  
- **无** morph 成全屏 Overlay  

#### ASSUMPTION
- MiniPlayer 在 Playlist **仅**作为入口条，点按 = `selectedTab = .player`，不创建第三播放层（遵循 §13 Q3）。

---

### 5.2 S2 · Player

| 字段 | 内容 |
|---|---|
| Screen ID | `S2_Player` |
| Purpose | 听歌 + 封面右→左时间戳飞幕回忆 |
| Hierarchy | 封面+飞幕 > 大紫播放键 > 进度 > 曲信息/venue > 模式与切歌 > 弹幕输入 > Tab |
| Layout（top→bottom） | |

```
bg.stage 全屏
SafeArea top
├── TopBar 44pt
│     leading: （可空或弱）
│     trailing: Button 歌单  SF: list.bullet  hit 44 → Playlist Tab
├── Spacer 12
├── CoverStack  maxWidth 290，aspect 1:1，居中
│     ├── Artwork card r24 + shadow
│     ├── DanmakuFlyOverlay（右→左，1–3 轨，密度 ≤5）
│     └── 无封面：紫黑渐变 seed 占位
├── Spacer 16
├── TitleBlock
│     title Display/Title 22–24 Bold，1 行
│     artist Body secondary，1 行
├── VenueGlassStrip 高 36，horizontal 16，margin top 12
│     有 venueTag：展示文本
│     无：弱文案「添加现场标签」（可点编辑）
│     整条可点 → Live（空标签也可进 Live，§13 Q4）
├── Spacer 20
├── ProgressBlock horizontal 24
│     track 高 6，knob 白圆 14–16
│     time labels Caption 左右
├── Transport 高 ~56，margin top 16
│     [mode chip 左] [prev 44] [PLAY 56] [next 44] [spacer 右平衡]
│     PLAY：实心圆 accent 56×56，icon play/pause 白 24
│     mode：glass chip，SF repeat / repeat.1 / shuffle
├── DanmakuInputBar 常驻 48–52pt，margin 12/16，bottom safe
│     [TextField 发弹幕…] [send 或 return] [smile Should]
└── TabBar
```

**无 Like / 心形槽位**。原参考心形位置：**不放装饰**；用左侧 **mode chip** 承担平衡（清晰层级优先于对称装饰）。

#### Components

| Name | Role | Key size |
|---|---|---|
| `CoverArtCard` | 视觉锚点 | ≤290 宽，r24 |
| `DanmakuFlyLayer` | 时间戳飞幕 | 覆盖封面；字 Body 15–17 |
| `VenueGlassStrip` | 现场标签 + 进 Live | 高 36，r12 |
| `ProgressBar` | seek | track 6，knob 16 |
| `PlayPauseButton` | 主操作 | 56 Ø |
| `ModeChip` | sequential / singleLoop / shuffle | 高 32，r16 |
| `TransportPrevNext` | 切歌 | 44 hit |
| `DanmakuInputBar` | 常驻发送（§13 Q2） | 高 48–52 |
| `NoTrackPlaceholder` | 无曲 | 中部 CTA 去歌单 |

#### Primary CTA
播放 / 暂停（大紫键）

#### Secondary CTA
发弹幕；进 Live（封面/venue）；模式；上一首/下一首；回歌单；smile→Modal（Should）

#### Navigation
- → Live Tab（cover / venue）  
- → Playlist Tab（toolbar / 无曲 CTA）  
- → S5 sheet（smile）

#### States

| State | UI |
|---|---|
| First Use | N/A（无曲走 NoTrack） |
| Empty / NoTrack | 封面位渐变占位 +「去歌单选一首」按钮 |
| Loading / Buffering | Play 键上小 Progress 或封面弱 shimmer（optional） |
| Loaded / Paused | 静态封面；play icon；飞幕不新发（历史调度仍可按 clock 若在播） |
| Playing | pause icon；飞幕按 clock |
| Seeking | knob 跟随；松手后恢复意图态 |
| Error | toast「无法播放」+ 保留控件 |
| Offline | 本地播放正常 |
| Disabled | 无曲时 prev/next/play 弱化；输入可禁用或提示先选歌 |
| Long Content | 标题 truncate；弹幕文本 UI 截断 80 字（Change Spec §10） |
| Danmaku Off | **不绘制**飞幕；输入仍可用并入库（ASSUMPTION） |
| Permission Denied | N/A |

#### Interaction

| User Action | Visual Feedback | State Change | Result |
|---|---|---|---|
| Tap Play | 键 scale 0.94 + accent.pressed | paused↔playing | 音频切换 |
| Drag progress | knob 放大；时间预览 | seeking | seek 完成续播/暂停意图 |
| Send danmaku | 乐观飞幕 ≤100ms 入轨 | persist timestampMS | 同源可 Live 见 |
| Tap cover | 轻微 dim | — | Live Tab |
| Tap venue | strip highlight | — | Live Tab（空标签亦可） |
| Tap「添加现场标签」弱文案 | — | 编辑 venueTag | 可仍进 Live |
| Toggle mode | chip icon 切换 | mode 持久 | 播完行为变 |
| Danmaku switch off | 飞幕层隐藏 | danmakuEnabled=false | 仍可发送入库 |

#### Animation
- 飞幕：右→左，时长 ~3–4s，提前 ~500ms 调度；轨道 y 错开  
- Play 键：spring 轻按  
- 进 Live：系统 Tab 切换即可（不做自定义 hero，除非低成本 matchedGeometry 可选）  
- Reduce Motion：飞幕改为静态淡入淡出或短距离移动  

---

### 5.3 S3 · Live

| 字段 | 内容 |
|---|---|
| Screen ID | `S3_Live` |
| Purpose | 沉浸现场感；**同一**时间戳弹幕用气泡呈现 |
| Hierarchy | 全屏模糊封面氛围 > 返回 > 气泡栈 > 输入栏 |
| Layout | |

```
全屏：
├── Background
│     优先：当前曲 cover 模糊放大（§13 Q1）
│     无封面：紫黑纵向渐变（#09060F → #2E1065 类）
├── Dim overlay 黑 35–45% 保文字对比
├── TopBar SafeArea
│     leading: Button chevron.left +「返回播放」 44hit
│     center/trailing: 可选极弱曲名 Caption（次要）
├── BubbleStack
│     锚定 bottom-left，距左 16，距输入栏上 12
│     宽 max 280；从下往上堆；上推
│     仅显示 timestampMS ≤ now 的最近 50 条（ASSUMPTION N=50）
│     每条：glass 黑半透 + 左侧 accent 色点 6Ø + 文本「我」弱标可选
├── InputBar 底 SafeArea
│     TextField + Send + smile → S5
└── TabBar（Live Tab 选中）
```

**禁止**：飘心、点空白出心、他人头像昵称墙。

#### Components

| Name | Role | Key size |
|---|---|---|
| `LiveBackground` | 模糊封面/渐变 | 全屏 |
| `LiveBackButton` | 回 Player | 高 44 |
| `DanmakuBubble` | 单条回忆 | 高自适应，r16，maxW 280 |
| `BubbleStackView` | 可见窗口 ≤50 | 底左 |
| `LiveInputBar` | 发送主入口 | 高 52 |
| `LiveEmptyTrack` | 无曲引导 | 中部 |

#### Primary CTA
发弹幕（输入栏 / Modal 短语）

#### Secondary CTA
返回播放；打开 DanmakuModal

#### Navigation
- ← Player（返回）  
- → S5 sheet  
- Tab → Playlist / Player  

#### States

| State | UI |
|---|---|
| First Use | N/A |
| Empty / NoTrack | 「先去歌单选一首现场录音」+ 按钮切 Playlist |
| EmptyDanmaku | 背景+输入；无气泡；弱提示「记下这一刻」一次即可 |
| Loading | N/A（跟播放引擎） |
| Loaded / PlayingSynced | 气泡随 clock 追加 |
| Error | 发送失败 toast + rollback 乐观气泡 |
| Offline | 正常（本地） |
| Disabled | 无曲时输入禁用 |
| Long Content | 气泡文本多行最多 4 行后 truncate；窗口 50 |
| Permission Denied | N/A |
| InputFocus | 键盘顶起 InputBar；气泡区上移 |
| Danmaku Off | 不绘气泡；仍可发送入库 |

#### Interaction

| User Action | Visual Feedback | State Change | Result |
|---|---|---|---|
| Send | 新气泡底入 + 轻 haptic | persist | Player 同源可飞 |
| Seek（在 Player 后切回） | 重建可见集 | window | ≤50 条 |
| Tap back | — | — | Player Tab |
| Tap smile | sheet present | — | S5 |
| Tap phrase in S5 | dismiss + bubble | send immediate | 入库 |

#### Animation
- 新气泡：offsetY 12→0 + opacity，220ms  
- 上推：其余气泡易位 200ms  
- 背景：进入 Live 时 blur 强度 0→20（可选，Reduce Motion 则静态）  
- **无**飘心粒子  

---

### 5.4 S4 · WifiImport

| 字段 | 内容 |
|---|---|
| Screen ID | `S4_WifiImport` |
| Purpose | 电脑批量上传；**流程 Keep，仅换肤** |
| Hierarchy | 说明 > URL > 配对码 > 状态/进度 > 权限失败 CTA |
| Layout | |

```
NavigationStack sheet or push
├── Nav：标题「Wi‑Fi 导入」；trailing 完成/关闭
├── Scroll padding 20
│     ├── 说明 Body：同一 Wi‑Fi 下用电脑浏览器打开下列地址
│     ├── URLCard glass r16 padding 16
│     │     大字可复制 URL；旁 Copy 按钮
│     ├── PairingCodeCard margin top 16
│     │     标题 Caption「配对码」；码 Display 32 Bold 等宽；首次教育文案
│     ├── StatusRow：ServerOn 绿点 / Uploading Progress / Error
│     └── PermissionDenied 块：说明 + Button「打开设置」
└── 离开页面 → serverOff（Keep）
```

#### Components
`WifiURLCard` · `PairingCodeView` · `ImportProgressList` · `LocalNetworkDeniedView`

#### Primary CTA
展示 URL + 配对码（自动开服）

#### Secondary CTA
复制 URL；打开系统设置（权限拒时）；关闭页

#### Navigation
仅从 Playlist 进入；Dismiss → 停服

#### States

| State | UI |
|---|---|
| First Use | 配对码教育一句：「浏览器首次需输入配对码」 |
| Empty | N/A |
| Loading | 「正在开启服务…」Progress |
| ServerOn / Loaded | URL + 码清晰可复制 |
| Uploading | 文件名 + ProgressView |
| Error | 文案「无法获取局域网地址」等 + 重试 |
| Offline / no LAN IP | 明确不可用说明 |
| Permission Denied | CTA 去设置 |
| Disabled | N/A |
| Long Content | 上传列表可滚 |

#### Interaction
进入 → auto serverOn；复制 → toast「已复制」；离开 / background → serverOff；上传完成 → 库刷新（回 Playlist 可见）。

#### Animation
Progress 系统默认；无装饰动效。

---

### 5.5 S5 · DanmakuModal（Should Have）

| 字段 | 内容 |
|---|---|
| Screen ID | `S5_DanmakuModal` |
| Purpose | 固定快捷短语/表情，降低输入摩擦 |
| Hierarchy | 标题 > 短语网格 > 表情行 |
| Layout | |

```
.sheet detents: medium（可选 large）
bg.elevated
├── Grabber
├── Title「快捷弹幕」20 Bold，padding 16
├── PhraseGrid：2 列，spacing 12，padding 16
│     每格 glass r12 高 ~44，Body 文案
│     建议写死 6–8 条（CH-13）：
│       「起鸡皮疙瘩了」「副歌太绝了」「泪目」
│       「这段神仙」「安可！！」「好想再去一次」
│       「灯光美」「声音封神」
├── EmojiRow 可选 6–8 个常用，圆触 44
└── 点短语/表情 = **立即发送**并 dismiss（ASSUMPTION）
```

#### Primary CTA
点短语立即发送

#### Secondary CTA
下滑 / 关闭 dismiss（不发送）

#### Navigation
Present from Live（Must 入口）；Player smile（Should）

#### States
Presented / Dismissed；无曲时不应打开或打开后提示

#### Interaction
Tap phrase → haptic light → optimistic UI on parent → persist → dismiss  

#### Animation
系统 sheet；格子 press opacity。

---

## 6. Component System（可复用）

| Component | Used in | Spec |
|---|---|---|
| `AccentButton` | Play、Empty CTA、权限 CTA | 实心 `accent`，pressed `accent.pressed`，白字，r full 或 16，minH 48 |
| `GlassChip` | Mode、Venue strip、Phrase cell | `ultraThinMaterial` + stroke 白 10% |
| `TrackRow` | S1 | 见 §5.1 |
| `MiniPlayerBar` | S1 | 左 cover 40、中 title/artist、右 play/pause 44；bg glass |
| `DanmakuInputBar` | S2/S3 | TextField + send；optional smile |
| `DanmakuFlyText` | S2 | 近白字，可选 accent 描边 0.5 |
| `DanmakuBubble` | S3 | 黑 55% + material；左色点 accent |
| `ProgressBar` | S2 | track 白 15% fill，played 白 90%；knob 白 |
| `SectionCard` | S4 | elevated + r16 + padding 16 |
| `EmptyStateView` | S1/S2/S3 | icon + title + primary button |
| `Toast` | 全局 | 底中，2s，错误用 Error 色 |

**不做组件**：LikeButton、FloatingHeart、AvatarStack、ConcertMemoryForm、SetlistDrawer。

---

## 7. Design Tokens

### 7.1 Color

```swift
// LoveSongTheme tokens — codeable
let bgStage        = Color(hex: 0x09060F) // bg.stage
let bgElevated     = Color(hex: 0x0E0A17) // bg.elevated
let accent         = Color(hex: 0x8B5CF6) // Primary accent
let accentPressed  = Color(hex: 0x7C3AED)
let textPrimary    = Color.white
let textSecondary  = Color.white.opacity(0.64)
let textTertiary   = Color.white.opacity(0.40)
let border         = Color.white.opacity(0.10)
let error          = Color(hex: 0xFF453A) // system-like
let success        = Color(hex: 0x30D158)

// Glass fills / borders
let glassFill      = Color.white.opacity(0.06)
let glassFillStrong = Color.white.opacity(0.10)
let glassBorder    = Color.white.opacity(0.12)
let bubbleFill     = Color.black.opacity(0.55)
let dimOverlay     = Color.black.opacity(0.40)

// Danmaku
let danmakuFly     = Color.white.opacity(0.92)
let danmakuFlyStroke = accent.opacity(0.35)

// REMOVE — do not use as primary accent anywhere
// #FF8A3D (warm orange spotlight) — EXPLICITLY REMOVED
```

| Token | Value | Usage |
|---|---|---|
| Primary | `#8B5CF6` | Play、Tab selected、强调、色点 |
| Background | `#09060F` | 主舞台 |
| Surface | `#0E0A17` | 卡片、sheet、elevated |
| Text | `#FFFFFF` | 主文案 |
| Secondary Text | `#FFFFFF` @ 64% | 艺术家、说明 |
| Border | `#FFFFFF` @ 10–12% | 玻璃描边、分割 |
| Error | `#FF453A` | toast / 失败 |
| Success | `#30D158` | ServerOn 点 |
| **REMOVE** | `#FF8A3D` | 全量退出主强调 |

### 7.2 Typography（SF Pro）

| Role | Size | Weight | SwiftUI |
|---|---|---|---|
| Display | 32 | Bold | `.system(size: 32, weight: .bold)` |
| Title | 22 | Bold / Semibold | 导航、曲名 |
| Title Small | 20 | Semibold | Sheet 标题 |
| Body | 16 | Regular | 正文、短语、气泡 |
| Body Emph | 16 | Medium | 行标题 |
| Caption | 12–13 | Regular | 时长、次要、Tab |
| Mono Display | 32 | Bold | 配对码（`.monospacedDigit()`） |

Dynamic Type：优先 `@ScaledMetric` 或 `.font(.body)` 语义字体；封面固定尺寸可例外。

### 7.3 Spacing scale

`4 / 8 / 12 / 16 / 20 / 24 / 32`  
常用：屏边 16–20；组件间距 12–16；区块 24；大分隔 32。

### 7.4 Radius

| Token | pt |
|---|---|
| r8 | 8 |
| r12 | 12（row、chip、search） |
| r16 | 16（card、bubble、phrase） |
| r24 | 24（cover） |
| full | Capsule / 圆形 Play |

### 7.5 Glass + Shadow recipes（SwiftUI）

```swift
// Glass control
.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
.overlay(
  RoundedRectangle(cornerRadius: 12, style: .continuous)
    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
)

// Cover shadow
.shadow(color: Color.black.opacity(0.45), radius: 24, y: 12)

// MiniPlayer / Tab alternative solid
.background(bgElevated.opacity(0.92))
```

Play 键：**实心 accent**，不必强制 material（层级更清晰）。

---

## 8. Interaction Specification（核心流）

### F1 空库导入 → 首播 → 首发弹幕

1. S1 Empty →「导入现场录音」→ 选文件 → Importing → Loaded  
2. Tap row → Player Tab + playing  
3. 输入「起鸡皮疙瘩了」→ Send → ≤100ms 飞幕右→左 + 入库 `timestampMS`  
4. Result：回忆闭环起步  

### F2 Wi‑Fi 批量导入

1. S1 → Wi‑Fi → S4 ServerOn  
2. 电脑打开 URL + 配对码 → Uploading → 完成  
3. Dismiss S4 → serverOff；S1 列表刷新  

### F3 Player ↔ Live 同源

1. Playing 中 tap cover/venue → Live  
2. 已触发弹幕以气泡可见（≤50）  
3. Live 再发 → 气泡入；回 Player 同时间点可飞幕重放  

### F4 快捷短语

1. Live smile → S5  
2. Tap「副歌太绝了」→ 立即发送 + dismiss（不经输入框）  

### F5 断点续播

1. 杀进程 → 再开 → 恢复 track、positionMS、mode、danmakuEnabled  

### F6 弹幕关闭

1. 用户关弹幕 → Player/Live **不绘制**  
2. 仍可发送并持久化（ASSUMPTION）  

---

## 9. Motion Specification

| 场景 | 动效 | 时长 / 曲线 | Reduce Motion |
|---|---|---|---|
| Tab 切换 | 系统 | — | 系统 |
| Play 键 | scale 0.94 spring | 120–160ms | 仅颜色 pressed |
| 飞幕 | 右→左平移 | ~3.5s linear | 淡入静止 ~1.2s 后淡出 |
| 新气泡 | fade+rise | 220ms easeOut | 仅 fade |
| MiniPlayer 出现 | slide up | 250ms | 瞬切 |
| Sheet S5 | 系统 present | — | 系统 |
| 行插入 | fade | 200ms | 瞬切 |
| 进 Live 背景 blur | optional | 300ms | 静态模糊图 |

**原则**：不为氛围加循环粒子/飘心。密度：飞幕同屏 ≤5。

---

## 10. State Specification（矩阵）

| 状态 | S1 Playlist | S2 Player | S3 Live | S4 Wi‑Fi | S5 Modal |
|---|---|---|---|---|---|
| First Use | Empty CTA | — | — | 配对教育 | — |
| Empty | 导入引导 | NoTrack CTA | 回歌单引导 | — | — |
| Loading | skeleton | buffering opt | — | 开服中 | — |
| Loaded/Success | 列表 | 播控+飞幕 | 气泡同步 | URL+码 | 短语网格 |
| Error | 导入 toast | 播放失败 toast | 发送 rollback | 无 IP/失败 | — |
| Offline | 本地可用 | 本地可用 | 本地可用 | 不可用说明 | — |
| Permission Denied | 文件权限 alert | N/A | N/A | 本地网络 CTA | N/A |
| Disabled | — | 无曲弱化控件 | 无曲禁用输入 | — | 无曲不打开 |
| Long Content | truncate List | 标题截断；弹幕 80 字 | 气泡 4 行；窗 50 | 上传列表滚 | 短语固定短 |
| Returning | 列表+Mini | 断点续播 | 跟随进度 | 码保持至离页 | — |
| Danmaku Off | — | 隐藏飞幕可发 | 隐藏气泡可发 | — | 仍发送入库 |
| Importing | banner/progress | — | — | Uploading | — |
| Searching | 过滤/无结果 | — | — | — | — |

---

## 11. Accessibility

### Dynamic Type
- 文案用语义字体（body/caption/title）；封面、Play 56、进度条高度可固定。  
- 大字号下：Venue strip 与 InputBar 允许增高；Transport 保持 44pt 触控。

### Contrast
- 白字 @ 舞台黑：达标。  
- `textSecondary` 64% 仅用于非关键；关键 CTA 用实心紫+白。  
- Live 必须有 dim overlay，避免亮封面吃白字。

### Touch
- 所有可点 ≥ 44×44 pt（Play 56、字号按钮扩 hitSlop）。

### VoiceOver labels（建议）

| 控件 | label |
|---|---|
| Tab 歌单 | 歌单 |
| Tab 播放 | 播放 |
| Tab 现场 | 现场 |
| Play | 播放 / 暂停 |
| Mode | 播放模式，当前：顺序/单曲循环/随机 |
| Venue strip | 现场标签，{tag}，进入现场 |
| Venue empty | 添加现场标签，仍可进入现场 |
| Danmaku input | 弹幕输入框 |
| Send | 发送弹幕 |
| Smile | 快捷弹幕 |
| Wifi | Wi‑Fi 导入 |
| Plus | 导入本地音频 |
| Bubble | 弹幕：{text} |
| Fly text | 可 accessibilityHidden 或简述「弹幕」以免刷屏 |

### Reduce Motion
见 §9；飞幕降级为淡入淡出。

---

## 12. DEV Handoff

### 12.1 页面结构（SwiftUI 暗示）

```swift
TabView(selection: $tab) {
  NavigationStack { PlaylistView() } // S1
    .tabItem { Label("歌单", systemImage: "list.music") }
  PlayerView() // S2
    .tabItem { Label("播放", systemImage: "opticaldisc") }
  LiveView() // S3
    .tabItem { Label("现场", systemImage: "bubble.left.and.bubble.right") }
}
.tint(accent) // CH-10
// MiniPlayer: overlay on Playlist only, above tab
// Wifi: .sheet from Playlist
// DanmakuModal: .sheet from Live/Player
```

### 12.2 组件层级（例：Player）

```
PlayerView
├── ZStack(bg.stage)
│   ├── VStack
│   │   ├── toolbar list → playlist tab
│   │   ├── CoverArtCard
│   │   │   └── DanmakuFlyLayer  // CH-02
│   │   ├── Title / Artist
│   │   ├── VenueGlassStrip → live tab  // CH-12
│   │   ├── ProgressBar
│   │   ├── HStack ModeChip · Prev · PlayPause · Next
│   │   └── DanmakuInputBar  // §13 Q2
│   └── NoTrackPlaceholder
```

### 12.3 CH-xx 映射（实现核对表）

| CH | 设计落地 | UI Spec 位置 |
|---|---|---|
| **CH-01** | 数据模型不改；发送/重放仍 `trackId+timestampMS`；UI 不表现多人 | §2 P4, §8 F3, 全屏弹幕交互 |
| **CH-02** | Player 封面右→左飞幕层保留并换肤 | §5.2 DanmakuFlyLayer |
| **CH-03** | 本地导入入口在 Playlist Nav `plus` | §5.1 Secondary CTA |
| **CH-04** | Wi‑Fi Keep；**仅** Playlist 入口；S4 换肤 | §5.1, §5.4 |
| **CH-05** | 播控/后台/锁屏不改交互契约；Play 视觉换紫 | §5.2 Transport |
| **CH-06** | ModeChip = 三态；Resume 无新 UI | §5.2 ModeChip, §8 F5 |
| **CH-07** | 列表+搜索视觉 = Playlist glass rows | §5.1 |
| **CH-08** | 三 Tab IA + Copy 歌单/播放/现场 | §3, §5.0 |
| **CH-09** | 新 Live Tab：模糊封面+气泡+输入 | §5.3 |
| **CH-10** | Token 全量黑紫白；**REMOVE `#FF8A3D`** | §7 |
| **CH-11** | 大紫 Play 56 + 毛玻璃 venue/mode/input | §5.2, §6 |
| **CH-12** | venue 条（及封面）进 Live；空标签弱「添加现场标签」仍可进 | §5.2 VenueGlassStrip |
| **CH-13** | S5 写死 6–8 短语；点即发 | §5.5 |
| **CH-14** | 弱化 Overlay；MiniPlayer → 切 Player Tab | §3, §5.1 MiniPlayer |
| **CH-15** | **不设计** Like | §14 |
| **CH-16** | **不设计** 飘心 | §14 |
| **CH-17** | **不设计** 多人头像昵称 | §14 |
| **CH-18** | **不设计** ConcertMemoryModal | §14 |
| **CH-19** | **不设计** SetlistDrawer | §14 |
| **CH-20** | **不设计** 设计画板/桌面壳 | §14 |

### 12.4 Spacing / Type / Color
严格按 §7；列表 row 72、cover 290 max、play 56、progress track 6。

### 12.5 States / Interactions / Animation
实现 §5 各屏 States + §8 + §9；弹幕 Off = 隐藏显示可写（ASSUMPTION）。

### 12.6 Assets
- 以 **SF Symbols** 为主：`list.music`, `opticaldisc`, `bubble.left.and.bubble.right`, `wifi`, `plus.circle.fill`, `play.fill`, `pause.fill`, `backward.fill`, `forward.fill`, `repeat`, `repeat.1`, `shuffle`, `face.smiling`, `chevron.left`, `list.bullet`  
- 无曲/空态可用 SF `opticaldisc` 大号，不必新插画  
- 封面来自曲库；无则 LinearGradient 紫黑  

### 12.7 明确技术收敛
- 删除/停用 FullPlayerOverlay 作为主路径（CH-14）  
- Live 订阅同一 clock；可见气泡窗口 50；seek 重建  
- Theme 一次清扫 Tab/Nav/Progress tint，防橙残留  

---

## 13. TEST Handoff

### 交互元素清单
- Tab ×3；S1：+、wifi、search、row、MiniPlayer、Empty CTA  
- S2：play、prev/next、seek、mode、venue、cover、input、send、smile、list  
- S3：back、bubbles（只读）、input、send、smile  
- S4：copy URL、close、打开设置  
- S5：phrase cells、emoji、dismiss  

### 必须测的状态变化
- Empty→Imported→Playing→Danmaku sent→Replay ±300ms  
- Player→Live sync→send→back→fly  
- Danmaku off：无绘制但仍入库  
- Seek 密集区：飞幕密度 ≤5；气泡 ≤50  
- 切歌：两屏可视弹幕清空并换调度  
- Wi‑Fi：进开服、出停服、Permission Denied CTA  
- 杀进程恢复：曲/进度/模式/开关  
- 无封面：渐变占位  
- venue 空：弱「添加现场标签」仍可进 Live  

### 跳转
见 §3 表；确认 **无** Overlay 第三播放器。

### 错误 / 边缘
导入失败 toast；播放失败；发送 rollback；无 LAN IP；空格弹幕忽略；超长 80 字截断。

### a11y 风险
- 飞幕 VoiceOver 刷屏 → hidden 或合并  
- Live 对比度（亮封面）→ 检查 dim  
- 触控：mode chip、smile、venue 弱文案  

### Drop 回归（AC-Drop）
全局搜 UI：**无** Like、飘心、他人头像、ConcertMemory、Setlist。

---

## 14. Out of Scope / 参考里有但本轮不做

- [ ] Like / 喜欢态  
- [ ] 浮动飘心 / 点空白出心  
- [ ] 多人昵称、头像、用户列表  
- [ ] ConcertMemoryModal（tour/date/seat/notes/lightstick）  
- [ ] SetlistDrawer  
- [ ] 设计画板 / 桌面导入 Web 壳搬进 iOS  
- [ ] 流媒体 / 推荐 / 积分徽章  
- [ ] 无时间戳的纯聊天数据模型  
- [ ] 去掉 Wi‑Fi 导入（**禁止删**）  
- [ ] 多主题切换器  
- [ ] 弹幕颜色/字号/速度个性化（旧 F11）  
- [ ] 回忆墙 / 导出长图 / iCloud / AirPlay / 歌词  
- [ ] FullPlayerOverlay 作为主播放体验保留  
- [ ] 假「多人直播」实时会话  

---

## 15. DESIGN QUESTIONS

None — following §0 / §13 defaults.

（已采纳：Live 背景封面模糊；Player 常驻简输入；Overlay 弱化；空 venue 弱入口仍可进 Live；弹幕关=只藏显示；短语点按即发；气泡窗 50。）

---

## 16. Design Review checklist（自答：砍了什么）

| 检查 | 结果 |
|---|---|
| 是否去掉不必要元素？ | 是：Like、飘心、头像墙、手账、Setlist、暖橙主强调、第三 Overlay |
| Clarity > Decoration？ | 是：大紫键与进度优先；玻璃仅分层 |
| 产品逻辑被静默改动？ | 否：时间戳模型 Keep；Wi‑Fi Keep；ASSUMPTION 仅对齐 §12/§13 |
| 参考「直播聊天」误导？ | 已用气泡皮肤包装同源弹幕，禁止多人社区语义 |
| DEV 能否不看 music-UI？ | 是：本文件含 IA、布局 pt、组件、Token、状态、交互、CH 映射 |
| iPhone 15 / 44pt / Dynamic Type / Reduce Motion？ | 已写入 §5 / §7 / §11 |
| 中文 Copy 就绪？ | 歌单/播放/现场；我的歌单；导入现场录音；添加现场标签；返回播放 |
| CH-15…20 未漏进视觉？ | §14 checklist 全勾不做 |

---

## Appendix A · Copy Sheet（产品文案）

| Key | ZH |
|---|---|
| tab.playlist | 歌单 |
| tab.player | 播放 |
| tab.live | 现场 |
| playlist.title | 我的歌单 |
| playlist.empty.title | 还没有现场录音 |
| playlist.empty.cta | 导入现场录音 |
| playlist.empty.wifi | Wi‑Fi 从电脑导入 |
| playlist.search | 搜索歌曲或现场 |
| venue.add | 添加现场标签 |
| live.back | 返回播放 |
| live.emptyTrack | 先去歌单选一首现场录音 |
| live.emptyDanmaku | 记下这一刻 |
| player.noTrack | 去歌单选一首 |
| danmaku.placeholder | 发弹幕… |
| modal.title | 快捷弹幕 |
| wifi.title | Wi‑Fi 导入 |
| wifi.pair | 配对码 |
| wifi.pair.hint | 浏览器首次需输入配对码 |
| wifi.denied | 需要本地网络权限才能导入 |
| wifi.openSettings | 打开设置 |

## Appendix B · Phrase pack（S5 默认）

1. 起鸡皮疙瘩了  
2. 副歌太绝了  
3. 泪目  
4. 这段神仙  
5. 安可！！  
6. 好想再去一次  
7. 灯光美  
8. 声音封神  

---

**下一跳**：DEV 按 §12 CH 表改 `main`；TEST 按 §13 + Change Spec §11 AC 验收。
