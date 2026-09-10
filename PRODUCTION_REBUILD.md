# Starfall Vengeance — Production Rebuild

This branch contains the integrated production source.

## Exactly three modes

1. Campaign — 30 structured waves with boss gates, elites, combo scoring, XP and permanent upgrades.
2. Endless — infinite adaptive pressure with escalating density, elites and periodic bosses.
3. Gauntlet — 8 timed trials with distinct combat mutators and a final boss-pressure trial.

## Integrated systems

- Repository ship, enemy, pet, planet, star, lighting, noise, projectile and bonus artwork through `assets.lua`.
- Repository `sounds/` SFX through `sound.lua` with variant selection and missing-file safety.
- Four standard weapons available at run start: pistol, shotgun, machine gun and sniper.
- Temporary homing, explosive, shield, rapid-fire and other power-up effects.
- XP levels and permanent run upgrades, including drones, piercing, damage, fire-rate and mobility upgrades.
- Combo multiplier, elite high-value targets, lives, dash, enemy projectiles and boss radial attacks.
- Persistent profile score/stars/game-count statistics.
- Desktop controls and mobile dual virtual joysticks.
- Sound/music/quality settings.
- Native LÖVE packaging helpers and a web host/platform bridge.

## Release verification

The source integration is complete. A real native LÖVE 11.5 run and a real generated love.js/browser run are still required for final release certification; these cannot be truthfully simulated by repository inspection. Validate menu navigation, all three modes, progression, bosses, power-ups, drones, lives, dash, pause/resume, persistence, touch input, audio and browser startup before public portal submission.
