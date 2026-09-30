# Review Notes — Soccer Board 2.0.1 (build 7)

> 提交执行：从 "Dear App Review team" 到 "Thank you..." 写入 App Review
> Information。上一版 2.0.0 (3) 于 2026-09-27 提交，2026-09-28
> **APPROVED / READY_FOR_SALE**，没有待处理的拒绝。
>
> **本文件同样不含真机验证声明**：2.0.1 (7) 在模拟器、开发机和一台 iPhone 17 Pro Max 上运行验证过（真机上逐步过了传球、射门、播放、单步、道具编辑、文字元素）；build 4 的首页版本号写着 2.0.0 重打了 build 5，真机上发现球的传球线在蓝色球衣上看不见又重打了 build 6，
> `DEVICE_QA_2.0.0.md` 那份真机清单仍然没有跑。写做过的，不写没做的。

---

Dear App Review team,

Soccer Board 2.0.1 is a maintenance release over 2.0.0, which you approved
yesterday. There are no new features, no new permissions, no new network
calls and no change to pricing or the in-app purchase. Every change is in
how the built-in drill boards are drawn.

## What changed

1. A run, a dribble and a pass are now three different lines — dashed,
   waved and solid, and the ball's line is drawn at full strength from the
   boot it leaves. A player carrying the ball was previously given two
   near-identical arrows side by side, one for him and one for the ball.
2. A short run keeps the copy of the player it started from. Below a
   threshold the board drew only the destination and a stub arrow, so
   roughly a quarter of the arrows in the drill library began nowhere.
3. A player who has finished a move is drawn once. Past the first beat,
   anyone who had moved was drawn twice — once at his current position and
   once at the end of his run, a stride apart and facing different ways.
4. A shot is drawn arriving at the goal. It had been placed the way a
   carried ball is, a token's length back toward whoever struck it, so it
   stopped short on the keeper.
5. A goalkeeper stands in front of his goal rather than inside the net, and
   faces the attacker rather than his own goal line.
6. Equipment stays where it was placed when a run passes near it; the pass
   arrow arrives with the ball instead of ahead of it; a conditioning
   shuttle run is drawn with nothing in the player's hands.

## How to see it

Open the app → Drills → any card → "Put on the board" → press play, or use
the step arrows under the board. "Rondo 4v2" shows the three line styles on
one board; "First-time finishing" shows a shot reaching the goal.

No account is required. Sign in with Apple and Google remain optional and
only back up a coach's own boards.

## What was tested

Run on an iPhone 17 Pro Max, on the iOS Simulator and on macOS on an Apple
silicon Mac: the home
page, the drill library, loading a drill onto the board, stepping and
playing every beat of it, the practice plan, the squad page, and the
board's own drawing tools. The full automated suite — 520 tests — passes,
and all 674 drill boards in the library were re-rendered through the app's
own painters and reviewed.

Thank you for reviewing.
