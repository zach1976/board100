#!/usr/bin/env python3
"""Put a generated intro backdrop into the app that owns it.

The art is shot for a 9:19.5 phone. A generator that hands back something
shorter is the normal case, not the exception, and `BoxFit.cover` pays for
it by cropping the SIDES — which is where the decorative chalk handwriting
sits, so "Plan / Train / Improve" arrives on the phone as "rain / mprove".

So instead of cropping, extend upward. The top of every one of these images
is an almost flat dark gradient with the odd light ray in it: continuing row
zero upward, blurred horizontally and darkening as it goes, is invisible,
and it means the whole composed frame survives to the phone.

    tools/install_intro_art.py soccer 1 ~/Downloads/intro_art/soccer_1.png
    tools/install_intro_art.py --all ~/Downloads/intro_art
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image, ImageFilter  # noqa: E402
import apps  # noqa: E402

TARGET = 2340 / 1080  # 9:19.5, the tallest phone the apps run on
QUALITY = 82


def extend_top(im):
    """Grow the canvas upward until the frame is 9:19.5, painting the new
    space with a continuation of the image's own top edge."""
    w, h = im.size
    want = int(round(w * TARGET))
    if h >= want:
        return im, 0
    pad = want - h

    # Row zero, smeared sideways: keeps a light ray roughly where it was
    # without carrying any hard edge up into the new space.
    strip = im.crop((0, 0, w, 1)).resize((w, 8), Image.NEAREST)
    strip = strip.filter(ImageFilter.GaussianBlur(radius=w / 22))
    strip = strip.crop((0, 0, w, 1))

    out = Image.new('RGB', (w, want))
    px = strip.load()
    for y in range(pad):
        # 1.0 at the seam, 0.78 at the very top: the frame is already
        # darkest at the top, so continuing to darken reads as depth
        # rather than as a join.
        k = 0.78 + 0.22 * (y / max(pad - 1, 1))
        row = Image.new('RGB', (w, 1))
        rpx = row.load()
        for x in range(w):
            r, g, b = px[x, 0]
            rpx[x, 0] = (int(r * k), int(g * k), int(b * k))
        out.paste(row, (0, y))
    out.paste(im, (0, pad))
    return out, pad


def install(key, panel, src):
    directory = apps.app_dir(key)
    dest_dir = os.path.join(directory, 'assets', 'intro')
    os.makedirs(dest_dir, exist_ok=True)
    dest = os.path.join(dest_dir, 'intro_%d.webp' % panel)

    im = Image.open(src).convert('RGB')
    before = im.size
    im, pad = extend_top(im)
    im.save(dest, 'WEBP', quality=QUALITY, method=6)
    kb = os.path.getsize(dest) // 1024
    print('%-14s panel %d  %dx%d -> %dx%d (+%d top)  %d KB  %s'
          % (key, panel, before[0], before[1], im.size[0], im.size[1], pad,
             kb, os.path.relpath(dest)))


def main(argv):
    if not argv:
        print(__doc__)
        return 1
    if argv[0] == '--all':
        root = os.path.expanduser(argv[1])
        found = 0
        for name in sorted(os.listdir(root)):
            stem, ext = os.path.splitext(name)
            if ext.lower() not in ('.png', '.jpg', '.jpeg', '.webp'):
                continue
            key, _, panel = stem.rpartition('_')
            if not key or not panel.isdigit() or not 1 <= int(panel) <= 3:
                print('skip (name it <key>_<1|2|3>.png):', name)
                continue
            install(key, int(panel), os.path.join(root, name))
            found += 1
        if not found:
            print('nothing to install in', root)
            return 1
        return 0
    key, panel, src = argv[0], int(argv[1]), os.path.expanduser(argv[2])
    install(key, panel, src)
    return 0


if __name__ == '__main__':
    raise SystemExit(main(sys.argv[1:]))
