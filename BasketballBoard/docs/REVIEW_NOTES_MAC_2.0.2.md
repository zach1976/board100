# Review Notes — Basketball Board 2.0.2 macOS (build 4)

> 背景：macOS 版 1.1.24 于 2026-07-12 被 4.3(a) 判为垃圾应用，之后 Mac 整体
> 暂停。2026-10-07 用户指示重新提交，2.0.1 那次已由用户自行撤回；这是带上
> 板面几何修复之后的重交。Notes 正面回应 4.3。
>
> **送审前必须确认**：账号当前没有其他 app 在审。

---

Dear App Review team,

Basketball Board 2.0.2 is the macOS build of a release whose iOS version is on
the App Store. The last macOS version to reach review was 1.1.24 in July,
which was rejected under Guideline 4.3(a). We would like to explain what has
changed since then, because the app is not the same product it was.

## What the app now contains

1. A library of 58 basketball drills written for this sport. Each one is an
   animated board carrying its setup, the ball path, the sequence, how the
   drill continues, and the coaching point, in twelve languages. None of this
   existed in 1.1.24.
2. Practice plans: drills and the coach's own boards are strung into a
   session, timed item by item, and run from the touchline, with a record of
   what was actually run.
3. A squad page with players, their photos, and attendance per session.
4. The board itself was redrawn: the court is a card on the floor, players and
   the ball cast contact shadows, a player with the ball has it in front of
   him, and run / dribble / pass are three different lines.

In 1.1.24 the app was a drawing surface and little else, which is what made a
row of per-sport versions look like one app repeated. What a coach gets now is
specific to basketball: the drills, their coaching points and the court are
basketball's, and they are not interchangeable with another sport's.

## What this build fixes

5. On a Mac window the court is fitted by width rather than by height, and the
   players and the ball were placed against the window instead of against the
   court: a layup finished past the end line and the shooter stood on the rim.
   They now sit where the lines say, at any window size. The 58 drill boards
   were re-measured so the two agree.
6. The floating menu, page and zoom buttons no longer sit on the playing
   surface, and the small board pictures turn with the board.

## Ads, accounts, privacy

7. There are no ads in the macOS build at all: `google_mobile_ads` has no
   macOS implementation and AdService is gated on iOS/Android.
8. No account is required. Sign in with Apple and Google are optional and only
   back up a coach's own boards.
9. The app does not track. The bundle ships a privacy manifest declaring
   `NSPrivacyTracking = false`, and the App Privacy label agrees.

## How to see it

Open the app → Drills → any card → "Put on the board" → press play, or use the
step arrows under the board. Home → Practice Plan shows a session built from
those drills. Everything is in the build; nothing is downloaded to see it.

## What was tested

Run on macOS on an Apple silicon Mac at 1440x900 and full screen: the
onboarding, the home page, the drill library, loading a drill onto the board,
stepping every beat of it, the practice plan, and the board's own drawing
tools. The automated suite — 565 tests — passes, including one that walks
every drill of all sixteen sports at a Mac window's shape and checks that no
player and no ball is drawn off the court.

Thank you for reviewing.
