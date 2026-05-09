# Splash Screen Prompts (16 apps)

Run each prompt in ChatGPT (DALL·E 3 / GPT-4o image gen). Output: 1024×1024
PNG. Save each to the indicated path under `assets/icon/`.

After all 16 are in place, run:

```
dart run flutter_native_splash:create
```

(Both `tool/build_sport.sh` and `tool/build_all_ipa.sh` already invoke this
per build, so per-sport apps will pick up their splash automatically.)

---

## Shared style anchors (already baked into every prompt below)

- Format: 1024×1024 square, photorealistic atmospheric cinematic poster.
- References: Nike campaign visual / Apple Sports launch screen / FIFA brand
  poster / Olympic motion identity / Hudl product visuals.
- Composition: three-layer depth — background gradient + floodlight bloom +
  atmospheric haze; mid-canvas faint perspective lines into vanishing point;
  foreground hero motion arc with motion-blur ghost trails.
- Mood: pre-match stadium tension, broadcast-grade, expensive.
- Constraints: deep cinematic palette, white/silver accents, no neon, no
  fluorescent, no rainbow, **no text / no letters / no logos / no UI / no
  athletes / no real photography**.

---

## 0. Hub — multi-sport ecosystem
**Save as:** `assets/icon/splash_logo.png`

```
A 1024×1024 square premium sports brand splash screen poster — photorealistic atmospheric cinematic style, in the visual language of a Nike campaign visual, Apple Sports launch screen, and Olympic motion identity, but for an international multi-sport ecosystem brand.

Background: deep graphite-navy cinematic gradient (#0B1220 at top → #050810 at bottom). Stadium pre-event mood — soft warm-white floodlight bloom in the upper third (suggesting overhead arena lights), faint atmospheric haze across the mid-canvas, subtle radial vignette darkening the corners. Strong three-layer depth (foreground / mid / back).

Mid layer: 4–5 faint white perspective lines receding to a vanishing point in upper-center, hinting at a generic large arena floor seen from a low camera angle. Very subtle, ~5% opacity, evocative not literal.

Foreground: 2–3 OVERLAPPING abstract motion trajectories of different sports — a smooth ball-flight curve, a racket-swing arc, and a sprint streak — crossing through mid-frame in luminous white, each with motion-blur ghost trails behind it, as if multiple sports' moments were captured in a single long exposure.

Mood: professional, expensive, broadcast-grade. The calm-but-charged feeling moments before a major event begins. International sports tech brand.

Palette: deep graphite-navy background, white and silver luminance, faint metallic-blue cool highlight in glow areas. No neon, no fluorescent, no rainbow, no warm-orange.

No text, no letters, no logos, no UI elements, no athletes, no real people. Pure atmospheric branded composition.
```

---

## 1. Soccer
**Save as:** `assets/icon/soccer_splash.png`

```
A 1024×1024 square premium sports brand splash screen poster — photorealistic atmospheric cinematic style, in the visual language of a Nike Football campaign and a Champions League broadcast intro.

Background: deep forest-green cinematic gradient (#0A1F12 at top → #051208 at bottom). Night-game soccer stadium pre-match mood — soft warm-white floodlight bloom in the upper third, faint atmospheric haze across the mid-canvas, subtle radial vignette darkening the corners.

Mid layer: 4–5 faint white perspective lines receding to a vanishing point in upper-center, hinting at a soccer pitch from a low camera angle, with a faint partial center circle and a faint penalty arc visible. ~5% opacity.

Foreground: a soccer ball flight trajectory — a curving parabolic arc — sweeping dynamically across the middle of the frame in luminous white, with motion-blur ghost trails behind it as if the ball was struck and is captured mid-flight in long exposure.

Mood: professional, expensive, broadcast-grade. The hush moments before kickoff in a packed European stadium.

Palette: deep forest-green background, white and silver motion accents. No neon, no fluorescent, no rainbow.

No text, no letters, no logos, no UI elements, no athletes, no people.
```

---

## 2. Basketball
**Save as:** `assets/icon/basketball_splash.png`

```
A 1024×1024 square premium sports brand splash screen poster — photorealistic atmospheric cinematic style, in the visual language of an NBA broadcast intro and Apple Sports launch screen.

Background: deep amber-brown cinematic gradient (#1A0F05 at top → #0E0703 at bottom), evoking dim hardwood-arena lighting before tipoff. Soft warm-white floodlight bloom in the upper third (overhead arena spotlights), faint atmospheric haze mid-canvas, vignette darkening corners.

Mid layer: 4–5 faint white perspective lines receding to a vanishing point in upper-center, hinting at a hardwood basketball court from a low camera angle, with a faint key (paint area) and three-point arc visible. ~5% opacity.

Foreground: a basketball jump-shot trajectory — a high parabolic arc rising and descending — across the mid-frame in luminous white, with motion-blur ghost trails behind it, freezing the ball's flight toward the rim.

Mood: professional, expensive, broadcast-grade. The hush before a Game-7 tipoff.

Palette: deep amber-brown background hinting at hardwood and dim arena, white and silver motion accents. No neon, no fluorescent, no rainbow.

No text, no letters, no logos, no UI, no athletes, no people.
```

---

## 3. Volleyball
**Save as:** `assets/icon/volleyball_splash.png`

```
A 1024×1024 square premium sports brand splash screen poster — photorealistic atmospheric cinematic style, in the visual language of an Olympic volleyball broadcast and an Apple Sports launch screen.

Background: deep indigo-violet cinematic gradient (#11132E at top → #08092A at bottom), evoking an indoor arena before a final. Soft cool-white floodlight bloom in the upper third, faint atmospheric haze mid-canvas, subtle vignette.

Mid layer: 4–5 faint white perspective lines receding to a vanishing point in upper-center, hinting at an indoor volleyball court from a low camera angle, with a horizontal faint silhouette of the net spanning across mid-canvas. ~5% opacity.

Foreground: a volleyball spike trajectory — a sharp diagonal arc crashing downward across mid-frame — in luminous white, with motion-blur ghost trails behind it, freezing the ball mid-spike at peak velocity.

Mood: professional, expensive, broadcast-grade. The crackle of energy in an Olympic gymnasium just before a kill.

Palette: deep indigo-violet background, white and silver motion accents. No neon, no fluorescent, no rainbow.

No text, no letters, no logos, no UI, no athletes, no people.
```

---

## 4. Badminton
**Save as:** `assets/icon/badminton_splash.png`

```
A 1024×1024 square premium sports brand splash screen poster — photorealistic atmospheric cinematic style, in the visual language of a BWF World Tour broadcast and Apple Sports launch screen.

Background: deep teal-cyan cinematic gradient (#042028 at top → #02141A at bottom), evoking a dim indoor badminton arena before a final. Soft cool-white floodlight bloom in the upper third, faint atmospheric haze mid-canvas, vignette.

Mid layer: 4–5 faint white perspective lines receding to a vanishing point in upper-center, hinting at a badminton court from a low angle, with a faint horizontal net silhouette across mid-canvas. ~5% opacity.

Foreground: a shuttlecock flight trajectory — a high steep parabolic arc — across mid-frame in luminous white, with motion-blur ghost trails behind it, freezing the shuttle mid-flight after a clear or smash.

Mood: professional, expensive, broadcast-grade. The taut quiet before a championship rally.

Palette: deep teal-cyan background, white and silver motion accents. No neon, no fluorescent, no rainbow.

No text, no letters, no logos, no UI, no athletes, no people.
```

---

## 5. Tennis
**Save as:** `assets/icon/tennis_splash.png`

```
A 1024×1024 square premium sports brand splash screen poster — photorealistic atmospheric cinematic style, in the visual language of a Grand Slam evening session broadcast and Apple Sports launch screen.

Background: deep emerald-teal cinematic gradient (#0A2218 at top → #051611 at bottom), evoking a stadium court at twilight. Soft warm-white floodlight bloom upper third, faint atmospheric haze mid-canvas, vignette.

Mid layer: 4–5 faint white perspective lines receding to a vanishing point in upper-center, hinting at a tennis court from a low camera angle, with a faint horizontal net silhouette and a hint of baseline. ~5% opacity.

Foreground: a tennis ball baseline-to-baseline trajectory — a long flat parabolic arc — across mid-frame in luminous white, with motion-blur ghost trails behind it, freezing the ball mid-rally after a heavy groundstroke.

Mood: professional, expensive, broadcast-grade. The hush of a packed stadium between points.

Palette: deep emerald-teal background, white and silver motion accents. No neon, no fluorescent, no rainbow.

No text, no letters, no logos, no UI, no athletes, no people.
```

---

## 6. Table Tennis
**Save as:** `assets/icon/tableTennis_splash.png`

```
A 1024×1024 square premium sports brand splash screen poster — photorealistic atmospheric cinematic style, in the visual language of an ITTF World Tour broadcast and Apple Sports launch screen.

Background: deep claret-wine cinematic gradient (#1A0815 at top → #0E040E at bottom), evoking a darkened broadcast arena spotlight on a single table. Soft warm-white floodlight bloom in the upper third, faint atmospheric haze mid-canvas, strong vignette focusing the eye on center.

Mid layer: 4–5 faint white perspective lines receding to a vanishing point in upper-center, hinting at the surface of a table tennis table from a low angle, with a faint center net silhouette. ~5% opacity.

Foreground: a ping-pong ball trajectory — a quick low fast arc — across mid-frame in luminous white, with motion-blur ghost trails behind it, freezing the ball mid-rally at high speed.

Mood: professional, expensive, broadcast-grade. The intimate, lit-stage feel of a televised TT final.

Palette: deep claret-wine background, white and silver motion accents. No neon, no fluorescent, no rainbow.

No text, no letters, no logos, no UI, no athletes, no people.
```

---

## 7. Pickleball
**Save as:** `assets/icon/pickleball_splash.png`

```
A 1024×1024 square premium sports brand splash screen poster — photorealistic atmospheric cinematic style, in the visual language of a PPA Tour broadcast and Apple Sports launch screen.

Background: deep teal-blue cinematic gradient (#062028 at top → #02151E at bottom), evoking an outdoor pickleball arena under floodlights at dusk. Soft cool-white bloom upper third, faint atmospheric haze mid-canvas, vignette.

Mid layer: 4–5 faint white perspective lines receding to a vanishing point upper-center, hinting at a pickleball court from a low angle, with a faint horizontal net silhouette and a faint kitchen line. ~5% opacity.

Foreground: a pickleball trajectory — a low quick parabolic arc — across mid-frame in luminous white, with motion-blur ghost trails behind it, freezing the ball mid-dink-to-drive.

Mood: professional, expensive, broadcast-grade.

Palette: deep teal-blue background, white and silver motion accents. No neon, no fluorescent, no rainbow.

No text, no letters, no logos, no UI, no athletes, no people.
```

---

## 8. Field Hockey
**Save as:** `assets/icon/fieldHockey_splash.png`

```
A 1024×1024 square premium sports brand splash screen poster — photorealistic atmospheric cinematic style, in the visual language of an FIH Pro League broadcast and Apple Sports launch screen.

Background: deep astro-blue cinematic gradient (#082135 at top → #03101E at bottom), evoking a blue-astroturf stadium under floodlights. Soft cool-white bloom upper third, faint atmospheric haze mid-canvas, vignette.

Mid layer: 4–5 faint white perspective lines receding to a vanishing point upper-center, hinting at a field hockey pitch (blue astroturf) from a low angle, with a faint shooting-circle D-arc near top. ~5% opacity.

Foreground: a field hockey ball ground trajectory — a flat low fast curve — sweeping across mid-frame in luminous white, with motion-blur ghost trails behind it, freezing the ball mid-pass after a stick swing.

Mood: professional, expensive, broadcast-grade.

Palette: deep astro-blue background, white and silver motion accents. No neon, no fluorescent, no rainbow.

No text, no letters, no logos, no UI, no athletes, no people.
```

---

## 9. Rugby
**Save as:** `assets/icon/rugby_splash.png`

```
A 1024×1024 square premium sports brand splash screen poster — photorealistic atmospheric cinematic style, in the visual language of a Six Nations / Rugby World Cup broadcast and Apple Sports launch screen.

Background: deep forest cinematic gradient (#082010 at top → #04140A at bottom), evoking a packed rugby stadium at night under floodlights. Soft warm-white bloom upper third, faint atmospheric haze mid-canvas, vignette.

Mid layer: 4–5 faint white perspective lines receding to a vanishing point upper-center, hinting at a rugby pitch from a low angle, with faint H-post silhouettes faintly visible at the far end. ~5% opacity.

Foreground: an oval rugby-ball flight trajectory — a high tumbling parabolic arc, slightly off-axis to suggest the ball's spinning oval shape — across mid-frame in luminous white, with motion-blur ghost trails behind it, freezing the ball mid-flight after a drop kick or long pass.

Mood: professional, expensive, broadcast-grade. The pre-anthem hush of a Test match crowd.

Palette: deep forest background, white and silver motion accents. No neon, no fluorescent, no rainbow.

No text, no letters, no logos, no UI, no athletes, no people.
```

---

## 10. Baseball
**Save as:** `assets/icon/baseball_splash.png`

```
A 1024×1024 square premium sports brand splash screen poster — photorealistic atmospheric cinematic style, in the visual language of an MLB World Series broadcast and Apple Sports launch screen.

Background: deep classic-navy cinematic gradient (#0B1530 at top → #051022 at bottom), evoking a packed ballpark under floodlights at night. Soft warm-white bloom upper third, faint atmospheric haze mid-canvas, vignette.

Mid layer: 4–5 faint white perspective lines receding to a vanishing point upper-center, hinting at a baseball diamond from a low camera angle, with a faint home-plate / first-base silhouette and infield-dirt suggestion. ~5% opacity.

Foreground: a baseball pitch / batted-ball trajectory — a fast slightly curving parabolic arc — across mid-frame in luminous white, with motion-blur ghost trails behind it, freezing the ball at peak velocity.

Mood: professional, expensive, broadcast-grade.

Palette: deep classic-navy background, white and silver motion accents. No neon, no fluorescent, no rainbow.

No text, no letters, no logos, no UI, no athletes, no people.
```

---

## 11. Handball
**Save as:** `assets/icon/handball_splash.png`

```
A 1024×1024 square premium sports brand splash screen poster — photorealistic atmospheric cinematic style, in the visual language of an EHF Champions League broadcast and Apple Sports launch screen.

Background: deep azure cinematic gradient (#0A1A35 at top → #050D20 at bottom), evoking an indoor European handball arena before a final. Soft cool-white bloom upper third, faint atmospheric haze mid-canvas, vignette.

Mid layer: 4–5 faint white perspective lines receding to a vanishing point upper-center, hinting at a handball court from a low angle, with a faint 6-meter arc visible near the top. ~5% opacity.

Foreground: a handball throw trajectory — a strong high parabolic arc descending toward the goal — across mid-frame in luminous white, with motion-blur ghost trails behind it, freezing the ball mid-flight after a jump shot.

Mood: professional, expensive, broadcast-grade.

Palette: deep azure background, white and silver motion accents. No neon, no fluorescent, no rainbow.

No text, no letters, no logos, no UI, no athletes, no people.
```

---

## 12. Water Polo
**Save as:** `assets/icon/waterPolo_splash.png`

```
A 1024×1024 square premium sports brand splash screen poster — photorealistic atmospheric cinematic style, in the visual language of an Olympic water polo broadcast and Apple Sports launch screen.

Background: deep ocean-blue cinematic gradient (#082030 at top → #03121E at bottom), evoking a darkened indoor pool with surface-light reflections. Soft cool-white bloom upper third, faint underwater-style caustic light pattern hints in the haze, vignette.

Mid layer: 4–5 faint white perspective lines receding to a vanishing point upper-center, hinting at a pool surface from a low angle, with a faint lane-marker line and a faint goal silhouette near top. ~5% opacity.

Foreground: a water polo ball trajectory — a wet glistening parabolic arc rising out of and back toward the water — across mid-frame in luminous white, with motion-blur ghost trails behind it and a tiny splash hint at the launch point.

Mood: professional, expensive, broadcast-grade.

Palette: deep ocean-blue background, white and silver motion accents. No neon, no fluorescent, no rainbow.

No text, no letters, no logos, no UI, no athletes, no people.
```

---

## 13. Sepak Takraw
**Save as:** `assets/icon/sepakTakraw_splash.png`

```
A 1024×1024 square premium sports brand splash screen poster — photorealistic atmospheric cinematic style, in the visual language of a Southeast Asian Games broadcast and a premium sports brand visual.

Background: deep teak-warm cinematic gradient (#1A1408 at top → #0E0A04 at bottom), evoking a dim indoor sepak takraw arena with warm spot lighting. Soft warm-white bloom upper third, faint atmospheric haze mid-canvas, vignette.

Mid layer: 4–5 faint white perspective lines receding to a vanishing point upper-center, hinting at a sepak takraw court from a low angle, with a faint horizontal net silhouette across mid-canvas. ~5% opacity.

Foreground: a rattan-ball overhead-kick trajectory — a high steep parabolic arc — across mid-frame in luminous white, with motion-blur ghost trails behind it, freezing the rattan ball mid-flight after an acrobatic bicycle kick.

Mood: professional, expensive, broadcast-grade. Cultural-warm but premium.

Palette: deep teak-warm background, white and silver motion accents. No neon, no fluorescent, no rainbow.

No text, no letters, no logos, no UI, no athletes, no people.
```

---

## 14. Beach Tennis
**Save as:** `assets/icon/beachTennis_splash.png`

```
A 1024×1024 square premium sports brand splash screen poster — photorealistic atmospheric cinematic style, in the visual language of an ITF Beach Tennis Tour broadcast.

Background: deep gold-amber cinematic gradient (#1A1208 at top → #0E0904 at bottom), evoking a beach court at golden-hour twilight, just after sunset. Soft warm-white bloom upper third (the last light of day), faint atmospheric haze mid-canvas suggesting sea-breeze sand mist, vignette.

Mid layer: 4–5 faint white perspective lines receding to a vanishing point upper-center, hinting at a sand court surface from a low angle, with a faint horizontal net silhouette across mid-canvas. ~5% opacity.

Foreground: a beach-tennis ball trajectory — a low fast parabolic arc — across mid-frame in luminous white, with motion-blur ghost trails behind it, freezing the ball mid-rally.

Mood: professional, expensive, broadcast-grade. Premium twilight beach atmosphere.

Palette: deep gold-amber background, white and silver motion accents. No neon, no fluorescent, no rainbow.

No text, no letters, no logos, no UI, no athletes, no people.
```

---

## 15. Footvolley
**Save as:** `assets/icon/footvolley_splash.png`

```
A 1024×1024 square premium sports brand splash screen poster — photorealistic atmospheric cinematic style, in the visual language of a tropical beach-sport broadcast and a premium sports brand visual.

Background: deep tropical-teal cinematic gradient (#082238 at top → #03121E at bottom), evoking a Brazilian beach arena under floodlights at dusk. Soft cool-white bloom upper third with a faint warm hint at the horizon, faint atmospheric haze mid-canvas suggesting ocean-air mist, vignette.

Mid layer: 4–5 faint white perspective lines receding to a vanishing point upper-center, hinting at a sand court from a low angle, with a faint horizontal net silhouette across mid-canvas. ~5% opacity.

Foreground: a footvolley ball trajectory — a high acrobatic parabolic arc, suggestive of a bicycle-kick path — across mid-frame in luminous white, with motion-blur ghost trails behind it, freezing the ball mid-flight after an aerial kick.

Mood: professional, expensive, broadcast-grade. Tropical-night premium atmosphere.

Palette: deep tropical-teal background, white and silver motion accents. No neon, no fluorescent, no rainbow.

No text, no letters, no logos, no UI, no athletes, no people.
```
