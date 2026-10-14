# Review Notes — Volleyball Board 2.1.0 (build 5)

> 提交执行：从 "Dear App Review team" 到 "Thank you..." 写入 App Review
> Information。线上版本是 2.0.0，本次是 2.0.0 → 2.1.0。
>
> **年订阅随本版本首次送审**（volleyball_remove_ads_yearly，READY_TO_SUBMIT）：
> submit 时要把订阅一起加进 reviewSubmission，否则商店依旧只显示买断。
>
> **送审前必须确认**（zachs_app_base.md 6.4）：账号当前没有其他 app 在审，
> 距上一个过审 ≥1 周。16 个 app 一次只送一个。真机 QA 未做，下面不写真机。

---

Dear App Review team,

Volleyball Board 2.1.0 is a feature release over 2.0.0. There are no new
permissions and no new network endpoints.

## In-app purchase submitted with this version

1. The auto-renewable yearly subscription "volleyball_remove_ads_yearly"
   (group "Tactics Board Pro") is submitted for the first time with this
   version. It removes ads and unlocks the full drill library, the same as
   the already approved one-time "Lifetime" purchase.
2. To see it: open any board → the menu button (top corner) → "Remove Ads",
   or open a locked drill in the Drills tab and tap "Unlock with Pro". The purchase sheet
   lists both plans with their localized prices, states that the yearly plan
   auto-renews and can be cancelled in Settings, and links the Terms of Use
   (standard EULA) and the Privacy Policy. "Restore Purchases" is on the same
   sheet.

## New in 2.1.0

3. Rotations: on the board, Add → "Rotation" sets out all six
   players for any of the six rotations, in serve or in receive. Coaches can
   step forward and back, choose the setter's zone and bring in the libero.
   An overlap check marks players who would be out of position at the serve.
4. The drill library grows from 44 to 154 drills.
5. iPad: a side bar instead of tabs, list-beside-detail for drills and
   plans, panels as popovers, hardware keyboard shortcuts and Apple Pencil
   drawing.
6. Back from a board returns to the practice plan being run; a short run's
   arrow is drawn beside the player; untranslated labels were translated.
7. The app's interface and every drill's coaching notes are now also in
   German and Dutch (14 languages in all).
8. Rule sets: the rotation bar offers FIVB, USAV, NFHS or NCAA per board.
   The substitution limit (6/12/18/15 per set) shows beside it, and under
   the US rule sets the libero may serve in one rotation.
9. "Fix positions": when the overlap check marks two players, a red button
   on the rotation bar moves them to a legal spot; Undo restores them.
10. Lineup sheet: with a rotation on the board, the Share menu gains
   "Lineup sheet", a PDF in the paper format (zones, serving order I–VI,
   libero, rule set). It is generated on the device.
11. Six ready sessions, built from the library's own drills: Plans → New →
   "From a ready session".
12. Match day: the home page's board card gains a "Match day" button: a
   substitution sheet counted per set (rule set, best of 3 or 5, six
   starters, liberos; substitutions against the rule set's limit, libero
   replacements uncounted, two timeouts, the set score; summary and PDF).
   Setting a match up is free; starting it asks for Pro through the
   purchase sheet above (a sandbox purchase of either plan unlocks it).
   Finished matches sync to the coach's account when signed in.
13. While a player is dragged in a rotation, the court shades the area
   where that player may legally stand.
14. Playbook: a saved board can be marked "In playbook" (bookmark icon in
   the Boards panel) and the match-day screen's "Playbook" button flips
   through those boards full screen.
15. The field menu offers a beach court (16 × 8 m sand, pairs formations).

## How to see it

Open the app → the board → Add → "Rotation" to step through the six
rotations, or Drills → any card → "Put on the board" → press play. No
account is required; Sign in with Apple and Google are optional and only
back up a coach's own boards.

## What was tested

Run on the iOS Simulator (iPhone and iPad). The automated suite — 798 tests,
including the rotation and overlap rules, the four rule sets, the lineup
sheet and the per-set match day — passes, and every drill board in
the library was rendered through the app's own painters and reviewed.

Thank you for reviewing.
