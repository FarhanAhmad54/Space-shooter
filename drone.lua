-- Drone Companion System

local util = require("util")

local Drone = {}
Drone.__index = Drone

-- Drone types
Drone.types = {
    attack = {
        name = "Attack Drone",
        color = {1, 0.3, 0.3},
        shootCooldown = 0.5,
        damage = 0.5,
        icon = "⚔"
    },
    healer = {
        name = "Healer Drone",
        color = {0.3, 1, 0.3},
        healCooldown = 3.0,
        healAmount = 1,
        icon = "♥"
    },
    defender = {
        name = "Defender Drone",
        color = {0.3, 0.3, 1},
        shieldRadius = 30,
        icon = "🛡"
    },
    collector = {
        name = "Collector Drone",
        color = {1, 1, 0.3},
        collectRadius = 80,
        icon = "⬡"
    },
    pet1 = {
        name = "Pet 1",
        color = {1, 1, 0.2}, -- Yellow
        shootCooldown = 1.5,
        damage = 0.5,
        health = 3,
        maxHealth = 3,
        bulletColor = "yellow",
        image = "pet 1.png"
    },
    pet2 = {
        name = "Pet 2",
        color = {0.2, 0.5, 1}, -- Blue
        shootCooldown = 1.5,
        damage = 0.5,
        health = 3,
        maxHealth = 3,
        bulletColor = "blue",
        image = "pet 2.png"
    },
    pet3 = {
        name = "Pet 3",
        color = {0.2, 1, 0.2}, -- Green
        shootCooldown = 1.5,
        damage = 0.5,
        health = 3,
        maxHealth = 3,
        bulletColor = "green",
        image = "pet 3.png"
    }
}

-- Cache images
local droneImages = {}

function Drone.new(x, y, droneType, playerId)
    local self = setmetatable({}, Drone)
    
    droneType = droneType or "attack"
    local typeData = Drone.types[droneType] or Drone.types.attack
    if not Drone.types[droneType] then droneType = "attack" end
    
    self.x = x
    self.y = y
    self.type = droneType
    self.playerId = playerId
    self.radius = 12 -- Slightly larger for pets
    self.color = typeData.color
    self.dead = false
    
    -- Load image if needed
    if typeData.image and not droneImages[droneType] then
        if love.filesystem.getInfo("assets/" .. typeData.image) then
            droneImages[droneType] = love.graphics.newImage("assets/" .. typeData.image)
        end
    end
    
    -- Orbiting behavior
    self.orbitDistance = 50
    self.orbitAngle = math.random() * math.pi * 2
    self.orbitSpeed = 2
    self.formation = "pet"
    self.formationIndex = 0
    self.formationCount = 1
    self.quality = "high"
    
    -- Type-specific properties
    if droneType == "attack" or droneType == "pet1" or droneType == "pet2" or droneType == "pet3" then
        self.shootTimer = 0
        self.shootCooldown = typeData.shootCooldown
        self.damage = typeData.damage
        self.bulletColor = typeData.bulletColor
    elseif droneType == "healer" then
        self.healTimer = 0
        self.healCooldown = typeData.healCooldown
        self.healAmount = typeData.healAmount
    elseif droneType == "defender" then
        self.shieldRadius = typeData.shieldRadius
    elseif droneType == "collector" then
        self.collectRadius = typeData.collectRadius
    end
    
    -- Initialize health for pets
    if typeData.health then
        self.health = typeData.health
        self.maxHealth = typeData.maxHealth
    end
    
    return self
end

function Drone:takeDamage(amount)
    if self.health then
        self.health = self.health - (amount or 1)
        if self.health <= 0 then
            self.dead = true
        end
        return true
    end
    return false
end

function Drone:update(dt, player, enemies, bullets, powerups, ammo)
    -- Formation movement. Pet companions orbit; upgrade drones use dedicated formations.
    if self.formation == "side" then
        local side = (self.formationIndex == 1) and -1 or 1
        local tx = player.x + side * 48
        local ty = player.y + 18 + math.sin(love.timer.getTime() * 3 + self.formationIndex) * 6
        local t = math.min(1, 10 * dt)
        self.x = self.x + (tx - self.x) * t
        self.y = self.y + (ty - self.y) * t
        self.orbitAngle = 0
    elseif self.formation == "orbit_upgrade" then
        self.orbitAngle = self.orbitAngle + self.orbitSpeed * dt
        local offset = (self.formationIndex - 1) * math.pi
        self.x = player.x + math.cos(self.orbitAngle + offset) * 60
        self.y = player.y + math.sin(self.orbitAngle + offset) * 60
    else
        self.orbitAngle = self.orbitAngle + self.orbitSpeed * dt
        self.x = player.x + math.cos(self.orbitAngle) * self.orbitDistance
        self.y = player.y + math.sin(self.orbitAngle) * self.orbitDistance
    end
    
    -- Type-specific behavior
    if self.type == "attack" or self.type == "pet1" or self.type == "pet2" or self.type == "pet3" then
        self.shootTimer = self.shootTimer - dt
        if self.shootTimer <= 0 and #enemies > 0 then
            -- Find nearest enemy
            local nearest = enemies[1]
            local nearestDist = util.distance(self.x, self.y, nearest.x, nearest.y)
            
            for i, enemy in ipairs(enemies) do
                local dist = util.distance(self.x, self.y, enemy.x, enemy.y)
                if dist < nearestDist then
                    nearest = enemy
                    nearestDist = dist
                end
            end
            
            -- Return bullet to spawn
            local angle = util.angle(self.x, self.y, nearest.x, nearest.y)
            self.shootTimer = self.shootCooldown
            
            -- Use specific bullet color if defined, otherwise default behavior
            local bulletColor = self.bulletColor
            
            return {type = "shoot", angle = angle, damage = self.damage, color = bulletColor}
        end
        
    elseif self.type == "healer" then
        self.healTimer = self.healTimer - dt
        if self.healTimer <= 0 and player.health < player.maxHealth then
            self.healTimer = self.healCooldown
            return {type = "heal", amount = self.healAmount}
        end
        
    elseif self.type == "defender" then
        -- Check bullets in shield radius
        for i = #bullets, 1, -1 do
            local bullet = bullets[i]
            if bullet.owner == "enemy" then
                local dist = util.distance(self.x, self.y, bullet.x, bullet.y)
                if dist < self.shieldRadius then
                    bullet.dead = true
                end
            end
        end
        
    elseif self.type == "collector" then
        -- Collect power-ups
        for i, powerup in ipairs(powerups) do
            local dist = util.distance(self.x, self.y, powerup.x, powerup.y)
            if dist < self.collectRadius then
                -- Pull towards player
                local angle = util.angle(powerup.x, powerup.y, player.x, player.y)
                powerup.x = powerup.x + math.cos(angle) * 200 * dt
                powerup.y = powerup.y + math.sin(angle) * 200 * dt
            end
        end
        
        -- Collect ammo
        for i, ammoPickup in ipairs(ammo) do
            local dist = util.distance(self.x, self.y, ammoPickup.x, ammoPickup.y)
            if dist < self.collectRadius then
                local angle = util.angle(ammoPickup.x, ammoPickup.y, player.x, player.y)
                ammoPickup.x = ammoPickup.x + math.cos(angle) * 200 * dt
                ammoPickup.y = ammoPickup.y + math.sin(angle) * 200 * dt
            end
        end
    end
    
    return nil
end

function Drone:setQuality(quality)
    if quality == "low" or quality == "medium" or quality == "high" then self.quality = quality end
end

function Drone:draw()
    local typeData = Drone.types[self.type]
    local pulse = math.sin(love.timer.getTime() * 5) * 0.3 + 0.7
    local glowScale = self.quality == "low" and 0.5 or (self.quality == "medium" and 0.75 or 1)
    
    -- Glow effect
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.3 * pulse * glowScale)
    love.graphics.circle("fill", self.x, self.y, self.radius + 4)
    
    -- Draw image if available
    if droneImages[self.type] then
        love.graphics.setColor(1, 1, 1)
        local img = droneImages[self.type]
        -- Scale image to fit radius * 2
        local scale = (self.radius * 2.5) / img:getWidth()
        love.graphics.draw(img, self.x, self.y, self.orbitAngle + math.pi/2, scale, scale, img:getWidth()/2, img:getHeight()/2)
    else
        -- Body
        love.graphics.setColor(self.color[1], self.color[2], self.color[3])
        love.graphics.circle("fill", self.x, self.y, self.radius)
        
        -- Core highlight
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.circle("fill", self.x - 2, self.y - 2, self.radius * 0.4)
    end
    
    -- Type indicator (only for non-pet types or if image missing)
    if not droneImages[self.type] then
        if self.type == "defender" then
            -- Draw shield ring
            love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.2)
            love.graphics.circle("line", self.x, self.y, self.shieldRadius)
        elseif self.type == "collector" then
            -- Draw collection range
            love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.1)
            love.graphics.circle("line", self.x, self.y, self.collectRadius)
        end
    end
end

return Drone
