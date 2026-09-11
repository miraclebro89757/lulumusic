# LoveSong UI Spec · 1:1 Visual Patch（像素真理补丁）

| 项 | 内容 |
|---|---|
| 产品 | LoveSong（演唱会录音本地播放 + 弹幕回忆） |
| 文档 | **UI Spec · 1:1 Visual Patch**（相对 `UI-SPEC-lovesong-ui-refresh.md` v1.0） |
| 日期 | 2026-09-11 |
| 设备 | iPhone 15 逻辑约 **390×844 pt**（实现以 Safe Area 为准；文中 pt 按 390 宽换算） |
| 上游产品 | `/workspace/lulumusic-prd/CHANGE-SPEC-lovesong-ui-refresh.md` + `/workspace/lulumusic-prd/CHANGE-SPEC-lovesong-ui-1to1-amend.md` |
| 上游视觉（被本补丁覆盖冲突项） | `/workspace/lulumusic-prd/UI-SPEC-lovesong-ui-refresh.md` v1.0 |
| 像素真理源 | `/workspace/lulumusic-prd/reference-screens/01-player.png`（744×1316） · `02-live.png`（778×1354） · `03-danmaku-modal.png`（744×1358） · `04-playlist.png`（768×1330） |
| 素材 | `/workspace/music-UI/src/assets/images/album_night_we_met_1789098894760.jpg` · `concert_live_stage_1789098877222.jpg` |
| 作者 | Senior iOS Product Designer（IOS UI） |
| 交接 | IOS DEV → IOS TEST |
| 目标 | DEV **必须按参考 PNG 1:1 落地**；禁止按 v1.0「简化版」或 music-UI 代码猜测重绘 |

---

## 0. Authority（效力声明）

**真理源优先级（高 → 低）**：

1. **参考 PNG 像素布局**（`reference-screens/*.png`）— 本补丁所描述的视觉即 PNG 的可执行翻译  
2. **本 1:1 Visual Patch** — 冲突时覆盖 UI Spec v1.0 的简化视觉决策  
3. **Change Spec Amend（1to1）** — 产品冻结表 A01–A15  
4. **Change Spec v1.0 / UI Spec v1.0** — 未点名条款仍有效（时间戳弹幕、Wi‑Fi、私密本地等）  
5. music-UI 仓库代码猜测 — **最低**；不得用代码反推覆盖 PNG  

**用户否决「近似还原」**。本文件标题即约束：**1:1 Visual Patch — DEV must implement**。  
**禁止**：简化、省略控件、用 mode chip 顶替心形、把 Playlist Tab 排到最左、用 sheet 网格替掉居中毛玻璃 Modal、在 Player 参考帧强行加常驻弹幕底栏（见 §6 ASSUMPTION）。

**换算约定**：参考图约 **~1.9×** 逻辑屏。下文同时给 **相对屏宽/屏高比例** 与推荐 **pt @390 宽**。Safe Area / Dynamic Island / Home Indicator 必须遵守；装饰发光可略柔，但 **结构、控件、文案、顺序不得缺**。

---

## 1. Design Direction

**一句话**：按 `reference-screens` 四张 PNG **1:1 还原**黑紫白毛玻璃舞台（叠层封面、紫心、现场实况 pill、HQ、左下头像气泡壳、居中弹幕 Modal、歌单大卡 +「返回当前播放」），产品行为仍锚定时间戳弹幕与私密本地。

---

## 2. Global Diff vs UI Spec v1.0（关键）

| 主题 | UI Spec v1.0 | 本 1:1 Patch（PNG 真理） | 效力 |
|---|---|---|---|
| Tab 顺序 L→R | 歌单 / 播放 / 现场 | **播放器 / 现场弹幕 / 歌单** | **VOID v1.0 顺序** |
| Tab Copy | 歌单 · 播放 · 现场 | **播放器 · 现场弹幕 · 歌单** | **VOID** |
| Tab 选中态 | 仅 tint 紫字/紫标 | **紫色胶囊/pill 包住 icon+label**；白字白标；软紫 glow | **Override** |
| Player 顶栏 | trailing 歌单 list | **L：紫实心点 +「Live Memory」+ 副文「Concert · 日期」；R：⋮** | **Override** |
| 封面 | 单卡 ≤290 r24 | **叠层双卡**：主卡大圆角 ~24–28pt + 后卡右上窥出；舞台照 | **Override** |
| 封面角标 | 无 | **右上玻璃暗 pill「现场实况」+ 小紫 ping 点** | **Must 新增** |
| 曲名位置 | 封面下 TitleBlock | **叠在封面底 overlay**：波形条 + 标题 + 艺术家 | **Override** |
| 进度 knob | 白圆 | **紫渐变填充末端 → 明亮白 knob + 紫 glow** | **Override** |
| Transport | mode chip \| prev \| play \| next | **实心紫心(+glow) \| SkipBack \| 大紫 Play(~52–56)+强外光 \| SkipForward \| 横 ⋯** | **VOID「无 Like」** |
| Venue 条 | 文本/弱「添加现场标签」 | **L：Activity 图标紫方块；「Live · 日期」+ 场馆；R：HQ 描边 pill** | **Override** |
| Player 常驻弹幕输入 | **常驻** DanmakuInputBar | **参考帧无底栏输入**；发送走 Live / Modal | **Diff · ASSUMPTION 跟 PNG** |
| Live 顶栏 | 「返回播放」文案按钮 | **圆形玻璃 back chevron**；R：玻璃 pill「● Live • 日期」+ divider + expand | **Override** |
| Live 气泡 | 色点 + 可选「我」弱标 | **胶囊气泡：圆形彩色字母头像 + username + text**（壳 1:1） | **Override 视觉；数据仍仅自己** |
| Live 输入 | 简输入 | **玻璃 pill「发一条弹幕...」；L smile outline；R 实心紫圆 send（纸飞机）** | **Override** |
| 飘心环境 | Drop | 本参考帧 **无**；可省略 | 与 Amend 一致 |
| S5 Modal | medium sheet + 短语网格 6–8 | **居中大圆角(~32) 毛玻璃 Modal**；心形圆钮 + 紫光边输入 + send；横 chips 4 条；底 smile/bubble/keyboard | **VOID sheet 网格布局** |
| S5 短语 | 起鸡皮疙瘩了… | **现场封神 / 万人大合唱 / 这首直接泪目 / 永远的经典** | **Override Copy** |
| S1 Playlist | Nav+Search+List+MiniPlayer | **居中大玻璃卡「我的歌单」+ Concert · N + 圆形 +**；行；卡下全宽 **「返回当前播放」** | **Override 主视觉壳**（导入/Wi‑Fi 能力 Keep，入口可落在 + / ⋯） |
| MiniPlayer | Playlist 底 Must | 参考帧 **未展示** MiniPlayer；能力可保留但不挡 1:1 主卡 | Soft — 不挡像素验收 |
| Like / Heart | **不设计**（CH-15） | **视觉 Must**；产品见 §14 Q-A | **VOID「不做 Like 控件」** |
| 多人头像 | **不设计**（CH-17） | **UI 壳 Must**；数据见 §14 Q-B | **VOID「不做头像壳」** |


---

## 2.1 Amend A01–A15 对齐表（强制）

上游：`CHANGE-SPEC-lovesong-ui-1to1-amend.md`。本补丁视觉与下表 **一一对应**；DEV/TEST 按 ID 勾选。

| ID | 项 | 本 Spec 落点 | 状态 |
|---|---|---|---|
| **A01** | Tab `播放器\|现场弹幕\|歌单` + 紫胶囊 | §2 Diff · §4 C0 | Must |
| **A02** | 紫心两态 + 本机 `isLiked` | §5 Player Heart · §13 已冻结 A2 | Must |
| **A03** | 叠层封面卡 | §5 StackedCover | Must |
| **A04** | 「现场实况」pill | §5 LivePill | Must |
| **A05** | Live Memory 头 | §5 Header | Must |
| **A06** | venue 毛玻璃条 + HQ；点→现场弹幕 | §5 VenueStrip | Must |
| **A07** | 大紫播放键+柔光；切歌；⋯ | §5 Transport | Must |
| **A08** | 气泡壳头像+昵称+文；数据仅自己 | §6 Live Bubbles | Must |
| **A09** | Live 顶：圆返回 + Live pill + 展开 | §6 TopBar | Must |
| **A10** | Live 输入：微笑+占位+紫发送 | §6 Input | Must |
| **A11** | Modal Must；四 chips 原图文案；点心/chip 即发后关 | §7 Modal | Must |
| **A12** | 我的歌单大卡；+；当前曲紫描边 | §8 Playlist | Must |
| **A13** | 「返回当前播放」 | §8 Return button | Must |
| **A14** | 时间戳/Wi‑Fi/私密 | §10 Keep | Keep |
| **A15** | 真多人社区/账号 | Forbidden · §14 | Forbidden |

**禁止省略**：爱心、HQ、现场实况（用户/Amend 明文）。  
**禁止做成社交产品**：无账号、无他人弹幕入库、无喜欢云同步。

---

## 3. Token Overrides（相对 v1.0 §7）

v1.0 Token 基线保留；下列为 **1:1 强化 / 补样**（自参考视觉采样意图，非实验室测色仪；DEV 以观感对齐 PNG）：

| Token | Value | Usage |
|---|---|---|
| `bg.stage` | `#09060F` | 全屏舞台底 |
| `bg.elevated` | `#0E0A17` | 抬升面 / Modal 底倾向 |
| `accent` | `#8B5CF6` | 主紫（心、Play、Tab pill、波形、边光） |
| `accent.bright` | `#A855F7` | 渐变高端 / 更亮紫高光 |
| `accent.pressed` | `#7C3AED` | 按下 |
| `accent.glow` | `#8B5CF6` @ ~40–55% blur | Play / Heart / Tab active / 进度 knob 外光 |
| `text.primary` | `#FFFFFF` | 主文案 |
| `text.secondary` | `#FFFFFF` @ ~58–64% | 副文、艺术家、未选 Tab |
| `text.tertiary` | `#FFFFFF` @ ~40% | 提示、Modal 灰 hint |
| `glass.fill` | 白 @ 6–10% + `.ultraThinMaterial` | 输入 pill、venue、气泡、歌单卡、Modal |
| `glass.border` | 白 @ 10–14% | 描边 |
| `tab.active.fill` | 紫半透胶囊（accent @ ~28–40%）+ soft glow | C0 选中 |
| `progress.track` | 白 @ ~12–16% | 细轨 |
| `progress.fill` | 紫渐变 `accent → accent.bright` | 已播 |
| `progress.knob` | **纯白** + 紫 glow | 末端圆钮（比 v1.0 更「亮」） |
| `live.ping` | accent 实心小圆 + 可选脉冲 | 「现场实况」点 |
| `hq.border` | 白 @ ~35–50% 描边 pill | HQ 徽章 |
| `row.active` | 紫 tint 底 + 紫 border/glow | 歌单当前行 |
| **REMOVE** | `#FF8A3D` | 仍禁止作主强调 |

### Typography（1:1 倾向）

| Role | Size @390 | Weight | 用途 |
|---|---|---|---|
| Header Title | 17–18 | Bold / Semibold | 「Live Memory」 |
| Header Sub | 12–13 | Regular | 「Concert · 2025.08.16」 |
| Cover Title | 18–20 | Bold | 封面底「The Night We Met」 |
| Cover Artist | 13–14 | Regular | 「Lord Huron」 |
| Time Mono | 11–12 | Regular + monospacedDigit | `2:34` / `5:12` |
| Bubble Name | 12–13 | Semibold | 用户名 |
| Bubble Body | 14–15 | Regular | 弹幕正文 |
| Tab Label | 10–11 | Medium | Tab 文案 |
| Card Title | 20–22 | Bold | 「我的歌单」 |
| Modal Hint | 12–13 | Regular | 灰提示 |
| Chip | 13–14 | Medium | 快捷短语 |

### Radius Overrides

| Token | pt | 用途 |
|---|---|---|
| `rCover` | **24–28** | 主封面卡（取 26 可） |
| `rModal` | **32** | Danmaku Modal / 歌单大卡 |
| `rPill` | Capsule | Tab active、输入、现场实况、HQ、chips、返回当前播放 |
| `rBubble` | **18–22** Capsule-ish | Live 气泡 |
| `rAvatar` | full | 气泡字母头像 ~28–32 Ø |
| `rPlay` | full | Play ~52–56 Ø；Send ~40–44 Ø |

### Glow Recipes（必须有观感，非可选装饰）

```
PlayButton:
  fill = accent
  shadow(color: accent.opacity(0.55), radius: 16–22, y: 0)

HeartFilled:
  fill = accent
  soft glow same family, weaker than Play

ProgressKnob:
  fill = white
  shadow(color: accent.opacity(0.5), radius: 8–12)

TabActivePill:
  fill = accent.opacity(0.32–0.40)
  optional blur glow behind

ActivePlaylistRow:
  stroke accent 1–1.5pt + accent fill ~12%
```

---

## 4. C0 · Tab Bar 1:1

| 字段 | 内容 |
|---|---|
| Screen ID | `C0_TabBar` |
| 参考 | 四张 PNG 底栏一致 |
| Purpose | 全局三 Tab；选中紫胶囊 |

### Order & Copy（L→R，不可改）

| Index | ID | 中文 | Icon（视觉） | SF Symbol 建议 |
|---|---|---|---|---|
| 0 | `player` | **播放器** | 碟片/唱片环 | `opticaldisc`（fallback `record.circle`） |
| 1 | `live` | **现场弹幕** | 方形气泡/对话 | `bubble.left.and.bubble.right` 或 `ellipsis.message` |
| 2 | `playlist` | **歌单** | 列表+音符 | `list.bullet` + 音符感：`music.note.list` / `list.music` |

**VOID**：v1.0 `歌单 | 播放 | 现场` 与 Playlist-first IA 叙述中的 Tab 顺序。

### Visual

| 态 | 表现 |
|---|---|
| Active | **紫色胶囊/pill** 包裹 icon+label；**白** icon + **白** text；软紫 glow |
| Inactive | **灰** icon+text（`text.secondary`）；无填充 |
| Bar | **Frosted dark**（`ultraThinMaterial` 或 `bg.elevated` 高不透明）+ 顶部分割线弱 |

### Layout @390

- Tab bar 内容区高约 **49** + Home Indicator  
- Active pill 水平 padding ~12–16；垂直 ~6–8；corner = Capsule  
- Icon ~22–24；Label Caption ~10–11；icon↔label spacing ~2–4  
- 三等分或光学均分；**中项「现场弹幕」文案较长，勿截成「现场」**（可用略紧 tracking，禁止改词）

### Interaction

- Tap → 切 Tab；播放不中断；Live/Player 共享 `PlayerEngine`  
- Haptic light 可选  

---

## 5. S2 · Player 1:1

| 字段 | 内容 |
|---|---|
| Screen ID | `S2_Player` |
| 参考 | `/workspace/lulumusic-prd/reference-screens/01-player.png`（744×1316） |
| Purpose | 主播放面：叠层封面回忆舞台 + 大紫键 + 紫心 + venue/HQ |

### Layout Recipe（top → bottom，@390×844）

```
bg.stage 全屏
SafeArea top
├── HeaderBar ~44–48pt  H padding 16–20
│     L: HStack(spacing 8)
│          · Dot 8Ø solid accent
│          · VStack(alignment: .leading, spacing 2)
│               「Live Memory」 17–18 Bold white
│               「Concert · 2025.08.16」 12–13 secondary
│     R: Button ⋮ (ellipsis) 44hit  secondary/white
├── Spacer ~12–16
├── CoverStack  水平居中
│     宽 ≈ 0.72–0.78 × screenWidth → ~280–304pt
│     高 ≈ 同宽（近方）或按素材
│     ├── RearCard：同图/紫暗层，offset(+10…16, -10…16) 右上窥出；略大或同大；低透明/暗化
│     └── MainCard：r 24–28 continuous；强阴影
│           ├── Artwork = concert stage 照（或曲封面）
│           ├── TopTrailing Pill：「现场实况」
│           │     glass dark capsule；L 小紫 ping Ø4–6；padding H10–12 V5–6；字 11–12
│           ├── Optional DanmakuFlyLayer（产品 Keep：右→左时间戳飞幕；密度≤5）
│           └── BottomOverlay（渐变黑底 → 透明）
│                 · mini waveform 紫条 × N（矮 12–16pt 高）
│                 · Title「The Night We Met」Bold
│                 · Artist「Lord Huron」secondary
├── Spacer ~16–20
├── ProgressBlock  H padding 24–28
│     HStack: timeElapsed mono | Spacer | timeRemaining/total mono
│     Track 高 3–4pt；fill 紫渐变；末端 WHITE knob Ø12–14 + purple glow
│     例：2:34 · 5:12
├── TransportRow  高 ~56–64；margin top 14–18；H 均分光学
│     [Heart 44hit] [SkipBack 44] [Play 52–56Ø] [SkipForward 44] [⋯ 44]
│     Heart: FILLED purple + glow（liked）；unlike = 描边紫心（两态）
│     Play: solid accent circle；白 play/pause；STRONG outer glow
│     Skip / ⋯: 白/浅灰 SF
├── VenueGlassStrip  高 ~44–48；H margin 16–20；margin top 16–20
│     glass pill/rounded-16
│     L: 紫方底 ~28–32 内 Activity/pulse SF（`waveform.path.ecg` / `bolt.heart` 类）
│     Mid: VStack
│          「Live · 2025.08.16」 Caption emph
│          「Madison Square Garden」 Body/subhead
│     R: 「HQ」 bordered pill（描边白/浅紫，小字 Bold）
├── （本参考帧）NO persistent DanmakuInputBar
└── C0_TabBar（播放器 active）
```

### Components（Must）

| Name | 1:1 要求 |
|---|---|
| `LiveMemoryHeader` | 紫点 + 双行标题；R ⋮ |
| `StackedCoverCards` | 后卡窥出 + 主卡 r24–28 |
| `LiveStatusPill` | 「现场实况」+ ping |
| `CoverMetaOverlay` | 波形 + title + artist |
| `GlowProgressBar` | 细轨 + 紫渐变 + 白光 knob |
| `LikeHeartButton` | 实心紫心 + glow；可点 |
| `PlayPauseGlowButton` | 52–56 Ø + 强外光 |
| `TransportEllipsis` | 横 ⋯ |
| `VenueGlassStrip` | 图标方块 + Live 文案 + 场馆 + HQ |
| `DanmakuFlyLayer` | 产品 Keep（可与 PNG 同帧叠加） |

### Primary / Secondary CTA

- Primary：Play / Pause  
- Secondary：Heart toggle；prev/next；⋮ / ⋯ 菜单；venue → Live Tab；封面点按 → Live Tab（Change Spec Keep）

### ASSUMPTION · Player 无常驻输入

- **PNG `01-player.png` 无底部弹幕输入条**。  
- 相对 v1.0「常驻输入」：**本补丁跟参考 → Player 不画 persistent input**。  
- 发送路径：**Live 底栏** 与 **S5 Modal**（从 Live smile / Modal 入口）。  
- 若 Product 强令 Player 也要发：优先在 ⋮/⋯ 或次要入口打开 S5，**不要**破坏本帧 1:1 底栏留白。  
- 封面飞幕重放（CH-01/02）**Keep**。

### States（视觉）

| State | UI |
|---|---|
| Playing | Pause icon；飞幕按 clock；Heart 保持态 |
| Paused | Play icon |
| Liked | 实心紫心 + glow |
| Unliked | 描边紫心（仍清晰可见） |
| NoTrack | 占位渐变卡 + CTA 去歌单（结构仍尽量保留壳） |
| Seeking | knob 跟随；glow 可略加强 |

### Interaction（要点）

| Action | Result |
|---|---|
| Tap Heart | 切换 liked 视觉；持久化策略见 §14 Q-A |
| Tap Play | 播/停；键 scale 弹簧 |
| Drag progress | seek；松手续意图态 |
| Tap venue / cover | → Live Tab（同曲同进度） |
| Tap ⋮ / ⋯ | 菜单：至少保留进歌单 /（Should）Wi‑Fi 或模式等；**勿用 mode chip 替换心形槽位** |

---

## 6. S3 · Live 1:1

| 字段 | 内容 |
|---|---|
| Screen ID | `S3_Live` |
| 参考 | `/workspace/lulumusic-prd/reference-screens/02-live.png`（778×1354） |
| Purpose | 全屏沉浸；左下多气泡壳呈现同源时间戳弹幕 |

### Layout Recipe

```
全屏 Background
├── Full-bleed concert photo（紫舞台光束 + 人群）
│     优先：曲封面/现场图；可用 asset concert_live_stage_*.jpg
├── Dim 黑 ~30–45%（保字对比）
├── TopBar SafeArea  H 16–20
│     L: Circular glass back 44Ø — chevron.left
│     R: Glass pill
│          「● Live • 8.16」（红/亮点 + 文案）
│          + thin divider
│          + expand / maximize SF（`arrow.up.left.and.arrow.down.right`）
├── BubbleStack  左下锚定
│     left inset ~12–16；bottom 在输入条之上 ~12–16
│     宽 max ~0.78×screen → ~300pt
│     自下而上；新消息上推
│     每条 Capsule glass：
│       [Avatar Ø28–32 彩色圆 + 字母] [VStack/HStack name + text]
│     参考名壳（演示镍铬）：Luna👑, 阿哲, 小鱼, Sky, 静静, Dreamer, 小橙子
│     ★ 产品数据规则见 §14 Q-B（默认真实数据一律「我」）
├── InputBar 底 SafeArea 上 ~8–12；H 16
│     Glass pill 高 ~48–52
│     L: smile outline button 44hit
│     Mid: placeholder「发一条弹幕...」
│     R: solid purple circular send Ø36–40 — paperplane.fill 白
└── C0_TabBar（现场弹幕 active）
```

### Components

| Name | 1:1 |
|---|---|
| `LiveBackCircle` | 玻璃圆 back |
| `LiveStatusExpandPill` | Live 点 + 日期 + expand |
| `DanmakuAvatarBubble` | 圆头像字母 + 名 + 文 |
| `LiveComposerPill` | smile + field + 紫 send |

### 禁止 / 可选

- **本参考帧无**环境浮动爱心 → 默认 **omit**（与 Amend「飘心仍默认不做」一致）  
- **禁止**真实多人社区后端、他人弹幕入库  

### Interaction

| Action | Result |
|---|---|
| Back | → Player Tab |
| Expand | ASSUMPTION：可进更沉浸/隐藏 Tab 或全屏背景；若未定，先做无破坏布局的 no-op / 同 Live 强化，不挡 AC |
| Smile | → S5 Modal |
| Send | 乐观气泡 + persist `timestampMS`；显示名按 Q-B |
| Chip/Phrase from S5 | 立即发送（Amend ASSUMPTION：发后关 Modal） |

### 数据呈现（壳 vs 真）

- UI **必须**支持 `avatarCircle + displayName + text` 布局（对齐 PNG）。  
- 默认：**真实评论仅自己** → `displayName = "我"` + accent/派生色字母头像。  
- 不得把假用户写入 DB。演示 seed 仅当 Product 显式允许（Q-B）。

---

## 7. S5 · Danmaku Modal 1:1

| 字段 | 内容 |
|---|---|
| Screen ID | `S5_DanmakuModal` |
| 参考 | `/workspace/lulumusic-prd/reference-screens/03-danmaku-modal.png`（744×1358） |
| Priority | **Must**（VOID v1.0「Should + medium sheet 网格」） |

### Layout Recipe

```
Scrim: 模糊/变暗的 Player（或下层）背景
Center Modal:
  width ≈ 0.86–0.90 × screen → ~336–350pt
  cornerRadius ≈ 32
  frosted dark material + glass border
  padding ~16–20

├── TopRow
│     L: X close 44hit
│     R: grey hint「发弹幕参与现场互动」12–13
├── ComposerRow  margin top 16
│     L: Circular purple HEART button Ø40–44（bordered + glow）
│     Mid: Pill input — purple GLOWING border；placeholder「发一条弹幕...」
│     R: Solid purple send circle Ø40–44（paperplane）
├── ChipsRow  horizontal scroll/wrap  margin top 14–16
│     glass dark pills:
│       现场封神 | 万人大合唱 | 这首直接泪目 | 永远的经典
├── FooterIcons  trailing/right cluster  margin top 16–20
│     smile | speech.bubble | keyboard   灰色
└── 底层仍可见 C0_TabBar（现场弹幕 active）— 与 PNG 一致
```

### Interaction

| Action | Result |
|---|---|
| X / scrim | dismiss，不发送 |
| Heart（Modal） | ASSUMPTION：与 Player Heart 同 liked 态或触发一次轻反馈；**不要**做成社交赞列表 |
| Send / Return | 发送当前输入；ASSUMPTION 成功后 dismiss |
| Tap chip | **立即发送该短语**并 dismiss（Amend） |
| Footer smile/bubble/keyboard | ASSUMPTION：smile=表情面板轻量；bubble=焦点输入；keyboard=系统键盘 — 至少保证键盘可唤起；未做面板不挡 Must 结构 |

### VOID vs v1.0 S5

- ❌ `.sheet` medium + 2 列短语网格 + 标题「快捷弹幕」作为主形态  
- ❌ 默认短语包「起鸡皮疙瘩了 / 副歌太绝了 …」作为主 chip 文案  
- ✅ 改为 PNG 居中 Modal + 上列四句 chips  

（若需保留更多短语，可进二次面板；**首屏四句必须与 PNG 一致**。）

---

## 8. S1 · Playlist 1:1

| 字段 | 内容 |
|---|---|
| Screen ID | `S1_Playlist` |
| 参考 | `/workspace/lulumusic-prd/reference-screens/04-playlist.png`（768×1330） |
| Purpose | 选歌；大玻璃卡列表；返回当前播放 |

### Layout Recipe

```
bg.stage
SafeArea
├── Centered large Glass Card
│     width ≈ 0.88–0.92 × screen → ~344–360pt
│     cornerRadius ≈ 32
│     padding 16–20
│     ├── HeaderRow
│     │     VStack L:
│     │       「我的歌单」20–22 Bold
│     │       「Concert · 3」 secondary（N = 曲数）
│     │     R: circular + button Ø32–36（导入入口）
│     └── Rows spacing 10–12
│           Active row:
│             purple border/glow + purple tint fill
│             thumb with play overlay
│             title / artist / duration / ⋯
│           Inactive rows:
│             glass row；cover art r10–12；title；artist；duration；⋯
├── Below card（margin top 16–20）
│     Full-width glass pill button「返回当前播放」
│     height ~48–52；H margin 与卡对齐或略宽满
└── C0_TabBar（歌单 active）
```

### Components

| Name | 1:1 |
|---|---|
| `PlaylistGlassCard` | 大卡 r32 |
| `PlaylistCardHeader` | 标题 + Concert · N + + |
| `PlaylistTrackRow` | active/inactive 两态 |
| `ReturnToNowPlayingButton` | 「返回当前播放」 |

### Product Keep（能力，不挡视觉）

- **本地导入**：主入口 = 卡头 **+**（与 PNG）  
- **Wi‑Fi 导入**：Must Keep（Change Spec）；放在行 ⋯ / 卡 ⋯ / + 的菜单次级 — **不得删除能力**  
- 搜索：参考帧未强调；可保留手势/菜单入口，但 **主视觉先 1:1 大卡**，勿强制 Nav+Search 压过 PNG  
- MiniPlayer：参考帧未画；可选保留在 Tab 上，验收以卡+按钮+Tab 为准  

### Interaction

| Action | Result |
|---|---|
| Tap row | 设 currentTrack；play；可自动切播放器 Tab |
| Tap + | 本地文件导入（系统 picker） |
| Tap ⋯ | 行菜单：venue 编辑 / Wi‑Fi / 删除等（现有能力） |
| Tap「返回当前播放」 | **selectedTab = player**；聚焦当前/最近曲（Amend A13） |

---

## 9. Asset Requirements

### Raster（必须拷入 App 资源）

| Source | Suggested asset name | Usage |
|---|---|---|
| `/workspace/music-UI/src/assets/images/album_night_we_met_1789098894760.jpg` | `album_night_we_met` | 预览/占位专辑；封面 overlay 演示 |
| `/workspace/music-UI/src/assets/images/concert_live_stage_1789098877222.jpg` | `concert_live_stage` | Player 叠层主图 / Live 全屏底 |

真机用户导入封面优先；上述为 **1:1 预览与空态示范**。

### SF Symbols Mapping（推荐）

| UI 元素 | Symbol |
|---|---|
| Tab 播放器 | `opticaldisc` |
| Tab 现场弹幕 | `bubble.left.and.bubble.right` / `ellipsis.message` |
| Tab 歌单 | `music.note.list` |
| Header ⋮ | `ellipsis` |
| Heart | `heart.fill` / `heart` |
| SkipBack / Forward | `backward.fill` / `forward.fill` |
| Play / Pause | `play.fill` / `pause.fill` |
| Transport ⋯ | `ellipsis` |
| Venue activity | `waveform.path.ecg` 或 `chart.bar.fill` |
| Live back | `chevron.left` |
| Live expand | `arrow.up.left.and.arrow.down.right` |
| Smile | `face.smiling` |
| Send | `paperplane.fill` |
| Modal close | `xmark` |
| Modal footer bubble | `bubble.left` |
| Keyboard | `keyboard` |
| Playlist + | `plus` |
| Row play overlay | `play.fill` |
| HQ | Text「HQ」（非 SF） |

---

## 10. Interaction Still from Change Spec（未矛盾则 Keep）

| 项 | 状态 |
|---|---|
| CH-01 时间戳 `trackId+timestampMS` ±300ms | **Keep** |
| CH-02 Player 飞幕右→左 | **Keep**（叠在封面之上） |
| CH-03/04 本地 + Wi‑Fi 导入 | **Keep**（入口视觉服从 PNG） |
| CH-05/06 播控/后台/锁屏/模式/断点 | **Keep**（模式 UI 勿占心形位；可进 ⋯） |
| CH-08/09 三 Tab + Live | **Keep IA**；文案/顺序/选中态按本补丁 |
| CH-10 黑紫白 | **Keep** + 本 Token 强化 |
| CH-12 venue → Live | **Keep** |
| CH-13 快捷短语 | **Keep 行为**；文案/容器改本补丁四句+Modal |
| CH-14 无第三 Overlay 主路径 | **Keep** |
| CH-15/17 | **视觉改判** → 见 Amend + §14；非社交后端 |
| CH-18/19/20 手账/Setlist/画板 | 仍 Defer/Drop |
| 私密本地、无账号广场 | **Keep** |

---

## 11. DEV Implementation Checklist

### C0 Tab

- [ ] 顺序 L→R：播放器 | 现场弹幕 | 歌单  
- [ ] 文案三词完整  
- [ ] Active = 紫胶囊 + 白字标 + soft glow  
- [ ] Frosted dark bar  

### S2 Player（`01-player.png`）

- [ ] Live Memory 头 + 紫点 + Concert 日期 + ⋮  
- [ ] 叠层封面 + 现场实况 pill + 底波形/标题/艺术家  
- [ ] 进度细轨 + 紫渐变 + 白光 knob  
- [ ] Heart | Back | Play(glow) | Forward | ⋯  
- [ ] Venue 玻璃条 + HQ  
- [ ] **无** PNG 外的常驻底输入（除非 Product 否决 ASSUMPTION）  
- [ ] 飞幕层仍接 CH-01/02  

### S3 Live（`02-live.png`）

- [ ] 全出血现场图 + dim  
- [ ] 圆玻璃 back；右 Live pill + expand  
- [ ] 气泡壳 avatar+name+text  
- [ ] 输入 pill + smile + 紫纸飞机 send  
- [ ] Tab=现场弹幕  
- [ ] 数据仅自己时间戳；显示名策略 Q-B  

### S5 Modal（`03-danmaku-modal.png`）

- [ ] 居中 r32 毛玻璃，非 v1.0 sheet 网格主形态  
- [ ] X + hint；心形圆钮；紫光边输入；紫 send  
- [ ] 四 chips 文案一致  
- [ ] 底 smile / bubble / keyboard  
- [ ] Tab 可见且 Live active  

### S1 Playlist（`04-playlist.png`）

- [ ] 大玻璃卡 + 我的歌单 + Concert · N + +  
- [ ] Active 行紫边光 + play overlay  
- [ ] 「返回当前播放」全宽 pill  
- [ ] Wi‑Fi 能力仍可达  
- [ ] Tab=歌单  

### CH Conflicts to wire

| Conflict | DEV 默认 |
|---|---|
| Heart vs CH-15 Drop | **做控件**；**A02 本机 `isLiked` 持久化** |
| Avatar bubbles vs CH-17 Drop | **做壳**；仅「我」；不 seed 假用户入库（A08） |
| Player 常驻输入 vs v1.0 | **跟 PNG：不做常驻条** |
| Tab 顺序/文案 | **跟本补丁** |
| S5 形态/短语 | **跟本补丁** |

---

## 12. TEST · Visual AC（Screenshot Compare）

对照设备：iPhone 15 逻辑宽 ~390；允许系统字体/Safe Area ±2–4pt；**不允许缺控件或改 Tab 文案顺序**。

### AC-V1 Player ↔ `01-player.png`

- [ ] 顶栏 Live Memory + 紫点 + 副标题 + ⋮  
- [ ] 叠层封面右上窥出  
- [ ] 「现场实况」pill + ping  
- [ ] 封面底波形 + 曲名 + 艺术家  
- [ ] 时间码 + 细进度 + 白光 knob  
- [ ] 紫心 + 大紫 Play 外光 + 两侧 skip + ⋯  
- [ ] Venue 条含 HQ  
- [ ] 底 Tab：播放器为紫胶囊选中；文案三词正确  
- [ ] 无错误的常驻弹幕底栏（与 PNG 一致）  

### AC-V2 Live ↔ `02-live.png`

- [ ] 全屏现场底图氛围  
- [ ] 圆 back；右 Live pill + expand  
- [ ] 左下多条胶囊气泡（头像圆+名+文）布局存在  
- [ ] 底输入「发一条弹幕...」+ smile + 紫 send  
- [ ] Tab 现场弹幕选中  
- [ ] 无强制环境飘心  

### AC-V3 Modal ↔ `03-danmaku-modal.png`

- [ ] 居中大圆角毛玻璃卡  
- [ ] 心形圆钮 + 发光边输入 + send  
- [ ] 四 chips 文案  
- [ ] 底三灰标  
- [ ] 下层 Tab 仍见且 Live active  

### AC-V4 Playlist ↔ `04-playlist.png`

- [ ] 居中大卡标题区 + +  
- [ ] Active 行紫强调  
- [ ] 「返回当前播放」  
- [ ] Tab 歌单选中  

### AC-P Product regression

- [ ] 弹幕入库仍 `timestampMS`；重放 ±300ms  
- [ ] Wi‑Fi 导入仍可用  
- [ ] 无真实社交/他人弹幕泄漏  
- [ ] Heart：两态 + 本机 `isLiked` 持久化（A02）  
- [ ] 气泡壳 1:1 但作者均为「我」（A08）  

---

## 13. DESIGN QUESTIONS

### Q-A · Heart（相对 Change Spec CH-15 / Amend A02）

用户要求 1:1 实心紫心。产品曾 Drop Like。

| 选项 | 说明 |
|---|---|
| A1 | 纯视觉 session toggle，杀进程丢失 |
| A2 | 本机 `liked: Bool` 持久化，不社交不同步（Amend 倾向） |
| A3 | 完整喜欢列表/云同步 — **禁止本轮** |

**已冻结（Amend A02）**：**A2** — 本机 `isLiked: Bool` 持久化（Track 或本地键）；可点两态（描边 ↔ 实心紫+glow）；杀进程仍在。  
不做喜欢 Tab、不做分享、不做他人可见、不同步。Q-A 不再开放。

### Q-B · Live 气泡多人壳（相对 CH-17 / Amend A08）

PNG 为多用户头像+昵称壳；产品仅自己评论。

| 选项 | 说明 |
|---|---|
| B1 | 布局支持 avatar+name；真实数据一律「我」+ 单一/派生 accent 头像 |
| B2 | 额外允许 Product 批准的 **demo seed** 假名气泡（不入库或标记 mock） |
| B3 | 假多人真数据 — **禁止** |

**已冻结（Amend A08）**：**B1**。布局 = 圆头像+昵称+文案；`displayName = "我"`；`avatarColor` 由 color 或固定紫派生。  
禁止假多用户入库；禁止可切换「他人」资料。Q-B 不再开放。

---

## 14. Explicit：v1.0 现已 VOID 的条款

下列 UI Spec v1.0 表述 **对视觉实现作废**（产品未点名 Keep 的行为条款仍有效）：

1. Tab Copy/顺序「歌单 / 播放 / 现场」及 Playlist-first Tab 索引叙述（§3 / §5.0 / Appendix A tab.*）  
2. Tab 选中「仅 accent 着色、无胶囊」  
3. Player「无 Like / 心形槽位；用 mode chip 平衡」（§5.2）  
4. Player 顶栏 trailing「歌单 list」为主头（改为 Live Memory 头）  
5. 单层封面 ≤290、曲名在封面外 TitleBlock 的简化结构（改为叠层 + 封面内 overlay）  
6. Player **常驻** `DanmakuInputBar` 作为该参考帧必选项（§5.2 / §13 Q2 视觉结论）— 以 PNG 为准  
7. Live 气泡「仅色点、禁止头像昵称墙」的 **视觉**禁令（§5.3）— 改为壳 1:1；数据禁令仍在  
8. Live 顶「返回播放」文字主按钮形态（改为玻璃圆 chevron）  
9. S5 作为 Should 的 medium sheet 短语网格 + 旧八句主包（§5.5 / Appendix B 作为主 UI）  
10. S1 以 Nav+Search+标准 List+MiniPlayer 为唯一主壳（§5.1）— 主壳改大卡+返回当前播放  
11. §6「不做组件：LikeButton、Avatar…」— **LikeHeart 与 AvatarBubble 壳改为要做**  
12. §12.3 CH-15/17「不设计」— 改为按本补丁 + Amend 设计视觉  
13. §14 Out of Scope 中「Like / 多人昵称头像」作为 **零像素** 禁令 — **改为允许 1:1 视觉**；社交后端仍禁止  
14. Design Direction v1.0「去掉一切社交壳」之 **字面清掉心形与头像壳** — 被用户 1:1 要求否决  

**仍有效**：时间戳模型、Wi‑Fi Must、私密本地、无账号广场、无 ConcertMemory/Setlist 本轮、暖橙移除、无第三全屏 Overlay 主路径。

---

## 15. Copy Sheet Patch（覆盖 v1.0 Appendix A 冲突项）

| Key | ZH（1:1） |
|---|---|
| tab.player | 播放器 |
| tab.live | 现场弹幕 |
| tab.playlist | 歌单 |
| player.header | Live Memory |
| player.header.sub | Concert · {date} |
| player.livePill | 现场实况 |
| player.hq | HQ |
| live.composer.placeholder | 发一条弹幕... |
| live.pill | ● Live • {date} |
| modal.hint | 发弹幕参与现场互动 |
| modal.chip.1 | 现场封神 |
| modal.chip.2 | 万人大合唱 |
| modal.chip.3 | 这首直接泪目 |
| modal.chip.4 | 永远的经典 |
| playlist.title | 我的歌单 |
| playlist.subtitle | Concert · {n} |
| playlist.return | 返回当前播放 |
| bubble.selfName | 我 |

---

## 16. Handoff 一句话

**DEV：按四张 `reference-screens` PNG + 本文 pt/比例配方落地；冲突以 PNG 与本文为准，废除 v1.0 简化视觉。TEST：用 §12 截图对照清单验收。PRD：尽快终答 §13 Q-A / Q-B。**

---

**文档结束 · UI Spec 1:1 Visual Patch**
