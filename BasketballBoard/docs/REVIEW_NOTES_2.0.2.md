# Review Notes — Basketball Board 2.0.2 (build 4)

> 提交执行：从 "Dear App Review team" 到 "Thank you..." 写入 App Review
> Information。线上是 2.0.1；这一版修的是板子在 iPad／横屏下的几何错位。
>
> **送审前必须确认**（zachs_app_base.md 6.4）：账号当前没有其他 app 在审。
> **真机 QA 未做**：下面写的是模拟器和 Mac，没有真机声明。

---

Dear App Review team,

Basketball Board 2.0.2 is a fix release over 2.0.1. No new features, no new
permissions, no new network endpoints, and no change to what the app collects
or sends.

## What changed since 2.0.1

1. The court is centred inside the board at its own aspect ratio, and on a
   wide screen — an iPad, a Mac window, a phone turned sideways — it is fitted
   by width rather than by height. The players and the ball were placed
   against the canvas instead of against the court, so on those screens a
   layup finished past the end line and the shooter stood on the rim. They are
   now placed against the court and sit where the lines say, at any size.
2. The 58 built-in drill boards were re-measured in the frame their
   coordinates mean, so the two agree.
3. A player warming up with two balls has one at either side of him instead of
   one in front and one behind.
4. Turned sideways, the floating menu, page and zoom buttons sat on the
   playing surface; the board now starts inside them.
5. The small board pictures on the home screen and on a drill are drawn the
   same way round as the board they open.

## Store compliance

6. The description carries the standard EULA link and the privacy policy link
   in every localization.
7. The app does not present App Tracking Transparency. Ads are
   non-personalized, the bundle ships a privacy manifest declaring
   `NSPrivacyTracking = false`, and the App Privacy label declares no
   tracking. These three agree.

## How to see it

Open the app → Drills → "Layup lines" → "Put on the board" → press the step
arrow twice. On an iPad, or with the phone turned sideways, the shot finishes
in the basket and both players stand inside the key.

## What was tested

Run on the iOS Simulator (iPhone and iPad, iOS 26/27) and on macOS on an
Apple silicon Mac at 1440x900: the board upright and turned sideways, the
drill library, loading a drill onto the board and stepping every beat of it,
and the practice plan. The automated suite — 565 tests — passes, and one of
them walks all sixteen sports' drill libraries, every board at every beat, at
a Mac window's shape, checking that no player and no ball is drawn off the
court.

Thank you for reviewing.
