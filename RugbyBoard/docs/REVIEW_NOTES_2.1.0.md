# Review Notes — Rugby Board 2.1.0 (build 2)

> 提交执行：从 "Dear App Review team" 到 "Thank you..." 写入 App Review
> Information。线上版本是 1.1.25，本次是 1.1.25 → 2.1.0。
>
> **无新内购**：买断 "Lifetime" 已过审且不变，本版本不随审任何内购。
>
> **送审前必须确认**（zachs_app_base.md 6.4）：账号当前没有其他 app 在审，
> 距上一个过审 ≥1 周。16 个 app 一次只送一个。真机 QA 未做，下面不写真机。

---

Dear App Review team,

Rugby Board 2.1.0 is a feature release over 1.1.25. There are no new
permissions and no new network endpoints. The one-time "Lifetime"
purchase is unchanged; no new in-app purchase is submitted.

## Drill library and practice plans (new since 1.1.25)

1. 40 built-in drills, each an animated board with its setup, ball path and
   coaching point in 14 languages: Drills tab → any card → "Put on the
   board" → press play. Search and filters; a drill can be put on the board
   and edited like the coach's own; the library works offline and updates
   over the air.
2. Drills and saved boards can be strung into a practice plan and run from
   the touchline one item at a time, with a record of what was run; a squad
   page keeps players with photos and attendance.
3. Six ready sessions (foundation to pre-season), built from the library's
   own drills: Plans → New → "From a ready session".

## The board, redrawn

4. The board is drawn as a card on the sport's own dark ground, with contact
   shadows and mesh nets; the ball sits in front of its carrier, run,
   dribble and pass are three different lines, the controls were rebuilt,
   and players are placed against the court so they stand where the lines
   say at any size.
5. Text can be written on the board, a drill's step note sits on the board
   and changes with each step, and a selected line can be restyled.

## Match day and playbook

6. Match day: the home page's board card gains a "Match day" button, a
   substitution sheet. Set the periods and the starting line-up, mark the
   keeper, run the clock (it stops itself at the end of a period; "+1 min"
   for added time), tap two players to substitute; the bench sorts by
   minutes played and "Suggest" evens out playing time, leaving the keeper
   out. Afterwards the minutes and substitutions export as a PDF, and
   finished matches sync to the coach's account when signed in. Set-up is
   free; starting the clock asks for Pro through the purchase sheet (a
   sandbox purchase of "Lifetime" unlocks it).
7. Playbook: a saved board can be marked "In playbook" (bookmark icon in the
   Boards panel) and the match-day screen's "Playbook" button flips through
   those boards full screen.

## Also since 1.1.25

8. iPad: a side bar instead of tabs, list-beside-detail for drills and
   plans, panels as popovers, hardware keyboard shortcuts and Apple Pencil
   drawing while fingers move players.
9. The app's interface and every drill's coaching notes are now also in
   German and Dutch (14 languages in all).
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
including the match-day clock and substitutions — passes, and every drill board was
rendered through the app's own painters and reviewed.

Thank you for reviewing.
