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
    
    -- Aim angle for mobile controls
    self.aimAngle = 0  -- Current aiming angle
    self.hasAimOverride = false  -- True when using mobile aim joystick
    
    -- Dash ability
    self.dashCooldown = 0
    self.dashDelay = 2.0
    self.dashSpeed = 600
    self.dashDuration = 0.15
    self.dashTimer = 0
    self.dashDirection = {x = 0, y = 0}
    
    -- Active power-ups
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
    
    -- Visual effects
    self.damageFlash = 0
    self.invulnerable = false
    self.bulletColor = "yellow"

    -- Persistent run upgrades
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
    
    return self
end

function Player:update(dt, joystickX, joystickY, controlType)
    -- Update power-ups
    for name, timer in pairs(self.powerups) do
        if timer > 0 then
            self.powerups[name] = timer - dt
        end
    end
    
    -- Reset bullet color if powerup expired (optional, or keep it permanent until new pickup)
    -- For now, let's make it permanent until changed, as requested "collect pick ups bullets then show the new bullets"
    
    -- Apply power-up effects
    local speedMultiplier = 1.0
    if self.powerups.speed > 0 then
        speedMultiplier = 1.7
    end
    self.speed = self.baseSpeed * speedMultiplier
    
    if self.powerups.rapidfire > 0 then
        self.shootDelay = 0.1
    else
        self.shootDelay = 0.2
    end
    
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
    
    -- Handle dash
    if self.dashTimer > 0 then
        self.dashTimer = self.dashTimer - dt
        self.x = self.x + self.dashDirection.x * self.dashSpeed * dt
        self.y = self.y + self.dashDirection.y * self.dashSpeed * dt
    else
        -- Normal movement
        local dx, dy = 0, 0
        
        -- Use joystick if provided and non-zero (mobile), else keyboard (PC)
        if joystickX and (math.abs(joystickX) > 0.01 or math.abs(joystickY) > 0.01) then
            dx, dy = joystickX, joystickY
        elseif controlType ~= "mobile" then
            -- Keyboard controls (only active when NOT in mobile mode)
            if love.keyboard.isDown("w") or love.keyboard.isDown("up") then
                dy = dy - 1
            end
            if love.keyboard.isDown("s") or love.keyboard.isDown("down") then
                dy = dy + 1
            end
            if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
                dx = dx - 1
            end
            if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
                dx = dx + 1
            end
        end
        
        -- Normalize diagonal movement
        if dx ~= 0 or dy ~= 0 then
            local length = math.sqrt(dx * dx + dy * dy)
            dx = dx / length
            dy = dy / length
        end
        
        -- Apply movement
        self.x = self.x + dx * self.speed * dt
        self.y = self.y + dy * self.speed * dt
    end
    
    -- Keep player in bounds
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    self.x = math.max(self.radius, math.min(screenWidth - self.radius, self.x))
    self.y = math.max(self.radius, math.min(screenHeight - self.radius, self.y))
    
    -- Update cooldowns
    if self.shootCooldown > 0 then
        self.shootCooldown = self.shootCooldown - dt
    end
    
    if self.dashCooldown > 0 then
        self.dashCooldown = self.dashCooldown - dt
    end
    
    if self.damageFlash > 0 then
        self.damageFlash = self.damageFlash - dt
    end
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
        self.health = math.max(0, self.health - (amount or 1))
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
        self.powerups.rapidfire = 5
    elseif powerType == "shield" then
        self.powerups.shield = 8
    elseif powerType == "damage" then
        self.powerups.damage = 7
    elseif powerType == "multishot" then
        self.powerups.multishot = 6
    elseif powerType == "homing" then
        self.powerups.homing = 8
    elseif powerType == "explosive" then
        self.powerups.explosive = 5
    elseif powerType == "timeslow" then
        self.powerups.timeslow = 4
    elseif powerType == "invincible" then
        self.powerups.invincible = 3
    elseif powerType == "magnet" then
        self.powerups.magnet = 10
    elseif powerType == "xpboost" then
        self.powerups.xpboost = 15
    elseif powerType == "armor" then
        self.powerups.armor = 12
    elseif powerType == "regen" then
        self.powerups.regen = 10
    elseif powerType == "ghost" then
        self.powerups.ghost = 5
    elseif powerType == "critical" then
        self.powerups.critical = 8
    elseif powerType == "green_bullet" then
        self.bulletColor = "green"
    elseif powerType == "blue_bullet" then
        self.bulletColor = "blue"
    end
end

function Player:draw(shipImage)
    -- Draw dash trail with afterimages
    if self.dashTimer > 0 then
        for i = 1, 3 do
            local alpha = (1 - i / 3) * 0.4
            local size = self.radius * (1 + i * 0.1)
            love.graphics.setColor(0.2, 0.6, 1.0, alpha)
            love.graphics.circle("fill", self.x, self.y, size)
        end
    end
    
    -- Draw shield with hexagonal pattern
    if self.invulnerable then
        local shieldPulse = math.sin(love.timer.getTime() * 8) * 0.3 + 0.7
        local shieldRadius = self.radius + 10
        
        love.graphics.setColor(1, 0, 1, 0.2 * shieldPulse)
        love.graphics.circle("fill", self.x, self.y, shieldRadius + 5)
        
        -- Hexagon shield (filled only)
        love.graphics.setColor(1, 0, 1, 0.4 * shieldPulse)
        local points = {}
        for i = 0, 5 do
            local angle = (i / 6) * math.pi * 2
            table.insert(points, self.x + math.cos(angle) * shieldRadius)
            table.insert(points, self.y + math.sin(angle) * shieldRadius)
        end
        -- love.graphics.polygon("line", points) -- Removed outline
    end
    
    -- Draw ship image or fallback to circle
    if shipImage then
        love.graphics.setColor(1, 1, 1)
        if self.damageFlash > 0 then
            love.graphics.setColor(1, 0.5, 0.5)
        end
        
        -- Get rotation angle (use aim override if active, else mouse)
        local angle
        if self.hasAimOverride then
            angle = self.aimAngle
        else
            local mouseX, mouseY = love.mouse.getPosition()
            angle = util.angle(self.x, self.y, mouseX, mouseY)
        end
        
        local scale = (self.radius * 2.5) / math.max(shipImage:getWidth(), shipImage:getHeight())
        love.graphics.draw(shipImage, self.x, self.y, angle + math.pi/2, scale, scale, 
                          shipImage:getWidth()/2, shipImage:getHeight()/2)
    else
        -- Fallback to colored circle
        local glowPulse = math.sin(love.timer.getTime() * 3) * 0.2 + 0.8
        love.graphics.setColor(0.2, 0.6, 1.0, 0.4 * glowPulse)
        love.graphics.circle("fill", self.x, self.y, self.radius + 5)
        
        if self.damageFlash > 0 then
            love.graphics.setColor(1, 0.5, 0.5)
        else
            love.graphics.setColor(0.2, 0.6, 1.0)
        end
        love.graphics.circle("fill", self.x, self.y, self.radius)
        
        love.graphics.setColor(0.5, 0.8, 1, 0.6)
        love.graphics.circle("fill", self.x - 3, self.y - 3, self.radius * 0.4)
        
        -- Draw direction indicator (use aim override if active, else mouse)
        local angle
        if self.hasAimOverride then
            angle = self.aimAngle
        else
            local mouseX, mouseY = love.mouse.getPosition()
            angle = util.angle(self.x, self.y, mouseX, mouseY)
        end
        local indicatorLength = self.radius + 5
        local endX = self.x + math.cos(angle) * indicatorLength
        local endY = self.y + math.sin(angle) * indicatorLength
        love.graphics.line(self.x, self.y, endX, endY)
    end
end

return Player
