#!/usr/bin/env python3
"""Add machine-assisted English translations to the bundled iOS content JSONs.

For the demo only: adds *_en fields alongside the *_tc fields. To be replaced
by Harmon's official English later. Idempotent — re-running overwrites *_en.

    python3 scripts/translate_content.py
"""
from pathlib import Path

from content_translations import apply_to

ROOT = Path(__file__).resolve().parent.parent
CONTENT_DIR = ROOT / "CareVoice" / "Resources" / "content"

if __name__ == "__main__":
    apply_to(CONTENT_DIR)
    print("Translated iOS content in", CONTENT_DIR)
