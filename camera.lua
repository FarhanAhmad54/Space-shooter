-- Enhanced camera module with smooth following and advanced shake effects

local Camera = {}
Camera.__index = Camera

function Camera.new()
    local self = setmetatable({}, Camera)
    self.x = 0
    self.y = 0
    self.shakeIntensity = 0
    self.shakeDuration = 0
    self.shakeRotation = 0
    self.shakeRotationIntensity = 0
    self.shakeTime = 0
    self.shakeAge = 0
    self.quality = "high"
    self.offsetX = 0
    self.offsetY = 0
    
    -- Smooth following
    self.targetX = 0
    self.targetY = 0
    self.followSpeed = 7
    
    -- Zoom
    self.zoom = 1
    self.targetZoom = 1
    self.zoomSpeed = 3
    
    return self
end

function Camera:update(dt)
    -- Smooth follow without accumulating transient shake offsets.
    local followT = math.min(1, self.followSpeed * dt)
    self.x = self.x + (self.targetX - self.x) * followT
    self.y = self.y + (self.targetY - self.y) * followT

    local zoomT = math.min(1, self.zoomSpeed * dt)
    self.zoom = self.zoom + (self.targetZoom - self.zoom) * zoomT

    self.shakeAge = self.shakeAge + dt
    if self.shakeDuration > 0 then
        self.shakeDuration = math.max(0, self.shakeDuration - dt)
        local progress = self.shakeDuration / math.max(self.shakeTime, 0.0001)
        local falloff = progress * progress
        local qualityScale = self.quality == "low" and 0.6 or (self.quality == "medium" and 0.8 or 1.0)
        local amplitude = self.shakeIntensity * falloff * qualityScale
        self.offsetX = (math.random() - 0.5) * amplitude
        self.offsetY = (math.random() - 0.5) * amplitude
        self.shakeRotation = (math.random() - 0.5) * self.shakeRotationIntensity * 0.05 * falloff * qualityScale
    else
        self.offsetX, self.offsetY, self.shakeRotation = 0, 0, 0
    end
end

function Camera:shake(intensity, duration, rotationIntensity)
    self.shakeIntensity = math.max(0, intensity or 10)
    self.shakeDuration = math.max(0, duration or 0.3)
    self.shakeTime = self.shakeDuration
    self.shakeAge = 0
    self.shakeRotationIntensity = rotationIntensity or 0
end

function Camera:setQuality(quality)
    if quality == "low" or quality == "medium" or quality == "high" then
        self.quality = quality
    end
end

function Camera:setTarget(x, y)
    self.targetX = x
    self.targetY = y
end

function Camera:setZoom(zoom)
    self.targetZoom = zoom
end

function Camera:apply()
    love.graphics.push()
    
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Apply zoom from center
    love.graphics.translate(w/2, h/2)
    love.graphics.scale(self.zoom, self.zoom)
    love.graphics.rotate(self.shakeRotation)
    love.graphics.translate(-w/2, -h/2)
    
    -- Apply camera position
    love.graphics.translate(self.x + self.offsetX, self.y + self.offsetY)
end

function Camera:unapply()
    love.graphics.pop()
end

return Camera
