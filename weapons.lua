-- Weapons module

local Weapons = {}

-- Weapon definitions
Weapons.types = {
    pistol = {
        name = "Pistol",
        fireRate = 0.2,
        damage = 1,
        bulletSpeed = 400,
        bulletCount = 1,
        spread = 0,
        ammo = -1, -- infinite
        maxAmmo = -1,
        range = 1000,
        piercing = false,
        icon = "P"
    },
    shotgun = {
        name = "Shotgun",
        fireRate = 0.6,
        damage = 1,
        bulletSpeed = 350,
        bulletCount = 5,
        spread = 0.4,
        ammo = 30,
        maxAmmo = 30,
        range = 300,
        piercing = false,
        icon = "S"
    },
    machinegun = {
        name = "Machine Gun",
        fireRate = 0.08,
        damage = 0.7,
        bulletSpeed = 450,
        bulletCount = 1,
        spread = 0.1,
        ammo = 100,
        maxAmmo = 100,
        range = 800,
        piercing = false,
        icon = "M"
    },
    sniper = {
        name = "Sniper",
        fireRate = 1.0,
        damage = 5,
        bulletSpeed = 600,
        bulletCount = 1,
        spread = 0,
        ammo = 10,
        maxAmmo = 10,
        range = 1500,
        piercing = true,
        icon = "R"
    },
    homing = {
        name = "Homing Missile",
        fireRate = 1.5,
        damage = 3,
        bulletSpeed = 250,
        bulletCount = 1,
        spread = 0,
        ammo = 20,
        maxAmmo = 20,
        range = 1000,
        piercing = false,
        homing = true,
        homingStrength = 3.0,
        explosion = true,
        explosionRadius = 40,
        icon = "H"
    }
}

function Weapons.new()
    local weapons = {}
    
    -- Initialize weapon ammo
    for weaponType, data in pairs(Weapons.types) do
        weapons[weaponType] = {
            ammo = data.ammo,
            unlocked = (weaponType == "pistol") -- Only pistol unlocked at start
        }
    end
    
    return weapons
end

function Weapons.unlockWeapon(weapons, weaponType)
    if weapons and weapons[weaponType] and Weapons.types[weaponType] then
        weapons[weaponType].unlocked = true
    end
end

function Weapons.addAmmo(weapons, weaponType, amount)
    amount = math.max(0, tonumber(amount) or 0)
    if weapons and weapons[weaponType] and Weapons.types[weaponType].maxAmmo ~= -1 then
        weapons[weaponType].ammo = math.min(
            weapons[weaponType].ammo + amount,
            Weapons.types[weaponType].maxAmmo
        )
    end
end

function Weapons.useAmmo(weapons, weaponType, amount)
    amount = math.max(0, tonumber(amount) or 0)
    if weapons and weapons[weaponType] then
        if Weapons.types[weaponType].maxAmmo == -1 then
            return true -- Infinite ammo
        end
        
        if weapons[weaponType].ammo >= amount then
            weapons[weaponType].ammo = weapons[weaponType].ammo - amount
            return true
        end
    end
    return false
end

function Weapons.hasAmmo(weapons, weaponType)
    if weapons[weaponType] then
        if Weapons.types[weaponType].maxAmmo == -1 then
            return true
        end
        return weapons[weaponType].ammo > 0
    end
    return false
end

function Weapons.get(weaponType)
    return Weapons.types[weaponType]
end

function Weapons.isUnlocked(weapons, weaponType)
    return weapons ~= nil and weapons[weaponType] ~= nil and weapons[weaponType].unlocked == true
end

return Weapons
