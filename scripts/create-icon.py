#!/usr/bin/env python3
"""Encode the checked-in Limitly mark as a multi-size Windows ICO.

The 256px PNG in ``Sources/LimitlyApp/Resources`` is the visual reference
supplied for Limitly. Keeping that raster as the single design source avoids
silently changing the ring end caps, opening, or dot when the icon is rebuilt.
The application and DMG still consume ``Limitly.ico`` through
``scripts/make-icons.sh``; this helper only packages the same mark into the
required ICO sizes and refreshes the SwiftUI preview resource.
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
REFERENCE = ROOT / "Sources" / "LimitlyApp" / "Resources" / "LimitlyIcon.png"
OUTPUT = ROOT / "Limitly.ico"

ICO_SIZES = [
    (16, 16),
    (24, 24),
    (32, 32),
    (48, 48),
    (64, 64),
    (128, 128),
    (256, 256),
]


def main() -> None:
    if not REFERENCE.is_file():
        raise SystemExit(f"Missing icon reference: {REFERENCE}")

    image = Image.open(REFERENCE).convert("RGBA")
    if image.size != (256, 256):
        raise SystemExit(f"Icon reference must be 256x256, got {image.size}")

    image.save(OUTPUT, format="ICO", sizes=ICO_SIZES)
    # Re-save the normalized RGBA image so the SwiftUI fallback resource stays
    # byte-for-byte aligned with the visual source used to build the ICO.
    image.save(REFERENCE, format="PNG")
    print(f"Generated {OUTPUT}")
    print(f"Verified {REFERENCE}")


if __name__ == "__main__":
    main()
