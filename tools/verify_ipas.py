#!/usr/bin/env python3
"""Verify every built IPA before uploading: right version, right bundle id, a
REAL AdMob App ID (not Google's placeholder / another sport's), and device-only
architectures in every bundled framework.

Two failure modes this catches, both of which build and package cleanly and
only blow up later:

1. **Wrong / placeholder AdMob App ID.** The batch build patches Info.plist per
   sport with PlistBuddy. Miss that step and the app crashes at launch or
   serves ads to the wrong AdMob app. ADMOB_PUBLISHING_PLAYBOOK.md lists it as
   the #1 recurring bug — build_all_ipa.sh shipped the placeholder once.

2. **Simulator slice in a framework.** Running any `--simulator` build (e.g. to
   screenshot ad placements) leaves x86_64 artifacts behind; the next release
   build can pick up the fat variant. altool then rejects the upload with
   error 90087 "Unsupported Architectures". Hit on 1.1.25 via
   objective_c.framework. Fix is a full clean + pod reinstall before building.

Checking 16 zip files takes seconds; a bad batch costs a review cycle x16.

  python3 tool/verify_ipas.py 1.1.25
"""
import plistlib
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

IPA_DIR = Path(__file__).resolve().parent.parent / "build" / "ipa_all"

# bundle-id suffix (== IPA filename stem) -> expected AdMob iOS App ID.
# Mirrors the case block in build_all_ipa.sh; keep the two in sync.
EXPECTED_ADMOB = {
    "tacticsBoard":     "ca-app-pub-4247621509300508~5907516538",
    "badmintonBoard":   "ca-app-pub-4247621509300508~8533679872",
    "tableTennisBoard": "ca-app-pub-4247621509300508~2607096007",
    "tennisBoard":      "ca-app-pub-4247621509300508~1321934499",
    "basketballBoard":  "ca-app-pub-4247621509300508~7734769370",
    "volleyballBoard":  "ca-app-pub-4247621509300508~2373641809",
    "pickleballBoard":  "ca-app-pub-4247621509300508~3191899453",
    "soccerBoard":      "ca-app-pub-4247621509300508~2977796941",
    "fieldHockeyBoard": "ca-app-pub-4247621509300508~7240475581",
    "rugbyBoard":       "ca-app-pub-4247621509300508~3301230572",
    "baseballBoard":    "ca-app-pub-4247621509300508~8270486222",
    "handballBoard":    "ca-app-pub-4247621509300508~1878817785",
    "waterPoloBoard":   "ca-app-pub-4247621509300508~6692160761",
    "beachTennisBoard": "ca-app-pub-4247621509300508~8509629141",
    "footvolleyBoard":  "ca-app-pub-4247621509300508~6721904756",
    "sepakTakrawBoard": "ca-app-pub-4247621509300508~4478884795",
}

# Google's sample/test AdMob app ids — shipping either is a launch crash or a
# policy problem, never correct in a release build.
PLACEHOLDERS = {
    "ca-app-pub-3940256099942544~1458002511",
    "ca-app-pub-3940256099942544~3347511713",
}


# Anything not in here is a simulator/Mac slice that App Store Connect rejects.
ALLOWED_ARCHS = {"arm64", "arm64e"}


def bad_arch_frameworks(ipa: Path) -> list[str]:
    """Return "framework: archs" for every bundled framework carrying a
    non-device slice. Extracts only the Mach-O binaries, not the whole IPA."""
    bad = []
    with zipfile.ZipFile(ipa) as z:
        # Payload/Runner.app/Frameworks/<name>.framework/<name>
        names = [n for n in z.namelist()
                 if "/Frameworks/" in n and not n.endswith("/")
                 and Path(n).stem == Path(n).parent.name.replace(".framework", "")
                 and n.endswith(Path(n).parent.name.replace(".framework", ""))]
        with tempfile.TemporaryDirectory() as td:
            for n in names:
                fw = Path(n).parent.name.replace(".framework", "")
                out = Path(td) / fw
                out.write_bytes(z.read(n))
                r = subprocess.run(["lipo", "-archs", str(out)],
                                   capture_output=True, text=True)
                if r.returncode != 0:
                    continue  # not a Mach-O we can read; skip quietly
                archs = set(r.stdout.split())
                if not archs <= ALLOWED_ARCHS:
                    bad.append(f"{fw}({' '.join(sorted(archs))})")
    return bad


def read_info_plist(ipa: Path) -> dict:
    with zipfile.ZipFile(ipa) as z:
        name = next((n for n in z.namelist()
                     if n.count("/") == 2
                     and n.startswith("Payload/")
                     and n.endswith(".app/Info.plist")), None)
        if not name:
            raise LookupError("Info.plist not found in Payload/*.app/")
        return plistlib.loads(z.read(name))


def main() -> int:
    if len(sys.argv) < 2:
        sys.exit("usage: verify_ipas.py <expected-version>   e.g. 1.1.25")
    want_version = sys.argv[1]

    ipas = sorted(IPA_DIR.glob("*.ipa"))
    if not ipas:
        sys.exit(f"no IPAs under {IPA_DIR}")

    print(f"Verifying {len(ipas)} IPAs against version {want_version}\n")
    print(f"{'ipa':20}{'version':10}{'bundle id':30}{'AdMob App ID':42}status")
    print("-" * 112)

    failures, seen_admob = [], {}
    for ipa in ipas:
        stem = ipa.stem
        try:
            info = read_info_plist(ipa)
        except Exception as e:                                  # noqa: BLE001
            print(f"{stem:20}{'?':10}{'?':30}{'?':42}UNREADABLE ({e})")
            failures.append(f"{stem}: unreadable ({e})")
            continue

        version = info.get("CFBundleShortVersionString", "?")
        bundle = info.get("CFBundleIdentifier", "?")
        admob = info.get("GADApplicationIdentifier", "(missing)")

        problems = []
        if version != want_version:
            problems.append(f"version {version} != {want_version}")
        if bundle != f"com.zach.{stem}":
            problems.append(f"bundle {bundle} != com.zach.{stem}")
        expected = EXPECTED_ADMOB.get(stem)
        if expected is None:
            problems.append("unknown app (not in EXPECTED_ADMOB)")
        elif admob in PLACEHOLDERS:
            problems.append("AdMob App ID is Google's PLACEHOLDER")
        elif admob != expected:
            problems.append(f"AdMob {admob} != {expected}")
        # Two apps sharing an AdMob App ID means a PlistBuddy patch was skipped
        # and this build inherited the previous sport's plist.
        if admob in seen_admob:
            problems.append(f"AdMob App ID duplicated with {seen_admob[admob]}")
        else:
            seen_admob[admob] = stem
        # altool error 90087 — catch it here rather than 30 minutes into an upload.
        bad = bad_arch_frameworks(ipa)
        if bad:
            problems.append(f"non-device arch in {', '.join(bad)}")

        status = "OK" if not problems else "; ".join(problems)
        print(f"{stem:20}{version:10}{bundle:30}{admob:42}{status}")
        if problems:
            failures.append(f"{stem}: {status}")

    missing = sorted(set(EXPECTED_ADMOB) - {i.stem for i in ipas})
    if missing:
        failures.append(f"missing IPAs: {', '.join(missing)}")

    print()
    if failures:
        print(f"❌ {len(failures)} problem(s):")
        for f in failures:
            print(f"   - {f}")
        return 1
    print(f"✅ all {len(ipas)} IPAs verified")
    return 0


if __name__ == "__main__":
    sys.exit(main())
