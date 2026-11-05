# Usability audit: HubBoard + 9 single-sport apps (tableTennis, tennis, pickleball, rugby, handball, waterPolo, sepakTakraw, beachTennis, footvolley)

Screenshots are in this folder (`NN_*.png` full size, `*_s.jpg` downscaled, `*_crop.png` zooms). Device: iPhone 17 Pro sim 7D49F0A5, HubBoard debug build from branch soccer-2.2.0. I also built FootvolleyBoard once to check how a single-sport app's colours look.

## (a) Verdict
**Not ready to ship as-is.**
- **The hub can lose a coach's saved board.** Switching sport keeps the previous board's name. Opening and leaving a board in another sport then writes an empty board over the saved one. I reproduced this.
- **Chinese has a wrong sport term.** The "Finishing" category shows as 射门 ("shot on goal") in every net sport and in rugby.
- **Drill thumbnails are wrong for most sports.** Every thumbnail is drawn on a green soccer pitch with a centre circle: the table-tennis table, the pool and the sand courts included.
- **Several layout problems:** the step note gets clipped at the bottom of the board; the draw panel hides players; each sport's own equipment is buried behind soccer gear.

Core flows work in every sport and nothing crashed: library, search, filters, drill detail, stepping, playback, Add, draw, timeline, save, plan.

## (b) Findings

| # | Sev | App / sport | Screen | What's wrong | Evidence | Fix |
|---|---|---|---|---|---|---|
| B1 | BLOCKER | Hub, all sports | Sport switch → home → board | `setSportType` clears the players but keeps `currentTacticName`, `currentTacticMeta` and `drillBeats`. It also never saves the old sport's working board or restores the new one. Result: Rugby's home card said "TT a" (the table-tennis board) above an empty pitch. Opening and leaving it created a ghost "TT a" under Rugby. Back in Table Tennis, "Open the board" showed an empty table named "TT a", and leaving it **overwrote the saved TT board with an empty one** (data loss). | 40_rugby_home, 41_rugby_open, 42_rugby_home_after, 47_tt_open3, 48_tt_saved_board_after; `state/tactics_state.dart:514-531`, `pages/sport_selection_page.dart:122-124`, `autosave()` ~l.232 | In `_open`: `await state.autosave()` before switching. `setSportType` should null `currentTacticName`/`Meta`, clear `drillBeats`/`drillSetup`, then `restoreWorkingBoard()` for the new sport. |
| B2 | BLOCKER | All net sports (TT, tennis, pickleball, beach tennis, footvolley, sepak) + rugby, zh-CN / zh-TW | Home "按类别找", library chips | `drill_cat_finishing` = 射门 / 射門 ("shot on goal") in sports with no goal. Net sports only override possession/setpiece/ssg, not finishing. Rugby (tries) uses the soccer word too. | 121_zh_tt_home2; `models/drill.dart:204-222`; zh-CN.json `drill_cat_finishing` | Add `finishing` to the net overrides as `drill_cat_finishing_net` (EN "Put-away", zh 得分球/终结). Add a rugby term (达阵). Check every locale. |
| M1 | MAJOR | All 9 | Library list, home "Recent" | Thumbnails always paint soccer turf with a centre circle (`T.turf`, `drawCircle`): table tennis looks like a pitch, water polo is a grass field, beach courts are green, rugby gets a centre circle. Some thumbnails are blank apart from the circle (tennis "Rally"). | 11_tt_thumbs_crop, 61_hb_lib, 71_wp_lib, 81_tennis_lib, 91_bt_lib, 95_fv_lib; `widgets/drill_thumbnail.dart:353-380` | Use the sport's surface colour and its own simple markings (net line for net sports, no circle). Fall back to the start positions when a drill has no arrows. |
| M2 | MAJOR | Rugby, handball, beach tennis, pickleball, sepak, water polo (worse in zh) | Board (drill loaded) | The step-note text element sits at the bottom edge. Its second line is cut off by the board frame or transport bar (and hidden under the drill-name snackbar for 4 s). In Chinese it is truncated with "…" ("5 名 ..."). | 55_rugby_note_crop, 64_hb_note_crop, 93_bt_board, 117_zh_wp_board | Clamp the note inside the visible board rect, prefer the top band, allow 3 lines without ellipsis, and keep it clear of goals. |
| M3 | MAJOR | All (seen in TT) | Board → Draw | The draw options panel (Line/Eraser/colours) covers the bottom ~20% of the board. TT player "1" and the ball disappear, so you can't draw from the player you're annotating. | 15_tt_board2 vs 20_tt_draw_mode | Dock the options into the transport-bar slot, or shrink or lift the board while drawing. |
| M4 | MAJOR | TT, tennis, pickleball, beach tennis, footvolley, sepak, water polo, rugby | Add sheet → More | Each sport's own equipment is appended after 24 shared items (`order 24+`). TT Net/Paddle are items 19-20 of a horizontal strip; WP "Water goal"/"Lane rope" are last and their labels are truncated. Meanwhile soccer goal, mini goal, corner flag, a bag of soccer balls, ladder and hurdle are offered in a pool and on a TT table. | 19_tt_more_end, 76_wp_more_b, 119_zh_wp_more, 57_rugby_row_crop; `widgets/toolbar.dart:1933-1975` | Put `sportType.markers` right after the inline row (order 4…). Hide goal/miniGoal/cornerFlag for net sports and water polo. Use a sport-specific ball bag. |
| M5 | MAJOR | Water polo (also any formation with unequal sides) | Add sheet → Players | The count chip label is built from `homeCount` only. The 6v5 power-play formation appears as **"6v6"**, and because it's the only formation for that count its name is never shown. | 74_wp_6v6; `toolbar.dart:4200-4213`, `sport_type.dart` WP `formation_6v5` | Label as `${home}v${away}` or show the formation name ("Power play 6v5"). |
| M6 | MAJOR | All | Practice Plan → Edit Plan → Add Tactic | The picker lists only saved boards. None of the sport's 28-42 library drills can be added from inside the plan editor; you have to leave and use "Add to plan" on each drill. Wording also mixes "Drills" (header), "add a tactic" and "Add Tactic", and the picker's first row repeats "Add Tactic" (= save the current board). | 32_tt_plan_created, 33_tt_addtactic; `pages/practice_plan_page.dart:486-530` | Add a "From drill library" entry that opens the library in pick mode. Use one noun (drill/board). |
| M7 | MAJOR | All (hub + single apps) | Home "What to run today" cards | When the title wraps to two lines, the description's 2nd line is cut mid-glyph and runs into "10 min". | 10_tt_card_crop, 60_hb_home, 70_wp_home, 131_fvapp_home; `pages/sport_home_page.dart:1236-1262` | Drop the description to 1 line when the title wraps, or clip it (ClipRect plus a maxLines computed from the space left). |
| m1 | MINOR | Hub: TT, beach tennis, sepak | Sport home header | The 24pt title truncates: "Table Tennis Bo…", "Beach Tennis Bo…", "Sepak Takraw B…". | 10_tt_home, 98_st_home | Scale down (FittedBox) or allow 2 lines. |
| m2 | MINOR | All | Library opened from a home category | The selected category chip is scrolled off-screen, so you can't see which filter is active (two rows of "All" chips with no row labels). | 51_rugby_setpieces, 59_chips_crop | `Scrollable.ensureVisible` on the active chip; label the level row. |
| m3 | MINOR | Hub | Picker "Continue" card | "35 drills · 1 boards". | 37_picker; `hub_boards_n` | Plural forms. |
| m4 | MINOR | All | Home "Recent", board text | After a language switch, Recent rows and the drill note already on the board stay in the old language ("Dink cross-court" under zh). | 110_zh_pb_home, 115_zh_wp_lib | Store the drill id and resolve the label at render time. |
| m5 | MINOR | All | Save board / New plan / New board | Saving a board loaded from a drill doesn't prefill the drill's name. The confirm button in the create dialogs says "Apply" rather than Create/Save. | 25_tt_savepage, 31_tt_newplan, cur (Name this board) | Prefill; rename the button. |
| m6 | MINOR | All | Timeline | The ball's row has an empty grey dot and no label. The drawn line's row shows "ALL" in a middle cell. | 22_tt_timeline | Label it "Ball". |
| m7 | MINOR | All | Drill detail/board title | Family and variant are joined by plain concatenation: "Set piece the scrum", "Warm-up on every surface", "Rally control half-long pushes". | 52_rugby_scrum, 10_tt_home | Use a separator ("Set piece · the scrum") or authored titles. |
| m8 | MINOR | Handball, rugby, WP vs net sports | Add → Players | Handball shows formation "7v7" under count "7v7" (duplicate). Chip styles are inconsistent: net sports get illustrated chips ("Regu (3v3)"), team sports get bare "15v15 / 7v7". | 66_hb_7v7, 54_rugby_add, 99_st_add | Name formations ("6-0 base"); one chip style. |
| m9 | MINOR | Beach tennis, footvolley | Board figures | Barefoot sand sports are drawn in socks and boots. | 93_bt_board, 96_fv_board; `sport_type.dart:460` `playerBody` | Add a barefoot body for the sand sports. |
| m10 | MINOR | Pickleball | Picker/Continue vs board | Picker and Continue thumbnails show a blue court; the board and home default is green (`courtSurfaces` lead with 0xFF2E7D32). | 45_picker_bottom, 113_zh_picker vs 100_pb_home | Use the same default in both places. |
| m11 | MINOR | Footvolley app (all shells), hub | Intro, picker shelf | Intro says "Put players on the pitch" in a footvolley app. The hub shelf "Pitch sports" holds the basketball and handball courts. | 130_fvapp_launch, 01_launch | Sport-neutral wording ("on the court/field"). |
| m12 | MINOR | Rugby, handball, WP | Drill detail setup line | Auto text "red: D, D, D, D, D, D, D, D" is unreadable. | 52_rugby_scrum | Collapse to "8 defenders (D)". |
| m13 | MINOR | Single-sport apps (footvolley checked) | Me tab | The re-hued chrome is readable (worked out from the code: dim text 5.5-8:1 on surfaces, teal accent ≥5.3:1). But the Login card keeps a hard-coded teal gradient on brown chrome, and `textOff` is 3.0-4.5:1 on surfaceHi everywhere (an older issue, also in the hub). | 132_fvapp_me, 131_fvapp_home | Derive the gradient from the palette; lift `textOff` slightly. |
| m14 | MINOR | All | Library card badge | "Regular" (usage frequency) has no explanation and reads like a level. | 11_tt_lib | Icon plus tooltip, or rename ("Used often"). |
| m15 | MINOR | TT | Board | The TT ball is drawn as big as a player's head, at hip height. | 13_tt_ball_crop | Scale the ball per sport. |

## (c) Per-sport counts (findings observed in that sport; shared ones counted in each)

| Sport | Blocker | Major | Minor |
|---|---|---|---|
| Hub (picker/shell) | 1 (B1) | 2 (M6, M7) | 4 (m1, m3, m10, m11) |
| Table tennis | 2 (B1 data loss, B2) | 6 (M1, M3, M4, M6, M7, + M2 n/a) | 7 |
| Tennis | 1 (B2) | 4 (M1, M4, M6, M7) | 4 |
| Pickleball | 1 (B2) | 5 (M1, M2, M4, M6, M7) | 5 |
| Rugby | 2 (B1 ghost board, B2) | 5 (M1, M2, M4, M6, M7) | 6 |
| Handball | 0 | 4 (M1, M2, M6, M7) | 5 |
| Water polo | 0 | 6 (M1, M2, M4, M5, M6, M7) | 5 |
| Sepak takraw | 1 (B2) | 5 (M1, M2, M4, M6, M7) | 4 |
| Beach tennis | 1 (B2) | 5 (M1, M2, M4, M6, M7) | 5 |
| Footvolley | 1 (B2) | 4 (M1, M4, M6, M7) | 6 |

## (d) Not tested / limits
- **Landscape:** `simctl` can't rotate and idb has no rotate command. Not tested.
- **iPad and macOS:** not run.
- **Device-level language:** I switched language with the app's own picker (zh-CN for pickleball, water polo, table tennis) instead of AppleLanguages. The device language was never changed; the app language is back to English (US).
- **Not exercised:** Share/PDF export, presentation mode, login/sync, photo import, My Teams, practice *run*, the full drill catalogue.
- **Ads:** no test app-open ad appeared during the session.
- **Hub first-run intro:** the hub already had data, so I didn't see its intro. I saw the footvolley app's intro on a fresh install.
- **Single-sport shells:** only FootvolleyBoard was built and opened. The other shells share the core, so code-level findings apply to them, but I didn't open each one.
- **Performance:** no jank or crash seen. A 4-beat drill plays in about 3.5 s.
- **Test data left on the simulator** (hub, com.zach.tacticsBoard): TT board "TT a" (emptied by B1), a ghost rugby board "TT a", TT plan "Tuesday". FootvolleyBoard (com.zach.footvolleyBoard) is now installed.
