from pathlib import Path
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
errors = []

required_files = [
    "main.lua", "conf.lua", "assets.lua", "modes.lua", "player.lua", "enemy.lua",
    "bullet.lua", "weapons.lua", "powerup.lua", "xp.lua", "drone.lua", "particles.lua",
    "effects.lua", "sound.lua", "profile.lua", "touchcontrols.lua"
]
for name in required_files:
    if not (ROOT / name).is_file():
        errors.append(f"missing runtime file: {name}")

for directory in ["assets", "sounds"]:
    p = ROOT / directory
    if not p.is_dir():
        errors.append(f"missing runtime directory: {directory}")
    elif not any(p.iterdir()):
        errors.append(f"empty runtime directory: {directory}")

# The web shell intentionally requires a generated love.js at deployment time.
web = ROOT / "web" / "index.html"
if not web.is_file():
    errors.append("missing web/index.html")
elif "love.js" not in web.read_text(encoding="utf-8"):
    errors.append("web shell does not reference love.js")

# Validate the native package when it has already been built locally.
artifact = ROOT / "Starfall-Vengeance.love"
if artifact.exists():
    try:
        with zipfile.ZipFile(artifact) as z:
            names = set(z.namelist())
            for name in required_files:
                if name not in names:
                    errors.append(f"native package missing: {name}")
            if not any(n.startswith("assets/") for n in names):
                errors.append("native package missing assets/")
            if not any(n.startswith("sounds/") for n in names):
                errors.append("native package missing sounds/")
            forbidden = [n for n in names if n.startswith((".git/", "tools/", "tests/", "docs/"))]
            if forbidden:
                errors.append(f"native package contains development payload: {forbidden[:3]}")
    except zipfile.BadZipFile:
        errors.append("native package is not a valid ZIP/LÖVE archive")

if errors:
    print("STARFALL RELEASE CHECK: FAIL")
    for e in errors:
        print(" -", e)
    sys.exit(1)

print("STARFALL RELEASE CHECK: PASS")
print("Runtime files, asset/audio directories and web loader structure are release-ready.")
