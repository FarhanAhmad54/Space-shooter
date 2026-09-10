-- Leaderboard management module
-- Tracks top 10 high scores

local Leaderboard = {}

local entries = {}
local MAX_ENTRIES = 10

-- Load leaderboard from file
function Leaderboard.load()
    entries = {}
    local info = love.filesystem.getInfo("leaderboard.txt")
    if info then
        local contents = love.filesystem.read("leaderboard.txt")
        if contents then
            for line in contents:gmatch("[^\r\n]+") do
                local name, score = line:match("^(.-):(%-?%d+)$")
                score = tonumber(score)
                if name and name ~= "" and score and score >= 0 then
                    table.insert(entries, { name = name, score = score })
                end
            end
        end
    end
end

-- Save leaderboard to file
function Leaderboard.save()
    local data = ""
    for i, entry in ipairs(entries) do
        data = data .. entry.name .. ":" .. entry.score
        if i < #entries then
            data = data .. "\n"
        end
    end
    pcall(love.filesystem.write, "leaderboard.txt", data)
end

-- Add score to leaderboard
function Leaderboard.addScore(name, score)
    -- Check if this name already exists in leaderboard
    local existingIndex = nil
    for i, entry in ipairs(entries) do
        if entry.name == name then
            existingIndex = i
            break
        end
    end
    
    -- If exists, update only if new score is higher
    if existingIndex then
        if score > entries[existingIndex].score then
            entries[existingIndex].score = score
        end
    else
        -- Add new entry
        table.insert(entries, {
            name = name,
            score = score
        })
    end
    
    -- Sort by score (descending)
    table.sort(entries, function(a, b)
        return a.score > b.score
    end)
    
    -- Keep only top 10
    while #entries > MAX_ENTRIES do
        table.remove(entries)
    end
    
    Leaderboard.save()
end

-- Get all entries
function Leaderboard.getEntries()
    return entries
end

-- Clear leaderboard
function Leaderboard.clear()
    -- Compatibility API. The game no longer calls this on launch.
    entries = {}
    Leaderboard.save()
end

-- Check if a name exists in leaderboard
function Leaderboard.hasName(name)
    for i, entry in ipairs(entries) do
        if entry.name == name then
            return true
        end
    end
    return false
end

-- Initialize leaderboard
function Leaderboard.init()
    Leaderboard.load()
    table.sort(entries, function(a, b) return a.score > b.score end)
    while #entries > MAX_ENTRIES do table.remove(entries) end
end

return Leaderboard
