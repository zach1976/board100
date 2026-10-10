# Review Notes — Tennis Board 2.0.0 (build 1)

> 提交执行：从 "Dear App Review team" 到 "Thank you..." 写入 App Review
> Information。本 app 线上版本是 **1.1.25**，所以本次是 1.1.25 → 2.0.0 的
> 功能更新，Notes 必须覆盖 2.0 的训练库／训练计划，而不只是 2.2 的重绘。
>
> **送审前必须确认**（zachs_app_base.md 6.4）：账号当前没有其他 app 在审，
> 距上一个过审 ≥1 周。16 个 app 一次只送一个。
>
> **真机 QA 未做**：下面「What was tested」写的是模拟器和 Mac，没有真机声明。
> 跑完 `DEVICE_QA` 清单后再把机型和日期补进去——写做过的，不写没做的。

---

Dear App Review team,

Tennis Board 2.0.0 is a feature release over 1.1.25. There are no new permissions
and no new network endpoints. Everything below is in the build and can be
reached from the app's own navigation.

## Drill library (new since 1.1.25)

1. 38 built-in drills. Each one is an animated board carrying its setup,
   the ball path and the coaching point. Drills tab → any card → "Put on the
   board" → press play.
2. Search, plus filters by category, by level and by squad size. A drill can
   be starred, and put on the board and edited like the coach's own.
3. Drill content updates over the air when the library changes; the app ships
   a complete copy and works with no network at all.

## Practice plans and squad (new since 1.1.25)

4. Drills and saved boards can be strung into a practice plan and run from
   the touchline one item at a time, with a record of what was actually run.
5. A squad page keeps players with their photos and marks attendance per
   session.

## The board, redrawn (new in 2.0.0)

6. The board is drawn as a card on the sport's own dark ground, with rounded
   corners and a soft shadow. Players, equipment and the ball cast contact
   shadows, the playing surface carries its own texture, and nets are drawn
   as mesh.
7. The controls were rebuilt: tools in one bottom capsule and playback in
   another, larger corner buttons that keep clear of the Dynamic Island, and
   zoom and fullscreen moved into the bar. On iPad in landscape the controls
   sit under the board so the court takes the full width.
8. A player holding the ball has it in front of them on the side they face,
   and the draw order follows depth, so a player with their back to the
   viewer is drawn over the ball.
9. Run, dribble and pass are three different lines, drawn beneath the
   figures, starting and ending at the feet, with arrowheads that stop short
   of the player they point at.
10. Every drill in the library was re-spaced so that no two figures overlap
    at any step.
11. A landscape launch screen was added.

## Also since 1.1.25

12. A saved board can be shared as a web link; the recipient opens it in a
    browser and needs no app.
13. A move can be exported as a video as well as a still image, and a player
    can be copied with their run onto the next page.

## Store compliance

14. The description carries the standard EULA link and the privacy policy
    link in every localization.
15. The app does not present App Tracking Transparency. Ads are
    non-personalized, the bundle ships a privacy manifest declaring
    `NSPrivacyTracking = false`, and the App Privacy label declares no
    tracking. These three agree.

## How to see it

Open the app → Drills → any card → "Put on the board" → press play, or use
the step arrows under the board. Turn the device sideways for the landscape
layout. No account is required; Sign in with Apple and Google are optional
and only back up a coach's own boards.

## What was tested

Run on the iOS Simulator (iPhone and iPad, iOS 26/27) and on macOS on an
Apple silicon Mac: the home page, the drill library, loading a drill onto the
board, stepping and playing every beat of it, the practice plan, the squad
page, and the board's own drawing tools. The full automated suite — 575
tests — passes, and all 674 drill boards in the library were re-rendered
through the app's own painters and reviewed.

Thank you for reviewing.
