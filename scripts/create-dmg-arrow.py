#!/usr/bin/env python3
"""Create the installation arrow used by the DMG background."""
from __future__ import annotations

import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


CANVAS_WIDTH = 700
CANVAS_HEIGHT = 400
SCALE = 4
FINDER_ICON_SIZE = 128
ARROW_SIZE = 100


def scaled_points(points: list[tuple[float, float]]) -> list[tuple[float, float]]:
    return [(x * SCALE, y * SCALE) for x, y in points]


def dashed_path(
    draw: ImageDraw.ImageDraw,
    points: list[tuple[float, float]],
    *,
    fill: tuple[int, int, int, int],
    width: int,
    dash: float = 11,
    gap: float = 8,
) -> None:
    for start, end in zip(points, points[1:]):
        x1, y1 = start
        x2, y2 = end
        length = math.hypot(x2 - x1, y2 - y1)
        if length == 0:
            continue
        dx = (x2 - x1) / length
        dy = (y2 - y1) / length
        distance = 0.0
        while distance < length:
            dash_end = min(distance + dash, length)
            draw.line(
                (
                    (x1 + dx * distance, y1 + dy * distance),
                    (x1 + dx * dash_end, y1 + dy * dash_end),
                ),
                fill=fill,
                width=width,
            )
            distance += dash + gap


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("usage: create-dmg-arrow.py OUTPUT.png")

    output = Path(sys.argv[1])
    output.parent.mkdir(parents=True, exist_ok=True)

    size = (CANVAS_WIDTH * SCALE, CANVAS_HEIGHT * SCALE)
    # Use the same dark surface as the app's macOS mock-up. An opaque image
    # keeps Finder from replacing a transparent DMG background with white.
    image = Image.new("RGBA", size, (30, 30, 30, 255))

    if ARROW_SIZE >= FINDER_ICON_SIZE:
        raise SystemExit("DMG arrow must remain smaller than Finder icons")

    # The arrow is a 100x100 outline centered between the two 128px installer
    # icons. Keeping it smaller than the icons leaves both labels readable.
    arrow = [
        (300, 175),
        (350, 175),
        (350, 150),
        (400, 200),
        (350, 250),
        (350, 225),
        (300, 225),
        (300, 175),
    ]
    shadow_layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow_layer)
    dashed_path(
        shadow_draw,
        scaled_points(arrow),
        fill=(0, 0, 0, 90),
        width=5 * SCALE,
    )
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(2 * SCALE))
    image.alpha_composite(shadow_layer)

    draw = ImageDraw.Draw(image)
    dashed_path(
        draw,
        scaled_points(arrow),
        fill=(220, 220, 220, 225),
        width=3 * SCALE,
    )

    image.resize((CANVAS_WIDTH, CANVAS_HEIGHT), Image.Resampling.LANCZOS).save(
        output,
        format="PNG",
        optimize=True,
    )
    print(f"Generated {output}")


if __name__ == "__main__":
    main()
