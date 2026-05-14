# Tactics Board — ASO Strategy Master

> **Strategic source of truth**: positioning, naming, copy patterns, locale tone-of-voice, screenshot framework, keyword research.
>
> **Published copy lives in `fastlane/metadata/<sku>/<locale>/`** — 16 SKUs × 11 locales = **176 listings**. This doc tells you *how* to write; fastlane is *what shipped*.
>
> Last refresh: 2026-05-14

---

## 1. SKU Inventory (16 apps)

| # | SKU folder | App Name (EN) | EN Subtitle | L1 Hook (EN) |
|---|-----------|---------------|-------------|--------------|
| 0 | `tactics_board` | Tactics Board - Coach Playbook | 15 Sports. One Tactical Board. | Your clipboard, upgraded to a full coaching brain. |
| 1 | `soccer` | Soccer Board - Tactics & Plays | Draw a Play. Watch It Run. | Draw the goal before it happens. |
| 2 | `basketball` | Basketball Board - Play Maker | Draw It. Run It. Score. | Run the play before tip-off. |
| 3 | `volleyball` | Volleyball Board - Tactics | Rotations, Demystified. | Rotate right, win the rally. |
| 4 | `badminton` | Badminton Board - Tactics | Win Doubles Without Words. | Move them. Smash to finish. |
| 5 | `tennis` | Tennis Board - Tactics | See the Point Before You Play. | Win the point on paper first. |
| 6 | `tableTennis` | Table Tennis Board - Tactics | Read the Spin. Plan the Rally. | Three shots ahead. |
| 7 | `pickleball` | Pickleball Board - Tactics | Win the Kitchen. Win the Game. | Own the kitchen line. |
| 8 | `baseball` | Baseball Board - Tactics | Every Pitch Has a Plan. | Plan before the pitch. |
| 9 | `handball` | Handball Board - Tactics | Draw the Break. Read the Wing. | Break the 6-meter line. |
| 10 | `rugby` | Rugby Board - Tactics | Win the Set Piece. Win Match. | Win at the gain line. |
| 11 | `fieldHockey` | Field Hockey Board - Tactics | Penalty Corners, Solved. | Penalty corners, drawn easy. |
| 12 | `waterPolo` | Water Polo Board - Tactics | Plan the 6-on-5. Win the Pool. | Anyone can plan a 6-on-5. |
| 13 | `sepakTakraw` | Sepak Takraw - Tactics | Tekong Serves. Striker Wins. | Own the Regu rotation. |
| 14 | `beachTennis` | Beach Tennis - Tactics | Stack. Smash. Win the Sand. | Doubles on sand — anyone can plan it. |
| 15 | `footvolley` | Footvolley Board - Tactics | Plan the Touch. Own the Sand. | Brazilian feet. Win on sand. |

> tactics_board (#0) is the multi-sport flagship. SKUs 1–15 are single-sport siblings sharing the same canvas + animation engine.

---

## 2. Positioning Framework

**Target user (in priority order):**
1. **Youth / amateur head coaches** — primary buyer of intent. Pre-game prep, halftime adjustments.
2. **Assistant coaches / analysts** — need a faster clipboard than whiteboard photos.
3. **Players (esp. doubles racket sports + team captains)** — peer-to-peer tactical comms.
4. **PE teachers / camp instructors** — bulk teaching aid.

**Core value props (rank-ordered by conversion impact):**
1. **Draw → Play → Share** in one screen — kills the whiteboard-photo workflow.
2. **Animation playback** — differentiation vs every static-diagram competitor.
3. **15 sports in 1 app** (or per-sport SKU for SEO targeting).
4. **Pre-loaded formations** — zero-setup onboarding.
5. **Free forever, offline, no account, no ads** — the trust-signal stack (front-loaded since `d3cb878`).

**What we deliberately don't promise:** team management, video analysis, statistics, cloud-only features. Staying narrow keeps the canvas focused.

---

## 3. Copy Patterns (templates, not copies)

Every published `description.txt` follows the same skeleton — adapt per sport, never invent a new structure.

```
<L1: 5-9 word concrete tactical promise>

<L3: sport-specific tagline naming the canvas + audience + scope>

Free forever · Works offline · No ads · No account     ← trust line (en-US, added in d3cb878)

DRAW IT. PLAY IT. SHARE IT.

- 4 capability bullets (drag / draw / animate / share)

FORMATIONS, READY TO GO

<sport-specific formation list>
<one-line CTA: "Apply with one tap. Customize from there.">

BUILT FOR THE SIDELINE

- 5 trust bullets (offline / dark theme / undo / AirPlay / free)

11 LANGUAGES
<language list with current locale first>

<social proof line: "Trusted by youth coaches and clubs across 50+ leagues...">

<closing manifesto line: "if you can coach it, you can draw it.">
```

**Subtitle pattern (≤30 chars across all locales):** verb-led tactical hook, no "<sport> plans, animated, free" template (banned since `c4b5710`). Two short clauses separated by "." or "·" beats one long clause.

**Promotional text (170 chars, no review required):** time-bounded hook — season opener, tournament tie-in, "new in this update". Refresh quarterly minimum. This is the **only field** ASO operators can A/B without re-submission.

---

## 4. Locale Tone-of-Voice

| Locale | Tone | Hook style | Trust appeal |
|--------|------|-----------|--------------|
| en-US | Direct, imperative, coach-jargon-fluent | "Draw it. Run it. Score." | Free / Offline / No ads |
| es-ES | Warm-imperative, club-football-fluent | "Dibuja la jugada. Vívela." | Gratis / Sin conexión |
| fr-FR | Tactical-cerebral, club-football | "Voyez le point avant de jouer." | Gratuit / Hors-ligne |
| ja | Polished, slightly formal, technical | "戦術を、描いて、動かす。" | 完全無料 / オフライン |
| ko | Energetic, coach-as-teammate | "작전을 그려서 보여줘." | 무료 / 오프라인 |
| zh-Hans | 量化具体，钩子直白，本地球类术语 | "教练桌上的第二块大脑" | 完全免费 / 离线可用 / 无广告 |
| zh-Hant | 同 zh-Hans 调性，繁体术语（羽球/桌球） | "教練桌上的第二顆大腦" | 完全免費 / 離線可用 |
| th | **Sabai 调性** + emoji: ใครๆ ก็... / สบายๆ / ไม่ต้อง... | "ใครๆ ก็วางเกมได้ 🏖️" | ฟรี · ออฟไลน์ · ไม่มีโฆษณา |
| vi | Friendly-imperative, futsal-fluent | "Vẽ pha bóng trước khi chơi." | Miễn phí / Ngoại tuyến |
| id, ms | Casual-direct, futsal/badminton fluent | "Gambar taktik, mainkan." | Gratis / Tanpa internet |

**Cross-locale rule:** never machine-translate hooks. Each locale's L1 + subtitle must be re-conceived from positioning, not from the EN version.

---

## 5. Keyword Strategy (100-char field)

**Slot allocation per SKU (rule of thumb):**
- 35 chars: sport-name variants (e.g., `soccer,football,futsal,fútbol`)
- 25 chars: tactical verbs (`tactics,play,formation,strategy,drill`)
- 20 chars: persona (`coach,player,clipboard,whiteboard`)
- 20 chars: court/feature (`field,court,offline,animation`)

**Per-locale localization:** App Store keyword fields are per-locale, but Apple indexes across all locales the device matches. For TH/JA/KO, include both transliterated English (`tactics`) and native script (`戦術` / `전술` / `แท็คติค`) for max coverage.

**Forbidden:** competitor brand names, generic "free/best/top" filler, plurals duplicating singular (Apple's indexer normalizes).

---

## 6. Screenshot Framework

### Design spec

| Param | Value |
|-------|-------|
| iPhone 6.7" | 1290 × 2796 px |
| iPhone 6.5" | 1242 × 2688 px |
| iPhone 5.5" | 1242 × 2208 px |
| iPad 12.9" | 2048 × 2732 px |
| Count | 6–8 (first 3 are 80% of conversion lift) |
| Bg | #0D0D1A (matches in-app dark theme) |
| Caption | #FFFFFF main, #FFD600 accent |
| Font | SF Pro Display Bold |
| Layout | Top 1/3 = caption, bottom 2/3 = device mockup |

### Universal 6-shot order

| # | Subject | Job-to-do |
|---|---------|-----------|
| 1 | Full formation on the field | "This is what a tactical board looks like" — first impression |
| 2 | Drawing in action — arrows / runs / zones | Demonstrate interactivity |
| 3 | Animation playback with motion trails | The differentiation moment |
| 4 | Formation picker panel | "Open-the-box-and-go" reassurance |
| 5 | Share / export modal | Implied social use, viral surface |
| 6 | Language picker / settings | International trust, accessibility |

**Caption style:** benefit > feature. ❌ "Tap to draw arrows." ✅ "Show every run before it happens."

Localized PNGs live in `aso/screenshots_localized/`; raw source captures in `aso/screenshots_raw/` (iPhone) and `aso/screenshots_raw_ipad/` (iPad).

---

## 7. Per-Sport Positioning (one-paragraph each)

> Full descriptions are in `fastlane/metadata/<sku>/<locale>/description.txt`. The paragraphs below capture *why this sport gets its own SKU* and what its primary tactical hook is — the seed every locale's copy grows from.

- **soccer** — biggest TAM. Hook = formation-and-set-piece planning from futsal to 11v11. Audience skews European/LatAm club + US youth soccer.
- **basketball** — NBA-fluency table-stakes. Hook = pick-and-roll / motion offense / 3-2 zone diagramming. Heavy keyword competition; lean into "NBA-accurate court" for trust.
- **volleyball** — rotation confusion is the #1 user pain. Hook = "rotations, demystified". Targets HS/club coaches mostly.
- **badminton** — doubles-dominant market (SEA, China, Korea, Japan, Denmark). Hook = "win doubles without words". Front-back vs side-by-side is the visual.
- **tennis** — singles/doubles split; doubles positioning is the under-served niche. Hook = "see the point before you play".
- **tableTennis** — spin + serve sequencing is the differentiator vs other racket SKUs. Hook = "read the spin, plan the rally".
- **pickleball** — fastest-growing sport globally. Hook = "win the kitchen". Heavy doubles weight; stacking is the killer use case.
- **baseball** — defensive shift + pitcher-cover positioning. Niche but high-intent. Targets US + JP + KR + LatAm.
- **handball** — Europe-heavy (DE / ES / FR / nordics). Hook = "break the 6-meter line". 6-0 vs 5-1 defenses are the must-have formations.
- **rugby** — set-piece-driven sport, perfect for the canvas. Hook = "win at the gain line". 7s / 10s / 15s coverage. Target UK / FR / ZA / NZ / AU.
- **fieldHockey** — penalty corners are *the* match-deciding moment. Hook = "PC drawn easy". Target IN / NL / GB / AU / PK.
- **waterPolo** — 6-on-5 man-up is the canonical play. Hook = "anyone can plan a 6-on-5". Niche but loyal — HU / IT / ES / SRB / US.
- **sepakTakraw** — SEA-native, heavily TH/MY/ID skew. Hook = Tekong serve + striker kill. **Treat as cultural-pride positioning**, not generic "tactical board".
- **beachTennis** — Mediterranean + LatAm beach culture. Hook = "stack and smash". Doubles-only sport, simpler court → cleaner screenshots.
- **footvolley** — Brazil-native. Hook = "Brazilian feet on sand". Tight niche, brand-affinity play more than search-volume play.

---

## 8. Operational Notes

- **Apple subtitle limit:** 30 characters (counted per-codepoint, including combining marks — Thai/Hindi watch out).
- **Apple keyword limit:** 100 characters per locale, no spaces around commas (Apple strips them, costing chars).
- **Promotional text:** 170 chars, doesn't require app review — **rotate quarterly** for seasonal hooks.
- **Description:** ~4000 chars technical max, but iOS truncates listing preview at ~250 chars. **Front-load** the hook + sport tagline + trust line in the first three lines (current pattern since `d3cb878`).
- **Review-triggering fields:** name, subtitle, description, screenshots. **Non-review fields:** promotional text, app rating, keywords, in-app events.

---

## 9. Recent ASO commits (changelog)

| SHA | Field | What |
|-----|-------|------|
| `c4b5710` | EN subtitle × 16, descriptions | Replace "<sport> plays, animated. Free." template with benefit hooks; strip "<App> — <App>" duplication |
| `c6ba761` | TH (tactics_board + 3 SKUs) | 7→15 sports data fix; sabai L1s for beachTennis/fieldHockey/waterPolo |
| `90890db` | EN/ES/FR/zh-Hans/zh-Hant tactics_board description | Cross-locale 7→15 sports + complete formation list (added baseball/handball/rugby/fieldHockey/waterPolo/sepakTakraw/beachTennis/footvolley) |
| `899f816` | TH subtitle × 15 single-sport | Drop "แผน<sport> แอนิเมชัน ฟรี" template, replace with tactical hooks (≤30 chars) |
| `d3cb878` | EN description × 16 | Front-load `Free forever · Works offline · No ads · No account` trust line at L5 |

---

## Appendix A: Quick-access fastlane paths

```
tactics_board/fastlane/metadata/<sku>/<locale>/
  ├─ name.txt               (≤30 chars, app name)
  ├─ subtitle.txt           (≤30 chars)
  ├─ description.txt        (≤4000 chars; iOS preview truncates ~250)
  ├─ keywords.txt           (≤100 chars, comma-separated, no spaces)
  ├─ promotional_text.txt   (≤170 chars; not review-gated)
  └─ release_notes.txt      (per-version "What's New")
```

Locale codes in use: `en-US, es-ES, fr-FR, id, ja, ko, ms, th, vi, zh-Hans, zh-Hant`.
