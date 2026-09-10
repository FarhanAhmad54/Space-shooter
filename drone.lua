-- Starfall Vengeance companion system with real pet/support artwork.
local util=require("util"); local Assets=require("assets")
local Drone={}; Drone.__index=Drone
Drone.types={
 attack={name="Attack Drone",color={1,.3,.3},shootCooldown=.5,damage=.5,icon="⚔",asset="support"},
 healer={name="Healer Drone",color={.3,1,.3},healCooldown=3,healAmount=1,icon="♥",asset="pet3"},
 defender={name="Defender Drone",color={.3,.3,1},shieldRadius=30,icon="🛡",asset="shield"},
 collector={name="Collector Drone",color={1,1,.3},collectRadius=80,icon="⬡",asset="pet2"},
 pet1={name="Pet 1",color={1,1,.2},shootCooldown=1.5,damage=.5,health=3,maxHealth=3,bulletColor="yellow",asset="pet1"},
 pet2={name="Pet 2",color={.2,.5,1},shootCooldown=1.5,damage=.5,health=3,maxHealth=3,bulletColor="blue",asset="pet2"},
 pet3={name="Pet 3",color={.2,1,.2},shootCooldown=1.5,damage=.5,health=3,maxHealth=3,bulletColor="green",asset="pet3"}
}
function Drone.new(x,y,droneType,playerId)
 local s=setmetatable({},Drone); droneType=droneType or "attack"; local d=Drone.types[droneType] or Drone.types.attack; if not Drone.types[droneType] then droneType="attack" end
 s.x,s.y=x,y; s.type=droneType; s.playerId=playerId; s.radius=12; s.color=d.color; s.dead=false; s.assetKey=d.asset; s.orbitDistance=50; s.orbitAngle=math.random()*math.pi*2; s.orbitSpeed=2; s.formation="pet"; s.formationIndex=0; s.formationCount=1; s.quality="high"
 if droneType=="attack" or droneType=="pet1" or droneType=="pet2" or droneType=="pet3" then s.shootTimer=0; s.shootCooldown=d.shootCooldown; s.damage=d.damage; s.bulletColor=d.bulletColor end
 if droneType=="healer" then s.healTimer=0; s.healCooldown=d.healCooldown; s.healAmount=d.healAmount end
 if droneType=="defender" then s.shieldRadius=d.shieldRadius end
 if droneType=="collector" then s.collectRadius=d.collectRadius end
 if d.health then s.health=d.health; s.maxHealth=d.maxHealth end
 return s
end
function Drone:takeDamage(amount) if self.health then self.health=self.health-(amount or 1); if self.health<=0 then self.dead=true end; return true end; return false end
function Drone:update(dt,player,enemies,bullets,powerups,ammo)
 if self.formation=="side" then local side=self.formationIndex==1 and -1 or 1; local tx=player.x+side*48; local ty=player.y+18+math.sin(love.timer.getTime()*3+self.formationIndex)*6; local t=math.min(1,10*dt); self.x=self.x+(tx-self.x)*t; self.y=self.y+(ty-self.y)*t; self.orbitAngle=0
 elseif self.formation=="orbit_upgrade" then self.orbitAngle=self.orbitAngle+self.orbitSpeed*dt; local off=(self.formationIndex-1)*math.pi; self.x=player.x+math.cos(self.orbitAngle+off)*60; self.y=player.y+math.sin(self.orbitAngle+off)*60
 else self.orbitAngle=self.orbitAngle+self.orbitSpeed*dt; self.x=player.x+math.cos(self.orbitAngle)*self.orbitDistance; self.y=player.y+math.sin(self.orbitAngle)*self.orbitDistance end
 if self.type=="attack" or self.type=="pet1" or self.type=="pet2" or self.type=="pet3" then
  self.shootTimer=self.shootTimer-dt
  if self.shootTimer<=0 and #enemies>0 then local nearest=enemies[1]; local nd=util.distance(self.x,self.y,nearest.x,nearest.y); for _,e in ipairs(enemies) do local q=util.distance(self.x,self.y,e.x,e.y); if q<nd then nearest,nd=e,q end end; local a=util.angle(self.x,self.y,nearest.x,nearest.y); self.shootTimer=self.shootCooldown; return {type="shoot",angle=a,damage=self.damage,color=self.bulletColor} end
 elseif self.type=="healer" then self.healTimer=self.healTimer-dt; if self.healTimer<=0 and player.health<player.maxHealth then self.healTimer=self.healCooldown; return {type="heal",amount=self.healAmount} end
 elseif self.type=="defender" then for _,b in ipairs(bullets) do if b.owner=="enemy" and util.distance(self.x,self.y,b.x,b.y)<self.shieldRadius then b.dead=true end end
 elseif self.type=="collector" then for _,p in ipairs(powerups) do if util.distance(self.x,self.y,p.x,p.y)<self.collectRadius then local a=util.angle(p.x,p.y,player.x,player.y); p.x=p.x+math.cos(a)*200*dt; p.y=p.y+math.sin(a)*200*dt end end end
end
function Drone:setQuality(q) if q=="low" or q=="medium" or q=="high" then self.quality=q end end
function Drone:draw()
 local d=Drone.types[self.type]; local pulse=math.sin(love.timer.getTime()*5)*.3+.7; local gs=self.quality=="low" and .5 or (self.quality=="medium" and .75 or 1); love.graphics.setColor(self.color[1],self.color[2],self.color[3],.3*pulse*gs); love.graphics.circle("fill",self.x,self.y,self.radius+4)
 local img=Assets.get(self.assetKey)
 if img then local scale=(self.radius*2.5)/math.max(img:getWidth(),img:getHeight()); love.graphics.setColor(1,1,1,.98); love.graphics.draw(img,self.x,self.y,self.orbitAngle+math.pi/2,scale,scale,img:getWidth()/2,img:getHeight()/2) else love.graphics.setColor(self.color[1],self.color[2],self.color[3]); love.graphics.circle("fill",self.x,self.y,self.radius); love.graphics.setColor(1,1,1,.8); love.graphics.circle("fill",self.x-2,self.y-2,self.radius*.4) end
 if self.type=="defender" then love.graphics.setColor(self.color[1],self.color[2],self.color[3],.18); love.graphics.circle("line",self.x,self.y,self.shieldRadius) elseif self.type=="collector" then love.graphics.setColor(self.color[1],self.color[2],self.color[3],.08); love.graphics.circle("line",self.x,self.y,self.collectRadius) end
end
return Drone
