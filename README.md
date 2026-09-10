# Starfall Vengeance

A LÖVE 11.5 arcade space shooter rebuilt around exactly three player-facing modes.

## Modes

**CAMPAIGN** — 30 escalating waves with boss gates and a full completion goal.

**ENDLESS** — infinite adaptive pressure, escalating density, elites and periodic bosses.

**GAUNTLET** — 8 timed trials with rotating mutators and a final boss-pressure trial.

## Core loop

Aim and fire, build combo multipliers, collect temporary power-ups, level up into permanent run upgrades, and add attack/orbit drones. The game uses the repository artwork, planets, stars, lights, noise layers, ship/enemy/pet sprites, and the real `sounds/` SFX library through centralized loaders.

## Controls

Desktop: WASD/arrow keys to move, mouse to aim/fire, Space to dash, 1–4 to switch weapons, Esc to pause.

Mobile: dual virtual joysticks; the right aim joystick also controls automatic firing when pushed fully outward.

## Project layout

`main.lua` is the gameplay state machine. `modes.lua` owns the three mode rules. `assets.lua` and `sound.lua` centralize media loading. `bullet.lua`, `enemy.lua`, `player.lua`, `drone.lua`, `powerup.lua`, and `xp.lua` provide the combat systems. `web/` contains the portal shell and platform bridge used around a generated love.js build.

## Build

Run the project with **LÖVE 11.5**. For web deployment, generate a love.js/WebGL build containing this project's complete source, `assets/`, and `sounds/`, then use `web/index.html` as the host shell. The platform bridge is intentionally defensive and becomes active only when the host SDK is present.

## Production QA gate

Before portal submission, test a clean native LÖVE 11.5 build, verify all asset paths, play through wave transitions in all three modes, verify level-up choices, power-ups, drones, dash, pause/resume, mobile touch input, persistence, and browser builds. Native/browser runtime verification must be performed on an actual LÖVE/love.js runtime; repository-side code inspection alone is not a substitute.
