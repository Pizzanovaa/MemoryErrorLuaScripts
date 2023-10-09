local API = require("api")
local UTILS = require("utils")

MAX_IDLE_TIME_MINUTES = 4
afk = os.time()
local USERNAME_BOX_VARBIT_STR = "00000000000000000000000001100100"
local PASSWORD_BOX_VARBIT_STR = "00000000000000000000000001100101"
local INVALID_BOX_VARBIT_STR = "00000000000000000000000001100110"
local CURSOR_LOCATION_VARBIT_ID = 174
local BACKSPACE_KEY = 8
local USERNAME = false
local PASSWORD = false
local JagexAccount = true -- Autologin function won't be used if true.
local accountusername = "thievesdoors@outlook.co.uk" -- replace with your actual username/email
local passwordstring = "getpickpocketed" -- Replace with your actual password
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
    46, 49, 50, 51, 53, 54, 58, 59, 60, 62, 63, 64, 65, 67, 68, 69, 70, 71, 72, 73, 74, 76, 77, 78, 79,
    82, 83, 85, 88, 89, 91, 92, 97, 98, 99, 100, 103, 104, 105, 106, 116, 117, 119, 123, 124, 134, 138,
    140, 139, 252, 257, 258, 259
}

----------------------------------------LOGIN SHIT-------------------------------------

local specialChars = {
    ["!"] = true, ["@"] = true, ["#"] = true, ["$"] = true, ["%"] = true, ["^"] = true,
    ["&"] = true, ["*"] = true, ["("] = true, [")"] = true, ["_"] = true, ["-"] = true,
    ["+"] = true, ["="] = true, ["{"] = true, ["}"] = true, ["["] = true, ["]"] = true,
    ["|"] = true, ["\\"] = true, [":"] = true, [";"] = true, ['"'] = true, ["'"] = true,
    ["<"] = true, [">"] = true, [","] = true, ["."] = true, ["/"] = true, ["?"] = true, ["~"] = true
}

local function getCursorState()
    cursor_box = tostring(API.VB_GetBits(CURSOR_LOCATION_VARBIT_ID))
    if cursor_box == USERNAME_BOX_VARBIT_STR then
        print("USERNAME_BOX")
        USERNAME = true
        PASSWORD = false
    end
    if cursor_box == PASSWORD_BOX_VARBIT_STR then
        print("PASSWORD_BOX")
        USERNAME = false
        PASSWORD = true
    end
end

local function TypeStringOnKeyboard(inputString)
    for i = 1, #inputString do
        local char = inputString:sub(i, i)
        API.KeyPress_(char)

        if specialChars[char] or char:match("%u") then
            API.RandomSleep2(200, 0, 0)
        end
    end
end

local function getUsernameInterfaceText()
    return API.ScanForInterfaceTest2Get(false,
        {{744, 0, -1, -1, 0}, {744, 26, -1, 0, 0}, {744, 39, -1, 26, 0}, {744, 52, -1, 39, 0},
            {744, 93, -1, 52, 0}, {744, 94, -1, 93, 0}, {744, 96, -1, 94, 0}, {744, 110, -1, 96, 0},
            {744, 111, -1, 110, 0}})[1].textids
end

local function isInvalidDetailsInterfaceVisible()
    local text = API.ScanForInterfaceTest2Get(false,
        {{744, 0, -1, -1, 0}, {744, 197, -1, 0, 0}, {744, 338, -1, 197, 0}, {744, 340, -1, 338, 0},
            {744, 342, -1, 340, 0}, {744, 345, -1, 342, 0}})[1].textids

    return text and text:find("Invalid email or password.")
end

local function clearPass()
    if (API.GetGameState() == 1) then
        if USERNAME then
            API.KeyPress_("\t")
            API.RandomSleep2(600, 200, 200)
        end

        if PASSWORD then
            for i = 1, 40 do
                API.KeyboardPress2(BACKSPACE_KEY, .6, .2)
            end
            API.RandomSleep2(600, 200, 200)
        end
    end
end

--------------------------LOGIN SHIT------------------------------------------------------

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
    IG6.string_value = "-----------------------------------"

    IG7 = API.CreateIG_answer()
    IG7.box_start = FFPOINT.new(5, 5, 0)
    IG7.box_name = "LINE2"
    IG7.colour = ImColor.new(0, 255, 0);
    IG7.string_value = "-----------------------------------"

    IG4 = API.CreateIG_answer()
    IG4.box_start = FFPOINT.new(70, 31, 0)
    IG4.box_name = "TIME"
    IG4.colour = ImColor.new(255, 255, 255);
    IG4.string_value = "[00:00:00]"

    IG_Back = API.CreateIG_answer();
    IG_Back.box_name = "back";
    IG_Back.box_start = FFPOINT.new(0, 0, 0)
    IG_Back.box_size = FFPOINT.new(255, 100, 0)
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
    local numSteps = 8 -- Number of steps to divide the sleep into (To not stop GUI from updating mid-sleep)

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
}

local doorstruetile = {
    { tile = WPOINT.new(4776, 5917, 0) },
    { tile = WPOINT.new(4778, 5917, 0) },
    { tile = WPOINT.new(4780, 5917, 0) },
}

function checkalldoors()
    for i, door in ipairs(doors) do
        door.status = CheckDoorStatus(door.tile)
    end
end

local function calculateDistance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
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
local hasAddedElements = false

while API.Read_LoopyLoop() do
    drawGUI()
    ThievingLevel = API.XPLevelTable(API.GetSkillXP("THIEVING"))

    if ThievingLevel >= 35 and not hasAddedElements then
        table.insert(doors, { tile = WPOINT.new(4776, 5915, 0), status = false })
        table.insert(doors, { tile = WPOINT.new(4778, 5915, 0), status = false })
        table.insert(doors, { tile = WPOINT.new(4780, 5915, 0), status = false })

        table.insert(doorstruetile, { tile = WPOINT.new(4776, 5914, 0) })
        table.insert(doorstruetile, { tile = WPOINT.new(4778, 5914, 0) })
        table.insert(doorstruetile, { tile = WPOINT.new(4780, 5914, 0) })

        hasAddedElements = true  -- Set the flag to true to prevent further additions
    end

    if (API.GetGameState() == 1 and not JagexAccount) then

        getCursorState()

        local usernametext = getUsernameInterfaceText()

        if (isInvalidDetailsInterfaceVisible()) then
            API.KeyPress_("\27")
            API.RandomSleep2(50, 50, 50)
            clearPass()
        end

        if USERNAME then
            if usernametext == accountusername then
                print("Username correct")
                API.KeyPress_("\t")
                API.RandomSleep2(200, 200, 200)
            elseif usernametext == "" then
                TypeStringOnKeyboard(accountusername)
                API.RandomSleep2(200, 0, 0)
            elseif usernametext ~= "" and usernametext ~= accountusername then
                print("Random stuff, pressing backspace")
                for i = 1, 40 do
                    API.KeyboardPress2(BACKSPACE_KEY, .6, .2)
                end
                API.RandomSleep2(5, 0, 0)
            else
                print("Broke")
                API.Write_LoopyLoop(false)
            end
        end

        if PASSWORD then
            TypeStringOnKeyboard(passwordstring)
            API.RandomSleep2(200, 0, 0)

            if usernametext == accountusername then
                API.KeyPress_("\n")
                API.RandomSleep2(200, 0, 0)
            else
                API.KeyPress_("\t")
                API.RandomSleep2(200, 0, 0)
            end
        end
    end

    if (API.GetGameState() == 1 and JagexAccount) then
        API.Write_LoopyLoop(false)
    end

    if (API.GetGameState() == 2) then
        API.KeyPress_(" ")
        API.RandomSleep2(200, 200, 200)
    end

    if findNpc(11294) then
        if ThievingLevel >= 15 then
            printProgressReport()
            idleCheck()

            if ThievingLevel < 35 and doors[1].status and doors[2].status and doors[3].status then
                worldhop()
            end

            if ThievingLevel >= 35 then
                if doors[1].status and doors[2].status and doors[3].status and doors[4].status and doors[5].status and doors[6].status then
                    worldhop()
                end
            end

            -- Get the player's coordinates
            local player = API.PlayerCoord()

            -- Find the closest door to the player
            local closestDoor = nil
            local closestDistance = math.huge 
            local doorId = nil
            local closestDoorIndex = nil

            for i, door in ipairs(doors) do
                checkalldoors()
                local distance = calculateDistance(player.x, player.y, doorstruetile[i].tile.x, doorstruetile[i].tile.y)
                if not door.status and distance < closestDistance then
                    closestDistance = distance
                    closestDoor = door
                    doorId = (i <= 3) and door13 or door46 -- Determine the door ID based on position
                    closestDoorIndex = i -- Store the closest door's index
                end
            end

            if closestDoor then
                print("Door " .. closestDoorIndex .. " is closed, Trying to open...")
                API.DoAction_Object2(0x31, 0, { doorId }, 50, doorstruetile[closestDoorIndex].tile)
                RandomSleep3(600, 200, 200)
                API.WaitUntilMovingEnds()
                RandomSleep3(1100, 200, 200)
            end
        end
    end
end

