# Review Notes — Field Hockey Board 2.0.0 (build 1)

> 提交执行：从 "Dear App Review team" 到 "Thank you..." 写入 App Review
> Information。
>
> **背景**：iOS 线上版本是 **1.1.25 READY_FOR_SALE**（2026-07 的包），没有
> 待处理的拒绝。本次是从 1.1.25 的常规功能更新，Notes 不写拒因。
>
> **macOS 不在本次范围**：2026-07 全部 16 个 macOS 版本被 4.3(a) 拒绝后
> macOS 一直停着，本次只发 iOS。
>
> **本文件不含真机声明**：2.0.0 (1) 在 iOS 模拟器和开发机上逐步验证过，
> 没有在真机上跑 34 项清单。写做过的，不写没做的。

---

Dear App Review team,

Field Hockey Board 2.0.0 is a feature release over 1.1.25. Everything below
is in the build and can be reached from the app's own navigation. There are
no new permissions and no new data collection.

## Drill library (new in 2.0)

1. 36 built-in field hockey drills. Each one is an animated board carrying
   its setup, the ball path and the coaching point. Drills tab → any card →
   "Put on the board" → press play.
2. Search, plus filters by category (warm-up, building up, circle entry,
   finishing, pressing, set pieces, small-sided, goalkeeping, conditioning),
   by level, and by squad size.
3. Every drill is written for field hockey: the stick, the shooting circle,
   the penalty corner, the self-pass. The coaching language is the sport's.

## Session planning

4. Practice plans: drills and saved boards strung into a session, run one
   item at a time from the sideline, with a record of what was run.
5. A squad page with player photos and per-session attendance.

## The board itself

6. Redrawn player figures that face where they are going, stick in hand;
   equipment drawn from above so it stays upright when the board is rotated.
7. A run is a dashed arrow, a carry waves, a pass is a solid line — three
   actions drawn three ways.
8. Any element can be rotated, and text can be typed straight onto the
   pitch and set in one of four typefaces.
9. A board is a set of pages a coach can flick between.
10. A board can be shared as a web link that opens in any browser, with no
    app and no account on the other end.

## Monetisation

11. The app is free with banner and interstitial ads. One optional
    non-consumable in-app purchase removes them permanently. Nothing else
    is gated: every drill, plan and board is available without paying.

## What was tested

Run on the iOS Simulator and on macOS on an Apple silicon Mac: the home
page, the drill library, loading a drill onto the board, stepping and
playing every beat of it, the practice plan, the squad page, the board's
own drawing tools, and the share link. The full automated suite — 531
tests — passes, and all 36 field hockey boards were re-rendered through the
app's own painters and reviewed one by one.

## Demo path (about 45 seconds)

Open the app → the home page lists drills to run today → Drills → pick any
card → "Put on the board" → press play and watch the routine run → tap a
player to bring up the edit bar → back → "Practice Plan" → add the drill →
run it.

No account is required. Sign in with Apple and Google are optional and only
back up a coach's own boards.

Thank you for reviewing.
