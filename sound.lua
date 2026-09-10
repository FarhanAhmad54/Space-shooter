-- Starfall Vengeance production audio manager.
-- Uses the repository's real sounds/ directory. Missing optional files are silent.
local Sound={}; Sound.__index=Sound
local groups={
 shoot={"laserSmall_000.ogg","laserSmall_001.ogg","laserSmall_002.ogg","laserSmall_003.ogg","laserSmall_004.ogg","laser1.ogg","laser2.ogg","laser3.ogg","laser4.ogg","laser5.ogg"},
 heavyShoot={"laserLarge_000.ogg","laserLarge_001.ogg","laserLarge_002.ogg","laserLarge_003.ogg","laserLarge_004.ogg","laser6.ogg","laser7.ogg","laser8.ogg","laser9.ogg"},
 retroShoot={"laserRetro_000.ogg","laserRetro_001.ogg","laserRetro_002.ogg","laserRetro_003.ogg","laserRetro_004.ogg"},
 hit={"impactMetal_000.ogg","impactMetal_001.ogg","impactMetal_002.ogg","impactMetal_003.ogg","impactMetal_004.ogg","hit.wav"},
 explosion={"explosionCrunch_000.ogg","explosionCrunch_001.ogg","explosionCrunch_002.ogg","explosionCrunch_003.ogg","explosionCrunch_004.ogg","explosion.mp3"},
 shield={"forceField_000.ogg","forceField_001.ogg","forceField_002.ogg","forceField_003.ogg","forceField_004.ogg"},
 menu={"computerNoise_000.ogg","computerNoise_001.ogg","computerNoise_002.ogg","computerNoise_003.ogg","doorOpen_000.ogg","doorOpen_001.ogg","doorOpen_002.ogg"},
 menuClose={"doorClose_000.ogg","doorClose_001.ogg","doorClose_002.ogg"},
 engine={"engineCircular_000.ogg","engineCircular_001.ogg","engineCircular_002.ogg","engineCircular_003.ogg","engineCircular_004.ogg"},
 highUp={"highUp.ogg"},highDown={"highDown.ogg"},levelup={"levelup.mp3"},death={"death.wav"}
}
function Sound.new()
 local s=setmetatable({},Sound); s.soundEnabled=true; s.musicEnabled=true; s.soundVolume=.72; s.musicVolume=.45; s.sounds={}; s.lastVariant={}; s.music=nil; s:loadAudio(); return s
end
function Sound:tryLoad(path,kind) local ok,src=pcall(love.audio.newSource,path,kind or "static"); return ok and src or nil end
function Sound:loadAudio()
 for name,files in pairs(groups) do self.sounds[name]={}; for _,file in ipairs(files) do local src=self:tryLoad("sounds/"..file,"static"); if src then self.sounds[name][#self.sounds[name]+1]=src end end end
 self.music=self:tryLoad("sounds/music.mp3","stream"); if self.music then self.music:setLooping(true) end
end
function Sound:playSound(name,mult)
 if not self.soundEnabled then return false end; local v=self.sounds[name]; if not v or #v==0 then return false end
 local i=math.random(#v); if #v>1 and i==self.lastVariant[name] then i=i%#v+1 end; self.lastVariant[name]=i; local src=v[i]:clone(); src:setVolume(math.max(0,math.min(1,self.soundVolume*(mult or 1)))); src:play(); return true
end
function Sound:playMusic() if not self.musicEnabled or not self.music then return false end; self.music:setVolume(self.musicVolume); if not self.music:isPlaying() then self.music:play() end; return true end
function Sound:stopMusic() if self.music then self.music:stop() end end
function Sound:toggleSound() self.soundEnabled=not self.soundEnabled end
function Sound:toggleMusic() self.musicEnabled=not self.musicEnabled; if self.musicEnabled then self:playMusic() else self:stopMusic() end end
function Sound:setSoundVolume(v) self.soundVolume=math.max(0,math.min(1,tonumber(v) or .7)) end
function Sound:setMusicVolume(v) self.musicVolume=math.max(0,math.min(1,tonumber(v) or .5)); if self.music then self.music:setVolume(self.musicVolume) end end
function Sound:hasSound(name) return self.sounds[name] and #self.sounds[name]>0 or false end
function Sound:getSettings() return {soundEnabled=self.soundEnabled,musicEnabled=self.musicEnabled,soundVolume=self.soundVolume,musicVolume=self.musicVolume} end
return Sound
