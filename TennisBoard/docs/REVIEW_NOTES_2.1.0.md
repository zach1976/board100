# Review Notes — Tennis Board 2.1.0 (build 2)

> 提交执行：从 "Dear App Review team" 到 "Thank you..." 写入 App Review
> Information。线上版本是 1.1.25，本次是 1.1.25 → 2.1.0。
>
> **无新内购**：买断 "Lifetime" 已过审且不变，本版本不随审任何内购。
>
> **送审前必须确认**（zachs_app_base.md 6.4）：账号当前没有其他 app 在审，
> 距上一个过审 ≥1 周。16 个 app 一次只送一个。真机 QA 未做，下面不写真机。

---

Dear App Review team,

Tennis Board 2.1.0 is a feature release over 1.1.25. There are no new
permissions and no new network endpoints. The one-time "Lifetime"
purchase is unchanged; no new in-app purchase is submitted.

## Drill library and practice plans (new since 1.1.25)

1. 38 built-in drills. Each is an animated board carrying its setup, the
   ball path and the coaching point, with notes in 14 languages. Drills tab
   → any card → "Put on the board" → press play. Search, and filter by
   category, level and squad size; a drill can be starred, put on the board
   and edited like the coach's own. The library ships in the app and works
   offline; its content updates over the air.
2. Drills and saved boards can be strung into a practice plan and run from
   the touchline one item at a time, with a record of what was actually run.
   A squad page keeps players with their photos and marks attendance.
3. Six ready sessions (foundation to pre-season), built from the library's
   own drills: Plans → New → "From a ready session".

## The board, redrawn

4. The board is drawn as a card on the sport's own dark ground; players,
   equipment and the ball cast contact shadows, and nets are drawn as mesh.
   A player holding the ball has it in front of them on the side they face;
   run, dribble and pass are three different lines beneath the figures. The
   controls were rebuilt (tools in one bottom capsule, playback in another,
   corner buttons clear of the Dynamic Island), and players are placed
   against the court rather than the window, so they stand where the lines
   say at any size.
5. The court takes the sport's official colours: a blue hard court in a
   green surround with white net tape.
6. Text can be written on the board, a drill's step note sits on the board
   and changes with each step, and a selected line can be restyled.

## Also since 1.1.25

7. iPad: a side bar instead of tabs, list-beside-detail for drills and
   plans, panels as popovers, hardware keyboard shortcuts and Apple Pencil
   drawing while fingers move players. In landscape on iPhone the side bar
   keeps to the Dynamic Island's side.
8. The app's interface and every drill's coaching notes are now also in
   German and Dutch (14 languages in all).
9. A saved board can be shared as a web link (no app needed to open it), a
   move exports as a video, and a player can be copied with their run onto
   the next page.
10. The Pro screen is titled "All drills, no ads". Back from a board returns
   to the practice plan being run; labels that were still in English were
   translated.

## Store compliance

11. The description carries the standard EULA link and the privacy policy
   link in every localization.
12. No App Tracking Transparency prompt: ads are non-personalized, the
   privacy manifest declares `NSPrivacyTracking = false`, and the App
   Privacy label declares no tracking. These three agree.

## How to see it

Open the app → Drills → any card → "Put on the board" → press play, or use
the step arrows under the board. No account is required; Sign in with Apple
and Google are optional and only back up a coach's own boards.

## What was tested

Run on the iOS Simulator (iPhone and iPad). The automated suite — 798 tests,
including the drill library, practice plans and the board's drawing tools — passes, and every drill board was
rendered through the app's own painters and reviewed.

Thank you for reviewing.
