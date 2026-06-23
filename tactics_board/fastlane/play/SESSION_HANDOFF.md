# Google Play 发布 · 会话续接备忘

---

## 🆕 会话存档 2026-06-23 — 4 个上架 app 换 V2 截图 + 推送 Play

把 **basketball / badminton / soccer / volleyball** 4 个 Play app 的截图换成 App Store 同款
**V2「PLAN EVERY RALLY」设计**，并推送到 Google Play（含 11 语言 listing 文本 + 图形），4/4 自动送审成功。

- **尺寸坑**：V2 合成器出 1290×2796（App Store 6.7"），比 Play 的 **≤2:1** 上限更高 → Play 拒。
  新工具 `tool/play_v2_screenshots.py` 复用 `aso_design_compositor.py`（零改动），**只猴补丁画布到
  1440×2868**；手机截图锁定原宽高比，加宽画布只是加宽深蓝边距，不变形。
- **生成**：`python3 tool/play_v2_screenshots.py basketball soccer volleyball badminton`
  → 覆盖各 `fastlane/play/<sport>/metadata/android/en-US/images/phoneScreenshots/{1..6}.png`（24 张，1440×2868 / 24-bit / 无 alpha）。
- **推送**：`python3 tool/play_push.py --commit basketball badminton soccer volleyball`
  （androidpublisher Edits API，service account `~/projects/keys/learnthai-play-api.json`，
  推 11 语言 listing 文本 + en-US icon/featureGraphic/6 截图，自动送审）。先 DRY-RUN 4/4 过再 commit。
  ⚠️ **本次只推 listing+图形，未推新 AAB**——应用包没动。
- **目录迁移**：仓库从 `~/Desktop/projects/board100` 移到 `~/projects/board100`；硬编码路径已全量
  替换并 commit（`7f77920`，50 文件 / 66 路径），`flutter clean` 清掉旧构建缓存。
- **Git**：分支 `aso/screenshots-v2`，已推 origin。`7f77920` 路径迁移 → `5a05740` Play V2 图+工具。
- **待办**：Play 审核几小时~1~2 天才上线；其余 12 个未上架运动若要做，需先在 Play Console 手建 app 再
  `play_v2_screenshots.py --all` + `play_push.py`。

---

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
