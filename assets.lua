-- Starfall Vengeance asset registry.
-- Loads the complete artwork library and composites the ambient families into the backdrop.
local Assets={images={},loaded=false,missing={}}
local function safeImage(path)
    local ok,img=pcall(love.graphics.newImage,path)
    if ok and img then img:setFilter("linear","linear"); return img end
    Assets.missing[path]=true; return nil
end
local imageFiles={
 player="assets/SpaceShip.png",ship="assets/ship.png",support="assets/support.png",pet1="assets/pet 1.png",pet2="assets/pet 2.png",pet3="assets/pet 3.png",
 swarmer="assets/SWARMERS.png",sniper="assets/SNIPERS.png",bomber="assets/BOMBERS.png",turret="assets/TURRET DRONES.png",miniboss="assets/MINI-BOSSES.png",
 bullet="assets/bullet.png",bullet1="assets/bullet-1.png",bullet2="assets/bullet-2.png",laser1="assets/laser-1.png",laser2="assets/laser-2.png",laser3="assets/laser-3.png",plasma="assets/plasm.png",rocket="assets/rocket.png",shield="assets/shield.png",fire="assets/fire.png",
 background="assets/bg.png",starsA="assets/Stars-A.png",starsB="assets/Stars-B.png",bonusLife="assets/bonus_life.png",bonusShield="assets/bonus_shield.png",bonusTime="assets/bonus_time.png",
 asteroidSmallA="assets/small-A.png",asteroidSmallB="assets/small-B.png",asteroidMediumA="assets/medium-A.png",asteroidMediumB="assets/medium-B.png",asteroidLargeA="assets/large-A.png",asteroidLargeB="assets/large-B.png",sphere0="assets/sphere0.png",sphere1="assets/sphere1.png",sphere2="assets/sphere2.png"
}
for i=0,10 do imageFiles["light"..i]="assets/light"..i..".png" end
for i=0,27 do imageFiles["noise"..string.format("%02d",i)]="assets/noise"..string.format("%02d",i)..".png" end
for i=0,9 do imageFiles["planet"..string.format("%02d",i)]="assets/planet"..string.format("%02d",i)..".png" end
function Assets.load() if Assets.loaded then return Assets.images end; for k,p in pairs(imageFiles) do Assets.images[k]=safeImage(p) end; Assets.loaded=true; return Assets.images end
function Assets.get(name) if not Assets.loaded then Assets.load() end; return Assets.images[name] end
function Assets.drawImage(image,x,y,w,h,rotation,alpha)
    if not image then return false end
    local iw,ih=image:getWidth(),image:getHeight(); if iw<=0 or ih<=0 then return false end
    local sx=w and w/iw or 1; local sy=h and h/ih or sx; love.graphics.setColor(1,1,1,alpha or 1); love.graphics.draw(image,x,y,rotation or 0,sx,sy,iw/2,ih/2)
    if image==Assets.images.background then
        local t=love.timer.getTime(); local sw,sh=love.graphics.getWidth(),love.graphics.getHeight()
        local n=Assets.images["noise"..string.format("%02d",math.floor(t*.55)%28)]; if n then love.graphics.setColor(1,1,1,.032); love.graphics.draw(n,sw/2,sh/2,0,sw/n:getWidth(),sh/n:getHeight(),n:getWidth()/2,n:getHeight()/2) end
        local l=Assets.images["light"..(math.floor(t*.35)%11)]; if l then local lx=sw*(.18+.64*(.5+.5*math.sin(t*.11))); local ly=sh*(.25+.45*(.5+.5*math.cos(t*.07))); love.graphics.setColor(1,1,1,.085); love.graphics.draw(l,lx,ly,0,.34,.34,l:getWidth()/2,l:getHeight()/2) end
        local s=Assets.images["sphere"..(math.floor(t/4)%3)]; if s then love.graphics.setColor(1,1,1,.065); love.graphics.draw(s,sw*.20+math.sin(t*.09)*35,sh*.28,0,.34,.34,s:getWidth()/2,s:getHeight()/2) end
        local sets={Assets.images.asteroidSmallA,Assets.images.asteroidSmallB,Assets.images.asteroidMediumA,Assets.images.asteroidMediumB,Assets.images.asteroidLargeA,Assets.images.asteroidLargeB}
        for i,a in ipairs(sets) do if a then local px=sw*(.08+.16*i)+math.sin(t*(.025+i*.004))*28; local py=sh*(.82-.06*i)+math.cos(t*(.021+i*.003))*18; love.graphics.setColor(1,1,1,.028+(i%2)*.014); love.graphics.draw(a,px,py,t*(i%2==0 and -.01 or .01),.11,.11,a:getWidth()/2,a:getHeight()/2) end end
        local p=Assets.images["planet"..string.format("%02d",math.floor(t/7)%10)]; if p then love.graphics.setColor(1,1,1,.045); love.graphics.draw(p,sw*.80+math.sin(t*.08)*22,sh*.30,math.sin(t*.03)*.08,.55,.55,p:getWidth()/2,p:getHeight()/2) end
        local deco={{Assets.images.ship,sw*.13,sh*.18,.11,.16},{Assets.images.bonusLife,sw*.08,sh*.56,.04,.14},{Assets.images.bonusShield,sw*.92,sh*.63,.04,.16},{Assets.images.bonusTime,sw*.86,sh*.48,.04,.15},{Assets.images.fire,sw*.58,sh*.84,.06,.10},{Assets.images.shield,sw*.73,sh*.18,.05,.11}}
        for _,d in ipairs(deco) do local a2,dx,dy,sc,al=d[1],d[2],d[3],d[4],d[5]; if a2 then love.graphics.setColor(1,1,1,al); love.graphics.draw(a2,dx+math.sin(t*.1+dx)*8,dy+math.cos(t*.08+dy)*5,math.sin(t*.03)*.2,sc,sc,a2:getWidth()/2,a2:getHeight()/2) end end
    end
    return true
end
function Assets.getLoadReport()
    local loaded,missing=0,0; for k in pairs(imageFiles) do if Assets.images[k] then loaded=loaded+1 else missing=missing+1 end end; return {loaded=loaded,missing=missing,total=loaded+missing} end
return Assets
