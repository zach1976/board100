# Strict audit: table tennis, sepak takraw, footvolley (drill pack as of 2026-10-11)

PNG paths are relative to `tools/board_png/`. Sn means step n, which is `<id>-n.png`. Metres are court coordinates with y measured from the top (far) end line.
- Table tennis: table 1.525 × 2.74, net at y = 1.37. On the phone canvas the visible area runs from about y = −0.76 to y = 3.50.
- Sepak takraw: court 6.1 × 13.4, net at y = 6.7. Service-circle centres are at y = 2.45 and y = 10.95, radius 0.30.
- Footvolley: court 9 × 18, net at y = 9.

## (a) Verdict per sport

**Table tennis (35 drills): not ready.**
- The court painter is correct (ITTF 2.74 × 1.525 table, centre line, net).
- The doubles game breaks two of the sport's rules. The serve goes from the server's left half to the receiver's left half, while the note says right half to right half. The receiver then returns the ball to the server again, so there is no alternation. Two of the four players are also half off the canvas.
- All three fitness drills draw the player and cones on top of the table, even though the text says the cones go "on the floor behind the table".
- Cones also sit on the playing surface in the footwork, short-game and half-table drills.
- In the lob and deep-chop defence drills, the defender walks off the bottom of the board.
- Most feed and rally drills stop one stroke too early. The loop, flick, smash and third-ball attack are never drawn. After the last contact the ball is left lying on the floor while the player walks away.
- Multiball and the footwork drills (Falkenberg is labelled advanced) are filed as warm-ups, so their notes read "raise the heart rate… opens the training".

**Sepak takraw (32 drills): not ready.**
- The court painter is correct: 13.4 × 6.1, service circle r = 0.30 centred 2.45 m from the back line, quarter circles r = 0.90.
- The serve law is broken in 9 drills:
  - In both "Tekong serve" drills the inside player kicks the ball over the net and the tekong never touches it.
  - In `st_receive_header` the red tekong serves from the blue half's own service circle, so the serve never crosses the net.
  - The 2v2, 3v3 and no-block games start with an inside player kicking from about 2 m off the net.
  - In the three feed drills the tekong serves from 0.5 m outside the circle.
- The attack, defence and feed families never show the skill they are named after:
  - Attacks: the striker starts with the ball in hand, kicks it into the blocker, and the blocker returns it.
  - Defence: the ball path ends at the blocker and the defender never plays.
  - Feed drills: the feed is never drawn.
- Left/right labels are mirrored in places, and both teams use the same labels, so the text reads "L plays it to L".

**Footvolley (30 drills): not ready.**
- The court (18 × 9, net at 9 m) is fine.
- Six drills serve from inside the court:
  - In `fv_receive_chest` and `fv_receive_thigh` the server walks 1.8 m in and kicks from 2.5 m inside the baseline.
  - All four game drills open with a kick from 3.5–7 m inside the court.
- In every serve drill the ball goes to a receiver's standing spot, not to the shaded target zone. The receiver then walks onto the zone after the ball has arrived.
- The combination, finishing and control families never perform their named action:
  - Combination drills: the first touch is kicked straight over the net to the blocker.
  - Finishing drills: the back player shoots from 1.8 m off the net through the blocker, and the designated finisher never touches the ball.
- Chest, shoulder and header touches are drawn with the ball at the feet.
- Facing between teammates is correct in the drills I zoomed into.
- No player crosses the net in any of the three sports.

## (b) Findings, sorted by severity

### BLOCKER

| # | Sport | Drill / file | Step | Problem | Evidence (seen on the PNG) | Fix |
|---|---|---|---|---|---|---|
| B1 | All 3 (and every other sport except zh) | `tools/drills/notes_tableTennis.py`, `notes_sepakTakraw.py`, `notes_footvolley.py` (`_t()` only fills en/en-GB/zh-CN/zh-TW); the fitness setup strings are the same | n/a | **English sentences inside ja/ko/th/es/fr/id/ms/vi notes**, e.g. ja: `【用具】the shaded zone is the part of the table the ball has to land on…`. The Equipment, Setup and "How it continues" lines are untranslated in **33/35 TT, 25/32 ST and 22/30 FV drills**, for each of the 8 locales. | `tableTennis.json` and the others, field `note["ja-JP"]` | Add the 8 missing locales to every `_t()` and GEAR/SETUP/FLOW string, then regenerate. Add a generator check that fails when a non-en locale contains `\b(the\|and\|has)\b`. |
| B2 | TT | `tt_game_doubles` | S0–S2 | **Illegal doubles serve and no alternation.** Server 1 is at x = 0.34 (his left/backhand half) and serves to A at x = 1.19 (A's left half). ITTF 2.2.2 and the note itself say right half to right half. In S2, A plays back to **1** again; under ITTF 2.8.3 the next ball must be 2's. | `tableTennis/tt_game_doubles-1.png` (1 is on screen-left, the arrow goes to A on screen-right). `-2.png`: the arrow from A ends at 1. | Put 1 at x ≈ 1.19 and A at x ≈ 0.34. In S2 send the ball A → **2**, with 1 stepping out. |
| B3 | TT | `tt_game_doubles` | S0, S2 | **Players off the canvas.** B (y = −0.71) and 2 (y = 3.45) are cut off in S0, and A (−0.66) and 1 (3.40) in S2. | `tt_game_doubles-0.png`: B's head is above the top edge and 2's feet below the bottom edge. | Keep partners within y ∈ [−0.55, 3.30] and stagger them sideways instead of deep. |
| B4 | TT | `ttfit_side_step`, `ttfit_in_and_out`, `ttfit_figure_eight` | all | **Player and cones drawn on the table surface** (y 2.08–2.69; the table ends at 2.74). The text says "cones on the floor behind the table … the feet stay behind the cones, never under the table". | `tableTennis/ttfit_*-0.png`: the cones and runner sit inside the blue table. | Shift the whole layout behind the end line (y ≈ 2.95–3.35, which is already `offSurface`). |
| B5 | TT | `tt_footwork_two_one`, `tt_footwork_falkenberg`; `tt_short_touch/flick/banana/long_push`; `tt_game_half_table` | all | **Cones standing on the playing surface.** Footwork cones are at (0.67, 1.70), (1.19, 2.52) etc., but are meant to mark "spots the player has to get to". The short-game cone is at (0.61, 1.70), 0.33 m from the net, meant as the "spot the player steps in to". In the half-table drill the cones sit on the centre line. | `tt_footwork_falkenberg-0.png` (3 cones on the table), `tt_short_touch-0.png`, `tt_game_half_table-0.png` | Footwork: put the cones on the floor behind the end line at the player's stations. Short game: drop the cone, or put a floor cone at y ≈ 2.85. Half table: shade the half in play with a zone instead of cones. |
| B6 | TT | `tt_defence_lob` | S1–S3 | **The defender leaves the board.** 1 goes to y = 3.84 / 3.67 m, and the visible limit is about 3.35 m. | `tt_defence_lob-1.png` and `-3.png`: there is no "1" at the bottom; in S2 the ball arrow runs off the bottom edge. | Clamp to ≤ 3.30 m, or use a frame that shows more floor behind the table. |
| B7 | TT | `tt_defence_deep_chop` | S1–S2 | Same as B6 (y = 3.62 / 3.56). | `tt_defence_deep_chop-1.png`, `-2.png`: 1 is cut off at the bottom edge. | Same as B6. |
| B8 | ST | `st_tekong_high_toss`, `st_tekong_low_drive` | S1 | **The tekong never serves.** L (inside player) kicks the ball over the net to D, and the ball path is `L → D → T`. ISTAF: the inside player throws and the tekong kicks the serve. The drill's own note says "the inside player throws it…". | `sepakTakraw/st_tekong_high_toss-1.png`: the arrow runs from L at the left quarter circle to D, while T stands idle in the circle. | S1: L tosses to T (short arc, own side). S2: T serves to D. S3: D returns. |
| B9 | ST | `st_receive_header` | S0–S4 | **The server is in the receivers' half.** The red T (team 1) stands in the **blue** service circle (3.05, 10.95) and serves to R and F on the same side; the serve never crosses the net. | `st_receive_header-0.png`: red T is at the bottom circle and R/F are between T and the net. | Move T to the red circle (3.05, 2.45); R and F receive on the blue side. |
| B10 | ST | `st_game_2v2`, `st_game_3v3`, `st_game_no_block` | S1 | **Serve not from the service circle.** The rally opens with 1 kicking from y = 8.6 / 8.1 / 9.2 (1.4–2.5 m off the net). In 3v3 and no-block, the tekong 3 stands idle in the circle. The 2v2 doubles event also serves from the circle. | `st_game_3v3-1.png`: the arrow starts at 1 (inside left) and 3 is in the circle. | Give the ball to 3 (2v2: player 1 in the circle), place the inside players in the quarter circles, and serve from the circle. |
| B11 | ST | `st_feed_receiving_the_serve`, `st_feed_the_high_feed`, `st_feed_the_quick_feed` | S1 | **The tekong serves from outside the circle.** The red T moves to (3.05, 2.95), 0.50 m from the centre (the circle radius is 0.30). | `st_feed_the_high_feed-1.png`: T stands below the top circle, not in it. | Stop at y ≈ 2.68, as in `st_receive_left`. |
| B12 | FV | `fv_receive_chest`, `fv_receive_thigh` | S1–S2 | **Serve from inside the court.** S moves from y = −0.45 to 1.80, and the ball is kicked from (4.50, 2.50), 2.5 m inside the baseline. | `footvolley/fv_receive_chest-1.png`: S and the ball are clearly inside the top baseline. In `-2.png` the serve arrow starts there. | S stays behind the baseline (y ≤ −0.4) and serves from there. |
| B13 | FV | `fv_game_1v1`, `fv_game_2v2`, `fv_game_3v3`, `fv_game_4v4` | S1 | **The opening serve is kicked from mid-court** (1 at y = 12.4 / 12.4 / 11.2 / 11.0, i.e. 6–7 m inside the baseline at 18). | `fv_game_2v2-1.png`, `fv_game_4v4-1.png`: the arrow starts at 1, close to the net. | The server starts at y ≈ 18.7 behind the baseline, with the partner(s) in receive positions. |

### MAJOR

| # | Sport | Drill | Step | Problem | Evidence | Fix |
|---|---|---|---|---|---|---|
| M1 | All 3 (cross-sport) | `tools/drills/narrate.py:501` (`DIR["up"]["en"] = "up the board"`) | various | **English text says "moves up the board" while the far-side player moves *down* the screen.** `_facing()` turns "up" into "toward the opponents" (zh 向前 is right), but English prints the literal "up the board". There are 17 TT, 31 ST and 27 FV clauses like this, e.g. `tt_warm_forehand` S1 "1, 2 move up the board" (2 moves down), `st_serve_deep` S2 "T, D move up the board", `fv_game_2v2` S1 "A, B move up the board". | `tt_warm_forehand-1.png`: 2's ghost is above the figure, so 2 moved down. | Set en/en-GB `"up"` to `"forward"` / `"towards the net"`; `"down"` already reads "back". |
| M2 | TT | `tt_multiball`, `tt_footwork_two_one`, `tt_footwork_falkenberg`, `tt_footwork_side_to_side`, `tt_short_touch`, `tt_kill_wide_forehand`, `tt_serve_third_ball`, `tt_game_serve_receive` | last 1–2 steps | **The ball is left lying where it was received** while the worker shuffles away. The worker's return stroke is never drawn. | `tt_multiball-3.png` and `-4.png` (ball on the floor at 1's old spot); `tt_footwork_falkenberg-3/4.png`; `tt_serve_third_ball-4.png`; `tt_short_touch-3.png` (ball on the table edge) | Add the return leg (1 → zone or feeder) on the step 1 moves, or drop the ball after the last contact. |
| M3 | TT | `tt_loop_*` (4), `tt_kill_*` (3), `tt_short_*` (4), `tt_serve_third_ball`, `tt_multiball` | all | **The trained stroke is never drawn.** The loop, smash, flick, touch and third-ball attack never appear, and the zone is never hit. Loop drills open with 1 hitting from his own hand (a serve) without saying so. Multiball feeds 1 ball in 4 steps and never uses the second zone. | `tt_loop_vs_backspin-1/2.png`: 1 → 2 → 1, then the drill ends. `tt_multiball-2.png`: one feed only. | Extend each ball path by one leg, e.g. `2 (backspin) → 1 loops → zone`. For multiball, alternate C → 1 left, C → 1 right. |
| M4 | TT | `tt_loop_from_backhand` | S2 | **"Loop from the backhand corner", but 1 moves to the centre** (0.78) to take the ball. | `tt_loop_from_backhand-2.png`: the ball and 1 are at the middle of the end line. | Put the ball at about (0.34, 3.0), with 1 pivoting in the backhand corner. |
| M5 | TT | `tt_multiball`, `tt_footwork_two_one`, `tt_footwork_falkenberg` (advanced), `tt_footwork_side_to_side` | text | **Wrong category (warmup).** The notes read "Raise the heart rate… Used every session — it opens the training", which is wrong for multiball and Falkenberg. | `note.en` Purpose/Frequency | Give them a footwork/possession category and its purpose text. |
| M6 | TT | `ttfit_figure_eight` | all | **Named "Repeat sprints"**, with "sprint flat out" over 0.4 m, but the setup describes a figure-eight footwork pattern. | `ttfit_figure_eight-1.png` | Rename it "Figure-eight footwork" and say "move" instead of "sprint". |
| M7 | ST | `st_attack_straight`, `st_attack_cross_court`, `st_attack_the_feint`, `st_cover_spike` | S0–S3 | **No set, and the attack goes into the block.** S starts with the ball in hand, kicks it to B at the net (S1), B returns it to S (S2), and D then walks onto the zone. F never touches the ball, the ball never reaches the target zone, and three touches never happen. | `st_attack_straight-1.png` (arrow from S to B at the net), `-2.png` (ball back at S), `-3.png` (D steps onto the empty zone) | Path F → S (set) → zone. Keep the blocked-ball variant only for `st_cover_spike`, and have F or T play the rebound. |
| M8 | ST | `st_defence_at_the_net`, `st_defence_behind_the_block`, `st_defence_covering_the_block` | S1–S2 | **The defender never defends.** The path is `D → S → B`: blue D gives a free ball, S spikes it first-time into B, and red F (named "feeder") never sets. The three drills differ only in D's starting spot. | `st_defence_behind_the_block-2.png`: the ball ends at B and D walks back. | Path F (set) → S spikes past or off the block → D digs at the landing spot. |
| M9 | ST | `st_feed_receiving_the_serve`, `st_feed_the_high_feed`, `st_feed_the_quick_feed` | S2–S3 | **The feed is never drawn.** The path is `T → R` only. F walks onto the square the text calls "the spot the feed has to be set to for the striker". | `st_feed_the_high_feed-2/3.png`: F stands on the yellow square and the ball stays at R. | Add R → F, then F → square, with S arriving at the square. |
| M10 | ST | `st_receive_left`, `st_receive_right` | S2–S3 | **Name vs board.** "Receive on the left/right", but 1 moves to the centre (3.05) to receive, directly in front of his own tekong. The text "1 plays it deep" is also wrong: the ball goes up to 2 on the square. | `st_receive_left-2.png` (T, 1 and 2 in a column), `-3.png` (ball to 2) | Keep 1 at x ≈ 1.6 / 4.5 and aim the serve there. Change the text to "1 plays it up to 2". |
| M11 | ST | `st_serve_at_the_seam` | S0–S2 | **One receiver means there is no seam.** D stands on the zone and the serve goes straight to him. | `st_serve_at_the_seam-1.png` | Put 2 receivers 2–3 m apart with the zone between them. |
| M12 | ST | `st_game_regu`, `st_tekong_low_drive`, `st_receive_left/right`, `fv_serve_*` | S0–S2 | **Ambiguous or mirrored labels.** Both teams use L/R/T, so S2 reads "L plays it to L". The red L stands on red's *right* (screen-left, team facing down). In `st_tekong_low_drive` the blue "L" stands on blue's right (x = 5.64). Receive drills have two "T"s with "Setup: 3 v 1" for 4 people. Footvolley lists "red: R, R". | `st_game_regu-2.png`, `st_tekong_low_drive-0.png` | Use distinct labels per team (1/2/3 vs A/B/C, or L1/L2), and swap L/R for the side facing down. |
| M13 | ST | `st_game_regu` | S1–S2 | **The serve is aimed at an opponent standing 0.13 m from the net** in the quarter circle. The receiving inside players also hug the net. | `st_game_regu-1.png`: the arrow from T ends at red L on the net. | Receivers deep or mid-court; serve to the back half. |
| M14 | ST | `st_block_at_the_net` | S0–S3 | **The target zone is on the blocker's own court** (4.15, 9.65), "where the ball has to land". The coaching point says a block that drops on your own side is the mistake. | `st_block_at_the_net-0.png`: the zone is beside C on the blue half. | Move the zone to the red half, or relabel it as C's cover spot. |
| M15 | FV | `fv_serve_long_and_fast`, `fv_serve_in_the_corner`, `fv_serve_at_the_seam` | S1–S2 | **The serve misses its own target.** The ball goes to R's standing spot (2.79, 5.37), not the zone (deep/corner/seam). R walks onto the zone in S2, *after* the ball. | `fv_serve_long_and_fast-1.png` (ball at R, zone empty), `-2.png` (R moves to the zone) | Ball [0] goes to the zone, and the nearest R moves there at phase 0. |
| M16 | FV | `fv_combo_quick`, `fv_combo_back`, `fv_combo_second_ball` | S1–S2 | **No combination.** 1's first touch goes over the net to blocker B, and B plays it back. The square ("where the set has to be placed") is occupied by 1. | `fv_combo_quick-1.png`: the arrow runs from 1 to B at the net. | 1 receives, then 1 → square (set), then 2 attacks (or 1 attacks on the second ball). |
| M17 | FV | `fv_finish_the_bicycle_kick`, `fv_finish_the_header`, `fv_finish_the_drop` | S1–S3 | **The finisher never finishes.** 1 shoots from (3.93, 10.80), 1.8 m off the net, through B to D, and D returns to 1. Player 2 only walks to the net. | `fv_finish_the_bicycle_kick-1.png` (arrow passes through B), `fv_finish_the_header-2.png` | 1 sets to 2 at the net; 2 finishes into the zone. |
| M18 | FV | `fv_control_chest_control`, `fv_control_the_shoulder_pass`, `fv_control_the_high_feed`, `fv_receive_chest`, `fv_receive_thigh` | S2 | **The second touch, the point of the drill, is missing.** The note says the control must reach the square; the path ends F → 1. | `fv_control_chest_control-2.png`: 2 stands on the square and the ball stays at 1. | Add 1 → square (2). |
| M19 | FV + ST | `fv_receive_chest`, `fv_control_chest_control`, `fv_control_the_shoulder_pass`, `fv_finish_the_header`, `st_receive_header` | contact step | **Ball drawn at the feet for a chest, shoulder or head touch.** This is the "ball in the upper zone" rule already enforced for volleyball (`_kChestAnchor`). | `fv_control_chest_control-2.png` zoomed: the ball is on the sand at 1's feet. | Give the ball-holder anchor a chest/head tier for these touches in FV and ST. |

### MINOR

| # | Sport | Drill / file | Step | Problem | Evidence | Fix |
|---|---|---|---|---|---|---|
| m1 | TT | `tt_footwork_side_to_side` | text | The Equipment line describes cones, but there are none. Step 2 does not mention 1 moving right. | `tt_footwork_side_to_side-2.png` | Drop the line and narrate the move. |
| m2 | TT | `tt_multiball` | text | "Setup: 1 v 1" for a coach and a worker. | note | Use "coach C + 1". |
| m3 | TT | `tt_game_*` Rules line (`rules_common.POINT_RULES`) | text | "A ball landing inside the lines… a ball on the line is in" is court wording, not table tennis. | note | "Lands on the table (edges count)…" |
| m4 | TT | `table_tennis_court_painter.dart:91-92` | n/a | Net posts are drawn 0.04 m outside the sideline; ITTF says 15.25 cm. | code | Use −0.1525 and 1.6775. |
| m5 | TT | `tt_defence_chop_block` zh | text | "减力挡" is the soft/dead block. A chop block is 侧切挡/切挡. | name | Rename. |
| m6 | TT | `tt_footwork_two_one` | name | The id is two-one footwork, but the name is "in and out", which duplicates `ttfit_in_and_out`. | names | Rename to "2-1 footwork" or rename the id. |
| m7 | ST | `st_game_2v2`, `st_game_3v3`, `st_game_regu` | text | The coaching point "Three touches, three players… Take the block away" is copied from the no-block game onto the 2v2 and full-block games. | note | Write a coaching point for each game. |
| m8 | ST | `stfit_ankle_hops` | S1–S4 | The board moves the player 0.54 m forward and back, while the text says the hops land between the cones and drifting forward is the error. The text also mentions "hurdles" that aren't there. | `stfit_ankle_hops-1.png` | Hop in place; remove the hurdle wording. |
| m9 | ST | `st_game_no_block` | all | A single cone at the centre of the net is supposed to "mark the line". | `st_game_no_block-0.png` | Use a line or zone 1 m off the net. |
| m10 | ST | `st_warm_juggling` | S1–S2 | The ball lands about 0.5 m from the receiver, between the two players. | `st_warm_juggling-1.png` | Snap the ball to the receiver. |
| m11 | ST | th-TH / ms-MY names | text | Thai "เตะกง" for tekong (Thai coaches say ตัวเสิร์ฟ / ตัวชง / ตัวฟาด). ms "Rejaman sunback" is half English. zh/zh-TW `formation_regu` is "Regu (3v3)" untranslated (三人制). | names, translations | Ask a native reviewer. |
| m12 | FV | `fv_serve_long_and_fast` | text | The coaching point "Height is the weapon here, not power" contradicts "long and fast". | note | Write a pace/depth coaching point. |
| m13 | FV | `fv_serve_in_the_corner` zh | text | "角旗区" means corner-flag area; footvolley has no flags. | name | Use "发球 打底角". |
| m14 | FV | `fvfit_sand_sprints` | S0–S2 | The "baseline" cone is 1.4 m inside the baseline, and the jog back runs diagonally inside the court, though the text says outside. | `fvfit_sand_sprints-2.png` | Put the cone on the baseline and route the jog outside the sideline. |
| m15 | FV | `fvfit_sand_lateral` | text | The text says "cones 4 m apart"; on the board they are 2.5–2.7 m apart. | dump | Fix the number or the cones. |
| m16 | FV | `footvolley_court_painter.dart:85-87,159` | n/a | It draws a "centre service mark" dot on each baseline; there is no such marking in footvolley. | code | Remove. |
| m17 | FV | `fv_attack_the_shark_attack` S2–S3, `fv_combo_quick` S2, `fv_defence_the_block` S2 | n/a | The attacker and blocker figures overlap across the net line. Nobody crosses, but it reads like contact over the net. | zoom of `fv_attack_the_shark_attack-2/3.png` | Keep about 0.6 m each side of the net. |
| m18 | Cross | `translations/ms-MY.json` `formation_doubles` | n/a | "Bergu" is a typo for **"Beregu"**. It appears in every sport. | json | Fix the string. |

## (c) Counts

| Sport | BLOCKER | MAJOR | MINOR |
|---|---|---|---|
| Table tennis | 6 (B2–B7) | 5 (M2–M6) | 6 (m1–m6) |
| Sepak takraw | 4 (B8–B11) | 8 (M7–M14) | 5 (m7–m11) |
| Footvolley | 2 (B12–B13) | 4 (M15–M18) | 6 (m12–m17) |
| Cross-sport | 1 (B1, localisation) | 2 (M1 narration, M19 ball height for FV+ST) | 1 (m18) |
| **Total** | **13** | **19** | **18** |

## (d) What I could not verify, and why

- **Rendered PNGs checked.** I opened contact sheets for 20/35 TT, 19/32 ST and 11/30 FV drills, plus full-resolution zooms where it mattered. The remaining drills come from the same family generator as a drill I viewed (identical JSON apart from the target point). I reported them from the JSON plus the viewed sibling, and named them in the family rows (M3, M7–M9, M15–M18).
- **Table tennis serve mechanics.** The board has no height or bounce, so it cannot show an open-palm toss of at least 16 cm, the ball bouncing on the server's own half first, or net height.
- **Sepak takraw serve toss.** The rules I know require the inside player to throw to the tekong. Most ST serve drills instead start with the ball in the tekong's hand, which conflicts with `st_tekong_high_toss`'s own note. I could not confirm whether a current ISTAF or regional variant allows a self-toss, so I did not rate it.
- **Antennas.** I did not confirm whether ISTAF nets carry antennas (the `antenna` marker is offered for sepak takraw).
- **Footvolley.** I took 18 × 9 m as standard; federations differ, and some Brazilian events use 16 × 8. Net height is not modelled.
- **Facing.** I verified facing only on zoomed chest/shoulder/receive drills (correct there). At contact-sheet scale I could not reliably judge front versus back on every figure.
- **Landscape layout.** Not checked. Every PNG is portrait.
