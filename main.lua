-- Main game file for Starfall Vengeance
-- Web-ready arcade space shooter

local util = require("util")
local Player = require("player")
local Bullet = require("bullet")
local Enemy = require("enemy")
local PowerUp = require("powerup")
local Camera = require("camera")
local Background = require("background")
local Weapons = require("weapons")
local Ammo = require("ammo")
local XP = require("xp")
local Shaders = require("shaders")
local Particles = require("particles")
local Effects = require("effects")
local UI = require("ui")
local Sound = require("sound")
local TouchControls = require("touchcontrols")
local Drone = require("drone")
local AIDirector = require("aidirector")
local Profile = require("profile")
local Leaderboard = require("leaderboard")
local Ads = require("ads")

-- Game state
local gameState = "menu"
local controlType = nil
local touchControls = nil
local gameMode = "classic"
local previousState = "menu" -- Track previous state for back buttons
local menuButtons = {}
local menuTime = 0
local gameTimer = 0
local timeLimit = 300
local quality = "high"
local tutorialStep = 0
local tutorialPrompt = nil
local shotSequence = 0
local classicVictory = false

-- Profile and leaderboard state
local profileNameInput = ""
local profileInputActive = false
local profileError = nil
local leaderboardScroll = 0
local showDeleteConfirmation = false

-- Game objects
local player
local bullets = {}
local enemies = {}
local powerups = {}
local ammoPickups = {}
local drones = {}
local score = 0
local particles
local camera
local background
local shaders
local particleManager
local effects
local ui
local aiDirector

-- Asset images
local images
local fonts = {}

-- Cached font accessor. Unknown sizes are created once and then reused.
local function getFont(size)
    size = tonumber(size) or 20
    if not fonts[size] then
        fonts[size] = love.graphics.newFont(size)
    end
    return fonts[size]
end

-- Player progression
local playerXP
local currentWeapon = "pistol"
local playerWeapons
local upgradeChoices = {}

-- Wave system
local wave = 1
local enemiesInWave = 0
local enemiesKilledThisWave = 0
local waveDelay = 3.0
local waveTimer = 0
local inWave = false

-- Spawning
local enemySpawnTimer = 0
local enemySpawnDelay = 2.0
local powerupSpawnTimer = 0
local powerupSpawnDelay = 10.0
local ammoSpawnTimer = 0
local ammoSpawnDelay = 8.0

-- Combo system
local combo = 0
local comboTimer = 0
local comboTimeout = 3.0

-- Stats
local totalKills = 0
local highScore = 0
local totalDamageDealt = 0
local bulletsFired = 0
local bulletsHit = 0

function love.load()
    love.window.setTitle("Starfall Vengeance")
    math.randomseed(os.time())
    love.mouse.setVisible(true)
    local fontSizes = {10,11,12,13,14,16,18,20,22,24,26,28,36,40,48,56,64,72}
    fonts = {}
    for _, size in ipairs(fontSizes) do fonts[size] = love.graphics.newFont(size) end
    love.graphics.setFont(fonts[20])

    -- Set window icon
    local icon = love.image.newImageData("icon.png")
    love.window.setIcon(icon)
    
    -- Load asset images
    images = {
        ship = love.graphics.newImage("assets/ship.png"),
        swarmer = love.graphics.newImage("assets/SWARMERS.png"),
        sniper = love.graphics.newImage("assets/SNIPERS.png"),
        bomber = love.graphics.newImage("assets/BOMBERS.png"),
        turret = love.graphics.newImage("assets/TURRET DRONES.png"),
        miniboss = love.graphics.newImage("assets/MINI-BOSSES.png"),
        pet1 = love.graphics.newImage("assets/pet 1.png"),
        pet2 = love.graphics.newImage("assets/pet 2.png"),
        pet3 = love.graphics.newImage("assets/pet 3.png")
    }
    
    camera = Camera.new()
    background = Background.new()
    shaders = Shaders.new()
    particleManager = Particles.new()
    effects = Effects.new()
    ui = UI.new()
    sound = Sound.new()
    aiDirector = AIDirector.new()

    -- Runtime quality defaults and adaptive device controls
    quality = "high"
    particleManager:setQuality(quality)
    effects:setQuality(quality)
    camera:setQuality(quality)
    background:setQuality(quality)
    ui:setQuality(quality)
    shaders:setQuality(quality)
    
    -- Initialize profile and leaderboard systems
    Profile.init()
    Leaderboard.init()
    
    -- Auto-create guest profile if none exists
    if not Profile.hasProfile() then
        Profile.createProfile("Guest")
    end
    
    -- Leaderboard loads from persistent storage automatically via init()
    
    local osName = love.system.getOS()
    controlType = (osName == "Android" or osName == "iOS") and "mobile" or "pc"
    if controlType == "mobile" then touchControls = TouchControls.new() end

    resetGame()
    
    -- Initialize menu buttons
    initMenuButtons()
    
    -- Start background music
    sound:playMusic()
    Ads.onGameStart()
end

function initMenuButtons()
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Control selection buttons
    menuButtons.controlPC = {
        x = sw/2 - 280,
        y = sh/2 - 50,
        width = 250,
        height = 100,
        text = "PC CONTROLS",
        hovered = false
    }
    
    menuButtons.controlMobile = {
        x = sw/2 + 30,
        y = sh/2 -50,
        width = 250,
        height = 100,
        text = "MOBILE CONTROLS",
        hovered = false
    }
    
    -- Home screen buttons
    menuButtons.play = {
        x = sw/2 - 100,
        y = sh/2 + 20,
        width = 200,
        height = 50,
        text = "PLAY",
        hovered = false
    }
    
    menuButtons.credits = {
        x = sw/2 - 100,
        y = sh/2 + 90,
        width = 200,
        height = 50,
        text = "CREDITS",
        hovered = false
    }
    
    menuButtons.shop = {
        x = sw/2 - 100,
        y = sh/2 + 230,
        width = 200,
        height = 50,
        text = "SHOP",
        hovered = false
    }
    
    menuButtons.settings = {
        x = sw/2 - 100,
        y = sh/2 + 160,
        width = 200,
        height = 50,
        text = "SETTINGS",
        hovered = false
    }
    
    -- Credits/Settings screen button
    menuButtons.back = {
        x = sw/2 - 100,
        y = sh - 100,
        width = 200,
        height = 50,
        text = "BACK",
        hovered = false
    }
    
    -- Pause screen buttons
    -- Pause screen buttons
    menuButtons.pauseResume = {
        x = sw/2 - 100,
        y = sh/2 - 30,
        width = 200,
        height = 50,
        text = "RESUME",
        hovered = false
    }
    
    menuButtons.pauseSettings = {
        x = sw/2 - 100,
        y = sh/2 + 40,
        width = 200,
        height = 50,
        text = "SETTINGS",
        hovered = false
    }
    
    menuButtons.pauseHome = {
        x = sw/2 - 100,
        y = sh/2 + 110,
        width = 200,
        height = 50,
        text = "HOME",
        hovered = false
    }

    -- In-game Pause Button (Bottom Left)
    menuButtons.pauseBtn = {
        x = 20,
        y = sh - 70,
        width = 50,
        height = 50,
        text = "||",
        hovered = false
    }
    

    
    -- Mode selection buttons
    menuButtons.modeClassic = {
        x = sw/2 - 270,
        y = sh/2 - 40,
        width = 240,
        height = 90,
        text = "CLASSIC",
        desc = "30 waves to win",
        hovered = false
    }
    
    menuButtons.modeEndless = {
        x = sw/2 + 30,
        y = sh/2 - 40,
        width = 240,
        height = 90,
        text = "ENDLESS",
        desc = "Infinite waves",
        hovered = false
    }
    
    -- Game over screen buttons (at bottom)
    menuButtons.gameoverRestart = {
        x = sw/2 - 270,
        y = sh - 100,
        width = 240,
        height = 70,
        text = "RESTART",
        hovered = false
    }
    
    menuButtons.gameoverHome = {
        x = sw/2 + 30,
        y = sh - 100,
        width = 240,
        height = 70,
        text = "HOME",
        hovered = false
    }
    
    -- Profile/Leaderboard buttons (home screen)
    menuButtons.profileIcon = {
        x = 20,
        y = 20,
        width = 60,
        height = 60,
        text = "",
        hovered = false
    }
    
    menuButtons.leaderboardBtn = {
        x = sw - 180,
        y = 20,
        width = 160,
        height = 50,
        text = "LEADERBOARD",
        hovered = false
    }
    
    -- Profile screen buttons
    menuButtons.profileSubmit = {
        x = sw/2 - 100,
        y = sh/2 + 50,
        width = 200,
        height = 50,
        text = "SUBMIT",
        hovered = false
    }
    
    menuButtons.profileDelete = {
        x = sw/2 - 100,
        y = sh - 180,
        width = 200,
        height = 50,
        text = "DELETE PROFILE",
        hovered = false
    }
    
    -- Leaderboard screen button
    menuButtons.leaderboardClose = {
        x = sw - 110,
        y = 20,
        width = 90,
        height = 40,
        text = "CLOSE",
        hovered = false
    }
    
    -- Settings screen button
    menuButtons.qualityToggle = {
        x = sw/2 - 120, y = sh/2 + 80, width = 240, height = 50, text = "QUALITY", hovered = false
    }

end


local function syncUpgradeDrones()
    if not player then return end
    local sideCount, orbitCount = 0, 0
    for _, d in ipairs(drones) do
        if d.formation == "side" then sideCount = sideCount + 1 end
        if d.formation == "orbit_upgrade" then orbitCount = orbitCount + 1 end
    end
    if player.hasSideDrones then
        while sideCount < 2 do
            sideCount = sideCount + 1
            local d = Drone.new(player.x, player.y, "attack", "player")
            d.formation="side"; d.formationIndex=sideCount; d.formationCount=2; d.damage=(d.damage or 0.5)*(player.droneDamageMultiplier or 1); d:setQuality(quality)
            drones[#drones+1]=d
        end
    end
    if player.hasOrbitDrones then
        while orbitCount < 2 do
            orbitCount = orbitCount + 1
            local d = Drone.new(player.x, player.y, "attack", "player")
            d.formation="orbit_upgrade"; d.formationIndex=orbitCount; d.formationCount=2; d.orbitSpeed=2.5; d.damage=(d.damage or 0.5)*(player.droneDamageMultiplier or 1); d:setQuality(quality)
            drones[#drones+1]=d
        end
    end
end

function resetGame()
    player = Player.new(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
    
    -- Init player progression
    player.fireRateMultiplier = 1.0
    player.damageMultiplier = 1.0
    player.magneticRange = 0
    player.piercingBullets = false
    player.extraProjectiles = 0
    player.hasSideDrones = false
    player.hasOrbitDrones = false
    player.hasHomingMissile = false
    player.explosionSizeMultiplier = 1.0
    player.droneDamageMultiplier = 1.0
    
    playerXP = XP.new()
    playerWeapons = Weapons.new()
    currentWeapon = "pistol"
    
    bullets = {}
    enemies = {}
    powerups = {}
    ammoPickups = {}
    drones = {}  -- Reset drones
    
    -- Spawn equipped pet
    local profile = Profile.getProfile()
    if profile and profile.equippedPet and profile.equippedPet ~= "none" then
        local pet = Drone.new(player.x, player.y, profile.equippedPet, "player")
        table.insert(drones, pet)
    end
    
    score = 0
    totalKills = 0
    totalDamageDealt = 0
    bulletsFired = 0
    bulletsHit = 0
    shotSequence = 0
    classicVictory = false
    tutorialStep = 1
    tutorialPrompt = nil
    combo = 0
    comboTimer = 0
    
    wave = 1
    enemiesInWave = 5
    enemiesKilledThisWave = 0
    waveTimer = 0
    inWave = false
    
    enemySpawnTimer = 0
    enemySpawnDelay = 2.0
    powerupSpawnTimer = 0
    ammoSpawnTimer = 0
    
end

function love.update(dt)
    menuTime = menuTime + dt
    
    background:update(dt)
    camera:update(dt)
    particleManager:update(dt)
    effects:update(dt)
    
    -- Update button hover states
    local mx, my = love.mouse.getPosition()
    for name, btn in pairs(menuButtons) do
        btn.hovered = mx >= btn.x and mx <= btn.x + btn.width and 
                      my >= btn.y and my <= btn.y + btn.height
    end
    
    if gameState == "levelup" then
        -- Paused for level up selection
        return
    end
    
    if gameState == "playing" then
        local joyX, joyY = 0, 0
        
        -- Get movement from mobile controls if active
        if controlType == "mobile" and touchControls then
            joyX, joyY = touchControls:getMovement()
        end
        
        local oldPlayerX, oldPlayerY = player.x, player.y
        player:update(dt, joyX, joyY, controlType)
        if tutorialStep == 1 and (math.abs(player.x-oldPlayerX) > 0.5 or math.abs(player.y-oldPlayerY) > 0.5) then
            completeTutorialStep()
        end
        
        -- Update AI Director
        aiDirector:update(dt, player, enemies, wave)
        aiDirector:setCombo(combo)
        
        -- Get current XP safely  
        local currentXP = playerXP.current or 0
        ui:update(dt, player, score, currentXP, playerXP.toNextLevel or 100, combo, wave)
        
        -- Handle dash (only allow spacebar dash in PC mode)
        if controlType ~= "mobile" and love.keyboard.isDown("space") then
            if player:dash() then
                -- Create dash particles
                particleManager:dashTrail(player.x, player.y, player.radius)
                sound:playSound("dash")
                if tutorialStep == 3 then completeTutorialStep() end
            end
        end
        
        -- Mobile aim joystick control
        if controlType == "mobile" and touchControls then
            local aimX, aimY = touchControls:getAimDirection()
            
            -- Update player rotation based on aim joystick
            if aimX ~= 0 or aimY ~= 0 then
                player.aimAngle = math.atan2(aimY, aimX)
                player.hasAimOverride = true
                
                -- Auto-shoot when aim joystick is fully stretched
                if touchControls:isShooting() then
                    local weaponData = Weapons.types[currentWeapon]
                    local fireRate = weaponData.fireRate * player.fireRateMultiplier
                    
                    if player.shootCooldown <= 0 and Weapons.hasAmmo(playerWeapons, currentWeapon) then
                        local angle = player.aimAngle
                        local bulletCount = weaponData.bulletCount + player.extraProjectiles
                        local spread = weaponData.spread
                        
                        local color = player.bulletColor
                        local baseDamage = 10
                        if color == "blue" then baseDamage = 15 end
                        if color == "green" then baseDamage = 25 end
                        
                        for i = 1, bulletCount do
                            local bulletAngle = angle
                            if bulletCount > 1 then
                                local spreadOffset = (i - (bulletCount + 1) / 2) * spread / bulletCount
                                bulletAngle = angle + spreadOffset
                            end
                            
                            local bullet = Bullet.new(player.x, player.y, bulletAngle, "player", color)
                            bullet.damage = baseDamage * player.damageMultiplier
                            bullet.speed = weaponData.bulletSpeed
                            bullet.vx = math.cos(bulletAngle) * bullet.speed
                            bullet.vy = math.sin(bulletAngle) * bullet.speed
                            table.insert(bullets, bullet)
                            bulletsFired = bulletsFired + 1
                            shotSequence = shotSequence + 1
                            if player.hasHomingMissile and shotSequence % 5 == 0 then
                                bullet.homing = true; bullet.homingStrength = 3.5; bullet.speed = bullet.speed * 0.75
                                bullet.explosion = true; bullet.explosionRadius = 40 * (player.explosionSizeMultiplier or 1)
                                bullet.vx = math.cos(bulletAngle) * bullet.speed; bullet.vy = math.sin(bulletAngle) * bullet.speed
                            end
                            aiDirector:recordShot()  -- Track shot for AI director
                        end
                        
                        sound:playSound("shoot")
                        player.shootCooldown = fireRate
                        Weapons.useAmmo(playerWeapons, currentWeapon, 1)
                        createMuzzleFlash(player.x, player.y, angle)
                    end
                end
            else
                -- No aim input, reset to mouse control
                player.hasAimOverride = false
            end
        else
            -- PC mode uses mouse
            player.hasAimOverride = false
        end
        
        -- Update bullets
        for i, bullet in ipairs(bullets) do
            bullet:update(dt, enemies)
        end
        util.removeDeadEntities(bullets)
        
        -- Update enemies
        for i, enemy in ipairs(enemies) do
            enemy:update(dt, player.x, player.y)
            
            if enemy:canShoot() then
                local angle = util.angle(enemy.x, enemy.y, player.x, player.y)
                
                -- Determine bullet properties based on enemy type
                local bulletColor = "yellow"
                local bulletDamage = 1.0
                
                if enemy.type == "miniboss" or enemy.type == "turret" or enemy.type == "shielded" or enemy.type == "teleporter" then
                    bulletColor = "blue"
                    bulletDamage = 1.5
                end
                
                local bullet = Bullet.new(enemy.x, enemy.y, angle, "enemy", bulletColor)
                bullet.damage = bulletDamage
                table.insert(bullets, bullet)
            end
        end
        util.removeDeadEntities(enemies)
        
        syncUpgradeDrones()

        -- Update drones
        for i, drone in ipairs(drones) do
            local action = drone:update(dt, player, enemies, bullets, powerups, ammoPickups)
            if action then
                if action.type == "shoot" then
                    -- Drone fires bullet
                    local color = action.color or player.bulletColor
                    local baseDamage = 10
                    if color == "blue" then baseDamage = 15 end
                    if color == "green" then baseDamage = 25 end
                    
                    local bullet = Bullet.new(drone.x, drone.y, action.angle, "player", color)
                    bullet.damage = (action.damage or baseDamage) * (player.droneDamageMultiplier or 1)
                    table.insert(bullets, bullet)
                    sound:playSound("shoot")
                elseif action.type == "heal" then
                    -- Drone heals player
                    player.health = math.min(player.health + action.amount, player.maxHealth)
                    createDamageNumber(player.x, player.y - 20, "+" .. action.amount, 0.3, 1, 0.3)
                end
            end
        end
        util.removeDeadEntities(drones)
        
        -- Update power-ups
        for i, powerup in ipairs(powerups) do
            powerup:update(dt)
        end
        util.removeDeadEntities(powerups)
        
        -- Update ammo pickups
        for i, ammo in ipairs(ammoPickups) do
            ammo:update(dt)
        end
        util.removeDeadEntities(ammoPickups)
        
        -- Wave system
        if not inWave then
            waveTimer = waveTimer + dt
            if waveTimer >= waveDelay then
                startWave()
            end
        else
            if enemiesKilledThisWave < enemiesInWave then
                enemySpawnTimer = enemySpawnTimer + dt
                if enemySpawnTimer >= enemySpawnDelay then
                    enemySpawnTimer = 0
                    spawnEnemy()
                end
            else
                if #enemies == 0 then
                    completeWave()
                end
            end
        end
        
        -- AI-controlled power-up spawning
        if aiDirector:shouldSpawnPowerup() then
            local powerupType = aiDirector:getRecommendedPowerup()
            spawnSpecificPowerUp(powerupType)
        end
        
        -- AI-controlled elite enemy spawning
        if aiDirector:shouldSpawnElite() and inWave then
            spawnEliteEnemy()
        end
        
        -- Spawn ammo
        ammoSpawnTimer = ammoSpawnTimer + dt
        if ammoSpawnTimer >= ammoSpawnDelay then
            ammoSpawnTimer = 0
            spawnAmmo()
        end
        
        -- Bullet-enemy collisions
        for i = #bullets, 1, -1 do
            local bullet = bullets[i]
            if bullet.owner == "player" then
                for j = #enemies, 1, -1 do
                    local enemy = enemies[j]
                    if util.checkCollision(bullet.x, bullet.y, bullet.radius, enemy.x, enemy.y, enemy.radius) then
                        local damage = bullet.damage or (1 * player.damageMultiplier)
                        enemy:takeDamage(damage)
                        totalDamageDealt = totalDamageDealt + damage
                        bulletsHit = bulletsHit + 1
                        
                        -- AI Director tracking
                        aiDirector:recordHit()
                        aiDirector:recordDamageDealt(damage)
                        
                        -- Impact effects
                        sound:playSound("hit")
                        local hitAngle = util.angle(bullet.x, bullet.y, enemy.x, enemy.y)
                        particleManager:impact(enemy.x, enemy.y, hitAngle, 1)
                        effects:addDamageNumber(enemy.x, enemy.y, math.floor(damage))
                        
                        if not player.piercingBullets then
                            bullet.dead = true
                        end
                        
                        if enemy.dead then
                            sound:playSound("explosion")
                            aiDirector:recordKill(enemy)
                            onEnemyKilled(enemy)
                        end

                        if bullet.explosion and not bullet.explosionTriggered then
                            bullet.explosionTriggered = true
                            local radius = bullet.explosionRadius or 40
                            particleManager:explosion(bullet.x, bullet.y, (radius / 40) * (player.explosionSizeMultiplier or 1), "fire")
                            for _, nearby in ipairs(enemies) do
                                if nearby ~= enemy and not nearby.dead and util.distance(bullet.x, bullet.y, nearby.x, nearby.y) <= radius then
                                    nearby:takeDamage((bullet.damage or 1) * 0.5)
                                    if nearby.dead then
                                        aiDirector:recordKill(nearby)
                                        onEnemyKilled(nearby)
                                    end
                                end
                            end
                        end
                        
                        camera:shake(5, 0.1, 0.5)
                        
                        if not player.piercingBullets then
                            break
                        end
                    end
                end
            end
        end
        
        -- Enemy bullet-player/drone collisions
        for i = #bullets, 1, -1 do
            local bullet = bullets[i]
            if bullet.owner == "enemy" then
                -- Check collision with Player
                if util.checkCollision(bullet.x, bullet.y, bullet.radius, player.x, player.y, player.radius) then
                    local damage = bullet.damage or 1
                    if player:takeDamage(damage) then
                        aiDirector:recordDamage(damage)  -- Track damage for AI director
                        sound:playSound("playerHit")
                        camera:shake(15, 0.3, 2)
                        effects:flash(1, 0, 0, 0.3)
                        shaders:addDistortion(0.02)
                        combo = 0
                        comboTimer = 0
                    end
                    bullet.dead = true
                    
                    if player.health <= 0 then
                        sound:playSound("death")
                        gameState = "gameover"
                        Ads.onGameOver(score)
                        
                        -- Save score to profile and leaderboard
                        if Profile.hasProfile() then
                            Profile.updateStats(score)
                            Profile.incrementGamesPlayed()
                            Leaderboard.addScore(Profile.getProfileName(), score)
                        end
                        
                        if score >= highScore then
                            highScore = score
                        end
                        particleManager:explosion(player.x, player.y, 2, "fire")
                    end
                end
                
                -- Check collision with Drones (if bullet is still active)
                if not bullet.dead then
                    for k, drone in ipairs(drones) do
                        if not drone.dead and (drone.type == "pet1" or drone.type == "pet2" or drone.type == "pet3") then
                            if util.checkCollision(bullet.x, bullet.y, bullet.radius, drone.x, drone.y, drone.radius) then
                                if drone:takeDamage(1) then
                                    sound:playSound("hit")
                                    particleManager:impact(drone.x, drone.y, 0, 0.5)
                                    effects:addDamageNumber(drone.x, drone.y, 1, 1, 0.5, 0.5)
                                    
                                    if drone.dead then
                                        particleManager:explosion(drone.x, drone.y, 0.5, "default")
                                        sound:playSound("explosion")
                                    end
                                end
                                bullet.dead = true
                                break -- Bullet hits one drone and disappears
                            end
                        end
                    end
                end
            end
        end
        
        -- Player/Drone-enemy collisions
        for i, enemy in ipairs(enemies) do
            -- Check collision with Player
            if util.checkCollision(player.x, player.y, player.radius, enemy.x, enemy.y, enemy.radius) then
                if enemy:canDamagePlayer() then
                    if player:takeDamage() then
                        aiDirector:recordDamage(1)  -- Track damage for AI director
                        sound:playSound("playerHit")
                        camera:shake(15, 0.3, 2)
                        effects:flash(1, 0, 0, 0.3)
                        shaders:addDistortion(0.02)
                        combo = 0
                        comboTimer = 0
                        
                        -- Kamikaze explodes on contact
                        if enemy.type == "bomber" then
                            explodeKamikaze(enemy)
                            enemy.dead = true
                        end
                    end
                    
                    if player.health <= 0 then
                        sound:playSound("death")
                        gameState = "gameover"
                        Ads.onGameOver(score)
                        
                        -- Save score to profile and leaderboard
                        if Profile.hasProfile() then
                            Profile.updateStats(score)
                            Profile.incrementGamesPlayed()
                            Leaderboard.addScore(Profile.getProfileName(), score)
                        end
                        
                        if score >= highScore then
                            highScore = score
                        end
                        particleManager:explosion(player.x, player.y, 2, "fire")
                    end
                end
            end
            
            -- Check collision with Drones
            if not enemy.dead then
                for k, drone in ipairs(drones) do
                    if not drone.dead and (drone.type == "pet1" or drone.type == "pet2" or drone.type == "pet3") then
                        if util.checkCollision(enemy.x, enemy.y, enemy.radius, drone.x, drone.y, drone.radius) then
                            -- Enemy hits drone
                            if drone:takeDamage(1) then
                                sound:playSound("hit")
                                particleManager:impact(drone.x, drone.y, 0, 0.5)
                                effects:addDamageNumber(drone.x, drone.y, 1, 1, 0.5, 0.5)
                                
                                if drone.dead then
                                    particleManager:explosion(drone.x, drone.y, 0.5, "default")
                                    sound:playSound("explosion")
                                end
                                
                                -- Kamikaze explodes on contact with drone too
                                if enemy.type == "bomber" then
                                    explodeKamikaze(enemy)
                                    enemy.dead = true
                                end
                            end
                        end
                    end
                end
            end
        end
        
        -- Magnetic pickup collection
        if player.magneticRange > 0 then
            for i, powerup in ipairs(powerups) do
                local dist = util.distance(player.x, player.y, powerup.x, powerup.y)
                if dist < player.magneticRange then
                    local angle = util.angle(powerup.x, powerup.y, player.x, player.y)
                    powerup.x = powerup.x + math.cos(angle) * 150 * dt
                    powerup.y = powerup.y + math.sin(angle) * 150 * dt
                end
            end
            
            for i, ammo in ipairs(ammoPickups) do
                local dist = util.distance(player.x, player.y, ammo.x, ammo.y)
                if dist < player.magneticRange then
                    local angle = util.angle(ammo.x, ammo.y, player.x, player.y)
                    ammo.x = ammo.x + math.cos(angle) * 150 * dt
                    ammo.y = ammo.y + math.sin(angle) * 150 * dt
                end
            end
        end
        
        -- Player-powerup collisions
        for i = #powerups, 1, -1 do
            local powerup = powerups[i]
            if util.checkCollision(player.x, player.y, player.radius, powerup.x, powerup.y, powerup.radius) then
                sound:playSound("powerup")
                player:applyPowerUp(powerup.type)
                local color = PowerUp.types[powerup.type].color
                particleManager:healEffect(powerup.x, powerup.y, powerup.radius)
                effects:flash(color[1], color[2], color[3], 0.2)
                table.remove(powerups, i)
                if tutorialStep == 4 then completeTutorialStep() end
            end
        end
        
        -- Player-ammo collisions
        for i = #ammoPickups, 1, -1 do
            local ammo = ammoPickups[i]
            if util.checkCollision(player.x, player.y, player.radius, ammo.x, ammo.y, ammo.radius) then
                sound:playSound("powerup")
                Weapons.addAmmo(playerWeapons, ammo.type, ammo:getAmount())
                particleManager:energyField(ammo.x, ammo.y, ammo.radius, ammo.colors[ammo.type])
                table.remove(ammoPickups, i)
            end
        end
        
        -- Particle trails for bullets
        for i, bullet in ipairs(bullets) do
            if bullet.owner == "player" and math.random() < 0.3 then
                particleManager:trail(bullet.x, bullet.y, bullet.vx, bullet.vy, {1, 1, 0})
            end
        end
        
        -- Energy field around powerups
        for i, powerup in ipairs(powerups) do
            if math.random() < 0.1 then
                local color = PowerUp.types[powerup.type].color
                particleManager:energyField(powerup.x, powerup.y, powerup.radius + 10, color)
            end
        end
        
        -- Update combo timer
        if combo > 0 then
            comboTimer = comboTimer + dt
            if comboTimer >= comboTimeout then
                combo = 0
                comboTimer = 0
            end
        end
    end
end


local function completeTutorialStep()
    local profile = Profile.getProfile()
    if not profile or profile.tutorialCompleted then return end
    tutorialStep = tutorialStep + 1
    if tutorialStep > 4 then
        Profile.setTutorialCompleted(true)
        tutorialPrompt = nil
        tutorialStep = 0
    end
end

local function drawTutorial()
    local profile = Profile.getProfile()
    if not profile or profile.tutorialCompleted or gameState ~= "playing" then return end
    local w,h = love.graphics.getWidth(), love.graphics.getHeight()
    local text = tutorialPrompt
    if not text then
        if tutorialStep == 1 then text = controlType == "mobile" and "MOVE WITH THE LEFT STICK" or "WASD TO MOVE"
        elseif tutorialStep == 2 then text = controlType == "mobile" and "AIM TO SHOOT" or "CLICK TO SHOOT"
        elseif tutorialStep == 3 then text = controlType == "mobile" and "USE THE DASH BUTTON" or "SPACE TO DASH"
        end
    end
    if text then
        local alpha = 0.75 + 0.25 * math.sin(menuTime * 4)
        love.graphics.setColor(0.03,0.05,0.10,0.75*alpha)
        love.graphics.rectangle("fill", w/2-190, h-115, 380, 44, 10, 10)
        love.graphics.setFont(fonts[18]); love.graphics.setColor(0.75,0.95,1,alpha)
        love.graphics.printf(text, w/2-180, h-104, 360, "center")
    end
end

function love.draw()
    love.graphics.clear(0, 0, 0)  -- Pure black for deep space
    
    if gameState == "controlselect" then
        drawControlSelectScreen()
    elseif gameState == "menu" then
        drawHomeScreen()
    elseif gameState == "modeselect" then
        drawModeSelectScreen()
    elseif gameState == "credits" then
        drawCreditsScreen()
    elseif gameState == "settings" then
        drawSettingsScreen()
    elseif gameState == "playing" or gameState == "paused" then
        -- Direct rendering without shaders (to prevent gray screen)
        camera:apply()
        background:draw()
        
        -- Draw particles
        particleManager:draw()
        
        -- Draw power-ups
        for i, powerup in ipairs(powerups) do
            powerup:draw()
        end
        
        -- Draw drones
        for i, drone in ipairs(drones) do
            drone:draw()
        end
        
        -- Draw ammo pickups
        for i, ammo in ipairs(ammoPickups) do
            ammo:draw()
        end
        
        player:draw(images.ship)
        
        for i, bullet in ipairs(bullets) do
            bullet:draw()
        end
        
        for i, enemy in ipairs(enemies) do
            enemy:draw(player.x, player.y)
        end
        
        camera:unapply()
        
        -- Draw effects layer (damage numbers, screen flashes)
        effects:draw()
        
        -- Modern UI
        local weaponData = Weapons.types[currentWeapon]
        local ammoCount = playerWeapons[currentWeapon].ammo
        local maxAmmo = weaponData.maxAmmo
        ui:drawHUD(player, score, wave, ammoCount, maxAmmo)
        ui:drawCombo(combo, comboTimer, comboTimeout)
        ui:drawAbilityCooldowns(player)
        
        -- Draw mobile controls if mobile selected
        if controlType == "mobile" and touchControls then
            touchControls:draw()
        end

        -- Draw Pause Button (Bottom Left)
        drawButton(menuButtons.pauseBtn)
        
        drawTutorial()

        -- Wave notification
        if not inWave then
            love.graphics.setColor(0, 1, 1) -- Changed from Green to Cyan
            local waveText = string.format("Wave %d Complete! Next in %.1fs", wave - 1, waveDelay - waveTimer)
            if wave == 1 then
                waveText = "Get Ready!"
            end
            love.graphics.printf(waveText, 0, 250, love.graphics.getWidth(), "center")
        end
        
    elseif gameState == "levelup" then
        camera:apply()
        background:draw()
        camera:unapply()
        
        local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
        
        love.graphics.setFont(getFont(48))
        love.graphics.setColor(1, 1, 0)
        love.graphics.printf("LEVEL UP!", 0, 100, sw, "center")
        
        love.graphics.setFont(getFont(24))
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Choose an Upgrade:", 0, 160, sw, "center")
        
        -- Draw upgrade choices (centered)
        local boxWidth = 250
        local boxHeight = 140
        local spacing = 20
        local totalWidth = (boxWidth * 3) + (spacing * 2)
        local startX = (sw - totalWidth) / 2
        local startY = 230
        
        for i, upgrade in ipairs(upgradeChoices) do
            local x = startX + (i - 1) * (boxWidth + spacing)
            local y = startY
            
            -- Check mouse hover
            local mouseX, mouseY = love.mouse.getPosition()
            local isHovered = mouseX >= x and mouseX <= x + boxWidth and mouseY >= y and mouseY <= y + boxHeight
            
            -- Box background
            if isHovered then
                love.graphics.setColor(0.4, 0.4, 0.6, 0.9)
            else
                love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
            end
            love.graphics.rectangle("fill", x, y, boxWidth, boxHeight, 8, 8)
            
            -- Glow effect on hover
            if isHovered then
                love.graphics.setColor(0.5, 0.8, 1.0, 0.3)
                love.graphics.rectangle("fill", x - 2, y - 2, boxWidth + 4, boxHeight + 4, 8, 8)
            end
            
            -- Draw upgrade name (WHITE TEXT!)
            love.graphics.setFont(getFont(18))
            love.graphics.setColor(1, 1, 1)  -- White color for text
            love.graphics.printf(upgrade.name, x + 10, y + 20, boxWidth - 20, "center")
            
            -- Draw upgrade description (LIGHT GRAY TEXT!)
            love.graphics.setFont(getFont(14))
            love.graphics.setColor(0.9, 0.9, 0.9)  -- Light gray for description
            love.graphics.printf(upgrade.description, x + 10, y + 60, boxWidth - 20, "center")
        end
        
        yOffset = yOffset + 80
    love.graphics.setFont(fonts[24]); love.graphics.setColor(1,1,1)
    love.graphics.print("Quality:", panelX + 30, yOffset)
    love.graphics.setFont(fonts[20]); love.graphics.setColor(0.5,0.9,1)
    love.graphics.printf(string.upper(quality), toggleX, yOffset + 7, 80, "center")

    -- Hint text
        love.graphics.setFont(getFont(16))
        love.graphics.setColor(0.7, 0.7, 0.8)
        love.graphics.printf("Click to select", 0, sh - 60, sw, "center")
        
    elseif gameState == "gameover" then
        drawGameOverScreen()
    elseif gameState == "settings" then
        drawSettingsScreen()
    elseif gameState == "profile" then
        drawProfileScreen()
    elseif gameState == "leaderboard" then
        drawLeaderboardScreen()
    elseif gameState == "shop" then
        drawShopScreen()
    end
    
    -- Draw pause overlay if paused
    if gameState == "paused" then
        drawPauseScreen()
    end
end
function drawHomeScreen()
    camera:apply()
    background:draw()
    camera:unapply()
    
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Neon glow title effect
    local titleY = 80 + math.sin(menuTime) * 5
    local pulse = math.sin(menuTime * 2) * 0.3 + 0.7
    
    -- Neon glow layers for "STARFALL VENGEANCE"
    love.graphics.setFont(getFont(56))
    
    -- Outer glow layers (cyan neon)
    love.graphics.setColor(0.2, 0.8, 1.0, 0.15 * pulse)
    love.graphics.printf("STARFALL VENGEANCE", 0, titleY - 3, sw, "center")
    love.graphics.printf("STARFALL VENGEANCE", 0, titleY + 3, sw, "center")
    love.graphics.printf("STARFALL VENGEANCE", -3, titleY, sw, "center")
    love.graphics.printf("STARFALL VENGEANCE", 3, titleY, sw, "center")
    
    love.graphics.setColor(0.2, 0.8, 1.0, 0.3 * pulse)
    love.graphics.printf("STARFALL VENGEANCE", 0, titleY - 2, sw, "center")
    love.graphics.printf("STARFALL VENGEANCE", 0, titleY + 2, sw, "center")
    love.graphics.printf("STARFALL VENGEANCE", -2, titleY, sw, "center")
    love.graphics.printf("STARFALL VENGEANCE", 2, titleY, sw, "center")
    
    love.graphics.setColor(0.3, 0.9, 1.0, 0.5 * pulse)
    love.graphics.printf("STARFALL VENGEANCE", 0, titleY - 1, sw, "center")
    love.graphics.printf("STARFALL VENGEANCE", 0, titleY + 1, sw, "center")
    love.graphics.printf("STARFALL VENGEANCE", -1, titleY, sw, "center")
    love.graphics.printf("STARFALL VENGEANCE", 1, titleY, sw, "center")
    
    -- Bright core (main title)
    love.graphics.setColor(0.8, 1.0, 1.0)
    love.graphics.printf("STARFALL VENGEANCE", 0, titleY, sw, "center")
    
    -- Subtitle with neon glow effect
    love.graphics.setFont(getFont(20))
    
    -- Outer glow layers (orange neon)
    love.graphics.setColor(1.0, 0.4, 0.1, 0.2 * pulse)
    love.graphics.printf("Starfall Vengeance", 0, titleY + 61, sw, "center")
    love.graphics.printf("Starfall Vengeance", 0, titleY + 65, sw, "center")
    love.graphics.printf("Starfall Vengeance", -2, titleY + 63, sw, "center")
    love.graphics.printf("Starfall Vengeance", 2, titleY + 63, sw, "center")
    
    love.graphics.setColor(1.0, 0.5, 0.2, 0.4 * pulse)
    love.graphics.printf("Starfall Vengeance", 0, titleY + 62, sw, "center")
    love.graphics.printf("Starfall Vengeance", 0, titleY + 64, sw, "center")
    love.graphics.printf("Starfall Vengeance", -1, titleY + 63, sw, "center")
    love.graphics.printf("Starfall Vengeance", 1, titleY + 63, sw, "center")
    
    -- Bright core
    love.graphics.setColor(1.0, 0.8, 0.5)
    love.graphics.printf("Starfall Vengeance", 0, titleY + 63, sw, "center")
    
    -- Draw buttons
    drawButton(menuButtons.play)
    drawButton(menuButtons.credits)
    drawButton(menuButtons.settings)
    drawButton(menuButtons.shop)
    
    -- Profile circle icon (top left)
    local profileBtn = menuButtons.profileIcon
    if Profile.hasProfile() then
        -- Draw circle with first letter of profile name
        love.graphics.setColor(0.2, 0.6, 1.0, 0.9)
        love.graphics.circle("fill", profileBtn.x + 30, profileBtn.y + 30, 30)
        
        if profileBtn.hovered then
            love.graphics.setColor(0.4, 0.8, 1.0, 0.5)
            love.graphics.circle("fill", profileBtn.x + 30, profileBtn.y + 30, 33)
        end
        
        -- Border
        love.graphics.setColor(0.5, 0.9, 1.0)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", profileBtn.x + 30, profileBtn.y + 30, 30)
        
        -- First letter
        love.graphics.setFont(getFont(28))
        love.graphics.setColor(1, 1, 1)
        local profileName = Profile.getProfileName()
        local firstLetter = profileName:sub(1, 1):upper()
        love.graphics.printf(firstLetter, profileBtn.x, profileBtn.y + 16, profileBtn.width, "center")
        
        -- Profile name below circle
        love.graphics.setFont(getFont(14))
        love.graphics.setColor(0.8, 0.8, 0.9)
        love.graphics.printf(profileName, profileBtn.x - 20, profileBtn.y + 65, profileBtn.width + 40, "center")
    else
        -- Draw "+" icon to create profile
        love.graphics.setColor(0.5, 0.5, 0.6, 0.7)
        love.graphics.circle("fill", profileBtn.x + 30, profileBtn.y + 30, 30)
        
        if profileBtn.hovered then
            love.graphics.setColor(0.6, 0.6, 0.7, 0.9)
            love.graphics.circle("fill", profileBtn.x + 30, profileBtn.y + 30, 30)
        end
        
        -- Border
        love.graphics.setColor(0.7, 0.7, 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", profileBtn.x + 30, profileBtn.y + 30, 30)
        
        -- "+" symbol
        love.graphics.setFont(getFont(36))
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("+", profileBtn.x, profileBtn.y + 10, profileBtn.width, "center")
        
        -- Text below
        love.graphics.setFont(getFont(12))
        love.graphics.setColor(0.7, 0.7, 0.8)
        love.graphics.printf("Create Profile", profileBtn.x - 10, profileBtn.y + 65, profileBtn.width + 20, "center")
    end
    
    -- Leaderboard button (top right)
    drawButton(menuButtons.leaderboardBtn)
    
    -- High score
    if highScore > 0 then
        love.graphics.setFont(getFont(20))
        love.graphics.setColor(1, 1, 0.5)
        love.graphics.printf("High Score: " .. highScore, 0, sh - 50, sw, "center")
    end
    
    -- Version/hint text
    love.graphics.setFont(getFont(14))
    love.graphics.setColor(0.5, 0.5, 0.6)
    love.graphics.printf("Controls: WASD to move, Mouse to aim, Space to dash", 0, sh - 25, sw, "center")
end

-- Draw mode selection screen
function drawModeSelectScreen()
    camera:apply(); background:draw(); camera:unapply()
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.setFont(fonts[48]); love.graphics.setColor(0.8, 1, 1); love.graphics.printf("SELECT MODE", 0, 90, sw, "center")
    drawButton(menuButtons.modeClassic)
    drawButton(menuButtons.modeEndless)
    love.graphics.setFont(fonts[14]); love.graphics.setColor(0.7,0.7,0.8)
    love.graphics.printf("Classic: 30 waves • Endless: unlimited", 0, sh-60, sw, "center")
    drawButton(menuButtons.back)
end

-- Draw control selection screen
function drawControlSelectScreen()
    camera:apply(); background:draw(); camera:unapply()
    local sw = love.graphics.getWidth()
    love.graphics.setFont(fonts[40]); love.graphics.setColor(0.6,0.9,1); love.graphics.printf("CONTROLS",0,120,sw,"center")
    love.graphics.setFont(fonts[18]); love.graphics.setColor(0.8,0.8,0.9)
    if controlType == "mobile" then
        love.graphics.printf("Touch controls enabled automatically",0,210,sw,"center")
    else
        love.graphics.printf("WASD / Arrow Keys • Mouse Aim • Space Dash",0,210,sw,"center")
    end
    drawButton(menuButtons.back)
end

-- Draw credits screen
function drawCreditsScreen()
    camera:apply()
    background:draw()
    camera:unapply()
    
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    local fadeIn = math.min(1, menuTime * 2)
    local pulse = math.sin(menuTime * 2) * 0.3 + 0.7
    
    -- Title with glow effect (fixed at top)
    love.graphics.setFont(getFont(40))
    love.graphics.setColor(0.5, 0.8, 1.0, 0.2 * pulse * fadeIn)
    love.graphics.printf("CREDITS", 0, 28, sw, "center")
    love.graphics.printf("CREDITS", 0, 32, sw, "center")
    love.graphics.setColor(0.5, 0.8, 1.0, fadeIn)
    love.graphics.printf("CREDITS", 0, 30, sw, "center")
    
    -- Calculate total content height for vertical centering (content only, not title)
    local developerSection = 24 + 22 + 30  -- header + name + spacing
    local gameDesignSection = 24 + 13 + 22  -- header + detail + spacing
    local coreFeaturesSection = 24 + (32 * 4)  -- header + 4 features
    local technicalSection = 24 + (32 * 3)  -- header + 3 features
    local thanksSection = 24 + 13 + 22  -- header + detail + spacing
    local closingSection = 18 + 25  -- closing message
    local totalContentHeight = developerSection + gameDesignSection + coreFeaturesSection + 
                               technicalSection + thanksSection + closingSection
    
    -- Center content vertically (below the title)
    local titleBottomY = 80  -- Space after title
    local availableHeight = sh - titleBottomY - 50  -- 50px reserved for version at bottom
    local startY = titleBottomY + (availableHeight - totalContentHeight) / 2
    
    -- Credits content - compact version
    local yPos = startY
    local credits = {
        -- Developer Section
        {"DEVELOPER", "", "header"},
        {"", "FARHAN AHMAD", "name"},
        
        -- Game Design
        {"GAME DESIGN & DEVELOPMENT", "", "header"},
        {"", "Arcade survival • Wave-Based Combat", "detail"},
        
        -- Features
        {"CORE FEATURES", "", "header"},
        {"AI Director", "Dynamic Difficulty Adjustment", "feature"},
        {"Combat", "4 Weapons • Elite Enemies • Drones", "feature"},
        {"Progression", "XP • Upgrades • Power-ups", "feature"},
        {"Controls", "PC & Mobile Support", "feature"},
        
        -- Technical
        {"TECHNICAL", "", "header"},
        {"Visuals", "Particles • Shaders • Effects", "feature"},
        {"AI", "5 Enemy Types", "feature"},
        {"Audio", "Dynamic Sound System", "feature"},
        
        -- Special Thanks
        {"SPECIAL THANKS", "", "header"},
        {"", "LÖVE2D Community & Framework", "detail"},
        
        -- Closing
        {"", "★ THANK YOU FOR PLAYING! ★", "closing"}
    }
    
    for i, credit in ipairs(credits) do
        local alpha = math.min(1, (menuTime - i * 0.05) * 3) * fadeIn
        
        if credit[3] == "header" then
            -- Section headers
            love.graphics.setFont(getFont(16))
            love.graphics.setColor(1, 0.8, 0.3, alpha)
            love.graphics.printf(credit[1], 0, yPos, sw, "center")
            yPos = yPos + 24
            
        elseif credit[3] == "name" then
            -- Developer name with NEON GLOW effect
            love.graphics.setFont(getFont(26))
            
            -- Outer glow layers (cyan neon)
            love.graphics.setColor(0.2, 0.8, 1.0, 0.15 * pulse * alpha)
            love.graphics.printf(credit[2], 0, yPos - 3, sw, "center")
            love.graphics.printf(credit[2], 0, yPos + 3, sw, "center")
            love.graphics.printf(credit[2], -3, yPos, sw, "center")
            love.graphics.printf(credit[2], 3, yPos, sw, "center")
            
            love.graphics.setColor(0.2, 0.9, 1.0, 0.3 * pulse * alpha)
            love.graphics.printf(credit[2], 0, yPos - 2, sw, "center")
            love.graphics.printf(credit[2], 0, yPos + 2, sw, "center")
            love.graphics.printf(credit[2], -2, yPos, sw, "center")
            love.graphics.printf(credit[2], 2, yPos, sw, "center")
            
            love.graphics.setColor(0.3, 0.95, 1.0, 0.5 * pulse * alpha)
            love.graphics.printf(credit[2], 0, yPos - 1, sw, "center")
            love.graphics.printf(credit[2], 0, yPos + 1, sw, "center")
            love.graphics.printf(credit[2], -1, yPos, sw, "center")
            love.graphics.printf(credit[2], 1, yPos, sw, "center")
            
            -- Bright core (main text)
            love.graphics.setColor(0.8, 1.0, 1.0, alpha)
            love.graphics.printf(credit[2], 0, yPos, sw, "center")
            yPos = yPos + 35
            
        elseif credit[3] == "feature" then
            -- Feature entries (compact)
            love.graphics.setFont(getFont(13))
            love.graphics.setColor(0.5, 0.8, 1.0, alpha)
            love.graphics.printf(credit[1], 0, yPos, sw, "center")
            
            love.graphics.setFont(getFont(11))
            love.graphics.setColor(0.7, 0.7, 0.8, alpha * 0.8)
            love.graphics.printf(credit[2], 0, yPos + 15, sw, "center")
            yPos = yPos + 32
            
        elseif credit[3] == "detail" then
            -- Detail text
            love.graphics.setFont(getFont(13))
            love.graphics.setColor(0.8, 0.8, 0.9, alpha)
            love.graphics.printf(credit[2], 0, yPos, sw, "center")
            yPos = yPos + 22
            
        elseif credit[3] == "closing" then
            -- Closing message
            love.graphics.setFont(getFont(18))
            love.graphics.setColor(1, 1, 0.5, alpha * pulse)
            love.graphics.printf(credit[2], 0, yPos, sw, "center")
            yPos = yPos + 25
        end
    end
    
    -- Back button
    drawButton(menuButtons.back)
    
    -- Version info
    love.graphics.setFont(getFont(10))
    love.graphics.setColor(0.5, 0.5, 0.6, fadeIn)
    love.graphics.printf("Starfall Vengeance v1.0", 0, sh - 50, sw, "center")
end

-- Draw settings screen
function drawSettingsScreen()
    camera:apply()
    background:draw()
    camera:unapply()
    
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Title
    love.graphics.setFont(getFont(48))
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("SETTINGS", 0, 80, sw, "center")
    
    -- Settings panel
    local panelW = 500
    local panelH = 350
    local panelX = (sw - panelW) / 2
    local panelY = 180
    
    -- Panel background
    love.graphics.setColor(0.1, 0.1, 0.15, 0.9)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 10, 10)
    
    local yOffset = panelY + 40
    local settings = sound:getSettings()
    
    -- Sound Effects Toggle
    love.graphics.setFont(getFont(24))
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Sound Effects:", panelX + 30, yOffset)
    
    local toggleX = panelX + panelW - 120
    if settings.soundEnabled then
        love.graphics.setColor(0.3, 0.8, 0.3)
        love.graphics.rectangle("fill", toggleX, yOffset, 80, 35, 5, 5)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(getFont(20))
        love.graphics.printf("ON", toggleX, yOffset + 7, 80, "center")
    else
        love.graphics.setColor(0.8, 0.3, 0.3)
        love.graphics.rectangle("fill", toggleX, yOffset, 80, 35, 5, 5)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(getFont(20))
        love.graphics.printf("OFF", toggleX, yOffset + 7, 80, "center")
    end
    
    yOffset = yOffset + 80
    
    -- Background Music Toggle
    love.graphics.setFont(getFont(24))
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Background Music:", panelX + 30, yOffset)
    
    if settings.musicEnabled then
        love.graphics.setColor(0.3, 0.8, 0.3)
        love.graphics.rectangle("fill", toggleX, yOffset, 80, 35, 5, 5)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(getFont(20))
        love.graphics.printf("ON", toggleX, yOffset + 7, 80, "center")
    else
        love.graphics.setColor(0.8, 0.3, 0.3)
        love.graphics.rectangle("fill", toggleX, yOffset, 80, 35, 5, 5)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(getFont(20))
        love.graphics.printf("OFF", toggleX, yOffset + 7, 80, "center")
    end
    
    yOffset = yOffset + 100
    
    -- Hint text
    love.graphics.setFont(getFont(16))
    love.graphics.setColor(0.7, 0.7, 0.8)
    love.graphics.printf("Click the toggles to change settings", panelX, yOffset, panelW, "center")
    
    -- Back button
    drawButton(menuButtons.back)
end

-- Draw pause screen overlay
function drawPauseScreen()
    -- Dim background (reduced from 0.7 to prevent gray screen)
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Pause title
    love.graphics.setFont(getFont(64))
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("PAUSED", 0, sh/2 - 100, sw, "center")
    
    -- Draw pause buttons
    drawButton(menuButtons.pauseResume)
    drawButton(menuButtons.pauseSettings)
    drawButton(menuButtons.pauseHome)
    
    -- Hint
    love.graphics.setFont(getFont(16))
    love.graphics.setColor(0.7, 0.7, 0.8)
    love.graphics.printf("Press ESC to resume", 0, sh - 40, sw, "center")
end

-- Draw game over screen
function drawGameOverScreen()
    camera:apply()
    background:draw()
    camera:unapply()
    
    -- Dim overlay
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    local pulse = math.sin(menuTime * 2) * 0.3 + 0.7
    
    -- GAME OVER title with glow effect
    love.graphics.setFont(getFont(72))
    love.graphics.setColor(1, 0.2, 0.2, 0.3 * pulse)
    love.graphics.printf("GAME OVER", 0, sh/2 - 152, sw, "center")
    love.graphics.printf("GAME OVER", 0, sh/2 - 148, sw, "center")
    
    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.printf(classicVictory and "VICTORY!" or "GAME OVER", 0, sh/2 - 150, sw, "center")
    
    -- Stats panel
    local panelW = 400
    local panelH = 180
    local panelX = (sw - panelW) / 2
    local panelY = sh/2 - 60
    
    -- Panel background
    love.graphics.setColor(0.1, 0.1, 0.15, 0.9)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 10, 10)
    
    -- Stats
    local yOffset = panelY + 20
    
    love.graphics.setFont(getFont(28))
    love.graphics.setColor(1, 1, 0.5)
    love.graphics.printf("SCORE: " .. score, panelX, yOffset, panelW, "center")
    
    yOffset = yOffset + 40
    
    -- High score indicator
    if score >= highScore then
        love.graphics.setFont(getFont(24))
        love.graphics.setColor(1, 1, 0)
        love.graphics.printf("★ NEW HIGH SCORE! ★", panelX, yOffset, panelW, "center")
        yOffset = yOffset + 35
    end
    
    -- Additional stats
    love.graphics.setFont(getFont(18))
    love.graphics.setColor(0.8, 0.8, 0.9)
    love.graphics.printf("Wave " .. wave .. " • " .. totalKills .. " Kills", panelX, yOffset, panelW, "center")
    local currentProfile = Profile.getProfile()
    local earnedStars = currentProfile and currentProfile.stars or 0
    
    yOffset = yOffset + 30
    
    local accuracy = bulletsFired > 0 and math.floor((bulletsHit / bulletsFired) * 100) or 0
    love.graphics.setColor(0.7, 0.7, 0.8)
    love.graphics.printf("Accuracy: " .. accuracy .. "%", panelX, yOffset, panelW, "center")
    
    -- Draw buttons
    drawButton(menuButtons.gameoverRestart)
    drawButton(menuButtons.gameoverHome)
    
    -- Hint
    love.graphics.setFont(getFont(14))
    love.graphics.setColor(0.6, 0.6, 0.7)
    love.graphics.printf("Choose an option to continue", 0, sh - 40, sw, "center")
end

-- Helper function to draw a button
function drawButton(btn)
    local pulse = btn.hovered and (math.sin(menuTime * 8) * 0.1 + 1.1) or 1
    
    -- Button shadow
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", btn.x + 4, btn.y + 4, btn.width, btn.height, 8, 8)
    
    -- Button background
    if btn.hovered then
        love.graphics.setColor(0.3, 0.7, 1.0, 0.9)
    else
        love.graphics.setColor(0.2, 0.4, 0.8, 0.7)
    end
    love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height, 8, 8)
    
    -- Button border (Removed)
    -- love.graphics.setColor(0.5, 0.8, 1.0)
    -- love.graphics.setLineWidth(2)
    -- love.graphics.rectangle("line", btn.x, btn.y, btn.width, btn.height, 8, 8)
    -- love.graphics.setLineWidth(1)
    
    -- Button text - use smaller font for longer text
    local fontSize = #btn.text > 10 and 18 or 24
    love.graphics.setFont(getFont(fontSize))
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(btn.text, btn.x, btn.y + (btn.height - fontSize) / 2, btn.width, "center")
end

function startWave()
    inWave = true
    waveTimer = 0
    enemiesKilledThisWave = 0
    
    -- ENDLESS MODE: Progressive difficulty scaling
    -- More enemies each wave
    enemiesInWave = 5 + (wave - 1) * 4  -- Increased from 3 to 4 per wave
    
    -- Boss spawns more frequently as game progresses
    if wave % 3 == 0 then  -- Boss every 3 waves (was 5)
        spawnBoss()
    end
    
    -- Spawn rate increases continuously (enemies spawn faster)
    enemySpawnDelay = math.max(0.3, 2.0 - wave * 0.08)  -- Faster minimum spawn (0.3s)
    
    -- Unlock weapons based on wave (keep this progression)
    if wave >= 2 and not playerWeapons.shotgun.unlocked then
        Weapons.unlockWeapon(playerWeapons, "shotgun")
        createDamageNumber(love.graphics.getWidth() / 2, 100, "Shotgun Unlocked!", 1, 0.5, 0)
    end
    if wave >= 4 and not playerWeapons.machinegun.unlocked then
        Weapons.unlockWeapon(playerWeapons, "machinegun")
        createDamageNumber(love.graphics.getWidth() / 2, 100, "Machine Gun Unlocked!", 1, 0.5, 0)
    end
    if wave >= 7 and not playerWeapons.sniper.unlocked then
        Weapons.unlockWeapon(playerWeapons, "sniper")
        createDamageNumber(love.graphics.getWidth() / 2, 100, "Sniper Unlocked!", 1, 0.5, 0)
    end
end

function completeWave()
    sound:playSound("waveComplete")
    inWave = false
    waveTimer = 0
    local completedWave = wave
    local bonus = completedWave * 10
    score = score + bonus
    Profile.addStars(completedWave * 10)
    Ads.onWaveComplete(completedWave)

    if gameMode == "classic" and completedWave >= 30 then
        classicVictory = true
        gameState = "gameover"
        Ads.onGameOver(score)
        if Profile.hasProfile() then
            Profile.incrementGamesPlayed()
            Leaderboard.addScore(Profile.getProfileName(), score)
        end
        return
    end

    spawnPowerUp()
    wave = completedWave + 1
    
    -- Deactivate boss mode when wave completes
    background:setBossMode(false)
end

-- Track mouse as touch for mobile controls on desktop
local mouseAsTouchId = "mouse"
local mouseIsDown = false

function love.mousepressed(x, y, button)
    if button == 1 then
        -- Simulate touch event for mobile controls (when in playing state)
        if gameState == "playing" and controlType == "mobile" and touchControls then
            if touchControls:touchpressed(mouseAsTouchId, x, y) then
                mouseIsDown = true
                return  -- Touch control handled it, don't process as game click
            end
        end
        
        if gameState == "menu" then
            if menuButtons.play.hovered then
                sound:playSound("powerup")
                gameState = "modeselect"  -- Go to mode selection first
            elseif menuButtons.credits.hovered then
                sound:playSound("powerup")
                gameState = "credits"
                menuTime = 0
            elseif menuButtons.shop.hovered then
                sound:playSound("powerup")
                gameState = "shop"
                menuTime = 0
            elseif menuButtons.settings.hovered then
                sound:playSound("powerup")
                previousState = "menu"
                gameState = "settings"
                menuTime = 0
            elseif menuButtons.profileIcon.hovered then
                sound:playSound("powerup")
                gameState = "profile"
                profileNameInput = ""
                profileError = nil
                profileInputActive = false
                menuTime = 0
            elseif menuButtons.leaderboardBtn.hovered then
                sound:playSound("powerup")
                gameState = "leaderboard"
                menuTime = 0
            end
        elseif gameState == "modeselect" then
            -- Handle mode selection
            if menuButtons.modeEndless.hovered then
                sound:playSound("powerup")
                gameMode = "endless"
                gameState = "playing"
                resetGame()
                Ads.onGameStart()
            elseif menuButtons.modeClassic.hovered then
                sound:playSound("powerup")
                gameMode = "classic"
                gameState = "playing"
                resetGame()
                Ads.onGameStart()
            elseif menuButtons.back.hovered then
                sound:playSound("powerup")
                gameState = "menu"
            end
        elseif gameState == "credits" or gameState == "settings" or gameState == "shop" then
            if menuButtons.back.hovered then
                sound:playSound("powerup")
                if gameState == "settings" and previousState == "paused" then
                    gameState = "paused" -- Return to pause menu if we came from there
                else
                    gameState = "menu" -- Default to main menu
                end
                menuTime = 0
            elseif gameState == "settings" then
                    -- Handle settings toggle clicks
                    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
                    local panelW = 500
                    local panelX = (sw - panelW) / 2
                    local panelY = 180
                    local toggleX = panelX + panelW - 120
                    
                    -- Sound effects toggle
                    if x >= toggleX and x <= toggleX + 80 and y >= panelY + 40 and y <= panelY + 75 then
                        sound:toggleSound()
                        sound:playSound("powerup")
                    end
                    
                    -- Music toggle
                    if x >= toggleX and x <= toggleX + 80 and y >= panelY + 120 and y <= panelY + 155 then
                        sound:toggleMusic()
                        sound:playSound("powerup")
                    end

                    if x >= toggleX and x <= toggleX + 80 and y >= panelY + 200 and y <= panelY + 235 then
                        quality = quality == "high" and "medium" or (quality == "medium" and "low" or "high")
                        particleManager:setQuality(quality); effects:setQuality(quality); camera:setQuality(quality); ui:setQuality(quality); shaders:setQuality(quality)
                        for _, d in ipairs(drones) do d:setQuality(quality) end
                        sound:playSound("powerup")
                    end
            elseif gameState == "shop" then
                -- Handle shop item clicks
                local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
                local pets = {
                    {id = "pet1", price = 1200},
                    {id = "pet2", price = 3500},
                    {id = "pet3", price = 7500}
                }
                
                local itemW, itemH = 250, 350
                local startX = (sw - (#pets * (itemW + 20))) / 2 + 10
                local startY = 150
                
                for i, pet in ipairs(pets) do
                    local itemX = startX + (i-1) * (itemW + 20)
                    local itemY = startY
                    local buttonY = itemY + itemH - 60
                    
                    -- Check click on button
                    if x >= itemX + 20 and x <= itemX + itemW - 20 and y >= buttonY and y <= buttonY + 40 then
                        local profile = Profile.getProfile()
                        if profile then
                            local unlocked = string.find(profile.unlockedPets, pet.id)
                            local equipped = profile.equippedPet == pet.id
                            
                            if not unlocked then
                                -- Try to buy
                                if Profile.spendStars(pet.price) then
                                    Profile.unlockPet(pet.id)
                                    sound:playSound("powerup")
                                else
                                    sound:playSound("shoot") -- Error sound
                                end
                            elseif not equipped then
                                -- Equip
                                Profile.equipPet(pet.id)
                                sound:playSound("powerup")
                            end
                        end
                    end
                end
            end
        elseif gameState == "paused" then
            if menuButtons.pauseResume.hovered then
                gameState = "playing"
            elseif menuButtons.pauseSettings.hovered then
                sound:playSound("powerup")
                previousState = "paused" -- Remember we came from pause
                gameState = "settings"
            elseif menuButtons.pauseHome.hovered then
                gameState = "menu"
                menuTime = 0
                resetGame() -- Reset game when going home
            end
        elseif gameState == "playing" then
            -- Check for Pause Button click
            if menuButtons.pauseBtn.hovered then
                sound:playSound("powerup")
                gameState = "paused"
                return -- Don't shoot if we clicked pause
            end

            -- Only allow PC shooting when NOT in mobile mode
            if controlType ~= "mobile" then
                -- Shoot bullet
                local weaponData = Weapons.types[currentWeapon]
                local fireRate = weaponData.fireRate * player.fireRateMultiplier
                
                if player.shootCooldown <= 0 and Weapons.hasAmmo(playerWeapons, currentWeapon) then
                    local angle = util.angle(player.x, player.y, x, y)
                    local bulletCount = weaponData.bulletCount + player.extraProjectiles
                    local spread = weaponData.spread
                    
                    local color = player.bulletColor
                    local baseDamage = 10
                    if color == "blue" then baseDamage = 15 end
                    if color == "green" then baseDamage = 25 end
                    
                    for i = 1, bulletCount do
                        local bulletAngle = angle
                        if bulletCount > 1 then
                            local spreadOffset = (i - (bulletCount + 1) / 2) * spread / bulletCount
                            bulletAngle = angle + spreadOffset
                        end
                        
                        local bullet = Bullet.new(player.x, player.y, bulletAngle, "player", color)
                        bullet.damage = baseDamage * player.damageMultiplier
                        bullet.speed = weaponData.bulletSpeed
                        bullet.vx = math.cos(bulletAngle) * bullet.speed
                        bullet.vy = math.sin(bulletAngle) * bullet.speed
                        table.insert(bullets, bullet)
                        bulletsFired = bulletsFired + 1
                        shotSequence = shotSequence + 1
                        if player.hasHomingMissile and shotSequence % 5 == 0 then
                            bullet.homing = true; bullet.homingStrength = 3.5; bullet.speed = bullet.speed * 0.75
                            bullet.explosion = true; bullet.explosionRadius = 40 * (player.explosionSizeMultiplier or 1)
                            bullet.vx = math.cos(bulletAngle) * bullet.speed; bullet.vy = math.sin(bulletAngle) * bullet.speed
                        end
                        aiDirector:recordShot()  -- Track shot for AI director
                    end
                    
                    -- Play shoot sound
                    sound:playSound("shoot")
                    
                    player.shootCooldown = fireRate
                    Weapons.useAmmo(playerWeapons, currentWeapon, 1)
                    
                    -- Muzzle flash particles
                    createMuzzleFlash(player.x, player.y, angle)
                end
            end
        elseif gameState == "levelup" then
            -- Check upgrade selection
            local boxWidth = 250
            local boxHeight = 140
            local spacing = 20
            local totalWidth = (boxWidth * 3) + (spacing * 2)
            local sw = love.graphics.getWidth()
            local startX = (sw - totalWidth) / 2
            local startY = 230
            
            for i, upgrade in ipairs(upgradeChoices) do
                local boxX = startX + (i - 1) * (boxWidth + spacing)
                local boxY = startY
                
                if x >= boxX and x <= boxX + boxWidth and y >= boxY and y <= boxY + boxHeight then
                    sound:playSound("levelup")
                    upgrade.apply(player)
                    syncUpgradeDrones()
                    gameState = "playing"
                    break
                end
            end
        elseif gameState == "gameover" then
            if menuButtons.gameoverRestart.hovered then
                sound:playSound("powerup")
                gameState = "playing"
                resetGame()
            elseif menuButtons.gameoverHome.hovered then
                sound:playSound("powerup")
                gameState = "menu"
                menuTime = 0
            end
        elseif gameState == "profile" then
            if showDeleteConfirmation then
                -- Handle confirmation popup clicks
                local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
                local boxW, boxH = 400, 200
                local boxX, boxY = (sw - boxW)/2, (sh - boxH)/2
                local btnW, btnH = 120, 45
                local btnY = boxY + 130
                local btnYesX = boxX + 50
                local btnNoX = boxX + boxW - 50 - btnW
                
                -- Yes Button
                if x >= btnYesX and x <= btnYesX + btnW and y >= btnY and y <= btnY + btnH then
                    sound:playSound("powerup")
                    -- Delete profile AND remove from leaderboard
                    local profileName = Profile.getProfileName()
                    Profile.deleteProfile()
                    gameState = "menu"
                    menuTime = 0
                    showDeleteConfirmation = false
                end
                
                -- No Button
                if x >= btnNoX and x <= btnNoX + btnW and y >= btnY and y <= btnY + btnH then
                    sound:playSound("powerup")
                    showDeleteConfirmation = false
                end
            elseif Profile.hasProfile() then
                -- Profile exists - handle delete button
                if menuButtons.profileDelete.hovered then
                    sound:playSound("powerup")
                    showDeleteConfirmation = true
                elseif menuButtons.back.hovered then
                    sound:playSound("powerup")
                    gameState = "menu"
                    menuTime = 0
                end
            else
                -- No profile - handle create profile
                if menuButtons.profileSubmit.hovered then
                    -- Submit profile
                    if Leaderboard.hasName(profileNameInput) then
                        profileError = "Name already exists in leaderboard!"
                        sound:playSound("playerHit")
                    else
                        local success, message = Profile.createProfile(profileNameInput)
                        if success then
                            sound:playSound("powerup")
                            gameState = "menu"
                            menuTime = 0
                            profileNameInput = ""
                            profileError = nil
                        else
                            profileError = message
                            sound:playSound("playerHit")
                        end
                    end
                elseif menuButtons.back.hovered then
                    sound:playSound("powerup")
                    gameState = "menu"
                    menuTime = 0
                    profileNameInput = ""
                    profileError = nil
                else
                    -- Check if clicked on input box
                    local sw = love.graphics.getWidth()
                    local sh = love.graphics.getHeight()
                    local inputX = sw/2 - 200
                    local inputY = sh/2 - 60
                    local inputWidth = 400
                    local inputHeight = 50
                    
                    if x >= inputX and x <= inputX + inputWidth and y >= inputY and y <= inputY + inputHeight then
                        profileInputActive = true
                        love.keyboard.setTextInput(true)
                    else
                        profileInputActive = false
                        love.keyboard.setTextInput(false)
                    end
                end
            end
        elseif gameState == "leaderboard" then
            if menuButtons.leaderboardClose.hovered then
                sound:playSound("powerup")
                gameState = "menu"
                menuTime = 0
            end
        end
    end
end

-- Simulate touch moved events for mobile controls on desktop
function love.mousemoved(x, y, dx, dy)
    if mouseIsDown and gameState == "playing" and controlType == "mobile" and touchControls then
        touchControls:touchmoved(mouseAsTouchId, x, y)
    end
end

-- Simulate touch released events for mobile controls on desktop
function love.mousereleased(x, y, button)
    if button == 1 and mouseIsDown then
        if gameState == "playing" and controlType == "mobile" and touchControls then
            touchControls:touchreleased(mouseAsTouchId)
            mouseIsDown = false
        end
    end
end

function love.keypressed(key)
    -- Pause/Unpause with ESC
    if key == "escape" then
        if gameState == "playing" then
            gameState = "paused"
        elseif gameState == "paused" then
            gameState = "playing"
        end
        return
    end
    
    -- Handle text input for profile creation
    if gameState == "profile" and profileInputActive then
        if key == "backspace" then
            profileNameInput = profileNameInput:sub(1, -2)
            profileError = nil
        elseif key == "return" or key == "enter" then
            -- Submit via Enter key
            if not Profile.hasProfile() then
                if Leaderboard.hasName(profileNameInput) then
                    profileError = "Name already exists in leaderboard!"
                    sound:playSound("playerHit")
                else
                    local success, message = Profile.createProfile(profileNameInput)
                    if success then
                        sound:playSound("powerup")
                        gameState = "menu"
                        menuTime = 0
                        profileNameInput = ""
                        profileError = nil
                        profileInputActive = false
                        love.keyboard.setTextInput(false)
                    else
                        profileError = message
                        sound:playSound("playerHit")
                    end
                end
            end
        end
        return
    end
    
    if gameState == "playing" then
        -- Weapon switching
        if key == "1" and playerWeapons.pistol.unlocked then
            currentWeapon = "pistol"
        elseif key == "2" and playerWeapons.shotgun.unlocked then
            currentWeapon = "shotgun"
        elseif key == "3" and playerWeapons.machinegun.unlocked then
            currentWeapon = "machinegun"
        elseif key == "4" and playerWeapons.sniper.unlocked then
            currentWeapon = "sniper"
        end
    end
end

-- Handle text input for profile name
function love.textinput(text)
    if gameState == "profile" and profileInputActive then
        if #profileNameInput < 20 then
            profileNameInput = profileNameInput .. text
            profileError = nil
        end
    end
end

function spawnEnemy()
    local x, y = util.getRandomEdgePosition()
    local enemyType = Enemy.getRandomType(wave)
    local enemyImage = images[enemyType]
    table.insert(enemies, Enemy.new(x, y, enemyType, enemyImage))
end

function spawnBoss()
    local x, y = util.getRandomEdgePosition()
    local boss = Enemy.new(x, y, "miniboss", images.miniboss)  -- Use miniboss image
    
    -- PROGRESSIVE BOSS SCALING
    boss.health = 15 + wave * 7  -- Scales faster (was wave * 5)
    boss.maxHealth = boss.health
    boss.radius = 22 + math.min(wave * 0.5, 10)  -- Gets bigger (max +10)
    boss.score = 200 + wave * 50  -- More points for harder bosses
    boss.speed = 50 + wave * 2  -- Gets faster
    
    table.insert(enemies, boss)
    
    -- Activate dramatic god ray effects for boss fight
    background:setBossMode(true)
end

function spawnPowerUp()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local x = math.random(50, screenWidth - 50)
    local y = math.random(50, screenHeight - 50)
    table.insert(powerups, PowerUp.new(x, y))
    if tutorialStep == 3 then tutorialStep = 4; tutorialPrompt = "COLLECT POWER-UPS!" end
end

function spawnAmmo()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local x = math.random(50, screenWidth - 50)
    local y = math.random(50, screenHeight - 50)
    
    local types = {"shotgun", "machinegun", "sniper"}
    local ammoType = types[math.random(#types)]
    
    table.insert(ammoPickups, Ammo.new(x, y, ammoType))
end

function spawnSpecificPowerUp(powerupType)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local x = math.random(50, screenWidth - 50)
    local y = math.random(50, screenHeight - 50)
    local powerup = PowerUp.new(x, y, powerupType)
    if powerupType then
        powerup.type = powerupType
    end
    table.insert(powerups, powerup)
end

function spawnEliteEnemy()
    local x, y = util.getRandomEdgePosition()
    local enemyType = Enemy.getRandomType(wave)
    local enemyImage = images[enemyType]
    local enemy = Enemy.new(x, y, enemyType, enemyImage)
    
    -- Apply AI difficulty multiplier to make enemies harder
    local difficultyMult = aiDirector:getDifficultyMultiplier()
    enemy.health = enemy.health * difficultyMult
    enemy.maxHealth = enemy.maxHealth * difficultyMult
    enemy.speed = enemy.speed * (1 + (difficultyMult - 1) * 0.5)  -- Speed increases less
    enemy.score = math.floor(enemy.score * difficultyMult * 1.5)  -- More points for harder enemies
    
    table.insert(enemies, enemy)
    
    -- Visual feedback for elite spawn
    effects:addDamageNumber(x, y, "ELITE!", 1, 0.5, 0)
end

function onEnemyKilled(enemy)
    combo = combo + 1
    comboTimer = 0
    
    local points = enemy.score * combo
    score = score + points
    totalKills = totalKills + 1
    enemiesKilledThisWave = enemiesKilledThisWave + 1
    
    -- Add XP
    local xpGained = Enemy.types[enemy.type].xp or 10
    local leveledUp = XP.addXP(playerXP, xpGained)
    
    -- Add Stars (balanced for web play)
    local starsGained = 0
    if enemy.type == "swarmer" then
        starsGained = math.random(5, 8)
    elseif enemy.type == "miniboss" then
        starsGained = math.random(25, 40)
    else
        -- Regular enemies (sniper, bomber, turret, etc)
        starsGained = math.random(12, 18)
    end
    
    -- Update profile stats immediately
    Profile.addStars(starsGained)
    
    -- Visual feedback for stars
    if starsGained > 0 then
        effects:addDamageNumber(enemy.x, enemy.y - 20, "+" .. starsGained .. " Stars", 1, 1, 0.2)
    end
    
    if leveledUp then
        gameState = "levelup"
        upgradeChoices = XP.getRandomUpgrades(3)
    end
    
    -- Bomber explodes on death
    if enemy.type == "bomber" then
        explodeKamikaze(enemy)
    else
        particleManager:explosion(enemy.x, enemy.y, 1, "default")
    end
    
    effects:addDamageNumber(enemy.x, enemy.y, points)
    camera:shake(8, 0.15, 1)
    shaders:addDistortion(0.01)
end

function explodeKamikaze(kamikaze)
    local bomberData = Enemy.types.bomber or {}
    local explodeRadius = bomberData.explodeRadius or 60
    local explodeDamage = bomberData.explodeDamage or 2
    
    -- Create massive explosion with particle manager
    particleManager:explosion(kamikaze.x, kamikaze.y, 2 * (player.explosionSizeMultiplier or 1), "fire")
    shaders:addDistortion(0.03)
    camera:shake(20, 0.5, 3)
    
    -- Damage player if in range
    local distToPlayer = util.distance(kamikaze.x, kamikaze.y, player.x, player.y)
    if distToPlayer < explodeRadius then
        for i = 1, explodeDamage do
            if player:takeDamage() then
                camera:shake(20, 0.5, 3)
                effects:flash(1, 0.3, 0, 0.5)
                combo = 0
                comboTimer = 0
            end
        end
        
        if player.health <= 0 then
            gameState = "gameover"
            if score > highScore then
                highScore = score
            end
            
            -- Save profile stats
            Profile.incrementGamesPlayed()
            
            -- Save to leaderboard
            if Profile.hasProfile() then
                local name = Profile.getProfileName()
                Leaderboard.addScore(name, score)
            end
        end
    end
    
    -- Damage nearby enemies
    for i, other in ipairs(enemies) do
        if other ~= kamikaze then
            local dist = util.distance(kamikaze.x, kamikaze.y, other.x, other.y)
            if dist < explodeRadius then
                other:takeDamage(explodeDamage)
                if other.dead then
                    onEnemyKilled(other)
                end
            end
        end
    end
end

function createMuzzleFlash(x, y, angle)
    -- Muzzle flash effect
    for i = 1, 3 do
        local spreadAngle = angle + math.random(-15, 15) * (math.pi / 180)
        particleManager:thruster(x + math.cos(angle) * 15, y + math.sin(angle) * 15, spreadAngle, 0.8)
    end
    camera:shake(2, 0.05, 0.2)
end

function createExplosion(x, y, color)
    -- Use particle manager for explosions
    particleManager:explosion(x, y, 1, "default")
end

function createDashParticles(x, y)
    -- Dash trail effect
    particleManager:dashTrail(x, y, 15)
end

function createPowerUpParticles(x, y, color)
    -- Power-up collection effect
    particleManager:healEffect(x, y, 15)
end

function createDamageNumber(x, y, text, r, g, b)
    -- Damage numbers
    effects:addDamageNumber(x, y, text)
end

-- Touch event handlers for mobile controls
function love.touchpressed(id, x, y)
    if controlType ~= "mobile" then
        controlType = "mobile"
        touchControls = TouchControls.new()
    end
    if controlType == "mobile" and touchControls then
        touchControls:touchpressed(id, x, y)
    end
end

function love.touchmoved(id, x, y)
    if controlType == "mobile" and touchControls then
        touchControls:touchmoved(id, x, y)
    end
end

function love.touchreleased(id)
    if controlType == "mobile" and touchControls then
        touchControls:touchreleased(id)
    end
end



-- Shop Screen
function drawShopScreen()
    camera:apply()
    background:draw()
    camera:unapply()
    
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    local pulse = math.sin(menuTime * 2) * 0.3 + 0.7
    
    -- Title
    love.graphics.setFont(getFont(48))
    love.graphics.setColor(1, 0.8, 0.2, 0.2 * pulse)
    love.graphics.printf("DRONE SHOP", 0, 49, sw, "center")
    love.graphics.printf("DRONE SHOP", 0, 51, sw, "center")
    love.graphics.setColor(1, 0.8, 0.2)
    love.graphics.printf("DRONE SHOP", 0, 50, sw, "center")
    
    -- Stars display
    local profile = Profile.getProfile()
    local stars = profile and profile.stars or 0
    
    love.graphics.setFont(getFont(24))
    love.graphics.setColor(1, 1, 0.2)
    love.graphics.print("Stars: " .. stars, 20, 20)
    
    -- Shop items
    local pets = {
        {id = "pet1", name = "Pet 1", price = 1200, desc = "Fires yellow bullets. Basic but reliable.", color = {1, 1, 0.2}},
        {id = "pet2", name = "Pet 2", price = 3500, desc = "Fires blue bullets. Faster and stronger.", color = {0.2, 0.5, 1}},
        {id = "pet3", name = "Pet 3", price = 7500, desc = "Fires green bullets. Maximum power!", color = {0.2, 1, 0.2}}
    }
    
    local itemW, itemH = 250, 350
    local startX = (sw - (#pets * (itemW + 20))) / 2 + 10
    local startY = 150
    
    for i, pet in ipairs(pets) do
        local x = startX + (i-1) * (itemW + 20)
        local y = startY
        
        -- Card background
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", x, y, itemW, itemH, 10, 10)
        love.graphics.setColor(pet.color)
        love.graphics.rectangle("line", x, y, itemW, itemH, 10, 10)
        
        -- Pet Image/Icon
        local img = images[pet.id] -- Assuming loaded in love.load
        if not img then
            -- Fallback circle
            love.graphics.circle("fill", x + itemW/2, y + 80, 40)
        else
            love.graphics.setColor(1, 1, 1)
            local scale = 80 / img:getWidth()
            love.graphics.draw(img, x + itemW/2, y + 80, 0, scale, scale, img:getWidth()/2, img:getHeight()/2)
        end
        
        -- Name
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(getFont(24))
        love.graphics.printf(pet.name, x, y + 140, itemW, "center")
        
        -- Description
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.setFont(getFont(16))
        love.graphics.printf(pet.desc, x + 10, y + 180, itemW - 20, "center")
        
        -- Price / Status
        local unlocked = false
        local equipped = false
        if profile then
            unlocked = string.find(profile.unlockedPets, pet.id)
            equipped = profile.equippedPet == pet.id
        end
        
        local buttonY = y + itemH - 60
        local mx, my = love.mouse.getPosition()
        local hovered = mx >= x + 20 and mx <= x + itemW - 20 and my >= buttonY and my <= buttonY + 40
        
        if equipped then
            love.graphics.setColor(0.2, 0.8, 0.2)
            love.graphics.setFont(getFont(20))
            love.graphics.printf("EQUIPPED", x, buttonY + 10, itemW, "center")
        elseif unlocked then
            -- Equip button
            love.graphics.setColor(hovered and 0.4 or 0.2, hovered and 0.4 or 0.2, hovered and 0.8 or 0.6)
            love.graphics.rectangle("fill", x + 20, buttonY, itemW - 40, 40, 5, 5)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf("EQUIP", x, buttonY + 10, itemW, "center")
            
            if hovered and love.mouse.isDown(1) then
                -- Handle click (simple check, better in mousepressed)
            end
        else
            -- Buy button
            local canAfford = stars >= pet.price
            love.graphics.setColor(hovered and (canAfford and 0.4 or 0.3) or (canAfford and 0.2 or 0.1), hovered and (canAfford and 0.8 or 0.3) or (canAfford and 0.6 or 0.2), 0.2)
            love.graphics.rectangle("fill", x + 20, buttonY, itemW - 40, 40, 5, 5)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(pet.price .. " Stars", x, buttonY + 10, itemW, "center")
        end
    end
    
    -- Back button
    drawButton(menuButtons.back)
end

-- Profile Screen
function drawProfileScreen()
    camera:apply()
    background:draw()
    camera:unapply()
    
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    local pulse = math.sin(menuTime * 2) * 0.3 + 0.7
    
    -- Title
    love.graphics.setFont(getFont(48))
    love.graphics.setColor(0.5, 0.8, 1.0, 0.2 * pulse)
    love.graphics.printf("PLAYER PROFILE", 0, 89, sw, "center")
    love.graphics.printf("PLAYER PROFILE", 0, 91, sw, "center")
    love.graphics.setColor(0.5, 0.8, 1.0)
    love.graphics.printf("PLAYER PROFILE", 0, 90, sw, "center")
    
    if Profile.hasProfile() then
        -- Show existing profile
        local profile = Profile.getProfile()
        
        love.graphics.setFont(getFont(28))
        love.graphics.setColor(1,1, 1)
        love.graphics.printf("Welcome, " .. profile.name, 0, 200, sw, "center")
        
        love.graphics.setFont(getFont(20))
        love.graphics.setColor(0.8, 0.8, 0.9)
        love.graphics.printf("Games Played: " .. profile.gamesPlayed, 0, 260, sw, "center")
        love.graphics.printf("Total Score: " .. profile.totalScore, 0, 290, sw, "center")
        love.graphics.printf("Best Score: " .. profile.bestScore, 0, 320, sw, "center")
        
        -- Delete button
        drawButton(menuButtons.profileDelete)
    else
        -- Profile creation form
        love.graphics.setFont(getFont(20))
        love.graphics.setColor(0.8, 0.8, 0.9)
        love.graphics.printf("Enter your name:", 0, 200, sw, "center")
        
        -- Input box
        local inputX = sw/2 - 200
        local inputY = sh/2 - 60
        local inputWidth = 400
        local inputHeight = 50
        
        love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
        love.graphics.rectangle("fill", inputX, inputY, inputWidth, inputHeight, 5, 5)
        
        if profileInputActive then
            love.graphics.setColor(0.5, 0.8, 1.0, 0.3 * pulse)
            love.graphics.rectangle("fill", inputX - 2, inputY - 2, inputWidth +  4, inputHeight + 4, 5, 5)
        end
        
        love.graphics.setColor(0.6, 0.6, 0.7)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", inputX, inputY, inputWidth, inputHeight, 5, 5)
        
        -- Input text
        love.graphics.setFont(getFont(24))
        love.graphics.setColor(1, 1, 1)
        local displayText = profileNameInput
        if profileInputActive and math.floor(menuTime * 2) % 2 == 0 then
            displayText = displayText .. "|"
        end
        love.graphics.printf(displayText, inputX + 10, inputY + 13, inputWidth - 20, "left")
        
        -- Error message
        if profileError then
            love.graphics.setFont(getFont(16))
            love.graphics.setColor(1, 0.3, 0.3)
            love.graphics.printf(profileError, 0, inputY + 60, sw, "center")
        end
        
        -- Submit button
        drawButton(menuButtons.profileSubmit)
        
        -- Hint
        love.graphics.setFont(getFont(14))
        love.graphics.setColor(0.6, 0.6, 0.7)
        love.graphics.printf("Click the input box and type your name (max 20 characters)", 0, sh - 60, sw, "center")
    end
    
    -- Back button
    drawButton(menuButtons.back)
    
    -- Confirmation Popup
    if showDeleteConfirmation then
        -- Overlay
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", 0, 0, sw, sh)
        
        -- Popup Box
        local boxW, boxH = 400, 200
        local boxX, boxY = (sw - boxW)/2, (sh - boxH)/2
        
        love.graphics.setColor(0.15, 0.15, 0.2, 1)
        love.graphics.rectangle("fill", boxX, boxY, boxW, boxH, 10, 10)
        
        love.graphics.setColor(0.8, 0.3, 0.3, 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", boxX, boxY, boxW, boxH, 10, 10)
        
        -- Text
        love.graphics.setFont(getFont(28))
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Are you sure?", boxX, boxY + 40, boxW, "center")
        
        love.graphics.setFont(getFont(16))
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.printf("This action cannot be undone.", boxX, boxY + 85, boxW, "center")
        
        -- Buttons
        local btnW, btnH = 120, 45
        local btnY = boxY + 130
        local btnYesX = boxX + 50
        local btnNoX = boxX + boxW - 50 - btnW
        
        -- Yes Button
        local mx, my = love.mouse.getPosition()
        local yesHover = mx >= btnYesX and mx <= btnYesX + btnW and my >= btnY and my <= btnY + btnH
        
        love.graphics.setColor(yesHover and 0.9 or 0.7, 0.2, 0.2)
        love.graphics.rectangle("fill", btnYesX, btnY, btnW, btnH, 5, 5)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(getFont(20))
        love.graphics.printf("YES", btnYesX, btnY + 10, btnW, "center")
        
        -- No Button
        local noHover = mx >= btnNoX and mx <= btnNoX + btnW and my >= btnY and my <= btnY + btnH
        
        love.graphics.setColor(noHover and 0.4 or 0.3, noHover and 0.8 or 0.7, noHover and 0.4 or 0.3)
        love.graphics.rectangle("fill", btnNoX, btnY, btnW, btnH, 5, 5)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("NO", btnNoX, btnY + 10, btnW, "center")
    end
end

-- Leaderboard Screen
function drawLeaderboardScreen()
    camera:apply()
    background:draw()
    camera:unapply()
    
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    local pulse = math.sin(menuTime * 2) * 0.3 + 0.7
    
    -- Title
    love.graphics.setFont(getFont(48))
    love.graphics.setColor(1, 0.8, 0.2, 0.2 * pulse)
    love.graphics.printf("LEADERBOARD", 0, 39, sw, "center")
    love.graphics.printf("LEADERBOARD", 0, 41, sw, "center")
    love.graphics.setColor(1, 0.8, 0.2)
    love.graphics.printf("LEADERBOARD", 0, 40, sw, "center")
    
    -- Subtitle
    love.graphics.setFont(getFont(16))
    love.graphics.setColor(0.7, 0.7, 0.8)
    love.graphics.printf("Personal Best Scores - stored locally on this device", 0, 95, sw, "center")
    
    -- Close button
    drawButton(menuButtons.leaderboardClose)
    
    -- Leaderboard entries
    local entries = Leaderboard.getEntries()
    local startY = 125
    local entryHeight = 50
    local panelWidth = 600
    local panelX = (sw - panelWidth) / 2
    
    if #entries == 0 then
        love.graphics.setFont(getFont(20))
        love.graphics.setColor(0.7, 0.7, 0.8)
        love.graphics.printf("No scores yet! Play the game to get on the leaderboard.", 0, sh/2, sw, "center")
    else
        local playerInTop10 = false
        local playerRank = 0
        local playerScore = 0
        
        -- Enable scissor to clip entries below header
        love.graphics.setScissor(0, startY, sw, sh - startY - 100)
        
        -- Draw top 10 entries
        for i, entry in ipairs(entries) do
            local y = startY + (i - 1) * (entryHeight + 10) - leaderboardScroll
            
            -- Only draw if entry is visible on screen
            if y + entryHeight >= startY - 10 and y <= sh - 150 then
                -- Check if this is current player's entry
                local isCurrentPlayer = Profile.hasProfile() and entry.name == Profile.getProfileName()
                if isCurrentPlayer then
                    playerInTop10 = true
                end
                
                -- Entry background
                if isCurrentPlayer then
                    love.graphics.setColor(0.3, 0.6, 0.9, 0.6)
                else
                    love.graphics.setColor(0.2, 0.2, 0.3, 0.7)
                end
                love.graphics.rectangle("fill", panelX, y, panelWidth, entryHeight, 5, 5)
                
                -- Border
                if isCurrentPlayer then
                    love.graphics.setColor(0.5, 0.8, 1.0)
                else
                    love.graphics.setColor(0.4, 0.4, 0.5)
                end
                love.graphics.setLineWidth(2)
                love.graphics.rectangle("line", panelX, y, panelWidth, entryHeight, 5, 5)
                
                -- Rank
                love.graphics.setFont(getFont(28))
                if i == 1 then
                    love.graphics.setColor(1, 0.8, 0.2)  -- Gold
                elseif i == 2 then
                    love.graphics.setColor(0.8, 0.8, 0.8)  -- Silver
                elseif i == 3 then
                    love.graphics.setColor(0.8, 0.5, 0.3)  -- Bronze
                else
                    love.graphics.setColor(0.7, 0.7, 0.8)
                end
                love.graphics.printf("#" .. i, panelX + 10, y + 11, 60, "left")
                
                -- Player name
                love.graphics.setFont(getFont(22))
                love.graphics.setColor(1, 1, 1)
                love.graphics.printf(entry.name, panelX + 80, y + 14, panelWidth - 250, "left")
                
                -- Score
                love.graphics.setFont(getFont(24))
                love.graphics.setColor(1, 1, 0.5)
                love.graphics.printf(entry.score, panelX, y + 13, panelWidth - 20, "right")
            end
        end
        
        -- Disable scissor
        love.graphics.setScissor()
        
        -- Show current player's rank if they have a profile but are not in top 10
        if Profile.hasProfile() and not playerInTop10 then
            local profileName = Profile.getProfileName()
            local allEntries = Leaderboard.getEntries()  -- This returns top 10
            
            -- Get the profile's best score
            local profile = Profile.getProfile()
            if profile and profile.bestScore > 0 then
                -- Show player's rank below the top 10
                local playerY = sh - 100
                
                love.graphics.setFont(getFont(18))
                love.graphics.setColor(0.7, 0.7, 0.8)
                love.graphics.printf("Your Rank:", 0, playerY - 25, sw, "center")
                
                -- Player entry box
                love.graphics.setColor(0.3, 0.6, 0.9, 0.4)
                love.graphics.rectangle("fill", panelX, playerY, panelWidth, 45, 5, 5)
                love.graphics.setColor(0.5, 0.8, 1.0)
                love.graphics.setLineWidth(2)
                love.graphics.rectangle("line", panelX, playerY, panelWidth, 45, 5, 5)
                
                -- Rank (Not in top 10)
                love.graphics.setFont(getFont(20))
                love.graphics.setColor(0.7, 0.7, 0.8)
                love.graphics.printf("Not in Top 10", panelX + 10, playerY + 12, 150, "left")
                
                -- Player name
                love.graphics.setFont(getFont(18))
                love.graphics.setColor(1, 1, 1)
                love.graphics.printf(profileName, panelX + 170, playerY + 13, panelWidth - 340, "left")
                
                -- Score
                love.graphics.setFont(getFont(20))
                love.graphics.setColor(1, 1, 0.5)
                love.graphics.printf(profile.bestScore, panelX, playerY + 12, panelWidth - 20, "right")
            end
        end
    end
end

-- Handle mouse wheel scrolling for leaderboard
function love.wheelmoved(x, y)
    if gameState == "leaderboard" then
        -- Scroll the leaderboard
        leaderboardScroll = leaderboardScroll - y * 40  -- 40 pixels per scroll step
        
        -- Clamp scroll to valid range
        local entries = Leaderboard.getEntries()
        local maxScroll = math.max(0, (#entries * 60) - 400)  -- Total height minus visible area
        leaderboardScroll = math.max(0, math.min(leaderboardScroll, maxScroll))
    end
end

