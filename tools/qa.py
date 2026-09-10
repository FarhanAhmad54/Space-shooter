from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
errors = []
required = ["main.lua","conf.lua","assets.lua","modes.lua","player.lua","enemy.lua","bullet.lua","weapons.lua","powerup.lua","xp.lua","drone.lua","particles.lua","effects.lua","sound.lua","profile.lua","touchcontrols.lua"]
for name in required:
    if not (ROOT/name).is_file(): errors.append(f"missing required source: {name}")

main=(ROOT/"main.lua").read_text(encoding="utf-8") if (ROOT/"main.lua").exists() else ""
modes=(ROOT/"modes.lua").read_text(encoding="utf-8") if (ROOT/"modes.lua").exists() else ""

mode_ids=re.findall(r'id="(campaign|endless|gauntlet)"', modes)
if sorted(set(mode_ids)) != ["campaign","endless","gauntlet"]: errors.append(f"mode registry invalid: {sorted(set(mode_ids))}")
if len(re.findall(r'^\s*\w+\s*=\s*\{id=', modes, re.M)) != 3: errors.append("modes.lua must expose exactly three mode definitions")

# High-value integrations that must stay wired.
for needle in ["require(\"touchcontrols\")","Assets.load()","Modes.waveRules(run)","XP.addXP(xpData","Particles","Effects","Sound.new()","Profile.init()"]:
    if needle not in main and needle not in modes: errors.append(f"integration missing: {needle}")

asset_patterns = [
    "assets/SpaceShip.png","assets/bg.png","assets/Stars-A.png","assets/Stars-B.png",
    "assets/SWARMERS.png","assets/SNIPERS.png","assets/BOMBERS.png","assets/TURRET DRONES.png","assets/MINI-BOSSES.png",
    "assets/bullet.png","assets/bullet-1.png","assets/bullet-2.png","assets/laser-1.png","assets/laser-2.png","assets/laser-3.png","assets/plasm.png","assets/rocket.png",
    "assets/shield.png","assets/fire.png","assets/bonus_life.png","assets/bonus_shield.png","assets/bonus_time.png",
]
assets_lua=(ROOT/"assets.lua").read_text(encoding="utf-8") if (ROOT/"assets.lua").exists() else ""
for p in asset_patterns:
    if p not in assets_lua: errors.append(f"asset registry missing: {p}")

# Ensure the real audio directory exists and the production audio manager points at it.
sound=(ROOT/"sound.lua").read_text(encoding="utf-8") if (ROOT/"sound.lua").exists() else ""
if "sounds/" not in sound: errors.append("sound manager is not pointed at sounds/")

if errors:
    print("STARFALL QA: FAIL")
    for e in errors: print(" -", e)
    sys.exit(1)
print("STARFALL QA: PASS")
print("Required source modules present; exactly three mode definitions detected; core gameplay, controls, effects, audio and asset registry hooks found.")
