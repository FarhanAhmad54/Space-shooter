-- Utility functions for the game

local util = {}

-- Calculate distance between two points
function util.distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

-- Calculate angle between two points
function util.angle(x1, y1, x2, y2)
    return math.atan2(y2 - y1, x2 - x1)
end

-- Check collision between two circles
function util.checkCollision(x1, y1, r1, x2, y2, r2)
    return util.distance(x1, y1, x2, y2) < r1 + r2
end

-- Remove dead entities from a table
function util.removeDeadEntities(entities)
    for i = #entities, 1, -1 do
        if entities[i].dead then
            table.remove(entities, i)
        end
    end
end

-- Linear interpolation
function util.lerp(a, b, t)
    t = math.max(0, math.min(1, t or 0))
    return a + (b - a) * t
end

function util.clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

function util.safeNumber(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value then
        return fallback or 0
    end
    return value
end

function util.wrapAngle(angle)
    angle = angle or 0
    while angle > math.pi do angle = angle - math.pi * 2 end
    while angle < -math.pi do angle = angle + math.pi * 2 end
    return angle
end

-- Get random position on screen edge
function util.getRandomEdgePosition()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local side = math.random(1, 4)
    local x, y
    
    if side == 1 then -- Top
        x = math.random(0, screenWidth)
        y = -20
    elseif side == 2 then -- Right
        x = screenWidth + 20
        y = math.random(0, screenHeight)
    elseif side == 3 then -- Bottom
        x = math.random(0, screenWidth)
        y = screenHeight + 20
    else -- Left
        x = -20
        y = math.random(0, screenHeight)
    end
    
    return x, y
end

return util
