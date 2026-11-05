# Review Notes — Soccer Board 2.2.0 (build 9)

> 提交执行：从 "Dear App Review team" 到 "Thank you..." 写入 App Review
> Information。上一版 2.0.1 (8) 于 2026-09-30 提交。送审前先确认 2.0.1 已出结果
> （6.4：一次只送一个），并把下面「What was tested」里的真机一段改成实际跑过的
> 机型和日期——**写做过的，不写没做的**。2.2.0 (9) 截至 2026-10-02 只在模拟器
> （iPhone 17 Pro、iPad Air 13）和开发机上验证过，`DEVICE_QA_2.0.0.md` 那份
> 真机清单没有跑；跑完再送。

---

Dear App Review team,

Soccer Board 2.2.0 is a visual and drawing release over 2.0.1. There are no
new permissions, no new network endpoints, and no change to pricing or the
in-app purchase. The drill updates the app already fetched now send an
ETag and skip the download when nothing has changed.

## What changed

1. The board is drawn as a card: the pitch sits on the sport's own dark
   ground with rounded corners and a soft shadow instead of running off
   the screen edges. Players, cones and the ball cast contact shadows, the
   turf has mowing bands, nets have mesh, and the football goals are
   pictures rather than line drawings.
2. The controls were rebuilt: tools in one bottom capsule and playback in
   another; larger corner buttons that keep clear of the Dynamic Island;
   zoom and fullscreen moved into the bar. On iPad in landscape the
   controls sit under the board so the pitch takes the full width; on a
   phone in landscape the two view buttons stay on the board.
3. The ball is placed in front of the player who has it, at his feet on
   the side he faces, and the draw order follows depth, so a player with
   his back to the viewer is drawn over the ball. The ball no longer
   jumps on the first frame of a step or lands twice at the end of one.
4. Run, dribble and pass lines are drawn beneath the figures, start and
   end at the feet, and arrowheads stop short of the player they point at.
5. Every drill in the library — 674 boards — was re-spaced so that no two
   figures overlap at any step. Two field hockey pressing boards that had
   no finishing step were completed.
6. A landscape launch screen was added; the home screen label reads
   "Soccer Board".

## How to see it

Open the app → Drills → any card → "Put on the board" → press play, or use
the step arrows under the board. "Rondo 4v2" shows the ball at a player's
feet and the lines running under the figures; turn the device sideways to
see the landscape layout and launch screen.

No account is required. Sign in with Apple and Google remain optional and
only back up a coach's own boards.

## What was tested

Run on the iOS Simulator (iPhone 17 Pro and iPad Air 13-inch, iOS 27) and
on macOS on an Apple silicon Mac: the home page, the drill library, loading
a drill onto the board, stepping and playing every beat of it, the practice
plan, the squad page, and the board's own drawing tools. The full automated
suite — 575 tests — passes, and all 674 drill boards in the library were
re-rendered through the app's own painters and reviewed.

Thank you for reviewing.
