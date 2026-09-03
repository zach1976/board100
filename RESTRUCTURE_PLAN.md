# board100 目录结构改造执行计划 — 对齐 ScoreSyncer 模式

> 目标：把「一个 Flutter 工程 + 构建时打补丁出 16 个 app」改成 ScoreSyncer 的
> 「共享核心包 + 每个 app 一个薄壳目录」。补丁-还原机制（`build_sport.sh` 系列）
> 是这次 Codex review 里 macOS 图标被 footvolley 残留覆盖那类事故的根源，
> 改造后彻底消失。

## 现状 vs 目标

```
现在                                   目标（对齐 ScoreSyncer）
board100/                              board100/
├── backend/                           ├── backend/            # 不动
├── tactics_board/   ← 唯一工程         ├── tactics_board/      # = ScoreSyncer 的 FrontEnd/
│   ├── lib/  (SPORT dart-define)      │     核心包 + hub app（com.zach.tacticsBoard 本身也是 16 个上架 app 之一）
│   └── tool/build_sport*.sh           ├── SoccerBoard/        # 薄壳 ×15：只有平台目录 + lib/main.dart（≈20 行）
│         （打补丁→构建→还原）           ├── BasketballBoard/
└── screenshots/ 等                    ├── ...（BadmintonBoard / FootvolleyBoard 等）
                                       ├── tools/              # 发布脚本上移到仓库级（原 tactics_board/tool/）
                                       └── screenshots/ 等
```

ScoreSyncer 薄壳的本质（以 `BadmintonPoints/` 为参照）：
- 壳里 `lib/` **只有一个 `main.dart`**：设置 `ConfigConstants`（固定运动、广告单元 id、
  IAP 前缀、`hasPackagePath=true`）然后调核心包的 `main_real()`；
- 壳有**自己的** ios/android/macos 平台目录：bundle id、图标、闪屏、签名、
  Info.plist（GADApplicationIdentifier、本地化名）全部**落盘提交**，不再运行时打补丁；
- 核心包通过 `path: ../tactics_board/` 依赖。

## 硬性不变量（违反任何一条 = 变成新 app / 上架事故）

1. **Bundle ID / applicationId 一字不差**：iOS 与 Android 同为 `com.zach.<sport>Board`
   （对照表 = `tool/build_sport.sh` 里的 case 表，作为唯一事实来源抽出）。
2. 签名团队 `Q6H46AAX22`；自动签名会按 bundle id 自动出 profile（现有行为）。
3. 每壳 Info.plist 必须带对的 `GADApplicationIdentifier`（case 表里那 15 个 `~` id；
   sepakTakraw 无广告用 Google 样例 id）、`UIStatusBarHidden`、权限文案、
   Sign in with Apple entitlements、`*.lproj/InfoPlist.strings` 本地化显示名。
4. IAP 商品 id 由 sport 前缀生成（`<sport>_remove_ads_lifetime` 等），
   核心里逻辑不变，壳只提供 sport 名。
5. 版本延续：所有壳 pubspec 版本与核心一致（当前 1.1.25+1），永不回退。
6. **先发完 1.1.25 再动手**。改造期间不夹带发布；1.1.25 从现结构出包。

## Phase 0 — 核心包改造（不动目录，先把补丁点变成运行时配置）｜~1 天

- [ ] 新建 `lib/config_constants.dart`（对齐 ScoreSyncer 命名）：
      `fixedSportType`、`enableAds`、`adIos/AndroidAppOpen/InterstitialUnitId`、
      `removeAdsSportPrefix`、`hasPackagePath`。
- [ ] `main()` 拆成可导出的 `main_real()`；hub 自己的 `main.dart` 用默认配置调用它。
- [ ] `String.fromEnvironment('SPORT')` / `HUB_ADS` 改读 ConfigConstants，
      **dart-define 作为默认值保留**（过渡期两条路都能跑，等 16 壳全验证过再删）。
- [ ] `ad_service.dart` 里 per-sport 广告单元 map：改为壳注入（ScoreSyncer 模式），
      map 降级为 hub/dart-define 路径的后备。
- [ ] **资产包前缀**（最大的代码工作量）：核心被壳引用时，`Image.asset`、
      `rootBundle`、`easy_localization` 的 `path:` 都要走
      `packages/tactics_board/assets/...`。做一个 `assetPath(String p)` 助手统一收口，
      全库替换；hub 内运行时前缀为空。用 `grep -rn "assets/" lib/` 清点，逐处过。
- [ ] 验收：hub 与 `--dart-define=SPORT=badminton` 两种老构建产物与改造前无行为差异。

## Phase 1 — 首个薄壳试点（BadmintonBoard/）｜1–2 天

- [ ] 以 `tactics_board/ios|android|macos` 为模板复制出壳的平台目录
      （**不要**裸 `flutter create`——会丢 Podfile 定制、entitlements、lproj、gradle 签名配置），
      再落盘改：bundle id、显示名、GADApplicationIdentifier、图标、闪屏。
- [ ] `lib/main.dart` ≈20 行：set config → `main_real()`（照抄 BadmintonPoints 的形状）。
- [ ] pubspec：`tactics_board: {path: ../tactics_board}`；
      `flutter_launcher_icons` / `flutter_native_splash` 指向核心包的
      `assets/icon/badminton_icon.png` / `badminton_splash.png`，**生成一次、提交**。
- [ ] 验收清单（对照 `build_sport.sh badminton` 的产物逐项比）：
      bundle id / 显示名（含 zh/ja 本地化）/ 图标 / 闪屏 / 广告测试模式弹出 /
      IAP 商品 id / Apple 登录 / 12 语言文案 / 真机 + 模拟器各跑一遍。
- [ ] TestFlight 传一个 build（**遵守送审节奏铁律，只传不送审**）。

## Phase 2 — 批量生成其余 14 壳｜~0.5 天

- [ ] case 表抽成 `tools/sports.tsv`（sport、bundle id、EN/ZH/JA 名、AdMob app id、单元 id）。
- [ ] `tools/gen_sport_shell.sh <sport>`：从 BadmintonBoard 模板复制 + 按表替换。
- [ ] 逐个 `flutter build ios --simulator` 冒烟；抽 3 个装真机验图标/名字/广告。

## Phase 3 — 发布管线切换｜~1 天

- [ ] `tactics_board/tool/` → 仓库级 `tools/`（对齐 ScoreSyncer/tools）。
- [ ] `build_all_ipa.sh`：从「16 次补丁-构建-还原」改为「cd 各壳目录直接 build」，
      从此可并行、无残留。`verify_ipas.py` 不变（它验的是产物）。
- [ ] `build_sport_android.sh` 同理改为 per-壳 AAB；Play 的 per-app versionCode 逻辑保留。
- [ ] **删除** `build_sport.sh` / `build_sport_android.sh` / `build_sport_macos.sh`
      及所有 `.bak`/trap-restore 机制（确认无引用后）。
- [ ] `release_1_1_2x.sh` 模板、fastlane metadata 路径核对（metadata 本身不动）。

## Phase 4 — 收尾｜~0.5 天

- [ ] 各壳 `build/`、`.dart_tool/` 进 gitignore；壳的 pubspec.lock 提交。
- [ ] CLAUDE.md 的 Project Structure / Running the App 全部重写；
      README、记忆文件、`HOWTO_截图` 引用路径更新。
- [ ] 删除核心里 dart-define 过渡代码（全壳验证之后的独立 commit）。

## 风险与回滚

- 最大风险 = **资产包前缀遗漏**：症状是壳 app 里图片/翻译加载失败但 hub 正常。
  Phase 0 的 `assetPath()` 收口 + Phase 1 的 12 语言过一遍是主要防线。
- 次风险 = 平台目录抄漏某个键（权限文案 / ATT / encryption exempt）。
  Phase 1 的逐项对照清单负责兜住；后续 15 壳由脚本从已验证模板生成，不手抄。
- 回滚：改造分支独立（`restructure/sport-shells`），老构建路径在 Phase 0-2 期间
  始终可用；任何时候 main 都能按旧法出包。
- 仓库体积：16 套平台目录约 +30–50MB 源文件，可接受；IPA 类产物已 gitignore。

## 明确不做（本次范围外）

- 不改 `backend/`、website、fastlane metadata 内容本身；
- 不引入 ScoreSyncer 的 `zach_base` 依赖（board100 核心目前不用它）；
- macOS 壳目录会生成但不发布（macOS 策略仍是 hub-only、暂停状态）；
- 不在改造中夹带任何功能/UI 改动。

**总量级：约 4–5 个工作日，其中 Phase 0 的资产路径收口和 Phase 1 的试点验收是大头。**
