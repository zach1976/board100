# Review Notes — Beach Tennis Board 2.1.0 (build 2)

> 提交执行：从 "Dear App Review team" 到 "Thank you..." 写入 App Review
> Information。线上版本是 1.1.25，本次是 1.1.25 → 2.1.0。
>
> **年订阅随本版本首次送审**（beachtennis_remove_ads_yearly，READY_TO_SUBMIT）：submit 会把它一起加进
> reviewSubmission。入口段 10-21 补（篮球/足球曾因找不到内购被 2.1(b) 退回）。
>
> **送审前必须确认**（zachs_app_base.md 6.4）：账号当前没有其他 app 在审，
> 距上一个过审 ≥1 周。16 个 app 一次只送一个。真机 QA 未做，下面不写真机。

---

Dear App Review team,

Beach Tennis Board 2.1.0 is a feature release over 1.1.25. There are no new
permissions and no new network endpoints. With this version the yearly subscription is submitted for the
first time; see below for where to find it.

## Where to find the In-App Purchases

Both purchases — "Remove Ads (Yearly)" (beachtennis_remove_ads_yearly,
auto-renewable, submitted for the first time with this version) and
the already approved one-time "Remove Ads (Lifetime)" — are on one
purchase sheet. Two ways to it, any one is
enough:

1. From the board: on the Home tab tap "Open the board" (or "New board").
   On the board, tap the round "⋯" button in the top-right corner, then
   "Remove Ads". The purchase sheet opens.
2. From the drills: open the "Drills" tab and tap any drill marked with a
   lock, then "Unlock with Pro". The same sheet opens.

The sheet shows both plans with localized prices, the auto-renewal terms,
the Terms of Use (EULA) and Privacy Policy links, and "Restore Purchases".
Nothing restricts the purchases by storefront or device. The Paid Apps
Agreement is in effect (the Lifetime purchase is live).

## Drill library and practice plans (new since 1.1.25)

1. 28 built-in drills. Each is an animated board carrying its setup, the
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

4. The board is redrawn: a card on the sport's own ground with contact
   shadows and mesh nets; run, dribble and pass are distinct lines; the
   controls were rebuilt and players stand where the lines say at any size.
5. The court takes the sport's official colours: white net tape and dark
   posts.
6. Text can be written on the board, a drill's step note sits on the board
   and changes with each step, and a selected line can be restyled.

## Also since 1.1.25

7. iPad: a side bar instead of tabs, list-beside-detail for drills and
   plans, panels as popovers, hardware keyboard shortcuts and Apple Pencil
   drawing while fingers move players.
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

## Account

No account is required; Sign in with Apple and Google are optional
and only back up a coach's own boards.

## What was tested

Run on the iOS Simulator (iPhone and iPad); the automated suite (798 tests)
passes and every drill board was rendered and reviewed.

Thank you for reviewing.
