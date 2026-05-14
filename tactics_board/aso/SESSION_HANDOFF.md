# ASO 战役 · 会话续接备忘

> 最后更新：2026-05-14
> 状态：A~K 全部落地，**13 个 commit 在本地 main，全部 unpushed**
> 角色：用户以 15 年 App Growth Hacker / CMO 身份协作

---

## ✅ 已落地（13 个 commit 全部 unpushed）

| Commit | 任务 | 内容 |
|---|---|---|
| `c4b5710` | P0 | 16 个 EN subtitle benefit 钩子 + description "<App> — <App>" 去重 |
| `c6ba761` | TH-P0 | 泰文 tactics_board "7→15" 数据 + 3 单运动 L1 sabai 化 |
| `90890db` | **A** | tactics_board en-US/es-ES/fr-FR/zh-Hans/zh-Hant 跨 locale "7→15" + 补全 8 项运动 |
| `899f816` | **B** | 15 single-sport SKU 泰文 subtitle 改战术钩子 |
| `d3cb878` | **C** | 16 EN description L5 前置 trust signal 行 |
| `a08d277` | **D** | ASO_MASTER 重写：574 → 215 行，策略真相源 |
| `05def81` | **E** | 16 EN promo text 改 Q2 2026 时效钩子 + promo rotation SOP |
| `0512347` | **F** | 新增 `SCREENSHOT_CAPTIONS.md`：96 条 EN benefit caption spec |
| `26da8db` | **G** | 10 个非 EN locale × 16 SKU = 160 条 promo 本地化（事件本地化，非机翻） |
| `60f4088` | **H** | 16 个 TH description 前置 sabai trust signal |
| `010051d` | **I** | 48 keyword 文件优化（EN+zh-Hans+zh-Hant × 16 SKU），零 name 重复规则 |
| `ac24de0` | **J** | Pillow caption overlay 工具 + 烤好 91 张 EN 截图 PNG |
| `9f7c629` | **K** | A/B 实验框架 + 4 个高价值 SKU 的 B 变体种子 |

工具/脚本（按用途归类）：
- `tactics_board/tool/aso_fix_desc_dedup.py` — desc 重复去重
- `tactics_board/tool/aso_rewrite_subtitles_en.py` — EN subtitle 批改
- `tactics_board/tool/aso_caption_overlay.py` — **新增**，Pillow caption 烤制（v0）

文档全套：
- `aso/ASO_MASTER.md` — 16-SKU 策略真相源（已包含 promo rotation SOP §8、A/B 链接、keyword SOP §5）
- `aso/SCREENSHOT_CAPTIONS.md` — 96 caption spec + 工具用法 + v0 限制
- `aso/AB_VARIANTS.md` — A/B 实验流程 + 4 个 seeded 变体对
- `aso/SCREENSHOT_SPEC.md` — 截图设计规范（未动）
- `aso/SCREENSHOT_DESIGN.md` — 截图视觉设计（未动）
- `aso/SESSION_HANDOFF.md` — 本文件

---

## ⚠️ 注意

- **千万别擅自 push** —— 13 个 commit 静默累积，等用户确认（也许打包跟下一次 release 一起走）
- `git status` 残留的 splash/LaunchScreen PNG 改动是会话开始前就有的，**不属于 ASO 工作**
- 本轮所有 commit msg 都带 `ASO <X>:` 前缀 + Co-Authored-By 行
- screenshots_captioned/ 新增 91 PNG（~19MB），是 ASO J 的烤制产物

---

## 🟢 剩余可做（每个独立 commit 或独立项目）

| 候选 | 说明 | 工作量 |
|---|---|---|
| **L** | 跨 locale screenshot caption 本地化烤制（zh-Hans/th/ja/ko... × 16 × 6）—— 需先在 `SCREENSHOT_CAPTIONS.md` 加 locale 段，再跑 J 的工具 | 1~2 天（含 raw 重新拍） |
| **M** | tactics_board s2~s6 raw 截图捕获（`appstore_screenshots.dart` 改造） | 半天 |
| **N** | th / ja / ko / es / fr / vi / id / ms keyword 100 字段优化（I 只做了 EN+zh） | 1 天 |
| **O** | promo A/B 实际跑起来 —— 需要 App Store Connect / Analytics 接入 + 决策流程 | 持续 |
| **P** | 把 13 个 ASO commit push 上去 + 跑 fastlane deliver 实际发到 App Store | 半小时（user-triggered） |
| **Q** | Caption tool v1：加设备 mockup 框、SF Pro 字体、`<accent>` 标记支持 #FFD600 | 半天 |

---

## 📌 关键事实速查

- 16 个 App Store SKU：1 全运动（tactics_board）+ 15 单运动
- tactics_board 实际含 15 个 SportType（`lib/models/sport_theme.dart` L33-L103）
- 11 个 locale：`en-US, es-ES, fr-FR, id, ja, ko, ms, th, vi, zh-Hans, zh-Hant`
- 字段限制：subtitle 30 / keywords 100 / promo 170 / description ~4000 / iOS 预览 ~250
- Promo text 是唯一不重审字段 → A/B 主战场
- 176 listings 总盘（16 × 11）— EN 已系统翻新；其他 locale 选择性触
