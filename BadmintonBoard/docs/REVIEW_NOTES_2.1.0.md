# Review Notes — Badminton Board 2.1.0 (build 2)

> 提交执行：从 "Dear App Review team" 到 "Thank you..." 写入 App Review
> Information。线上版本是 2.0.0，本次是 2.0.0 → 2.1.0。
>
> **年订阅随本版本首次送审**（badminton_remove_ads_yearly，READY_TO_SUBMIT）：submit 会把它一起加进
> reviewSubmission。入口段 10-21 补（篮球/足球曾因找不到内购被 2.1(b) 退回）。
>
> **送审前必须确认**（zachs_app_base.md 6.4）：账号当前没有其他 app 在审，
> 距上一个过审 ≥1 周。16 个 app 一次只送一个。真机 QA 未做，下面不写真机。

---

Dear App Review team,

Badminton Board 2.1.0 is a feature release over 2.0.0. There are no new
permissions and no new network endpoints. With this version the yearly subscription is submitted for the
first time; see below for where to find it.

## Where to find the In-App Purchases

Both purchases — "Remove Ads (Yearly)" (badminton_remove_ads_yearly,
auto-renewable, submitted for the first time with this version) and the
already approved one-time "Remove Ads (Lifetime)" — are on one purchase
sheet. Two ways to it, either one is enough. Verified on an iPad (11-inch
and 13-inch) and on iPhone with this exact build:

1. From the board. On an iPad the tabs are a side bar down the left edge
   (Home, Board, Drills, Me). Tap "Home", then the "New board" button at
   the top of the page (it reads "Open the board" once a board has been
   saved). Name the board and tap "Create". On the board, tap the round
   "⋯" button in the TOP-RIGHT corner of the screen (next to the step
   counter "1"). The menu that drops down ends with "Remove Ads" — tap
   it. The purchase sheet opens.
2. From the drills. Tap "Drills" in the side bar (or the tab bar on
   iPhone). 14 of the 42 drills are free; the other 28 show a lock on
   their card. Tap any locked drill, then "Unlock with Pro". The same
   sheet opens.

The sheet shows both plans with localized prices (Yearly $2.99 / year,
Lifetime $6.99 one-time), the auto-renewal terms, the Terms of Use (EULA)
and Privacy Policy links, and "Restore Purchases". Tap a plan, then
"Unlock Now" to start the StoreKit purchase. Nothing restricts the
purchases by storefront, device or account; they are not gated behind sign-
in. The Paid Apps Agreement is in effect (the Lifetime purchase has been
live since 2.0.0).

## New in 2.1.0

1. Six ready sessions (foundation to pre-season), built from the library's
   own drills: Plans → New → "From a ready session".
2. Text can be written on the board, a drill's step note sits on the board
   and changes with each step, and a selected line can be restyled.
3. The court takes the sport's official colours: a green court with white
   net tape.
4. iPad: a side bar instead of tabs, list-beside-detail for drills and
   plans, panels as popovers, hardware keyboard shortcuts and Apple Pencil
   drawing while fingers move players. In landscape on iPhone the side bar
   keeps to the Dynamic Island's side.
5. The app's interface and every drill's coaching notes are now also in
   German and Dutch (14 languages in all).
6. The Pro screen is titled "All drills, no ads". Back from a board returns
   to the practice plan being run; labels that were still in English were
   translated.

## Store compliance

7. The description carries the standard EULA link and the privacy policy
   link in every localization.
8. No App Tracking Transparency prompt: ads are non-personalized, the
   privacy manifest declares `NSPrivacyTracking = false`, and the App
   Privacy label declares no tracking. These three agree.

## How to see it

Open the app → Plans → New → "From a ready session", or Drills → any card →
"Put on the board" → press play. No account is required; Sign in with Apple
and Google are optional and only back up a coach's own boards.

## What was tested

Run on the iOS Simulator (iPhone and iPad). The automated suite — 798 tests,
including the ready sessions, the board text and the iPad layout — passes, and every drill board was
rendered through the app's own painters and reviewed.

Thank you for reviewing.
