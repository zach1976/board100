# ASO 战役 · 会话续接备忘

---

## 🆕 会话存档 2026-06-22 — 截图设计 V2 全量重做

把 16 个 board app 的 App Store 截图换成新设计 V2「PLAN EVERY RALLY」:
**16 运动 × 11 语言 × 6 幕 = 1056 张**,并**撤回 1.1.19 审核 → 换图 → 全部重提成功**
(16/16 回到 WAITING_FOR_REVIEW,零错误)。审核计时重置,预计再排队 1–2 天。

- 设计:深蓝渐变 + 每运动场地线背景 + 运动图标水印 + 钛框手机(灵动岛/倒影)
  + TACTICS BOARD 徽章 + 双行白/绿大标题 + 副标题(1290×2796)。
  6 幕:空场→站位→时间轴→Add菜单→路线→回放。旗舰 6 幕展示 6 个不同运动。
- 工具(tactics_board/):`tool/aso_design_compositor.py`(合成 `--all`)、
  `test/export_glyphs_test.dart`(导 SportGlyph 图标)、
  `integration_test/appstore_screenshots.dart` + `tool/capture_v2.sh`(重截)、
  `tool/build_captions_v2.py` + `aso/captions_v2.json` + `aso/captions_loc/`(文案/11 语言)、
  `tool/resubmit_v2.py`(撤回+换图+重提)。
- 文档:`board100/SCREENSHOT_PIPELINE_V2.md`(工具参考)、`board100/HOWTO_截图设计_多语言.md`(方法)。
- 踩坑:撤回 IN_REVIEW 后变 DEVELOPER_REJECTED(可编辑可上传);pubspec 的 `integration_test`
  跑捕获时临时开、**已改回注释 + pub get**;不用真器材摄影图,统一扁平 SportGlyph。
  ⚠️ `flutter pub get` 不会回滚 **ios/Podfile.lock** 里被 pod install 写入的 `integration_test`
  —— 必须手动 `git checkout ios/Podfile.lock` 还原,否则下次 iOS 发版被 App Store 拒。已还原。
- Git:分支 `aso/screenshots-v2`,已推送 origin,最新 `26e0579`。
  commits:`90cb155` V2 截图+工具+原图 → `37b70b0` 方法文档+存档 → `26e0579` gitignore 预览产物。
  `aso/sample_v2/` 与 `design_sample_badminton_s1.png` 已 gitignore;工作区干净。

---

> 最后更新：2026-05-14（**v1.1.11 已全部提交审核**）
> 状态：A~Q + P 完成。**26 个 ASO commit 已 push 到 origin/main。**
> 角色：用户以 15 年 App Growth Hacker / CMO 身份协作

---

## ✅ 上线情况

### Phase 1：promo text 直接 PATCH 到 live（无需审核）
- **176 个 promo text** PATCH 上 App Store v1.1.10 live 版本（commit `34c453f` 的工具 `tool/upload_promo_only.py` 直推 ASC API）
- 16 app × 11 locale 全 Q2 2026 时效钩子（世界杯 6/11 / NBA finals / 法网 / 夏季沙滩季等）
- 几分钟内出现在 App Store 搜索结果

### Phase 2：v1.1.11 metadata-only release（已提交审核）
| 阶段 | 工具 | 结果 |
|---|---|---|
| 2a bump + release_notes | pubspec + `metadata/*/release_notes.txt` × 176 | `6a85ccc` commit |
| 2b build 16 IPAs | `tool/build_all_ipa.sh` | 20 min wall time，16 IPA in `build/ipa_all/`，每个 76-79 MB |
| 2b altool upload | `tool/upload_all_ipa.sh` | 5 min 16 IPA 上 ASC（zero hangs） |
| 2c ASC build processing | 自然等 | 20 min，全 16 builds → VALID |
| 2c create v1.1.11 versions | `tool/create_versions_1_1_11.py`（新） | 16/16 draft 创建并 attach build |
| 2c upload metadata | `fastlane upload_all_metadata` | 16 app × 11 locale × {description/subtitle/keywords/release_notes/promo} PATCH 到 v1.1.11 draft |
| 2d submit for review | `tool/submit_all.py`（v=1.1.11） | **16/16 → WAITING_FOR_REVIEW** |

**Apple 审核期：1~3 天 / app**。监控：`python3 tactics_board/tool/check_app_status.py`

---

## 📦 已落地（26 个 commit · 全部 pushed 到 origin/main）

| Commit | 任务 | 内容 |
|---|---|---|
| `c4b5710` | P0 | 16 EN subtitle benefit 钩子 + desc "<App> — <App>" 去重 |
| `c6ba761` | TH-P0 | 泰文 tactics_board "7→15" + 3 单运动 L1 sabai |
| `90890db` | **A** | tactics_board 5 locale "7→15" + 补 8 项运动 |
| `899f816` | **B** | 15 single-sport TH subtitle 战术钩子 |
| `d3cb878` | **C** | 16 EN description trust signal 前置 |
| `a08d277` | **D** | ASO_MASTER 重写策略真相源 |
| `05def81` | **E** | 16 EN promo Q2 2026 时效钩子 + rotation SOP |
| `0512347` | **F** | 96 EN caption spec |
| `26da8db` | **G** | 10 非 EN locale × 16 SKU = 160 条 promo 本地化 |
| `60f4088` | **H** | 16 TH desc sabai trust signal |
| `010051d` | **I** | 48 keyword 文件（EN+zh-Hans+zh-Hant × 16） |
| `ac24de0` | **J** | Pillow caption tool v0 + 91 EN PNG |
| `9f7c629` | **K** | A/B 框架 + 4 SKU 种子变体 |
| `e5c5d1e` | — | SESSION_HANDOFF 转入 git |
| `269d985` | **N** | 80 keyword（th/ja/ko/es-ES/fr-FR × 16） |
| `53b5831` | **L** | 480 localized captions + 172 PNG |
| `da415de` | **M** | tactics_board s2~s6 raws + 重烤 |
| `d3b001f` | **Q** | Caption tool v1：圆角 + accent + font flag |
| `14cc343` | — | handoff sync |
| `c575de9` | — | MASTER §5 status update |
| `34c453f` | **P1** | `upload_promo_only.py` + 176 promo live PATCH 到 v1.1.10 |
| `6a85ccc` | **P2a** | pubspec 1.1.10→1.1.11 + 176 release_notes 重写 |
| `5acd6a9` | **P2c-prep** | Fastfile APPS 补 8 app + submit_all → 1.1.11 |
| `13cb43f` | **P** | `tool/release_1_1_11.sh` 端到端编排 |
| `acbf645` | **P** | `tool/wait_builds_processed.py` ASC 轮询 |
| `0a3cea4` | **P** | strip edit_live + skip Phase 4b screenshots |
| `c78a7ee` | **P** | `tool/create_versions_1_1_11.py` + Phase 3.5 |

---

## 🛠️ 工具栈（已落库）

- `tool/aso_fix_desc_dedup.py` — desc 去重（早期）
- `tool/aso_rewrite_subtitles_en.py` — EN subtitle 批改（早期）
- `tool/aso_caption_overlay.py` v1 — Pillow caption 烤制（5-locale 字体、圆角、`<a>` accent、`--font-path`）
- `tool/upload_promo_only.py` — 直推 promo 到 live（无审核）
- `tool/create_versions_1_1_11.py` — 创 App Store Version draft + attach build
- `tool/wait_builds_processed.py` — ASC build VALID 轮询
- `tool/release_1_1_11.sh` — 5 阶段端到端编排器，checkpoint-resumable
- `tool/submit_all.py` — 16 app 提交审核（v=1.1.11）

---

## 📋 文档真相源

- `aso/ASO_MASTER.md` — 16-SKU 策略真相源（locale 调性、copy 模式、keyword SOP、promo SOP、A/B 链接）
- `aso/SCREENSHOT_CAPTIONS.md` — 16 SKU × 6 shot × 6 locale = 576 caption + 工具用法
- `aso/AB_VARIANTS.md` — A/B 实验流程 + 4 个种子变体
- `aso/SCREENSHOT_SPEC.md` — 截图设计规范
- `aso/SESSION_HANDOFF.md` — 本文件

---

## 🟢 剩余 / 长期项

| 候选 | 说明 | 时机 |
|---|---|---|
| **审核监控** | Apple 1~3 天 / app · 关注是否触发审查员关注（截图未改风险较小） | 日常 |
| **被拒应对** | 万一某 app 被拒，看 ASC reviewSubmissions 错误码，按 `tool/fix_rejected_resubmit.py` 走 | 应急 |
| **截图 v1.1.12** | 现在 v1.1.11 用旧截图。等 designer 把 96 caption 跨 11 locale 补齐 + 设备 mockup 框，下版本 ship | 下个 release |
| **vi/id/ms keyword** | 48 文件，需 native research | 半天 |
| **promo A/B 实战** | K 已 seeded 4 个 B 变体 · 等 v1.1.11 上线后开第一轮 | v1.1.11 通过后 1 周 |
| **CVR 复盘** | 30 天后看 ASO_MASTER §10 changelog 哪些改动真升 | 上线 30 天后 |

---

## 📌 关键事实速查

- 16 个 App Store SKU：1 全运动（tactics_board）+ 15 单运动
- 11 个 locale：`en-US, es-ES, fr-FR, id, ja, ko, ms, th, vi, zh-Hans, zh-Hant`
- 字段限制：subtitle 30 / keywords 100 / promo 170 / description ~4000 / iOS 预览 ~250
- Promo text 唯一不重审字段 → A/B 主战场
- v1.1.11 = metadata-only：代码不变，仅 ASO 内容刷新
- 审核通过后，v1.1.10 → v1.1.11 自动替换 live；如审核被拒，可在 ASC 撤回并重提
