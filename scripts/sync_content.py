#!/usr/bin/env python3
"""Copy the Phase 1 data-layer JSON exports into the app's bundled content.

Usage:
    python3 scripts/sync_content.py [source_dir]

Default source: the Desktop handoff folder's export/ directory. Run this
after the data layer re-exports, then regenerate the Xcode project if new
files were added (python3 scripts/generate_project.py).
"""
from pathlib import Path
import shutil
import sys

ROOT = Path(__file__).resolve().parent.parent
DST = ROOT / "CareVoice" / "Resources" / "content"
DEFAULT = Path.home() / "Desktop" / "Phase1资料层_0ae157aa8e0a22c8" / "phase1_db" / "export"


def main() -> int:
    src = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT
    if not src.is_dir():
        print(f"Error: source directory not found: {src}")
        return 1
    files = sorted(src.glob("*.json"))
    if not files:
        print(f"Error: no *.json files in {src}")
        return 1
    DST.mkdir(parents=True, exist_ok=True)
    for f in files:
        shutil.copy2(f, DST / f.name)
        print(f"  {f.name}")
    print(f"Synced {len(files)} files -> {DST}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
