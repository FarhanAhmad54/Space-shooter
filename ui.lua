-- Modern UI system with smooth animations

local UI = {}
UI.__index = UI

function UI.new()
    local self = setmetatable({}, UI)
    
    -- Animated values
    self.displayHealth = 3
    self.displayScore = 0
    self.displayXP = 0
    self.displayCombo = 0
    
    -- Animation speeds
    self.healthSpeed = 8
    self.scoreSpeed = 500
    self.xpSpeed = 100
    self.comboSpeed = 10
    
    -- Pulse effects
    self.comboPulse = 1
    self.comboPulseSpeed = 0
    self.quality = "high"
    self.fonts = {}
    
    return self
end

function UI:setQuality(quality)
    if quality == "low" or quality == "medium" or quality == "high" then self.quality=quality end
end

function UI:getFont(size)
    if not self.fonts[size] then self.fonts[size]=love.graphics.newFont(size) end
    return self.fonts[size]
end

function UI:update(dt, player, score, xp, maxXP, combo, wave)
    -- Smooth value interpolation
    self.displayHealth = self:lerp(self.displayHealth, player.health, self.healthSpeed * dt)
    self.displayScore = self:lerp(self.displayScore, score, self.scoreSpeed * dt)
    self.displayXP = self:lerp(self.displayXP, xp, self.xpSpeed * dt)
    self.displayCombo = self:lerp(self.displayCombo, combo, self.comboSpeed * dt)
    
    -- Combo pulse animation
    if combo > 0 then
        self.comboPulseSpeed = self.comboPulseSpeed + dt * 15
        self.comboPulse = 1 + math.sin(self.comboPulseSpeed) * 0.1
    else
        self.comboPulse = 1
        self.comboPulseSpeed = 0
    self.quality = "high"
    self.fonts = {}
    end
end

function UI:lerp(current, target, speed)
    return current + (target - current) * math.min(1, speed)
end

function UI:drawHUD(player, score, wave, ammo, maxAmmo)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Top-left panel (Health, Wave, Score)
    self:drawPanel(10, 10, 300, 140, 0.2)
    
    -- Health display with hearts
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.setFont(self:getFont(16))
    love.graphics.print("HEALTH", 20, 20)
    
    local heartSize = 20
    for i = 1, player.maxHealth do
        local x = 20 + (i - 1) * (heartSize + 8)
        local y = 45
        
        if i <= math.floor(self.displayHealth + 0.5) then
            love.graphics.setColor(1, 0.2, 0.3)
            self:drawHeart(x, y, heartSize)
        else
            love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
            self:drawHeart(x, y, heartSize)
        end
    end
    
    -- Wave display
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.setFont(self:getFont(16))
    love.graphics.print("WAVE", 20, 80)
    love.graphics.setFont(self:getFont(24))
    love.graphics.setColor(0.5, 0.8, 1)
    love.graphics.print(tostring(wave), 20, 100)
    
    -- Score display
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.setFont(self:getFont(14))
    love.graphics.print("SCORE: " .. math.floor(self.displayScore), 170, 20)
    
    -- Stars display
    local profile = require("profile").getProfile()
    local stars = profile and profile.stars or 0
    love.graphics.setColor(1, 1, 0.2)
    love.graphics.print("STARS: " .. stars, 170, 40)
    
    -- Ammo display
    if maxAmmo > 0 then
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.print("AMMO: " .. ammo .. "/" .. maxAmmo, 170, 60)
        
        -- Ammo bar
        local ammoBarW = 100
        local ammoBarH = 8
        local ammoPercent = ammo / maxAmmo
        
        love.graphics.setColor(0.2, 0.2, 0.2, 0.7)
        love.graphics.rectangle("fill", 170, 80, ammoBarW, ammoBarH)
        
        love.graphics.setColor(1, 0.8, 0, 0.9)
        love.graphics.rectangle("fill", 170, 80, ammoBarW * ammoPercent, ammoBarH)
    end
    
    -- Bottom XP bar
    local xpBarW = w - 40
    local xpBarH = 20
    local xpBarX = 20
    local xpBarY = h - 40
    
    self:drawPanel(xpBarX - 5, xpBarY - 5, xpBarW + 10, xpBarH + 10, 0.2)
    
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", xpBarX, xpBarY, xpBarW, xpBarH)
    
    -- XP fill gradient
    local xpPercent = self.displayXP / 100
    love.graphics.setColor(0.3, 0.8, 1, 0.9)
    love.graphics.rectangle("fill", xpBarX, xpBarY, xpBarW * xpPercent, xpBarH)
    
    love.graphics.setColor(0.5, 1, 1, 0.6)
    love.graphics.rectangle("fill", xpBarX, xpBarY, xpBarW * xpPercent, xpBarH / 2)
    
    -- XP text
    love.graphics.setFont(self:getFont(14))
    love.graphics.setColor(1, 1, 1, 0.9)
    local xpText = string.format("XP: %d / 100", math.floor(self.displayXP))
    love.graphics.printf(xpText, xpBarX, xpBarY + 3, xpBarW, "center")
end

function UI:drawCombo(combo, comboTimer, comboTimeout)
    if combo > 1 then
        local w = love.graphics.getWidth()
        local x = w - 150
        local y = 20
        
        -- Combo display
        love.graphics.setColor(1, 1, 0, 0.9)
        love.graphics.setFont(self:getFont(32))
        
        local text = combo .. "x COMBO"
        love.graphics.print(text, x, y, 0, self.comboPulse, self.comboPulse)
        
        -- Combo timeout bar
        local timeLeft = (comboTimeout - comboTimer) / comboTimeout
        love.graphics.setColor(1, 1, 0, 0.7)
        love.graphics.rectangle("fill", x, y + 40, 120 * timeLeft, 5)
    end
end

function UI:drawAbilityCooldowns(player)
    local x = love.graphics.getWidth() - 100
    local y = 100
    
    -- Dash cooldown
    if player.dashCooldown > 0 then
        self:drawCooldownIndicator(x, y, player.dashCooldown, player.dashDelay, "DASH", {0.2, 0.6, 1})
    else
        love.graphics.setColor(0.2, 0.6, 1, 0.8)
        love.graphics.circle("fill", x, y, 20)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(self:getFont(12))
        love.graphics.printf("DASH", x - 30, y + 25, 60, "center")
    end
end

function UI:drawCooldownIndicator(x, y, current, max, label, color)
    local percent = 1 - (current / max)
    
    -- Background circle
    love.graphics.setColor(0.2, 0.2, 0.2, 0.7)
    love.graphics.circle("fill", x, y, 20)
    
    -- Cooldown arc
    love.graphics.setColor(color[1], color[2], color[3], 0.6)
    love.graphics.arc("fill", x, y, 20, -math.pi/2, -math.pi/2 + (math.pi * 2 * percent))
    
    -- Label
    love.graphics.setFont(self:getFont(12))
    love.graphics.printf(label, x - 30, y + 25, 60, "center")
end

function UI:drawPanel(x, y, w, h, alpha)
    -- Panel background with gradient effect
    love.graphics.setColor(0.1, 0.1, 0.15, alpha or 0.3)
    love.graphics.rectangle("fill", x, y, w, h, 5, 5)
    
    -- Highlight
    love.graphics.setColor(0.3, 0.4, 0.6, (alpha or 0.3) * 0.5)
    love.graphics.rectangle("fill", x, y, w, 2, 5, 5)
    
    -- Border (removed)
    -- love.graphics.setColor(0.4, 0.5, 0.7, (alpha or 0.3) * 1.5)
    -- love.graphics.rectangle("line", x, y, w, h, 5, 5)
end

function UI:drawHeart(x, y, size)
    -- Simple heart shape using circles and triangle
    local s = size / 2
    love.graphics.circle("fill", x, y, s)
    love.graphics.circle("fill", x + s, y, s)
    love.graphics.polygon("fill", x - s, y, x + s * 2, y, x + s/2, y + s * 1.5)
end

function UI:drawWaveAnnouncement(waveNumber, alpha)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.setFont(self:getFont(64))
    
    local text = "WAVE " .. waveNumber
    local textWidth = love.graphics.getFont():getWidth(text)
    
    love.graphics.print(text, (w - textWidth) / 2, h / 2 - 32, 0, 1 + (1 - alpha) * 0.2, 1 + (1 - alpha) * 0.2)
end

return UI
