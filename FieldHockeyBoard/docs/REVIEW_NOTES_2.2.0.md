# Review Notes — Field Hockey Board 2.2.0 (build 4)

> 提交执行：从 "Dear App Review team" 到 "Thank you..." 写入 App Review
> Information。线上版本是 2.0.1，本次是 2.0.1 → 2.2.0。
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

## In-app purchase submitted with this version

1. The auto-renewable yearly subscription "fieldhockey_remove_ads_yearly"
   (group "Tactics Board Pro") is submitted for the first time with this
   version. It removes ads and unlocks the full drill library, the same as
   the already approved one-time "Lifetime" purchase.
2. To see it: open any board → the menu button (top corner) → "Remove Ads",
   or open a locked drill in the Drills tab and tap "Unlock with Pro". The purchase sheet
   lists both plans with their localized prices, states that the yearly plan
   auto-renews and can be cancelled in Settings, and links the Terms of Use
   (standard EULA) and the Privacy Policy. "Restore Purchases" is on the same
   sheet.

## New in 2.2.0

3. Two new pitches beside the outdoor one: the FIH indoor pitch and the
   Hockey5s court, chosen from the board's field menu. Each board keeps its
   own pitch, and the formation list follows it.
4. The drill library grows from 36 to 65 drills, six of them indoor.
5. Text can be written on the board, and a drill's step note sits on the
   board and changes with each step.
6. The app's backgrounds take the sport's blue instead of the shared dark teal.
7. iPad: a side bar instead of tabs, list-beside-detail for drills and
   plans, panels as popovers, hardware keyboard shortcuts and Apple Pencil
   drawing. In landscape on iPhone the side bar keeps to the Dynamic
   Island's side.
8. The app's interface and every drill's coaching notes are now also in
   German and Dutch (14 languages in all).

## How to see it

Open the app → the board → the field menu → "Indoor" or "Hockey5s", or
Drills → any card → "Put on the board" → press play. No account is
required; Sign in with Apple and Google are optional and only back up a
coach's own boards.

## What was tested

Run on the iOS Simulator (iPhone and iPad). The automated suite — 721 tests,
including the indoor and Hockey5s pitches — passes, and every drill board in
the library was rendered through the app's own painters and reviewed.

Thank you for reviewing.
