-- XP and Leveling system
-- Functional upgrades only; temporary combat effects remain in Player.

local XP={}

function XP.new()
    return {current=0,level=1,toNextLevel=100,totalXP=0}
end

function XP.addXP(xpData,amount)
    amount=math.max(0,tonumber(amount) or 0)
    xpData.current=xpData.current+amount; xpData.totalXP=xpData.totalXP+amount
    local leveled=false
    while xpData.current>=xpData.toNextLevel do
        xpData.current=xpData.current-xpData.toNextLevel; xpData.level=xpData.level+1
        xpData.toNextLevel=math.max(xpData.toNextLevel+1,math.floor(xpData.toNextLevel*1.2)); leveled=true
    end
    return leveled
end

function XP.getProgress(xpData)
    if not xpData or xpData.toNextLevel<=0 then return 0 end
    return math.max(0,math.min(1,xpData.current/xpData.toNextLevel))
end

XP.upgrades={
    {id="health",name="+1 Max Health",description="Increase maximum health by 1",apply=function(p) p.maxHealth=p.maxHealth+1; p.health=math.min(p.maxHealth,p.health+1) end},
    {id="speed",name="+15% Movement Speed",description="Move faster permanently",apply=function(p) p.baseSpeed=p.baseSpeed*1.15 end},
    {id="firerate",name="+20% Fire Rate",description="Shoot faster with all weapons",apply=function(p) p.persistentFireRateMultiplier=(p.persistentFireRateMultiplier or p.fireRateMultiplier or 1)*0.8; p.fireRateMultiplier=p.persistentFireRateMultiplier end},
    {id="damage",name="+25% Damage",description="Deal more damage with all weapons",apply=function(p) p.persistentDamageMultiplier=(p.persistentDamageMultiplier or p.damageMultiplier or 1)*1.25; p.damageMultiplier=p.persistentDamageMultiplier end},
    {id="dashcooldown",name="-20% Dash Cooldown",description="Dash more frequently",apply=function(p) p.dashDelay=math.max(0.35,p.dashDelay*0.8) end},
    {id="pickup",name="Magnetic Pickups",description="Auto-collect nearby pickups",apply=function(p) p.persistentMagneticRange=math.max(p.persistentMagneticRange or p.magneticRange or 0,80); p.magneticRange=p.persistentMagneticRange end},
    {id="piercing",name="Piercing Bullets",description="Bullets go through enemies",apply=function(p) p.piercingBullets=true end},
    {id="multishot",name="+1 Extra Projectile",description="Fire one additional bullet",apply=function(p) p.persistentExtraProjectiles=(p.persistentExtraProjectiles or p.extraProjectiles or 0)+1; p.extraProjectiles=p.persistentExtraProjectiles end},
    {id="sidedrones",name="Side Drones",description="Deploy 2 side drones that auto-shoot",apply=function(p) p.hasSideDrones=true end},
    {id="orbitdrones",name="Orbit Drones",description="Deploy 2 drones that orbit and damage enemies",apply=function(p) p.hasOrbitDrones=true end},
    {id="dronedamage",name="+50% Drone Damage",description="All companion drones deal more damage",apply=function(p) p.droneDamageMultiplier=(p.droneDamageMultiplier or 1)*1.5 end},
    {id="homingmissile",name="Homing Missiles",description="Every 5th shot becomes a homing missile",apply=function(p) p.hasHomingMissile=true end},
    {id="explosion",name="+50% Explosion Size",description="Increase explosion radius and particle size",apply=function(p) p.explosionSizeMultiplier=(p.explosionSizeMultiplier or 1)*1.5 end},
}

function XP.getRandomUpgrades(count)
    local shuffled={}; for _,u in ipairs(XP.upgrades) do shuffled[#shuffled+1]=u end
    for i=#shuffled,2,-1 do local j=math.random(i); shuffled[i],shuffled[j]=shuffled[j],shuffled[i] end
    local result={}; for i=1,math.min(count or 3,#shuffled) do result[#result+1]=shuffled[i] end
    return result
end

return XP
