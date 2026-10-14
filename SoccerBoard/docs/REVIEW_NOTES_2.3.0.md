# Review Notes — Soccer Board 2.3.0 (build 11)

> 提交执行：从 "Dear App Review team" 到 "Thank you..." 写入 App Review
> Information。线上版本是 2.2.1，本次是 2.2.1 → 2.3.0。
>
> **年订阅随本版本首次送审**（soccer_remove_ads_yearly，READY_TO_SUBMIT）：
> submit 时要把订阅一起加进 reviewSubmission，否则商店依旧只显示买断。
>
> **送审前必须确认**（zachs_app_base.md 6.4）：账号当前没有其他 app 在审，
> 距上一个过审 ≥1 周。16 个 app 一次只送一个。真机 QA 未做，下面不写真机。

---

Dear App Review team,

Soccer Board 2.3.0 is a feature release over 2.2.1. There are no new
permissions and no new network endpoints.

## In-app purchase submitted with this version

1. The auto-renewable yearly subscription "soccer_remove_ads_yearly"
   (group "Tactics Board Pro") is submitted for the first time with this
   version. It removes ads and unlocks the full drill library, the same as
   the already approved one-time "Lifetime" purchase.
2. To see it: open any board → the menu button (top corner) → "Remove Ads",
   or open a locked drill in the Drills tab and tap "Unlock with Pro". The purchase sheet
   lists both plans with their localized prices, states that the yearly plan
   auto-renews and can be cancelled in Settings, and links the Terms of Use
   (standard EULA) and the Privacy Policy. "Restore Purchases" is on the same
   sheet.

## New in 2.3.0

3. Match day: the home page's board card gains a "Match day" button, a
   substitution sheet. Set the periods and the starting line-up, mark the
   keeper, run the clock (it stops itself at the end of a period; "+1 min"
   for added time), tap two players to substitute; the bench sorts by
   minutes played and "Suggest" evens out playing time, leaving the keeper
   out. Yellow and red cards are recorded per player, and a shoot-out panel
   records each kick. Afterwards the minutes and substitutions export as a
   PDF, and finished matches sync to the coach's account when signed in.
   Set-up is free; starting the clock asks for Pro through the purchase
   sheet above (a sandbox purchase of either plan unlocks it).
4. Playbook: a saved board can be marked "In playbook" (bookmark icon in the
   Boards panel) and the match-day screen's "Playbook" button flips through
   those boards full screen.
5. Six ready sessions (foundation to pre-season), built from the library's
   own drills: Plans → New → "From a ready session".
6. Text can be written on the board, a drill's step note sits on the board
   and changes with each step, and a selected line can be restyled.
7. iPad: a side bar instead of tabs, list-beside-detail for drills and
   plans, panels as popovers, hardware keyboard shortcuts and Apple Pencil
   drawing while fingers move players. In landscape on iPhone the side bar
   keeps to the Dynamic Island's side.
8. The app's interface and every drill's coaching notes are now also in
   German and Dutch (14 languages in all).
9. The Pro screen is titled "All drills, no ads". Back from a board returns
   to the practice plan being run; labels that were still in English were
   translated.

## Store compliance

10. The description carries the standard EULA link and the privacy policy
   link in every localization.
11. No App Tracking Transparency prompt: ads are non-personalized, the
   privacy manifest declares `NSPrivacyTracking = false`, and the App
   Privacy label declares no tracking. These three agree.

## How to see it

Open the app → the home page → the board card's "Match day" button, or
Drills → any card → "Put on the board" → press play. No account is required;
Sign in with Apple and Google are optional and only back up a coach's own
boards.

## What was tested

Run on the iOS Simulator (iPhone and iPad). The automated suite — 798 tests,
including the match-day clock, bookings, shoot-out and
substitutions — passes, and every drill board was
rendered through the app's own painters and reviewed.

Thank you for reviewing.
