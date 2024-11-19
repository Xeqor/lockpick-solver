local Config = require(script.Configurations)
local MiscFunctions = require(script.MiscFunctions)
local Parser = require(script.Parser)

local Inventory = {}
local HP = 100
local CanInteractObjs = {}
local History = {
	["INVENTORY"] = {{}},
	["HP"] = {{100}},
	["CAN_INTERACT_OBJS"] = {{}},
}

local Unlocked = {}
local BadRoutes = {}
local StepCount = 0
local CanInteractCount = 0

local TimeStarted = DateTime.now().UnixTimestampMillis / 1000

local function CanInteract(ID)
	CanInteractCount += 1
	local Properties = Config.MAP[ID]
	
	local Node
	
	for _, _ID in Unlocked do
		if Node then
			Node = Node[_ID]
		else
			Node = BadRoutes[_ID]
		end
		
		if not Node then
			break
		elseif MiscFunctions.LengthOfDict(Node) == 0 then
			return false
		end
	end
	
	if Node and Node[ID] and MiscFunctions.LengthOfDict(Node[ID]) == 0 then
		return false
	end
	
	if Properties.TYPE == "DOOR" then
		for _, Req in Properties.COLOR_COUNT do
			if (Inventory[Req[1]] or 0) < Req[2] then
				return false
			end
		end
	end

	return true
end

local function Interact(ID)
	if Config.DEBUG then
		print(`Interacting with: {ID}`)
	end
	
	local Properties = Config.MAP[ID]
	
	CanInteractObjs[ID] = nil
	Config.MAP[ID].INTERACTED = true
	
	for _ID, _Properties in Config.MAP do
		if not _Properties.REQUIREMENTS or _Properties.INTERACTED 
			or CanInteractObjs[_ID] then
			continue
		end
		
		if table.find(_Properties.REQUIREMENTS, ID) then
			CanInteractObjs[_ID] = true
		end
	end
	
	if Properties.TYPE == "DOOR" then
		for _, Requirement in Properties.COLOR_COUNT do
			Inventory[Requirement[1]] -= Requirement[2]
		end
	elseif Properties.TYPE == "KEY" then
		for _, KeyGiven in Properties.COLOR_COUNT do
			if not Inventory[KeyGiven[1]] then
				Inventory[KeyGiven[1]] = 0
			end
			
			Inventory[KeyGiven[1]] += KeyGiven[2]
		end
	end
	
	if table.find(Config.END_REQUIREMENT, ID) then
		table.insert(Unlocked, ID)
		print(`Time took: {DateTime.now().UnixTimestampMillis / 1000 - TimeStarted}`)
		print("Route found!")
		print(Unlocked)
		print(CanInteractCount)
		print(StepCount)
		print(BadRoutes)
		StepCount = Config.STEPS_LIMIT
	end
end

local function Undo()
	if Config.DEBUG then
		print(`Undo`)
	end
	
	local Node
	
	for Index, ID in Unlocked do
		if Index == #Unlocked then
			if Node then 
				Node[ID] = {}
			else
				BadRoutes[ID] = {}
			end
		else
			if Node then 
				if not Node[ID] then
					Node[ID] = {}
				end
				Node = Node[ID]
			else 
				if not BadRoutes[ID] then
					BadRoutes[ID] = {}
				end
				Node = BadRoutes[ID]
			end
		end
	end
	
	Config.MAP[Unlocked[#Unlocked]]["INTERACTED"] = false
	Unlocked[#Unlocked] = nil
	
	History.INVENTORY[#History.INVENTORY] = nil
	History.HP[#History.HP] = nil
	History.CAN_INTERACT_OBJS[#History.CAN_INTERACT_OBJS] = nil
	Inventory = table.clone(History.INVENTORY[#History.INVENTORY])
	HP = History.HP[#History.HP]
	CanInteractObjs = table.clone(History.CAN_INTERACT_OBJS[#History.CAN_INTERACT_OBJS])
end

local function Initialize()
	if Config.USE_FAST_MAP then
		Config.MAP = Parser.Parse(Config.FAST_MAP)
	end
	
	for ID, Properties in Config.MAP do
		Properties["INTERACTED"] = false
		
		if not Properties.REQUIREMENTS then
			CanInteractObjs[ID] = true
		end
	end
	
 	while true do
		local Moved = false
		StepCount += 1
		
		if StepCount % 50000 == 0 then
			print(`Current step count: {StepCount}`)
			print(CanInteractCount)
			task.wait(0.25)
		end
		
		if StepCount >= Config.STEPS_LIMIT then
			print("Too much steps!")
			return
		end
		
		if Config.DEBUG then
			print("Interactable Objects:", CanInteractObjs)
			warn("Bad Routes:", BadRoutes)
		end
		
		for ID in CanInteractObjs do
			if CanInteract(ID) then
				Moved = true
				Interact(ID)
				table.insert(Unlocked, ID)
				table.insert(History.INVENTORY, table.clone(Inventory))
				table.insert(History.CAN_INTERACT_OBJS, table.clone(CanInteractObjs))
				table.insert(History.HP, HP)
				break
			end
		end	

		if not Moved then
			Undo()
		end
	end
end

Initialize()
