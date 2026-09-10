-- AI Director Module
-- Dynamically adjusts game difficulty based on player performance

local AIDirector = {}
AIDirector.__index = AIDirector

function AIDirector.new()
    local self = setmetatable({}, AIDirector)
    
    -- Performance metrics
    self.metrics = {
        shotsFired = 0,
        shotsHit = 0,
        damageTaken = 0,
        damageDealt = 0,
        kills = 0,
        combo = 0,
        survivalTime = 0
    }
    
    -- Recent history (last 10 seconds)
    self.recentDamage = 0
    self.recentKills = 0
    self.damageHistory = {}
    self.killHistory = {}
    
    -- AI state
    self.playerState = "normal"  -- "struggling", "normal", "dominating"
    self.performanceScore = 0.5
    self.difficultyMultiplier = 1.0
    self.targetDifficultyMultiplier = 1.0
    self.enabled = true
    self.quality = "high"
    self.gracePeriod = 8
    
    -- Spawn timers
    self.eliteSpawnTimer = 0
    self.eliteSpawnDelay = 15.0
    self.powerupSpawnTimer = 0
    self.powerupSpawnDelay = 8.0
    
    -- Thresholds
    self.strugglingThreshold = 0.3
    self.dominatingThreshold = 0.7
    
    return self
end

function AIDirector:setQuality(quality)
    if quality == "low" or quality == "medium" or quality == "high" then self.quality = quality end
end

function AIDirector:setEnabled(enabled)
    self.enabled = enabled ~= false
end

function AIDirector:reset()
    self.metrics = {shotsFired=0, shotsHit=0, damageTaken=0, damageDealt=0, kills=0, combo=0, survivalTime=0}
    self.recentDamage, self.recentKills = 0, 0
    self.damageHistory, self.killHistory = {}, {}
    self.playerState, self.performanceScore = "normal", 0.5
    self.difficultyMultiplier, self.targetDifficultyMultiplier = 1.0, 1.0
    self.eliteSpawnTimer, self.powerupSpawnTimer = 0, 0
end

function AIDirector:update(dt, player, enemies, wave)
    if not self.enabled or not player then return end
    self.metrics.survivalTime = self.metrics.survivalTime + dt
    
    -- Update timers
    self.eliteSpawnTimer = self.eliteSpawnTimer + dt
    self.powerupSpawnTimer = self.powerupSpawnTimer + dt
    
    -- Update damage history (only keep last 10 seconds)
    for i = #self.damageHistory, 1, -1 do
        self.damageHistory[i].time = self.damageHistory[i].time + dt
        if self.damageHistory[i].time > 10.0 then
            table.remove(self.damageHistory, i)
        end
    end
    
    -- Update kill history (only keep last 10 seconds)
    for i = #self.killHistory, 1, -1 do
        self.killHistory[i].time = self.killHistory[i].time + dt
        if self.killHistory[i].time > 10.0 then
            table.remove(self.killHistory, i)
        end
    end
    
    -- Calculate recent metrics
    self.recentDamage = 0
    for _, entry in ipairs(self.damageHistory) do
        self.recentDamage = self.recentDamage + entry.amount
    end
    
    self.recentKills = #self.killHistory
    
    -- Calculate performance score
    self:calculatePerformance(player, wave)
    
    -- Determine player state
    self:updatePlayerState(player)
    
    -- Adjust difficulty multiplier
    self:updateDifficultyMultiplier(wave)
end

function AIDirector:calculatePerformance(player, wave)
    -- Health score (0-1)
    local healthScore = math.max(0, math.min(1, (player.health or 0) / math.max(1, player.maxHealth or 1)))
    
    -- Accuracy score (0-1)
    local accuracyScore = 0.5  -- Default if no shots fired
    if self.metrics.shotsFired > 0 then
        accuracyScore = math.min(1.0, self.metrics.shotsHit / self.metrics.shotsFired)
    end
    
    -- Kill rate score (0-1)
    -- Expect roughly 0.5 kills per second at normal difficulty
    local expectedKillRate = 0.3 + (wave * 0.05)
    local actualKillRate = self.recentKills / 10.0  -- kills per second in last 10s
    local killRateScore = math.min(1.0, actualKillRate / expectedKillRate)
    
    -- Damage mitigation score (0-1)
    -- Lower recent damage = better score
    local expectedDamage = 6.0  -- Expected to take some damage
    local damageScore = math.max(0, 1.0 - (self.recentDamage / expectedDamage))
    
    -- Weighted performance score
    self.performanceScore = (healthScore * 0.3) + 
                           (accuracyScore * 0.2) + 
                           (killRateScore * 0.3) + 
                           (damageScore * 0.2)
    
    -- Clamp to 0-1
    self.performanceScore = math.max(0, math.min(1, self.performanceScore))
end

function AIDirector:updatePlayerState(player)
    if self.performanceScore < self.strugglingThreshold then
        self.playerState = "struggling"
    elseif self.performanceScore > self.dominatingThreshold then
        self.playerState = "dominating"
    else
        self.playerState = "normal"
    end
end

function AIDirector:updateDifficultyMultiplier(wave)
    local baseDifficulty = 1.0 + (math.max(1, wave or 1) * 0.045)
    local target = baseDifficulty
    if self.playerState == "struggling" then
        target = baseDifficulty * 0.72
    elseif self.playerState == "dominating" then
        target = baseDifficulty * 1.18
    end
    self.targetDifficultyMultiplier = target
    local smoothing = 0.12
    self.difficultyMultiplier = self.difficultyMultiplier + (target - self.difficultyMultiplier) * smoothing
    if self.metrics.survivalTime < self.gracePeriod then
        self.difficultyMultiplier = math.min(self.difficultyMultiplier, 1.0 + (math.max(1,wave or 1) * 0.02))
    end
end

function AIDirector:shouldSpawnElite()
    -- Don't spawn elites if player is struggling
    if self.playerState == "struggling" or self.metrics.survivalTime < self.gracePeriod then
        return false
    end
    
    -- Check if enough time has passed
    local adaptiveDelay = self.eliteSpawnDelay
    if self.playerState == "dominating" then adaptiveDelay = adaptiveDelay * 0.75 end
    if self.eliteSpawnTimer < adaptiveDelay then
        return false
    end
    
    -- Adjust spawn chance based on performance
    local spawnChance = 0.3  -- Base 30% chance
    if self.playerState == "dominating" then
        spawnChance = 0.7  -- 70% chance when dominating
    end
    
    if math.random() < spawnChance then
        self.eliteSpawnTimer = 0
        return true
    end
    
    return false
end

function AIDirector:shouldSpawnPowerup()
    if self.powerupSpawnTimer < self.powerupSpawnDelay then
        return false
    end
    
    self.powerupSpawnTimer = 0
    return true
end

function AIDirector:getRecommendedPowerup()
    -- Smart power-up selection based on player state
    local powerupTypes = {
        defensive = {"health", "shield", "armor"},
        offensive = {"damage", "rapidfire", "multishot", "green_bullet", "blue_bullet"},
        utility = {"speed", "magnet", "xpboost"}
    }
    
    if self.playerState == "struggling" then
        -- Prioritize defensive power-ups
        local choice = math.random()
        if choice < 0.6 then
            return powerupTypes.defensive[math.random(#powerupTypes.defensive)]
        elseif choice < 0.9 then
            return powerupTypes.utility[math.random(#powerupTypes.utility)]
        else
            return powerupTypes.offensive[math.random(#powerupTypes.offensive)]
        end
    elseif self.playerState == "dominating" then
        -- Prioritize offensive power-ups
        local choice = math.random()
        if choice < 0.6 then
            return powerupTypes.offensive[math.random(#powerupTypes.offensive)]
        elseif choice < 0.9 then
            return powerupTypes.utility[math.random(#powerupTypes.utility)]
        else
            return powerupTypes.defensive[math.random(#powerupTypes.defensive)]
        end
    else
        -- Balanced distribution
        local category = math.random(3)
        if category == 1 then
            return powerupTypes.defensive[math.random(#powerupTypes.defensive)]
        elseif category == 2 then
            return powerupTypes.offensive[math.random(#powerupTypes.offensive)]
        else
            return powerupTypes.utility[math.random(#powerupTypes.utility)]
        end
    end
end

-- Metrics tracking functions
function AIDirector:recordShot()
    self.metrics.shotsFired = self.metrics.shotsFired + 1
end

function AIDirector:recordHit()
    self.metrics.shotsHit = self.metrics.shotsHit + 1
end

function AIDirector:recordDamage(amount)
    self.metrics.damageTaken = self.metrics.damageTaken + amount
    table.insert(self.damageHistory, {amount = amount, time = 0})
end

function AIDirector:recordKill(enemy)
    self.metrics.kills = self.metrics.kills + 1
    table.insert(self.killHistory, {time = 0})
end

function AIDirector:recordDamageDealt(amount)
    self.metrics.damageDealt = self.metrics.damageDealt + amount
end

function AIDirector:setCombo(combo)
    self.metrics.combo = combo
end

-- Getters
function AIDirector:getPlayerState()
    return self.playerState
end

function AIDirector:getPerformanceScore()
    return self.performanceScore
end

function AIDirector:getDifficultyMultiplier()
    return self.difficultyMultiplier
end

function AIDirector:getMetrics()
    return {
        accuracy = self.metrics.shotsFired > 0 and (self.metrics.shotsHit / self.metrics.shotsFired) or 0,
        kills = self.metrics.kills,
        survivalTime = self.metrics.survivalTime,
        recentKills = self.recentKills,
        recentDamage = self.recentDamage,
        performanceScore = self.performanceScore,
        playerState = self.playerState
    }
end

return AIDirector
