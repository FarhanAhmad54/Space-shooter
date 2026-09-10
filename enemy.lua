-- Enemy module with sprite support

local util = require("util")

local Enemy = {}
Enemy.__index = Enemy

Enemy.types = {
    swarmer = {speed=120,health=10,radius=12,color={1,0.6,0.2},score=15,xp=15,shootCooldown=0,imageName="swarmer"},
    sniper = {speed=40,health=50,radius=14,color={0.2,0.8,1},score=25,xp=25,shootCooldown=2.5,imageName="sniper"},
    bomber = {speed=80,health=50,radius=16,color={1,1,0},score=30,xp=30,shootCooldown=0,explodeRadius=60,explodeDamage=2,imageName="bomber"},
    turret = {speed=30,health=50,radius=13,color={0.6,0.2,0.6},score=20,xp=20,shootCooldown=1.5,imageName="turret"},
    miniboss = {speed=50,health=300,radius=22,color={0.8,0.2,0.2},score=50,xp=50,shootCooldown=1.0,imageName="miniboss"},
    serpent = {speed=90,health=10,radius=10,color={0.5,1,0.5},score=20,xp=20,shootCooldown=0,serpentLength=5,imageName="swarmer"},
    teleporter = {speed=0,health=150,radius=13,color={0.8,0.3,1},score=35,xp=35,shootCooldown=2.0,teleportCooldown=2.5,imageName="sniper"},
    carrier = {speed=30,health=150,radius=25,color={0.9,0.5,0.2},score=80,xp=80,shootCooldown=0,spawnCooldown=4.0,imageName="miniboss"},
    shielded = {speed=70,health=50,radius=14,color={0.4,0.7,1},score=40,xp=40,shootCooldown=3.0,shieldHealth=3,imageName="turret"}
}

function Enemy.new(x,y,enemyType,enemyImage)
    local self=setmetatable({},Enemy)
    enemyType=enemyType or "swarmer"
    local typeData=Enemy.types[enemyType]
    self.x=x; self.y=y; self.type=enemyType; self.speed=typeData.speed; self.radius=typeData.radius
    self.health=typeData.health; self.maxHealth=typeData.health; self.color=typeData.color; self.score=typeData.score
    self.dead=false; self.quality="high"; self.age=0; self.damage=1; self.damageCooldown=0; self.image=enemyImage
    self.shootTimer=typeData.shootCooldown or 0; self.shootCooldown=typeData.shootCooldown or 0
    if enemyType=="serpent" then self.trail={}; self.trailTimer=0
    elseif enemyType=="teleporter" then self.teleportTimer=typeData.teleportCooldown
    elseif enemyType=="carrier" then self.spawnTimer=typeData.spawnCooldown; self.spawnCooldown=typeData.spawnCooldown
    elseif enemyType=="shielded" then self.shieldHealth=typeData.shieldHealth; self.maxShieldHealth=typeData.shieldHealth end
    return self
end

function Enemy.getRandomType(wave)
    local availableTypes={"swarmer"}
    if wave>=2 then table.insert(availableTypes,"turret") end
    if wave>=3 then table.insert(availableTypes,"sniper") end
    if wave>=4 then table.insert(availableTypes,"bomber") end
    if wave>=5 then table.insert(availableTypes,"miniboss") end
    if wave>=6 then table.insert(availableTypes,"serpent") end
    if wave>=8 then table.insert(availableTypes,"teleporter") end
    if wave>=10 then table.insert(availableTypes,"shielded") end
    if wave>=12 then table.insert(availableTypes,"carrier") end
    return availableTypes[math.random(#availableTypes)]
end

function Enemy:setQuality(quality) if quality=="low" or quality=="medium" or quality=="high" then self.quality=quality end end

function Enemy:update(dt,playerX,playerY)
    dt=dt*(_G.__SV_TIME_SCALE or 1)
    local angle=util.angle(self.x,self.y,playerX,playerY)

    if self.type=="serpent" then
        self.trailTimer=self.trailTimer+dt
        if self.trailTimer>0.1 then
            table.insert(self.trail,1,{x=self.x,y=self.y})
            if #self.trail>5 then table.remove(self.trail) end
            self.trailTimer=0
        end
        local sineOffset=math.sin(love.timer.getTime()*3)*30
        self.x=self.x+math.cos(angle)*self.speed*dt+math.cos(angle+math.pi/2)*sineOffset*dt
        self.y=self.y+math.sin(angle)*self.speed*dt+math.sin(angle+math.pi/2)*sineOffset*dt
    elseif self.type=="teleporter" then
        self.teleportTimer=self.teleportTimer-dt
        if self.teleportTimer<=0 then
            local dist=math.random(150,250); local randomAngle=math.random()*math.pi*2
            self.x=playerX+math.cos(randomAngle)*dist; self.y=playerY+math.sin(randomAngle)*dist; self.teleportTimer=2.5
        end
        self.shootTimer=self.shootTimer-dt
    elseif self.type=="carrier" then
        self.spawnTimer=self.spawnTimer-dt
        local dist=util.distance(self.x,self.y,playerX,playerY)
        if dist>200 then self.x=self.x+math.cos(angle)*self.speed*dt; self.y=self.y+math.sin(angle)*self.speed*dt end
    else
        if self.shootCooldown>0 then
            local dist=util.distance(self.x,self.y,playerX,playerY)
            if dist>200 then self.x=self.x+math.cos(angle)*self.speed*dt; self.y=self.y+math.sin(angle)*self.speed*dt end
            self.shootTimer=self.shootTimer-dt
        else
            self.x=self.x+math.cos(angle)*self.speed*dt; self.y=self.y+math.sin(angle)*self.speed*dt
        end
    end
    if self.damageCooldown>0 then self.damageCooldown=self.damageCooldown-dt end
end

function Enemy:canShoot()
    if self.shootCooldown>0 and self.shootTimer<=0 then self.shootTimer=self.shootCooldown; return true end
    return false
end

function Enemy:takeDamage(damage)
    if self.type=="shielded" and self.shieldHealth>0 then
        self.shieldHealth=self.shieldHealth-damage
        if self.shieldHealth<0 then self.health=self.health+self.shieldHealth; self.shieldHealth=0 end
    else self.health=self.health-damage end
    if self.health<=0 then self.dead=true end
end

function Enemy:canDamagePlayer()
    if self.damageCooldown<=0 then self.damageCooldown=1.0; return true end
    return false
end

function Enemy:draw(playerX,playerY)
    if self.image then
        local r,g,b=self.color[1],self.color[2],self.color[3]
        local pulse=math.sin(love.timer.getTime()*3)*0.2+0.8
        love.graphics.setColor(r,g,b,0.15*pulse); love.graphics.circle("fill",self.x,self.y,self.radius+10)
        love.graphics.setColor(r,g,b,0.25*pulse); love.graphics.circle("fill",self.x,self.y,self.radius+7)
        love.graphics.setColor(r,g,b,0.4*pulse); love.graphics.circle("fill",self.x,self.y,self.radius+4)
        love.graphics.setColor(r,g,b,0.6*pulse); love.graphics.circle("fill",self.x,self.y,self.radius+2)
        love.graphics.setColor(1,1,1)
        local scale=(self.radius*2)/math.max(self.image:getWidth(),self.image:getHeight())
        love.graphics.draw(self.image,self.x,self.y,0,scale,scale,self.image:getWidth()/2,self.image:getHeight()/2)
    else
        local healthPercent=self.health/self.maxHealth; local r,g,b=self.color[1],self.color[2],self.color[3]
        if self.type=="bomber" and playerX and playerY then
            local dist=util.distance(self.x,self.y,playerX,playerY)
            if dist<150 then
                local glowIntensity=math.max(0,1-dist/150); local pulse=math.sin(love.timer.getTime()*15)*0.5+0.5
                love.graphics.setColor(1,0,0,0.6*glowIntensity*pulse); love.graphics.circle("fill",self.x,self.y,self.radius+12)
            end
        end
        r=r*(0.5+healthPercent*0.5); g=g*(0.5+healthPercent*0.5); b=b*(0.5+healthPercent*0.5)
        love.graphics.setColor(r,g,b,0.4); love.graphics.circle("fill",self.x,self.y,self.radius+3)
        love.graphics.setColor(r,g,b); love.graphics.circle("fill",self.x,self.y,self.radius)
        love.graphics.setColor(r+0.3,g+0.3,b+0.3,0.6); love.graphics.circle("fill",self.x-3,self.y-3,self.radius*0.3)
    end
    if self.health>0 and self.maxHealth>1 then
        local barWidth=self.radius*2.5; local barHeight=4; local barX=self.x-barWidth/2; local barY=self.y-self.radius-10
        love.graphics.setColor(0.3,0.3,0.3,0.8); love.graphics.rectangle("fill",barX,barY,barWidth,barHeight)
        local healthPercent=math.max(0,math.min(1,self.health/self.maxHealth))
        love.graphics.setColor(0,1,1); love.graphics.rectangle("fill",barX,barY,barWidth*healthPercent,barHeight)
    end
end

return Enemy
