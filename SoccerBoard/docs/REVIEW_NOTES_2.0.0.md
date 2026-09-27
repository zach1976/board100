# Review Notes — Soccer Board 2.0.0 (build 3)

> 提交执行：从 "Dear App Review team" 到 "Thank you..." 写入 App Review
> Information。
>
> **背景更正（2026-09-27）**：iOS 线上版本是 **1.1.25 READY_FOR_SALE**，
> 2026-07-26 的那次审核是 **APPROVED**。iOS 侧没有待处理的拒绝。
> 之前看到的「1.1.24 REJECTED」是 **macOS 平台**的版本记录
> （4.3(a) 全量拒绝，见 memory 的 macos-4-3-spam-rejection），
> `tools/check_app_status.py` 没做 `filter[platform]` 才把它当成了 iOS。
> 所以本次是从 1.1.25 的**常规更新**，不是被拒后重交，Notes 不写拒因。
>
> **本文件不含真机验证声明**：2.0.0 (3) 没有在真机上过
> `DEVICE_QA_2.0.0.md` 那份清单。下面只写已经做过的事，不写没做的。

---

Dear App Review team,

Soccer Board 2.0.0 is a feature release over 1.1.25. Everything below is in
the build and can be reached from the app's own navigation.

## Drill library (new in 2.0)

1. 137 built-in soccer drills. Each one is an animated board carrying its
   setup, the ball path and the coaching point. Drills tab → any card → "Put
   on the board" → press play.
2. Search, plus filters by category (warm-up, possession, attacking,
   finishing, defending, set pieces, small-sided, goalkeeping, conditioning),
   by level, and by squad size.
3. Every drill was audited so each player faces the ball or their next action
   at every beat of the animation.

## Practice plans and squad (new in 2.0)

4. Drills and saved boards can be strung into a practice plan and run from
   the touchline one item at a time, with a record of what was actually run.
5. A squad page keeps players with their photos and marks attendance per
   session.

## Board

6. Redrawn player figures that turn to face where they are going; the ball is
   drawn at the feet of whoever holds it.
7. Equipment (goals, cones, poles, hurdles, rebounders, mannequins) is drawn
   from above, so it stays upright when the board is rotated to landscape.
8. A saved board can be shared as a web link; the recipient opens it in a
   browser and needs no app.
9. A player can be copied with their run and pasted onto the next page. The
   last hundred boards opened are one tap from the home page.
10. A move can be exported as a video as well as a still image.

## Store compliance

11. The description carries the standard EULA link and the privacy policy
    link in every localization.
12. The app does not present App Tracking Transparency. Ads are
    non-personalized, the bundle ships a privacy manifest declaring
    `NSPrivacyTracking = false`, and the App Privacy label declares no
    tracking. These three agree.
13. An optional one-time purchase removes ads, with a yearly alternative.
    Both products are attached to this version.

## What was tested, and how

- Automated: the shared board logic runs under unit and widget tests, and a
  scripted pass drives the real app on an iOS 26 simulator through the home
  page, the drill library, loading a drill, playing it to the last beat, the
  player editor and the timeline. The App Preview film accompanying this
  version is an unedited recording of that pass.
- Manual: the same flows on an iOS 26 simulator across all 12 shipped
  languages.

## Demo path (about 45 seconds)

Open the app → the home page lists drills to run today → Drills tab → tap any
card → "Put on the board" → press play and watch the passes run → tap a
player to bring up the edit bar → back → "Practice Plan" → add the drill →
run it.

No account is required for any of the above. Sign in with Apple and Google
are optional, and only back up a coach's own boards.

Thank you for reviewing.
