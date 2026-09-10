Starfall Vengeance — Production Rebuild

Entry point: main.lua
Target runtime: LÖVE 11.5.

Exactly three player-facing modes:
- Campaign: 30 waves with boss gates.
- Endless: infinite adaptive pressure.
- Gauntlet: 8 timed mutator trials.

Runtime media comes from the repository's real assets/ and sounds/ directories through assets.lua and sound.lua. Desktop and mobile input are supported through main.lua + touchcontrols.lua.

Before publishing a portal build, run the complete project on native LÖVE 11.5 and validate the generated love.js build in a browser. The web folder provides the host shell and defensive platform bridge.
