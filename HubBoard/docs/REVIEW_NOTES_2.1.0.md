# Review Notes — Tactics Board 2.1.0 (build 2)

> 提交执行：从 "Dear App Review team" 到 "Thank you..." 写入 App Review
> Information。线上版本是 1.1.25，本次是 1.1.25 → 2.1.0。
>
> **内购**：年订阅与买断均已过审，本版本不随审内购；入口段写明两条以上路径（10-21 补，防 2.1(b)）。
>
> **送审前必须确认**（zachs_app_base.md 6.4）：账号当前没有其他 app 在审，
> 距上一个过审 ≥1 周。16 个 app 一次只送一个。真机 QA 未做，下面不写真机。

---

Dear App Review team,

Tactics Board 2.1.0 is a feature release over 1.1.25. There are no new
permissions and no new network endpoints. Both in-app purchases are already approved; see below for where
to find them.

## Where to find the In-App Purchases

Both purchases — "Remove Ads (Yearly)" (remove_ads_annual,
auto-renewable) and the one-time "Remove Ads (Lifetime)", both
already approved — are on one purchase sheet. Three ways to it, any one is
enough:

1. From the board: on the Home tab tap "Open the board" (or "New board").
   On the board, tap the round "⋯" button in the top-right corner, then
   "Remove Ads". The purchase sheet opens.
2. From the drills: open the "Drills" tab and tap any drill marked with a
   lock, then "Unlock with Pro". The same sheet opens.
3. From match day: on the Home tab tap "Match day" (with a team sport such as soccer picked), set up a match
   and tap the clock's start button; starting the clock asks for Pro
   with the same sheet.

The sheet shows both plans with localized prices, the auto-renewal terms,
the Terms of Use (EULA) and Privacy Policy links, and "Restore Purchases".
The Paid Apps Agreement is in effect.

## Drill library and practice plans (new since 1.1.25)

1. 854 built-in drills across the fifteen sports the app bundles, each an
   animated board with its setup, ball path and coaching point in 14
   languages: Drills tab → any card → "Put on the board" → press play.
2. Drills and saved boards can be strung into a practice plan and run from
   the touchline one item at a time; a squad page keeps players with photos and attendance.
3. Six ready sessions (foundation to pre-season), built from the library's
   own drills: Plans → New → "From a ready session".

## The board, redrawn

4. The board is redrawn: a card on the sport's own ground with contact
   shadows and mesh nets; run, dribble and pass are distinct lines; the
   controls were rebuilt and players stand where the lines say at any size.
5. Text can be written on the board, a drill's step note sits on the board
   and changes with each step, and a selected line can be restyled.

## Match day and playbook (team sports)

6. Match day ("Match day" on the home page's board card): line-up, a
   clock that stops at the end of a period, two-tap substitutions, a bench
   sorted by minutes with "Suggest" to even out playing time. Soccer adds
   bookings and a shoot-out, handball the 2-minute suspension, field hockey
   cards. Minutes export as a PDF. Set-up is free; starting the clock asks
   for Pro (a sandbox purchase of either plan unlocks it).
7. Playbook: boards marked "In playbook" (bookmark icon, Boards panel)
   flip full screen from the match-day screen's "Playbook" button.
8. Volleyball: six rotations under FIVB, USAV, NFHS or NCAA rules with an
   overlap check, "Fix positions", a lineup-sheet PDF and a beach court.
   Field hockey: FIH indoor and Hockey5s pitches. Basketball: NBA, NCAA and
   NFHS courts.

## Also since 1.1.25

9. iPad: a side bar instead of tabs, list-beside-detail for drills and
   plans, panels as popovers, hardware keyboard shortcuts and Apple Pencil
   drawing while fingers move players.
10. The app's interface and every drill's coaching notes are now also in
   German and Dutch (14 languages in all).
11. The Pro screen is titled "All drills, no ads". Back from a board returns
   to the practice plan being run.

## Store compliance

12. The description carries the standard EULA link and the privacy policy
   link in every localization.
13. No App Tracking Transparency prompt: ads are non-personalized, and the
   privacy manifest and the App Privacy label both declare no tracking.

## Account

No account is required; Sign in with Apple and Google are optional
and only back up a coach's own boards.

## What was tested

Run on the iOS Simulator (iPhone and iPad); the automated suite (798 tests)
passes and every drill board was rendered and reviewed.

Thank you for reviewing.
