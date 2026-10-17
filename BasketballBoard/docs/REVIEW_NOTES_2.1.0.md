# Review Notes — Basketball Board 2.1.0 (build 5)

> 提交执行：从 "Dear App Review team" 到 "Thank you..." 写入 App Review
> Information。线上版本是 2.0.2，本次是 2.0.2 → 2.1.0。
>
> **10-17 被 2.1(b) 退回：审核员找不到内购入口。** 入口段已改成三条明确路径。
>
> **年订阅随本版本首次送审**（basketball_remove_ads_yearly，READY_TO_SUBMIT）：
> submit 时要把订阅一起加进 reviewSubmission，否则商店依旧只显示买断。
>
> **送审前必须确认**（zachs_app_base.md 6.4）：账号当前没有其他 app 在审，
> 距上一个过审 ≥1 周。16 个 app 一次只送一个。真机 QA 未做，下面不写真机。

---

Dear App Review team,

Basketball Board 2.1.0 is a feature release over 2.0.2. There are no new
permissions and no new network endpoints.

## Where to find the In-App Purchases

Both purchases — "Remove Ads (Yearly)" (basketball_remove_ads_yearly,
auto-renewable, submitted for the first time with this version) and the
already approved one-time "Lifetime" — are on one purchase sheet. Three ways
to it, any one is enough:

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

## New in 2.1.0

1. Match day: the home page's board card gains a "Match day" button, a
   substitution sheet. Set the periods and the starting line-up, mark the
   keeper, run the clock (it stops itself at the end of a period; "+1 min"
   for added time), tap two players to substitute; the bench sorts by
   minutes played and "Suggest" evens out playing time, leaving the keeper
   out. Afterwards the minutes and substitutions export as a PDF, and
   finished matches sync to the coach's account when signed in. Set-up is
   free; starting the clock asks for Pro through the purchase sheet above (a
   sandbox purchase of either plan unlocks it).
2. Playbook: a saved board can be marked "In playbook" (bookmark icon in the
   Boards panel) and the match-day screen's "Playbook" button flips through
   those boards full screen.
3. NBA, NCAA and high-school (NFHS) courts beside FIBA in the board's field
   menu: 16 ft key and 23.75 ft arc; 12 ft key and 22′1¾″ arc; 84 ft court
   with a 19′9″ arc and no restricted area.
4. The drill library grows from 58 to 99 drills: set plays, pick-and-roll
   reads, inbounds plays, presses and press breaks, zone and man-to-man
   principles, transition, shooting and finishing.
5. Six ready sessions (foundation to pre-season), built from the library's
   own drills: Plans → New → "From a ready session".
6. Text can be written on the board, a drill's step note sits on the board
   and changes with each step, and a selected line can be restyled.
7. iPad: a side bar, list-beside-detail, popovers, keyboard shortcuts and
   Apple Pencil drawing.
8. The app's interface and every drill's coaching notes are now also in
   German and Dutch (14 languages in all).
9. The Pro screen is titled "All drills, no ads".

## Store compliance

10. The description carries the standard EULA link and the privacy policy
   link in every localization.
11. No App Tracking Transparency prompt: ads are non-personalized, the
   privacy manifest declares `NSPrivacyTracking = false`, and the App
   Privacy label declares no tracking. These three agree.

## How to see it

Open the app → the board → the field menu → "NBA", or the home page → the
board card's "Match day" button, or Drills → any card → "Put on the board" →
press play. No account is required; Sign in with Apple and Google are
optional and only back up a coach's own boards.

## What was tested

Run on the iOS Simulator (iPhone and iPad). The automated suite — 798 tests,
including the four courts' geometry and the match-day clock and
substitutions — passes, and every drill board was
rendered through the app's own painters and reviewed.

Thank you for reviewing.
