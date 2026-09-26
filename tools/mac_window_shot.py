#!/usr/bin/env python3
"""Capture one window at Retina resolution, excluding anything drawn over it.

For the macOS App Store screenshots: a 1440x900 window on a Retina display
is exactly the 2880x1800 Apple asks for.

`screencapture -R` grabs the screen, so a notification banner — or any
window the app is not actually in front of — lands in the shot; and the app
had better be on the built-in display, because a capture off a 1x monitor
comes out 1440x900. `screencapture -l` gives the window alone but only at
1x. This asks the window server for the window's own image at its backing
scale, which is neither.

    python3 tools/mac_window_shot.py "Soccer Board" out.png

Flatten the result before uploading: a window capture carries an alpha
channel for its rounded corners and the App Store refuses one.
"""
import sys
import Quartz
from Quartz import CGWindowListCreateImage, CGRectNull
import AppKit


def window_id(owner: str) -> int:
    for w in Quartz.CGWindowListCopyWindowInfo(
            Quartz.kCGWindowListOptionOnScreenOnly, Quartz.kCGNullWindowID):
        if w.get('kCGWindowOwnerName') == owner and w['kCGWindowBounds']['Width'] > 800:
            return w['kCGWindowNumber']
    raise SystemExit(f'no window for {owner}')


def main() -> None:
    owner, out = sys.argv[1], sys.argv[2]
    wid = window_id(owner)
    img = CGWindowListCreateImage(
        CGRectNull,
        Quartz.kCGWindowListOptionIncludingWindow,
        wid,
        Quartz.kCGWindowImageBoundsIgnoreFraming
        | Quartz.kCGWindowImageBestResolution)
    rep = AppKit.NSBitmapImageRep.alloc().initWithCGImage_(img)
    data = rep.representationUsingType_properties_(AppKit.NSBitmapImageFileTypePNG, {})
    data.writeToFile_atomically_(out, True)
    print(out, rep.pixelsWide(), 'x', rep.pixelsHigh())


if __name__ == '__main__':
    main()
