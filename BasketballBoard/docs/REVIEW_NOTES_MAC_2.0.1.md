# Review Notes — Basketball Board 2.0.1 macOS (build 3)

> 提交执行：从 "Dear App Review team" 到 "Thank you..." 写入 macOS 版本的
> App Review Information。
>
> **背景（必读）**：本 app 的 macOS 版 1.1.24 于 2026-07-12 被 4.3(a) 判为
> 垃圾应用（当时 15 个单项 Mac 版 + 合集一起被拒），之后 Mac 整体暂停。
> 2026-10-07 用户明确指示重新提交篮球 Mac 版，风险由用户承担。下面的
> Notes 正面回应 4.3：这一版的内容（58 个训练、训练计划、球队点名）是
> 1.1.24 所没有的，不再是"同一个二进制换个开关"。
>
> **真机 QA**：Mac 版就在开发机上跑的，这条不适用；iOS 那边仍未做。

---

Dear App Review team,

Basketball Board 2.0.1 is the macOS build of a release whose iOS version is
already on the App Store. The last macOS submission was 1.1.24 in July, which
was rejected under Guideline 4.3(a). We would like to explain what has changed
since then, because the app is not the same product it was.

## What the app now contains

1. A library of 58 basketball drills written for this sport. Each one is an
   animated board carrying its setup, the ball path, the sequence, how the
   drill continues, and the coaching point, in twelve languages. None of this
   existed in 1.1.24.
2. Practice plans: drills and the coach's own boards are strung into a
   session, timed item by item, and run from the touchline, with a record of
   what was actually run.
3. A squad page with players, their photos, and attendance per session.
4. The board itself was redrawn: the court is a card on the floor, players
   and the ball cast contact shadows, a player with the ball has it in front
   of him, and run / dribble / pass are three different lines.

In 1.1.24 the app was a drawing surface and little else, which is what made a
row of per-sport versions look like one app repeated. What a coach gets now is
specific to basketball: the drills, their coaching points and the court are
basketball's, and they are not interchangeable with another sport's.

## What changed since the iOS 2.0.1 build

5. The three onboarding screens carry photographic backdrops instead of a
   flat gradient, and no full-screen ad can appear over them.
6. Board geometry on a wide window: the court is centred inside the canvas at
   its own aspect, and the players and the ball are now placed against the
   court rather than against the window, so a layup finishes at the rim
   instead of past the end line.
7. The floating corner buttons sit beside the board, not on the playing
   surface.

## Ads, accounts, privacy

8. There are no ads in the macOS build at all: `google_mobile_ads` has no
   macOS implementation and AdService is gated on iOS/Android.
9. No account is required. Sign in with Apple and Google are optional and
   only back up a coach's own boards.
10. The app does not track. The bundle ships a privacy manifest declaring
    `NSPrivacyTracking = false`, and the App Privacy label agrees.

## How to see it

Open the app → Drills → any card → "Put on the board" → press play, or use the
step arrows under the board. Home → Practice Plan shows a session built from
those drills. Everything is in the build; nothing is downloaded to see it.

## What was tested

Run on macOS on an Apple silicon Mac at 1440×900 and full screen: the
onboarding, the home page, the drill library, loading a drill onto the board,
stepping every beat of it, the practice plan, and the board's own drawing
tools. The full automated suite — 564 tests — passes.

Thank you for reviewing.
