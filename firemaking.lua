--[[
#Script Name:   <firemaking.lua>
# Description:  <Burns logs on a brazier.>
# Autor:        <Pizzanova>
# Version:      <1.1>
# Datum:        <06.10.2023>
--]]



local API = require("api")
local UTILS = require("utils")
local LogsInBank = true
local bankid = 79036
local brazierid = 106601
local startTime = os.time()
local startXp = API.GetSkillXP("FIREMAKING")
local logsburnt, fail = -1, 0

------------------CHANGE THESE TO YOUR SETTINGS---------------------------------
local logid = 1519 -- Willow Logs ID
local logsname = "Willow logs"
local MAXNOXPTIME = 120 -- 120 seconds of no xp will stop the script.
---MAXNOXPTIME is what im using for the amount of time it will wait for a brazier until i add an brazier renewel function (no plans too)
--------------------------------------------------------------------------------


local bankstatus = false
local brazierstatus = false
local skillxpsold = 0
local burninglogs = false
local lastXpDropTime = os.time()
MAX_IDLE_TIME_MINUTES = 4
afk = os.time()


-- Format script elapsed time to [hh:mm:ss]
local function formatElapsedTime(startTime)
    local currentTime = os.time()
    local elapsedTime = currentTime - startTime
    local hours = math.floor(elapsedTime / 3600)
    local minutes = math.floor((elapsedTime % 3600) / 60)
    local seconds = elapsedTime % 60
    return string.format("[%02d:%02d:%02d]", hours, minutes, seconds)
end

local function checkbank()

items = API.FetchBankArray()
for k, v in pairs(items) do
    if v.itemid1 == logid then
        print("Found: " .. v.itemid1_size .. " logs.")
		if(v.itemid1_size > 0) then
		LogsInBank = true
		return
		else
		print("out of logs..")
		LogsInBank = false
		DoAction_Interface(0x24,0xffffffff,1,1433,68,-1,5392);
		API.Write_LoopyLoop(false)
		end
    else
	LogsInBank = false
	end
end

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
    local currentXp = API.GetSkillXP("FIREMAKING")
    local elapsedMinutes = (os.time() - startTime) / 60
    local diffXp = math.abs(currentXp - startXp);
    local xpPH = round((diffXp * 60) / elapsedMinutes);
    local logsburntPH = round((logsburnt * 60) / elapsedMinutes);
    local time = formatElapsedTime(startTime)
    IG.string_value = "Firemaking XP : " .. formatNumberWithCommas(diffXp) .. " (" .. formatNumberWithCommas(xpPH) .. ")"
    IG2.string_value = "  Logs Burnt : " .. formatNumberWithCommas(logsburnt) .. " (" .. formatNumberWithCommas(logsburntPH) .. ")"
    IG4.string_value = time
	IG5.string_value = "Brazier Active : " .. tostring(brazierstatus) .. " "
	IG6.string_value = "Burning Logs : " .. tostring(burninglogs) .. " "
    if final then
        print(os.date("%H:%M:%S") .. " Script Finished\nRuntime : " .. time .. "\nFiremaking XP : " .. formatNumberWithCommas(diffXp) .. " \nBowlogsburnt : " .. formatNumberWithCommas(logsburnt))
    end
end

local function setupGUI()
    IG = API.CreateIG_answer()
    IG.box_start = FFPOINT.new(15, 40, 0)
    IG.box_name = "FIREMAKING"
    IG.colour = ImColor.new(255, 255, 255);
    IG.string_value = "Firemaking XP : 0 (0)"

    IG2 = API.CreateIG_answer()
    IG2.box_start = FFPOINT.new(1, 55, 0)
    IG2.box_name = "LOGSBURNTT"
    IG2.colour = ImColor.new(255, 255, 255);
    IG2.string_value = "  Logs Burnt : 0 (0)"

    IG3 = API.CreateIG_answer()
    IG3.box_start = FFPOINT.new(40, 5, 0)
    IG3.box_name = "TITLE"
    IG3.colour = ImColor.new(0, 255, 0);
    IG3.string_value = "- Firemaker v1.0 -"

    IG4 = API.CreateIG_answer()
    IG4.box_start = FFPOINT.new(70, 21, 0)
    IG4.box_name = "TIME"
    IG4.colour = ImColor.new(255, 255, 255);
    IG4.string_value = "[00:00:00]"
 
    IG5 = API.CreateIG_answer()
    IG5.box_start = FFPOINT.new(15, 70, 0)
    IG5.box_name = "BANK"
    IG5.colour = ImColor.new(255, 255, 255);
    IG5.string_value = "Bank: False"
	
	IG6 = API.CreateIG_answer()
    IG6.box_start = FFPOINT.new(15, 85, 0)
    IG6.box_name = "BRAZIER"
    IG6.colour = ImColor.new(255, 255, 255);
    IG6.string_value = "Brazier: false."
	
    IG_Back = API.CreateIG_answer();
    IG_Back.box_name = "back";
    IG_Back.box_start = FFPOINT.new(0, 0, 0)
    IG_Back.box_size = FFPOINT.new(235, 120, 0)
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
      
local function findBank()
    local objs = API.ReadAllObjectsArray(true, 0)
    for _, obj in pairs(objs) do
        if obj.Id == bankid then
		    bankstatus = true
            return true
        end
    end
	  bankstatus = false
    return false
end

local function fireSpirits() -- collect fire spirits
    DoAction_NPC(0x29,3120,{15451},50);
    API.RandomSleep2(500, 1000, 750)
end

local function findBrazier()
    local objs = API.ReadAllObjectsArray(true, 0)
    for _, obj in pairs(objs) do
        if obj.Id == brazierid then
		    brazierstatus = true
            return true
        end
    end
	 brazierstatus = false
    return false
end

local function findNpc(npcid, distance)
    local distance = distance or 20
    return #API.GetAllObjArrayInteract({ npcid }, distance, 1) > 0
end

local function burnlogs()
if not (burninglogs) then
API.DoAction_Object1(0x29,0,{ brazierid },50);
 API.RandomSleep2(700,100,100)
 burninglogs = true
 end
 end

local function openbank()
 API.DoAction_Object1(0x2e, 0, { bankid }, 50)
 API.RandomSleep2(700,100,100)
end






while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------
   drawGUI()
   idleCheck() 
   findBank()
   findBrazier()
   skillxps = API.GetSkillXP("FIREMAKING")
   local currentTime2 = os.time()   
   
   
   if API.GetGameState() == 2 or API.GetGameState() == 1 then
	print("Gamestate 2or1 stopping script")
	 API.DoAction_Interface(0x24,0xffffffff,1,1433,68,-1,5392)
     API.Write_LoopyLoop(false)
   end
	  
   
   if (currentTime2 - lastXpDropTime > MAXNOXPTIME) then
   print("" .. MAXNOXPTIME .. " seconds since xp drop stopping script")
   DoAction_Interface(0x24,0xffffffff,1,1433,68,-1,5392);
   API.Write_LoopyLoop(false)
   end
   
   if (skillxps ~= skillxpsold) then
   skillxpsold = skillxps
   logsburnt = logsburnt+1
   fail = 0
   local currentTime = os.time()
   local timeElapsed = currentTime - lastXpDropTime
   -- print("Time since last XP drop: " .. timeElapsed .. " seconds")
   lastXpDropTime = currentTime
   else
   fail = fail+1
   end
   
    if findNpc(15451) then
	fireSpirits()
	API.RandomSleep2(300,50,50)
	end
	
   if(burninglogs and API.InvItemcount_1(logid) < 1) then
   burninglogs = false
   end
   
    if(burninglogs and fail > 6) then
	burninglogs = false
	end
      
	  
	  if(API.BankOpen2()) then
	  checkbank()
	  API.RandomSleep2(50,50,50)
	  if(LogsInBank) then
	  API.DoAction_Interface(0x24,0xffffffff,1,517,119,1,5392);
	  API.RandomSleep2(1200,300,300)
	  LogsInBank = false
	  else
	  print("No Logs left in bank...")
	  DoAction_Interface(0x24,0xffffffff,1,1433,68,-1,5392);
	  API.Write_LoopyLoop(false)
	  end
	  end
   
      if not (burninglogs) then
      if(bankstatus and brazierstatus and API.InvItemcount_1(logid) > 0) then
	  API.RandomSleep2(100,100,100)
	  burnlogs()
	  end
	  end
	  
	  if(bankstatus and brazierstatus and API.InvItemcount_1(logid) < 1) then
	  API.RandomSleep2(100,100,100)
      openbank()	
	  end
	  
	  if(bankstatus and not brazierstatus) then
      API.RandomSleep2(100,100,100)
	  end
	

    ::continue::
    printProgressReport()
    API.RandomSleep2(600, 400, 200)

end----------------------------------------------------------------------------------
