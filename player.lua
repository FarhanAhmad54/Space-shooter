-- Player module with image support

local util = require("util")

local Player = {}
Player.__index = Player

function Player.new(x, y)
    local self = setmetatable({}, Player)
    self.x = x
    self.y = y
    self.speed = 200
    self.baseSpeed = 200
    self.radius = 15
    self.health = 5
    self.maxHealth = 5
    self.shootCooldown = 0
    self.shootDelay = 0.2

    self.aimAngle = 0
    self.hasAimOverride = false

    self.dashCooldown = 0
    self.dashDelay = 2.0
    self.dashSpeed = 600
    self.dashDuration = 0.15
    self.dashTimer = 0
    self.dashDirection = {x = 0, y = 0}

    self.powerups = {
        speed = 0,
        rapidfire = 0,
        shield = 0,
        damage = 0,
        multishot = 0,
        homing = 0,
        explosive = 0,
        timeslow = 0,
        invincible = 0,
        magnet = 0,
        xpboost = 0,
        armor = 0,
        regen = 0,
        ghost = 0,
        critical = 0
    }

    self.damageFlash = 0
    self.invulnerable = false
    self.bulletColor = "yellow"

    self.fireRateMultiplier = 1.0
    self.damageMultiplier = 1.0
    self.magneticRange = 0
    self.piercingBullets = false
    self.extraProjectiles = 0
    self.hasSideDrones = false
    self.hasOrbitDrones = false
    self.hasHomingMissile = false
    self.explosionSizeMultiplier = 1.0
    self.droneDamageMultiplier = 1.0
    self.homingShotCounter = 0
    self.regenTimer = 0

    -- Temporary-effect snapshots preserve permanent XP upgrades.
    self._restoreFireRate = nil
    self._restoreDamage = nil
    self._restoreProjectiles = nil
    self._restoreMagnet = nil
    self._timeslowActive = false

    return self
end

function Player:update(dt, joystickX, joystickY, controlType)
    local previous = {}
    for name, timer in pairs(self.powerups) do
        previous[name] = timer
        if timer > 0 then
            self.powerups[name] = math.max(0, timer - dt)
        end
    end

    -- Restore temporary modifiers exactly when their timers expire.
    if previous.rapidfire > 0 and self.powerups.rapidfire <= 0 and self._restoreFireRate then
        self.fireRateMultiplier = self._restoreFireRate
        self._restoreFireRate = nil
    end
    if previous.damage > 0 and self.powerups.damage <= 0 and self._restoreDamage then
        self.damageMultiplier = self._restoreDamage
        self._restoreDamage = nil
    end
    if previous.multishot > 0 and self.powerups.multishot <= 0 and self._restoreProjectiles ~= nil then
        self.extraProjectiles = self._restoreProjectiles
        self._restoreProjectiles = nil
    end
    if previous.magnet > 0 and self.powerups.magnet <= 0 and self._restoreMagnet ~= nil then
        self.magneticRange = self._restoreMagnet
        self._restoreMagnet = nil
    end

    -- Time Slow is consumed by Enemy.update through the shared runtime scale.
    if self.powerups.timeslow > 0 then
        _G.__SV_TIME_SCALE = 0.5
        self._timeslowActive = true
    elseif self._timeslowActive then
        _G.__SV_TIME_SCALE = 1
        self._timeslowActive = false
    elseif _G.__SV_TIME_SCALE == nil then
        _G.__SV_TIME_SCALE = 1
    end

    local speedMultiplier = self.powerups.speed > 0 and 1.7 or 1.0
    self.speed = self.baseSpeed * speedMultiplier
    self.shootDelay = self.powerups.rapidfire > 0 and 0.1 or 0.2
    self.invulnerable = self.powerups.shield > 0 or self.powerups.invincible > 0 or self.powerups.ghost > 0

    if self.powerups.regen > 0 and self.health < self.maxHealth then
        self.regenTimer = self.regenTimer - dt
        if self.regenTimer <= 0 then
            self.health = math.min(self.maxHealth, self.health + 1)
            self.regenTimer = 1.5
        end
    else
        self.regenTimer = 0
    end

    if self.dashTimer > 0 then
        self.dashTimer = self.dashTimer - dt
        self.x = self.x + self.dashDirection.x * self.dashSpeed * dt
        self.y = self.y + self.dashDirection.y * self.dashSpeed * dt
    else
        local dx, dy = 0, 0
        if joystickX and (math.abs(joystickX) > 0.01 or math.abs(joystickY) > 0.01) then
            dx, dy = joystickX, joystickY
        elseif controlType ~= "mobile" then
            if love.keyboard.isDown("w") or love.keyboard.isDown("up") then dy = dy - 1 end
            if love.keyboard.isDown("s") or love.keyboard.isDown("down") then dy = dy + 1 end
            if love.keyboard.isDown("a") or love.keyboard.isDown("left") then dx = dx - 1 end
            if love.keyboard.isDown("d") or love.keyboard.isDown("right") then dx = dx + 1 end
        end
        if dx ~= 0 or dy ~= 0 then
            local length = math.sqrt(dx * dx + dy * dy)
            dx, dy = dx / length, dy / length
        end
        self.x = self.x + dx * self.speed * dt
        self.y = self.y + dy * self.speed * dt
    end

    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    self.x = math.max(self.radius, math.min(screenWidth - self.radius, self.x))
    self.y = math.max(self.radius, math.min(screenHeight - self.radius, self.y))

    if self.shootCooldown > 0 then self.shootCooldown = self.shootCooldown - dt end
    if self.dashCooldown > 0 then self.dashCooldown = self.dashCooldown - dt end
    if self.damageFlash > 0 then self.damageFlash = self.damageFlash - dt end
end

function Player:shoot(mouseX, mouseY)
    if self.shootCooldown <= 0 then
        self.shootCooldown = self.shootDelay
        return true
    end
    return false
end

function Player:dash()
    if self.dashCooldown <= 0 and self.dashTimer <= 0 then
        local mouseX, mouseY = love.mouse.getPosition()
        local angle = util.angle(self.x, self.y, mouseX, mouseY)
        self.dashDirection.x = math.cos(angle)
        self.dashDirection.y = math.sin(angle)
        self.dashTimer = self.dashDuration
        self.dashCooldown = self.dashDelay
        return true
    end
    return false
end

function Player:takeDamage(amount)
    if not self.invulnerable then
        amount = math.max(0, tonumber(amount) or 1)
        if self.powerups.armor > 0 then
            amount = amount * 0.6
        end
        self.health = math.max(0, self.health - amount)
        self.damageFlash = 0.2
        return true
    end
    return false
end

function Player:heal()
    self.health = math.min(self.health + 1, self.maxHealth)
end

function Player:applyPowerUp(powerType)
    if powerType == "health" then
        self:heal()
    elseif powerType == "speed" then
        self.powerups.speed = 5
    elseif powerType == "rapidfire" then
        if not self._restoreFireRate then self._restoreFireRate = self.fireRateMultiplier end
        self.powerups.rapidfire = 5
        self.fireRateMultiplier = self._restoreFireRate * 0.5
    elseif powerType == "shield" then
        self.powerups.shield = 8
    elseif powerType == "damage" then
        if not self._restoreDamage then self._restoreDamage = self.damageMultiplier end
        self.powerups.damage = 7
        self.damageMultiplier = self._restoreDamage * 1.5
    elseif powerType == "multishot" then
        if self._restoreProjectiles == nil then self._restoreProjectiles = self.extraProjectiles end
        self.powerups.multishot = 6
        self.extraProjectiles = self._restoreProjectiles + 1
    elseif powerType == "homing" then
        self.powerups.homing = 8
    elseif powerType == "explosive" then
        self.powerups.explosive = 5
    elseif powerType == "timeslow" then
        self.powerups.timeslow = 4
        _G.__SV_TIME_SCALE = 0.5
        self._timeslowActive = true
    elseif powerType == "invincible" then
        self.powerups.invincible = 3
    elseif powerType == "magnet" then
        if self._restoreMagnet == nil then self._restoreMagnet = self.magneticRange end
        self.powerups.magnet = 10
        self.magneticRange = math.max(self._restoreMagnet, 160)
    elseif powerType == "xpboost" then
        self.powerups.xpboost = 15
    elseif powerType == "armor" then
        self.powerups.armor = 12
    elseif powerType == "regen" then
        self.powerups.regen = 10
    elseif powerType == "ghost" then
        self.powerups.ghost = 5
    elseif powerType == "critical" then
        if not self._restoreDamage then self._restoreDamage = self.damageMultiplier end
        self.powerups.critical = 8
        self.damageMultiplier = self._restoreDamage * 1.35
    elseif powerType == "green_bullet" then
        self.bulletColor = "green"
    elseif powerType == "blue_bullet" then
        self.bulletColor = "blue"
    end
end

function Player:draw(shipImage)
    if self.dashTimer > 0 then
        for i = 1, 3 do
            local alpha = (1 - i / 3) * 0.4
            local size = self.radius * (1 + i * 0.1)
            love.graphics.setColor(0.2, 0.6, 1.0, alpha)
            love.graphics.circle("fill", self.x, self.y, size)
        end
    end

    if self.invulnerable then
        local shieldPulse = math.sin(love.timer.getTime() * 8) * 0.3 + 0.7
        local shieldRadius = self.radius + 10
        love.graphics.setColor(1, 0, 1, 0.2 * shieldPulse)
        love.graphics.circle("fill", self.x, self.y, shieldRadius + 5)
        love.graphics.setColor(1, 0, 1, 0.4 * shieldPulse)
        local points = {}
        for i = 0, 5 do
            local angle = (i / 6) * math.pi * 2
            table.insert(points, self.x + math.cos(angle) * shieldRadius)
            table.insert(points, self.y + math.sin(angle) * shieldRadius)
        end
    end

    if shipImage then
        love.graphics.setColor(1, 1, 1)
        if self.damageFlash > 0 then love.graphics.setColor(1, 0.5, 0.5) end
        local angle
        if self.hasAimOverride then
            angle = self.aimAngle
        else
            local mouseX, mouseY = love.mouse.getPosition()
            angle = util.angle(self.x, self.y, mouseX, mouseY)
        end
        local scale = (self.radius * 2.5) / math.max(shipImage:getWidth(), shipImage:getHeight())
        love.graphics.draw(shipImage, self.x, self.y, angle + math.pi/2, scale, scale, shipImage:getWidth()/2, shipImage:getHeight()/2)
    else
        local glowPulse = math.sin(love.timer.getTime() * 3) * 0.2 + 0.8
        love.graphics.setColor(0.2, 0.6, 1.0, 0.4 * glowPulse)
        love.graphics.circle("fill", self.x, self.y, self.radius + 5)
        if self.damageFlash > 0 then love.graphics.setColor(1, 0.5, 0.5) else love.graphics.setColor(0.2, 0.6, 1.0) end
        love.graphics.circle("fill", self.x, self.y, self.radius)
        love.graphics.setColor(0.5, 0.8, 1, 0.6)
        love.graphics.circle("fill", self.x - 3, self.y - 3, self.radius * 0.4)
        local angle
        if self.hasAimOverride then angle = self.aimAngle else local mouseX, mouseY = love.mouse.getPosition(); angle = util.angle(self.x, self.y, mouseX, mouseY) end
        local indicatorLength = self.radius + 5
        love.graphics.line(self.x, self.y, self.x + math.cos(angle) * indicatorLength, self.y + math.sin(angle) * indicatorLength)
    end
end

return Player
