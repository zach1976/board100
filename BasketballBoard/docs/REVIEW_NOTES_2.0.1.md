# Review Notes — Basketball Board 2.0.1 (build 2)

> 提交执行：从 "Dear App Review team" 到 "Thank you..." 写入 App Review
> Information。线上版本是 **2.0.0**，所以这是一次小版本修补：欢迎页换成实拍
> 底图，以及欢迎页期间不再出现 app-open 广告。
>
> **送审前必须确认**（zachs_app_base.md 6.4）：账号当前没有其他 app 在审，
> 距上一个过审 ≥1 周。16 个 app 一次只送一个。
>
> **真机 QA 未做**：下面「What was tested」写的是模拟器，没有真机声明。
> 跑完 `DEVICE_QA` 清单后再把机型和日期补进去——写做过的，不写没做的。

---

Dear App Review team,

Basketball Board 2.0.1 is a small fix release over 2.0.0. No new features, no
new permissions, no new network endpoints, and no change to what the app
collects or sends.

## What changed since 2.0.0

1. The three onboarding screens now carry photographic backdrops of a tactics
   board on a basketball court, in place of the flat gradient they showed
   before. The artwork ships inside the bundle; nothing is downloaded.
2. The app-open ad is suppressed for as long as the onboarding screens are on
   screen. On a fresh install an app-open ad could appear a few seconds in,
   on top of the welcome screens, before the user had reached the app at all.
   It now waits until onboarding is finished and the app is in use.
3. Minor positional corrections to five of the built-in drill boards so that
   no two figures overlap.

Ad behaviour is otherwise unchanged from 2.0.0: ads are non-personalized, are
rate-limited, and are suppressed on the screens where a coach is actually
running a session. Nothing was added to hide ads from review — the daily cap,
the minimum gap and the background rules apply identically to every user,
including a first session.

## Store compliance

4. The description carries the standard EULA link and the privacy policy
   link in every localization.
5. The app does not present App Tracking Transparency. Ads are
   non-personalized, the bundle ships a privacy manifest declaring
   `NSPrivacyTracking = false`, and the App Privacy label declares no
   tracking. These three agree.

## How to see it

Delete the app and install this build: the three welcome screens appear on
first launch, each on its own photograph, with no ad over them. "Skip" or
"Start" takes you into the app, where the rest of 2.0.0 is unchanged — Drills
→ any card → "Put on the board" → press play.

## What was tested

Run on the iOS Simulator (iPhone and iPad, iOS 26/27): a clean install
through all three onboarding screens with ads in test mode, confirming no
app-open ad appears over them and that one is served normally afterwards;
then the home page, the drill library, loading a drill onto the board and
stepping through it. The full automated suite — 564 tests — passes.

Thank you for reviewing.
