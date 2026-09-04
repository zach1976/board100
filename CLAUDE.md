# board100

## 💰 会产生费用的操作：必须三次确认 ★强制（2026-08-26 用户指令）

**任何会产生真实费用的操作（计费 API 调用、enable 计费服务、云资源创建、付费下单等），
必须获得用户三次独立的明确许可才可以执行。** 细则见
[`zachs_app_base.md`](见本项目引用路径) 同名章节;免费替代映射见
`AlphabetLearningFramework/docs/cost_audit_2026-08-26.md`。

> **本项目须遵循 [`zachs_app_base.md`](../zachs_app_base.md) 中的所有项目通用规范。**

## Project Structure

```
board100/
├── tactics_board/     # the shared core package AND the multi-sport hub app
│                      # (com.zach.tacticsBoard) — all Dart code lives here
├── SoccerBoard/       # single-sport apps. Each owns everything that is only
├── BasketballBoard/   # its own:
├── BadmintonBoard/    #   lib/main.dart        ~20 lines: config + mainReal()
├── ...  (15 apps)     #   ios|android|macos/   bundle id, plists, icons
│                      #   assets/icon/         app_icon.png, splash_logo.png
│                      #   fastlane/metadata/   App Store text per locale
│                      #   fastlane/screenshots/
│                      #   fastlane/play/       Play listing
├── tools/             # cross-app tooling: sports.tsv (the source of truth
│                      # for all 16 apps), apps.py (path resolver), shell
│                      # generator, build/release scripts
└── backend/
```

The core keeps only what every app shares: the Dart code, the translations,
the two in-game ball images, `assets/preview/`, and fastlane's Appfile /
Fastfile. Scripts must not hardcode per-app paths — import `tools/apps.py`
(`metadata_dir(key)`, `screenshots_dir(key)`, `play_metadata_dir(key)`,
`icon_source(key)`) so the table stays the only mapping.

**One app = one directory.** A build never patches another app's files: bundle
ids, display names, AdMob app ids, icons and splash screens are committed
inside each shell. (Before 2026-09, all 16 apps came out of `tactics_board/`
by `sed`-ing its project files and restoring them afterwards — that is how a
`footvolley` macOS build once left its icon committed as the hub's.)

Adding or refreshing an app:

```bash
tools/gen_sport_shell.sh soccer   # regenerates SoccerBoard/ from tools/sports.tsv
tools/gen_sport_shell.sh all      # all 15 shells
```

`tools/sports.tsv` is the only place app identity is written down: key,
directory, bundle id, EN/ZH/JA display names, iOS + Android AdMob app ids.
**Never edit a shell's identity by hand** — change the table and regenerate.

## AI Code Editing Rules

1. Never modify code that already works.
2. Only apply the minimal change required.
3. Do not refactor unrelated code.
4. Do not rename variables or functions unless required.
5. Preserve code structure and formatting.
6. Prefer small diffs instead of rewriting files.
7. If uncertain, leave the code unchanged.

## Running the App

```bash
cd tactics_board && flutter run          # multi-sport hub (all sports, dev)
cd SoccerBoard   && flutter run          # one single-sport app
cd tactics_board && flutter run -d macos # macOS hub
```

Every app is a normal Flutter project — run, debug and profile it directly.
Release builds:

```bash
tools/build_all_ipa.sh                 # all 16 IPAs → build/ipa_all/
tools/build_all_ipa.sh soccer          # just one
BUILD_NUMBER=5 tools/build_all_aab.sh tactics_board   # Play bundle (6 apps only)
```

First build of a new bundle id auto-creates its provisioning profile (Sign in
with Apple) via `xcodebuild -allowProvisioningUpdates`.

Platforms: iOS, Android, macOS (`macos/`). Ads (`google_mobile_ads`) have no
macOS build; `AdService` already gates on `Platform.isIOS/isAndroid`, so the Mac
app is ad-free with no code change. macOS signs with team `Q6H46AAX22` (the same
paid team as iOS, whose App ID already has Sign in with Apple); automatic signing
provisions `com.apple.developer.applesignin` (`macos/Runner/*.entitlements`), so
Apple login works. Each app's macOS icon is generated once by `tools/gen_sport_shell.sh` (from
`tactics_board/assets/icon/<sport>_icon.png`) and committed, same as iOS.

## Running Tests

```bash
cd tactics_board
flutter test test/models/ test/state/
