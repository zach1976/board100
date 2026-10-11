# iPad locale and layout audit (widget-test sweep)

Date: 2026-10-11. Read-only. No lib/ changes, no commits. The temporary tests (`test/tmp_ipad_*.dart`) have been deleted, and `git status` shows only the untracked `tactics_board/test/tmp_twoball_test.dart`, which was there before this audit.

## How the sweep ran

- **Harness:** one `pumpWidget` per file. EasyLocalization holds all 12 locales, and `ctx.setLocale` switches between them. The home widget is a `ValueNotifier<Widget>` inside a `MaterialApp` with the app's dark theme, and a `ValueNotifier<TacticsState>` supplies a fresh state per sport. Between screens the test calls `navigator.popUntil(first)` and then shows `SizedBox.shrink()`.
- **Overflow capture:** a hook on `FlutterError.onError` writes each overflow (locale, size, sport, screen, message, `lib/` source line) to a TSV file. I checked the hook works by running the same sweep at 220×500 in Thai. It recorded 40 overflows, for example `drill_library_page.dart:689` and `toolbar.dart:1200`.
- **View:** device pixel ratio 2. Simulated safe area of top 24 and bottom 20. The real apps hide the status bar (`UIStatusBarHidden`), so the real top inset is smaller.
- **Fonts:** Roboto and MaterialIcons from the Flutter cache, plus `/System/Library/Fonts/Supplemental/Arial Unicode.ttf` as the fallback font. **CJK, Thai and Korean rendered as real text, with no tofu boxes.** Metrics are Roboto/Arial rather than SF Pro/PingFang, so widths are close to iOS but not exact.
- **Sizes:**

  | Name | Size (pt) |
  |---|---|
  | pro_p | 1032×1376 |
  | pro_l | 1376×1032 |
  | mini_p | 744×1133 |
  | mini_l | 1133×744 |
  | split_half | 678×1032 |
  | slideover | 375×1032 |

- **Sports:** soccer, volleyball, tableTennis, waterPolo, rugby.
- **Screens, per locale and size:**
  - The hub picker.
  - Per sport: MainShell home (top and scrolled), Drills tab (top and scrolled), drill detail for the drill with the longest name (top and scrolled), the board with that drill loaded, the Add sheet, draw mode with its draw panel, and the Timeline sheet.
  - The ⋯ menu (soccer and volleyball only).
  - Intro (no art).
  - Me tab and Practice Plan (soccer only).
  - A second pass covered the Practice plan page after loading, and the Practice **run** page, at 5 sizes × 8 locales.
  - A third pass served SoccerBoard's real shell artwork (hero, covers, intro_1–3 webp) through a mock `flutter/assets` channel, for home and the three intro panels: 5 sizes × en/th/fr/ja.
- **Volume:** about 3,450 overflow-checked renders across 12 locales × 6 sizes, and 3,020 PNGs under `scratchpad/ipad_audit/sweep/<size>/<locale>__<screen>.png`. Montages I inspected are in `scratchpad/ipad_audit/mont/`.

## Overflow result

**Zero RenderFlex/overflow errors in any locale, at any of the 6 iPad sizes, on any of the screens above. There were also zero other Flutter errors.** Files: `sweep/overflows_*.tsv` (all empty) and `sweep/errors_*.txt` (all empty).

## Findings by severity

There are no BLOCKERs: no overflow, no control that cannot be used, and no text that cannot be read at all.

| # | Sev | Locale | Size / orientation | Screen | Evidence | Fix |
|---|---|---|---|---|---|---|
| 1 | MAJOR | all | pro_l, mini_l (landscape) | Intro, 3 panels, sport shells (and the hub intro, by the same code) | `sweep/pro_l/th-TH__art_intro3.png`, `mont/art_intro.png`. The art is portrait (933×2021). `BoxFit.cover` with `Alignment.bottomCenter` shows only the bottom ~35% (pro_l) or ~30% (mini_l) of it. The tactics board, magnets and ball then sit directly behind the headline and body text, which the code says must land on the empty top 40%. The body text over the magnets is low contrast. The three pillars spread across 1376pt. | `lib/pages/intro_page.dart:351-357` (`_Backdrop`): when `size.aspectRatio > 0.75`, lay the panel out as two columns (text column max ~520 on the left, art in a portrait box on the right), or at least use `Alignment.center` and a full-height scrim. Cap the text column (`:284`, Padding) at ~560 wide. |
| 2 | MAJOR | all | all iPad sizes ≥678 | Intro CTA "Next/Start" | `sweep/pro_l/en-US__soccer_intro.png`: a 60pt pill 1336pt wide. | `lib/pages/intro_page.dart:214-217`: wrap `_BigCta` in `Center(ConstrainedBox(maxWidth: 480))`. |
| 3 | MAJOR | all | pro_p, pro_l, mini_l, split_half | Me tab | `sweep/pro_l/en-US__me.png`. The page runs to the full 1336pt with no column cap. In each row the trailing value ("None yet ›", "English (US) ›") sits in the middle of the row (x≈700), not at the right edge. | `lib/pages/main_shell.dart:693-698`: the trailing `Flexible` splits the free space 1:1 with the label's `Expanded`. Make it `Expanded(child: Text(..., textAlign: TextAlign.end))` or give the label a larger flex. `main_shell.dart:417` ListView: wrap it in a centred `ConstrainedBox(maxWidth: 720)` (or reuse SportHomePage's `_kMaxColumn` idea). |
| 4 | MAJOR | all | pro_p, pro_l, mini_l | Drill library (Drills tab) | `sweep/pro_l/en-US__soccer_drills.png`, `mont/pro_p_en_a.png`. Rows span the full width with no cap. The usage tag ("Staple/Common") floats mid-row (x≈700). The "open on board" icon is at the far right edge, about 600pt from the text it belongs to. | `lib/pages/drill_library_page.dart:~752-775`: the name is `Expanded` and the tag is `Flexible`, which splits the free space. Make the name `Flexible` so the tag follows it. Cap the list (padding at `:257`) at ~1040 centred, as `sport_home_page.dart:334-345` already does. |
| 5 | MAJOR | all | mini_p, mini_l, split_half | Board toolbar | `mont/toolbars.png` and `mont/toolbars2.png`. Move/Draw/Select/Add lose their labels on iPad mini and in Split View, even though each icon-only slot is ~90pt wide. The labels appear on the 13" iPad, so the two iPads look inconsistent. | `lib/widgets/toolbar.dart:1039-1040`: `wide = roomy && box.maxWidth >= barButton(context) * 8.4`. `barButton` is scaled ×1.4 on tablets (`toolbar.dart:69,88`), so the threshold becomes 517pt. Use `T.tap * 8.4` (≈370) or measure the four labels. |
| 6 | MAJOR | all | pro_l, pro_p, mini_l | Practice run page | `sweep/pro_l/fr-FR__run.png`. This is the phone layout stretched. The drill card is full width, the prev and next arrows are about 480pt apart, the Reset button is 300pt and "Open on board" 600pt wide, and the middle is a large empty area. | `lib/pages/practice_run_page.dart:230+` (body) and `:340-360` (button row): centre the content in `ConstrainedBox(maxWidth: 640)`. |
| 7 | MAJOR (locale) | es, fr, id, ja, ko, ms, th, vi (+zh-TW for some keys) | all | Me, Drills chip, Timeline sheet, Practice run, Contact page | `sweep/mini_p/th-TH__me.png` shows "Login", "My drills", "Language" and "Contact Us" in English, the drill chip says "Starred", and the Timeline and Run pages say "Reset". | `assets/translations/*.json`: keys `menu_login`, `menu_contact`, `menu_language`, `home_starred`, `drills_starred`, `timeline_reset`, `contact_title`, `send`, `your_email`, `subject` and `message` are identical to en-US. That is 9 locales for most keys, and 8 for `home_starred` and `drills_starred` (zh-TW has those two). Only zh-CN is fully translated. Keeping `menu_language` in English may be deliberate; the others are not. |
| 8 | MINOR | all | pro_l (and any width >1040) | Sport home | `sweep/pro_l/en-US__soccer_home.png`. The title "Soccer Board" and its tagline sit at x=20, while the content column starts at x≈168, so the left edges do not line up. | `lib/pages/sport_home_page.dart` `_hero(...)`: apply the same `_kMaxColumn` centring (`:340`) to the hero's text row, leaving the photo full-bleed. |
| 9 | MINOR | all | pro_p (1032) | Drill library filter chips | `mont/pro_p_en_a.png`. The category chip row is a horizontal scroller cut mid-chip ("Set p…") at the edge, with no hint that it scrolls. In landscape the chips fit. | `lib/pages/drill_library_page.dart:453` and `:505`: on width ≥700 use a `Wrap` instead of `SingleChildScrollView`. |
| 10 | MINOR | all (worse in vi, id, ms) | all | Add sheet → OBJECTS row | `mont/vi_soccer_add_sheet.png`, `mont/fr_sheets.png`. Inside the 640pt sheet the last tile is cut ("Triang", "Tam gi", "Segitig"). "Hình vuông", "Tuan Rumah" and "Chủ nhà" wrap onto 2 lines inside 56pt tiles. | `lib/widgets/toolbar.dart:2171`: on tablets use a `Wrap` (or widen the tile to fit the label). |
| 11 | MINOR | all | pro_l, mini_l | Hub picker | `sweep/pro_l/en-US__hub.png`, `mont/misc.png`. "Team sports" has 5 cards in 4 columns, so one card is orphaned next to ~1000pt of empty space. | `lib/pages/sport_selection_page.dart` grid: choose a column count that divides the shelf (5 → 5 or 3) or let the cards size to fill the row. |
| 12 | MINOR | es-ES | slideover (375) | Hub picker | `sweep/slideover/es-ES__hub.png`: "Hockey sobre…" is truncated. This is the same phone-width behaviour, not iPad-specific. | Allow 2 lines on the `_SportCard` name (`sport_selection_page.dart:380+`). |
| 13 | MINOR | all | pro_l | Draw panel, Timeline sheet | `mont/pro_l_en_d.png`, `mont/pro_l_en_c.png`. Phone-sized panels (~380pt and ~430pt) float in a 1376pt canvas. They work, but the slider and swatches are small for a tablet. | Optional: scale them with `uiScale(context)` as the chrome circles already do (`toolbar.dart:69`). |
| 14 | MINOR | all | pro_p | Drill detail (wide layout, width ≥900) | `mont/pro_p_en_b.png`. The left column is 0.36 of the width, so the pinned board is narrow, and in portrait there is a large empty area under it. | `lib/pages/drill_detail_page.dart:225,288`: consider using the wide layout only when landscape, or give the board a taller share in portrait. |

### Checked and fine

- **No full-width bottom sheets.** Material 3 caps them at 640pt.
- **The courts scale correctly** in both orientations for all 5 sports, and the board rotates the pitch in portrait.
- **CJK, Thai and Vietnamese text is not clipped** on home cards, detail titles (2 lines), the timeline, or the menu.
- **SportHomePage** already caps its column at 1040 and uses a 3-column card grid.
- **Practice plan** empty state is centred and fine. The page title touching the left edge in the PNGs is a test artefact: the page was the root with no back button.

## Static string-length scan

`scratchpad/ipad_audit/strlen.tsv`.

- **Method:** short UI strings (en ≤ 40 characters) where a locale is more than 1.6× the en-US visual width, counting CJK as 1.8 and ignoring Thai combining marks.
- **Totals:** 251 locale-key pairs over the threshold, across 150 keys. 57 of those keys are used in chips, buttons, tabs or titles.
- **Worst cases:**

  | Key | Usage | en | Longer translations |
  |---|---|---|---|
  | `male_doubles` / `female_doubles` | `toolbar.dart:4185`, formation chips | "M+M" | ja ×3.6 "男子ダブルス" |
  | `redo` / `undo` | | | ms ×2.75, ko ×2 (icon-only on iPad, semantic labels only) |
  | `save` | | | fr ×2.75 |
  | `intro_next` | | | ms ×2.5 |
  | `team_home` / `team_away` | | | id/ms "Tuan Rumah", es "Visitante" |
  | `mode_move` / `mode_select` / `mode_draw` | | | vi/fr ×2 |
  | `plan_add_drill` | | | fr ×2.1 |

- **On iPad none of these overflow**, as the sweep confirms. The visible effects are #5 (tool labels dropped) and #10 (2-line object labels). The formation chips sit in a horizontal scroller (`toolbar.dart:4166`), so the Japanese labels scroll rather than overflow.

## Counts

**Overflow errors:** 0 at every locale × size.

| | pro_p | pro_l | mini_p | mini_l | split_half | slideover |
|---|---|---|---|---|---|---|
| en-US | 0 | 0 | 0 | 0 | 0 | 0 |
| en-GB | 0 | 0 | 0 | 0 | 0 | 0 |
| zh-CN | 0 | 0 | 0 | 0 | 0 | 0 |
| zh-TW | 0 | 0 | 0 | 0 | 0 | 0 |
| ja-JP | 0 | 0 | 0 | 0 | 0 | 0 |
| ko-KR | 0 | 0 | 0 | 0 | 0 | 0 |
| es-ES | 0 | 0 | 0 | 0 | 0 | 0 |
| fr-FR | 0 | 0 | 0 | 0 | 0 | 0 |
| id-ID | 0 | 0 | 0 | 0 | 0 | 0 |
| ms-MY | 0 | 0 | 0 | 0 | 0 | 0 |
| th-TH | 0 | 0 | 0 | 0 | 0 | 0 |
| vi-VN | 0 | 0 | 0 | 0 | 0 | 0 |

**Visual findings (14):**

- **By locale:** 12 apply to every locale. #7 applies to 8–9 non-Chinese locales. #12 is es-ES only, and #10 is worse in vi, id and ms.
- **By size:**

  | Size | Findings |
  |---|---|
  | pro_l | 1, 2, 3, 4, 6, 8, 11, 13 |
  | pro_p | 2, 3, 4, 6, 9, 14 |
  | mini_l | 1, 2, 3, 4, 5, 6, 11 |
  | mini_p | 2, 5 |
  | split_half | 2, 3, 5 |
  | slideover | 12 |

- **#7 and #10** apply at every size.

## What I could not test

- **Real iOS fonts** (SF Pro, PingFang, Hiragino, Thonburi). I used Roboto and Arial Unicode, so widths may differ by a few percent. With zero overflows and generous iPad widths, the risk is low.
- **Larger accessibility text sizes on iPad:** not swept. The phone large-text test exists, but the iPad layout at 1.3–2.0× was not run.
- **Shell artwork for sports other than soccer:** served only from SoccerBoard. The other shells (volleyball, table tennis, water polo, rugby) have intro art only, and use the same `_Backdrop` code, so #1 applies to them. The hub intro (HubBoard art) was not rendered.
- **Sheets not opened:** login, contact, language picker, field/court settings, the player edit bar, the photo/team sheets, save/load, PDF export, and practice history/attendance.
- **Practice plan** was checked only in its empty state, with no saved plans in the list.
- **Not simulated:** Stage Manager free-form window sizes, the iPad keyboard, and pointer hover. I also did not check the real safe-area insets on device, since the status bar is hidden.
- **Simulator:** I did not use one, as instructed, and did not touch the "Lang1000 Audit iPad" simulator.
