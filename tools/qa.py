from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
errors = []
required = [
    "main.lua","conf.lua","assets.lua","modes.lua","player.lua","enemy.lua","bullet.lua","weapons.lua",
    "powerup.lua","xp.lua","drone.lua","particles.lua","effects.lua","sound.lua","profile.lua","touchcontrols.lua"
]
for name in required:
    if not (ROOT / name).is_file(): errors.append(f"missing required source: {name}")

files = {}
for name in ["main.lua","modes.lua","player.lua","enemy.lua","weapons.lua","assets.lua","sound.lua","xp.lua"]:
    p = ROOT / name
    files[name] = p.read_text(encoding="utf-8") if p.exists() else ""
web = (ROOT / "web" / "index.html").read_text(encoding="utf-8") if (ROOT / "web" / "index.html").exists() else ""

modes = files["modes.lua"]
mode_ids = re.findall(r'id="(campaign|endless|gauntlet)"', modes)
if sorted(set(mode_ids)) != ["campaign", "endless", "gauntlet"]: errors.append(f"mode registry invalid: {sorted(set(mode_ids))}")
if len(re.findall(r'^\s*\w+\s*=\s*\{id=', modes, re.M)) != 3: errors.append("modes.lua must expose exactly three mode definitions")

for needle in ['require("touchcontrols")','Assets.load()','Modes.waveRules(run)','XP.addXP(xpData','Particles','Effects','Sound.new()','Modes.nextGauntletTrial(run)']:
    if needle not in files["main.lua"] and needle not in modes: errors.append(f"integration missing: {needle}")

for p in [
    "assets/SpaceShip.png","assets/bg.png","assets/Stars-A.png","assets/Stars-B.png","assets/SWARMERS.png","assets/SNIPERS.png",
    "assets/BOMBERS.png","assets/TURRET DRONES.png","assets/MINI-BOSSES.png","assets/bullet.png","assets/bullet-1.png","assets/bullet-2.png",
    "assets/laser-1.png","assets/laser-2.png","assets/laser-3.png","assets/plasm.png","assets/rocket.png","assets/shield.png","assets/fire.png",
    "assets/bonus_life.png","assets/bonus_shield.png","assets/bonus_time.png"]:
    if p not in files["assets.lua"]: errors.append(f"asset registry missing: {p}")
if "sounds/" not in files["sound.lua"]: errors.append("sound manager is not pointed at sounds/")

for label, needle, source in [
    ("temporary rapid-fire", "rapidfire > 0", files["player.lua"]),
    ("temporary damage boost", "damage > 0", files["player.lua"]),
    ("temporary multi-shot", "multishot > 0", files["player.lua"]),
    ("armor mitigation", "self.powerups.armor > 0", files["player.lua"]),
    ("time slow state", "__SV_TIME_SCALE", files["player.lua"]),
    ("enemy time scaling", "dt=dt*(_G.__SV_TIME_SCALE or 1)", files["enemy.lua"]),
    ("weapon auto reload", "autoReload=true", files["weapons.lua"]),
    ("weapon ammo refill", "d.autoReload", files["weapons.lua"]),
]:
    if needle not in source: errors.append(f"gameplay hook missing: {label}")

for label, needles, source in [
    ("weapon fire profile", ["Weapons.types", "fireRate", "damage", "bulletSpeed"], files["weapons.lua"]),
    ("weapon selection state", ["currentWeapon", "Weapons.hasAmmo", "Weapons.useAmmo"], files["main.lua"]),
    ("homing missile weapon data", ["homing=true", "explosion=true"], files["weapons.lua"]),
]:
    for needle in needles:
        if needle not in source: errors.append(f"weapon integration missing: {label}: {needle}")

for needle in ['id="firerate"','id="damage"','id="multishot"','id="piercing"','id="dronedamage"']:
    if needle not in files["xp.lua"]: errors.append(f"persistent upgrade missing: {needle}")

for needle in ["loader.src='love.js'", "love.js was not found", "theme-color", "platform-bridge.js"]:
    if needle not in web: errors.append(f"web shell missing: {needle}")

package = ROOT / "tools" / "package_love.sh"
if not package.is_file(): errors.append("release package helper missing: tools/package_love.sh")
else:
    package_text = package.read_text(encoding="utf-8")
    for needle in ["zip -qr", "-x '.git/*'", "-x '*.love'"]:
        if needle not in package_text: errors.append(f"package helper missing safeguard: {needle}")

if errors:
    print("STARFALL QA: FAIL")
    for e in errors: print(" -", e)
    sys.exit(1)
print("STARFALL QA: PASS")
print("Production source, three-mode registry, gameplay effects, weapon wiring, asset/audio hooks, web loader shell and release packaging safeguards verified.")
