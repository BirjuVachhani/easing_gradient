#!/usr/bin/env python3
"""Losslessly optimize the generated README figures for web delivery.

Run after `flutter test tool/generate_readme_images.dart`.

The two dithered hero scrims compress better as PNG. Every other figure is
converted to exact lossless WebP, then its source PNG is removed. Decoded RGBA
bytes are compared before replacing a file, so a codec or tool change cannot
silently alter pixels.
"""

from __future__ import annotations

import hashlib
import shutil
import subprocess
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError as error:
    raise SystemExit(
        "Missing Pillow. Install it with `python3 -m pip install Pillow`."
    ) from error

IMAGE_DIR = Path("doc/images")
PNG_STEMS = {"scrim-native", "scrim-eased"}


def require_tool(name: str) -> str:
    path = shutil.which(name)
    if path is None:
        raise SystemExit(f"Missing required image optimizer: {name}")
    return path


def rgba_digest(path: Path) -> tuple[tuple[int, int], str]:
    with Image.open(path) as image:
        rgba = image.convert("RGBA")
        return rgba.size, hashlib.sha256(rgba.tobytes()).hexdigest()


def run(command: list[str]) -> None:
    subprocess.run(command, check=True)


def main() -> None:
    oxipng = require_tool("oxipng")
    cwebp = require_tool("cwebp")
    pngs = sorted(IMAGE_DIR.glob("*.png"))
    webps = sorted(IMAGE_DIR.glob("*.webp"))
    if not pngs:
        raise SystemExit(f"No generated PNGs found under {IMAGE_DIR}")

    # Immediately after generation, all figures exist as PNG and stale WebPs may
    # still be present from an earlier optimization. Count the canonical PNG set
    # in that case. On an already optimized tree, count the current hybrid set so
    # a second run reports zero savings.
    before_paths = pngs if len(pngs) > len(PNG_STEMS) else pngs + webps
    before = sum(path.stat().st_size for path in before_paths)
    run([
        oxipng,
        "-o",
        "max",
        "--strip",
        "safe",
        "--interlace",
        "off",
        *map(str, pngs),
    ])

    for png in pngs:
        if png.stem in PNG_STEMS:
            stale_webp = png.with_suffix(".webp")
            stale_webp.unlink(missing_ok=True)
            continue

        webp = png.with_suffix(".webp")
        temporary = webp.with_suffix(".webp.tmp")
        expected = rgba_digest(png)
        try:
            run([
                cwebp,
                "-quiet",
                "-lossless",
                "-z",
                "9",
                "-exact",
                "-metadata",
                "none",
                str(png),
                "-o",
                str(temporary),
            ])
            if rgba_digest(temporary) != expected:
                raise RuntimeError(f"Lossless verification failed for {png.name}")
            temporary.replace(webp)
            png.unlink()
        finally:
            temporary.unlink(missing_ok=True)

    outputs = sorted(IMAGE_DIR.glob("*.png")) + sorted(IMAGE_DIR.glob("*.webp"))
    after = sum(path.stat().st_size for path in outputs)
    saved = before - after
    percent = saved / before * 100
    print(
        f"Optimized {len(outputs)} figures: {before:,} -> {after:,} bytes "
        f"({saved:,} saved, {percent:.2f}%)."
    )


if __name__ == "__main__":
    try:
        main()
    except (OSError, subprocess.CalledProcessError, RuntimeError) as error:
        print(error, file=sys.stderr)
        raise SystemExit(1) from error
