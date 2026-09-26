# macOS App Store screenshots — Soccer Board

Five 2880×1800 captures of the real Mac app: home, a drill, the board two
beats into that drill, the library, the practice plan.

Tracked, unlike the iPhone set. The iPhone shots are composited from raw
captures that ARE tracked, so they can be rebuilt; these are photographs of
a running app and nothing else can recreate them.

How they were taken — the window is put on the **built-in Retina display**
at 1440×900 points, which is exactly 2880×1800 pixels:

```bash
osascript -e 'tell application "System Events" to tell process "Soccer Board"
  set frontmost to true
  set position of window 1 to {40, 60}
  set size of window 1 to {1440, 900}
end tell'
python3 tools/mac_window_shot.py "Soccer Board" 01_home.png
```

Then flattened to RGB: a window capture carries an alpha channel for the
rounded corners, and the App Store refuses a screenshot with one.
