-- Starfall Vengeance projectile system with real projectile artwork.
local util=require("util")
local Assets=require("assets")
local Bullet={}; Bullet.__index=Bullet
local COLOR={yellow={1,.82,.18},blue={.25,.75,1},green={.25,1,.45},red={1,.28,.28},purple={.82,.4,1},white={1,1,1}}
function Bullet.new(x,y,angle,owner,color)
 local s=setmetatable({},Bullet); s.x,s.y=x or 0,y or 0; s.angle=angle or 0; s.owner=owner or "player"; s.colorName=color or (s.owner=="enemy" and "red" or "yellow"); s.color=COLOR[s.colorName] or COLOR.yellow; s.radius=s.owner=="enemy" and 4 or 5; s.speed=s.owner=="enemy" and 260 or 400; s.vx=math.cos(s.angle)*s.speed; s.vy=math.sin(s.angle)*s.speed; s.damage=1; s.dead=false; s.age=0; s.maxAge=4; s.piercing=false; s.homing=false; s.homingStrength=3; s.explosion=false; s.explosionRadius=40; s.trail={}; s.trailTimer=0; s.maxTrail=5; return s
end
local function acquireTarget(self,enemies)
 local nearest,dist=nil,math.huge
 for _,e in ipairs(enemies or {}) do if e and not e.dead then local d=util.distance(self.x,self.y,e.x,e.y); if d<dist then nearest,dist=e,d end end end
 return nearest,dist
end
function Bullet:update(dt,enemies)
 if self.dead then return end; dt=math.max(0,dt or 0); self.age=self.age+dt; if self.age>=self.maxAge then self.dead=true; return end
 if self.homing and self.owner=="player" then local target,dist=acquireTarget(self,enemies); if target and dist<500 then local ta=util.angle(self.x,self.y,target.x,target.y); local delta=math.atan2(math.sin(ta-self.angle),math.cos(ta-self.angle)); local turn=math.max(-self.homingStrength*dt,math.min(self.homingStrength*dt,delta)); self.angle=self.angle+turn; self.vx=math.cos(self.angle)*self.speed; self.vy=math.sin(self.angle)*self.speed end end
 self.x=self.x+self.vx*dt; self.y=self.y+self.vy*dt; self.trailTimer=self.trailTimer+dt
 if self.trailTimer>=.035 then self.trailTimer=0; table.insert(self.trail,1,{x=self.x,y=self.y}); if #self.trail>self.maxTrail then table.remove(self.trail) end end
 local w,h=love.graphics.getWidth(),love.graphics.getHeight(); if self.x<-80 or self.x>w+80 or self.y<-80 or self.y>h+80 then self.dead=true end
end
local function drawSprite(img,x,y,size,angle,r,g,b,a)
 if not img then return false end; local scale=size/math.max(1,math.max(img:getWidth(),img:getHeight())); love.graphics.setColor(r,g,b,a or 1); love.graphics.draw(img,x,y,angle,scale,scale,img:getWidth()/2,img:getHeight()/2); return true
end
function Bullet:draw()
 if self.dead then return end; local r,g,b=self.color[1],self.color[2],self.color[3]
 for i=#self.trail,1,-1 do local t=self.trail[i]; love.graphics.setColor(r,g,b,.035+.08*(i/#self.trail)); love.graphics.circle("fill",t.x,t.y,self.radius*(.55+i/(#self.trail*2))) end
 local img
 if self.owner=="enemy" then img=(self.colorName=="purple" and Assets.get("plasma")) or Assets.get("bullet1") or Assets.get("bullet")
 elseif self.explosion then img=Assets.get("rocket") or Assets.get("plasma")
 elseif self.colorName=="blue" then img=Assets.get("laser2") or Assets.get("bullet2")
 elseif self.colorName=="green" then img=Assets.get("laser3") or Assets.get("bullet2")
 else img=Assets.get("laser1") or Assets.get("bullet") end
 if not drawSprite(img,self.x,self.y,self.radius*3.6,self.angle,r,g,b,.95) then
  local glow=.25+.15*math.sin(self.age*30); love.graphics.setColor(r,g,b,glow); love.graphics.circle("fill",self.x,self.y,self.radius*2.2); love.graphics.setColor(1,1,1,.92); love.graphics.circle("fill",self.x,self.y,self.radius*.65); love.graphics.setColor(r,g,b,1); love.graphics.circle("fill",self.x,self.y,self.radius)
 end
 if self.explosion then love.graphics.setColor(r,g,b,.16); love.graphics.circle("line",self.x,self.y,self.explosionRadius*(.92+.08*math.sin(self.age*18))) end
end
return Bullet
