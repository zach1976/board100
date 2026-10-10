# Review Notes — Field Hockey Board 2.0.1 (build 2)

> 提交执行：从 "Dear App Review team" 到 "Thank you..." 写入 App Review
> Information。线上是 2.0.0；这一版修的是板子的几何错位。
>
> **送审前必须确认**（zachs_app_base.md 6.4）：账号当前没有其他 app 在审。
> **真机 QA 未做**：下面写的是模拟器和 Mac，没有真机声明。

---

Dear App Review team,

Field Hockey Board 2.0.1 is a fix release over 2.0.0. No new features, no new
permissions, no new network endpoints, and no change to what the app collects
or sends.

## What changed since 2.0.0

1. The pitch is centred inside the board at its own aspect ratio, and on a
   wide screen — an iPad, a Mac window, a phone turned sideways — it is fitted
   by width rather than by height. The players and the ball were placed
   against the canvas instead of against the pitch, so on those screens the
   whole move sat several metres off the lines. They are now placed against
   the pitch and stand where the lines say, at any size. All 36 drill boards
   were re-measured in the frame their coordinates mean.
2. A player warming up with two balls has one at either side of him instead of
   one in front and one behind.
3. Turned sideways, the floating menu, page and zoom buttons sat on the
   playing surface; the board now starts inside them. On an iPad the playback
   bar and the tool bar share one row, so the pitch gets that height back.
4. The small board pictures on the home screen and on a drill are drawn the
   same way round as the board they open.

## Store compliance

5. The description carries the standard EULA link and the privacy policy link
   in every localization.
6. The app does not present App Tracking Transparency. Ads are
   non-personalized, the bundle ships a privacy manifest declaring
   `NSPrivacyTracking = false`, and the App Privacy label declares no
   tracking. These three agree.

## How to see it

Open the app → Drills → any card → "Put on the board" → step through it.
Turn an iPad sideways, or widen the window, and the players stay on the
pitch.

## What was tested

Run on the iOS Simulator (iPhone and iPad, iOS 26/27) and on macOS on an
Apple silicon Mac: the board upright and turned sideways, full screen and
windowed, the drill library, loading a drill onto the board and stepping
every beat of it, and the practice plan. The automated suite — 565 tests —
passes, including one that walks all sixteen sports' drill libraries, every
board at every beat, at a Mac window's shape, checking that no player and no
ball is drawn off the playing surface.

Thank you for reviewing.
