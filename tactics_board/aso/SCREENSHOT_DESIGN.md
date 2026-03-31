# Screenshot Design — 8 款 App 截图内容设计

> 核心原则：前 3 张决定下载，每张只传达 1 个信息，文字 < 6 个词

---

## 设计系统

### 布局

```
┌─────────────────────────────┐
│  ░░░░░░░░░░░░░░░░░░░░░░░░  │ ← 顶部留白 60px
│                             │
│   主标题 (白色 72pt Bold)     │ ← 1 行，≤6 词
│   副标题 (灰色 36pt)         │ ← 1 行，补充说明
│                             │
│  ┌───────────────────────┐  │
│  │                       │  │
│  │    App 真机截图         │  │ ← 底部 65%
│  │    (iPhone mockup)     │  │     设备微倾斜 3°
│  │                       │  │
│  │                       │  │
│  └───────────────────────┘  │
│                             │
└─────────────────────────────┘
```

### 色彩

- **背景**: 渐变 `#0D0D1A` → `#1A1A2E`（与 App 暗色主题融合）
- **主标题**: `#FFFFFF`
- **强调词**: `#FFD600`（黄色，用于数字和关键动词）
- **副标题**: `#AAAAAA`
- **设备外框**: 运动主色微光晕（10% opacity, 20px blur）

### 运动主色

| 运动 | 主色 | 用于光晕和强调 |
|------|------|--------------|
| Soccer | `#2D8A2D` 草地绿 | 绿色光晕 |
| Basketball | `#B5651D` 木纹棕 | 橙棕光晕 |
| Volleyball | `#F57F17` 亮橙 | 橙色光晕 |
| Badminton | `#1B5E20` 深绿 | 绿色光晕 |
| Tennis | `#1565C0` 蓝色 | 蓝色光晕 |
| Table Tennis | `#1565C0` 蓝色 | 蓝色光晕 |
| Pickleball | `#2E7D32` 绿色 | 绿色光晕 |
| 全运动版 | `#FFD600` 金色 | 金色光晕 |

---

## 全运动版 — Tactics Board（6 张）

### Screenshot 1: Hero — 运动选择页

```
主标题: "7 Sports. One Board."
副标题: "Soccer · Basketball · Volleyball & more"
强调词: "7" 用黄色
```

**画面内容**: 运动选择页面
- 7 个运动格子清晰可见（2 列布局）
- 每个格子内有迷你球场预览 + 运动名 + emoji
- 深色背景 `#0D0D1A`，格子 `#1A1A2E`
- 顶部 "Tactics Board" 标题 + "Choose a sport" 副标题

**为什么第 1 张**: 直接回答"这个 App 是什么" — 7 种运动的视觉冲击

---

### Screenshot 2: 核心功能 — 足球场战术画线

```
主标题: "Draw Plays Like a Pro"
副标题: "Arrows, lines, and zones"
强调词: "Draw" 用黄色
```

**画面内容**: 足球场 + 4-3-3 阵型 + 战术画线
- 绿色足球场满屏，白色标线清晰
- 11 名蓝色主队球员 + 11 名红色客队球员
- 2-3 条黄色实线箭头（模拟传球/跑位）
- 1 条白色虚线（模拟防守移动）
- 底部 Draw 模式工具栏展开：线型选择 + 颜色面板 + 粗细滑块
- 画线工具栏展示丰富的自定义选项

**操作步骤**:
1. 选择 Soccer → Apply 4-3-3 Home + Away
2. 切换 Draw 模式
3. 选黄色 + 实线 + 箭头尾部，画 2 条传球线
4. 选白色 + 虚线，画 1 条防守移动线
5. 截图

---

### Screenshot 3: 差异化 — 动画回放

```
主标题: "Watch Plays Move"
副标题: "Step-by-step animation"
强调词: "Move" 用黄色
```

**画面内容**: 篮球场 + 动画播放中
- 木纹棕色篮球场，三分线清晰
- 5 名蓝色主队球员，部分在移动中（位于起点和终点之间）
- 彩色虚线移动轨迹（蓝、红、绿不同颜色）
- 虚影(ghost)显示起始位置
- 轨迹上有编号的 waypoint 圆点（"1"、"2"）
- 底部播放控制栏：◀ 2/5 ▶ [▶播放] — 绿色播放按钮醒目
- 步数指示器 "2/5" 清晰可见

**操作步骤**:
1. 选择 Basketball → Apply 1-2-2 Horns
2. Move 模式下点击 2-3 个球员，分别设置移动路径
3. 点击 Play，在动画第 2 步时截图

---

### Screenshot 4: 阵型选择器

```
主标题: "Formations in One Tap"
副标题: "Pre-loaded for every sport"
强调词: "One Tap" 用黄色
```

**画面内容**: 足球场 + 阵型选择弹窗
- 背景：足球场半透明（被弹窗遮挡 50%）
- 弹窗内容：
  - 顶部：人数选择按钮 "5v5" "7v7" "11v11"（11v11 选中，蓝色高亮）
  - 中间：阵型卡片列表 "4-4-2" "4-3-3" "3-5-2" "4-2-3-1"
  - 底部：队伍选择 "Home" "Away" chips + "Apply" 绿色按钮
- 弹窗背景 `#1E1E2E`，圆角 20px

**操作步骤**:
1. 在足球场页面，点击 "Setup"
2. 选择 11v11
3. 截图（弹窗打开状态）

---

### Screenshot 5: 分享功能

```
主标题: "Share With Your Team"
副标题: "Export as HD image"
强调词: "Share" 用黄色
```

**画面内容**: 排球场战术 + iOS 分享弹窗
- 背景：亮橙色排球场 + 6v6 阵型 + 几条战术线
- iOS 原生分享面板从底部弹出
- 分享选项可见：Messages、AirDrop、Copy 等
- 展示"战术可以分享出去"的概念

**操作步骤**:
1. 选择 Volleyball → Apply 6v6 阵型
2. 画 2 条进攻箭头
3. 点击分享按钮
4. 截图（分享面板出现时）

---

### Screenshot 6: 多语言

```
主标题: "11 Languages"
副标题: "中文 · 日本語 · 한국어 · ไทย & more"
强调词: "11" 用黄色
```

**画面内容**: 语言选择弹窗
- 背景：某个球场半透明
- 语言列表弹窗，显示 11 种语言 + 国旗/标识
- 当前选中语言有蓝色高亮

**操作步骤**:
1. 点击菜单(⋯) → Language
2. 截图（语言列表打开）

---

## Soccer Board（6 张）

### Screenshot 1: Hero — 满场阵型

```
EN: "Your Pitch. Your Plan."     ZH: "你的球场，你的战术"
副标题: "FIFA-accurate field"     副标题: "FIFA 标准球场"
强调词: "Your" 用黄色              强调词: "你的" 用黄色
```

**画面**: 绿色球场 + 4-4-2 阵型（蓝色 11 人 + 红色 11 人），球场草地条纹可见，白色标线清晰，底部工具栏可见（Move 模式）

---

### Screenshot 2: 战术画线

```
EN: "Draw Every Run"             ZH: "画出每一次跑位"
副标题: "Passes, runs, zones"     副标题: "传球、跑位、区域"
强调词: "Every" 用黄色
```

**画面**: 4-3-3 阵型 + 3 条黄色传球箭头 + 1 条虚线跑位 + Draw 工具栏展开

---

### Screenshot 3: 定位球动画

```
EN: "Animate Set Pieces"         ZH: "定位球战术动画"
副标题: "Corner kicks, free kicks" 副标题: "角球、任意球"
强调词: "Animate" 用黄色
```

**画面**: 角球区域放大视角（或全场视角），3-4 名球员有移动轨迹（彩色虚线+箭头），播放控制栏可见，步数 "2/4"

---

### Screenshot 4: 阵型选择

```
EN: "6 Formations Built In"      ZH: "6 种阵型 一键加载"
副标题: "4-4-2 · 4-3-3 · 3-5-2 & more"
强调词: "6" 用黄色
```

**画面**: 阵型选择弹窗打开，可见 4-4-2 / 4-3-3 / 3-5-2 / 4-2-3-1 选项

---

### Screenshot 5: 5v5 Futsal

```
EN: "5v5 to 11v11"               ZH: "5 人制到 11 人制"
副标题: "Futsal included"          副标题: "Futsal 五人制"
强调词: "5v5" 和 "11v11" 用黄色
```

**画面**: 5v5 Futsal 阵型，球场上 5+5 球员，更紧凑的站位

---

### Screenshot 6: 保存与分享

```
EN: "Save & Share"                ZH: "保存与分享"
副标题: "Unlimited tactics"        副标题: "无限保存"
强调词: "Unlimited" 用黄色
```

**画面**: Save/Load 底部弹窗打开，可见保存列表 + 名称输入框 + 绿色保存按钮

---

## Basketball Board（6 张）

### Screenshot 1: Hero

```
EN: "Draw the Bucket"            ZH: "画出得分路线"
副标题: "Full-court tactics"       副标题: "全场战术一目了然"
强调词: "Bucket" 用黄色
```

**画面**: 木纹球场 + 1-2-2 Horns 阵型（5 蓝 + 5 红），三分线、罚球区清晰

### Screenshot 2: 挡拆画线

```
EN: "Screens. Cuts. Rolls."      ZH: "掩护、切入、挡拆"
副标题: "Draw every detail"
```

**画面**: 半场视角，2 条黄色箭头（掩护+切入路线） + 1 条红色虚线（防守） + Draw 工具栏

### Screenshot 3: 动画回放

```
EN: "Watch the Play Unfold"      ZH: "看战术逐步展开"
副标题: "Step by step"
强调词: "Unfold" 用黄色
```

**画面**: 3 名球员有移动轨迹，播放控制栏 "2/3"，ghost 虚影可见

### Screenshot 4: 阵型

```
EN: "5 Formations Ready"         ZH: "5 种阵型随时加载"
强调词: "5" 用黄色
```

**画面**: 阵型选择弹窗：1-2-2 Horns / 2-3 / 1-3-1 / 1-4 / 3v3

### Screenshot 5: 3v3

```
EN: "3v3 or 5v5"                 ZH: "3 对 3 或 5 对 5"
强调词: "3v3" 用黄色
```

**画面**: 3v3 三角阵型（3 蓝 + 3 红），半场

### Screenshot 6: 分享

```
EN: "Share the Playbook"         ZH: "分享战术手册"
```

**画面**: 分享弹窗或保存列表

---

## Volleyball Board（6 张）

### S1: Hero

```
EN: "Plan the Rotation"          ZH: "规划轮转站位"
强调词: "Rotation" 用黄色
```

**画面**: 亮橙球场 + 6v6 阵型（6 蓝 + 6 红），网带黄线醒目，进攻线虚线可见

### S2: 进攻路线

```
EN: "Map Your Attack"            ZH: "标出进攻路线"
强调词: "Attack" 用黄色
```

**画面**: 3 条黄色进攻箭头（主攻/副攻/二传跑位） + Draw 工具栏

### S3: 动画

```
EN: "Animate the Rally"          ZH: "让攻防动起来"
强调词: "Animate" 用黄色
```

**画面**: 球员移动轨迹 + 播放控制栏

### S4: 接发球

```
EN: "Serve-Receive Ready"        ZH: "接发球站位一目了然"
强调词: "Ready" 用黄色
```

**画面**: 接发球阵型，6 名球员特定站位

### S5: 主客对阵

```
EN: "Home & Away"                ZH: "主客两队对阵"
```

**画面**: 蓝红双色球员清晰对比，网两侧各 6 人

### S6: 分享

```
EN: "Share to Team Chat"         ZH: "分享到队伍群"
```

---

## Badminton Board（6 张）

### S1: Hero — 双打站位

```
EN: "See the Full Court"         ZH: "看清全场站位"
强调词: "Full Court" 用黄色
```

**画面**: 深绿球场 + 双打阵型（2 蓝 + 2 红），黄色网线醒目

### S2: 回合路线

```
EN: "Draw Rally Patterns"        ZH: "画出回合路线"
强调词: "Rally" 用黄色
```

**画面**: 2-3 条击球路线箭头（对角线/直线） + Draw 工具栏

### S3: 单打 vs 双打

```
EN: "Singles or Doubles"          ZH: "单打或双打"
```

**画面**: 阵型选择弹窗，"Singles" / "Doubles" 选项可见

### S4: 动画

```
EN: "Animate Movement"           ZH: "动画演示移动"
强调词: "Animate" 用黄色
```

**画面**: 球员移动轨迹 + 播放控制栏

### S5: 双打轮转

```
EN: "Plan Doubles Rotation"      ZH: "规划双打轮转"
强调词: "Doubles" 用黄色
```

**画面**: 双打轮转路线（前后换位箭头）

### S6: 分享

```
EN: "Share with Your Partner"    ZH: "分享给搭档"
```

---

## Tennis Board（6 张）

### S1: Hero

```
EN: "Map the Match"              ZH: "掌控全场布局"
强调词: "Match" 用黄色
```

**画面**: 蓝色网球场 + 双打阵型

### S2: 发球落点

```
EN: "Serve Placement"            ZH: "发球落点规划"
强调词: "Serve" 用黄色
```

**画面**: 发球区域 + 2-3 条落点箭头

### S3: 动画

```
EN: "Animate the Point"          ZH: "动画演示一分"
```

### S4: 阵型

```
EN: "Singles & Doubles"           ZH: "单打与双打"
```

### S5: 上网路线

```
EN: "Net Approach Plans"          ZH: "上网截击路线"
强调词: "Net" 用黄色
```

**画面**: 底线到网前的上网路线箭头

### S6: 分享

```
EN: "Share Your Strategy"        ZH: "分享你的战术"
```

---

## Table Tennis Board（6 张）

### S1: Hero

```
EN: "Plan Every Serve"           ZH: "规划每一个发球"
强调词: "Every" 用黄色
```

**画面**: 蓝色球台 + 深灰背景 `#263238` + 球员站位

### S2: 发球路线

```
EN: "Draw Spin Patterns"         ZH: "画出旋转路线"
强调词: "Spin" 用黄色
```

**画面**: 发球路线箭头 + Draw 工具栏

### S3: 阵型

```
EN: "Singles & Doubles"           ZH: "单打与双打"
```

### S4: 动画

```
EN: "Animate the Rally"          ZH: "动画演示回合"
```

### S5: 双打轮换

```
EN: "Doubles Rotation"           ZH: "双打轮换站位"
强调词: "Rotation" 用黄色
```

### S6: 保存

```
EN: "Save & Share"                ZH: "保存与分享"
```

---

## Pickleball Board（6 张）

### S1: Hero — Kitchen 高亮

```
EN: "Own the Kitchen"            ZH: "掌控非截击区"
强调词: "Kitchen" 用黄色
```

**画面**: 绿色球场 + Kitchen 区域半透明白色填充醒目 + 双打阵型

### S2: 短球博弈

```
EN: "Draw Dink Wars"             ZH: "画出短球博弈"
强调词: "Dink" 用黄色
```

**画面**: Kitchen 线附近的短球路线箭头

### S3: 第三拍

```
EN: "Plan Your Third Shot"       ZH: "规划第三拍战术"
强调词: "Third Shot" 用黄色
```

**画面**: 后场到 Kitchen 线的落点箭头

### S4: 叠式站位

```
EN: "Stacking Strategy"          ZH: "叠式站位策略"
强调词: "Stacking" 用黄色
```

**画面**: 双打叠式站位阵型

### S5: 动画

```
EN: "Animate the Point"          ZH: "动画演示得分"
```

### S6: 分享

```
EN: "Share Your Playbook"        ZH: "分享你的战术本"
```

---

## 截图拍摄优先级

| 优先级 | 内容 | 原因 |
|--------|------|------|
| **P0** | 每款 App 的 S1 (Hero) | 搜索结果只展示前 1-3 张 |
| **P0** | 每款 App 的 S2 (画线) | 核心交互，必须展示 |
| **P0** | 每款 App 的 S3 (动画) | 差异化卖点 |
| **P1** | S4 (阵型选择) | 内容丰富感 |
| **P2** | S5 (运动特色) | 锦上添花 |
| **P2** | S6 (分享/语言) | 信任感 |

## 拍摄顺序建议

按运动逐个拍摄（减少切换成本）：

1. **Soccer** → S1~S6（阵型最多，画面最丰富）
2. **Basketball** → S1~S6
3. **Volleyball** → S1~S6
4. **Badminton** → S1~S6
5. **Tennis** → S1~S6
6. **Table Tennis** → S1~S6
7. **Pickleball** → S1~S6
8. **Tactics Board 全运动版** → S1~S6（需要切换不同运动）
