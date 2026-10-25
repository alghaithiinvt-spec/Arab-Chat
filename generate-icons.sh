
#!/usr/bin/env bash
set -euo pipefail

ICON="icon.png"
RES="android/app/src/main/res"

if [ ! -f "$ICON" ]; then
  echo "ERROR: icon.png not found in project root"
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: Python 3 is required"
  exit 1
fi

python3 -m pip install --quiet Pillow

python3 - <<'PY'
from PIL import Image
from pathlib import Path

src = Image.open("icon.png").convert("RGBA")
sizes = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

for folder, size in sizes.items():
    dest = Path("android/app/src/main/res") / folder
    dest.mkdir(parents=True, exist_ok=True)
    img = src.resize((size, size), Image.Resampling.LANCZOS)
    img.save(dest / "ic_launcher.png")

print("Android launcher icons generated.")
PY

echo "Done."
