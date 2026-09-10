-- Sound Manager with Kenney sci-fi sounds integration
-- Uses Kenney's sci-fi sound pack for high-quality audio

local Sound = {}
Sound.__index = Sound

function Sound.new()
    local self = setmetatable({}, Sound)
    
    -- Settings
    self.soundEnabled = true
    self.musicEnabled = true
    self.soundVolume = 0.7
    self.musicVolume = 0.5
    
    -- Sound effects storage (each key maps to an array of variants)
    self.sounds = {}
    self.music = nil
    
    -- Try to load audio files
    self:loadAudio()
    
    return self
end

function Sound:tryLoadSound(path, sourceType)
    sourceType = sourceType or "static"
    local success, result = pcall(function()
        return love.audio.newSource(path, sourceType)
    end)
    if success then
        return result
    end
    return nil
end

function Sound:loadAudio()
    local kSfx = "assets/kenney_sci-fi-sounds/Audio/"
    local origSounds = "sounds/"
    
    -- Load sound variants (Kenney sci-fi sounds with fallback to originals)
    -- Each sound can have multiple variants for randomization
    self.sounds = {
        shoot = {
            self:tryLoadSound(kSfx .. "laserSmall_000.ogg"),
            self:tryLoadSound(kSfx .. "laserSmall_001.ogg"),
            self:tryLoadSound(kSfx .. "laserSmall_002.ogg"),
            self:tryLoadSound(kSfx .. "laserSmall_003.ogg"),
            self:tryLoadSound(kSfx .. "laserSmall_004.ogg"),
        },
        hit = {
            self:tryLoadSound(kSfx .. "impactMetal_000.ogg"),
            self:tryLoadSound(kSfx .. "impactMetal_001.ogg"),
            self:tryLoadSound(kSfx .. "impactMetal_002.ogg"),
            self:tryLoadSound(kSfx .. "impactMetal_003.ogg"),
            self:tryLoadSound(kSfx .. "impactMetal_004.ogg"),
        },
        explosion = {
            self:tryLoadSound(kSfx .. "explosionCrunch_001.ogg"),
            self:tryLoadSound(kSfx .. "explosionCrunch_002.ogg"),
            self:tryLoadSound(kSfx .. "explosionCrunch_003.ogg"),
        },
        playerHit = {
            self:tryLoadSound(kSfx .. "impactMetal_003.ogg"),
            self:tryLoadSound(kSfx .. "impactMetal_004.ogg"),
        },
        powerup = {
            self:tryLoadSound(kSfx .. "forceField_000.ogg"),
            self:tryLoadSound(kSfx .. "forceField_001.ogg"),
        },
        waveComplete = {
            self:tryLoadSound(kSfx .. "forceField_003.ogg"),
        },
        levelup = {
            self:tryLoadSound(kSfx .. "forceField_002.ogg"),
        },
        death = {
            self:tryLoadSound(kSfx .. "explosionCrunch_004.ogg"),
            self:tryLoadSound(kSfx .. "lowFrequency_explosion_001.ogg"),
        },
        dash = {
            self:tryLoadSound(kSfx .. "laserLarge_002.ogg"),
            self:tryLoadSound(kSfx .. "laserLarge_003.ogg"),
        },
        bossSpawn = {
            self:tryLoadSound(kSfx .. "lowFrequency_explosion_000.ogg"),
        },
    }
    
    -- Remove nil entries from arrays (failed loads)
    for name, variants in pairs(self.sounds) do
        local cleaned = {}
        for _, s in ipairs(variants) do
            if s then
                table.insert(cleaned, s)
            end
        end
        self.sounds[name] = cleaned
    end
    
    -- Fallback: if Kenney sounds not found, try original sounds
    local fallbackMap = {
        shoot = origSounds .. "shoot.mp3",
        hit = origSounds .. "hit.wav",
        playerHit = origSounds .. "playerHit.mp3",
        explosion = origSounds .. "explosion.mp3",
        waveComplete = origSounds .. "waveComplete.mp3",
        levelup = origSounds .. "levelup.mp3",
        death = origSounds .. "death.wav",
        powerup = origSounds .. "powerup.wav",
    }
    
    for name, path in pairs(fallbackMap) do
        if #self.sounds[name] == 0 then
            local snd = self:tryLoadSound(path)
            if snd then
                self.sounds[name] = {snd}
                print("Loaded fallback sound: " .. name)
            else
                print("Sound not found: " .. name .. " (will be silent)")
            end
        else
            print("Loaded " .. #self.sounds[name] .. " variants for: " .. name)
        end
    end
    
    -- Try to load background music
    self.music = self:tryLoadSound(origSounds .. "music.mp3", "stream")
    if self.music then
        self.music:setLooping(true)
        print("Loaded music")
    else
        print("Music not found (will be silent)")
    end
end

function Sound:playSound(soundName)
    if not self.soundEnabled then return false end

    local variants = self.sounds[soundName]
    if not variants or #variants == 0 then return false end

    self.lastVariant = self.lastVariant or {}
    local index = math.random(#variants)
    if #variants > 1 then
        while index == self.lastVariant[soundName] do index = math.random(#variants) end
    end
    self.lastVariant[soundName] = index

    local source = variants[index]
    if not source then return false end
    local clone = source:clone()
    clone:setVolume(self.soundVolume)
    clone:play()
    return true
end

function Sound:playMusic()
    if self.musicEnabled and self.music then
        self.music:setVolume(self.musicVolume)
        self.music:play()
    end
end

function Sound:stopMusic()
    if self.music then
        self.music:stop()
    end
end

function Sound:toggleSound()
    self.soundEnabled = not self.soundEnabled
end

function Sound:toggleMusic()
    self.musicEnabled = not self.musicEnabled
    
    if self.musicEnabled then
        self:playMusic()
    else
        self:stopMusic()
    end
end

function Sound:setSoundVolume(volume)
    self.soundVolume = math.max(0, math.min(1, volume))
end

function Sound:setMusicVolume(volume)
    self.musicVolume = math.max(0, math.min(1, volume))
    if self.music then
        self.music:setVolume(self.musicVolume)
    end
end

function Sound:hasSound(name)
    return self.sounds[name] ~= nil and #self.sounds[name] > 0
end

function Sound:hasSound(soundName)
    return self.sounds[soundName] ~= nil and #self.sounds[soundName] > 0
end

function Sound:getSettings()
    return {
        soundEnabled = self.soundEnabled,
        musicEnabled = self.musicEnabled,
        soundVolume = self.soundVolume,
        musicVolume = self.musicVolume
    }
end

return Sound
