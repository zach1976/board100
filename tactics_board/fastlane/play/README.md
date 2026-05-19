# Google Play 发布素材

篮球 / 足球 / 排球 / 羽毛球 4 个单运动 app 的 Google Play 上架素材。
当前 store listing locale：**仅 en-US**（其余语言后续再补）。

## 4 个 app

| sport | applicationId | 应用名 (en) | versionName+Code |
|---|---|---|---|
| basketball | `com.zach.basketballBoard` | Basketball Board | 1.1.12 (code 1) |
| soccer     | `com.zach.soccerBoard`     | Soccer Board     | 1.1.12 (code 1) |
| volleyball | `com.zach.volleyballBoard` | Volleyball Board | 1.1.12 (code 1) |
| badminton  | `com.zach.badmintonBoard`  | Badminton Board  | 1.1.12 (code 1) |

applicationId 与 iOS `build_sport.sh` 的 bundle ID 一致。**Play 首次上架后不可更改。**

## 目录结构

```
fastlane/play/<sport>/metadata/android/en-US/
  title.txt              应用名称        (≤30 字符)
  short_description.txt  简短说明        (≤80)
  full_description.txt   完整说明        (≤4000)
  changelogs/1.txt       版本更新说明，文件名 = versionCode (≤500)
  images/
    icon.png                   512×512   应用图标
    featureGraphic.png         1024×500  特色图片
    phoneScreenshots/1..6.png  1440×2868 手机截图 (App Store 原图，边缘复制补边到比例 1.99)
```

文本素材改写自 iOS App Store 文案（`fastlane/metadata/<sport>/en-US/`），
已把 "AirPlay to TV" 改成平台中性的 "mirror to a TV"。
截图直接用 App Store 同款原始截图（`fastlane/screenshots/<sport>/en-US/`），
1320×2868 超出 Play 的 ≤2:1，按行复制最边缘像素向外补到 1440 宽（无缝衔接球场色/工具栏色）。

## 签名

- 上传密钥库：`android/upload-keystore.jks`  —— 已 gitignore
- 凭据文件：`android/key.properties`         —— 已 gitignore
- ⚠️ **务必把这两个文件 + 密码备份到安全的地方。丢失即无法再更新这 4 个 app。**
- `android/app/build.gradle.kts` 已配置：`key.properties` 存在时用 release 签名，
  否则回退 debug 签名（保证 `flutter run --release` 仍可用）。

## 重新生成图形素材

```bash
python3 tool/gen_play_assets.py all          # 或 basketball / soccer / ...
```
来源：`assets/icon/<sport>_icon.png`、`<sport>_splash.png`、
`fastlane/screenshots/<sport>/en-US/`（与 App Store 一致的原始截图）。

## 构建签名 AAB

```bash
./tool/build_sport_android.sh basketball soccer volleyball badminton
```
逐个 patch applicationId + 本地化 app_name + 图标/启动图，构建后自动还原所有改动。
产物：`build/aab_play/<sport>-1.1.12.aab`（已用上传密钥签名）。

## 上传到 Google Play

**方式 A — 手动（Play Console 网页）**
各 app 分别上传 `build/aab_play/<sport>-1.1.12.aab`，store listing 直接复制本目录文本/图片。

**方式 B — fastlane supply**（需 Play Console service account JSON）
```bash
fastlane supply \
  --aab build/aab_play/basketball-1.1.12.aab \
  --metadata_path fastlane/play/basketball/metadata \
  --package_name com.zach.basketballBoard \
  --json_key <service-account>.json
```

## Play Console 仍需手动完成（非文件素材）

- 应用分类 / 标签
- 内容分级问卷（IARC）
- 目标受众与内容（Target audience）
- 隐私政策 URL
- 数据安全表单（Data safety）
- 国家/地区与定价（免费）
