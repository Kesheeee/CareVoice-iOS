#!/usr/bin/env python3
"""Sync Harmon's curated content into the FastAPI backend's data directory.

Copies export/*.json from the Phase 1 data layer, then applies the *_en
translations (shared with the iOS bundle).

    python3 backend/scripts/sync_data.py [source_dir]
"""
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent   # repo root
DATA_DIR = ROOT / "backend" / "data"
DEFAULT_SOURCE = (
    Path.home() / "Desktop" / "Phase1资料层_0ae157aa8e0a22c8" / "phase1_db" / "export"
)

# Make the repo's scripts/ importable so we can reuse the shared translation maps.
sys.path.insert(0, str(ROOT / "scripts"))
from content_translations import apply_to  # noqa: E402


def main() -> int:
    src = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_SOURCE
    if not src.is_dir():
        print(f"Error: source directory not found: {src}")
        return 1
    files = sorted(src.glob("*.json"))
    if not files:
        print(f"Error: no *.json files in {src}")
        return 1
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    for f in files:
        shutil.copy2(f, DATA_DIR / f.name)
    translated = apply_to(DATA_DIR)
    print(f"Synced {len(files)} files -> {DATA_DIR}")
    print(f"Applied translations to {len(translated)} files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
