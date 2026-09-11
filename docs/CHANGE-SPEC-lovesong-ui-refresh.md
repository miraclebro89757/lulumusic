# LoveSong 改动规格 · UI Refresh → 可执行 MVP

| 项 | 内容 |
|---|---|
| 产品 | LoveSong（演唱会录音本地播放 + 弹幕回忆） |
| 版本 | Change Spec v1.0（相对现网 main ≈ 6fb8230） |
| 日期 | 2026-09-11 |
| 设备 | iPhone 15 |
| 仓库 | https://github.com/miraclebro89757/lulumusic |
| 参考 UI | https://github.com/miraclebro89757/music-UI（视觉/交互真理源；产品行为以本规格为准） |
| 旧 PRD | `/workspace/lulumusic-prd/PRD-lovesong.md` |
| 作者 | IOS PRD |
| 交接对象 | IOS UI → IOS DEV → IOS TEST |
| 状态标签用法 | **Designed** = 本规格已定；**Implemented** = 现网代码已有；**Verified** = 测试已覆盖（真机另标） |

---

## 0. PRODUCT CONCERNS（主动挑战）

### C1 · 弹幕形态冲突（时间戳飞幕 vs 直播聊天流）

- **问题**：参考 UI 的 Live 是「多人聊天气泡上推」；现网/旧 PRD 是「trackId+毫秒时间戳锚定、右→左飞过封面重放」。二者不是同一产品。
- **原因**：聊天流默认暗示实时多人社区；时间戳飞幕才是「半年后同一拍点回忆重访」的成立条件。
- **影响**：若照抄直播聊天、丢掉时间戳模型，核心差异化死亡，产品退化为普通本地播放器 + 假社区皮。
- **推荐方案**：
  - **产品行为（不可让）**：继续 `trackId + timestampMS` 本地存储与重放（±300ms）。
  - **呈现分层**：
    - **Player**：封面区继续右→左经典飞幕（回忆播放器本体）。
    - **Live**：同一数据源，用左下聊天气泡流呈现「沉浸现场感」；气泡按当前播放进度显示已到达时间戳的弹幕（上推），发送仍锚定当前毫秒。
  - **禁止**：多人昵称广场、他人弹幕、无时间戳的纯会话日志。
- **MVP 替代**：不做「假多人」；自己的气泡可标「我」+ 可选色点，无头像上传。

### C2 · Like / 飘心 / 多人昵称头像

- **问题**：私密本地 App 里 Like、环境飘心、多用户头像是直播壳，不是回忆闭环。
- **原因**：无账号/无同步时 Like 无结果态；飘心无记忆价值；多人身份与「弹幕只有自己可见」冲突。
- **影响**：加了会膨胀交互与状态，偏离 MVP；用户误以为有社交。
- **推荐方案**：
  - **Drop**：Like / 喜欢态持久化。
  - **Drop**：多人昵称 + 头像系统（mock 里的多 user 仅属设计稿）。
  - **Defer**：点空白飘心（纯装饰）。若 UI 极低成本可做一次性动画且不入库，标 Optional；默认本轮不做。
- **MVP 替代**：用「发弹幕」作为唯一情感表达；Live 发送成功可有轻反馈（toast / 轻微 haptic），不做心形系统。

### C3 · ConcertMemoryModal / SetlistDrawer

- **问题**：参考有完整「巡演手账」表单与 Setlist 抽屉；现网仅有 `venueTag` 字符串。
- **原因**：手账字段（tour/seat/lightstick…）不是核心路径成立条件；选歌已被 Playlist 覆盖。
- **影响**：本轮做完整手账 = 扩 P1/P2。
- **推荐方案**：
  - **Keep / 轻增强**：`venueTag` 继续作为现场标签；Playlist 行展示 venue（有则显示）。
  - **Defer**：ConcertMemoryModal 全字段（tour/date/seat/notes/lightstick）→ P1。
  - **Defer**：SetlistDrawer → Playlist Tab 已覆盖「选歌回 Player」。
- **MVP 替代**：长按/编辑入口仅允许改 `venueTag`（可沿用现有编辑能力，不新增手账页）。

### C4 · Wi‑Fi 导入（参考没有，现网已有）

- **问题**：参考原型几乎无 Wi‑Fi 导入；现网 F02 已 Implemented。
- **原因**：演唱会录音体积大、批量从电脑进手机是 P0 成立条件（旧 PRD US-1）。参考是视觉壳，不是导入方案。
- **影响**：若因「参考没有」删掉，批量导入路径断裂，产品不可用。
- **推荐方案**：**Keep Must Have**。入口放在 **Playlist（我的歌单/演唱会回忆）**，不进设计画板。
- **MVP 替代**：无。本地文件/AirDrop 不能替代批量 30×200MB 场景。

### C5 · 主题暖橙 → 黑紫白

- **问题**：现网舞台近黑 + 追光橙 `#FF8A3D`；参考黑底 `#09060f/#0e0a17` + 紫 `#8b5cf6` + 白字 + 毛玻璃。
- **原因**：视觉刷新，非功能。
- **影响**：全量换肤触及 Theme / Tab tint / 弹幕强调色 / 播放键；需统一 Token，避免半橙半紫。
- **推荐方案**：**本轮全量换肤（Designed）**。暖橙退出主强调；紫色为唯一 accent。波形/弹幕强调跟新 Token。
- **MVP 替代**：不做多主题切换器；只保留一套黑紫白。

---

## 1. 产品目标（一句话）+ Not-Do

**目标**：在不动核心「本地导入 → 播放 → 时间戳弹幕回忆」闭环的前提下，把 LoveSong 的信息架构与视觉对齐新参考 UI（三 Tab：播放 / 现场 / 歌单），让 UI/DEV/TEST 可直接改现网。

**Not-Do（本轮）**

- ❌ 社交 / 他人弹幕 / 账号 / 分享广场
- ❌ Like、飘心系统、多用户头像昵称
- ❌ ConcertMemory 完整手账、SetlistDrawer
- ❌ 流媒体 / 推荐 / 积分徽章
- ❌ 为视觉新增无时间戳的聊天数据模型
- ❌ 去掉 Wi‑Fi 导入
- ❌ 扩 P2（回忆墙/导出长图/iCloud/AirPlay/歌词）
- ❌ Web 壳「全景设计画板 / 桌面导入工具」搬进 iOS

---

## 2. 现网 vs 目标 · 屏幕 / 流程地图

### 2.1 现网（Implemented）

```
Tab: 演唱会回忆(Library) | 播放(Player)
+ FullPlayerOverlay（从 MiniPlayer morph）
+ WebUploadView（回忆页 Wi‑Fi 入口）
弹幕：仅 Player 封面右→左飞幕 + 底栏输入
主题：#0A0A0C + #FF8A3D
```

状态标签：F01–F10 **Implemented**；逻辑测试 **Verified**（LoveSongTests + verify 脚本）；真机 **Not Verified**。

### 2.2 目标 IA（Designed · 本轮）

```
Bottom Tab（MobileTab）
├── Playlist  我的歌单 / 演唱会回忆
│     列表 · 搜索 · 本地导入 · Wi‑Fi 导入 · 选歌 → 切到 Player 并播放
├── Player    播放
│     封面叠层 · 右→左时间戳飞幕 · 进度 · 大紫播放键 · 模式
│     点封面或 venue 条 → Live
│     右上 / 便捷入口 → Playlist
└── Live      现场沉浸
      全屏现场图/封面模糊放大 · 左下气泡流（同源时间戳弹幕）
      底栏输入 · 微笑 → DanmakuModal（快捷短语/表情，轻量）
      返回 → Player
```

**相对现网增删改**

| 项 | 动作 | 说明 |
|---|---|---|
| Tab 结构 | **Change** | 2 Tab → 3 Tab：`playlist` / `player` / `live` |
| Library 命名 | **Change** | 「演唱会回忆」视觉上对齐「我的歌单」，能力保留 |
| Live Tab | **Add** | 新屏；弹幕呈现变体，数据模型不变 |
| FullPlayerOverlay | **Change/Simplify** | Player 本身即为主播放面；MiniPlayer 仅在 Playlist 底栏保留（可选 morph）。避免「Tab Player + Overlay」双播放器 |
| 飞幕 | **Keep** | Player 封面 |
| 气泡流 | **Add** | Live only，同源数据 |
| Wi‑Fi 导入 | **Keep** | 入口挪到 Playlist |
| Like / 飘心 / 多人身份 | **Drop** | |
| ConcertMemory / Setlist | **Defer** | |
| 主题 | **Change** | 全量黑紫白 |

### 2.3 核心用户路径（冻结）

```
START（有曲）
→ Playlist 选歌
→ Player 播放（State: playing）
→ 需要记回忆：输入弹幕 → 飞幕出现 + 入库（timestampMS）
→ 想沉浸：进 Live → 同进度气泡出现/可继续发
→ 半年后重听同曲 → 同时间点飞幕/气泡再次出现
→ Result：回忆闭环成立

START（空库）
→ Playlist Empty → 本地导入 or Wi‑Fi 导入
→ 导入成功列表可见 → 选歌进入上路径
```

---

## 3. 逐条 Change（Keep / Change / Drop / Defer）

| ID | 项 | 判定 | 用户理由 | 状态 |
|---|---|---|---|---|
| CH-01 | 时间戳弹幕数据模型 `trackId+timestampMS` | **Keep** | 产品成立条件 | Implemented → 保持 |
| CH-02 | Player 封面右→左飞幕 | **Keep** | 回忆播放器本体视觉 | Implemented → 保持并换肤 |
| CH-03 | 本地/AirDrop 导入 F01 | **Keep** | 基础获取路径 | Implemented |
| CH-04 | Wi‑Fi 导入 F02 | **Keep** | 批量演唱会录音刚需；参考无 ≠ 产品无 | Implemented；入口改 Playlist |
| CH-05 | 播放控制/后台/锁屏 F04–F05 | **Keep** | 听歌基线 | Implemented |
| CH-06 | 状态记忆 F09 / 三态模式 F10 | **Keep** | 断点续播与模式 | Implemented |
| CH-07 | 曲库列表+搜索 F08 | **Keep** | 选歌 | Implemented；视觉改 Playlist |
| CH-08 | IA → 三 Tab | **Change** | 对齐参考；分离「选歌 / 播放 / 沉浸」 | Designed |
| CH-09 | 新增 Live Tab | **Change/Add** | 参考核心沉浸面；呈现变体不改模型 | Designed |
| CH-10 | 主题黑紫白全量换肤 | **Change** | 参考视觉真理源 | Designed |
| CH-11 | Player 大紫播放键 + 毛玻璃控件 | **Change** | 参考主操作层级 | Designed |
| CH-12 | venue 条点击进 Live | **Change** | 参考动线；强化「现场」入口 | Designed |
| CH-13 | DanmakuModal 快捷短语/表情 | **Change**（轻量） | 降低输入摩擦；对应旧 P1 F15 的最小集 | Designed（短语可先写死 6–8 条） |
| CH-14 | MiniPlayer / Overlay 关系 | **Change** | 避免双播放器；Playlist 保留底栏迷你条 | Designed |
| CH-15 | Like | **Drop** | 无私密结果态 | — |
| CH-16 | 飘心系统 | **Drop**（默认） | 装饰无回忆价值 | Optional Defer |
| CH-17 | 多人昵称/头像 | **Drop** | 与私密弹幕冲突 | — |
| CH-18 | ConcertMemoryModal | **Defer** | 非核心路径；venueTag 足够 | Future/P1 |
| CH-19 | SetlistDrawer | **Defer** | Playlist Tab 已覆盖 | Future |
| CH-20 | 设计画板/桌面导入壳 | **Drop**（产品面） | 非 iOS 产品能力 | — |

---

## 4. MVP 范围冻结表

### Must Have（本轮必须交付）

1. 三 Tab：Playlist / Player / Live  
2. 黑紫白 Token 全量替换暖橙主题  
3. Player：封面飞幕 + 进度 + 紫实心主播放键 + 模式切换  
4. Live：全屏沉浸 + 同源时间戳气泡流 + 底栏发送  
5. Playlist：列表/搜索/本地导入/Wi‑Fi 导入/选歌播  
6. 弹幕发送与重放行为与现网一致（误差 ±300ms）  
7. 状态记忆与后台锁屏继续可用  

### Should Have（本轮尽量，可砍不影响成立）

1. DanmakuModal：固定快捷短语 + 少量表情（不接自定义短语管理）  
2. Live / Player 共享当前曲与进度，切换无重载卡顿感  
3. Playlist 行强化 venueTag 展示  

### Future / Defer

- ConcertMemory 手账全字段  
- SetlistDrawer  
- Like / 飘心  
- 弹幕颜色/字号/速度个性化（旧 F11）  
- 长录音分段（F14）、回忆墙/导出（F17–F18）等 P2  

### 核心用户 / 场景 / 路径（宪章）

- **1 用户**：自己（现场录音收藏者）  
- **1 场景**：重听演唱会录音时记下/重访瞬间感受  
- **1 路径**：导入 → 播放 → 发时间戳弹幕 → 重听重现（Live 为同路径的沉浸皮肤）  

---

## 5. 关键状态机

### 5.1 播放 Playback

```
idle ──play──▶ playing ──pause──▶ paused
playing ──seek──▶ seeking ──▶ playing/paused（保持 seek 前意图）
playing ──trackEnd──▶ next | loopSame | stop（依 mode）
any ──killApp──▶ resume(trackId, positionMS, mode, danmakuEnabled)
```

States：`idle | playing | paused | buffering(optional) | failed`  
Mode：`sequential | singleLoop | shuffle`（Keep）

### 5.2 Live

```
Player ──tapCover|tapVenue──▶ Live(enter)
Live ──back|tabPlayer──▶ Player
Live 始终绑定 currentTrack + currentTimeMS
无 currentTrack ──▶ Live Empty（引导去 Playlist）
```

### 5.3 弹幕 Danmaku

```
发送：
  editing ──send(nonEmpty)──▶ optimisticShow + persist(trackId, timestampMS=nowPlayingMS)
  失败 ──▶ rollback UI + Error toast（本地写库几乎不失败；磁盘满等）

重放：
  onClock(t) ──▶ schedule comments where timestampMS ∈ (t, t+lookahead]
  Player：入轨右→左（提前 ~500ms，1–3 轨道，密度上限 5）
  Live：追加气泡并上推（只显示 timestampMS ≤ t 的已触发集；seek 回退则重建可见集）

开关：
  danmakuEnabled=false ──▶ 两屏均不绘制；仍允许入库？→ 否，隐藏输入或发送时提示已关闭（Keep 现网语义：关闭=不显示；建议关闭时仍可发送并存储，默认 Adopt：关闭仅隐藏显示）
```

**ASSUMPTION**：弹幕关闭 = 仅隐藏显示，发送仍写入（避免用户关掉显示后丢回忆）。若现网相反，DEV 以「关闭仍可写」为准并改齐。

### 5.4 导入 Import

```
Playlist ──localPicker──▶ importing ──success──▶ libraryUpdated
Playlist ──wifiPage──▶ serverOn(auto) ──upload──▶ progress ──done──▶ libraryUpdated
leave wifiPage|background ──▶ serverOff
pairing required on first browser session
```

States：`idle | picking | importing | serverOn | uploading | error | permissionDenied(localNetwork)`

---

## 6. Screen List + Spec（MVP）

### S1 · Playlist（原演唱会回忆）

| 字段 | 内容 |
|---|---|
| Screen ID | `S1_Playlist` |
| Purpose | 选听什么；导入 |
| Entry | 底栏 Tab；Player 右上 |
| Primary Action | 点行播放并跳转/聚焦 Player |
| Secondary | 搜索；本地导入；Wi‑Fi 导入；编辑 venueTag（若已有） |
| Content | 封面缩略图、标题、艺术家、venueTag、时长 |
| States | Empty / Loading / Populated / Searching / Importing |
| Navigation | → Player（选歌）；→ Wi‑Fi 页（sheet/push） |
| Exit | 切 Tab |

### S2 · Player

| 字段 | 内容 |
|---|---|
| Screen ID | `S2_Player` |
| Purpose | 听 + 看飞幕回忆 |
| Entry | 底栏；选歌；从 Live 返回 |
| Primary Action | 播放/暂停 |
| Secondary | 上一首/下一首；seek；模式；发弹幕；进 Live；进 Playlist |
| Content | 叠层封面；飞幕层；标题/艺术家；venue 条；进度；紫主按钮；底栏输入（可常驻或聚焦时） |
| States | NoTrack / Paused / Playing / Seeking / DanmakuOn|Off / Error |
| Navigation | → Live；→ Playlist |
| Exit | 切 Tab；进 Live |

### S3 · Live

| 字段 | 内容 |
|---|---|
| Screen ID | `S3_Live` |
| Purpose | 沉浸现场感写/看回忆（气泡呈现） |
| Entry | Player 封面/venue |
| Primary Action | 发弹幕 |
| Secondary | 打开 DanmakuModal；返回 Player |
| Content | 全屏图（封面/现场图，无则渐变）；气泡流；底栏输入 |
| States | NoTrack / PlayingSynced / EmptyDanmaku / InputFocus / PermissionN/A |
| Navigation | ← Player；Modal |
| Exit | Back / Tab |

### S4 · Wi‑Fi Import（Keep）

| 字段 | 内容 |
|---|---|
| Screen ID | `S4_WifiImport` |
| Purpose | 电脑批量上传 |
| Entry | Playlist |
| Primary | 展示 URL + 配对码；自动开服 |
| States | ServerOn / PermissionDenied / Uploading / Error / Offline(no LAN IP) |
| Exit | 离开即停服 |

### S5 · DanmakuModal（Should）

| 字段 | 内容 |
|---|---|
| Screen ID | `S5_DanmakuModal` |
| Purpose | 快捷短语/表情，降低输入成本 |
| Entry | Live（及可选 Player）微笑按钮 |
| Primary | 点短语/表情 → 发送或填入输入框 |
| States | Presented / Dismissed |
| **ASSUMPTION** | 点短语 = 立即发送（与参考一致），不先进输入框 |

---

## 7. Data Model（最小；相对现网）

### Track（Keep + 无强制新字段）

```
id, title, artist, album, duration
venueTag
filePath, coverArt?, addedAt, source
lastPositionMS
```

**Defer 字段**（ConcertMemory）：`tour, eventDate, seat, notes, lightstickColor` — 本轮不建。

### DanmakuComment（Keep）

```
id, trackId, timestampMS, text, color, fontSize, createdAt
```

**不新增** `user` / `avatar` / `isSelf` 持久字段。UI 层恒定按「我」渲染。

### UI-only / 不入库

- Like  
- Floating hearts  
- Tab selection（可 session 级）  

---

## 8. Product States（跨屏必须设计）

| 状态 | Playlist | Player | Live | Wi‑Fi |
|---|---|---|---|---|
| Empty | 引导导入 | 无曲占位 | 引导回 Playlist | — |
| Loading | 骨架/转圈 | 缓冲可选 | — | 开服中 |
| Success | 列表 | 播放+弹幕 | 气泡同步 | 上传完成刷新 |
| Error | 导入失败 toast | 播放失败 | 发送失败 | 无 IP/鉴权失败 |
| Offline | 本地仍可用 | 本地仍可用 | 本地仍可用 | 不可用说明 |
| Permission Denied | 文件权限 | — | — | 本地网络权限说明 |
| First Use | Empty CTA | — | — | 配对码教育 |
| Returning | 恢复列表+进度 | 断点续播 | 跟随进度 | 配对码保持 |

---

## 9. UI Token 方向（交给 IOS UI 细化）

| Token | 方向值 | 备注 |
|---|---|---|
| `bg.stage` | `#09060F` | 主背景 |
| `bg.elevated` | `#0E0A17` | 卡片/模态 |
| `accent` | `#8B5CF6` | 主按钮、Tab 选中、强调 |
| `accent.pressed` | `#7C3AED` | |
| `text.primary` | `#FFFFFF` | |
| `text.secondary` | white 60–70% | |
| `glass` | ultraThinMaterial / 白 6–12% 边 | 毛玻璃控件 |
| `danmaku.fly` | 近白 / 可选 accent 描边 | Player 飞幕 |
| `danmaku.bubble` | 黑半透明玻璃 + 左色点 | Live 气泡 |
| **Remove** | `#FF8A3D` 作为主 accent | 全量退出 |

组件优先：大圆紫播放键、底栏毛玻璃 Tab、封面叠层、venue 胶囊条。  
**不做**：多主题开关、复杂动效堆叠（参考有的 ambient 飘心默认不做）。

---

## 10. Edge Cases

1. Seek 到已有大量弹幕区间：Player 轨道密度上限 5；Live 气泡只挂最近 N 条（**ASSUMPTION N=50 可见**），更早可上翻。  
2. 切歌：清空两屏弹幕可视层，加载新 track 调度。  
3. 无封面：Player/Live 用 seed 紫系渐变占位。  
4. 导入中切 Tab：本地导入继续；Wi‑Fi 离开页必须停服（Keep）。  
5. 弹幕空文本/纯空格：忽略。  
6. 超长文本：**ASSUMPTION** 截断至 80 字，UI 提示。  
7. 后台：飞幕/气泡可不绘；回前台按 clock 重建。  
8. 本地网络拒绝：Wi‑Fi 页明确 CTA 去设置。  

---

## 11. Acceptance Criteria（DEV 可执行 / TEST 可测）

### AC-IA

- GIVEN App 启动  
  WHEN 查看底栏  
  THEN 可见且仅可见三个 Tab：Playlist / Player / Live  

### AC-Theme

- GIVEN 任意主屏  
  WHEN 检查主强调色  
  THEN 主按钮/选中 Tab/关键强调为紫色系，无暖橙主强调残留  

### AC-Play-Danmaku

- GIVEN 用户已添加歌曲且正在播放  
  WHEN 用户发送弹幕「起鸡皮疙瘩了」  
  THEN Player 封面在 ≤100ms 内出现右→左飞幕，且记录 `timestampMS` 接近发送时进度（±300ms 内可接受写入误差）  

- GIVEN 该曲已有历史弹幕  
  WHEN 用户从头播放经过原时间点  
  THEN 对应飞幕重现，误差 ≤ ±300ms  

### AC-Live-Sync

- GIVEN 正在 Player 播放  
  WHEN 用户点封面或 venue 条进入 Live  
  THEN Live 显示同一首歌与同步进度；已触发弹幕以气泡形式可见  

- GIVEN 在 Live  
  WHEN 发送弹幕  
  THEN 气泡出现，且回到 Player 在相近时间点可飞幕重放（同源）  

### AC-Playlist-Import

- GIVEN 空库  
  WHEN 用户从 Playlist 本地导入合法音频  
  THEN 列表出现该曲且可点播  

- GIVEN 同一 Wi‑Fi  
  WHEN 用户打开 Playlist → Wi‑Fi 导入并完成网页上传  
  THEN 曲库即时可见；离开页面后服务停止  

### AC-Drop

- GIVEN 任意屏  
  WHEN 寻找 Like / 多用户头像墙 / ConcertMemory 手账 / Setlist 抽屉  
  THEN 不存在（本轮）  

### AC-Resume

- GIVEN 播放中杀进程  
  WHEN 再开 App  
  THEN 恢复曲目、进度、模式、弹幕开关  

---

## 12. Assumptions

1. 参考 UI 只作视觉/交互布局真理源；产品行为以时间戳回忆为准。  
2. Live 是 Player 的沉浸皮肤，不是第二套弹幕系统。  
3. 「我的歌单」= 现网演唱会回忆列表的产品文案/视觉升级，不是云端歌单。  
4. 弹幕关闭 = 隐藏显示，仍允许发送入库。  
5. DanmakuModal 点短语 = 立即发送。  
6. Live 可见气泡窗口最近 50 条。  
7. 本轮不做飘心；若 UI 强需求，仅动画不入库，且不得阻塞 Must Have。  
8. Team ID `5595Y4TR6U`；工作直接上 `main`。  

---

## 13. Open Questions（已给默认，不阻塞）

| # | 问题 | 默认（继续推进） |
|---|---|---|
| Q1 | Live 背景用曲封面还是固定现场图？ | **优先曲封面模糊放大**；无封面则紫黑渐变。固定库存现场图作 Future。 |
| Q2 | Player 底栏是否常驻输入？ | **常驻简化输入条**；详细快捷进 Modal（Live 必有，Player Should）。 |
| Q3 | 原 FullPlayerOverlay 是否保留？ | **弱化**：三 Tab 后 Player Tab 即主界面；Playlist 保留 MiniPlayer 点入 Player Tab，不再叠第三层全屏 morph（减少状态）。 |
| Q4 | venueTag 空时 venue 条？ | 显示「添加现场标签」弱入口（点进编辑）；无标签也可进 Live。 |

---

## 14. UI Handoff（给 IOS UI）

**必须设计的页面**

1. `S1_Playlist`（含 Empty / 列表 / 搜索 / 导入入口）  
2. `S2_Player`（封面叠层、飞幕层、venue 条、紫主按钮、进度、模式）  
3. `S3_Live`（全屏沉浸、气泡流、底栏、返回）  
4. `S4_WifiImport`（换肤，流程不变）  
5. `S5_DanmakuModal`（Should）  
6. 底栏 Tab 选中/未选中  

**必须出现的信息**

- Playlist：标题、艺术家、venueTag、时长、封面  
- Player：封面、标题、艺术家、venue、时间、进度  
- Live：当前曲名（次要）、气泡文本、输入  

**核心操作**

- 选歌播放、播放/暂停、发弹幕、进 Live、Wi‑Fi/本地导入  

**跳转**

- Playlist → Player；Player ↔ Live；Playlist → Wi‑Fi；任意 → Tab 切换  

**必须出的状态**

- Empty / Loading / Playing / Paused / NoTrack / PermissionDenied(Wi‑Fi) / Importing / Danmaku empty  

**Token**：按 §9 出完整视觉规范；去掉暖橙主强调。  
**明确不做视觉**：Like、飘心、他人头像列表、ConcertMemory 手账、Setlist 抽屉、设计画板。

---

## 15. DEV Handoff（给 IOS DEV）

**核心改动**

1. `ContentView` Tab：`library|player` → `playlist|player|live`  
2. 新增 `LiveView`：订阅同一 `PlayerEngine` clock + `DanmakuService`；气泡 UI；seek 重建可见集  
3. `LoveSongTheme`：全量替换为黑紫白 Token；清掉 spotlight 橙  
4. Player 视觉对齐参考（主按钮、venue 进 Live）  
5. Wi‑Fi 入口从旧 Library 迁到 Playlist（逻辑 Keep）  
6. 移除/不要实现 Like、多用户身份；不要新建 ConcertMemory 表  

**数据**

- SwiftData `Track` / `DanmakuComment` **保持**  
- 弹幕调度逻辑复用 `DanmakuCore` / `DanmakuService`；Live 只换 renderer  

**存储 / API**

- 仍全本地；Wi‑Fi 仍 `NWListener` 局域网 HTTP；无新后端  

**技术风险**

- Tab + 旧 Overlay 双播放器状态冲突 → 按 §13 Q3 收敛  
- Live 气泡在高频 seek 下重建性能 → 限制可见窗口  
- 换肤遗漏 tint（Tab/Nav/Progress）→ 全局 Theme 一次清扫  

**验收**：§11 全部 AC；单测保持现有 Danmaku/Import/Resume；新增 Live 可见集/同步的纯逻辑测试更佳。

---

## 16. TEST Handoff（给 IOS TEST）

**核心测试路径**

1. 空库 → 本地导入 → 播放 → 发弹幕 → 杀进程恢复 → 重听飞幕重现  
2. Playlist → Wi‑Fi 导入闭环（权限/配对/离开停服）  
3. Player → Live → 发弹幕 → 回 Player 重放一致  
4. Seek 穿越弹幕密集区：密度/气泡窗口行为  
5. 三 Tab 无 Like/手账/Setlist  

**高风险**

- 弹幕双呈现同源一致性（Fly vs Bubble）  
- Wi‑Fi 真机局域网权限与 IP  
- 换肤后对比度/可点区域  
- Tab 切换与播放状态不中断  

**状态测试**：§8 表逐项  
**边界**：§10  
**真机验证点（Not Verified → 本轮目标）**

- iPhone 15 真机：后台锁屏、Wi‑Fi 上传、Live/Player 弹幕观感、杀进程恢复  

**Release 建议门槛**

- 模拟器/单测绿 + 真机走通路径 1–3 才可称本轮 Verified  

---

## 17. 交付状态总表（宪章）

| 能力 | Designed | Implemented（现网） | Verified |
|---|---|---|---|
| F01–F10 核心闭环 | ✅（旧+本规格 Keep） | ✅ | 逻辑 ✅ / 真机 ❌ |
| 三 Tab IA | ✅ 本规格 | ❌ | ❌ |
| Live 气泡呈现 | ✅ 本规格 | ❌ | ❌ |
| 黑紫白换肤 | ✅ 本规格 | ❌ | ❌ |
| Wi‑Fi 导入 | ✅ Keep | ✅ | 逻辑 ✅ / 真机 ❌ |
| Like/飘心/多人身份 | ✅ Drop | ❌（不应出现） | — |
| ConcertMemory/Setlist | ✅ Defer | ❌ | — |

---

**下一跳**：IOS TEAM 转 IOS UI 出视觉规范与标注；UI 完成后 DEV 按 Change 表改 `main`；TEST 按 AC 与真机点验收。
