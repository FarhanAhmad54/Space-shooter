-- Starfall Vengeance weapon definitions
local Weapons={}
Weapons.types={
    pistol={name="Pistol",fireRate=.20,damage=1,bulletSpeed=400,bulletCount=1,spread=0,ammo=-1,maxAmmo=-1,range=1000,piercing=false,icon="P"},
    shotgun={name="Shotgun",fireRate=.60,damage=1,bulletSpeed=350,bulletCount=5,spread=.4,ammo=30,maxAmmo=30,range=300,piercing=false,icon="S",autoReload=true},
    machinegun={name="Machine Gun",fireRate=.08,damage=.7,bulletSpeed=450,bulletCount=1,spread=.1,ammo=100,maxAmmo=100,range=800,piercing=false,icon="M",autoReload=true},
    sniper={name="Sniper",fireRate=1.0,damage=5,bulletSpeed=600,bulletCount=1,spread=0,ammo=10,maxAmmo=10,range=1500,piercing=true,icon="R",autoReload=true},
    homing={name="Homing Missile",fireRate=1.5,damage=3,bulletSpeed=250,bulletCount=1,spread=0,ammo=20,maxAmmo=20,range=1000,piercing=false,homing=true,homingStrength=3.0,explosion=true,explosionRadius=40,icon="H",autoReload=true}
}

function Weapons.new()
    local w={}
    for id,d in pairs(Weapons.types) do
        w[id]={ammo=d.ammo,unlocked=(id=="pistol" or id=="shotgun" or id=="machinegun" or id=="sniper")}
    end
    return w
end

function Weapons.unlockWeapon(w,id)
    if w and w[id] and Weapons.types[id] then w[id].unlocked=true end
end

function Weapons.addAmmo(w,id,n)
    n=math.max(0,tonumber(n) or 0)
    if w and w[id] and Weapons.types[id].maxAmmo~=-1 then
        w[id].ammo=math.min(w[id].ammo+n,Weapons.types[id].maxAmmo)
    end
end

function Weapons.useAmmo(w,id,n)
    n=math.max(0,tonumber(n) or 0)
    if not (w and w[id]) then return false end
    local d=Weapons.types[id]
    if d.maxAmmo==-1 then return true end
    if w[id].ammo>=n then
        w[id].ammo=w[id].ammo-n
        return true
    end
    if d.autoReload then
        w[id].ammo=d.maxAmmo
        if w[id].ammo>=n then
            w[id].ammo=w[id].ammo-n
            return true
        end
    end
    return false
end

function Weapons.hasAmmo(w,id)
    if not (w and w[id]) then return false end
    local d=Weapons.types[id]
    if d.maxAmmo==-1 then return true end
    if w[id].ammo>0 then return true end
    if d.autoReload then
        w[id].ammo=d.maxAmmo
        return true
    end
    return false
end

function Weapons.get(id) return Weapons.types[id] end
function Weapons.isUnlocked(w,id) return w and w[id] and w[id].unlocked==true end

return Weapons
