# Review Notes — Soccer Board 2.0.0 (build 3) — DRAFT

> 提交执行：从 "Dear App Review team" 到 "Thank you..." 粘贴/写入 App Review
> Information。含占位符 `[...]` 时提交脚本必须拒绝执行（zachs_app_base.md 6.4）。
>
> 两处占位符必须由人填：
> 1. `[REJECTION REASON]` — 1.1.24 的拒因，Resolution Center 里读，本地没有记录。
>    16 个 app 同批被拒；1.1.21 的拒因是 2.3.7（副标题带「免费」）与 3.1.2(c)，
>    2026-07 之后中文名称/副标题改成了关键词堆砌形态，2.3.7 是最可能的拒因，
>    本版已把 zh-Hans / zh-Hant 的名称和副标题改回描述性写法。
> 2. `[FINAL DEVICE QA REQUIRED]` — 真机验证事实，见 docs/DEVICE_QA_2.0.0.md，
>    过完再填型号 / iOS 版本 / 过了哪些流程。

---

Dear App Review team,

This submission follows the rejection of 1.1.24. [REJECTION REASON — one
sentence on what was rejected and what was done about it. If 2.3.7: "The
Simplified and Traditional Chinese app name and subtitle have been rewritten
as plain descriptions — '足球战术板 - 战术与训练' / '阵型、跑位、定位球与训练计划' —
and no longer repeat the sport name in every segment."]

2.0.0 is a full release, not a metadata resubmission. Everything below is in
the build and can be verified in the app.

## Drill library (new)

1. 137 built-in soccer drills, each an animated board with its setup, the
   ball path and the coaching point. Drills tab → any card → "Put on the
   board" → play.
2. Search, and filters by category (warm-up, possession, attacking,
   finishing, defending, set pieces, small-sided, goalkeeping, conditioning),
   level and squad size.
3. Every drill was audited so that each player faces the ball or their next
   action at every beat; the audit is repeatable and shipped in the source.

## Practice plans and squad (new)

4. Drills and saved boards can be strung into a practice plan and run from
   the touchline one item at a time, with a history of what was actually run.
5. A squad page keeps players with photos and attendance per session.

## Board

6. Redrawn player figures that turn to face where they are going; the ball is
   drawn at the feet of whoever holds it; the referee is a person's height.
7. Equipment (goals, cones, poles, hurdles, rebounders, mannequins) is drawn
   from above, so it stays upright when the board is rotated to landscape.
8. A saved board can be shared as a web link; the recipient needs no app.
9. A player can be copied with their run and pasted onto the next page; the
   last hundred boards opened are one tap away from the home page.
10. A move can be exported as a video as well as an image.

## Store compliance

11. Description carries the standard EULA link and the privacy policy link.
12. The app does not request App Tracking Transparency; ads are
    non-personalized and the privacy label declares no tracking.
13. An optional one-time purchase (and a yearly alternative) removes ads.
    Both products are attached to this version.

## Device verification

[FINAL DEVICE QA REQUIRED — replace with facts, e.g. "Verified on iPhone 15
Pro, iOS 18.6, and iPhone SE (3rd gen), iOS 17.5: install over 1.1.24 keeps
saved boards; all 12 languages follow the device language; every drill in the
library loads and plays; share link opens in Safari with no app; purchase and
restore flows complete in the sandbox."]

## Demo path (about 45 seconds)

Open the app → Home shows today's drills → Drills tab → tap "Passing
pattern" → "Put on the board" → press play and watch the passes → tap a
player to see the edit bar → back → "Practice Plan" → add the drill → run it.

No login is required for any of the above. Sign in with Apple / Google is
optional and only backs up boards to the coach's own account.

Thank you for reviewing.
