# Google Play 发布 · 会话续接备忘

> 最后更新：2026-05-19
> 状态：篮球/足球/排球/羽毛球 4 个 app 的 Google Play 素材已全部产出，**未 commit**。
> 范围：文案 + 图形 + 签名 AAB，store listing 仅 en-US。

---

## ✅ 本次会话完成

| 项 | 产物 | 位置 |
|---|---|---|
| 商店文案 | title / short_description / full_description / changelogs/1.txt | `fastlane/play/<sport>/metadata/android/en-US/` |
| 图形 | icon 512×512、featureGraphic 1024×500、phoneScreenshots 1440×2868 ×6 | 同上 `images/` |
| 签名 AAB | `<sport>-1.1.12.aab`（114/113/112/113 MB，上传密钥签名） | `build/aab_play/` |
| 签名配置 | upload keystore + key.properties + build.gradle.kts release signingConfig | `android/`（前两者 gitignore） |
| 工具 | `gen_play_assets.py`、`build_sport_android.sh` | `tool/` |
| 文档 | `README.md`（用法）、本文件 | `fastlane/play/` |

## 📦 4 个 app

| sport | applicationId | 应用名 | versionName+Code |
|---|---|---|---|
| basketball | `com.zach.basketballBoard` | Basketball Board | 1.1.12 (code 1) |
| soccer     | `com.zach.soccerBoard`     | Soccer Board     | 1.1.12 (code 1) |
| volleyball | `com.zach.volleyballBoard` | Volleyball Board | 1.1.12 (code 1) |
| badminton  | `com.zach.badmintonBoard`  | Badminton Board  | 1.1.12 (code 1) |

applicationId 与 iOS bundle ID 一致，**Play 首次上架后不可更改**。

## ⚠️ 关键事项

- **上传密钥库务必备份**：`android/upload-keystore.jks` + `android/key.properties`（含密码，已 gitignore）。丢失 = 这 4 个 app 永远无法更新。
- 截图用的是 App Store 同款**原始截图**（`fastlane/screenshots/`，4/6 抓取），**不含 5/16 的 UI 改动**（size-to-content sheet、timeline 头像）。如需反映最新 UI 要重跑截图自动化。
- AAB 约 113 MB（每个单运动 app 都打包全部素材，与 iOS 76 MB IPA 同源）；Play 动态分发后实际下载会小很多。

## 🟢 剩余 / 待办

| 项 | 说明 |
|---|---|
| commit | 本次产物尚未 commit（新增 `fastlane/play/`、2 个 tool 脚本，改 `build.gradle.kts`） |
| Play Console 表单 | 内容分级问卷、数据安全表单、隐私政策 URL、应用分类、目标受众、国家/定价——非文件素材，需网页端手填 |
| 上传 | 手动上传 AAB+素材，或配 service account JSON 跑 `fastlane supply`（见 README） |
| 其他语言 | 当前仅 en-US；后续可补 zh-CN/zh-TW 等（Play 语言代码与 iOS 略不同） |
| 最新 UI 截图 | 如要截图反映 5/16 之后的 UI，重跑截图自动化重拍 4×6 |

## 🛠️ 复现命令

```bash
python3 tool/gen_play_assets.py all                                  # 重生成图形素材
./tool/build_sport_android.sh basketball soccer volleyball badminton  # 重建签名 AAB
```

详见 `fastlane/play/README.md`。
