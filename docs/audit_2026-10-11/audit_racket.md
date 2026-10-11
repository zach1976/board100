# Strict audit: tennis, pickleball, beach tennis (drills, boards, courts, text)

I checked every finding below against the rendered PNGs in `tools/board_png/<sport>/` (PNG step N is the board after N phases). JSON coordinates were converted to court metres with the painters' own geometry. The court lines in the renders match: tennis 23.77×10.97 m, service line 6.40 m, singles 8.23 m; pickleball 13.41×6.10 m, NVZ 2.13 m; beach tennis 16×8 m. Contact sheets are in `scratchpad/audit/sheets/<sport>/` and crops are in `p*.png` / `c*.png`.

## (a) Verdict per sport

**Tennis (38 drills): not releasable as is.** The court painter is correct. The drill library breaks tennis rules on the board in about 15 drills:
- The four rally drills ("cross-court FH/BH", "down the line", "figure of eight") all hit the ball centre to centre. A player shuffles to a corner only after the ball has gone.
- Three serve drills walk the server 1.4 m inside the baseline before the serve.
- `tn_defend_block_return` serves into the wrong box. `tn_return_plus_one`'s first ball also goes into the wrong box, if it is a serve; if not, the drill has the server and returner the wrong way round.
- Three plus-one target zones sit in the doubles alley, which is out in a 1v1 drill.
- In `tn_net_drop_volley` the feeder ends up standing on the net.
- In serve-and-volley and the poach drill, the return is struck from an empty spot.

Almost every attacking or finishing drill also stops before the shot it is named after. The feeder then walks onto the target zone instead. The "Equipment" line is in English in 8 locales.

**Pickleball (35 drills): not releasable as is.** The court painter is correct (NVZ 2.13 m). The previously flagged `pb_defend_counter` crossing is fixed, and no player crosses the net any more. But several drills contradict the rules the app teaches:
- "Dink cross-court" and "pull wide" are drawn straight.
- The third-shot family opens with a "serve" that lands in the receivers' kitchen, with the receiving team already at the line.
- The third-shot game opens with a straight serve.
- `pb_serve_return_and_in` labels both players "R", serves from the baseline, and brings the server in instead of the returner.
- The two-bounce drill parks the serving partner at the kitchen.
- Speed-up and put-away drills never draw the attacking shot, and they put the defender inside his own kitchen on the target.
- The `marker_paddle` label reads "ラバー" (ja) and "ไม้ปิงปอง" (th), i.e. table-tennis words.

**Beach tennis (28 drills): not releasable as is.** The court is the right size, but the net is drawn as a faint dashed white line that reads as a centre line. The previously flagged `bt_lob_recover` crossing is fixed, and there are no crossings. But:
- The game rules text says "a second bounce loses it" (zh: 落地两次). In beach tennis any bounce loses the point.
- "King of the court" is drawn as 4v4 with all 8 players on the sand.
- In `bt_lob_over` the target zone is in the drilling team's own half, and the lob is never drawn.
- "Defending the drop/lob" show the drilled player hitting the drop/lob.
- 5 drills give two players the same label (P/P, R/R).
- "Smash jump" is translated as "jump serve" in 6 locales.
- The return-block receiver sprints to the net to take a serve.

The diagonal-rally and serve placements are otherwise sound (beach tennis serves may go anywhere).

## (b) Findings (sorted by severity)

### BLOCKER

| # | Sport | Drill / file | Step | What is wrong | Evidence | Fix |
|---|---|---|---|---|---|---|
| B1 | tennis | tn_rally_crosscourt_fh, tn_rally_crosscourt_bh, tn_rally_down_the_line, tn_rally_figure_eight | 1–2 | The ball always goes centre mark to centre mark (x=5.49 m both ends). The player moves to the corner AFTER the shot, so the ball lands where nobody stands. All four drills draw the same straight line, so the names are contradicted. | `tn_rally_crosscourt_fh-1.png`, `-2.png`; `p1.png` (all four: vertical line down the T) | `tools/drills/tennis.py rally_family`: start 1 at `frm` and 2 at `to` (the corners), hit corner to corner, then recover to the middle. |
| B2 | tennis | tn_serve_second, tn_serve_and_volley, tn_doubles_poach | 1→2 | Step 1 "S moves into position to hit" walks S from 1 m behind the baseline to 1.4 m INSIDE it (y 22.34), carrying the ball. The serve in step 2 is struck from inside the court. | `tn_serve_second-1/2.png`, `tn_serve_and_volley-1/2.png`, `tn_doubles_poach-1/2.png`: S stands well inside the baseline when the arrow leaves | Drop the step-1 walk-in. Serve from (x, 1+BEHIND) and let S follow in after contact. |
| B3 | tennis | tn_defend_block_return | 1 | The serve from 2 (just right of 2's centre mark = deuce) travels straight to 1 on the home ad side (x 3.07). A deuce serve must land in the receiver's deuce box (canvas right). | `p5.png` panel "block_return s1" | Put 1 at the home deuce side (x ≈ 7.9) or move 2 to the ad half. |
| B4 | tennis | tn_return_plus_one | 1 | 1 opens from the ad corner (x 3.07, behind the baseline) and the ball goes straight up the same side to 2 (x 3.73), i.e. into the deuce box. If it is a serve it is in the wrong box. If it isn't, the drilled player is serving rather than returning, which contradicts the name and "Ten serves…" text. | `p2.png` "return_plus_one s1" | Make 2 serve diagonally to 1, then 1 returns and plays the +1. |
| B5 | tennis | tn_serve_plus_one, tn_return_plus_one, tn_inside_out | all | The shaded target zone sits in the doubles alley (x 1.10 m / 9.87 m; singles lines at 1.37 / 9.60). A 1v1 drill's target is out. | `tn_serve_plus_one-0.png` (zone left of singles line), `p2.png` "return_plus_one s3" / "inside_out s3" | Move the targets to x ≈ 1.8 / 9.2 (inside the singles line). |
| B6 | tennis | tn_net_drop_volley | 3 | 2 runs to the net (y=11.88, net=11.885). The figure stands on the net with its feet on 1's side and overlaps 1. | crop `c2.png` of `tn_net_drop_volley-3.png` | Stop 2 at ≥1.5 m from the net (e.g. y 10.3), level with the zone. |
| B7 | tennis | tn_serve_deuce_wide, tn_serve_ad_wide (also _body) | 1 | The serve arrow goes to the receiver standing in the middle behind the baseline. It crosses the service line ~2.6 m from the "wide" zone, and all deuce variants draw the same path (likewise all ad variants). Only the zone moves. | `tn_serve_deuce_wide-1.png`: arrow crosses the service line near the T, zone is at the sideline | Route the serve leg through the zone (bounce), then to R, who moves out wide to meet it. |
| B8 | tennis | tn_serve_and_volley, tn_doubles_poach | 3 | The return starts from the empty serve zone at the service line. R is 2–3 m away (the known "ball starts on empty court" class). | `tn_serve_and_volley` sheet step 3; `tn_doubles_poach` sheet step 3 | Move R onto the serve's landing line at step 2, and start the return from R. |
| B9 | tennis | tn_defend_slice, tn_defend_lob | 1 | In a 1v1 drill, the attack ball is played into the doubles alley (1 runs to x 0.77 / 10.20 m; singles line 1.37 / 9.60). The rally ball is out. | `p5.png` "defend_slice s1", "defend_lob s1" | Clamp to the singles corners (x ≈ 1.8 / 9.2). |
| B10 | pickleball | pb_dink_cross, pb_dink_pull | 1–2 | Same bug as B1: the ball goes straight 1→2 (x 4.27 both). 2 slides wide only after the ball arrives, so "cross-court" and "pulling wide" are never drawn. | `p8.png` "dink_cross s1/s2"; `p9.png` "dink_pull s2" | Start 2 diagonally (cross) or have the dink land wide where 2 moves to. |
| B11 | pickleball | pb_serve_return_and_in | all | Both players are labelled **R**, so the text reads "Step 1: R plays it to R". The server stands on the baseline line (13.01 m, 0.4 m inside). The board then brings the SERVER into the kitchen while the returner backs off, the opposite of the drill and its coaching point ("the return… buy the time you need to walk in behind it"). | `pb_serve_return_and_in` sheet, steps 0–3 | Label the server S. Put S behind the baseline. Make the returner R advance to the kitchen after the return while S stays back (two-bounce rule). |
| B12 | pickleball | pb_third_drop, pb_third_drive (pb_third_fifth similar) | 1 | The point opens with 1 hitting from the centre line into A, who is already standing at the kitchen line. The ball lands inside the opponents' NVZ (y 5.06; kitchen 4.58–6.71). As a serve that is a fault, and the receiving team cannot be at the line for a serve. The third shot (drop/drive) itself is never drawn, and A walks onto the drop target in step 2. | `pb_third_drop` sheet step 1–3 | Open with S serving diagonally from behind the baseline to a returner at the baseline (partner at the kitchen). Return deep, then draw the third shot into the zone. |
| B13 | pickleball | pb_game_third_shot | 1 | The serve goes straight down the left side (x 1.83 → 1.83), not diagonally, and both receivers stand on their baseline. | `p8.png` "game_third_shot s1" | Diagonal serve from behind the right baseline. Returner back, partner at the kitchen. |
| B14 | all three | `assets/drills/{tennis,pickleball,beachTennis}.json` note "Equipment" line | — | The Equipment sentence is untranslated English in ja, ko, th, es, fr, id, ms, vi: tennis 34 of 38 drills, pickleball 40 of 41 Equipment lines, beach tennis 26. Example: 【用具】the shaded zone is where the shot has to land — count only the ones that do。 (zh-CN/zh-TW are translated.) | grep of the JSON; examples in every serve/zone drill | Add those strings to the translation table in `tools/drills/narrate.py` / vocab and regenerate. |
| B15 | beachTennis | bt_game_half_court, bt_game_king_of_the_court, bt_game_full_doubles (Rules line, all locales; zh 「落地两次失分」) | — | "out, into the net, or a **second bounce** loses it". In beach tennis the ball may not bounce at all, so any bounce loses the point. | note text; `tools/drills/beach_tennis.py:112` even says the old wording was removed, but `rules_common` still emits it | Beach-tennis-specific rule: "any ball that touches the sand on your side loses the point". |
| B16 | beachTennis | bt_game_king_of_the_court | 0–1 | Drawn and described as "4 v 4" with 8 players. The waiting pairs 3/4 and C/D stand INSIDE the court at the baseline corners. King of the court is 2v2 with challengers queuing off court. | `p12.png` "king_of_the_court s1" | Draw 2v2 on court, queue the challengers outside the baseline/side, and change Setup to "2 v 2 + waiting pairs". |
| B17 | beachTennis | bt_lob_over | 0–2 | The target zone is in the drilling team's OWN half (5.28, 14.40, behind 2). The lob is never drawn: 1 drives to A at the net, A drives back, then A and B retreat as if they had been lobbed. | `p13.png` "lob_over s1/s2" | Have 1 lob over A/B to a zone near the far baseline, with A/B turning to chase it. |

### MAJOR

| # | Sport | Drill / file | Step | What is wrong | Evidence | Fix |
|---|---|---|---|---|---|---|
| M1 | tennis | tn_serve_plus_one, tn_return_plus_one, tn_inside_out, tn_approach, tn_net_first_volley, tn_net_second_volley, tn_net_overhead, tn_net_drop_volley | last | The shot the drill is named for (+1 ball, volley, overhead, drop volley) is never drawn. The ball ends with 1. In the last step the opponent/feeder walks onto the target zone, so it reads as "hit it to him". In tn_serve_plus_one s3 the ball is left floating where 1 used to be. | `tn_serve_plus_one-3.png`; `p4.png` (net family s3); `p2.png` | Add the final ball leg into the zone. Keep the opponent off the target (or have him start the recovery). |
| M2 | tennis | tn_attack_drop_shot | 1–4 | 2 sprints to the service line in step 1, before the drop is hit. After the drop, 1 moves BACK to the service line, contradicting the coaching point "follow it in". Step 2 text "1 plays it to the net" reads as a netted ball. | `tn_attack_drop_shot` sheet | Keep 2 deep until the drop, move 1 forward after it, and reword to "plays a drop shot short over the net". |
| M3 | tennis | tn_serve_second | 3–4 | "R plays it to the spot" appears twice. The ball goes from the bounce 1.5 m to R, then R's return ends on empty court 3 m in front of S. Holders are all null. | `tn_serve_second` sheet steps 3–4 | One return leg from R to S. |
| M4 | tennis | tn_game_first_to_seven, tn_game_doubles_set, tn_game_half_court, tn_game_approach_only; doubles family (tn_doubles_one_up_one_back, _both_back) | 0–1 | The rules say "Serve changes every two points", but the point starts with 1 standing 1–1.4 m inside the baseline (approach_only: 4.7 m inside). All four doubles drills show the same opponent shape (A back, B up) whatever the name. `tn_game_doubles_set` is called a "set" but plays games to 11. | `p6.png`, `p3.png` | Start the server behind the baseline. Vary the opponents to match each formation. Rename "set" to "game to 11". |
| M5 | tennis | tnfit_spider | 0 | The text puts the cones on the service-line corners, the T and the baseline corners. The board has them 2.1 m in front of the service line (y 16.16 vs 18.29) and 0.7 m inside the baseline. | `p7.png` "spider s0" | Cones at y 18.29 (service line) and 23.77 (baseline). |
| M6 | tennis | rally family (4 drills) | 0 | The two "target" cones sit under the players' feet at the centre marks. The text says they mark targets the rally is aimed at. | `p1.png` (cone only visible at the figure's feet) | Put the cones at the cross-court / line targets. |
| M7 | tennis | tn_approach | 3 | The approach target zone is 1.9 m from the net (approaches go deep), and 2 runs onto it. | `p2.png` "approach s3" | Zone deep in a corner (≈ 2 m from the baseline). |
| M8 | tennis | tn_defend_slice / tn_defend_lob / tn_defend_block_return text | — | "Ball path: 2 → deep court" and the Sequence leave out 1's defensive shot, which the board does draw (step 2). In tn_defend_lob, 2 runs into the alley in step 1 instead of being at the net to be lobbed. | dump + `p5.png` | Narrate 1's shot. Keep 2 at the net for the lob drill. |
| M9 | tennis | `lib/models/sport_type.dart` tennis formations (~l.647) | — | The "Singles" preset puts both players at 0.78/0.22 of the court, about 1.2 m behind the service line (no-man's-land). "Doubles" is commented "Server at baseline right", but the server is at 0.78, 5.2 m inside the baseline. | computed with `fieldRect` | Use y ≈ 1.03 / −0.03 for the server and singles players. |
| M10 | pickleball | pb_two_bounce_rule | 0–3 | In the drill that teaches the two-bounce rule, the serving partner P starts at the kitchen line (it should be the server's partner staying back). The return lands in an empty zone 1.4 m from S. | `pb_two_bounce_rule` sheet | Put P beside S at the baseline. Have S at the return's landing point in step 2. |
| M11 | pickleball | pb_serve_deep_backhand, pb_serve_deep_forehand | 1 | The "deep" serve is drawn landing at R, 2.2 m inside the baseline, short of the deep zone. Both variants draw the identical path (only the zone moves). | `p9.png` | Serve to the zone, with R standing at/behind the baseline to meet it. |
| M12 | pickleball | pb_speedup_shoulder, pb_speedup_hip, pb_speedup_ernie, pb_putaway_overhead, pb_putaway_roll_volley, pb_putaway_atp | 3 | The speed-up/put-away is never drawn. Defender A walks onto the target zone, and for the speed-ups that zone is inside A's own kitchen (y 4.83–5.36 vs line 4.58), so a volleyed reply there is a kitchen fault. | `p9.png` "speedup_shoulder s3", "ernie s3"; `p10.png` | Draw 1's attacking ball into the zone and keep A behind his line. |
| M13 | pickleball | pb_putaway_atp | 2–3 | "Around the post" needs the hitter outside the sideline. 1 moves back to mid-court (3.66, 9.66), and A runs to the post instead. | `p10.png` "putaway_atp s3" | Move 1 wide outside the sideline for the ATP, with the ball going around the post into the zone. |
| M14 | pickleball | pb_attack_lob | 3 | After the offensive lob, both 1 and 2 walk into the kitchen to 0.3 m from the net (1's body overlaps the net). This contradicts the drill's own coaching point. | crop `c3.png` of `pb_attack_lob-3.png` | Keep both at the kitchen line or show them retreating to transition. |
| M15 | pickleball | pb_game_full_doubles, pb_game_dink_only | 0–1 | Games start with all four at the kitchen line and a straight 1→A ball (full doubles has no serve). In step 1 everyone steps 0.5 m INSIDE the kitchen. | `p8.png` | Full doubles: diagonal serve from behind the baseline. Dink game: feet stay behind the line. |
| M16 | pickleball, beachTennis | `assets/translations/ja-JP.json` / `th-TH.json` `marker_paddle` | — | Paddle is "ラバー" (table-tennis rubber) in ja and "ไม้ปิงปอง" (ping-pong bat) in th, yet this marker is offered in the pickleball and beach tennis Add sheets. | translation dump | ja "パドル", th "ไม้พาย/แพดเดิล" (or sport-specific keys). |
| M17 | beachTennis | bt_return_block, bt_return_attacking, bt_serve_flat, bt_serve_sliced, bt_serve_jump | all | Duplicate labels: both teams have a "P", and both receivers are "R". The Setup text reads "red: R, R". | dump; `p12.png` | Unique labels (S/P vs R/Q, or R1/R2). |
| M18 | beachTennis | bt_return_block | 2 | The receiver sprints 4.5 m to the net and receives the serve standing 0.3 m from it (head over the net line). The return itself is not drawn, and the coaching point says "block it deep". | crop `c4.png` of `bt_return_block-2.png` | R meets the serve ~2–3 m from the net, and the return is drawn to the deep zone. |
| M19 | beachTennis | bt_defence_the_drop, bt_defence_the_lob | 1–2 | The names are inverted: A's ball is a flat drive and the DRILLED player 1 hits the drop / the lob. The shared coaching point "Block it back short…" contradicts "1 plays it deep" in the lob drill. | `p13.png` | Have A drop/lob and 1 defend it. Give each drill its own coaching point. |
| M20 | beachTennis | bt_attack_approach, bt_attack_the_drop, bt_attack_cross_court, bt_smash_straight/cross_court/jump | 2–3 | The drilled shot (approach/drop/smash) is never drawn. A then walks onto the target zone. The smashes are fed with a flat drive at chest height, not a lob. | `p14.png` | Feed a lob for the smashes, draw the drilled shot into the zone, and keep A off it. |
| M21 | beachTennis | bt_game_full_doubles, bt_game_half_court | 0–1 | The point (rules: "serve changes every two points") starts with the server 5 m inside the court. Half-court text says the cones sit "on the ends of the centre line", but a beach tennis court has no centre line. The zh text also says "swap partners" for a 1v1 game. | `p13.png` | Serve from behind the baseline. Write "cones on the baselines mark the middle". |
| M22 | beachTennis | bt_smash_jump name (zh-CN, zh-TW, ja, ko, th, vi) | — | "Smash jump" is translated as "jump serve": 扣杀 跳发 / スマッシュ ジャンプサーブ / 스매시 점프 서브 / สแมช กระโดดเสิร์ฟ / Đập bóng nhảy phát bóng. | JSON name | "跳起扣杀 / ジャンプスマッシュ / 점프 스매시 / กระโดดสแมช / Đập bóng bật nhảy". |
| M23 | beachTennis | `lib/painters/beach_tennis_court_painter.dart` | — | The net is a thin dashed white line with 0.25 m tabs. It reads as a centre line, not the 1.70 m net, and is inconsistent with the yellow mesh net in tennis and pickleball. The net-crossing reviews depend on seeing it. | every BT PNG | Use the shared `drawNetMesh` + net band like the tennis painter. |
| M24 | beachTennis | bt_game_king_of_the_court note (8 locales) | — | The "How it continues" line is English in ja, ko, th, es, fr, id, ms, vi ("The winners of each point stay on the king's side…"). | grep | Translate. |

### MINOR

| # | Sport | Drill / file | What | Fix |
|---|---|---|---|---|
| m1 | tennis | `tennis_court_painter.dart` | Net posts are drawn on the doubles sideline (ITF: 0.914 m outside). The centre mark is 0.2 m long (ITF: 0.10 m). | Cosmetic. |
| m2 | tennis | tn_warm_baseline_feed | A "baseline" feed with both players 1.4 m inside the baseline. | Move them behind the line. |
| m3 | tennis | tn_game_half_court | The cones sit 1.6 m inside the service lines, not at the "ends of the centre line", and do not extend to the baselines. | Cones on the centre marks at both baselines. |
| m4 | tennis | serve family (step 2) | After returning, R walks diagonally toward the alley/zone. | Recover to the middle. |
| m5 | all | facings | Several players stand side-on, looking at a partner instead of the net at step 0: e.g. tn_doubles_one_up_one_back "2", tn_defend_slice "1", pb_attack_lob "2" (crop `c5.png`), pb speed-up "2", bt serve "P", bt smash "2". | Face the net/ball. |
| m6 | pickleball | `sport_type.dart` pickleball formations | Doubles sits 0.8 m behind the kitchen line and singles 1.2 m behind it (transition zone). | 0.68/0.32 for kitchen, ~1.03 for baseline. |
| m7 | pickleball | pb_speedup_ernie s3 | After 1 jumps to the post, the ball is left lying on court at its old spot. | Draw the Ernie volley. |
| m8 | pickleball | pb_defend_counter s2 | 1 and 2 nearly overlap (0.6 m). | Space them out. |
| m9 | pickleball | serve drills | No mention of the underhand / below-the-waist serve rule in any serve note. | Add it to the coaching text. |
| m10 | pickleball | pbfit_kitchen_shuffle | Text says "cones at both sidelines", but they are 1.1 m inside. | Align the text or the cones. |
| m11 | beachTennis | `beach_tennis_court_painter.dart` | "Serve-target dots" at the baseline centres are not an ITF marking. The singles court (4.5 m) is not offered. A blue surface option exists for a sand sport. | Remove the dots and consider the singles lines. |
| m12 | beachTennis | btfit_sand_lateral | Text says the cones are "4 m apart"; they are 2.4 m apart on the board. | Fix the text. |
| m13 | beachTennis | btfit_sand_sprints | "Jog back outside the court", but the player jogs back inside it. | Route the return outside. |
| m14 | beachTennis | bt_serve_flat (zh 平抽对抗), bt_serve_sliced (zh 劈吊) | Odd terminology. | 平击发球 / 切削发球. |
| m15 | all | `translations/ja-JP.json`, `th-TH.json` `learn_ball_2` | The tutorial string is untranslated English (global, not sport-specific). | Translate. |

## (c) Counts per severity

| Sport | BLOCKER | MAJOR | MINOR |
|---|---|---|---|
| Tennis | 10 (B1–B9, B14) | 9 (M1–M9) | 5 (m1–m5) |
| Pickleball | 5 (B10–B14) | 7 (M10–M16) | 6 (m5–m10) |
| Beach tennis | 4 (B14–B17) | 9 (M16–M24) | 6 (m5, m11–m15) |

B14 (untranslated Equipment line), M16 (paddle label), m5 (facings) and m15 (`learn_ball_2`) are shared and counted under each sport they affect.

Three root causes account for most findings, so they can be fixed once in the generators:
1. **Rally leg drawn before the move.** The receiver's move is scheduled after the ball lands, so the ball goes to his previous spot (B1, B10). This is in the rally/dink generators.
2. **Drills stop one ball early.** Feed → reply is drawn, the named shot never is, and the opponent's last move lands on the zone (M1, M12, M20, B12).
3. **"S moves into position to hit"** walks a serving player inside the baseline (B2).

## (d) Not verified, and why

- **Underhand serve, contact below the waist, the paddle arc (pickleball); the beach tennis serve toss rule; foot faults.** These are stroke mechanics that a top-down board cannot show. I only checked whether the text mentions them (it doesn't, m9).
- **Facing.** I judged it only from sprite pose at the PNG resolution. I did not run `tools/facing_audit.py` against these drills, so subtle back-to-ball cases at small angles may be missed.
- **Beach tennis rules.** These are from my knowledge of the ITF Beach Tennis rules (16×8 m doubles, 4.5 m singles, net 1.70 m, no bounce, serve anywhere in the opponents' court, no lets on serve). I did not fetch the current ITF rulebook. I did not audit scoring details in the "How it continues" lines (e.g. "serve alternates every two points") beyond the bounce rule.
- **Translations.** I did not judge the quality of es, fr, id, ms or vi beyond detecting English left in them. CJK/Thai terminology was spot-checked on drill names and the sport markers only, not every note sentence.
- **iPad / landscape layouts and the half-court layout.** I did not check them; the renders are 402×730 full-court only.
