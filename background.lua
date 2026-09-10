-- Starfall Vengeance background system
-- Kenney planet sprites + layered parallax starfield.

local Background = {}
Background.__index = Background

local PLANET_COUNT = 10
local planetImages = {}
local planetPaths = {}

local function tryImage(paths)
    for _, path in ipairs(paths) do
        if love.filesystem.getInfo(path) then
            local ok, image = pcall(love.graphics.newImage, path)
            if ok then return image, path end
        end
    end
    return nil, nil
end

local function loadPlanets()
    for i=0,PLANET_COUNT-1 do
        local n=tostring(i)
        local name=string.format("planet%02d.png",i)
        local image,path=tryImage({
            "assets/kenney_planets/Planets/"..name,
            "assets/kenney_planets/"..name,
            "assets/Planets/"..name,
            "assets/"..name
        })
        planetImages[i]=image; planetPaths[i]=path
    end
end

function Background.new()
    local self=setmetatable({},Background)
    self.stars={}
    self.planets={}
    self.bossMode=false
    self.quality="high"
    self.time=0
    loadPlanets()

    local w,h=love.graphics.getDimensions()
    local counts={low=60,medium=100,high=140}
    for i=1,counts[self.quality] do
        local layer = i <= counts[self.quality]*0.42 and 1 or (i <= counts[self.quality]*0.75 and 2 or 3)
        local sizes={1,1.5,2.5}; local speeds={15,35,60}; local minB={0.25,0.45,0.7}
        self.stars[#self.stars+1]={x=math.random(0,w),y=math.random(0,h),size=sizes[layer],speed=speeds[layer]*math.random(80,120)/100,brightness=minB[layer]+math.random()*0.25,twinkle=math.random()*6.28,layer=layer}
    end

    local planetTotal=math.random(3,5)
    for i=1,planetTotal do
        local image=planetImages[math.random(0,PLANET_COUNT-1)]
        local diameter=math.random(90,170)
        self.planets[#self.planets+1]={x=math.random(-50,w+50),y=math.random(-h,h),size=diameter,speed=math.random(12,28),image=image,alpha=math.random(20,45)/100,layer=(i%2==0 and 2 or 1),rotation=(math.random()-0.5)*0.2,rotSpeed=(math.random()-0.5)*0.015,phase=math.random()*6.28,color={0.55,0.75,1}}
    end
    return self
end

function Background:setQuality(quality)
    if quality~="low" and quality~="medium" and quality~="high" then return end
    self.quality=quality
end

function Background:setBossMode(enabled) self.bossMode=enabled==true end

function Background:update(dt)
    self.time=self.time+dt
    local w,h=love.graphics.getDimensions()
    for _,s in ipairs(self.stars) do
        s.y=s.y+s.speed*dt
        if s.y>h+5 then s.y=-5; s.x=math.random(0,w) end
    end
    for _,p in ipairs(self.planets) do
        p.y=p.y+p.speed*dt
        p.rotation=p.rotation+p.rotSpeed*dt
        if p.y>h+p.size/2 then p.y=-p.size/2; p.x=math.random(-50,w+50) end
    end
end

function Background:draw()
    local w,h=love.graphics.getDimensions()
    for _,s in ipairs(self.stars) do
        local twinkle=0.9+0.1*math.sin(self.time*2+s.twinkle)
        local a=s.brightness*twinkle
        love.graphics.setColor(1,1,1,a)
        love.graphics.circle("fill",s.x,s.y,s.size)
    end

    for _,p in ipairs(self.planets) do
        local glow=self.bossMode and 0.22 or 0.10
        love.graphics.setColor(p.color[1],p.color[2],p.color[3],glow*p.alpha)
        love.graphics.circle("fill",p.x,p.y,p.size*0.6)
        if p.image then
            love.graphics.setColor(1,1,1,p.alpha)
            local scale=p.size/math.max(p.image:getWidth(),p.image:getHeight())
            love.graphics.draw(p.image,p.x,p.y,p.rotation,scale,scale,p.image:getWidth()/2,p.image:getHeight()/2)
        else
            -- Safe visual fallback if Kenney assets are not mounted.
            love.graphics.setColor(0.2,0.35,0.65,p.alpha)
            love.graphics.circle("fill",p.x,p.y,p.size*0.5)
        end
    end
end

return Background
