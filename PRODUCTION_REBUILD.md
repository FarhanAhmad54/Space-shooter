# Starfall Vengeance — Production Rebuild

This branch is the final integration branch for the arcade rebuild.

## Exactly three modes

1. Campaign — 30-wave structured campaign with boss gates, elites, combos, XP, upgrades and victory state.
2. Endless — infinite adaptive survival with increasing density, health, speed, elite pressure and periodic bosses.
3. Gauntlet — 8 timed trials with unique mutators and a final boss-pressure trial.

## Integrated systems

- Centralized asset loading for ship, enemy, pet, planet, star, lighting, noise, projectile and bonus artwork.
- Real repository sounds/ SFX with grouped variants and safe missing-file handling.
- Pistol, shotgun, machine gun and sniper combat plus temporary homing/explosive modifiers.
- XP progression and permanent upgrade choices.
- Combo scoring, elite rewards, power-ups, drones, dash, enemy projectiles and boss radial attacks.
- Persistent profile statistics and star rewards.
- Desktop mouse/keyboard input plus mobile dual-joystick input.
- Settings for sound, music and rendering quality.
- Native LÖVE packaging helpers and web host shell.

## QA gate

Run the project with LÖVE 11.5 and validate a real browser build before publishing. Repository inspection is not a substitute for runtime testing. Test menu navigation, all three modes, wave/trial progression, boss encounters, upgrade flow, power-ups, drones, dash, pause/resume, persistence, mobile touch controls, audio, and browser startup.
