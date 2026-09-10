-- Starfall Vengeance - Asset Registry
-- Centralized, defensive loader for all production artwork.

local Assets = {
    images = {},
    loaded = false,
    missing = {},
}

local function safeImage(path)
    local ok, img = pcall(love.graphics.newImage, path)
    if ok and img then
        img:setFilter("linear", "linear")
        return img
    end
    Assets.missing[path] = true
    return nil
end

local imageFiles = {
    player = "assets/SpaceShip.png",
    ship = "assets/ship.png",
    support = "assets/support.png",
    pet1 = "assets/pet 1.png",
    pet2 = "assets/pet 2.png",
    pet3 = "assets/pet 3.png",
    swarmer = "assets/SWARMERS.png",
    sniper = "assets/SNIPERS.png",
    bomber = "assets/BOMBERS.png",
    turret = "assets/TURRET DRONES.png",
    miniboss = "assets/MINI-BOSSES.png",
    bullet = "assets/bullet.png",
    bullet1 = "assets/bullet-1.png",
    bullet2 = "assets/bullet-2.png",
    laser1 = "assets/laser-1.png",
    laser2 = "assets/laser-2.png",
    laser3 = "assets/laser-3.png",
    plasma = "assets/plasm.png",
    rocket = "assets/rocket.png",
    shield = "assets/shield.png",
    fire = "assets/fire.png",
    background = "assets/bg.png",
    starsA = "assets/Stars-A.png",
    starsB = "assets/Stars-B.png",
    bonusLife = "assets/bonus_life.png",
    bonusShield = "assets/bonus_shield.png",
    bonusTime = "assets/bonus_time.png",
    asteroidSmallA = "assets/small-A.png",
    asteroidSmallB = "assets/small-B.png",
    asteroidMediumA = "assets/medium-A.png",
    asteroidMediumB = "assets/medium-B.png",
    asteroidLargeA = "assets/large-A.png",
    asteroidLargeB = "assets/large-B.png",
    sphere0 = "assets/sphere0.png",
    sphere1 = "assets/sphere1.png",
    sphere2 = "assets/sphere2.png",
}

for i = 0, 10 do
    imageFiles["light" .. i] = "assets/light" .. i .. ".png"
end
for i = 0, 27 do
    imageFiles["noise" .. string.format("%02d", i)] = "assets/noise" .. string.format("%02d", i) .. ".png"
end
for i = 0, 9 do
    imageFiles["planet" .. string.format("%02d", i)] = "assets/planet" .. string.format("%02d", i) .. ".png"
end

function Assets.load()
    if Assets.loaded then return Assets.images end
    for key, path in pairs(imageFiles) do
        Assets.images[key] = safeImage(path)
    end
    Assets.loaded = true
    return Assets.images
end

function Assets.get(name)
    if not Assets.loaded then Assets.load() end
    return Assets.images[name]
end

function Assets.drawImage(image, x, y, w, h, rotation, alpha)
    if not image then return false end
    local iw, ih = image:getWidth(), image:getHeight()
    if iw <= 0 or ih <= 0 then return false end
    local sx = w and w / iw or 1
    local sy = h and h / ih or sx
    love.graphics.setColor(1, 1, 1, alpha or 1)
    love.graphics.draw(image, x, y, rotation or 0, sx, sy, iw / 2, ih / 2)
    return true
end

return Assets
