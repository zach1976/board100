# App Store 截图制作流程 V2（PLAN EVERY RALLY 设计）

> 这套流程把"原始 app 截图"加工成 App Store 上架用的营销截图：
> 深蓝渐变 + 每运动场地线背景 + 钛框手机 + TACTICS BOARD 徽章 + 双行白/绿标题 + 副标题。
> 最终画布 **1290 × 2796**（App Store iPhone 6.7" 必需尺寸）。
>
> 覆盖范围：**16 运动 × 11 语言 × 6 幕 = 1056 张**。

---

## 0. 目录与产物

| 路径 | 作用 |
|------|------|
| `tactics_board/fastlane/screenshots/<sport>/<locale>/` | **上传源**（最终成品要回写到这里，upload 脚本只读这里） |
| `tactics_board/aso/glyphs/<sport>.png` | 每运动的专业扁平图标（从 app 的 `SportGlyph` 导出，徽章 + 背景水印用） |
| `tactics_board/aso/captions_v2.*` | 每运动 6 句标题 + 副标题 × 11 语言的文案表 |
| `tactics_board/tool/aso_design_compositor.py` | 合成器（背景 + 手机框 + 文字 → 成品） |
| `tactics_board/test/export_glyphs_test.dart` | 把 `SportGlyph` 导出成透明 PNG |
| `tactics_board/integration_test/appstore_screenshots.dart` | 跑出"手机里"的原始 app 截图 |

---

## 1. 设计规格（V2）

画布 1290 × 2796，从上到下：

1. **徽章 pill**（~4.5% 处，居中）：深蓝半透明底 + 绿色描边，左侧运动 glyph + 绿色加粗大写「TACTICS BOARD」。
2. **标题第 1 行**（白色，~11.8% 处）：Helvetica Neue Condensed Black，全大写，如 `PLAN`。
3. **标题第 2 行**（绿色 #9FE63F，~17.2% 处）：同字体，左右各一条短横线，如 `— EVERY RALLY —`。
4. **副标题**（浅灰 #BCC5D6，~22.2% 处）：Helvetica Neue Medium，一句话卖点。
5. **手机**（25.5%–95% 处）：代码绘制的钛色边框 + 灵动岛 + 侧键，里面贴原始 app 截图，下方有淡倒影。
6. **背景**：深蓝竖向渐变 + 中心径向辉光 + 透视场地线 + 右上角运动 glyph 大水印 + 四角暗角。

配色常量见 `aso_design_compositor.py` 顶部（`ACCENT = (159,230,63)` 等）。

### 6 幕剧情（与标题对应）

| # | 幕 | 英文标题（基准） | 副标题（基准） |
|---|-----|------------------|----------------|
| 1 | 空场 | PLAN / EVERY RALLY | Drag players and draw tactics in seconds |
| 2 | 站位 | PLACE / EVERY PLAYER | Build formations with clear numbered markers |
| 3 | 时间轴 | BUILD / A TIMELINE | Organize each move in a clear sequence |
| 4 | Add 菜单 | ADD / MATCH SETUPS | Singles, doubles, mixed and custom markers |
| 5 | 路线 | SHOW / SHOTS CLEARLY | Map routes, targets and rally patterns |
| 6 | 回放 | ANIMATE / THE DRILL | Play each step and visualize movement paths |

> 文案**按运动适配**：rally/shots 偏拍类，团队运动换 attack/plays/runs 等（见 captions 表）。

---

## 2. 完整步骤

### Step 1 — 导出专业运动图标（一次性，除非 SportGlyph 改了）

```bash
cd tactics_board
flutter test test/export_glyphs_test.dart
# → aso/glyphs/<sport>.png ×16（透明背景，512²@2x）
```

用 app 自带的 `SportGlyph`（CustomPainter 画的扁平图标），避免 emoji 那种不专业的观感。

### Step 2 — 跑原始 app 截图（手机里的内容）

```bash
cd tactics_board
flutter test integration_test/appstore_screenshots.dart \
  -d <simulator-id>
# → 每运动每语言 6 张原始全屏截图（1320×2868）
```

`appstore_screenshots.dart` 按 6 幕剧情构造画面（空场→站位→时间轴→Add菜单→路线→回放），
循环 16 运动 × 11 语言。

### Step 3 — 维护文案表

`aso/captions_v2.*`：每运动 6 句标题（白词 + 绿词）+ 副标题，× 11 语言。
合成器读它取每张图的文字。

### Step 4 — 合成成品

```bash
cd tactics_board
python3 tool/aso_design_compositor.py --sample        # 出一张样张自检
python3 tool/aso_design_compositor.py --all           # 全量 16×11×6
# → 回写到 fastlane/screenshots/<sport>/<locale>/
```

> **铁律：批量前先出 1 张样张给人确认视觉，再全量**（项目惯例）。

### Step 5 — 上传 App Store Connect

```bash
cd tactics_board
python3 tool/upload_screenshots.py            # 或 update_live_screenshots.py
```

两个脚本的 `SCREENSHOTS_BASE` 都指向 `fastlane/screenshots/`，所以成品必须回写到那里。

---

## 3. 语言清单（11）

`en-US · es-ES · fr-FR · id · ja · ko · ms · th · vi · zh-Hans · zh-Hant`

CJK / 越南语等需对应字体（合成器里按 locale 选字体；现用系统 Hiragino / STHeiti 等）。

---

## 4. 已知取舍

- 背景的场地线与手机框是**代码绘制**的，没有照片级器材质感（成本换可批量、统一）。
- Apple Color Emoji 弃用，统一用 `SportGlyph` 导出的图标。
- 旧流程 `tool/aso_caption_overlay.py`（顶部色带 + 截图）已被本流程取代。
