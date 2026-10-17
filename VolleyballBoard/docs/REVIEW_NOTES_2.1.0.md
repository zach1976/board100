# Review Notes — Volleyball Board 2.1.0 (build 5)

> 提交执行：从 "Dear App Review team" 到 "Thank you..." 写入 App Review
> Information。线上版本是 2.0.0，本次是 2.0.0 → 2.1.0。
>
> **10-17 篮球/足球被 2.1(b) 退回：审核员找不到内购入口。** 入口段改成三条明确路径。
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

## Where to find the In-App Purchases

Both purchases — "Remove Ads (Yearly)" (volleyball_remove_ads_yearly, auto-renewable,
submitted for the first time with this version) and the already approved
one-time "Lifetime" — are on one purchase sheet. Three ways to it, any one
is enough:

1. From the board: on the Home tab tap "Open the board" (or "New board").
   On the board, tap the round "⋯" button in the top-right corner, then
   "Remove Ads". The purchase sheet opens.
2. From the drills: open the "Drills" tab and tap any drill marked with a
   lock, then "Unlock with Pro". The same sheet opens.
3. From match day: on the Home tab tap "Match day", set up a match and tap
   the clock's start button; starting the clock asks for Pro with the same
   sheet.

The sheet shows both plans with localized prices, the auto-renewal terms,
the Terms of Use (EULA) and Privacy Policy links, and "Restore Purchases".
Nothing restricts them by storefront or device. The Paid Apps Agreement
is in effect (the Lifetime purchase is live).

## New in 2.1.0

1. Rotations: on the board, Add → "Rotation" sets out all six
   players for any of the six rotations, in serve or in receive. Coaches can
   step forward and back, choose the setter's zone and bring in the libero.
   An overlap check marks players who would be out of position at the serve.
2. The drill library grows from 44 to 154 drills.
3. iPad: a side bar, list-beside-detail, popovers, keyboard shortcuts and
   Apple Pencil drawing.
4. Back from a board returns to the practice plan being run; a short run's
   arrow is drawn beside the player; untranslated labels were translated.
5. The app's interface and every drill's coaching notes are now also in
   German and Dutch (14 languages in all).
6. Rule sets: the rotation bar offers FIVB, USAV, NFHS or NCAA per board.
   The substitution limit (6/12/18/15 per set) shows beside it, and under
   the US rule sets the libero may serve in one rotation.
7. "Fix positions": when the overlap check marks two players, a red button
   on the rotation bar moves them to a legal spot; Undo restores them.
8. Lineup sheet: with a rotation on the board, the Share menu gains
   "Lineup sheet", a PDF in the paper format (zones, serving order I–VI,
   libero, rule set). It is generated on the device.
9. Six ready sessions, built from the library's own drills: Plans → New →
   "From a ready session".
10. Match day: the home page's board card gains a "Match day" button: a
   substitution sheet counted per set (rule set, best of 3 or 5, six
   starters, liberos; substitutions against the rule set's limit, libero
   replacements uncounted, two timeouts, the set score; summary and PDF).
   Setting a match up is free; starting it asks for Pro through the
   purchase sheet above (a sandbox purchase of either plan unlocks it).
   Finished matches sync to the coach's account when signed in.
11. While a player is dragged in a rotation, the court shades the area
   where that player may legally stand.
12. Playbook: a saved board can be marked "In playbook" (bookmark icon in
   the Boards panel) and the match-day screen's "Playbook" button flips
   through those boards full screen.
13. The field menu offers a beach court (16 × 8 m sand, pairs formations).

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
