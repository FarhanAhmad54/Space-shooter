# Starfall Vengeance production release gate

1. `python3 tools/qa.py` must pass.
2. `python3 tools/release_check.py` must pass.
3. `tools/package_love.sh` must create a valid `Starfall-Vengeance.love` archive.
4. The native `.love` archive must be tested with LÖVE 11.5 on desktop before release.
5. A web build must provide the generated `love.js` bundle expected by `web/index.html`.
6. Browser QA must verify loading, input, resize, audio, pause, mode selection and game-over/restart flows.
7. Portal-specific SDK/advertising/leaderboard integration must be validated in each portal's own inspector before submission.

The production branch remains separate from `main` until these gates are satisfied.
