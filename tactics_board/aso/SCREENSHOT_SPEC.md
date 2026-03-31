# Screenshot Production Spec (App Store)

> 每款 App 6 张截图，8 款 App = 48 张截图
> iPhone 6.7" + iPhone 5.5" + iPad 12.9"

---

## 设计系统

### 尺寸 (App Store Connect 必需)

| 设备 | 尺寸 (px) | 备注 |
|------|----------|------|
| iPhone 6.7" | 1290 x 2796 | 必需 — iPhone 15/16 Pro Max |
| iPhone 6.5" | 1242 x 2688 | 可选 — iPhone 11 Pro Max |
| iPhone 5.5" | 1242 x 2208 | 必需 — 兼容旧机型 |
| iPad 12.9" | 2048 x 2732 | 必需 — iPad Pro |

### 布局模板

```
┌──────────────────────────┐
│                          │
│   [标题文案 - 大号白字]    │  ← 顶部 30%
│   [副标题 - 小号黄字]      │
│                          │
│  ┌────────────────────┐  │
│  │                    │  │
│  │   App 截图内容      │  │  ← 底部 70%
│  │   (带设备 mockup)   │  │
│  │                    │  │
│  │                    │  │
│  └────────────────────┘  │
│                          │
└──────────────────────────┘
```

### 色彩

| 元素 | 颜色 | 用途 |
|------|------|------|
| 背景 | #0D0D1A | 与 App 暗色主题一致 |
| 主标题 | #FFFFFF | 最大视觉冲击 |
| 强调词 | #FFD600 | 关键词高亮（如数字、运动名） |
| 副标题 | #AAAAAA | 补充说明 |
| 边框光晕 | 运动主色 | 截图设备外框微光 |

### 运动主色

| 运动 | 主色 | 来源 |
|------|------|------|
| Soccer | #2D8A2D (草地绿) | 球场背景 |
| Basketball | #B5651D (木纹棕) | 球场背景 |
| Volleyball | #F57F17 (亮橙) | 球场背景 |
| Badminton | #1B5E20 (深绿) | 球场背景 |
| Tennis | #1565C0 (蓝色) | 球场背景 |
| Table Tennis | #1565C0 (蓝色) | 球台背景 |
| Pickleball | #2E7D32 (绿色) | 球场背景 |
| 全运动版 | #FFD600 (金色) | 品牌色 |

### 字体

SF Pro Display Bold — 标题 72pt / 副标题 36pt

---

## 截图拍摄指南

### 通用准备

1. 使用 iPhone 17 Pro Max 模拟器 (6BA0E025-6BD3-49D9-8849-50489216CF24)
2. 确保设备语言设为英文（主截图），中文（本地化截图）
3. 隐藏状态栏（App 已设置 Status bar hidden）
4. 每张截图需要：真机截图 + 文案合成

---

## Screenshot 1: Hero Shot — 阵型全景

**目的：** 第一眼说明"这是什么 App"

**操作步骤：**
1. 启动 App，选择对应运动
2. 点击 "Setup" → 选择最经典阵型（足球 4-4-2 / 篮球 1-2-2 / 排球 6v6）
3. Apply 主队阵型
4. Apply 客队阵型
5. 确保工具栏可见
6. 截图

**画面要求：**
- 满场球员，蓝/红双色对比
- 球场完整可见，不被工具栏遮挡过多
- 工具栏底部可见，展示专业感

---

## Screenshot 2: Drawing — 画线功能

**目的：** 展示核心交互 — "你可以在上面画"

**操作步骤：**
1. 在 Screenshot 1 基础上
2. 切换到 Draw 模式
3. 选择黄色实线 + 箭头
4. 画 2-3 条战术箭头（跑位/传球路线）
5. 再用虚线画 1 条防守移动线
6. 截图（保持画线工具栏可见）

**画面要求：**
- 可以看到 2-3 种不同线型（实线箭头 + 虚线）
- 线条要清晰、美观，不要画太多以免杂乱
- Draw 模式工具栏展开

---

## Screenshot 3: Animation — 动画回放

**目的：** 差异化卖点 — 竞品大多没有动画

**操作步骤：**
1. 在 Screenshot 2 基础上
2. 为 2-3 个球员添加移动路径（点击球员 → 点击目标位置）
3. 点击 Play 按钮
4. 在动画播放中截图（球员在移动过程中）

**画面要求：**
- 可以看到移动轨迹线（彩色虚线 + 箭头）
- Play 控制栏可见
- 球员位置在移动中间（不是起点也不是终点）

---

## Screenshot 4: Formations — 阵型选择

**目的：** 展示内容丰富度 — "开箱即用"

**操作步骤：**
1. 点击 "Setup" 打开阵型选择面板
2. 截图（阵型面板为打开状态）

**画面要求：**
- 阵型选择弹窗/面板清晰可见
- 可以看到多个阵型名字
- 背后的球场半透明可见

---

## Screenshot 5: 差异化内容

| 运动 | 内容 | 操作 |
|------|------|------|
| 全运动版 | 运动选择页面 | 展示 7 种运动格子 |
| Soccer | 5v5 Futsal 小场 | 切换到 Futsal 阵型 |
| Basketball | 3v3 半场 | 切换到 3v3 阵型 |
| Volleyball | 主客对阵 | 双色球员对比 |
| Badminton | 单打 vs 双打 | 展示两种模式 |
| Tennis | 发球路线图 | 画发球落点箭头 |
| Table Tennis | 双打轮换 | 展示双打站位 |
| Pickleball | Kitchen 高亮 | 展示 Kitchen 区域战术 |

---

## Screenshot 6: Share/Language

**操作步骤 (方案 A - 分享)：**
1. 点击 Share 按钮
2. 截图（分享弹窗出现）

**操作步骤 (方案 B - 语言)：**
1. 点击菜单 → Language
2. 截图（语言选择列表）

---

## 截图命名规范

```
{sport}_ios_{size}_{number}_{locale}.png

例如：
soccer_ios_6.7_01_en.png
soccer_ios_6.7_02_en.png
soccer_ios_6.7_01_zh-CN.png
tactics_board_ios_ipad_01_en.png
```

---

## 本地化截图优先级

| 优先级 | 语言 | 原因 |
|--------|------|------|
| P0 | English (US) | 全球基础 |
| P0 | 简体中文 | 中国市场 |
| P1 | 日本語 | 日本体育 App 付费意愿高 |
| P1 | 한국어 | 韩国 App Store 竞争小 |
| P2 | 繁體中文 | 台湾/香港市场 |
| P2 | ไทย | 东南亚增长市场（羽毛球/排球热门） |
| P3 | 其他 | 按下载量数据决定 |

---

## 截图合成工作流

### 推荐工具

1. **Figma** — 设计截图模板 + 批量导出
2. **Screenshots Pro** (Mac App) — 快速加文案 + 设备 Mockup
3. **fastlane snapshot** — 自动化截图拍摄
4. **fastlane frameit** — 自动加设备边框

### Figma 模板结构

```
📁 Tactics Board Screenshots
  📄 Template — iPhone 6.7"
  📄 Template — iPhone 5.5"
  📄 Template — iPad 12.9"
  📁 Soccer
    Frame 01 — Hero
    Frame 02 — Drawing
    Frame 03 — Animation
    Frame 04 — Formations
    Frame 05 — Futsal
    Frame 06 — Share
  📁 Basketball
    ...
  📁 Volleyball
    ...
  (每个运动一个文件夹)
```

### 自动化方案 (fastlane)

```ruby
# Fastfile snippet
lane :screenshots do
  capture_screenshots(
    devices: [
      "iPhone 15 Pro Max",
      "iPhone 8 Plus",
      "iPad Pro (12.9-inch) (6th generation)"
    ],
    languages: ["en-US", "zh-Hans"],
    output_directory: "./screenshots"
  )
  frame_screenshots(
    path: "./screenshots",
    background: "#0D0D1A",
    title_color: "#FFFFFF"
  )
end
```

---

## Checklist

- [ ] 设计 Figma 模板（iPhone 6.7" + 5.5" + iPad 12.9"）
- [ ] 拍摄 7 个运动 × 6 张 = 42 张原始截图 (EN)
- [ ] 拍摄全运动版 6 张原始截图 (EN)
- [ ] 合成文案到截图（EN）
- [ ] 本地化截图（ZH-CN 优先）
- [ ] 导出所有尺寸
- [ ] 上传 App Store Connect
