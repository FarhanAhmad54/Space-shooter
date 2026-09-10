from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
errors = []
required = [
    "main.lua","conf.lua","assets.lua","modes.lua","player.lua","enemy.lua",
    "bullet.lua","weapons.lua","powerup.lua","xp.lua","drone.lua","particles.lua",
    "effects.lua","sound.lua","profile.lua","touchcontrols.lua"
]
for name in required:
    if not (ROOT/name).is_file():
        errors.append(f"missing required source: {name}")

main = (ROOT/"main.lua").read_text(encoding="utf-8") if (ROOT/"main.lua").exists() else ""
modes = (ROOT/"modes.lua").read_text(encoding="utf-8") if (ROOT/"modes.lua").exists() else ""
player = (ROOT/"player.lua").read_text(encoding="utf-8") if (ROOT/"player.lua").exists() else ""
enemy = (ROOT/"enemy.lua").read_text(encoding="utf-8") if (ROOT/"enemy.lua").exists() else ""
weapons = (ROOT/"weapons.lua").read_text(encoding="utf-8") if (ROOT/"weapons.lua").exists() else ""
assets_lua = (ROOT/"assets.lua").read_text(encoding="utf-8") if (ROOT/"assets.lua").exists() else ""
sound = (ROOT/"sound.lua").read_text(encoding="utf-8") if (ROOT/"sound.lua").exists() else ""
xp = (ROOT/"xp.lua").read_text(encoding="utf-8") if (ROOT/"xp.lua").exists() else ""

mode_ids = re.findall(r'id="(campaign|endless|gauntlet)"', modes)
if sorted(set(mode_ids)) != ["campaign","endless","gauntlet"]:
    errors.append(f"mode registry invalid: {sorted(set(mode_ids))}")
if len(re.findall(r'^\s*\w+\s*=\s*\{id=', modes, re.M)) != 3:
    errors.append("modes.lua must expose exactly three mode definitions")

for needle in [
    'require("touchcontrols")','Assets.load()','Modes.waveRules(run)','XP.addXP(xpData',
    'Particles','Effects','Sound.new()','Modes.nextGauntletTrial(run)'
]:
    if needle not in main and needle not in modes:
        errors.append(f"integration missing: {needle}")

asset_patterns = [
    "assets/SpaceShip.png","assets/bg.png","assets/Stars-A.png","assets/Stars-B.png",
    "assets/SWARMERS.png","assets/SNIPERS.png","assets/BOMBERS.png","assets/TURRET DRONES.png","assets/MINI-BOSSES.png",
    "assets/bullet.png","assets/bullet-1.png","assets/bullet-2.png","assets/laser-1.png","assets/laser-2.png","assets/laser-3.png",
    "assets/plasm.png","assets/rocket.png","assets/shield.png","assets/fire.png",
    "assets/bonus_life.png","assets/bonus_shield.png","assets/bonus_time.png"
]
for p in asset_patterns:
    if p not in assets_lua:
        errors.append(f"asset registry missing: {p}")

if "sounds/" not in sound:
    errors.append("sound manager is not pointed at sounds/")

source = player + enemy + weapons
critical_hooks = {
    "rapid-fire timer": 'previous.rapidfire > 0',
    "damage boost timer": 'previous.damage > 0',
    "multi-shot timer": 'previous.multishot > 0',
    "armor mitigation": 'self.powerups.armor > 0',
    "time slow state": '__SV_TIME_SCALE',
    "enemy time scaling": 'dt=dt*(_G.__SV_TIME_SCALE or 1)',
    "weapon auto reload": 'autoReload=true',
    "weapon ammo refill": 'd.autoReload'
}
for label, needle in critical_hooks.items():
    if needle not in source:
        errors.append(f"gameplay hook missing: {label}")

for needle in ['id="firerate"','id="damage"','id="multishot"','id="piercing"','id="dronedamage"']:
    if needle not in xp:
        errors.append(f"persistent upgrade missing: {needle}")

if errors:
    print("STARFALL QA: FAIL")
    for e in errors:
        print(" -", e)
    sys.exit(1)

print("STARFALL QA: PASS")
print("Required source modules present; exactly three player-facing modes detected; core runtime, effects, controls, audio, assets, timed power-ups, time-slow, armor and weapon recovery hooks verified.")
