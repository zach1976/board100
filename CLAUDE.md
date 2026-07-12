# board100

> **本项目须遵循 [`zachs_app_base.md`](../zachs_app_base.md) 中的所有项目通用规范。**

## Project Structure

```
board100/
└── tactics_board/   # Flutter app — multi-sport tactics board
```

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
cd tactics_board
flutter run -d B90045BA-4C79-4484-9CBC-7BD8C520759D  # iPhone 17 simulator (multi-sport hub)
flutter run -d macos                                 # macOS hub (multi-sport, dev)
./tool/build_sport_macos.sh badminton release        # macOS single-sport app (mirrors build_sport.sh)
```

Per-sport model: like iOS, each sport ships as its own app (own bundle id
`com.zach.<sport>Board`, name, and `assets/icon/<sport>_icon.png`). Build a
single-sport macOS app with `tool/build_sport_macos.sh <sport>` — it patches the
name/bundle-id/icon, builds `--dart-define=SPORT=<sport>`, and restores the
working tree. First build of a new bundle id auto-creates its provisioning
profile (Sign in with Apple) via `xcodebuild -allowProvisioningUpdates`.

Platforms: iOS, Android, macOS (`macos/`). Ads (`google_mobile_ads`) have no
macOS build; `AdService` already gates on `Platform.isIOS/isAndroid`, so the Mac
app is ad-free with no code change. macOS signs with team `Q6H46AAX22` (the same
paid team as iOS, whose App ID already has Sign in with Apple); automatic signing
provisions `com.apple.developer.applesignin` (`macos/Runner/*.entitlements`), so
Apple login works. macOS app icon is generated from `assets/icon/app_icon.png`
via `flutter_launcher_icons` (same source as iOS).

## Running Tests

```bash
cd tactics_board
flutter test test/models/ test/state/
