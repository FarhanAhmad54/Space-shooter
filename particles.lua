-- Advanced particle system manager

local Particles = {}
Particles.__index = Particles

function Particles.new()
    local self = setmetatable({}, Particles)
    self.particles = {}
    self.quality = "high"
    return self
end

function Particles:setQuality(quality)
    if quality == "low" or quality == "medium" or quality == "high" then
        self.quality = quality
    end
end

function Particles:update(dt)
    for i = #self.particles, 1, -1 do
        local p = self.particles[i]
        
        -- Update position
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        
        -- Apply gravity/acceleration
        if p.ax then
            p.vx = p.vx + p.ax * dt
            p.vy = p.vy + p.ay * dt
        end
        
        -- Apply drag
        if p.drag then
            local drag = math.max(0, 1 - p.drag * dt)
            p.vx = p.vx * drag
            p.vy = p.vy * drag
        end
        
        -- Update life
        p.life = p.life - dt
        
        -- Update size
        if p.growRate then
            p.size = p.size + p.growRate * dt
        end
        
        -- Update rotation
        if p.rotationSpeed then
            p.rotation = (p.rotation or 0) + p.rotationSpeed * dt
        end
        
        -- Remove dead particles
        if p.life <= 0 or p.size <= 0 then
            table.remove(self.particles, i)
        end
    end
end

function Particles:draw()
    for i, p in ipairs(self.particles) do
        local alpha = p.life / p.maxLife
        
        -- Apply fade curve
        if p.fadeType == "smooth" then
            alpha = math.sin(alpha * math.pi)
        elseif p.fadeType == "fast" then
            alpha = alpha * alpha
        end
        
        love.graphics.setColor(p.r, p.g, p.b, alpha * (p.alpha or 1))
        
        if p.shape == "circle" then
            love.graphics.circle("fill", p.x, p.y, p.size)
        elseif p.shape == "square" then
            local s = p.size
            love.graphics.rectangle("fill", p.x - s, p.y - s, s * 2, s * 2)
        elseif p.shape == "line" then
            local angle = p.rotation or math.atan2(p.vy, p.vx)
            local len = p.length or p.size * 2
            local dx = math.cos(angle) * len
            local dy = math.sin(angle) * len
            love.graphics.line(p.x - dx/2, p.y - dy/2, p.x + dx/2, p.y + dy/2)
        elseif p.shape == "ring" then
            -- Changed from "line" to "fill" with lower alpha to remove outline
            local currentAlpha = love.graphics.getColor() -- get alpha from set color
            love.graphics.setColor(p.r, p.g, p.b, alpha * (p.alpha or 1) * 0.5)
            love.graphics.circle("fill", p.x, p.y, p.size)
        end
    end
end

-- Explosion effect with shockwave
function Particles:explosion(x, y, size, colorPreset)
    size = size or 1
    
    local colors = {
        fire = {{1, 0.8, 0}, {1, 0.4, 0}, {1, 0, 0}},
        electric = {{0.5, 0.8, 1}, {0.3, 0.5, 1}, {1, 1, 1}},
        poison = {{0.5, 0.3, 1}, {0.3, 0.2, 0.8}, {0.8, 0, 1}}, -- Changed from Green to Purple
        default = {{1, 1, 0.5}, {1, 0.5, 0}, {1, 0.2, 0.2}}
    }
    
    local palette = colors[colorPreset] or colors.default
    
    -- Shockwave ring
    for i = 1, 2 do
        table.insert(self.particles, {
            x = x, y = y,
            vx = 0, vy = 0,
            size = 5 * size,
            r = palette[1][1], g = palette[1][2], b = palette[1][3],
            life = 0.3, maxLife = 0.3,
            shape = "ring",
            growRate = 200 * size,
            alpha = 0.6,
            fadeType = "fast"
        })
    end
    
    -- Explosion particles
    local particleCount = math.floor(20 * size)
    for i = 1, particleCount do
        local angle = (i / particleCount) * math.pi * 2
        local speed = math.random(80, 200) * size
        local color = palette[math.random(#palette)]
        
        table.insert(self.particles, {
            x = x, y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            size = math.random(2, 6) * size,
            r = color[1], g = color[2], b = color[3],
            life = math.random(0.3, 0.6),
            maxLife = 0.6,
            shape = "circle",
            drag = 2.0,
            growRate = -8 * size,
            fadeType = "smooth"
        })
    end
    
    -- Core flash
    table.insert(self.particles, {
        x = x, y = y,
        vx = 0, vy = 0,
        size = 20 * size,
        r = 1, g = 1, b = 1,
        life = 0.1, maxLife = 0.1,
        shape = "circle",
        alpha = 0.8,
        growRate = 100 * size
    })
end

-- Impact sparks when bullet hits enemy
function Particles:impact(x, y, angle, intensity)
    intensity = intensity or 1
    local sparkCount = math.floor(8 * intensity)
    
    for i = 1, sparkCount do
        local spreadAngle = angle + math.random(-60, 60) * (math.pi / 180)
        local speed = math.random(100, 250) * intensity
        
        table.insert(self.particles, {
            x = x, y = y,
            vx = math.cos(spreadAngle) * speed,
            vy = math.sin(spreadAngle) * speed,
            size = math.random(1, 3),
            r = 1, g = math.random(0.5, 0.8), b = 0.2, -- Changed to Orange/Yellow
            life = math.random(0.2, 0.4),
            maxLife = 0.4,
            shape = "line",
            length = math.random(4, 10),
            rotation = spreadAngle,
            drag = 3.0,
            fadeType = "fast"
        })
    end
end

-- Smooth bullet trail
function Particles:trail(x, y, vx, vy, color)
    color = color or {1, 1, 0}
    
    table.insert(self.particles, {
        x = x, y = y,
        vx = -vx * 0.1, vy = -vy * 0.1,
        size = math.random(2, 4),
        r = color[1], g = color[2], b = color[3],
        life = 0.3,
        maxLife = 0.3,
        shape = "circle",
        growRate = -8,
        alpha = 0.6,
        fadeType = "smooth"
    })
end

-- Energy field around powerups
function Particles:energyField(x, y, radius, color)
    color = color or {0, 1, 1}
    
    for i = 1, 2 do
        local angle = math.random() * math.pi * 2
        local dist = math.random() * radius
        local px = x + math.cos(angle) * dist
        local py = y + math.sin(angle) * dist
        
        -- Orbit angle
        local orbitAngle = angle + math.pi / 2
        local orbitSpeed = math.random(50, 100)
        
        table.insert(self.particles, {
            x = px, y = py,
            vx = math.cos(orbitAngle) * orbitSpeed,
            vy = math.sin(orbitAngle) * orbitSpeed,
            size = math.random(1, 3),
            r = color[1], g = color[2], b = color[3],
            life = 0.5,
            maxLife = 0.5,
            shape = "circle",
            alpha = 0.7,
            fadeType = "smooth"
        })
    end
end

-- Dash afterimage effect
function Particles:dashTrail(x, y, radius, color)
    color = color or {0.2, 0.6, 1}
    
    table.insert(self.particles, {
        x = x, y = y,
        vx = 0, vy = 0,
        size = radius,
        r = color[1], g = color[2], b = color[3],
        life = 0.2,
        maxLife = 0.2,
        shape = "circle",
        alpha = 0.4,
        growRate = -radius * 3,
        fadeType = "fast"
    })
end

-- Engine/thruster particles
function Particles:thruster(x, y, angle, power)
    power = power or 1
    
    for i = 1, 2 do
        local spreadAngle = angle + math.random(-20, 20) * (math.pi / 180)
        local speed = math.random(50, 150) * power
        
        table.insert(self.particles, {
            x = x, y = y,
            vx = math.cos(spreadAngle) * speed,
            vy = math.sin(spreadAngle) * speed,
            size = math.random(2, 4),
            r = 1, g = math.random(0.5, 0.8), b = 0,
            life = math.random(0.3, 0.5),
            maxLife = 0.5,
            shape = "circle",
            drag = 2.0,
            growRate = -6,
            fadeType = "smooth",
            alpha = 0.6
        })
    end
end

-- Death burst with particles flying outward
function Particles:deathBurst(x, y, color, size)
    color = color or {1, 0, 0}
    size = size or 1
    
    local count = math.floor(15 * size)
    for i = 1, count do
        local angle = (i / count) * math.pi * 2
        local speed = math.random(80, 180) * size
        
        table.insert(self.particles, {
            x = x, y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            size = math.random(2, 5) * size,
            r = color[1], g = color[2], b = color[3],
            life = math.random(0.4, 0.7),
            maxLife = 0.7,
            shape = "square",
            drag = 1.5,
            rotationSpeed = math.random(-10, 10),
            rotation = 0,
            growRate = -4 * size,
            fadeType = "smooth"
        })
    end
end

-- Heal/buff effect
function Particles:healEffect(x, y, radius)
    for i = 1, 10 do
        local angle = (i / 10) * math.pi * 2
        local dist = radius
        
        table.insert(self.particles, {
            x = x + math.cos(angle) * dist,
            y = y + math.sin(angle) * dist,
            vx = 0,
            vy = -50,
            ay = -30,
            size = math.random(2, 4),
            r = 0, g = 0.8, b = 1, -- Changed from Green to Cyan
            life = 0.8,
            maxLife = 0.8,
            shape = "circle",
            alpha = 0.8,
            fadeType = "smooth"
        })
    end
end

return Particles
