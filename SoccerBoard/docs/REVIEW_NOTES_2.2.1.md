# Review Notes — Soccer Board 2.2.1 (build 10)

> 提交执行：从 "Dear App Review team" 到 "Thank you..." 写入 App Review
> Information。线上是 2.2.0；这一版修的是板子的几何错位和射门落点。
>
> **送审前必须确认**（zachs_app_base.md 6.4）：账号当前没有其他 app 在审。
> **真机 QA 未做**：下面写的是模拟器和 Mac，没有真机声明。

---

Dear App Review team,

Soccer Board 2.2.1 is a fix release over 2.2.0. No new features, no new
permissions, no new network endpoints, and no change to what the app collects
or sends.

## What changed since 2.2.0

1. Every finishing drill ended with the ball well behind the goal. The target
   of a shot was written against the drawing canvas instead of against the
   pitch, which put it about ten metres past the goal line. The shot now
   finishes in the net.
2. The pitch is centred inside the board at its own aspect ratio, and on a
   wide screen — an iPad, a Mac window, a phone turned sideways — it is fitted
   by width rather than by height. The players and the ball were placed
   against the canvas instead of against the pitch, so on those screens the
   whole move sat several metres off the lines. They are now placed against
   the pitch and stand where the lines say, at any size. All 137 drill boards
   were re-measured in the frame their coordinates mean.
3. A player warming up with two balls has one at either side of him instead of
   one in front and one behind.
4. Turned sideways, the floating menu, page and zoom buttons sat on the
   playing surface; the board now starts inside them. On an iPad the playback
   bar and the tool bar share one row, so the pitch gets that height back.
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

Open the app → Drills → "Wall pass on the wing" → "Put on the board" → press
the step arrow three times: the shot finishes in the goal. Turn an iPad
sideways, or widen the Mac window, and the players stay on the pitch.

## What was tested

Run on the iOS Simulator (iPhone and iPad, iOS 26/27) and on macOS on an
Apple silicon Mac: the board upright and turned sideways, full screen and
windowed, the drill library, loading a drill onto the board and stepping
every beat of it, and the practice plan. The automated suite — 565 tests —
passes, including one that walks all sixteen sports' drill libraries, every
board at every beat, at a Mac window's shape, checking that no player and no
ball is drawn off the playing surface.

Thank you for reviewing.
