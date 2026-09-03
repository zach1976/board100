# 广告改动 — 模拟器截屏效果测试记录

按 [`zachs_app_base.md`](../../../zachs_app_base.md) §4.1 执行。
对应改动：[`marketing/ADMOB_GROWTH_PLAN.md`](../../../marketing/ADMOB_GROWTH_PLAN.md) 阶段 A / B3。

- **日期**：2026-07-26
- **设备**：iPhone 17 Pro 模拟器（`EBF03EA4-E6CE-4818-868B-6059FD025192`）
- **构建**：`flutter build ios --simulator --debug --dart-define=SPORT=basketball`
- **广告单元**：Google 官方测试单元（debug 构建自动切换，
  `GADApplicationIdentifier = ca-app-pub-3940256099942544~1458002511`，已核对）
- **前置**：`simctl uninstall` 清空数据容器后重装，确保「首次启动」状态真实
  （⚠️ 只做 `simctl install` 覆盖安装会**保留** SharedPreferences，首启标记还在，
  测不出首启 gate——第一轮就踩了这个坑）

## 结果（连续 5 次冷启动，逐次截图）

| 截图 | 场景 | 期望 | 实际 | 日志 |
| --- | --- | --- | --- | --- |
| `01_firstlaunch_gated.png` | 全新安装首次启动 | 不弹开屏 | ✅ 干净战术板 | `app open gated: first launch` |
| `02_shown_1of3.png` | 第 2 次冷启动 | 弹开屏 | ✅ 测试广告全屏 | `app open SHOWN (1/3 today)` |
| `03_shown_2of3.png` | 第 3 次冷启动 | 弹开屏 | ✅ | `app open SHOWN (2/3 today)` |
| `04_shown_3of3.png` | 第 4 次冷启动 | 弹开屏 | ✅ | `app open SHOWN (3/3 today)` |
| `05_dailycap_noad.png` | 第 5 次冷启动（已达日上限） | 不弹、且不发请求 | ✅ 干净战术板 | `app open load skipped: daily cap 3/3` |

## §4.1 逐条对照

- **广告正常加载** ✅ 开屏测试广告全屏渲染，"Test mode" 徽标 + "Advertisement" 标签正常。
- **布局不溢出** ✅ 无裁切、无 RenderFlex 黄黑条。
- **不遮挡关键 UI/按钮** ✅ 右上角关闭入口（"Continue to app"）清晰可点，
  未被刘海/灵动岛遮挡。
- **关闭后界面恢复正常** ✅ `01` / `05` 显示战术板完整，Move/Draw/Select/Add 工具栏、
  右侧浮动按钮均正常，无残留、无黑屏、无卡死。
- **首启不打扰** ✅ 全新安装首次启动全程无广告。
- **日上限生效** ✅ 3/3 之后不再展示，**且不再发起广告请求**（B3）。

## TapGuard（防误点击）

模拟器无法通过 `simctl` 注入触摸；`osascript` 又拿不到 Simulator 窗口
（macOS TCC 辅助功能权限，见 `~/.claude/lessons-learned.md`）。改用 widget 测试
在真实 widget 树里验证接线，覆盖两个 app 各自不同的注入方式：

- `board100/test/services/tap_guard_test.dart` — 7 项，`TapGuard.wrap(MaterialApp)` 包裹式。
- `ScoreSyncer/FrontEnd/test/util/tap_guard_test.dart` — 10 项，额外覆盖
  `MaterialApp.builder` 注入式，含**连点 +1 计分**与**对话框内点击**（overlay 路由）。

两处均验证：记录 pointer-down ✅、不吞噬下层点击 ✅、空白区域拖拽也记录 ✅、
900ms 窗口边界正确 ✅。

**仍需人工确认一次（唯一未闭环项）**：在真机或能注入触摸的环境里，冷启动瞬间持续
划动战术板，确认日志出现 `app open deferred: finger active`，且松手约 1.2s 后广告才补上。
这是 TapGuard 端到端行为的最后一环，自动化测试覆盖不到。

## 未覆盖

- **插屏**未实拍。board100 的插屏只在「分享成功后」触发（30 天仅 6 次展示），
  且已改为分享流程开始时才预加载（B3）。需要走完整分享流程才能触发，本轮未跑。
- **Android** 未测（本轮只验 iOS）。
- **ScoreSyncer** 未实拍（本轮只跑 board100；两者 TapGuard 接线已由 widget 测试覆盖，
  但 ScoreSyncer 的 gate 体系是既有代码、本次未改动）。
