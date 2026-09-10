-- Starfall Vengeance production audio manager.
-- Uses the repository's real sounds/ directory. Missing optional files are silent.

local Sound = {}
Sound.__index = Sound

local groups = {
    shoot = {"laserSmall_000.ogg","laserSmall_001.ogg","laserSmall_002.ogg","laserSmall_003.ogg","laserSmall_004.ogg","laser1.ogg","laser2.ogg","laser3.ogg","laser4.ogg","laser5.ogg"},
    heavyShoot = {"laserLarge_000.ogg","laserLarge_001.ogg","laserLarge_002.ogg","laserLarge_003.ogg","laserLarge_004.ogg","laser6.ogg","laser7.ogg","laser8.ogg","laser9.ogg"},
    retroShoot = {"laserRetro_000.ogg","laserRetro_001.ogg","laserRetro_002.ogg","laserRetro_003.ogg","laserRetro_004.ogg"},
    hit = {"impactMetal_000.ogg","impactMetal_001.ogg","impactMetal_002.ogg","impactMetal_003.ogg","impactMetal_004.ogg","hit.wav"},
    explosion = {"explosionCrunch_000.ogg","explosionCrunch_001.ogg","explosionCrunch_002.ogg","explosionCrunch_003.ogg","explosionCrunch_004.ogg","explosion.mp3"},
    shield = {"forceField_000.ogg","forceField_001.ogg","forceField_002.ogg","forceField_003.ogg","forceField_004.ogg"},
    menu = {"computerNoise_000.ogg","computerNoise_001.ogg","computerNoise_002.ogg","computerNoise_003.ogg","doorOpen_000.ogg","doorOpen_001.ogg","doorOpen_002.ogg"},
    menuClose = {"doorClose_000.ogg","doorClose_001.ogg","doorClose_002.ogg"},
    engine = {"engineCircular_000.ogg","engineCircular_001.ogg","engineCircular_002.ogg","engineCircular_003.ogg","engineCircular_004.ogg"},
    highUp = {"highUp.ogg"},
    highDown = {"highDown.ogg"},
    levelup = {"levelup.mp3"},
    death = {"death.wav"},
}

function Sound.new()
    local self = setmetatable({}, Sound)
    self.soundEnabled = true
    self.musicEnabled = true
    self.soundVolume = 0.72
    self.musicVolume = 0.45
    self.sounds = {}
    self.lastVariant = {}
    self.music = nil
    self.musicStarted = false
    self:loadAudio()
    return self
end

function Sound:tryLoad(path, kind)
    local ok, source = pcall(love.audio.newSource, path, kind or "static")
    if ok and source then return source end
    return nil
end

function Sound:loadAudio()
    for name, files in pairs(groups) do
        self.sounds[name] = {}
        for _, file in ipairs(files) do
            local source = self:tryLoad("sounds/" .. file, "static")
            if source then self.sounds[name][#self.sounds[name] + 1] = source end
        end
    end
    -- Optional legacy music. Streaming avoids loading a long track into memory.
    self.music = self:tryLoad("sounds/music.mp3", "stream")
    if self.music then self.music:setLooping(true) end
end

function Sound:playSound(name, volumeMultiplier)
    if not self.soundEnabled then return false end
    local variants = self.sounds[name]
    if not variants or #variants == 0 then return false end
    local index = math.random(#variants)
    if #variants > 1 and index == self.lastVariant[name] then index = index % #variants + 1 end
    self.lastVariant[name] = index
    local source = variants[index]
    local clone = source:clone()
    clone:setVolume(math.max(0, math.min(1, self.soundVolume * (volumeMultiplier or 1))))
    clone:play()
    return true
end

function Sound:playMusic()
    if not self.musicEnabled or not self.music then return false end
    self.music:setVolume(self.musicVolume)
    if not self.music:isPlaying() then self.music:play() end
    self.musicStarted = true
    return true
end

function Sound:stopMusic()
    if self.music then self.music:stop() end
    self.musicStarted = false
end

function Sound:toggleSound() self.soundEnabled = not self.soundEnabled end
function Sound:toggleMusic()
    self.musicEnabled = not self.musicEnabled
    if self.musicEnabled then self:playMusic() else self:stopMusic() end
end
function Sound:setSoundVolume(v) self.soundVolume = math.max(0, math.min(1, tonumber(v) or 0.7)) end
function Sound:setMusicVolume(v)
    self.musicVolume = math.max(0, math.min(1, tonumber(v) or 0.5))
    if self.music then self.music:setVolume(self.musicVolume) end
end
function Sound:hasSound(name) return self.sounds[name] and #self.sounds[name] > 0 or false end
function Sound:getSettings()
    return {soundEnabled=self.soundEnabled,musicEnabled=self.musicEnabled,soundVolume=self.soundVolume,musicVolume=self.musicVolume}
end
return Sound
