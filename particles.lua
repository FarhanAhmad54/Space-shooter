-- Starfall Vengeance production particle system. Lua 5.1/LuaJIT-safe random ranges.
local Particles={}; Particles.__index=Particles
local function frand(a,b) return a+math.random()*(b-a) end
function Particles.new() return setmetatable({particles={},quality="high"},Particles) end
function Particles:setQuality(q) if q=="low" or q=="medium" or q=="high" then self.quality=q end end
function Particles:update(dt)
    for i=#self.particles,1,-1 do
        local p=self.particles[i]; p.x=p.x+(p.vx or 0)*dt; p.y=p.y+(p.vy or 0)*dt
        p.vx=(p.vx or 0)+(p.ax or 0)*dt; p.vy=(p.vy or 0)+(p.ay or 0)*dt
        if p.drag then local d=math.max(0,1-p.drag*dt); p.vx=p.vx*d; p.vy=p.vy*d end
        p.life=p.life-dt; p.size=p.size+(p.growRate or 0)*dt; p.rotation=(p.rotation or 0)+(p.rotationSpeed or 0)*dt
        if p.life<=0 or p.size<=0 then table.remove(self.particles,i) end
    end
end
function Particles:draw()
    for _,p in ipairs(self.particles) do
        local a=math.max(0,p.life/(p.maxLife or 1))*(p.alpha or 1); love.graphics.setColor(p.r,p.g,p.b,a)
        if p.shape=="line" then local ang=p.rotation or math.atan2(p.vy or 0,p.vx or 0); local len=p.length or p.size*2; local dx=math.cos(ang)*len; local dy=math.sin(ang)*len; love.graphics.setLineWidth(math.max(1,p.size)); love.graphics.line(p.x-dx*.5,p.y-dy*.5,p.x+dx*.5,p.y+dy*.5); love.graphics.setLineWidth(1)
        elseif p.shape=="square" then love.graphics.push(); love.graphics.translate(p.x,p.y); love.graphics.rotate(p.rotation or 0); love.graphics.rectangle("fill",-p.size,-p.size,p.size*2,p.size*2); love.graphics.pop()
        elseif p.shape=="ring" then love.graphics.circle("line",p.x,p.y,p.size); else love.graphics.circle("fill",p.x,p.y,p.size) end
    end
end
function Particles:add(p) self.particles[#self.particles+1]=p end
function Particles:explosion(x,y,size,preset)
    size=size or 1; local pal={
        fire={{1,.85,.25},{1,.35,.05},{1,.08,.02}},
        electric={{.55,.85,1},{.25,.45,1},{1,1,1}},
        default={{1,1,.45},{1,.5,.08},{1,.15,.08}}
    }; local c=pal[preset] or pal.default
    self:add({x=x,y=y,vx=0,vy=0,size=5*size,r=c[1][1],g=c[1][2],b=c[1][3],life=.28,maxLife=.28,shape="ring",growRate=220*size,alpha=.65})
    local count=self.quality=="low" and math.floor(12*size) or (self.quality=="medium" and math.floor(18*size) or math.floor(26*size))
    for i=1,math.max(4,count) do local a=(i/count)*math.pi*2; local sp=frand(80,210)*size; local cc=c[math.random(#c)]; self:add({x=x,y=y,vx=math.cos(a)*sp,vy=math.sin(a)*sp,size=frand(1.5,5)*size,r=cc[1],g=cc[2],b=cc[3],life=frand(.3,.65),maxLife=.65,shape="circle",drag=2,growRate=-7*size,alpha=.95}) end
    self:add({x=x,y=y,vx=0,vy=0,size=16*size,r=1,g=1,b=1,life=.08,maxLife=.08,shape="circle",growRate=120*size,alpha=.8})
end
function Particles:impact(x,y,angle,intensity)
    intensity=intensity or 1; local count=math.max(3,math.floor((self.quality=="low" and 5 or 9)*intensity))
    for i=1,count do local a=angle+frand(-1.0,1.0); local sp=frand(90,250)*intensity; self:add({x=x,y=y,vx=math.cos(a)*sp,vy=math.sin(a)*sp,size=frand(1,3),r=1,g=frand(.45,.85),b=.12,life=frand(.18,.42),maxLife=.42,shape="line",length=frand(4,11),rotation=a,drag=3,alpha=.9}) end
end
function Particles:trail(x,y,vx,vy,color) color=color or {1,1,0}; self:add({x=x,y=y,vx=-(vx or 0)*.08,vy=-(vy or 0)*.08,size=frand(1.5,3.5),r=color[1],g=color[2],b=color[3],life=.25,maxLife=.25,shape="circle",growRate=-5,alpha=.55}) end
function Particles:energyField(x,y,radius,color) color=color or {0,1,1}; for i=1,2 do local a=math.random()*math.pi*2; local d=frand(0,radius); self:add({x=x+math.cos(a)*d,y=y+math.sin(a)*d,vx=-math.sin(a)*frand(40,100),vy=math.cos(a)*frand(40,100),size=frand(1,3),r=color[1],g=color[2],b=color[3],life=.5,maxLife=.5,shape="circle",alpha=.7}) end end
function Particles:dashTrail(x,y,radius,color) color=color or {.2,.6,1}; self:add({x=x,y=y,vx=0,vy=0,size=radius,r=color[1],g=color[2],b=color[3],life=.2,maxLife=.2,shape="circle",alpha=.4,growRate=-radius*3}) end
function Particles:thruster(x,y,angle,power) power=power or 1; for i=1,2 do local a=angle+frand(-.35,.35); local sp=frand(50,150)*power; self:add({x=x,y=y,vx=math.cos(a)*sp,vy=math.sin(a)*sp,size=frand(1.5,4),r=1,g=frand(.45,.85),b=0,life=frand(.28,.5),maxLife=.5,shape="circle",drag=2,growRate=-6,alpha=.65}) end end
function Particles:deathBurst(x,y,color,size) color=color or {1,0,0}; size=size or 1; local count=math.floor(16*size); for i=1,count do local a=(i/count)*math.pi*2; local sp=frand(80,180)*size; self:add({x=x,y=y,vx=math.cos(a)*sp,vy=math.sin(a)*sp,size=frand(2,5)*size,r=color[1],g=color[2],b=color[3],life=frand(.4,.7),maxLife=.7,shape="square",rotationSpeed=frand(-10,10),drag=1.5,growRate=-4*size,alpha=.8}) end end
function Particles:healEffect(x,y,radius) for i=1,10 do local a=(i/10)*math.pi*2; self:add({x=x+math.cos(a)*radius,y=y+math.sin(a)*radius,vx=0,vy=-frand(35,65),ay=-20,size=frand(2,4),r=0,g=.8,b=1,life=.75,maxLife=.75,shape="circle",alpha=.8}) end end
return Particles
