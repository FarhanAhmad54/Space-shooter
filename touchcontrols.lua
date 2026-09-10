-- Touch Controls for Mobile
-- Virtual joystick and fire button

local TouchControls = {}
TouchControls.__index = TouchControls

function TouchControls.new()
    local self = setmetatable({}, TouchControls)
    
    -- Joystick (left side for movement)
    self.joystick = {
        baseX = 120,
        baseY = nil,  -- Will be set based on screen height
        baseRadius = 60,
        stickX = 0,
        stickY = 0,
        stickRadius = 25,
        maxDistance = 50,
        active = false,
        touchId = nil,
        -- Output values
        dx = 0,
        dy = 0
    }
    
    -- Aim joystick (right side for aiming and shooting)
    self.aimJoystick = {
        baseX = nil,  -- Will be set based on screen width
        baseY = nil,  -- Will be set based on screen height
        baseRadius = 60,
        stickX = 0,
        stickY = 0,
        stickRadius = 25,
        maxDistance = 50,
        active = false,
        touchId = nil,
        -- Output values
        dx = 0,
        dy = 0,
        shooting = false  -- True when fully stretched
    }
    
    self.quality = "high"
    self:updatePositions()
    
    return self
end

function TouchControls:setQuality(quality)
    if quality == "low" or quality == "medium" or quality == "high" then self.quality = quality end
end

function TouchControls:updatePositions()
    local w, h = love.graphics.getDimensions()
    
    -- Joystick at bottom left
    self.joystick.baseY = h - 120
    
    -- Aim joystick at bottom right
    self.aimJoystick.baseX = w - 120
    self.aimJoystick.baseY = h - 120
end

function TouchControls:touchpressed(id, x, y)
    local joy = self.joystick
    local aim = self.aimJoystick
    
    -- Check movement joystick
    local distToJoy = math.sqrt((x - joy.baseX)^2 + (y - joy.baseY)^2)
    if distToJoy < joy.baseRadius + 20 and not joy.active then
        joy.active = true
        joy.touchId = id
        joy.stickX = x - joy.baseX
        joy.stickY = y - joy.baseY
        self:updateJoystick()
        return true
    end
    
    -- Check aim joystick
    local distToAim = math.sqrt((x - aim.baseX)^2 + (y - aim.baseY)^2)
    if distToAim < aim.baseRadius + 20 and not aim.active then
        aim.active = true
        aim.touchId = id
        aim.stickX = x - aim.baseX
        aim.stickY = y - aim.baseY
        self:updateAimJoystick()
        return true
    end
    
    return false
end

function TouchControls:touchmoved(id, x, y)
    local joy = self.joystick
    local aim = self.aimJoystick
    
    -- Update movement joystick if this is the joystick touch
    if joy.active and joy.touchId == id then
        joy.stickX = x - joy.baseX
        joy.stickY = y - joy.baseY
        self:updateJoystick()
        return true
    end
    
    -- Update aim joystick if this is the aim touch
    if aim.active and aim.touchId == id then
        aim.stickX = x - aim.baseX
        aim.stickY = y - aim.baseY
        self:updateAimJoystick()
        return true
    end
    
    return false
end

function TouchControls:touchreleased(id)
    local joy = self.joystick
    local aim = self.aimJoystick
    
    -- Release movement joystick
    if joy.active and joy.touchId == id then
        joy.active = false
        joy.touchId = nil
        joy.stickX = 0
        joy.stickY = 0
        joy.dx = 0
        joy.dy = 0
        return true
    end
    
    -- Release aim joystick
    if aim.active and aim.touchId == id then
        aim.active = false
        aim.touchId = nil
        aim.stickX = 0
        aim.stickY = 0
        aim.dx = 0
        aim.dy = 0
        aim.shooting = false
        return true
    end
    
    return false
end

function TouchControls:updateJoystick()
    local joy = self.joystick
    
    -- Limit stick to max distance
    local dist = math.sqrt(joy.stickX^2 + joy.stickY^2)
    if dist > joy.maxDistance then
        local angle = math.atan2(joy.stickY, joy.stickX)
        joy.stickX = math.cos(angle) * joy.maxDistance
        joy.stickY = math.sin(angle) * joy.maxDistance
        dist = joy.maxDistance
    end
    
    -- Calculate normalized direction (-1 to 1)
    if dist > 5 then  -- Dead zone
        joy.dx = joy.stickX / joy.maxDistance
        joy.dy = joy.stickY / joy.maxDistance
    else
        joy.dx = 0
        joy.dy = 0
    end
end

function TouchControls:getMovement()
    return self.joystick.dx, self.joystick.dy
end

function TouchControls:getAimDirection()
    return self.aimJoystick.dx, self.aimJoystick.dy
end

function TouchControls:isShooting()
    return self.aimJoystick.shooting
end

function TouchControls:updateAimJoystick()
    local aim = self.aimJoystick
    
    -- Limit stick to max distance
    local dist = math.sqrt(aim.stickX^2 + aim.stickY^2)
    if dist > aim.maxDistance then
        local angle = math.atan2(aim.stickY, aim.stickX)
        aim.stickX = math.cos(angle) * aim.maxDistance
        aim.stickY = math.sin(angle) * aim.maxDistance
        dist = aim.maxDistance
    end
    
    -- Calculate normalized direction (-1 to 1)
    if dist > 5 then  -- Dead zone
        aim.dx = aim.stickX / aim.maxDistance
        aim.dy = aim.stickY / aim.maxDistance
        
        -- Auto-shoot when stick is stretched (90% or more)
        aim.shooting = (dist >= aim.maxDistance * 0.9)
    else
        aim.dx = 0
        aim.dy = 0
        aim.shooting = false
    end
end

function TouchControls:draw()
    local joy = self.joystick
    local aim = self.aimJoystick
    
    -- Draw movement joystick base
    love.graphics.setColor(0.2, 0.2, 0.3, 0.6)
    love.graphics.circle("fill", joy.baseX, joy.baseY, joy.baseRadius)
    
    love.graphics.setColor(0.3, 0.3, 0.4, 0.4)
    love.graphics.circle("fill", joy.baseX, joy.baseY, joy.baseRadius - 5)
    
    -- Draw movement joystick stick
    local stickAlpha = joy.active and 0.9 or 0.6
    love.graphics.setColor(0.4, 0.6, 1.0, stickAlpha)
    love.graphics.circle("fill", joy.baseX + joy.stickX, joy.baseY + joy.stickY, joy.stickRadius)
    
    love.graphics.setColor(0.6, 0.8, 1.0, stickAlpha * 0.8)
    love.graphics.circle("fill", joy.baseX + joy.stickX, joy.baseY + joy.stickY, joy.stickRadius - 5)
    
    -- Draw aim joystick base
    love.graphics.setColor(0.2, 0.2, 0.3, 0.6)
    love.graphics.circle("fill", aim.baseX, aim.baseY, aim.baseRadius)
    
    love.graphics.setColor(0.3, 0.3, 0.4, 0.4)
    love.graphics.circle("fill", aim.baseX, aim.baseY, aim.baseRadius - 5)
    
    -- Draw aim joystick stick (red/orange for shooting theme)
    local aimAlpha = aim.active and 0.9 or 0.6
    if aim.shooting then
        love.graphics.setColor(1.0, 0.3, 0.3, aimAlpha)  -- Red when shooting
    else
        love.graphics.setColor(1.0, 0.5, 0.2, aimAlpha)  -- Orange when aiming
    end
    love.graphics.circle("fill", aim.baseX + aim.stickX, aim.baseY + aim.stickY, aim.stickRadius)
    
    if aim.shooting then
        love.graphics.setColor(1.0, 0.5, 0.5, aimAlpha * 0.8)
    else
        love.graphics.setColor(1.0, 0.7, 0.4, aimAlpha * 0.8)
    end
    love.graphics.circle("fill", aim.baseX + aim.stickX, aim.baseY + aim.stickY, aim.stickRadius - 5)
    
    -- Draw crosshair on aim joystick stick
    if aim.active and (aim.dx ~= 0 or aim.dy ~= 0) then
        love.graphics.setColor(1, 1, 1, aimAlpha)
        love.graphics.setLineWidth(2)
        local crossX = aim.baseX + aim.stickX
        local crossY = aim.baseY + aim.stickY
        love.graphics.line(crossX - 8, crossY, crossX + 8, crossY)
        love.graphics.line(crossX, crossY - 8, crossX, crossY + 8)
        love.graphics.setLineWidth(1)
    end
    
    -- Labels
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.printf("MOVE", joy.baseX - 30, joy.baseY + joy.baseRadius + 10, 60, "center")
    love.graphics.printf("AIM", aim.baseX - 30, aim.baseY + aim.baseRadius + 10, 60, "center")
end

return TouchControls
