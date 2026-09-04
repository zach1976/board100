# Splash artwork — house style and prompts

> The same prompts are built into `tools/splash_preview.html` with copy
> buttons and a slot-filler for new sports — `open tools/splash_preview.html`.
> Keep the two in step if you reword anything.

The 15 sport apps share one launch-screen look. Anything new has to match it,
or that app's launch reads as a different product. This file records the style
and the prompt that produces it, so the next sport doesn't need reverse
engineering.

## The house style (derived from the shipped 15)

| | |
|---|---|
| Canvas | **853 × 1844 px** portrait (aspect 0.463 ≈ 9:19.5) |
| Ground | near-black, very dark navy/charcoal; no bright areas outside the light |
| Light | ONE hard light source in the upper third (stadium floodlight / spotlight), visible light rays cutting through the dark |
| Hero | the sport's ball / implement, photoreal 3D render, **centred horizontally**, sitting in the lower-middle on the playing surface |
| Accent | a glowing neon trail arcing around the hero — one saturated colour per sport (soccer = green, beach tennis = electric blue, water polo = cyan) |
| Surface | the real playing surface, lit only near the hero (grass, sand, wood, water) |
| Detail | fine particles kicked up around the impact point (sand grains, dust, spray) |
| Empty | bottom ~15% and top ~20% stay near-black — the phone's clock/notch sit there |
| Text | **none.** No logos, no words, no watermark |

Why the shape matters: the launch screen uses `ios_content_mode:
scaleAspectFill`, so anything not close to 0.463 gets scaled to cover the
screen and loses its edges. Footvolley shipped a 1024-square and lost most of
the court — see `verify_app_assets.py`, which now fails that combination.

## Prompt — footvolley (the one currently missing)

Paste into ChatGPT (GPT Image / DALL·E) or any image model. Ask for **portrait
9:19.5**; if the model only offers 2:3 or 9:16, take the tallest option and
crop with `tools/make_splash.py`.

```
A dramatic, photorealistic 3D product render for a mobile app launch screen,
vertical portrait composition, aspect ratio 9:19.5.

Scene: a beach footvolley court at night. A single stadium floodlight in the
upper left casts hard visible light rays through the dark air. The background
is almost black — deep charcoal and midnight blue — with the silhouette of a
beach volleyball net stretching across the middle distance, its top tape
catching a thin rim of light.

Hero: a yellow-and-black footvolley ball resting in fine sand in the lower
middle of the frame, centred horizontally, lit from the upper left so its
panels and the sand grains around it are crisp. A glowing amber-gold neon
light trail arcs up and around the ball like a curved motion streak, leaving a
soft bloom on the sand. A small burst of sand grains is frozen mid-air around
the ball's base.

Mood: cinematic, high contrast, moody sports advertising photography.
The top 20% and bottom 15% of the frame stay almost pure black and empty.

No text, no logos, no watermark, no people, no UI elements.
```

Negative / avoid list, if the tool takes one:

```
text, letters, logo, watermark, people, hands, bright daytime sky, flat
lighting, cartoon, illustration, low contrast, busy background, multiple
light sources, centred logo composition, square composition
```

### Variants worth generating

Ask for 3-4 and pick: **(a)** ball on sand with the net behind, **(b)** ball
mid-air just above the sand with the trail beneath it, **(c)** ball at the foot
of the net post. Judge them in the preview page below at real crop, not as
thumbnails — the frame decides which one survives.

## Prompt template — any future sport

Swap the four bracketed slots:

```
A dramatic, photorealistic 3D product render for a mobile app launch screen,
vertical portrait composition, aspect ratio 9:19.5.

Scene: a [SPORT VENUE] at night. A single [floodlight/spotlight] in the upper
left casts hard visible light rays through the dark air. The background is
almost black, with [ONE VENUE FEATURE — net, goal, hoop, lane rope] visible in
the middle distance catching a thin rim of light.

Hero: a [BALL/IMPLEMENT] resting on [SURFACE] in the lower middle of the frame,
centred horizontally, lit from the upper left. A glowing [ACCENT COLOUR] neon
light trail arcs up and around it like a curved motion streak. A small burst of
[SURFACE PARTICLES] is frozen mid-air around its base.

Mood: cinematic, high contrast, moody sports advertising photography.
The top 20% and bottom 15% of the frame stay almost pure black and empty.

No text, no logos, no watermark, no people, no UI elements.
```

Accent colours already used: green (soccer), electric blue (beach tennis,
field hockey, handball), cyan (water polo, volleyball), amber (basketball),
lime (tennis, sepak takraw). Pick one that is not the neighbouring sport's.

## Getting from a generated image to a shipped splash

```bash
# 1. crop + resize whatever the model produced to the exact canvas
python3 tools/make_splash.py ~/Downloads/footvolley_render.png footvolley

# 2. look at it in real device frames before believing it
open tools/splash_preview.html

# 3. regenerate the native assets and check
cd FootvolleyBoard && dart run flutter_native_splash:create
python3 tools/verify_app_assets.py footvolley
```

`make_splash.py` writes `<App>/assets/icon/splash_logo.png` directly, so step 3
is all that is left. If the new art is a proper 0.463 portrait, also flip that
app's pubspec back to `ios_content_mode: scaleAspectFill` /
`android_gravity: fill` to match the other fifteen.
