--[[
#Script Name:   <thievesguilddoors.lua>
# Description:  <Picklocks  Thieves' Guild doors.>
# Autor:        <Pizzanova>
# Version:      <1.0>
# Datum:        <06.10.2023>
--]]


local API = require("api")
local UTILS = require("utils")

MAX_IDLE_TIME_MINUTES = 4
afk = os.time()
local door13 = 52302
local door46 = 52304
local ThievingLevel = API.XPLevelTable(API.GetSkillXP("THIEVING"))
local startTime = os.time()
local startXp = API.GetSkillXP("THIEVING")
local gatesopened, fail = -1, 0
local skillxpsold = 0
local lastXpDropTime = os.time()
local currentworld = 62
local P2PWorlds = {
    1, 5, 6, 9, 10, 12, 14, 15, 16, 21, 22, 23, 24, 25, 26, 27, 28, 31, 32, 35, 36, 37, 39, 40, 44, 45,
    46, 49, 50, 51, 53, 54, 58, 59, 60, 62, 63, 64, 65, 67, 68, 69, 70, 71, 72, 73, 74, 76, 77, 78, 79, 82,
}

-- Table to keep track of generated worlds and their generation times
local generatedWorlds = {}

-- Function to generate a random world
local function generateRandomWorld()
    math.randomseed(os.time()) -- Seed the random number generator with the current time
    local selectedWorld = P2PWorlds[math.random(1, #P2PWorlds)] -- Choose a random world from the list
    return selectedWorld
end

-- Function to get a new world, ensuring it's different from the ones generated within 5 minutes
local function getNewWorld()
    local currentTime = os.time()

    local function isWorldGeneratedWithinCooldown(worldName)
        local lastGeneratedTime = generatedWorlds[worldName]
        return lastGeneratedTime and currentTime - lastGeneratedTime < 300
    end

    local selectedWorld = generateRandomWorld()

    -- Keep selecting a new world until it's not generated within the cooldown period
    while isWorldGeneratedWithinCooldown(selectedWorld) do
        selectedWorld = generateRandomWorld()
    end

    generatedWorlds[selectedWorld] = currentTime -- Record the generation time

    return selectedWorld
end

-- Format script elapsed time to [hh:mm:ss]
local function formatElapsedTime(startTime)
    local currentTime = os.time()
    local elapsedTime = currentTime - startTime
    local hours = math.floor(elapsedTime / 3600)
    local minutes = math.floor((elapsedTime % 3600) / 60)
    local seconds = elapsedTime % 60
    return string.format("[%02d:%02d:%02d]", hours, minutes, seconds)
end

-- Round numbers
local function round(val, decimal)
    if decimal then
        return math.floor((val * 10 ^ decimal) + 0.5) / (10 ^ decimal)
    else
        return math.floor(val + 0.5)
    end
end

-- Format a number with commas as thousands separator
local function formatNumberWithCommas(amount)
    local formatted = tostring(amount)
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if (k == 0) then
            break
        end
    end
    return formatted
end

local function printProgressReport(final)
    skillxps = API.GetSkillXP("THIEVING")
    if (skillxps ~= skillxpsold) then
        skillxpsold = skillxps
        gatesopened = gatesopened + 1
    end
    local currentXp = API.GetSkillXP("THIEVING")
    local elapsedMinutes = (os.time() - startTime) / 60
    local diffXp = math.abs(currentXp - startXp)
    local xpPH = round((diffXp * 60) / elapsedMinutes)
    local gatesopenedPH = round((gatesopened * 60) / elapsedMinutes)
    local time = formatElapsedTime(startTime)
    IG.string_value = " Thieving XP : " .. formatNumberWithCommas(diffXp) .. " (" .. formatNumberWithCommas(xpPH) .. ")"
    IG2.string_value = "   Gates Opened : " .. formatNumberWithCommas(gatesopened) .. " (" .. formatNumberWithCommas(gatesopenedPH) .. ")"
    IG4.string_value = time

    if final then
        print(os.date("%H:%M:%S") .. " Script Finished\nRuntime : " .. time .. "\nTHIEVING XP : " .. formatNumberWithCommas(diffXp) .. " \nGates opened : " .. formatNumberWithCommas(gatesopened))
    end
end

local function setupGUI()
    IG = API.CreateIG_answer()
    IG.box_start = FFPOINT.new(15, 50, 0)
    IG.box_name = "THIEVING"
    IG.colour = ImColor.new(255, 255, 255);
    IG.string_value = "THIEVING XP : 0 (0)"

    IG2 = API.CreateIG_answer()
    IG2.box_start = FFPOINT.new(1, 65, 0)
    IG2.box_name = "gatesopenedT"
    IG2.colour = ImColor.new(255, 255, 255);
    IG2.string_value = " Gates Opened : 0 (0)"

    IG3 = API.CreateIG_answer()
    IG3.box_start = FFPOINT.new(40, 15, 0)
    IG3.box_name = "TITLE"
    IG3.colour = ImColor.new(0, 255, 0);
    IG3.string_value = "- Jail Opener v1.0 -"

    IG6 = API.CreateIG_answer()
    IG6.box_start = FFPOINT.new(5, 80, 0)
    IG6.box_name = "LINE"
    IG6.colour = ImColor.new(0, 255, 0);
    IG6.string_value = "--------------------------------"

    IG7 = API.CreateIG_answer()
    IG7.box_start = FFPOINT.new(5, 5, 0)
    IG7.box_name = "LINE2"
    IG7.colour = ImColor.new(0, 255, 0);
    IG7.string_value = "--------------------------------"

    IG8 = API.CreateIG_answer()
    IG8.box_start = FFPOINT.new(7, 5, 0)
    IG8.box_name = "LINE3"
    IG8.colour = ImColor.new(0, 255, 0);
    IG8.string_value = [[
|
|
|
|
|
|
|
]]

    IG9 = API.CreateIG_answer()
    IG9.box_start = FFPOINT.new(220, 5, 0)
    IG9.box_name = "LINE4"
    IG9.colour = ImColor.new(0, 255, 0);
    IG9.string_value = [[
|
|
|
|
|
|
|
]]

    IG4 = API.CreateIG_answer()
    IG4.box_start = FFPOINT.new(70, 31, 0)
    IG4.box_name = "TIME"
    IG4.colour = ImColor.new(255, 255, 255);
    IG4.string_value = "[00:00:00]"

    IG_Back = API.CreateIG_answer();
    IG_Back.box_name = "back";
    IG_Back.box_start = FFPOINT.new(0, 0, 0)
    IG_Back.box_size = FFPOINT.new(235, 100, 0)
    IG_Back.colour = ImColor.new(15, 13, 18, 255)
    IG_Back.string_value = ""
end

function drawGUI()
    API.DrawSquareFilled(IG_Back)
    API.DrawTextAt(IG)
    API.DrawTextAt(IG2)
    API.DrawTextAt(IG3)
    API.DrawTextAt(IG4)
    API.DrawTextAt(IG5)
    API.DrawTextAt(IG6)
    API.DrawTextAt(IG7)
    API.DrawTextAt(IG8)
    API.DrawTextAt(IG9)
end

setupGUI()


local function idleCheck()
    local timeDiff = os.difftime(os.time(), afk)
    local randomTime = math.random((MAX_IDLE_TIME_MINUTES * 60) * 0.6, (MAX_IDLE_TIME_MINUTES * 60) * 0.9)

    if timeDiff > randomTime then
        API.PIdle2()
        afk = os.time()
    end
end

local function RandomSleep3(arg1, arg2, arg3)
    local numSteps = 8 -- Number of steps to divide the sleep into

    for i = 1, numSteps do
        local stepDuration1 = arg1 / numSteps
        local stepDuration2 = arg2 / numSteps
        local stepDuration3 = arg3 / numSteps

        API.RandomSleep2(stepDuration1, stepDuration2, stepDuration3)
        printProgressReport()
    end
end


function CheckDoorStatus(doorTile)
    if not API.CheckTileforObjects1(doorTile) then
        return false -- Door is closed
    else
        return true -- Door is open
    end
end

local function findNpc(npcid, distance)
    local distance = distance or 20
    return #API.GetAllObjArrayInteract({ npcid }, distance, 1) > 0
end

-- Define the WPOINT objects for all doors in a table
local doors = {
    { tile = WPOINT.new(4776, 5916, 0), status = false },
    { tile = WPOINT.new(4778, 5916, 0), status = false },
    { tile = WPOINT.new(4780, 5916, 0), status = false },
    { tile = WPOINT.new(4776, 5915, 0), status = false },
    { tile = WPOINT.new(4778, 5915, 0), status = false },
    { tile = WPOINT.new(4780, 5915, 0), status = false }
}

-- Function to update the status of all doors and print their status
function checkalldoors()
    for i, door in ipairs(doors) do
        door.status = CheckDoorStatus(door.tile)
    end
end

function worldhop()
    local newWorld = getNewWorld()

    API.DoAction_Interface(0xffffffff, 0xffffffff, 3, 1465, 9, -1, 5392); -- world hop screen
    RandomSleep3(2000, 250, 50)
    API.DoAction_Interface(0xffffffff, 0xffffffff, 2, 1587, 8, newWorld, 5392); -- world hop
    RandomSleep3(5000, 550, 50)
end

-- main loop
API.Write_LoopyLoop(1)
API.Write_Doaction_paint(1)

while API.Read_LoopyLoop() do
    ::start::
    drawGUI()
    ThievingLevel = API.XPLevelTable(API.GetSkillXP("THIEVING"))

    if (API.GetGameState() == 1) then
        print("Logged out..")
        API.Write_LoopyLoop(false)
    end

    if findNpc(11294) then
        if ThievingLevel >= 15 then
            printProgressReport()
            idleCheck()
            checkalldoors()
            RandomSleep3(200, 50, 50)

            if ThievingLevel < 35 and doors[1].status and doors[2].status and doors[3].status then
                worldhop()
            end

            if ThievingLevel >= 35 and doors[1].status and doors[2].status and doors[3].status and doors[4].status and doors[5].status and doors[6].status then
                worldhop()
            end

            -- Check and open Door1
            if not doors[1].status then
                print("Door 1 is closed, Trying to open...")
                API.DoAction_Object2(0x31, 0, { door13 }, 50, WPOINT.new(4776, 5917, 0))
                RandomSleep3(700, 50, 50)
                API.WaitUntilMovingEnds()
                RandomSleep3(1400, 200, 200)
            end

            -- Check and open Door2
            if (not doors[2].status and doors[1].status) then
                print("Door 2 is closed, Trying to open...")
                API.DoAction_Object2(0x31, 0, { door13 }, 50, WPOINT.new(4778, 5917, 0))
                RandomSleep3(700, 50, 50)
                API.WaitUntilMovingEnds()
                RandomSleep3(1400, 200, 200)
            end

            -- Check and open Door3
            if (not doors[3].status and doors[1].status and doors[2].status) then
                print("Door 3 is closed, Trying to open...")
                API.DoAction_Object2(0x31, 0, { door13 }, 50, WPOINT.new(4780, 5917, 0))
                RandomSleep3(700, 50, 50)
                API.WaitUntilMovingEnds()
                RandomSleep3(1400, 200, 200)
            end

            -- Check and open Door6
            if ThievingLevel >= 35 and (not doors[6].status and doors[1].status and doors[2].status and doors[3].status) then
                print("Door 6 is closed, Trying to open...")
                API.DoAction_Object2(0x31, 0, { door46 }, 50, WPOINT.new(4780, 5914, 0))
                RandomSleep3(700, 50, 50)
                API.WaitUntilMovingEnds()
                RandomSleep3(1400, 200, 200)
            end

            -- Check and open Door5
            if ThievingLevel >= 35 and (not doors[5].status and doors[1].status and doors[2].status and doors[3].status and doors[6].status) then
                print("Door 5 is closed, Trying to open...")
                API.DoAction_Object2(0x31, 0, { door46 }, 50, WPOINT.new(4778, 5914, 0))
                RandomSleep3(700, 50, 50)
                API.WaitUntilMovingEnds()
                RandomSleep3(1400, 200, 200)
            end

            -- Check and open Door4
            if ThievingLevel >= 35 and (not doors[4].status and doors[1].status and doors[2].status and doors[3].status and doors[6].status and doors[5].status) then
                print("Door 4 is closed, Trying to open...")
                API.DoAction_Object2(0x31, 0, { door46 }, 50, WPOINT.new(4776, 5914, 0))
                RandomSleep3(700, 50, 50)
                API.WaitUntilMovingEnds()
                RandomSleep3(1400, 200, 200)
            end
        end
    end
end
