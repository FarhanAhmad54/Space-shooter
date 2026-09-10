# Starfall Vengeance

A LÖVE 11.5 arcade space shooter rebuilt around exactly three player-facing modes.

## Modes

**CAMPAIGN** — 30 escalating waves with boss gates and a full completion goal.

**ENDLESS** — infinite adaptive pressure with escalating density, elites and periodic bosses.

**GAUNTLET** — 8 timed trials with rotating combat mutators and a final boss-pressure trial.

## Core gameplay

Aim and fire, chain kills to grow the combo multiplier, collect temporary power-ups, level up into permanent run upgrades, and deploy attack/orbit drones. The runtime centralizes the repository artwork and the real `sounds/` SFX through dedicated loaders.

## Controls

Desktop: WASD/arrow keys to move, mouse to aim/fire, Space to dash, 1–4 to switch weapons, Esc to pause.

Mobile: dual virtual joysticks; the right joystick handles aim and fires when pushed outward.

## Production

Run with **LÖVE 11.5**. The `web/` directory contains the host shell and defensive portal bridge used around a generated love.js build. Before a portal release, validate the native build and browser build on real runtimes.
