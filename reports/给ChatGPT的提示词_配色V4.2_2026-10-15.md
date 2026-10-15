# Sports Tactics Board Series — Colour System V4.2 Revision Request

## Your role

You are a senior sports UI/UX designer, colour-system architect and accessibility engineer. You are revising **V4.1**, a light-theme colour system for 16 apps: 15 single-sport tactics boards plus one multi-sport Hub. V4.1 was measured programmatically. The results are below. Your job is to produce **V4.2**, which fixes the measured problems with the **smallest possible changes** and keeps each sport recognisable.

This is a revision, not a redesign. Do not touch anything that is not listed as a problem.

---

## 1. Fixed foundation — do not change

| Token | HEX |
|---|---|
| pageBackground | #F3F0E8 |
| appBackground | #F6F4EE |
| surface | #FFFFFF |
| elevatedSurface | #EEF3F8 |
| secondarySurface | #F7F9FC |
| textPrimary | #16212E |
| decorativeBorder | #D8E0E8 |
| disabledSurface | #C8D0D9 |

Every app uses Background #F6F4EE, Surface #FFFFFF and Elevated #EEF3F8.

---

## 2. Current V4.1 values

### Semantic colours

| Role | HEX |
|---|---|
| success | #147D50 |
| warning | #8B5900 |
| error | #B83240 |
| information | #155E9E |
| focus | #4A345C |
| textSecondary | #526071 |
| textTertiary | #586577 |
| inputBorder | #778494 |

### Brand colours

| App | Primary | Secondary | Button text |
|---|---|---|---|
| Volleyball 排球 | #2852B5 | #7DB7FF | #FFFFFF |
| Soccer 足球 | #257D42 | #8BCF67 | #FFFFFF |
| Basketball 篮球 | #D06B25 | #FFB566 | #16212E |
| Field Hockey 曲棍球 | #0873A4 | #E3C86C | #FFFFFF |
| Tennis 网球 | #C7D93B | #6E95DD | #16212E |
| Rugby 橄榄球 | #B98056 | #6FA570 | #16212E |
| Badminton 羽毛球 | #087E78 | #D8B688 | #FFFFFF |
| Table Tennis 乒乓球 | #594695 | #E15C56 | #FFFFFF |
| Pickleball 匹克球 | #159C85 | #D7C96E | #16212E |
| Baseball 棒球 | #883C66 | #C98E57 | #FFFFFF |
| Handball 手球 | #7385C3 | #E59B55 | #16212E |
| Water Polo 水球 | #227AA7 | #5E8FC8 | #FFFFFF |
| Sepak Takraw 藤球 | #AC862C | #67A56C | #16212E |
| Beach Tennis 沙滩网球 | #E1C79B | #CFA087 | #16212E |
| Footvolley 足排球 | #A64E29 | #39B9C8 | #FFFFFF |
| Hub 战术板合集 | #344D63 | #B49A6A | #FFFFFF |

---

## 3. Measured results of V4.1

The measurements use the WCAG 2.1 contrast formula with sRGB linearisation, truncated and never rounded up. Colour distance is ΔE in OKLab: below 0.08 is high risk, 0.08 to 0.12 needs review, above 0.12 is lower risk.

**Contrast: no failures.** All derived text and stroke tokens pass.

### Problem A — high-risk collisions between sports

| Pair | ΔE_OK |
|---|---|
| Field Hockey #0873A4 vs Water Polo #227AA7 | **0.024**. Indistinguishable as 60 pt App Store icons. V4.1 made Water Polo darker, which caused this. |
| Rugby #B98056 vs Sepak Takraw #AC862C | 0.055 |
| Basketball #D06B25 vs Rugby #B98056 | 0.061. Rugby sits between two warm browns. |
| Soccer #257D42 vs Badminton #087E78 | 0.078 |

### Problem B — brand colours collide with semantic colours

| Pair | ΔE_OK |
|---|---|
| Soccer #257D42 vs success #147D50 | **0.019** |
| Volleyball #2852B5 vs information #155E9E | 0.053 |
| Field Hockey #0873A4 vs information #155E9E | 0.060 |
| Badminton #087E78 vs success #147D50 | 0.060 |
| Footvolley #A64E29 vs warning #8B5900 | 0.066 |
| Footvolley #A64E29 vs error #B83240 | 0.071 |
| Hub #344D63 vs focus #4A345C | 0.078 |

**Root cause.** success sits among the green sports (soccer, badminton) and information sits among the blue sports (volleyball, field hockey). An automated search found that Field Hockey cannot escape information anywhere in the blue family (hue ±30°, lightness ±0.15). Fixing these one sport at a time would move four sports. Moving two semantic colours may fix more with less.

### Problem C — pairs to review (0.08 to 0.12)

| Pair | ΔE_OK |
|---|---|
| Volleyball vs Table Tennis | 0.081 |
| Badminton vs Water Polo | 0.082 |
| Basketball vs Sepak Takraw | 0.085 |
| Field Hockey vs Badminton | 0.087 |
| Table Tennis vs information | 0.090 |
| Pickleball vs Badminton | 0.091 |
| Handball vs Water Polo | 0.099 |
| Volleyball vs Field Hockey | 0.099 |
| Hub vs Table Tennis | 0.107 |
| Baseball vs error | 0.109 |
| Footvolley vs Basketball | 0.111 |

### Problem D — borderline contrast (passes, but below the 5:1 internal target)

| Item | Contrast |
|---|---|
| Basketball button text #16212E on #D06B25 | 4.50 |
| Handball #16212E on #7385C3 | 4.54 |
| Pickleball #16212E on #159C85 | 4.74 |
| Water Polo #FFFFFF on #227AA7 | 4.76 |
| Sepak Takraw #16212E on #AC862C | 4.80 |
| Rugby #16212E on #B98056 | 4.86 |
| Badminton #FFFFFF on #087E78 | 4.92 |
| inputBorder #778494 | 3.34 (target 3.5) |
| success used as text | 4.52 |

A dedicated button fill that differs from the brand colour by less than 0.03 ΔE_OK would reach 5:1 for each of these. For example, Basketball #DA7430 reaches 5.05.

### Problem E — text hierarchy

textSecondary #526071 and textTertiary #586577 are almost the same darkness, so there is no visible hierarchy between them.

---

## 4. What I need from you

1. **Decide the strategy for Problem B first.** Choose one and justify it:
   - **(a)** Move the semantic colours: success, information, and if needed warning and error, plus focus vs Hub, to hues that no sport uses, while keeping their conventional meaning recognisable.
   - **(b)** Move the sports.
   - **(c)** A mix of both.

   Explain what each option costs.
2. **Fix every Problem A pair** by moving only one side of each pair. Say which side moves and why, based on sport authenticity, for example "Water Polo gives way because V4.1 changed it".
3. **Propose button fills or foregrounds for Problem D**, or accept the borderline values with a reason.
4. **Fix Problem E** with a visible step between textSecondary and textTertiary. Both must keep at least 4.5:1 on #FFFFFF, #F6F4EE, #EEF3F8 and #F3F0E8.
5. **Keep every unchanged colour exactly as it is.**

### Hard constraints for every new value

- Each sport must stay recognisable as itself, based on real surfaces, balls or equipment. No arbitrary colours just to increase distance.
- **Brand vs brand:** ΔE_OK at least 0.10 for every pair of the 16 primaries, ideally 0.12.
- **Brand vs semantic:** ΔE_OK at least 0.10.
- **Hub vs focus:** at least 0.12.
- **Button text on its fill:** at least 4.5:1, target 5:1.
- **Semantic colours used as text:** at least 4.5:1 on all four light backgrounds.
- **inputBorder:** at least 3:1, target 3.5:1.
- Light theme only: no dark or near-black backgrounds, no neon colours.

### Self-check

Before answering, compute ΔE_OK and WCAG contrast yourself for every value you change, and show the numbers. If you cannot compute them reliably, say so; do not guess. I will re-run my own validator on your output.

---

## 5. Output format

Reply in this order:

1. **Strategy** — one paragraph explaining your choice for Problem B.
2. **Change table** — only the tokens you changed: token, old HEX, new HEX, reason, new nearest ΔE_OK neighbour, new contrast figures.
3. **Complete V4.2 JSON** — the full system, including unchanged values, in exactly this structure:

```json
{
  "version": "4.2",
  "shared": { "textSecondary": "#…", "textTertiary": "#…", "inputBorder": "#…" },
  "semantic": { "success": "#…", "warning": "#…", "error": "#…", "information": "#…", "focus": "#…" },
  "apps": [
    { "id": "volleyball", "primary": "#…", "secondary": "#…", "buttonForeground": "#…", "buttonFill": "#… or null" }
  ]
}
```

   List all 16 apps in this order: volleyball, soccer, basketball, fieldHockey, tennis, rugby, badminton, tableTennis, pickleball, baseball, handball, waterPolo, sepakTakraw, beachTennis, footvolley, hub. `buttonFill` is null when the button uses the brand primary itself.
4. **Open risks** — anything you could not resolve, and the trade-off you accepted.
