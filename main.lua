-- Starfall Vengeance
-- Final integrated runtime: exactly 3 modes, desktop + mobile controls,
-- combat progression, VFX, SFX, persistence, and production-safe fallbacks.

local Assets=require("assets")
local Modes=require("modes")
local Player=require("player")
local Bullet=require("bullet")
local Enemy=require("enemy")
local PowerUp=require("powerup")
local Weapons=require("weapons")
local XP=require("xp")
local Particles=require("particles")
local Effects=require("effects")
local Camera=require("camera")
local Sound=require("sound")
local Drone=require("drone")
local Profile=require("profile")
local Ads=require("ads")
local TouchControls=require("touchcontrols")
local util=require("util")

local state="menu"; local run=nil; local player=nil
local bullets,enemies,powerups,drones={},{},{},{}
local playerWeapons,currentWeapon,xpData
local particles,effects,camera,sound,touch
local fonts={}; local time=0; local selectedMode=1
local modeIds={"campaign","endless","gauntlet"}
local mouseDown=false; local mobile=false; local quality="high"
local screenFlash=0; local flash={1,1,1}; local waveAnnounce=0
local upgradeChoices={}; local gameOverReason=""; local bestScore=0; local newBest=false
local settingsReturn="menu"

local function F(n) fonts[n]=fonts[n] or love.graphics.newFont(n); return fonts[n] end
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function inside(x,y,r) return x>=r.x and x<=r.x+r.w and y>=r.y and y<=r.y+r.h end
local function safe(o,m,...)
    if o and type(o[m])=="function" then local ok,res=pcall(o[m],o,...); if ok then return res end end
end
local function sfx(n,v) safe(sound,"playSound",n,v) end
local function fx(r,g,b,a) screenFlash=math.max(screenFlash,a or .16); flash={r,g,b}; safe(effects,"flash",r,g,b,a or .16) end
local function panel(x,y,w,h,a)
    love.graphics.setColor(.008,.018,.045,a or .84); love.graphics.rectangle("fill",x,y,w,h,14,14)
    love.graphics.setColor(.18,.65,1,.32); love.graphics.rectangle("line",x,y,w,h,14,14)
end
local function button(r,accent)
    local mx,my=love.mouse.getPosition(); local h=inside(mx,my,r); local c=accent or {.18,.65,1}
    love.graphics.setColor(0,0,0,.4); love.graphics.rectangle("fill",r.x+4,r.y+5,r.w,r.h,10,10)
    love.graphics.setColor(c[1],c[2],c[3],h and .98 or .72); love.graphics.rectangle("fill",r.x,r.y,r.w,r.h,10,10)
    local fs=#(r.text or "")>15 and 16 or 20; love.graphics.setFont(F(fs)); love.graphics.setColor(1,1,1,h and 1 or .88)
    love.graphics.printf(r.text or "",r.x,r.y+(r.h-F(fs):getHeight())/2,r.w,"center")
end

local function resetWorld()
    bullets,enemies,powerups,drones={},{},{},{}
    playerWeapons=Weapons.new(); currentWeapon="pistol"; xpData=XP.new()
    player=Player.new(love.graphics.getWidth()/2,love.graphics.getHeight()/2)
    player.fireRateMultiplier=1; player.damageMultiplier=1; player.magneticRange=0
    player.piercingBullets=false; player.extraProjectiles=0; player.hasSideDrones=false
    player.hasOrbitDrones=false; player.hasHomingMissile=false; player.explosionSizeMultiplier=1
    player.droneDamageMultiplier=1; run=Modes.newRun(modeIds[selectedMode]); waveAnnounce=2
    if mobile then touch=TouchControls.new(); touch:setQuality(quality) end
    sfx("menuClose",.25)
end

local function addDrones()
    if not player then return end
    local side,orbit=0,0
    for _,d in ipairs(drones) do if d.formation=="side" then side=side+1 elseif d.formation=="orbit_upgrade" then orbit=orbit+1 end end
    if player.hasSideDrones and side<2 then
        for i=side+1,2 do local d=Drone.new(player.x,player.y,"attack","player"); d.formation="side"; d.formationIndex=i; safe(d,"setQuality",quality); drones[#drones+1]=d end
    end
    if player.hasOrbitDrones and orbit<2 then
        for i=orbit+1,2 do local d=Drone.new(player.x,player.y,"attack","player"); d.formation="orbit_upgrade"; d.formationIndex=i; d.orbitSpeed=2.5; safe(d,"setQuality",quality); drones[#drones+1]=d end
    end
end

local function enemyPool(w)
    local p={"swarmer"}; if w>=2 then p[#p+1]="turret" end; if w>=3 then p[#p+1]="sniper" end; if w>=4 then p[#p+1]="bomber" end
    return p
end
local function edgeSpawn()
    local w,h=love.graphics.getWidth(),love.graphics.getHeight(); local s=math.random(4); local m=70
    if s==1 then return math.random(0,w),-m elseif s==2 then return w+m,math.random(0,h) elseif s==3 then return math.random(0,w),h+m else return -m,math.random(0,h) end
end
local function spawnEnemy(kind,elite)
    local x,y=edgeSpawn(); kind=kind or enemyPool(run.wave)[math.random(#enemyPool(run.wave))]
    local e=Enemy.new(x,y,kind,Assets.get(kind)); local r=Modes.waveRules(run)
    e.health=e.health*r.health; e.maxHealth=e.health; e.speed=e.speed*r.speed
    if r.fireMultiplier and e.shootCooldown>0 then e.shootCooldown=e.shootCooldown*r.fireMultiplier end
    if elite then e.health=e.health*1.8; e.maxHealth=e.health; e.speed=e.speed*1.15; e.score=e.score*3; e.elite=true end
    e._scored=false; enemies[#enemies+1]=e
end
local function boss()
    spawnEnemy("miniboss",false); sfx("explosion",.7); fx(.75,.2,1,.22); safe(camera,"shake",14,.4,2)
end
local function reward()
    local w,h=love.graphics.getWidth(),love.graphics.getHeight(); local p=PowerUp.new(math.random(80,w-80),math.random(90,h-90)); safe(p,"setQuality",quality); powerups[#powerups+1]=p
end
local function chooseUpgrade()
    upgradeChoices=XP.getRandomUpgrades(3); state="upgrade"; sfx("levelup",.7); fx(.2,.8,1,.2)
end
local function killScore(e)
    run.kills=run.kills+1; run.combo=run.combo+1; run.bestCombo=math.max(run.bestCombo,run.combo); run.comboTimer=0
    local mode=Modes.get(run.id); local mult=1+math.min(run.combo,25)*.06; local gain=(e.score or 10)*mult*mode.scoreMultiplier
    if e.elite then gain=gain*1.75 end; run.score=math.floor(run.score+gain); run.threat=clamp(run.threat+.025,0,1)
    local amount=(Enemy.types[e.type] and Enemy.types[e.type].xp or 10)*mode.xpMultiplier; if player.powerups.xpboost>0 then amount=amount*2 end
    if XP.addXP(xpData,amount) then chooseUpgrade() end
    safe(effects,"addDamageNumber",e.x,e.y,"+"..math.floor(gain),e.elite); safe(particles,"explosion",e.x,e.y,e.elite and 1.8 or .9,e.elite and "electric" or "default"); safe(camera,"shake",e.elite and 8 or 3,.1,1)
    sfx(e.elite and "heavyShoot" or "hit",.32); if e.elite or math.random()<.09 then reward() end
end
local function finish(victory,reason)
    if state=="gameover" or not run then return end; run.completed=victory; gameOverReason=reason or (victory and "MISSION COMPLETE" or "SHIP DESTROYED")
    newBest=run.score>bestScore; bestScore=math.max(bestScore,run.score); state="gameover"; mouseDown=false
    safe(Ads,"onGameOver",run.score); if Profile.hasProfile() then safe(Profile,"updateStats",run.score,math.floor(run.score/50)); safe(Profile,"incrementGamesPlayed") end
    sfx(victory and "levelup" or "death",.8); safe(particles,"explosion",player.x,player.y,2.3,"fire")
end
local function beginWave()
    local r=Modes.waveRules(run); run.target=r.target; run.spawned=0; run.spawnTimer=0; run.killedThisWave=0; run.trialTimer=run.trialTimer or 0; waveAnnounce=1.2
    if r.boss then boss() end
    safe(Ads,"onWaveComplete",run.wave)
end
local function nextWave()
    run.score=run.score+math.floor(run.wave*12*Modes.get(run.id).scoreMultiplier); sfx("highUp",.65); fx(.1,.8,1,.12)
    if run.id=="campaign" and run.wave>=30 then finish(true,"CAMPAIGN COMPLETE"); return end
    if run.id=="gauntlet" then if run.trial>=8 then finish(true,"GAUNTLET CLEARED"); return end; if not Modes.nextGauntletTrial(run) then finish(true,"GAUNTLET CLEARED"); return end else run.wave=run.wave+1 end
    beginWave()
end

local function aimAngle()
    local mx,my=love.mouse.getPosition(); return util.angle(player.x,player.y,mx,my)
end
local function doDash(angle)
    if player.dashCooldown<=0 and player.dashTimer<=0 then
        angle=angle or aimAngle(); player.dashDirection.x=math.cos(angle); player.dashDirection.y=math.sin(angle); player.dashTimer=player.dashDuration; player.dashCooldown=player.dashDelay
        safe(particles,"dashTrail",player.x,player.y,player.radius); sfx("heavyShoot",.45); safe(camera,"shake",4,.1,1)
    end
end
local function shoot(angle)
    local data=Weapons.types[currentWeapon]; if not data or player.shootCooldown>0 or not Weapons.hasAmmo(playerWeapons,currentWeapon) then return end
    local count=(data.bulletCount or 1)+(player.extraProjectiles or 0); for i=1,count do
        local a=angle; if count>1 then a=a+(i-(count+1)/2)*(data.spread or 0)/count end
        local b=Bullet.new(player.x,player.y,a,"player",player.bulletColor or "yellow"); b.damage=(data.damage or 1)*10*(player.damageMultiplier or 1); b.speed=data.bulletSpeed or 400; b.vx=math.cos(a)*b.speed; b.vy=math.sin(a)*b.speed
        b.piercing=player.piercingBullets or data.piercing; if player.powerups.homing>0 then b.homing=true; b.homingStrength=3.2 end; if player.powerups.explosive>0 then b.explosion=true; b.explosionRadius=42*(player.explosionSizeMultiplier or 1) end; bullets[#bullets+1]=b
    end
    Weapons.useAmmo(playerWeapons,currentWeapon,1); player.shootCooldown=(data.fireRate or .2)*(player.fireRateMultiplier or 1); sfx((data.fireRate or .2)<.15 and "shoot" or "heavyShoot",.3); safe(particles,"thruster",player.x-math.cos(angle)*12,player.y-math.sin(angle)*12,angle+math.pi,.8)
end

local function updateCombat(dt)
    run.elapsed=run.elapsed+dt; run.comboTimer=(run.combo>0 and (run.comboTimer or 0)+dt or 0); if run.comboTimer>2.8 then run.combo=0 end
    local jx,jy=0,0; local adx,ady=0,0; local shooting=mouseDown or love.mouse.isDown(1)
    if mobile and touch then jx,jy=touch:getMovement(); adx,ady=touch:getAimDirection(); shooting=shooting or touch:isShooting() end
    player:update(dt,jx,jy,mobile and "mobile" or "pc")
    local angle=aimAngle(); if mobile and (math.abs(adx)+math.abs(ady)>.1) then angle=math.atan2(ady,adx); player.hasAimOverride=true; player.aimAngle=angle else player.hasAimOverride=false end
    if shooting then shoot(angle) end
    for _,b in ipairs(bullets) do b:update(dt,enemies) end
    for _,e in ipairs(enemies) do
        e:update(dt,player.x,player.y)
        if e:canShoot() then local a=util.angle(e.x,e.y,player.x,player.y); local eb=Bullet.new(e.x,e.y,a,"enemy",e.type=="sniper" and "blue" or "red"); eb.damage=e.damage*(Modes.waveRules(run).damageMultiplier or 1); eb.speed=e.type=="sniper" and 330 or 260; eb.vx=math.cos(a)*eb.speed; eb.vy=math.sin(a)*eb.speed; bullets[#bullets+1]=eb; sfx("retroShoot",.17) end
        if e.type=="miniboss" then e._bossFire=(e._bossFire or 1.6)-dt; if e._bossFire<=0 then e._bossFire=2.2; for i=1,8 do local a=(i/8)*math.pi*2; local eb=Bullet.new(e.x,e.y,a,"enemy","purple"); eb.damage=e.damage*1.35; eb.speed=220; eb.vx=math.cos(a)*eb.speed; eb.vy=math.sin(a)*eb.speed; bullets[#bullets+1]=eb end; sfx("laserLarge_000.ogg",.25) end end
    end
    for _,p in ipairs(powerups) do p:update(dt) end
    for _,d in ipairs(drones) do local a=safe(d,"update",dt,player,enemies,bullets,powerups,{}); if a and a.type=="shoot" then local b=Bullet.new(d.x,d.y,a.angle or 0,"player",a.color or "yellow"); b.damage=(a.damage or 4)*(player.droneDamageMultiplier or 1); b.speed=420; b.vx=math.cos(a.angle or 0)*b.speed; b.vy=math.sin(a.angle or 0)*b.speed; bullets[#bullets+1]=b; end end
    for _,b in ipairs(bullets) do
        if not b.dead and b.owner=="player" then for _,e in ipairs(enemies) do if not e.dead and util.checkCollision(b.x,b.y,b.radius,e.x,e.y,e.radius) then e:takeDamage(b.damage); safe(particles,"impact",e.x,e.y,util.angle(b.x,b.y,e.x,e.y),1); if b.explosion then b.dead=true; local rr=b.explosionRadius or 40; for _,e2 in ipairs(enemies) do if not e2.dead and e2~=e and util.distance(b.x,b.y,e2.x,e2.y)<rr then e2:takeDamage(b.damage*.6) end end; safe(particles,"explosion",b.x,b.y,rr/40,"fire"); sfx("explosion",.25) else b.dead=not b.piercing end; if e.dead and not e._scored then e._scored=true; run.killedThisWave=run.killedThisWave+1; killScore(e) end; if not b.piercing then break end end end
        elseif not b.dead and b.owner=="enemy" and util.checkCollision(b.x,b.y,b.radius,player.x,player.y,player.radius) then b.dead=true; if player:takeDamage(b.damage) then run.combo=0; fx(1,.12,.1,.2); sfx("hit",.5); safe(camera,"shake",9,.18,2); if player.health<=0 then finish(false,"SHIP DESTROYED") end end end
    end
    for _,e in ipairs(enemies) do if not e.dead and util.checkCollision(e.x,e.y,e.radius,player.x,player.y,player.radius) and e:canDamagePlayer() then if player:takeDamage(e.damage*1.3) then fx(1,.1,.1,.22); sfx("hit",.45); safe(camera,"shake",8,.16,2); if player.health<=0 then finish(false,"SHIP DESTROYED") end end; e.x=e.x+math.cos(util.angle(player.x,player.y,e.x,e.y))*14; e.y=e.y+math.sin(util.angle(player.x,player.y,e.x,e.y))*14 end end
    util.removeDeadEntities(bullets)
    for i=#powerups,1,-1 do local p=powerups[i]; local d=util.distance(player.x,player.y,p.x,p.y); if player.magneticRange>0 and d<player.magneticRange then local a=util.angle(p.x,p.y,player.x,player.y); p.x=p.x+math.cos(a)*220*dt; p.y=p.y+math.sin(a)*220*dt end; if util.checkCollision(player.x,player.y,player.radius,p.x,p.y,p.radius) then player:applyPowerUp(p.type); table.remove(powerups,i); sfx("shield",.55); safe(particles,"healEffect",player.x,player.y,20) end end
    util.removeDeadEntities(enemies); util.removeDeadEntities(powerups); addDrones()
    local r=Modes.waveRules(run); if run.spawned<run.target then run.spawnTimer=run.spawnTimer+dt; if run.spawnTimer>=r.spawnDelay then run.spawnTimer=0; run.spawned=run.spawned+1; spawnEnemy(nil,run.spawned>3 and math.random()<r.eliteChance) end elseif #enemies==0 and state=="playing" then nextWave() end
    if run.id=="gauntlet" then run.trialTimer=run.trialTimer+dt; if run.trialTimer>=run.trialDuration then enemies={}; nextWave() end end
end

local function drawSpace()
    local w,h=love.graphics.getWidth(),love.graphics.getHeight(); local bg=Assets.get("background"); if bg then Assets.drawImage(bg,w/2,h/2,w,h,0,1) else love.graphics.clear(.004,.007,.02) end
    local sa,sb=Assets.get("starsA"),Assets.get("starsB"); if sa then Assets.drawImage(sa,w/2,h/2,w,h,0,.28) end; if sb then Assets.drawImage(sb,w/2,h/2,w,h,0,.16) end
    local p=Assets.get("planet"..string.format("%02d",math.floor(time/6)%10)); if p then Assets.drawImage(p,w*.8+math.sin(time*.07)*35,h*.28,190,190,math.sin(time*.03)*.15,.25) end
    local light=Assets.get("light"..(math.floor(time*1.4)%11)); if light then Assets.drawImage(light,w*.2,h*.35,350,350,time*.02,.06) end
    local noise=Assets.get("noise"..string.format("%02d",math.floor(time*4)%28)); if noise then Assets.drawImage(noise,w/2,h/2,w,h,0,.035) end
end
local function drawWorld()
    drawSpace(); for _,p in ipairs(powerups) do p:draw() end; for _,d in ipairs(drones) do d:draw() end; player:draw(Assets.get("player")); for _,b in ipairs(bullets) do b:draw() end; for _,e in ipairs(enemies) do e:draw(player.x,player.y) end; particles:draw(); safe(effects,"draw")
end
local function hud()
    local w,h=love.graphics.getWidth(),love.graphics.getHeight(); local m=Modes.get(run.id); panel(16,16,390,96,.72); love.graphics.setFont(F(18)); love.graphics.setColor(.7,.9,1); love.graphics.print(m.name,30,28); love.graphics.setFont(F(30)); love.graphics.setColor(1,1,1); love.graphics.print("WAVE "..run.wave,30,52); love.graphics.setFont(F(16)); love.graphics.setColor(1,.85,.25); love.graphics.print("SCORE "..run.score,175,31); love.graphics.setColor(.65,.75,.85); love.graphics.print("KILLS "..run.kills,175,58); love.graphics.setColor(1,.3,.35); love.graphics.print("HP "..math.ceil(player.health).."/"..player.maxHealth,270,31); love.graphics.setColor(.8,.75,1); love.graphics.print("x"..run.combo,315,58)
    local bw=320,bx=(w-bw)/2,by=h-30; love.graphics.setColor(.02,.03,.06,.88); love.graphics.rectangle("fill",bx,by,bw,12,6,6); love.graphics.setColor(.2,.75,1,.9); love.graphics.rectangle("fill",bx,by,bw*clamp(xpData.current/xpData.toNextLevel,0,1),12,6,6); love.graphics.setFont(F(12)); love.graphics.setColor(1,1,1,.8); love.graphics.printf("LV "..xpData.level,bx,by-18,bw,"center")
    if run.id=="gauntlet" then panel(w-285,16,269,86,.72); love.graphics.setFont(F(16)); love.graphics.setColor(.9,.45,1); love.graphics.print(run.mutator.name,w-270,28); love.graphics.setFont(F(12)); love.graphics.setColor(.8,.8,.9); love.graphics.printf(run.mutator.desc,w-270,50,240,"left"); love.graphics.printf(string.format("TRIAL %d/8  %ds",run.trial,math.max(0,run.trialDuration-run.trialTimer)),w-270,79,240,"left") end
    if waveAnnounce>0 then love.graphics.setFont(F(44)); love.graphics.setColor(.5,.9,1,clamp(waveAnnounce/1.2,0,1)); love.graphics.printf("WAVE "..run.wave,0,h*.32,w,"center") end
    if mobile and touch then touch:draw() end
end
local function menu()
    drawSpace(); local w,h=love.graphics.getWidth(),love.graphics.getHeight(); love.graphics.setFont(F(58)); love.graphics.setColor(.3,.85,1,.22); love.graphics.printf("STARFALL VENGEANCE",0,82,w,"center"); love.graphics.setColor(.9,.98,1); love.graphics.printf("STARFALL VENGEANCE",0,78,w,"center"); love.graphics.setFont(F(18)); love.graphics.setColor(.65,.78,.9); love.graphics.printf("SURVIVE • ADAPT • DOMINATE",0,145,w,"center"); button({x=w/2-125,y=h/2-25,w=250,h=58,text="PLAY"}); button({x=w/2-125,y=h/2+50,w=250,h=58,text="HOW TO PLAY"}); button({x=w/2-125,y=h/2+125,w=250,h=58,text="SETTINGS"}); love.graphics.setFont(F(12)); love.graphics.setColor(.55,.65,.72); love.graphics.printf("Best Score: "..bestScore,0,h-25,w,"center")
end
local function modes()
    drawSpace(); local w,h=love.graphics.getWidth(),love.graphics.getHeight(); love.graphics.setFont(F(44)); love.graphics.setColor(.82,.95,1); love.graphics.printf("SELECT YOUR RUN",0,55,w,"center")
    for i,id in ipairs(modeIds) do local m=Modes.get(id); local x=w/2-430+(i-1)*290; local y=150; local c=Modes.modeColor(id); panel(x,y,260,345,i==selectedMode and .9 or .7); love.graphics.setFont(F(26)); love.graphics.setColor(c[1],c[2],c[3]); love.graphics.printf(m.name,x,y+25,260,"center"); love.graphics.setFont(F(14)); love.graphics.setColor(.84,.9,.96); love.graphics.printf(m.tagline,x+20,y+70,220,"center"); love.graphics.setColor(.65,.72,.82); love.graphics.printf(m.description,x+20,y+120,220,"center"); love.graphics.setColor(c[1],c[2],c[3]); love.graphics.printf(m.goal,x+20,y+238,220,"center"); button({x=x+30,y=y+285,w=200,h=40,text="SELECT"},c) end
    button({x=w/2-90,y=h-55,w=180,h=40,text="BACK"},{.3,.42,.55})
end
local function upgrade()
    drawWorld(); local w,h=love.graphics.getWidth(),love.graphics.getHeight(); love.graphics.setColor(0,0,0,.78); love.graphics.rectangle("fill",0,0,w,h); love.graphics.setFont(F(46)); love.graphics.setColor(1,.9,.35); love.graphics.printf("LEVEL UP",0,70,w,"center"); for i,u in ipairs(upgradeChoices) do local x=w/2-410+(i-1)*280; panel(x,190,250,210,.92); love.graphics.setFont(F(18)); love.graphics.setColor(.35,.85,1); love.graphics.printf(u.name,x+15,215,220,"center"); love.graphics.setFont(F(13)); love.graphics.setColor(.8,.85,.92); love.graphics.printf(u.description,x+20,270,210,"center"); love.graphics.setFont(F(11)); love.graphics.setColor(.55,.65,.75); love.graphics.printf("CLICK TO INSTALL",x+20,365,210,"center") end
end
local function gameover()
    drawSpace(); local w,h=love.graphics.getWidth(),love.graphics.getHeight(); love.graphics.setColor(0,0,0,.74); love.graphics.rectangle("fill",0,0,w,h); love.graphics.setFont(F(60)); love.graphics.setColor(run.completed and .3 or 1,run.completed and .95 or .25,run.completed and 1 or .3); love.graphics.printf(run.completed and "VICTORY" or "GAME OVER",0,75,w,"center"); love.graphics.setFont(F(18)); love.graphics.setColor(.75,.85,.95); love.graphics.printf(gameOverReason,0,145,w,"center"); panel(w/2-250,195,500,225,.9); love.graphics.setFont(F(36)); love.graphics.setColor(1,.86,.3); love.graphics.printf(tostring(run.score),w/2-230,225,460,"center"); love.graphics.setFont(F(16)); love.graphics.setColor(.8,.85,.9); love.graphics.printf("Wave "..run.wave.."   •   "..run.kills.." kills   •   Best combo x"..run.bestCombo,w/2-230,305,460,"center"); if newBest then love.graphics.setColor(1,.85,.25); love.graphics.printf("★ NEW PERSONAL BEST ★",w/2-230,348,460,"center") end; button({x=w/2-220,y=465,w=200,h=55,text="RETRY"}); button({x=w/2+20,y=465,w=200,h=55,text="MENU"},{.3,.42,.58})
end
local function help()
    drawSpace(); local w,h=love.graphics.getWidth(),love.graphics.getHeight(); panel(w/2-420,80,840,500,.92); love.graphics.setFont(F(40)); love.graphics.setColor(.7,.9,1); love.graphics.printf("HOW TO PLAY",0,110,w,"center"); love.graphics.setFont(F(17)); love.graphics.setColor(.82,.88,.94); love.graphics.printf("WASD / ARROWS — MOVE\nMOUSE — AIM + FIRE\nSPACE — DASH\n1–4 — SWITCH WEAPON\nESC — PAUSE\n\nCombos increase score. Power-ups create temporary builds.\nLevel-ups give permanent run upgrades. Elites are high-risk, high-reward.\n\nCAMPAIGN — 30 waves\nENDLESS — infinite adaptive pressure\nGAUNTLET — 8 timed mutator trials",w/2-350,190,700,"center"); button({x=w/2-90,y=520,w=180,h=45,text="BACK"},{.3,.45,.65})
end
local function settings()
    drawSpace(); local w,h=love.graphics.getWidth(),love.graphics.getHeight(); panel(w/2-280,90,560,470,.92); love.graphics.setFont(F(44)); love.graphics.setColor(.8,.95,1); love.graphics.printf("SETTINGS",0,120,w,"center"); local st=sound:getSettings(); button({x=w/2-180,y=220,w=360,h=50,text="SOUND: "..(st.soundEnabled and "ON" or "OFF")}); button({x=w/2-180,y=290,w=360,h=50,text="MUSIC: "..(st.musicEnabled and "ON" or "OFF")}); button({x=w/2-180,y=360,w=360,h=50,text="QUALITY: "..quality:upper()}); button({x=w/2-180,y=450,w=360,h=50,text="BACK"},{.3,.42,.55})
end

function love.load()
    math.randomseed(os.time()); Assets.load(); sound=Sound.new(); particles=Particles.new(); effects=Effects.new(); camera=Camera.new(); mobile=love.system.getOS()=="Android" or love.system.getOS()=="iOS"; if mobile then touch=TouchControls.new() end; quality="high"; Profile.init(); if not Profile.hasProfile() then Profile.createProfile("Guest") end; local p=Profile.getProfile(); bestScore=p and p.bestScore or 0; love.mouse.setVisible(true)
end
function love.update(dt)
    dt=math.min(dt or .016,.05); time=time+dt; if waveAnnounce>0 then waveAnnounce=math.max(0,waveAnnounce-dt) end; if screenFlash>0 then screenFlash=math.max(0,screenFlash-dt*2.5) end; safe(particles,"update",dt); safe(effects,"update",dt); safe(camera,"update",dt); if state=="playing" then updateCombat(dt) end
end
function love.draw()
    love.graphics.clear(0,0,0); if state=="menu" then menu() elseif state=="modes" then modes() elseif state=="playing" then drawWorld(); hud() elseif state=="upgrade" then upgrade() elseif state=="gameover" then gameover() elseif state=="help" then help() elseif state=="settings" then settings() elseif state=="paused" then drawWorld(); love.graphics.setColor(0,0,0,.65); love.graphics.rectangle("fill",0,0,love.graphics.getWidth(),love.graphics.getHeight()); local w=love.graphics.getWidth(); love.graphics.setFont(F(56)); love.graphics.setColor(1,1,1); love.graphics.printf("PAUSED",0,155,w,"center"); button({x=w/2-110,y=250,w=220,h=50,text="RESUME"}); button({x=w/2-110,y=320,w=220,h=50,text="QUIT RUN"},{.3,.42,.55}) end; if screenFlash>0 then love.graphics.setColor(flash[1],flash[2],flash[3],screenFlash*.15); love.graphics.rectangle("fill",0,0,love.graphics.getWidth(),love.graphics.getHeight()) end
end

local function startSelected()
    resetWorld(); state="playing"; safe(Ads,"onGameStart"); beginWave(); sfx("menu",.3)
end
function love.mousepressed(x,y,b)
    if b~=1 then return end
    if state=="menu" then local w,h=love.graphics.getWidth(),love.graphics.getHeight(); if inside(x,y,{x=w/2-125,y=h/2-25,w=250,h=58}) then state="modes"; sfx("menu",.25) elseif inside(x,y,{x=w/2-125,y=h/2+50,w=250,h=58}) then state="help" elseif inside(x,y,{x=w/2-125,y=h/2+125,w=250,h=58}) then settingsReturn="menu"; state="settings" end
    elseif state=="modes" then local w,h=love.graphics.getWidth(),love.graphics.getHeight(); for i=1,3 do local x0=w/2-430+(i-1)*290; if inside(x,y,{x=x0,y=150,w=260,h=345}) then selectedMode=i; if y>435 then startSelected() end; return end end; if inside(x,y,{x=w/2-90,y=h-55,w=180,h=40}) then state="menu" end
    elseif state=="playing" then mouseDown=true
    elseif state=="upgrade" then local w=love.graphics.getWidth(); for i=1,#upgradeChoices do local x0=w/2-410+(i-1)*280; if inside(x,y,{x=x0,y=190,w=250,h=210}) then pcall(upgradeChoices[i].apply,player); addDrones(); state="playing"; return end end
    elseif state=="gameover" then local w=love.graphics.getWidth(); if inside(x,y,{x=w/2-220,y=465,w=200,h=55}) then startSelected() elseif inside(x,y,{x=w/2+20,y=465,w=200,h=55}) then state="menu" end
    elseif state=="help" then state="menu"
    elseif state=="settings" then local w=love.graphics.getWidth(); if inside(x,y,{x=w/2-180,y=220,w=360,h=50}) then sound:toggleSound() elseif inside(x,y,{x=w/2-180,y=290,w=360,h=50}) then sound:toggleMusic() elseif inside(x,y,{x=w/2-180,y=360,w=360,h=50}) then quality=(quality=="high" and "medium") or (quality=="medium" and "low") or "high"; particles:setQuality(quality); effects:setQuality(quality); camera:setQuality(quality) elseif inside(x,y,{x=w/2-180,y=450,w=360,h=50}) then state=settingsReturn end
    elseif state=="paused" then local w=love.graphics.getWidth(); if inside(x,y,{x=w/2-110,y=250,w=220,h=50}) then state="playing" elseif inside(x,y,{x=w/2-110,y=320,w=220,h=50}) then state="menu" end
    end
end
function love.mousereleased(_,_,b) if b==1 then mouseDown=false end end
function love.keypressed(k)
    if k=="escape" then if state=="playing" then state="paused" else if state=="paused" then state="playing" elseif state=="help" or state=="modes" or state=="settings" then state="menu" end end; return end
    if state=="modes" then if k=="left" or k=="a" then selectedMode=(selectedMode-2)%3+1 elseif k=="right" or k=="d" then selectedMode=selectedMode%3+1 elseif k=="return" or k=="space" then startSelected() end
    elseif state=="playing" then if k=="1" then currentWeapon="pistol" elseif k=="2" and playerWeapons.shotgun.unlocked then currentWeapon="shotgun" elseif k=="3" and playerWeapons.machinegun.unlocked then currentWeapon="machinegun" elseif k=="4" and playerWeapons.sniper.unlocked then currentWeapon="sniper" elseif k=="space" then doDash() end end
end
function love.touchpressed(id,x,y) if mobile and touch then touch:touchpressed(id,x,y) end end
function love.touchmoved(id,x,y) if mobile and touch then touch:touchmoved(id,x,y) end end
function love.touchreleased(id) if mobile and touch then touch:touchreleased(id) end end

return nil
