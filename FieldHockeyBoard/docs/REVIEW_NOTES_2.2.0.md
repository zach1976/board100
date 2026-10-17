# Review Notes — Field Hockey Board 2.2.0 (build 6)

> 提交执行：从 "Dear App Review team" 到 "Thank you..." 写入 App Review
> Information。线上版本是 2.0.1，本次是 2.0.1 → 2.2.0。
>
> **10-17 篮球/足球被 2.1(b) 退回：审核员找不到内购入口。** 入口段改成三条明确路径。
>
> **年订阅随本版本首次送审**（fieldhockey_remove_ads_yearly，READY_TO_SUBMIT）：
> submit 时要把订阅一起加进 reviewSubmission，否则商店依旧只显示买断。
>
> **送审前必须确认**（zachs_app_base.md 6.4）：账号当前没有其他 app 在审，
> 距上一个过审 ≥1 周。16 个 app 一次只送一个。真机 QA 未做，下面不写真机。

---

Dear App Review team,

Field Hockey Board 2.2.0 is a feature release over 2.0.1. There are no new
permissions and no new network endpoints.

## Where to find the In-App Purchases

Both purchases — "Remove Ads (Yearly)" (fieldhockey_remove_ads_yearly, auto-renewable,
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
Nothing restricts the purchases by storefront or device. The Paid Apps
Agreement is in effect (the Lifetime purchase is live).

## New in 2.2.0

1. Two new pitches beside the outdoor one: the FIH indoor pitch and the
   Hockey5s court, chosen from the board's field menu. Each board keeps its
   own pitch, and the formation list follows it.
2. The drill library grows from 36 to 65 drills, six of them indoor.
3. Text can be written on the board, and a drill's step note sits on the
   board and changes with each step.
4. The app's backgrounds take the sport's blue instead of the shared dark teal.
5. iPad: a side bar instead of tabs, list-beside-detail for drills and
   plans, panels as popovers, hardware keyboard shortcuts and Apple Pencil
   drawing. In landscape on iPhone the side bar keeps to the Dynamic
   Island's side.
6. The app's interface and every drill's coaching notes are now also in
   German and Dutch (14 languages in all).
7. Match day: on the home page, the board card's "Match day" button opens a
   substitution sheet. Set the periods and the starting line-up, run the
   clock, tap two players to substitute, and the bench sorts by minutes
   played; "Suggest" proposes swaps that even out playing time; afterwards
   the minutes and substitutions export as a PDF. Setting a match up is
   free; starting the clock asks for Pro through the purchase sheet above
   (a sandbox purchase of either plan unlocks it). The clock stops itself
   at the end of a period ("+1 min" for added time); a player can be given
   a green, yellow or red card and sits out 2, 5 or 10 minutes; a shoot-out
   panel records attempts; the keeper is left out of the fair-time
   suggestions. Finished matches are synced to the coach's account when
   signed in, like practice plans.
9. Playbook: a saved board can be marked "In playbook" (bookmark icon in
   the Boards panel) and the match-day screen's "Playbook" button flips
   through those boards full screen.
10. Six ready sessions (foundation, attacking, defending, set pieces, match
   week, pre-season), built from the library's own drills: Plans → New →
   "From a ready session".

## How to see it

Open the app → the board → the field menu → "Indoor" or "Hockey5s", or
Drills → any card → "Put on the board" → press play. No account is
required; Sign in with Apple and Google are optional and only back up a
coach's own boards.

## What was tested

Run on the iOS Simulator (iPhone and iPad). The automated suite — 798 tests,
including the indoor and Hockey5s pitches and the match-day clock, cards
and substitutions — passes, and every drill board in
the library was rendered through the app's own painters and reviewed.

Thank you for reviewing.
