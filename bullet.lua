-- Starfall Vengeance projectile system
local util = require("util")

local Bullet = {}
Bullet.__index = Bullet

local COLOR = {
    yellow = {1.0, 0.82, 0.18},
    blue = {0.25, 0.75, 1.0},
    green = {0.25, 1.0, 0.45},
    red = {1.0, 0.28, 0.28},
    purple = {0.82, 0.4, 1.0},
    white = {1.0, 1.0, 1.0}
}

function Bullet.new(x, y, angle, owner, color)
    local self = setmetatable({}, Bullet)
    self.x, self.y = x or 0, y or 0
    self.angle = angle or 0
    self.owner = owner or "player"
    self.colorName = color or (self.owner == "enemy" and "red" or "yellow")
    self.color = COLOR[self.colorName] or COLOR.yellow
    self.radius = self.owner == "enemy" and 4 or 5
    self.speed = self.owner == "enemy" and 260 or 400
    self.vx = math.cos(self.angle) * self.speed
    self.vy = math.sin(self.angle) * self.speed
    self.damage = 1
    self.dead = false
    self.age = 0
    self.maxAge = 4
    self.piercing = false
    self.homing = false
    self.homingStrength = 3.0
    self.explosion = false
    self.explosionRadius = 40
    self.trail = {}
    self.trailTimer = 0
    self.maxTrail = 5
    return self
end

local function acquireTarget(self, enemies)
    local nearest, nearestDist = nil, math.huge
    for _, enemy in ipairs(enemies or {}) do
        if enemy and not enemy.dead then
            local d = util.distance(self.x, self.y, enemy.x, enemy.y)
            if d < nearestDist then
                nearest, nearestDist = enemy, d
            end
        end
    end
    return nearest, nearestDist
end

function Bullet:update(dt, enemies)
    if self.dead then return end
    dt = math.max(0, dt or 0)
    self.age = self.age + dt
    if self.age >= self.maxAge then
        self.dead = true
        return
    end

    if self.homing and self.owner == "player" then
        local target, dist = acquireTarget(self, enemies)
        if target and dist < 500 then
            local targetAngle = util.angle(self.x, self.y, target.x, target.y)
            local delta = math.atan2(math.sin(targetAngle - self.angle), math.cos(targetAngle - self.angle))
            local maxTurn = self.homingStrength * dt
            delta = math.max(-maxTurn, math.min(maxTurn, delta))
            self.angle = self.angle + delta
            self.vx = math.cos(self.angle) * self.speed
            self.vy = math.sin(self.angle) * self.speed
        end
    end

    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    self.trailTimer = self.trailTimer + dt
    if self.trailTimer >= 0.035 then
        self.trailTimer = 0
        table.insert(self.trail, 1, {x = self.x, y = self.y})
        if #self.trail > self.maxTrail then table.remove(self.trail) end
    end

    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local margin = 80
    if self.x < -margin or self.x > w + margin or self.y < -margin or self.y > h + margin then
        self.dead = true
    end
end

function Bullet:draw()
    if self.dead then return end
    local r, g, b = self.color[1], self.color[2], self.color[3]

    for i = #self.trail, 1, -1 do
        local t = self.trail[i]
        local alpha = 0.04 + 0.10 * (i / #self.trail)
        love.graphics.setColor(r, g, b, alpha)
        love.graphics.circle("fill", t.x, t.y, self.radius * (0.55 + i / (#self.trail * 2)))
    end

    local glow = 0.25 + 0.15 * math.sin(self.age * 30)
    love.graphics.setColor(r, g, b, glow)
    love.graphics.circle("fill", self.x, self.y, self.radius * 2.2)
    love.graphics.setColor(1, 1, 1, 0.92)
    love.graphics.circle("fill", self.x, self.y, self.radius * 0.65)
    love.graphics.setColor(r, g, b, 1)
    love.graphics.circle("fill", self.x, self.y, self.radius)

    if self.explosion then
        love.graphics.setColor(r, g, b, 0.16)
        love.graphics.circle("line", self.x, self.y, self.explosionRadius * (0.92 + 0.08 * math.sin(self.age * 18)))
    end
end

return Bullet
