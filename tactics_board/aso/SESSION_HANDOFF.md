# ASO 战役 · 会话续接备忘

> 最后更新：2026-05-14
> 状态：A~Q 全部落地（除 O = A/B 实战 / P = push 上 App Store），**18 个 commit 在本地 main，全部 unpushed**
> 角色：用户以 15 年 App Growth Hacker / CMO 身份协作

---

## ✅ 已落地（18 个 commit · 全部 unpushed）

| Commit | 任务 | 内容 |
|---|---|---|
| `c4b5710` | P0 | 16 EN subtitle benefit 钩子 + desc "<App> — <App>" 去重 |
| `c6ba761` | TH-P0 | 泰文 tactics_board "7→15" 数据 + 3 单运动 L1 sabai 化 |
| `90890db` | **A** | tactics_board 5 locale "7→15" + 补全 8 项运动 |
| `899f816` | **B** | 15 single-sport SKU 泰文 subtitle 改战术钩子 |
| `d3cb878` | **C** | 16 EN description L5 前置 trust signal |
| `a08d277` | **D** | ASO_MASTER 重写策略真相源（574→215 行） |
| `05def81` | **E** | 16 EN promo Q2 2026 时效钩子 + rotation SOP |
| `0512347` | **F** | 新增 SCREENSHOT_CAPTIONS.md：96 EN caption spec |
| `26da8db` | **G** | 10 非 EN locale × 16 SKU = 160 条 promo 本地化 |
| `60f4088` | **H** | 16 TH description 前置 sabai trust signal |
| `010051d` | **I** | 48 keyword 文件优化（EN+zh-Hans+zh-Hant × 16） |
| `ac24de0` | **J** | Pillow caption 工具 v0 + 烤好 91 EN 截图 |
| `9f7c629` | **K** | A/B 框架 + 4 高价值 SKU 的 B 变体种子 |
| `e5c5d1e` | — | SESSION_HANDOFF 从未跟踪转为提交 |
| `269d985` | **N** | 80 keyword 文件（th/ja/ko/es-ES/fr-FR × 16），全 locale 状态完整 |
| `53b5831` | **L** | 480 localized captions（zh-Hans/zh-Hant/th/ja/ko）+ 烤 172 PNG（4 locale）+ 工具 locale 字体映射 |
| `da415de` | **M** | tactics_board s2~s6 raw 用各 sport 代表截图补齐 + 5 locale 重烤 |
| `d3b001f` | **Q** | Caption tool v1：圆角设备框 + `<a>` 黄色 accent markup + `--font-path` |

---

## 工具 / 文档

**新工具**：
- `tactics_board/tool/aso_caption_overlay.py` — Pillow caption 烤制 v1。支持：
  - 多 locale 自动字体（Hiragino Sans GB / AppleSDGothicNeo / ThonburiUI / Helvetica Neue）
  - `<a>...</a>` 黄色 accent markup（单行才生效）
  - 圆角设备框（无需 bezel 素材）
  - `--font-path` flag 接受自定义字体（SF Pro 等）

**已有工具**：
- `tactics_board/tool/aso_fix_desc_dedup.py`
- `tactics_board/tool/aso_rewrite_subtitles_en.py`

**文档**：
- `aso/ASO_MASTER.md` — 16-SKU 策略真相源
- `aso/SCREENSHOT_CAPTIONS.md` — 16 SKU × 6 shot × 6 locale = 576 caption（en-US + 5 locale）+ accent 用法
- `aso/AB_VARIANTS.md` — A/B 流程 + 4 个种子变体
- `aso/SCREENSHOT_SPEC.md` — 截图设计规范
- `aso/SCREENSHOT_DESIGN.md` — 截图视觉
- `aso/SESSION_HANDOFF.md` — 本文件

---

## 产出资产

- **fastlane/metadata**：
  - subtitle：16 EN + 16 TH 全改完；其他 locale 部分改
  - description：16 EN + 16 TH 全前置 trust signal；5 locale tactics_board 7→15 修
  - keywords：8 locale × 16 SKU = 128 个 keyword 文件按零 name 重复规则重写
  - promotional_text：11 locale × 16 SKU = 176 条 Q2 2026 时效钩子
  - 11 个 locale 中：en-US/zh-Hans/zh-Hant/th/ja/ko/es-ES/fr-FR ✅，vi/id/ms 仅 promo ✅，keywords ⏳

- **截图**：
  - `aso/screenshots_localized/` — raw（含 M 补的 tactics_board s2~s6）
  - `aso/screenshots_captioned/` — 烤好的 caption PNG：5 locale × ~46 = 263 张

---

## ⚠️ 注意

- **千万别擅自 push** —— 18 个 commit 静默累积，等用户确认（也许打包跟下一次 release 一起走）
- `git status` 残留的 splash/LaunchScreen PNG 改动是会话开始前就有的，**不属于 ASO 工作**
- 本轮所有 commit msg 都带 `ASO <X>:` 前缀 + Co-Authored-By 行

---

## 🟢 剩余候选（用户触发型 + 长期项）

| 候选 | 说明 | 工作量 |
|---|---|---|
| **O** | promo A/B 实战 —— 把 K 的 4 个 B 变体 swap 到 fastlane → deliver → 7~14 天测 → 决策 | 持续，每个变体周期 ~2 周 |
| **P** | push 18 个 ASO commit 到 origin/main + `fastlane deliver` 推到 App Store Connect | 半小时（用户授权） |
| **N+** | vi / id / ms keyword 优化（48 个文件，需 native 关键词研究） | 半天 |
| **L+** | vi / id / ms / es / fr screenshot caption 翻译 + 烤制 | 1 天 |
| **R** | 把 caption tool 接入 fastlane `deliver` pipeline，让上 App Store 时自动烤 | 半天 |
| **S** | 第二轮 ASO_MASTER 复盘：本轮哪些变更上线后 CVR 真升了，更新 §10 changelog | 上线 30 天后 |

---

## 📌 关键事实速查

- 16 个 App Store SKU：1 全运动（tactics_board）+ 15 单运动
- tactics_board 实际含 15 个 SportType（`lib/models/sport_theme.dart` L33-L103）
- 11 个 locale：`en-US, es-ES, fr-FR, id, ja, ko, ms, th, vi, zh-Hans, zh-Hant`
- 字段限制：subtitle 30 / keywords 100 / promo 170 / description ~4000 / iOS 预览 ~250
- Promo text 唯一不重审字段 → A/B 主战场
- 176 listings 总盘（16 × 11）—— EN + 7 locale 已系统翻新，3 locale（vi/id/ms）选择性触
- Caption 烤制：5 locale 共 263 PNG ready，源资产 raw 仍只覆盖 8 SKU（缺 baseball/handball/rugby/fieldHockey/waterPolo/sepakTakraw/beachTennis/footvolley 的非 EN raws —— 需 integration test 跑全 SportType）
