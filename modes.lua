-- Starfall Vengeance: exactly three production game modes.
-- The mode layer owns rules; main.lua owns presentation and entity orchestration.
local Modes={}
Modes.list={
 campaign={id="campaign",name="CAMPAIGN",tagline="30 waves. One final stand.",description="A curated 30-wave run with escalating enemy compositions, elite encounters and five boss gates.",goal="Defeat Wave 30",maxWave=30,startingLives=3,scoreMultiplier=1.0,xpMultiplier=1.0},
 endless={id="endless",name="ENDLESS",tagline="How far can you survive?",description="Infinite adaptive waves. Threat, density and elite pressure keep climbing until you break.",goal="Set a personal best",maxWave=math.huge,startingLives=3,scoreMultiplier=1.15,xpMultiplier=1.1},
 gauntlet={id="gauntlet",name="GAUNTLET",tagline="Eight brutal trials. No wasted moves.",description="Eight timed trials with rotating combat modifiers. Each trial ends with a high-value extraction bonus.",goal="Clear all 8 trials",maxWave=8,startingLives=2,scoreMultiplier=1.5,xpMultiplier=1.35}
}
local gauntletMutators={
 {name="OVERDRIVE",desc="Enemies move 30% faster.",speed=1.30,health=1.0,spawn=1.0},
 {name="BULLET HELL",desc="Enemy fire rate is doubled.",speed=1.0,health=1.0,spawn=1.0,fire=0.50},
 {name="IRON CORE",desc="Enemies have 55% more health.",speed=1.0,health=1.55,spawn=1.0},
 {name="CROSSFIRE",desc="More ranged enemies enter the field.",speed=1.0,health=1.15,spawn=0.80},
 {name="SWARM",desc="Spawn pressure is doubled.",speed=1.10,health=0.90,spawn=0.55},
 {name="GLASS CANNON",desc="Everything hits harder, including you.",speed=1.15,health=0.85,spawn=0.80,damage=1.8},
 {name="BLACKOUT",desc="Reduced visual clutter; elite rewards increase.",speed=1.20,health=1.20,spawn=0.90,reward=1.35},
 {name="FINAL LOCK",desc="Boss-grade pressure. Clear it to win.",speed=1.35,health=1.65,spawn=0.70,fire=0.55,reward=2.0}
}
function Modes.get(id) return Modes.list[id] or Modes.list.campaign end
function Modes.getAll() return {Modes.list.campaign,Modes.list.endless,Modes.list.gauntlet} end
function Modes.newRun(id)
 local m=Modes.get(id); local r={id=m.id,wave=1,score=0,kills=0,combo=0,bestCombo=0,elapsed=0,lives=m.startingLives,threat=0,trial=1,trialTimer=0,trialDuration=90,mutator=nil,completed=false,target=0,spawned=0,spawnTimer=0}
 if m.id=="gauntlet" then r.mutator=gauntletMutators[1] end; return r
end
function Modes.waveRules(run)
 local w=run.wave; local t=math.max(0,math.min(1,run.threat or 0)); local m=Modes.get(run.id)
 if run.id=="campaign" then
  return {target=math.min(8+w*2,68),spawnDelay=math.max(.24,(1.35-w*.028)*(1-t*.16)),boss=(w%6==0),eliteChance=math.min(.05+w*.012+t*.10,.45),health=(1+w*.045)*(1+t*.10),speed=(1+w*.012)*(1+t*.06)}
 elseif run.id=="endless" then
  local pressure=math.min(3,1+w*.035+t*.45)
  return {target=math.min(10+math.floor(w*2.5),95),spawnDelay=math.max(.15,1.15/pressure*(1-t*.18)),boss=(w%10==0),eliteChance=math.min(.08+w*.014+t*.12,.70),health=(1+w*.055)*(1+t*.12),speed=(1+w*.018)*(1+t*.07)}
 else
  local gm=run.mutator or gauntletMutators[run.trial]
  return {target=18+run.trial*5,spawnDelay=math.max(.20,.90*(gm.spawn or 1)*(1-t*.08)),boss=run.trial==8,eliteChance=math.min(.15+run.trial*.035+t*.06,.55),health=(1+run.trial*.06)*(gm.health or 1)*(1+t*.06),speed=(1+run.trial*.02)*(gm.speed or 1)*(1+t*.03),fireMultiplier=gm.fire or 1,rewardMultiplier=gm.reward or 1,damageMultiplier=gm.damage or 1}
 end
end
function Modes.nextGauntletTrial(run)
 run.trial=run.trial+1; run.wave=run.trial; run.trialTimer=0; run.mutator=gauntletMutators[run.trial]; return run.trial<=#gauntletMutators
end
function Modes.isVictory(run)
 if run.id=="campaign" then return run.wave>=30 and run.completed end
 if run.id=="gauntlet" then return run.trial>=8 and run.completed end
 return false
end
function Modes.modeColor(id)
 if id=="campaign" then return {.25,.85,1} elseif id=="endless" then return {1,.55,.20} else return {.85,.35,1} end
end
return Modes
