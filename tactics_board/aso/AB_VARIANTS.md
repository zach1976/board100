# Promotional Text A/B Variants

> **Live variants for promo-text experiments.** Promo text is the only listing field that doesn't trigger app review, so it's the natural surface for ongoing A/B work.
>
> **Variant A = the copy currently in `fastlane/metadata/<sku>/<locale>/promotional_text.txt`.** Variants B (and beyond) are seeded below — swap them in via fastlane when you want to test, then revert or roll forward based on conversion delta.
>
> See [`ASO_MASTER.md §8`](./ASO_MASTER.md) for the rotation SOP that this experiment surface sits on top of.

---

## How to run an A/B in App Store Connect

App Store Connect doesn't expose a native A/B tester for promo text (only for app icon / screenshots via "Product Page Optimization"). The pragmatic workflow:

1. **Baseline week (variant A live):** record installs/day, page-view → install conversion rate, and tracked-search lift from App Analytics.
2. **Variant week (swap to B):** copy `aso/AB_VARIANTS.md` block B into the relevant `promotional_text.txt`, ship via `fastlane deliver`, leave for 7–14 days.
3. **Decide:** if B's CVR (page-view → install) beats A by ≥10% at p<0.10, promote B to canonical (replace `promotional_text.txt` with B and update Variant A in this file). Otherwise revert to A and either retire B or write Variant C.
4. **Audit trail:** log each swap in `ASO_MASTER §10 changelog` with from→to SHAs and the conversion delta observed.

### Statistical floor

With a typical mid-volume SKU (~500 page views/day), a 10% CVR lift takes ~10 days to clear p<0.10. Don't make calls earlier than 7 days, and don't keep a losing variant in market longer than 14.

### What NOT to A/B simultaneously

One variable per test. If you also change the app icon or screenshot in the same week, the promo lift becomes uninterpretable. Cadence: at most one promo flip per SKU per fortnight.

---

## Seeded variant pairs (for first round of tests)

> **Angle convention:** Variant A is always **event-tied** (current shipped copy, anchored in Q2 2026 calendar). Variant B is **anti-formula** — a different conversion driver (specificity, anti-competitor, persona) — chosen so the test actually measures *which angle works*, not *which wording works*.

### tactics_board (en-US)

**A (event-tied, currently live):**
> World Cup, NBA finals, Roland Garros — one board for 15 sports. Draw, animate, share. Free forever, offline, ad-free.

**B (anti-whiteboard, persona angle):**
> Whiteboard photos shared in the group chat? Replace them in 5 minutes — 15 sports, drag-and-drop, animated playback. Free forever, offline, no account.

### soccer (en-US)

**A (event-tied):**
> World Cup 2026 kicks off June 11 — pre-load every group-stage formation in seconds. Tap Play, watch the press unfold. Free, offline, ad-free.

**B (specificity angle):**
> 4-4-2, 4-3-3, 3-5-2 — every group-stage shape, drawable in 10 seconds. Tap Play to animate the press. Free, offline, no account.

### basketball (en-US)

**A (event-tied):**
> Playoff season is film-room season. Diagram every set, animate every cut, settle every halftime argument. Free, offline, no account.

**B (anti-competitor angle):**
> Stop drawing plays on napkins. Diagram pick-and-rolls, animate cuts, send to the team chat in one tap. Free, offline, ad-free.

### pickleball (en-US)

**A (event-tied):**
> Summer league sign-ups are now. Lock in your stacking, third-shot drops, kitchen plan before opening week. Free, offline, no account.

**B (concrete-skill angle):**
> Stacking. Third-shot drops. Kitchen-line traps. Map every doubles pattern your partner needs to see. Free, offline, no account.

---

## Backlog (variants drafted, awaiting test slot)

| SKU | Variant ID | Angle | Status |
|-----|-----------|-------|--------|
| tactics_board | C | Quantified onboarding ("8 sports, 2 taps, 0 setup") | drafted, untested |
| soccer | C | Coach-pain angle ("Stop yelling at the bench") | drafted, untested |
| basketball | C | NBA-fluency ("Diagram what Spo runs") | drafted, untested |
| volleyball | B | Rotation-confusion angle ("Anyone can read your rotations") | not drafted |
| tennis | B | Doubles-positioning angle ("Tell your partner the plan, not the score") | not drafted |

---

## Locale prioritization for K-round tests

Run A/B on en-US first. **Don't simultaneously test in multiple locales** — Apple's per-locale search algorithms drift independently and noise multiplies. Once an angle wins in en-US, port the winning angle (not the string) to the next highest-volume locale, draft a B variant against it, repeat.

Suggested cadence:
- **en-US** weeks 1–4: angle-A vs angle-B above
- **zh-Hans** weeks 5–8: port winning en-US angle, draft locale-B
- **th** weeks 9–12: same approach
- Other 7 locales: only after the first three converge on a winning angle pattern

---

## Variant naming convention in fastlane

When swapping a variant into production, append a comment line at the top of the moved file (commented or not — fastlane ignores `#` lines on promo text loads):

```
# A/B test live: variant B from AB_VARIANTS.md, swapped 2026-05-21, expecting revert by 2026-06-04
Whiteboard photos shared in the group chat? Replace them in 5 minutes — 15 sports...
```

This makes it obvious in `git blame` what experiment was running when, and prevents "this string is weird, did someone fat-finger?" confusion six weeks later.
