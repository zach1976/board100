#!/usr/bin/env python3
"""真机截图 vs 审校页面的渲染图，逐像素比对。

回答一个问题：drill_review.html 上的板，和手机上画的是不是同一块。

    DRIVE_DEFINES="--dart-define=DRILL=<id>" WALK=board_shot \
        tools/drive_app.sh <key> <udid>
    python3 tools/compare_board.py <key> <id>

已知残差：Display-P3 采集与 sRGB 渲染的固定色偏，表现为 R 通道整体
+29 左右而 G/B 几乎不动，中位差约 6。结构性差异会让某一拍的数字明显
跳出其余几拍 —— 四拍数字接近就是一致。
"""
import sys, pathlib
import numpy as np
from PIL import Image

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from apps import APPS

def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    key, drill = sys.argv[1], sys.argv[2]
    shots = pathlib.Path(APPS[key]['dir']) / 'screenshots'
    rendered = pathlib.Path('tools/board_png') / key

    print(f"{'拍':>3s}  {'平均差':>7s} {'中位':>5s} {'>40占比':>8s}  {'R/G/B 偏移'}")
    rows = []
    for s in range(20):
        a_p = shots / f'sim-{drill}-{s}.png'
        b_p = rendered / f'{drill}-{s}.png'
        if not a_p.exists() or not b_p.exists():
            break
        sim = Image.open(a_p).convert('RGB')
        ren = Image.open(b_p).convert('RGB')
        # 真机图含工具栏；球场区是顶部起、与渲染同比例的那一块
        h = round(sim.width * ren.height / ren.width)
        sim = sim.crop((0, 0, sim.width, h)).resize(ren.size, Image.LANCZOS)
        a = np.asarray(sim, dtype=np.int16)
        b = np.asarray(ren, dtype=np.int16)
        d = np.abs(a - b)
        mean, med = d.mean(), float(np.median(d))
        big = (d.max(axis=2) > 40).mean() * 100
        chan = [round(float((a[:, :, i] - b[:, :, i]).mean()), 1) for i in range(3)]
        rows.append(big)
        print(f'{s:>3d}  {mean:7.2f} {med:5.1f} {big:7.2f}%  {chan}')

    if not rows:
        sys.exit(f'✗ 没有可比对的图。先跑 board_shot，再确认 tools/board_png/{key}/ 有 {drill}')
    spread = max(rows) - min(rows)
    print()
    print(f'各拍差异离散度 {spread:.2f} 个百分点', end='  ')
    print('→ 一致' if spread < 1.5 else '→ 有某一拍画得不同，去看它')

if __name__ == '__main__':
    main()
