-- Power-up module

local PowerUp = {}
PowerUp.__index = PowerUp

PowerUp.types = {
    health = {
        name = "Health",
        color = {0, 1, 0},
        duration = 0, -- instant
        icon = "+"
    },
    speed = {
        name = "Speed Boost",
        color = {0, 0.8, 1},
        duration = 5,
        icon = "S"
    },
    rapidfire = {
        name = "Rapid Fire",
        color = {1, 0.8, 0},
        duration = 5,
        icon = "R"
    },
    shield = {
        name = "Shield",
        color = {1, 0, 1},
        duration = 8,
        icon = "◆"
    },
    damage = {
        name = "Damage Boost",
        color = {1, 0.3, 0.1},
        duration = 7,
        icon = "D"
    },
    multishot = {
        name = "Multi-Shot",
        color = {0.9, 0.5, 1},
        duration = 6,
        icon = "M"
    },
    homing = {
        name = "Homing Bullets",
        color = {1, 1, 0.3},
        duration = 8,
        icon = "H"
    },
    explosive = {
        name = "Explosive Rounds",
        color = {1, 0.5, 0},
        duration = 5,
        icon = "E"
    },
    timeslow = {
        name = "Time Slow",
        color = {0.5, 0.8, 1},
        duration = 4,
        icon = "T"
    },
    invincible = {
        name = "Invincibility",
        color = {1, 1, 0},
        duration = 3,
        icon = "★"
    },
    magnet = {
        name = "Super Magnet",
        color = {0.8, 0.2, 0.8},
        duration = 10,
        icon = "⬡"
    },
    xpboost = {
        name = "XP Multiplier",
        color = {0.4, 1, 0.4},
        duration = 15,
        icon = "X"
    },
    armor = {
        name = "Heavy Armor",
        color = {0.6, 0.6, 0.7},
        duration = 12,
        icon = "A"
    },
    regen = {
        name = "Regeneration",
        color = {0.2, 1, 0.6},
        duration = 10,
        icon = "♥"
    },
    ghost = {
        name = "Ghost Mode",
        color = {0.7, 0.7, 1},
        duration = 5,
        icon = "G"
    },
    critical = {
        name = "Critical Hits",
        color = {1, 0.2, 0.2},
        duration = 8,
        icon = "!"
    },
    green_bullet = {
        name = "Green Laser",
        color = {0, 1, 0},
        duration = 15,
        icon = "G"
    },
    blue_bullet = {
        name = "Blue Laser",
        color = {0, 0.5, 1},
        duration = 15,
        icon = "B"
    }
}

function PowerUp.new(x, y, powerType)
    local self = setmetatable({}, PowerUp)
    self.x = x
    self.y = y
    self.radius = 12
    self.type = powerType or PowerUp.getRandomType()
    self.dead = false
    self.pulseTimer = 0
    self.lifetime = 15
    self.baseY = y
    self.bobAmplitude = 3
    self.bobSpeed = 2.5
    self.quality = "high"
    return self
end

function PowerUp.getRandomType()
    local types = {
        "health", "speed", "rapidfire", "shield",
        "damage", "multishot", "homing", "explosive",
        "timeslow", "invincible", "magnet", "xpboost",
        "armor", "regen", "ghost", "critical",
        "green_bullet", "blue_bullet"
    }
    return types[math.random(#types)]
end

function PowerUp:setQuality(quality)
    if quality == "low" or quality == "medium" or quality == "high" then self.quality = quality end
end

function PowerUp:update(dt)
    self.pulseTimer = self.pulseTimer + dt
    self.lifetime = self.lifetime - dt
    self.y = self.baseY + math.sin(self.pulseTimer * self.bobSpeed) * self.bobAmplitude
    
    if self.lifetime <= 0 then
        self.dead = true
    end
end

function PowerUp:draw()
    local typeData = PowerUp.types[self.type]
    
    -- Pulsing glow effect
    local pulse = math.sin(self.pulseTimer * 4) * 0.3 + 0.7
    local glowRadius = self.radius + 5 * pulse
    
    -- Outer glow
    love.graphics.setColor(typeData.color[1], typeData.color[2], typeData.color[3], 0.3 * pulse)
    love.graphics.circle("fill", self.x, self.y, glowRadius)
    
    -- Inner circle
    love.graphics.setColor(typeData.color[1], typeData.color[2], typeData.color[3])
    love.graphics.circle("fill", self.x, self.y, self.radius)
    
    -- Draw custom icon based on type
    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(2)
    
    local cx, cy = self.x, self.y
    local r = self.radius * 0.6
    
    if self.type == "health" then
        -- Heart shape
        love.graphics.arc("fill", cx - r*0.3, cy - r*0.2, r*0.4, math.pi, 0)
        love.graphics.arc("fill", cx + r*0.3, cy - r*0.2, r*0.4, math.pi, 0)
        love.graphics.polygon("fill", cx - r*0.7, cy - r*0.2, cx, cy + r*0.8, cx + r*0.7, cy - r*0.2)
        
    elseif self.type == "speed" then
        -- Lightning bolt
        love.graphics.polygon("fill", 
            cx - r*0.3, cy - r*0.8,
            cx + r*0.2, cy - r*0.1,
            cx - r*0.2, cy + 0.1,
            cx + r*0.5, cy + r*0.8,
            cx + r*0.1, cy + r*0.2,
            cx + r*0.3, cy - r*0.3,
            cx - r*0.3, cy - r*0.8
        )
        
    elseif self.type == "rapidfire" then
        -- Three bullets
        for i = -1, 1 do
            love.graphics.circle("fill", cx + i * r*0.5, cy, r*0.25)
            love.graphics.rectangle("fill", cx + i * r*0.5 - r*0.15, cy - r*0.5, r*0.3, r*0.4)
        end
        
    elseif self.type == "shield" then
        -- Diamond shield
        love.graphics.polygon("fill",
            cx, cy - r*0.8,
            cx + r*0.7, cy,
            cx, cy + r*0.8,
            cx - r*0.7, cy
        )
        
    elseif self.type == "damage" then
        -- Explosion star
        for i = 0, 7 do
            local angle = (i / 8) * math.pi * 2
            local nextAngle = ((i + 1) / 8) * math.pi * 2
            local midAngle = (angle + nextAngle) / 2
            love.graphics.polygon("fill",
                cx, cy,
                cx + math.cos(angle) * r * 0.9, cy + math.sin(angle) * r * 0.9,
                cx + math.cos(midAngle) * r * 0.4, cy + math.sin(midAngle) * r * 0.4
            )
        end
        
    elseif self.type == "multishot" then
        -- Triple arrows spreading
        for i = -1, 1 do
            local angle = i * 0.4
            local cos, sin = math.cos(angle), math.sin(angle)
            love.graphics.polygon("fill",
                cx + cos * r*0.6, cy + sin * r*0.6 - r*0.5,
                cx + cos * r*0.3 - r*0.3, cy + sin * r*0.3,
                cx + cos * r*0.3 + r*0.3, cy + sin * r*0.3
            )
        end
        
    elseif self.type == "homing" then
        -- Curved arrow with target
        love.graphics.arc("line", cx, cy, r*0.6, -math.pi/2, math.pi/2)
        love.graphics.polygon("fill",
            cx + r*0.6, cy,
            cx + r*0.3, cy - r*0.3,
            cx + r*0.3, cy + r*0.3
        )
        love.graphics.circle("line", cx - r*0.5, cy, r*0.3)
        
    elseif self.type == "explosive" then
        -- Bomb
        love.graphics.circle("fill", cx, cy + r*0.2, r*0.7)
        love.graphics.rectangle("fill", cx - r*0.15, cy - r*0.7, r*0.3, r*0.5)
        love.graphics.arc("fill", cx, cy - r*0.7, r*0.2, 0, math.pi)
        
    elseif self.type == "timeslow" then
        -- Clock
        love.graphics.circle("line", cx, cy, r*0.8)
        love.graphics.line(cx, cy, cx, cy - r*0.6)
        love.graphics.line(cx, cy, cx + r*0.4, cy)
        for i = 0, 11 do
            local angle = (i / 12) * math.pi * 2 - math.pi/2
            love.graphics.circle("fill", cx + math.cos(angle) * r*0.7, cy + math.sin(angle) * r*0.7, r*0.1)
        end
        
    elseif self.type == "invincible" then
        -- Star
        for i = 0, 4 do
            local angle1 = (i / 5) * math.pi * 2 - math.pi/2
            local angle2 = ((i + 0.5) / 5) * math.pi * 2 - math.pi/2
            local angle3 = ((i + 1) / 5) * math.pi * 2 - math.pi/2
            love.graphics.polygon("fill",
                cx, cy,
                cx + math.cos(angle1) * r*0.9, cy + math.sin(angle1) * r*0.9,
                cx + math.cos(angle2) * r*0.4, cy + math.sin(angle2) * r*0.4,
                cx + math.cos(angle3) * r*0.9, cy + math.sin(angle3) * r*0.9
            )
        end
        
    elseif self.type == "magnet" then
        -- Horseshoe magnet
        love.graphics.arc("line", cx, cy, r*0.7, math.pi*0.2, math.pi*0.8)
        love.graphics.rectangle("fill", cx - r*0.7 - r*0.2, cy - r*0.3, r*0.2, r*0.6)
        love.graphics.rectangle("fill", cx + r*0.7, cy - r*0.3, r*0.2, r*0.6)
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("fill", cx - r*0.7 - r*0.2, cy - r*0.3, r*0.2, r*0.3)
        love.graphics.setColor(0, 0, 1)
        love.graphics.rectangle("fill", cx + r*0.7, cy - r*0.3, r*0.2, r*0.3)
        
    elseif self.type == "xpboost" then
        -- X with sparkles
        love.graphics.setLineWidth(3)
        love.graphics.line(cx - r*0.6, cy - r*0.6, cx + r*0.6, cy + r*0.6)
        love.graphics.line(cx + r*0.6, cy - r*0.6, cx - r*0.6, cy + r*0.6)
        for i = 0, 3 do
            local angle = (i / 4) * math.pi * 2
            love.graphics.line(
                cx + math.cos(angle) * r*0.7, cy + math.sin(angle) * r*0.7,
                cx + math.cos(angle) * r*0.9, cy + math.sin(angle) * r*0.9
            )
        end
        
    elseif self.type == "armor" then
        -- Shield with cross
        love.graphics.polygon("fill",
            cx, cy - r*0.9,
            cx + r*0.6, cy - r*0.3,
            cx + r*0.6, cy + r*0.5,
            cx, cy + r*0.9,
            cx - r*0.6, cy + r*0.5,
            cx - r*0.6, cy - r*0.3
        )
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", cx - r*0.15, cy - r*0.6, r*0.3, r*1.2)
        love.graphics.rectangle("fill", cx - r*0.5, cy - r*0.15, r, r*0.3)
        
    elseif self.type == "regen" then
        -- Heart with plus
        love.graphics.arc("fill", cx - r*0.25, cy - r*0.2, r*0.35, math.pi, 0)
        love.graphics.arc("fill", cx + r*0.25, cy - r*0.2, r*0.35, math.pi, 0)
        love.graphics.polygon("fill", cx - r*0.6, cy - r*0.2, cx, cy + r*0.7, cx + r*0.6, cy - r*0.2)
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill", cx - r*0.15, cy - r*0.3, r*0.3, r*0.8)
        love.graphics.rectangle("fill", cx - r*0.4, cy + r*0.05, r*0.8, r*0.3)
        
    elseif self.type == "ghost" then
        -- Ghost shape
        love.graphics.arc("fill", cx, cy - r*0.3, r*0.7, math.pi, 0)
        love.graphics.rectangle("fill", cx - r*0.7, cy - r*0.3, r*1.4, r*0.9)
        for i = 0, 4 do
            love.graphics.arc("fill", cx - r*0.6 + i * r*0.3, cy + r*0.6, r*0.15, 0, math.pi)
        end
        love.graphics.setColor(0, 0, 0)
        love.graphics.circle("fill", cx - r*0.25, cy - r*0.2, r*0.15)
        love.graphics.circle("fill", cx + r*0.25, cy - r*0.2, r*0.15)
        
    elseif self.type == "critical" then
        -- Exclamation with slash
        love.graphics.rectangle("fill", cx - r*0.15, cy - r*0.8, r*0.3, r*0.9)
        love.graphics.circle("fill", cx, cy + r*0.5, r*0.2)
        love.graphics.setLineWidth(4)
        love.graphics.line(cx - r*0.7, cy - r*0.7, cx + r*0.7, cy + r*0.7)
        
    elseif self.type == "green_bullet" then
        -- Green bullet icon
        love.graphics.setColor(0, 1, 0)
        love.graphics.circle("fill", cx, cy, r*0.6)
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", cx, cy, r*0.3)
        
    elseif self.type == "blue_bullet" then
        -- Blue bullet icon
        love.graphics.setColor(0, 0.5, 1)
        love.graphics.circle("fill", cx, cy, r*0.6)
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", cx, cy, r*0.3)
    end
    
    love.graphics.setLineWidth(1)
end

return PowerUp
