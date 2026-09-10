-- Profile management module
-- Handles player profile creation, deletion, and persistent progression.

local Profile = {}
local currentProfile = nil

local function serializeCurrent()
    if not currentProfile then return nil end
    return string.format(
        "name=%s\ntotalScore=%d\ngamesPlayed=%d\nbestScore=%d\nstars=%d\nunlockedPets=%s\nequippedPet=%s\ntutorialCompleted=%d",
        currentProfile.name or "Player",
        math.max(0, currentProfile.totalScore or 0),
        math.max(0, currentProfile.gamesPlayed or 0),
        math.max(0, currentProfile.bestScore or 0),
        math.max(0, currentProfile.stars or 0),
        currentProfile.unlockedPets or "",
        currentProfile.equippedPet or "none",
        currentProfile.tutorialCompleted and 1 or 0
    )
end

local function saveCurrent()
    local data = serializeCurrent()
    if not data then return false end
    local ok = love.filesystem.write("profile.txt", data)
    return ok ~= false
end

function Profile.loadProfile()
    local info = love.filesystem.getInfo("profile.txt")
    if not info then return false end
    local contents = love.filesystem.read("profile.txt")
    if not contents then return false end

    local data = {}
    for line in contents:gmatch("[^\r\n]+") do
        local key, value = line:match("^([^=]+)=(.*)$")
        if key and value then data[key] = value:gsub("^%s+", ""):gsub("%s+$", "") end
    end

    currentProfile = {
        name = data.name or "Player",
        totalScore = tonumber(data.totalScore) or 0,
        gamesPlayed = tonumber(data.gamesPlayed) or 0,
        bestScore = tonumber(data.bestScore) or 0,
        stars = tonumber(data.stars) or 0,
        unlockedPets = data.unlockedPets or "",
        equippedPet = data.equippedPet or "none",
        tutorialCompleted = data.tutorialCompleted == "1" or data.tutorialCompleted == "true"
    }
    return true
end

function Profile.saveProfile(name, totalScore, gamesPlayed, bestScore, stars, unlockedPets, equippedPet, tutorialCompleted)
    currentProfile = {
        name = tostring(name or "Player"):sub(1, 20),
        totalScore = math.max(0, math.floor(tonumber(totalScore) or 0)),
        gamesPlayed = math.max(0, math.floor(tonumber(gamesPlayed) or 0)),
        bestScore = math.max(0, math.floor(tonumber(bestScore) or 0)),
        stars = math.max(0, math.floor(tonumber(stars) or 0)),
        unlockedPets = tostring(unlockedPets or ""),
        equippedPet = tostring(equippedPet or "none"),
        tutorialCompleted = tutorialCompleted == true
    }
    saveCurrent()
end

function Profile.createProfile(name)
    if not name or name == "" or name:match("^%s*$") then return false, "Name cannot be empty" end
    name = name:match("^%s*(.-)%s*$"):sub(1, 20)
    Profile.saveProfile(name, 0, 0, 0, 0, "", "none", false)
    return true, "Profile created successfully"
end

function Profile.deleteProfile()
    love.filesystem.remove("profile.txt")
    currentProfile = nil
end

function Profile.hasProfile() return currentProfile ~= nil end
function Profile.getProfileName() return currentProfile and currentProfile.name or nil end
function Profile.getProfile() return currentProfile end

-- Update a completed run. starsGained is the complete reward for this run,
-- so callers do not need a second addStars call for the same score.
function Profile.updateStats(score, starsGained)
    if not currentProfile then return end
    local runScore = math.max(0, math.floor(tonumber(score) or 0))
    local runStars = math.max(0, math.floor(tonumber(starsGained) or 0))
    currentProfile.totalScore = currentProfile.totalScore + runScore
    currentProfile.stars = currentProfile.stars + runStars
    currentProfile.bestScore = math.max(currentProfile.bestScore, runScore)
    saveCurrent()
end

function Profile.addStars(amount)
    if not currentProfile then return false end
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    currentProfile.stars = currentProfile.stars + amount
    saveCurrent()
    return true
end

function Profile.incrementGamesPlayed()
    if not currentProfile then return end
    currentProfile.gamesPlayed = currentProfile.gamesPlayed + 1
    saveCurrent()
end

function Profile.spendStars(amount)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    if currentProfile and currentProfile.stars >= amount then
        currentProfile.stars = currentProfile.stars - amount
        saveCurrent()
        return true
    end
    return false
end

function Profile.unlockPet(petId)
    if not currentProfile or not petId then return false end
    for id in currentProfile.unlockedPets:gmatch("[^,]+") do if id == petId then return true end end
    currentProfile.unlockedPets = currentProfile.unlockedPets == "" and petId or (currentProfile.unlockedPets .. "," .. petId)
    saveCurrent()
    return true
end

function Profile.equipPet(petId)
    if not currentProfile or not petId then return false end
    currentProfile.equippedPet = petId
    saveCurrent()
    return true
end

function Profile.setTutorialCompleted(completed)
    if not currentProfile then return false end
    currentProfile.tutorialCompleted = completed == true
    saveCurrent()
    return true
end

function Profile.init()
    Profile.loadProfile()
end

return Profile
