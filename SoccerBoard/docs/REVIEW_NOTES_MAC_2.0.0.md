# Review Notes — Soccer Board for Mac 2.0.0 (build 3)

> macOS 专用。iOS 那份在 `REVIEW_NOTES_2.0.0.md`。
>
> **必须回应 4.3(a)**：2026-07 Apple 以 4.3(a) 一次性拒绝了本账号全部 16 个
> macOS 版本，理由针对的就是「一个运动一个 Mac app」这种形态。原样重交没有
> 意义，下面首段必须说明这一版在 Mac 上是什么、为什么不是 iPhone 版的套壳。
>
> 本文件同样**不含真机声明**：Mac 版是在开发机上实际运行验证的，这一点是事实，
> 写了；没做的不写。

---

Dear App Review team,

This is the first Mac submission since our macOS versions were rejected
under 4.3(a) in July. We did not resubmit then, and we have not resubmitted
since. What follows is what changed, and why we believe this version is a
Mac application rather than a phone layout in a window.

## Why this is built for the Mac

1. The board is laid out for a wide screen, not scaled up from a phone. A
   drill opens as two columns — the board on the left at full size, the
   setup, coaching point and beat-by-beat sequence readable beside it. On a
   phone the same page is one column and the reader scrolls.
2. The library and the home page use the width: the drill list is three
   columns, and the sections that are a horizontal scroller on a phone are a
   grid here.
3. Presentation mode drives an external display — a coach connects a screen
   or a projector, the board fills it, and the Mac keeps the controls. This
   has no equivalent on the phone build.
4. A board exports as an image or a video to the Mac filesystem, which is
   how session material actually gets into a team's shared drive.
5. The app is ad-free on macOS. The ad SDK has no Mac build and the code
   gates on platform, so nothing about the Mac version is funded by ads.

## What 2.0 adds, on every platform

6. 137 built-in soccer drills, each an animated board with its setup, ball
   path and coaching point.
7. Practice plans: drills and saved boards strung into a session and run one
   item at a time, with a record of what was run.
8. A squad page with player photos and per-session attendance.
9. Redrawn player figures that face where they are going; equipment drawn
   from above so it stays upright when the board is rotated.
10. A board can be shared as a web link that opens in any browser.

## On 4.3

We understand the concern behind the July rejection: a family of
single-sport apps built from one codebase looks like duplication. Our answer
is that each app ships a different drill library — this one carries 137
soccer drills written for soccer, with soccer equipment, soccer formations
and soccer coaching language — and that the drill library, not the drawing
surface, is what a coach buys. A basketball coach has no use for a
passing-pattern pentagon.

If the review team would prefer these consolidated into a single Mac
application containing every sport, we will do that instead. We would rather
be told than guess. Our multi-sport app already exists on iOS (Tactics
Board, com.zach.tacticsBoard) and could become the only Mac SKU.

## What was tested

Run on macOS on an Apple silicon Mac: the home page, the drill library,
loading a drill onto the board, playing it through, the practice plan, and
the window at several sizes down to the minimum. The five screenshots
accompanying this version are unretouched captures of that running app at
2880×1800.

## Demo path (about 45 seconds)

Open the app → the home page lists drills to run today → Drills → pick any
card → "Put on the board" → press play and watch the passes run → click a
player to bring up the edit bar → back → "Practice Plan" → add the drill →
run it.

No account is required. Sign in with Apple and Google are optional and only
back up a coach's own boards.

Thank you for reviewing.
