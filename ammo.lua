-- Ammo pickup module

local Ammo = {}
Ammo.__index = Ammo

Ammo.types = {
    shotgun   = {amount=15, color={1,0.5,0}, label="S"},
    machinegun= {amount=50, color={0.5,0.5,1}, label="M"},
    sniper    = {amount=5,  color={1,0,0.5}, label="R"},
}

function Ammo.new(x, y, ammoType)
    local self=setmetatable({},Ammo)
    self.x=x; self.y=y; self.radius=10
    self.type=Ammo.types[ammoType] and ammoType or "shotgun"
    self.dead=false; self.pulseTimer=0; self.age=0
    self.maxLifetime=20; self.lifetime=self.maxLifetime
    self.quality="high"
    self.amounts = {shotgun=15, machinegun=50, sniper=5}
    self.colors = {shotgun={1,0.5,0}, machinegun={0.5,0.5,1}, sniper={1,0,0.5}}
    return self
end

function Ammo:setQuality(quality)
    if quality=="low" or quality=="medium" or quality=="high" then self.quality=quality end
end

function Ammo:update(dt)
    self.pulseTimer=self.pulseTimer+dt; self.age=self.age+dt; self.lifetime=self.lifetime-dt
    if self.lifetime<=0 then self.dead=true end
end

function Ammo:draw()
    if self.dead then return end
    local data=Ammo.types[self.type] or Ammo.types.shotgun
    local pulse=math.sin(self.pulseTimer*5)*0.3+0.7
    local bob=math.sin(self.pulseTimer*2.5)*2
    local gx,gy=self.x,self.y+bob
    local glowScale=self.quality=="low" and 0.5 or (self.quality=="medium" and 0.75 or 1)

    love.graphics.setColor(data.color[1],data.color[2],data.color[3],0.22*pulse*glowScale)
    love.graphics.circle("fill",gx,gy,self.radius+5*pulse)
    love.graphics.setColor(data.color[1],data.color[2],data.color[3],0.95)
    love.graphics.rectangle("fill",gx-self.radius,gy-self.radius,self.radius*2,self.radius*2,3,3)
    love.graphics.setColor(1,1,1,0.9)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line",gx-self.radius+1,gy-self.radius+1,self.radius*2-2,self.radius*2-2,3,3)
    local font=love.graphics.getFont()
    local label=data.label
    love.graphics.print(label,gx-font:getWidth(label)/2,gy-font:getHeight()/2)
    love.graphics.setLineWidth(1)
end

function Ammo:getAmount()
    return (Ammo.types[self.type] and Ammo.types[self.type].amount) or 10
end

function Ammo:isDead() return self.dead end
function Ammo:kill() self.dead=true end

return Ammo
