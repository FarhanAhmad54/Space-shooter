# Starfall Vengeance — Production Rebuild

## Game modes

### 1. Campaign
30 curated waves. Enemy health, speed, composition and elite pressure rise in controlled steps. Boss gates occur every six waves. Weapon unlocks and permanent run upgrades create a readable power curve.

### 2. Endless
Infinite waves. Spawn density, enemy health, movement speed and elite probability continuously increase with a hard cap on pressure. Score is weighted above Campaign so survival and combo mastery are rewarded.

### 3. Gauntlet
Eight 90-second trials. Every trial has a distinct combat mutator: Overdrive, Bullet Hell, Iron Core, Crossfire, Swarm, Glass Cannon, Blackout and Final Lock. Clearing a trial advances immediately and awards a larger score/XP multiplier.

## Core loop

Move -> aim -> fire -> dodge -> build combo -> collect power-ups -> level up -> choose an upgrade -> adapt weapon -> clear wave/trial -> chase a higher score.

## Production rules

* Exactly three player-facing modes.
* No mode-specific external dependencies.
* Missing optional audio/visual assets fail soft instead of preventing boot.
* Audio is loaded from the repository's `sounds/` directory.
* Visuals are centralized through `assets.lua`.
* LÖVE target is 11.5.
* The game does not require a portal SDK to boot.
* Portal monetization hooks remain isolated from gameplay code.

## QA gate

Before publishing, run the game with LÖVE 11.5 on desktop, then run the web build in a local HTTP server. Test first boot, mode selection, pause/resume, all weapons, all enemy types, level-up, power-ups, boss waves, game-over, victory, resize, keyboard input and touch input. Portal SDK integration must be tested in each portal's own preview/inspection environment.
