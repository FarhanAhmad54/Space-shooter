-- Starfall Vengeance
-- Production rebuild: exactly three game modes, deterministic state flow, safe asset loading.

local Assets = require("assets")
local Modes = require("modes")
local Player = require("player")
local Bullet = require("bullet")
local Enemy = require("enemy")
local PowerUp = require("powerup")
local Weapons = require("weapons")
local Particles = require("particles")
local Effects = require("effects")
local Camera = require("camera")
local Sound = require("sound")
local Drone = require("drone")
local Profile = require("profile")
local Ads = require("ads")
local util = require("util")

local state = "menu"
local run = nil
local player = nil
local bullets, enemies, powerups, drones = {}, {}, {}, {}
local playerWeapons, currentWeapon, xpData
local particles, effects, camera, sound
local fonts = {}
local time = 0
local menuPulse = 0
local screenFlash = 0
local flashColor = {1,1,1}
local comboTimeout = 2.8
local highScore = 0
local newHighScore = false
local selectedMode = 1
local modeIds = {"campaign", "endless", "gauntlet"}
local pausedFrom = nil
local quality = "high"
local autoFire = false
local mouseDown = false
local gameOverReason = ""
local bossAlive = false
local waveAnnounce = 0
local upgradeChoices = {}
local tutorialShown = false
local shakeTimer = 0

local function font(size)
    size = math.max(8, math.floor(size))
    if not fonts[size] then fonts[size] = love.graphics.newFont(size) end
    return fonts[size]
end

local function clamp(v,a,b) return math.max(a, math.min(b,v)) end

local function safeCall(obj, method, ...)
    if obj and type(obj[method]) == "function" then
        local ok, result = pcall(obj[method], obj, ...)
        if ok then return result end
    end
end

local function play(name, volume)
    if sound then safeCall(sound, "playSound", name, volume) end
end

local function flash(r,g,b,a)
    screenFlash = math.max(screenFlash, a or 0.15)
    flashColor = {r or 1,g or 1,b or 1}
    safeCall(effects, "flash", r or 1,g or 1,b or 1,a or 0.15)
end

local function pointInRect(x,y,r)
    return x >= r.x and x <= r.x+r.w and y >= r.y and y <= r.h+r.y
end

local function drawPanel(x,y,w,h,alpha)
    love.graphics.setColor(0.015,0.025,0.06,alpha or 0.86)
    love.graphics.rectangle("fill",x,y,w,h,14,14)
    love.graphics.setColor(0.2,0.65,1,0.32)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line",x,y,w,h,14,14)
end

local function drawButton(r, accent)
    local hover = pointInRect(love.mouse.getPosition(), r)
    local c = accent or {0.18,0.65,1}
    love.graphics.setColor(0,0,0,0.42)
    love.graphics.rectangle("fill",r.x+4,r.y+5,r.w,r.h,10,10)
    love.graphics.setColor(c[1],c[2],c[3],hover and 0.95 or 0.72)
    love.graphics.rectangle("fill",r.x,r.y,r.w,r.h,10,10)
    love.graphics.setColor(1,1,1,hover and 1 or 0.88)
    love.graphics.setFont(font(#r.text > 15 and 16 or 20))
    love.graphics.printf(r.text,r.x,r.y+(r.h-fonts[#r.text > 15 and 16 or 20]:getHeight())/2,r.w,"center")
    return hover
end

local function resetWorld()
    bullets, enemies, powerups, drones = {}, {}, {}, {}
    playerWeapons = Weapons.new()
    currentWeapon = "pistol"
    xpData = require("xp").new()
    player = Player.new(love.graphics.getWidth()/2,love.graphics.getHeight()/2)
    player.fireRateMultiplier = 1
    player.damageMultiplier = 1
    player.magneticRange = 0
    player.piercingBullets = false
    player.extraProjectiles = 0
    player.hasSideDrones = false
    player.hasOrbitDrones = false
    player.hasHomingMissile = false
    player.explosionSizeMultiplier = 1
    player.droneDamageMultiplier = 1
    run = Modes.newRun(modeIds[selectedMode])
    bossAlive = false
    waveAnnounce = 2.2
    tutorialShown = false
    autoFire = false
end

local function addDroneFormation()
    local wantSide = player.hasSideDrones
    local wantOrbit = player.hasOrbitDrones
    local side, orbit = 0,0
    for _,d in ipairs(drones) do
        if d.formation == "side" then side=side+1 end
        if d.formation == "orbit_upgrade" then orbit=orbit+1 end
    end
    if wantSide and side < 2 then
        for i=side+1,2 do
            local d=Drone.new(player.x,player.y,"attack","player")
            d.formation="side"; d.formationIndex=i; d.formationCount=2
            safeCall(d,"setQuality",quality); drones[#drones+1]=d
        end
    end
    if wantOrbit and orbit < 2 then
        for i=orbit+1,2 do
            local d=Drone.new(player.x,player.y,"attack","player")
            d.formation="orbit_upgrade"; d.formationIndex=i; d.formationCount=2; d.orbitSpeed=2.5
            safeCall(d,"setQuality",quality); drones[#drones+1]=d
        end
    end
end

local function chooseEnemyType(w)
    local pool={"swarmer"}
    if w>=2 then pool[#pool+1]="turret" end
    if w>=3 then pool[#pool+1]="sniper" end
    if w>=4 then pool[#pool+1]="bomber" end
    return pool[math.random(#pool)]
end

local function spawnEnemy(forceType, elite)
    local sw,sh=love.graphics.getWidth(),love.graphics.getHeight()
    local side=math.random(4)
    local margin=60
    local x,y
    if side==1 then x=math.random(0,sw); y=-margin elseif side==2 then x=sw+margin;y=math.random(0,sh) elseif side==3 then x=math.random(0,sw);y=sh+margin else x=-margin;y=math.random(0,sh) end
    local typ=forceType or chooseEnemyType(run.wave)
    local image=Assets.get(typ)
    local e=Enemy.new(x,y,typ,image)
    local rules=Modes.waveRules(run)
    e.health=e.health*rules.health; e.maxHealth=e.health
    e.speed=e.speed*rules.speed
    if rules.fireMultiplier and e.shootCooldown>0 then e.shootCooldown=e.shootCooldown*rules.fireMultiplier end
    if elite then
        e.health=e.health*1.8; e.maxHealth=e.health; e.speed=e.speed*1.15; e.score=e.score*3; e.elite=true
    end
    safeCall(e,"setQuality",quality)
    enemies[#enemies+1]=e
    if typ=="miniboss" then bossAlive=true end
end

local function spawnBoss()
    spawnEnemy("miniboss",false)
    bossAlive=true
    play("explosion",0.65)
    flash(0.7,0.2,1,0.18)
    safeCall(camera,"shake",12,0.35,2)
end

local function spawnReward()
    local sw,sh=love.graphics.getWidth(),love.graphics.getHeight()
    local p=PowerUp.new(math.random(80,sw-80),math.random(100,sh-80))
    safeCall(p,"setQuality",quality)
    powerups[#powerups+1]=p
end

local function applyUpgrade(u)
    if not u then return end
    local ok=pcall(u.apply,player)
    if ok then
        addDroneFormation()
        play("levelup")
        flash(0.2,0.8,1,0.2)
    end
end

local function offerUpgrade()
    local XP=require("xp")
    upgradeChoices=XP.getRandomUpgrades(3)
    state="upgrade"
end

local function scoreKill(e)
    run.kills=run.kills+1
    run.combo=run.combo+1
    run.bestCombo=math.max(run.bestCombo,run.combo)
    run.threat=clamp(run.threat+0.025,0,1)
    local multiplier=1+math.min(run.combo,25)*0.06
    local mode=Modes.get(run.id)
    local reward=(e.score or 10)*multiplier*mode.scoreMultiplier
    if e.elite then reward=reward*1.75 end
    run.score=math.floor(run.score+reward)
    local xpAmount=(Enemy.types[e.type] and Enemy.types[e.type].xp) or 10
    if player.powerups and player.powerups.xpboost>0 then xpAmount=xpAmount*2 end
    local leveled=require("xp").addXP(xpData,xpAmount)
    safeCall(effects,"addDamageNumber",e.x,e.y,"+"..math.floor(reward))
    if e.elite then play("heavyShoot",0.35) else play("hit",0.35) end
    safeCall(particles,"explosion",e.x,e.y,e.elite and 1.8 or 0.9,e.elite and "electric" or "default")
    safeCall(camera,"shake",e.elite and 8 or 3,0.1,1)
    if leveled then offerUpgrade() end
    if math.random()<0.08 or e.elite then spawnReward() end
end

local function endRun(victory,reason)
    if state=="gameover" then return end
    run.completed=victory or false
    gameOverReason=reason or (victory and "MISSION COMPLETE" or "SHIP DESTROYED")
    newHighScore=run.score>highScore
    highScore=math.max(highScore,run.score)
    state="gameover"
    play(victory and "levelup" or "death",0.8)
    safeCall(Ads,"onGameOver",run.score)
    if Profile.hasProfile() then
        safeCall(Profile,"updateStats",run.score)
        safeCall(Profile,"incrementGamesPlayed")
        safeCall(Profile,"addStars",math.floor(run.score/50))
    end
    safeCall(particles,"explosion",player.x,player.y,2.2,"fire")
end

local function beginWave()
    local rules=Modes.waveRules(run)
    run.wave=run.wave
    run.target=rules.target
    run.spawned=0
    run.killedThisWave=0
    run.spawnTimer=0
    run.waveComplete=false
    waveAnnounce=1.5
    if rules.boss then spawnBoss() end
end

local function advanceWave()
    run.score=run.score+math.floor(run.wave*12*Modes.get(run.id).scoreMultiplier)
    play("highUp",0.7)
    flash(0.1,0.8,1,0.12)
    safeCall(effects,"addDamageNumber",love.graphics.getWidth()/2,110,"WAVE CLEAR +"..math.floor(run.wave*12))
    if run.id=="campaign" and run.wave>=30 then endRun(true,"CAMPAIGN COMPLETE") return end
    if run.id=="gauntlet" and run.trial>=8 then endRun(true,"GAUNTLET CLEARED") return end
    if run.id=="gauntlet" then
        if not Modes.nextGauntletTrial(run) then endRun(true,"GAUNTLET CLEARED") return end
    else
        run.wave=run.wave+1
    end
    beginWave()
end

local function updateRun(dt)
    run.elapsed=run.elapsed+dt
    if run.combo>0 then
        run.comboTimer=(run.comboTimer or 0)+dt
        if run.comboTimer>=comboTimeout then run.combo=0;run.comboTimer=0 end
    end
    player:update(dt,0,0,"pc")
    local mx,my=love.mouse.getPosition()
    local angle=util.angle(player.x,player.y,mx,my)
    if mouseDown or autoFire then
        local data=Weapons.types[currentWeapon]
        if data and player.shootCooldown<=0 and Weapons.hasAmmo(playerWeapons,currentWeapon) then
            local count=(data.bulletCount or 1)+(player.extraProjectiles or 0)
            for i=1,count do
                local a=angle
                if count>1 then a=a+(i-(count+1)/2)*(data.spread or 0)/count end
                local color=player.bulletColor or "yellow"
                local b=Bullet.new(player.x,player.y,a,"player",color)
                b.damage=(data.damage or 1)*10*(player.damageMultiplier or 1)
                b.speed=data.bulletSpeed or 400
                b.vx=math.cos(a)*b.speed;b.vy=math.sin(a)*b.speed
                b.piercing=player.piercingBullets or data.piercing
                if player.powerups.homing>0 and i==1 then b.homing=true;b.homingStrength=3.2 end
                if player.powerups.explosive>0 then b.explosion=true;b.explosionRadius=42 end
                bullets[#bullets+1]=b
            end
            Weapons.useAmmo(playerWeapons,currentWeapon,1)
            player.shootCooldown=data.fireRate*(player.fireRateMultiplier or 1)
            play((data.fireRate or 1)<0.15 and "shoot" or "heavyShoot",0.32)
            safeCall(particles,"thruster",player.x+math.cos(angle)*16,player.y+math.sin(angle)*16,angle,0.8)
        end
    end
    if player.dashTimer>0 then safeCall(particles,"dashTrail",player.x,player.y,player.radius) end

    for _,b in ipairs(bullets) do safeCall(b,"update",dt,enemies) end
    for _,e in ipairs(enemies) do
        e:update(dt,player.x,player.y)
        if e:canShoot() then
            local a=util.angle(e.x,e.y,player.x,player.y)
            local eb=Bullet.new(e.x,e.y,a,"enemy",e.type=="sniper" and "blue" or "yellow")
            eb.damage=(e.damage or 1)*(run.id=="gauntlet" and (Modes.waveRules(run).damageMultiplier or 1) or 1)
            eb.speed=e.type=="sniper" and 330 or 260
            eb.vx=math.cos(a)*eb.speed;eb.vy=math.sin(a)*eb.speed
            bullets[#bullets+1]=eb
            play("retroShoot",0.18)
        end
    end
    for _,p in ipairs(powerups) do p:update(dt) end
    for _,d in ipairs(drones) do
        local action=safeCall(d,"update",dt,player,enemies,bullets,powerups,{})
        if action and action.type=="shoot" then
            local b=Bullet.new(d.x,d.y,action.angle or 0,"player",action.color or "yellow")
            b.damage=(action.damage or 4)*(player.droneDamageMultiplier or 1)
            b.speed=420; b.vx=math.cos(action.angle or 0)*b.speed;b.vy=math.sin(action.angle or 0)*b.speed
            bullets[#bullets+1]=b;play("shoot",0.18)
        end
    end
    util.removeDeadEntities(bullets);util.removeDeadEntities(powerups);util.removeDeadEntities(drones)

    -- Player projectiles vs enemies. Dead entities are scored exactly once.
    for _,b in ipairs(bullets) do
        if b.owner=="player" and not b.dead then
            for _,e in ipairs(enemies) do
                if not e.dead and util.checkCollision(b.x,b.y,b.radius,e.x,e.y,e.radius) then
                    e:takeDamage(b.damage or 1)
                    b.dead=not (player.piercingBullets or b.piercing)
                    safeCall(particles,"impact",e.x,e.y,util.angle(b.x,b.y,e.x,e.y),1)
                    if e.dead and not e._scored then e._scored=true;run.killedThisWave=run.killedThisWave+1;scoreKill(e) end
                    break
                end
            end
        end
    end
    -- Enemy projectiles vs player.
    for _,b in ipairs(bullets) do
        if b.owner=="enemy" and not b.dead and util.checkCollision(b.x,b.y,b.radius,player.x,player.y,player.radius) then
            if player:takeDamage(b.damage or 1) then
                b.dead=true;run.combo=0;run.comboTimer=0
                play("playerHit",0.6);flash(1,0.15,0.1,0.22);safeCall(camera,"shake",10,0.2,2)
                if player.health<=0 then endRun(false,"SHIP DESTROYED") end
            else b.dead=true end
        end
    end
    util.removeDeadEntities(enemies)

    -- Player pickups.
    for i=#powerups,1,-1 do
        local p=powerups[i]
        local d=util.distance(player.x,player.y,p.x,p.y)
        if player.magneticRange>0 and d<player.magneticRange then
            local a=util.angle(p.x,p.y,player.x,player.y);p.baseY=p.y;p.x=p.x+math.cos(a)*220*dt;p.y=p.y+math.sin(a)*220*dt
        end
        if util.checkCollision(player.x,player.y,player.radius,p.x,p.y,p.radius) then
            player:applyPowerUp(p.type);table.remove(powerups,i);play("shield",0.65);flash(0.2,0.9,1,0.12);safeCall(particles,"healEffect",player.x,player.y,20)
        end
    end

    local rules=Modes.waveRules(run)
    if run.spawned < run.target then
        run.spawnTimer=run.spawnTimer+dt
        if run.spawnTimer>=rules.spawnDelay then
            run.spawnTimer=0;run.spawned=run.spawned+1
            local elite=math.random()<rules.eliteChance and run.spawned>3
            spawnEnemy(nil,elite)
        end
    elseif #enemies==0 then
        advanceWave()
    end

    if run.id=="gauntlet" then
        run.trialTimer=run.trialTimer+dt
        if run.trialTimer>=run.trialDuration then
            -- Surviving a timed trial counts as a clear even if the last few enemies remain.
            for _,e in ipairs(enemies) do e.dead=true end
            enemies={}
            advanceWave()
        end
    end
end

local function drawSpace()
    local sw,sh=love.graphics.getWidth(),love.graphics.getHeight()
    local bg=Assets.get("background")
    if bg then Assets.drawImage(bg,sw/2,sh/2,sw,sh,0,1) else love.graphics.clear(0.005,0.008,0.02) end
    local stars=Assets.get("starsA")
    if stars then Assets.drawImage(stars,sw/2,sh/2,sw,sh,0,0.28) end
    local stars2=Assets.get("starsB")
    if stars2 then Assets.drawImage(stars2,sw/2,sh/2,sw,sh,0,0.18) end
    -- Slow rotating planet is selected from the complete ten-planet set.
    local pi=(math.floor(time/7)%10)
    local planet=Assets.get("planet"..string.format("%02d",pi))
    if planet then
        local px=sw*0.78+math.sin(time*0.08)*40;local py=sh*0.30
        Assets.drawImage(planet,px,py,180,180,math.sin(time*0.03)*0.15,0.28)
    end
end

local function drawWorld()
    drawSpace()
    for _,p in ipairs(powerups) do p:draw() end
    for _,d in ipairs(drones) do d:draw() end
    player:draw(Assets.get("player"))
    for _,b in ipairs(bullets) do b:draw() end
    for _,e in ipairs(enemies) do e:draw(player.x,player.y) end
    particles:draw()
end

local function drawHUD()
    local sw,sh=love.graphics.getWidth(),love.graphics.getHeight()
    local mode=Modes.get(run.id)
    drawPanel(16,16,370,92,0.74)
    love.graphics.setFont(font(18));love.graphics.setColor(0.72,0.9,1);love.graphics.print(mode.name,30,27)
    love.graphics.setFont(font(30));love.graphics.setColor(1,1,1);love.graphics.print("WAVE "..run.wave,30,51)
    love.graphics.setFont(font(18));love.graphics.setColor(1,0.86,0.3);love.graphics.print("SCORE "..run.score,180,31)
    love.graphics.setColor(0.6,0.72,0.8);love.graphics.print("KILLS "..run.kills,180,57)
    love.graphics.setColor(1,0.3,0.35);love.graphics.print("HP "..math.ceil(player.health).."/"..player.maxHealth,290,31)
    love.graphics.setColor(0.7,0.8,0.9);love.graphics.print("x"..run.combo,290,57)

    local barW=300;local bx=(sw-barW)/2;local by=sh-34
    local xp=clamp(xpData.current/xpData.toNextLevel,0,1)
    love.graphics.setColor(0.02,0.03,0.06,0.9);love.graphics.rectangle("fill",bx,by,barW,14,7,7)
    love.graphics.setColor(0.2,0.75,1,0.9);love.graphics.rectangle("fill",bx,by,barW*xp,14,7,7)
    love.graphics.setFont(font(12));love.graphics.setColor(1,1,1,0.9);love.graphics.printf("LV "..xpData.level.."   XP",bx,by-18,barW,"center")

    local wd=Weapons.types[currentWeapon]
    love.graphics.setFont(font(16));love.graphics.setColor(1,1,1,0.88);love.graphics.printf(wd.name,bx,sh-80,barW,"center")
    love.graphics.setFont(font(13));love.graphics.setColor(0.65,0.75,0.85);love.graphics.printf("[1-4] WEAPON   [SPACE] DASH   [ESC] PAUSE",0,sh-18,sw,"center")
    if run.id=="gauntlet" then
        local m=run.mutator
        drawPanel(sw-285,16,269,86,0.72)
        love.graphics.setFont(font(16));love.graphics.setColor(0.9,0.45,1);love.graphics.print(m.name,sw-270,28)
        love.graphics.setFont(font(12));love.graphics.setColor(0.8,0.8,0.9);love.graphics.printf(m.desc,sw-270,52,240,"left")
        love.graphics.setColor(1,1,1);love.graphics.printf(string.format("TRIAL %d/8  %.0fs",run.trial,math.max(0,run.trialDuration-run.trialTimer)),sw-270,80,240,"left")
    end
    if waveAnnounce>0 then
        local a=clamp(waveAnnounce/1.5,0,1)
        love.graphics.setFont(font(46));love.graphics.setColor(0.6,0.9,1,a);love.graphics.printf("WAVE "..run.wave,0,sh*0.30,sw,"center")
    end
end

local function drawMenu()
    drawSpace();local sw,sh=love.graphics.getWidth(),love.graphics.getHeight()
    local y=80+math.sin(menuPulse)*5
    love.graphics.setFont(font(58));love.graphics.setColor(0.25,0.85,1,0.25);love.graphics.printf("STARFALL VENGEANCE",0,y-3,sw,"center");love.graphics.setColor(0.86,0.98,1);love.graphics.printf("STARFALL VENGEANCE",0,y,sw,"center")
    love.graphics.setFont(font(18));love.graphics.setColor(0.65,0.78,0.9);love.graphics.printf("ARCADE SPACE COMBAT • SURVIVE • ADAPT • DOMINATE",0,y+62,sw,"center")
    local buttons={
        {x=sw/2-125,y=sh/2-20,w=250,h=58,text="PLAY"},
        {x=sw/2-125,y=sh/2+55,w=250,h=58,text="HOW TO PLAY"},
        {x=sw/2-125,y=sh/2+130,w=250,h=58,text="SETTINGS"},
    }
    for _,r in ipairs(buttons) do drawButton(r) end
    drawPanel(sw/2-360,sh-105,720,65,0.58)
    love.graphics.setFont(font(14));love.graphics.setColor(0.72,0.82,0.9);love.graphics.printf("3 MODES  •  30-WAVE CAMPAIGN  •  INFINITE ENDLESS  •  8-TRIAL GAUNTLET",sw/2-340,sh-85,680,"center")
    love.graphics.setFont(font(12));love.graphics.setColor(0.5,0.6,0.7);love.graphics.printf("Best: "..highScore,0,sh-25,sw,"center")
end

local function drawModeSelect()
    drawSpace();local sw,sh=love.graphics.getWidth(),love.graphics.getHeight()
    love.graphics.setFont(font(46));love.graphics.setColor(0.8,0.95,1);love.graphics.printf("SELECT YOUR RUN",0,65,sw,"center")
    for i,id in ipairs(modeIds) do
        local m=Modes.get(id);local x=sw/2-430+(i-1)*290;local y=170
        local selected=i==selectedMode
        drawPanel(x,y,260,330,selected and 0.88 or 0.72)
        local c=Modes.modeColor(id)
        love.graphics.setColor(c[1],c[2],c[3],selected and 1 or 0.72);love.graphics.setFont(font(26));love.graphics.printf(m.name,x,y+28,260,"center")
        love.graphics.setFont(font(15));love.graphics.setColor(0.85,0.9,0.96);love.graphics.printf(m.tagline,x+20,y+72,220,"center")
        love.graphics.setFont(font(13));love.graphics.setColor(0.65,0.72,0.82);love.graphics.printf(m.description,x+20,y+118,220,"center")
        love.graphics.setFont(font(14));love.graphics.setColor(1,1,1);love.graphics.printf("GOAL",x+20,y+214,220,"center");love.graphics.setColor(c[1],c[2],c[3]);love.graphics.printf(m.goal,x+20,y+238,220,"center")
        local r={x=x+30,y=y+275,w=200,h=40,text=selected and "SELECTED" or "CHOOSE"};drawButton(r,c)
    end
    local back={x=sw/2-100,y=sh-70,w=200,h=42,text="BACK"};drawButton(back,{0.3,0.4,0.55})
end

local function drawUpgrade()
    drawWorld();local sw,sh=love.graphics.getWidth(),love.graphics.getHeight();love.graphics.setColor(0,0,0,0.78);love.graphics.rectangle("fill",0,0,sw,sh)
    love.graphics.setFont(font(48));love.graphics.setColor(1,0.9,0.35);love.graphics.printf("LEVEL UP",0,80,sw,"center")
    love.graphics.setFont(font(18));love.graphics.setColor(0.8,0.9,1);love.graphics.printf("Choose one permanent run upgrade",0,140,sw,"center")
    for i,u in ipairs(upgradeChoices) do
        local x=sw/2-410+(i-1)*280;local y=220
        local r={x=x,y=y,w=250,h=190,text=""};local h=pointInRect(love.mouse.getPosition(),r)
        drawPanel(x,y,250,190,h and 0.95 or 0.8)
        love.graphics.setFont(font(19));love.graphics.setColor(0.35,0.85,1);love.graphics.printf(u.name,x+15,y+22,220,"center")
        love.graphics.setFont(font(14));love.graphics.setColor(0.8,0.85,0.92);love.graphics.printf(u.description,x+20,y+70,210,"center")
        love.graphics.setFont(font(12));love.graphics.setColor(0.55,0.65,0.75);love.graphics.printf("CLICK TO INSTALL",x+20,y+150,210,"center")
    end
end

local function drawGameOver()
    drawSpace();local sw,sh=love.graphics.getWidth(),love.graphics.getHeight();love.graphics.setColor(0,0,0,0.74);love.graphics.rectangle("fill",0,0,sw,sh)
    love.graphics.setFont(font(62));love.graphics.setColor(run.completed and 0.3 or 1,run.completed and 0.95 or 0.25,run.completed and 1 or 0.3);love.graphics.printf(run.completed and "VICTORY" or "GAME OVER",0,75,sw,"center")
    love.graphics.setFont(font(20));love.graphics.setColor(0.75,0.85,0.95);love.graphics.printf(gameOverReason,0,150,sw,"center")
    drawPanel(sw/2-250,200,500,220,0.88)
    love.graphics.setFont(font(34));love.graphics.setColor(1,0.86,0.3);love.graphics.printf(""..run.score,sw/2-230,230,460,"center")
    love.graphics.setFont(font(14));love.graphics.setColor(0.65,0.75,0.85);love.graphics.printf("SCORE",sw/2-230,270,460,"center")
    love.graphics.setFont(font(18));love.graphics.setColor(1,1,1);love.graphics.printf("Wave "..run.wave.."   •   "..run.kills.." kills   •   Best combo x"..run.bestCombo,sw/2-230,315,460,"center")
    if newHighScore then love.graphics.setColor(1,0.85,0.25);love.graphics.printf("★ NEW PERSONAL BEST ★",sw/2-230,355,460,"center") end
    local r1={x=sw/2-220,y=470,w=200,h=55,text="RETRY"};local r2={x=sw/2+20,y=470,w=200,h=55,text="MENU"};drawButton(r1);drawButton(r2,{0.3,0.42,0.58})
end

function love.load()
    love.window.setTitle("Starfall Vengeance")
    love.window.setMode(1280,720,{resizable=true,vsync=1,msaa=4})
    math.randomseed(os.time())
    Assets.load()
    sound=Sound.new();particles=Particles.new();effects=Effects.new();camera=Camera.new()
    quality="high";safeCall(particles,"setQuality",quality);safeCall(effects,"setQuality",quality);safeCall(camera,"setQuality",quality)
    pcall(Profile.init);pcall(function() if not Profile.hasProfile() then Profile.createProfile("Guest") end end)
    state="menu"
    love.mouse.setVisible(true)
end

function love.update(dt)
    dt=math.min(dt or 0.016,0.05);time=time+dt;menuPulse=menuPulse+dt*1.8
    if screenFlash>0 then screenFlash=math.max(0,screenFlash-dt*2.5) end
    safeCall(particles,"update",dt);safeCall(effects,"update",dt);safeCall(camera,"update",dt)
    if waveAnnounce>0 then waveAnnounce=math.max(0,waveAnnounce-dt) end
    if state=="playing" then updateRun(dt) end
end

function love.draw()
    love.graphics.clear(0,0,0)
    if state=="menu" then drawMenu()
    elseif state=="modes" then drawModeSelect()
    elseif state=="playing" then drawWorld();drawHUD()
    elseif state=="upgrade" then drawUpgrade()
    elseif state=="gameover" then drawGameOver()
    elseif state=="help" then
        drawSpace();local sw,sh=love.graphics.getWidth(),love.graphics.getHeight();drawPanel(sw/2-420,90,840,500,0.9)
        love.graphics.setFont(font(40));love.graphics.setColor(0.7,0.9,1);love.graphics.printf("HOW TO PLAY",0,125,sw,"center")
        love.graphics.setFont(font(17));love.graphics.setColor(0.8,0.86,0.94);love.graphics.printf("WASD / ARROWS  Move\nMouse  Aim + Fire\nSPACE  Dash / evade\n1-4  Switch weapons\nESC  Pause\n\nBuild combos to multiply score. Collect power-ups.\nLevel up to install permanent run upgrades.\nElites are dangerous but dramatically increase rewards.\nEach mode has different pacing and win conditions.\n\nCAMPAIGN  Clear 30 curated waves.\nENDLESS  Survive infinite adaptive scaling.\nGAUNTLET  Clear 8 timed trials with mutators.",sw/2-350,205,700,"center")
        drawButton({x=sw/2-100,y=525,w=200,h=45,text="BACK"},{0.3,0.45,0.65})
    elseif state=="paused" then
        drawWorld();love.graphics.setColor(0,0,0,0.65);love.graphics.rectangle("fill",0,0,love.graphics.getWidth(),love.graphics.getHeight());local sw,sh=love.graphics.getWidth(),love.graphics.getHeight();love.graphics.setFont(font(58));love.graphics.setColor(1,1,1);love.graphics.printf("PAUSED",0,170,sw,"center");drawButton({x=sw/2-110,y=270,w=220,h=50,text="RESUME"});drawButton({x=sw/2-110,y=340,w=220,h=50,text="QUIT RUN"},{0.3,0.4,0.55})
    end
    if screenFlash>0 then love.graphics.setColor(flashColor[1],flashColor[2],flashColor[3],screenFlash*0.16);love.graphics.rectangle("fill",0,0,love.graphics.getWidth(),love.graphics.getHeight()) end
end

function love.mousepressed(x,y,button)
    if button~=1 then return end
    if state=="menu" then
        local sw,sh=love.graphics.getWidth(),love.graphics.getHeight()
        if pointInRect(x,y,{x=sw/2-125,y=sh/2-20,w=250,h=58}) then play("menu",0.5);state="modes"
        elseif pointInRect(x,y,{x=sw/2-125,y=sh/2+55,w=250,h=58}) then state="help"
        elseif pointInRect(x,y,{x=sw/2-125,y=sh/2+130,w=250,h=58}) then state="help" end
    elseif state=="modes" then
        local sw,sh=love.graphics.getWidth(),love.graphics.getHeight()
        for i=1,3 do local x0=sw/2-430+(i-1)*290;if pointInRect(x,y,{x=x0,y=170,w=260,h=330}) then selectedMode=i; if y>445 then resetWorld();state="playing";pcall(function() Ads.onGameStart() end);beginWave() else selectedMode=i end;return end end
        if pointInRect(x,y,{x=sw/2-100,y=sh-70,w=200,h=42}) then state="menu" end
    elseif state=="playing" then
        mouseDown=true
    elseif state=="upgrade" then
        local sw=love.graphics.getWidth()
        for i=1,#upgradeChoices do local x0=sw/2-410+(i-1)*280;if pointInRect(x,y,{x=x0,y=220,w=250,h=190}) then applyUpgrade(upgradeChoices[i]);state="playing";return end end
    elseif state=="gameover" then
        local sw=love.graphics.getWidth();if pointInRect(x,y,{x=sw/2-220,y=470,w=200,h=55}) then resetWorld();state="playing";beginWave();pcall(function() Ads.onGameStart() end) elseif pointInRect(x,y,{x=sw/2+20,y=470,w=200,h=55}) then state="menu" end
    elseif state=="help" then state="menu"
    elseif state=="paused" then
        local sw=love.graphics.getWidth();if pointInRect(x,y,{x=sw/2-110,y=270,w=220,h=50}) then state="playing" elseif pointInRect(x,y,{x=sw/2-110,y=340,w=220,h=50}) then state="menu" end
    end
end

function love.mousereleased(x,y,button) if button==1 then mouseDown=false end end

function love.keypressed(key)
    if key=="escape" then
        if state=="playing" then state="paused" elseif state=="paused" then state="playing" elseif state=="help" or state=="modes" then state="menu" end
        return
    end
    if state=="playing" then
        if key=="1" and playerWeapons.pistol.unlocked then currentWeapon="pistol"
        elseif key=="2" and playerWeapons.shotgun.unlocked then currentWeapon="shotgun"
        elseif key=="3" and playerWeapons.machinegun.unlocked then currentWeapon="machinegun"
        elseif key=="4" and playerWeapons.sniper.unlocked then currentWeapon="sniper"
        elseif key=="space" then
            if player:dash() then safeCall(particles,"dashTrail",player.x,player.y,player.radius);play("heavyShoot",0.5);safeCall(camera,"shake",4,0.08,1) end
        end
    elseif state=="modes" then
        if key=="left" or key=="a" then selectedMode=selectedMode%3+1 elseif key=="right" or key=="d" then selectedMode=(selectedMode-2)%3+1 elseif key=="return" or key=="space" then resetWorld();state="playing";beginWave() end
    end
end

return nil
