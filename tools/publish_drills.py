#!/usr/bin/env python3
"""Publish the drill libraries to the server, so installed apps get them.

The apps already know how to update themselves: every one of them asks
`GET https://tacticsboard.100for1.com/api/v1/drills/{sport}` in the
background and keeps the answer when its `version` is strictly higher than
the copy it has. What was missing was anybody raising that number and
putting the files where the API reads them. That is this script.

    python3 tools/publish_drills.py bump      # version +1, regenerate
    python3 tools/publish_drills.py verify    # parse the packs as the app does
    python3 tools/publish_drills.py upload    # scp them to the server
    python3 tools/publish_drills.py check     # read them back over HTTPS
    python3 tools/publish_drills.py all       # the four in order

Every step is separate and every step can be run again: `bump` is the only
one that changes anything locally, and re-uploading a pack the server
already has is a no-op as far as the apps are concerned.

This publishes data and nothing else. It does not build, upload or submit
an app — a released build and its drills are deliberately different things.
"""
import argparse
import json
import os
import subprocess
import sys
import urllib.request
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
PACKS = REPO / "tactics_board" / "assets" / "drills"
VERSION_FILE = REPO / "tools" / "drills" / "pack_version.txt"
API = "https://tacticsboard.100for1.com/api/v1/drills"

# Laravel 11 roots the `local` disk at storage/app/private, so the path the
# controller calls "drills/soccer.json" is this one on disk. Writing to
# storage/app/drills/ instead leaves the API serving the old packs and no
# error anywhere to say why.
REMOTE_DIR = "/srv/httpd/htdocs/tacticsboard/storage/app/private/drills"

SPORTS = ["badminton", "baseball", "basketball", "beachTennis", "fieldHockey",
          "footvolley", "handball", "pickleball", "rugby", "sepakTakraw",
          "soccer", "tableTennis", "tennis", "volleyball", "waterPolo"]


def read_version() -> int:
    return int(VERSION_FILE.read_text(encoding="utf-8").strip())


def ssh_config() -> dict:
    """Host, user and key for the box, from the .env files that hold them.

    Nothing about the server is written down in this repo on purpose: the
    key is a file outside it and the address lives in the untracked .env
    beside the other projects that deploy to the same machine.
    """
    cfg = {}
    for env in (Path.home() / "projects" / ".env", REPO / ".env"):
        if not env.exists():
            continue
        for line in env.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line.startswith("#") or "=" not in line:
                continue
            k, _, v = line.partition("=")
            k = k.strip()
            if k in ("SSH_HOST", "SSH_USER", "SSH_KEY_FILE"):
                cfg.setdefault(k, v.strip().strip('"').strip("'"))
    for k in ("SSH_HOST", "SSH_USER", "SSH_KEY_FILE"):
        if os.environ.get(k):
            cfg[k] = os.environ[k]
    missing = [k for k in ("SSH_HOST", "SSH_USER", "SSH_KEY_FILE") if not cfg.get(k)]
    if missing:
        sys.exit(f"✗ no server credentials: {', '.join(missing)} unset in "
                 f"~/projects/.env, {REPO.name}/.env or the environment")
    if not Path(cfg["SSH_KEY_FILE"]).exists():
        sys.exit(f"✗ SSH key {cfg['SSH_KEY_FILE']} does not exist")
    return cfg


def cmd_bump() -> int:
    """Raise the published version and rebuild the packs at that number."""
    new = read_version() + 1
    VERSION_FILE.write_text(f"{new}\n", encoding="utf-8")
    print(f"pack_version.txt: {new - 1} → {new}")
    r = subprocess.run([sys.executable, "gen_drills.py"], cwd=REPO / "tools")
    if r.returncode != 0:
        return r.returncode
    print(f"regenerated 15 packs at version {new}")
    return 0


def cmd_verify() -> int:
    """Read every pack the way the app reads it, and refuse a bad one.

    The app parses a downloaded pack before it writes it to disk, so a
    broken pack is survivable — but it is survivable by silently never
    updating, which looks exactly like everything being fine. Catch it here
    instead, where the output says which sport and how many drills.
    """
    want = read_version()
    bad = 0
    total = 0
    for sport in SPORTS:
        path = PACKS / f"{sport}.json"
        try:
            pack = json.loads(path.read_text(encoding="utf-8"))
            assert pack["sport"] == sport, f"says sport={pack['sport']}"
            assert pack["version"] == want, \
                f"version {pack['version']}, expected {want} — run bump"
            drills = pack["drills"]
            assert drills, "no drills"
            for d in drills:
                for key in ("id", "name", "board"):
                    assert key in d, f"drill {d.get('id', '?')} has no {key}"
                assert d["board"].get("players"), \
                    f"drill {d['id']} has an empty board"
        except Exception as e:  # noqa: BLE001 - the message is the product
            print(f"✗ {sport}: {e}")
            bad += 1
            continue
        total += len(drills)
        print(f"✓ {sport}: {len(drills)} drills, version {want}")
    print(f"{total} drills across {len(SPORTS)} sports")
    return 1 if bad else 0


def cmd_upload() -> int:
    """Copy the packs onto the box the API serves them from."""
    cfg = ssh_config()
    target = f"{cfg['SSH_USER']}@{cfg['SSH_HOST']}"
    ssh = ["ssh", "-i", cfg["SSH_KEY_FILE"], "-o", "BatchMode=yes"]
    r = subprocess.run(ssh + [target, f"mkdir -p {REMOTE_DIR}"])
    if r.returncode != 0:
        return r.returncode
    files = [str(PACKS / f"{s}.json") for s in SPORTS]
    r = subprocess.run(["scp", "-q", "-i", cfg["SSH_KEY_FILE"],
                        "-o", "BatchMode=yes", *files, f"{target}:{REMOTE_DIR}/"])
    if r.returncode != 0:
        return r.returncode
    print(f"uploaded {len(files)} packs to {target}:{REMOTE_DIR}")
    return 0


def cmd_check() -> int:
    """Ask the API for each pack and confirm it is the one just published.

    The responses are cached for an hour, so the request carries
    `Cache-Control: no-cache` — otherwise a successful publish reads back
    as the previous version and the next hour is spent looking for a bug
    that is not there.
    """
    want = read_version()
    bad = 0
    for sport in SPORTS:
        local = json.loads((PACKS / f"{sport}.json").read_text(encoding="utf-8"))
        req = urllib.request.Request(
            f"{API}/{sport}",
            headers={"Cache-Control": "no-cache", "Pragma": "no-cache"})
        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                served = json.loads(resp.read().decode("utf-8"))
        except Exception as e:  # noqa: BLE001
            print(f"✗ {sport}: {e}")
            bad += 1
            continue
        n, want_n = len(served.get("drills", [])), len(local["drills"])
        got = served.get("version")
        if got != want or n != want_n:
            print(f"✗ {sport}: serving version {got} with {n} drills, "
                  f"expected version {want} with {want_n}")
            bad += 1
        else:
            print(f"✓ {sport}: version {got}, {n} drills")
    return 1 if bad else 0


STEPS = {"bump": cmd_bump, "verify": cmd_verify,
         "upload": cmd_upload, "check": cmd_check}


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("step", choices=[*STEPS, "all"])
    args = ap.parse_args()
    steps = list(STEPS) if args.step == "all" else [args.step]
    for name in steps:
        print(f"── {name} ──")
        rc = STEPS[name]()
        if rc != 0:
            print(f"✗ {name} failed; stopping")
            return rc
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
