# Review Notes — Soccer Board 2.2.1 macOS (build 10)

> 提交执行：写入 **macOS** 版本的 App Review Information。线上的 macOS 版本是
> 2.0.0，所以这一版对 Mac 用户来说是 2.0.0 → 2.2.1。
>
> **送审前必须确认**（zachs_app_base.md 6.4）：账号当前没有其他 app 在审。
> **真机 QA 未做**：下面写的是模拟器和 Mac，没有真机声明。

---

Dear App Review team,

Soccer Board 2.2.1 is the macOS build of a fix release. The macOS version on
the store is 2.0.0; everything listed below has landed since then. No new features, no new
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

## On macOS

8. There are no ads in the macOS build at all: `google_mobile_ads` has no
   macOS implementation and AdService is gated on iOS/Android.
9. No account is required. Sign in with Apple and Google are optional and only
   back up a coach's own boards.

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
