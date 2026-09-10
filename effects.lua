-- Visual effects manager for screen effects and animations

local Effects = {}
Effects.__index = Effects

function Effects.new()
    local self = setmetatable({}, Effects)
    
    -- Screen flash effects
    self.flashR = 0
    self.flashG = 0
    self.flashB = 0
    self.flashAlpha = 0
    
    -- Damage numbers
    self.damageNumbers = {}
    
    -- Text popup notifications
    self.notifications = {}
    self.quality = "high"
    
    return self
end

function Effects:setQuality(quality)
    if quality == "low" or quality == "medium" or quality == "high" then
        self.quality = quality
    end
end

function Effects:update(dt)
    -- Decay flash
    if self.flashAlpha > 0 then
        self.flashAlpha = self.flashAlpha - dt * 3
    end
    
    -- Update damage numbers
    for i = #self.damageNumbers, 1, -1 do
        local dn = self.damageNumbers[i]
        dn.y = dn.y - 50 * dt
        dn.life = dn.life - dt
        
        if dn.life <= 0 then
            table.remove(self.damageNumbers, i)
        end
    end
    
    -- Update notifications
    for i = #self.notifications, 1, -1 do
        local notif = self.notifications[i]
        notif.life = notif.life - dt
        notif.y = notif.y - 30 * dt
        
        if notif.life <= 0 then
            table.remove(self.notifications, i)
        end
    end
end

function Effects:draw()
    -- Draw screen flash
    if self.flashAlpha > 0 then
        love.graphics.setColor(self.flashR, self.flashG, self.flashB, self.flashAlpha)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end
    
    -- Draw damage numbers
    local font = love.graphics.getFont()
    for i, dn in ipairs(self.damageNumbers) do
        local alpha = dn.life / dn.maxLife
        love.graphics.setColor(dn.r, dn.g, dn.b, alpha)
        
        local scale = 1 + (1 - alpha) * 0.3
        love.graphics.print(dn.text, dn.x, dn.y, 0, scale, scale)
    end
    
    -- Draw notifications
    for i, notif in ipairs(self.notifications) do
        local alpha = math.min(1, notif.life / 0.5)
        love.graphics.setColor(notif.r, notif.g, notif.b, alpha)
        
        local scale = 1.2
        love.graphics.printf(notif.text, 0, notif.y, love.graphics.getWidth(), "center", 0, scale, scale)
    end
end

function Effects:flash(r, g, b, intensity)
    self.flashR = r
    self.flashG = g
    self.flashB = b
    self.flashAlpha = intensity or 0.5
end

function Effects:addDamageNumber(x, y, damage, critical)
    local color = critical and {1, 1, 0} or {1, 0.5, 0.5}
    local text = critical and ("CRIT " .. tostring(damage)) or tostring(damage)
    
    if self.quality == "low" and #self.damageNumbers >= 8 then return end

    table.insert(self.damageNumbers, {
        x = x + math.random(-10, 10),
        y = y - 20,
        text = text,
        r = color[1],
        g = color[2],
        b = color[3],
        life = 1.0,
        maxLife = 1.0
    })
end

function Effects:notification(text, color)
    color = color or {1, 1, 1}
    
    table.insert(self.notifications, {
        text = text,
        x = love.graphics.getWidth() / 2,
        y = 200,
        r = color[1],
        g = color[2],
        b = color[3],
        life = 2.0
    })
end

return Effects
