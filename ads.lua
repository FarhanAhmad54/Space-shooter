-- Poki/CrazyGames integration hook points.
-- These are intentionally no-op until platform SDK integration is added.
local Ads = {}
Ads.enabled = false
function Ads.onGameStart() end
function Ads.onWaveComplete(wave) end
function Ads.onGameOver(score) end
function Ads.onRewardedAd() return false end
function Ads.onGamePause() end
function Ads.onGameResume() end
return Ads
