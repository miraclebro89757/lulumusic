# LoveSong Change Spec Amend · 1:1 高保真（紧急）

| 项 | 内容 |
|---|---|
| 文档 | `CHANGE-SPEC-lovesong-ui-1to1-amend.md` |
| 上级 | `CHANGE-SPEC-lovesong-ui-refresh.md`（v1.0） |
| 效力 | **本补丁覆盖 v1.0 中冲突的 Drop/文案/IA 细节**；未点名条款仍有效 |
| 日期 | 2026-09-11 |
| 触发 | 用户否决「近似」→「直接做成这样的 / 1:1 高保真还原」 |
| 原图 | `/workspace/lulumusic-prd/reference-screens/01-player.png` `02-live.png` `03-danmaku-modal.png` `04-playlist.png` |
| 素材 | `/workspace/music-UI/src/assets/images/album_night_we_met_*.jpg` `concert_live_stage_*.jpg` |
| 作者 | IOS PRD |

**真理源优先级**：原图像素布局 > music-UI 原型交互 > 本 Amend > v1.0 > 旧 PRD。  
**产品闭环不变**：时间戳弹幕、Wi‑Fi 导入、私密本地、无真实社交后端。

---

## 1. 撤销 / 改判（相对 v1.0）

| 原条款 | v1.0 | Amend | 理由 |
|---|---|---|---|
| CH-15 Like | Drop | **Must · Keep 控件 + 本机喜欢态** | 原图 Player 左下实心紫心；用户要 1:1 |
| CH-16 飘心 | Drop | **仍默认不做**（原图 Live 未强制环境飘心为主路径） | 不挡 1:1；勿扩 |
| CH-17 多人昵称头像 | Drop 产品数据 | **UI 铬件 Must 1:1；数据仍仅自己** | 气泡壳要像原图；禁止伪造多人社区数据入库 |
| Tab 文案/顺序 | playlist\|player\|live 英意、Playlist 偏左叙述 | **`播放器 \| 现场弹幕 \| 歌单`（左→右）** | 四张原图一致 |
| DanmakuModal | Should | **Must** | 原图 03 |
| HQ / 现场实况 pill / 叠层封面 / venue 毛玻璃条 / 返回当前播放 | 未逐条升 Must | **一律 Must 1:1** | 用户拍板视觉 |

---

## 2. Amend 冻结表（UI/DEV 可执行）

| ID | 项 | 判定 | 1:1 要求（对照原图） | 产品数据/行为 |
|---|---|---|---|---|
| A01 | Tab 顺序与文案 | **Must** | 左 `播放器` · 中 `现场弹幕` · 右 `歌单`；选中紫胶囊 | 三 Tab IA 保持 |
| A02 | Player 爱心 | **Must** | 控制条最左实心/描边紫心；可点 | `liked: Bool` **仅本机**持久化（Track 或本地键）；不社交、不同步、无列表「喜欢」Tab |
| A03 | 叠层封面卡 | **Must** | 主封面圆角卡 + 后方更大/偏移紫阴影层 | 装饰层 |
| A04 | 现场实况 pill | **Must** | 封面右上半透明胶囊「现场实况」 | 文案固定；无真实直播状态机 |
| A05 | Live Memory 头 | **Must** | 左上紫点 +「Live Memory」+ 副文 `Concert · 日期` | 日期取 venue/导入日；缺省占位 |
| A06 | venue 毛玻璃条 | **Must** | 控条下：波形图标 + `Live · 日期` + 场馆名 + 右 **HQ** 徽章 | 点条 → 进「现场弹幕」；HQ 为视觉徽章（**ASSUMPTION**：有无损/flac 或默认显示，不接真实码率探测也可先常显） |
| A07 | 大紫播放键 | **Must** | 中心实心紫圆 + 柔光；左右切歌；右 `···` | 播放逻辑 Keep |
| A08 | Live 气泡壳 | **Must** | 左对齐毛玻璃胶囊：圆头像 + 昵称 + 文案 | **每条弹幕仍 `trackId+timestampMS` 仅自己**；UI 可用固定「我」或单一展示人设色点/字；**禁止**写入多用户假数据；重放仍按时间戳 |
| A09 | Live 顶栏 | **Must** | 左圆形返回；右 `Live · 日期` pill + 展开图标 | 返回 → 播放器 |
| A10 | Live 输入条 | **Must** | 微笑 +「发一条弹幕...」+ 紫发送圆钮 | 微笑 → Modal |
| A11 | DanmakuModal | **Must** | 关、提示文案、心形圆钮、描边输入、发送、短语 chip 行、底栏表情/气泡/键盘图标 | 点 chip = 立即发送；短语文案按原图：`现场封神` / `万人大合唱` / `这首直接泪目` / `永远的经典`（原图截断补全） |
| A12 | 歌单页 | **Must** | 大卡片「我的歌单」+ `Concert · N`；`+` 导入；行封面/标题/艺术家/时长/`···`；当前曲紫描边高亮 | `+` → 本地导入（Wi‑Fi 仍从菜单/`···` 或次入口 Keep，**不得删**） |
| A13 | 返回当前播放 | **Must** | 歌单下部宽胶囊「返回当前播放」 | 切到播放器 Tab 并聚焦当前曲 |
| A14 | 时间戳/Wi‑Fi/私密 | **Keep** | 视觉不推翻 | 闭环不变 |
| A15 | 真多人社区/账号 | **Forbidden** | — | 不实现 |

**ASSUMPTION（Live 演示铬件）**：为 1:1 气泡观感，允许 UI 层对「我」的弹幕渲染为原图同款壳（圆头像色点 + 昵称「我」）。若设计稿展示多昵称，**工程实现只渲染当前用户一条身份**；不得 seed 假用户列表进数据库。QA 验收：库内作者维度不存在；界面不出现可切换的「他人」资料。

---

## 3. 屏幕对照（原图 → 实现）

1. **播放器** `01-player.png` — A02–A07 + A01  
2. **现场弹幕** `02-live.png` — A08–A10 + A01  
3. **弹幕 Modal** `03-danmaku-modal.png` — A11  
4. **歌单** `04-playlist.png` — A12–A13 + A01  

素材优先用仓库内 album / concert_live_stage 图做预览与占位，真机以用户导入封面为准。

---

## 4. 数据补丁（最小）

```
Track (or side store):
  isLiked: Bool = false   // 本机 only

DanmakuComment: 不变
  // 无 userId / nickname 持久字段
```

UI 映射：`displayName = "我"`；`avatarColor` 由 color 字段或固定紫派生。

---

## 5. AC 补丁（GIVEN/WHEN/THEN）

- GIVEN 播放器页对照 `01-player.png`  
  WHEN 目视主结构  
  THEN 叠层封面、现场实况 pill、紫心、大紫键、venue 毛玻璃条、HQ、底栏三 Tab 文案顺序与原图一致（允许系统字体微调，不允许缺控件）

- GIVEN 用户点爱心  
  WHEN 杀进程重开  
  THEN 该曲喜欢态仍在；无任何分享/他人可见路径

- GIVEN 现场弹幕页  
  WHEN 重放已有弹幕  
  THEN 气泡为「头像圆+昵称+文案」壳；数据均属当前用户时间戳弹幕

- GIVEN 歌单页  
  WHEN 点「返回当前播放」  
  THEN 进入播放器且当前曲为正在播/最近播

- GIVEN Modal  
  WHEN 点「现场封神」  
  THEN 立即发送并关闭或保持 Modal 策略与原型一致（**ASSUMPTION**：发送后关闭 Modal）

---

## 6. Handoff

### UI
按四张原图出 1:1 标注（间距、圆角、字号、色值、发光）；Tab 中文三词不可改；补爱心两态（描边/实心紫）。

### DEV
实现 A01–A14；Like 本机持久化；Live 壳 1:1 但禁止假多用户数据；Wi‑Fi/时间戳逻辑不回退；Theme 继续黑紫白。

### TEST
增加 1:1 对照清单（四图）；回归时间戳 ±300ms、Wi‑Fi、私密无社交泄漏；爱心持久化。

---

**下一跳**：IOS TEAM 立即转 UI 按 Amend 重出规范；DEV 等 UI Token/标注后按冻结表改 `main`。
