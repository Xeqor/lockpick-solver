-- Parser for FAST_MAP.

local Parser = {}
local Config = require(script.Parent.Configurations)

function Parser.ConvertType(TypeAbv)
	if TypeAbv == "D" then
		return "DOOR"
	elseif TypeAbv == "K" then
		return "KEY"
	elseif TypeAbv == "ERQ" then
		return "END_REQUIREMENT"
	else
		warn(`Unknown type abbreviation: {TypeAbv}`)
	end
end

function Parser.Parse(FastMap)
	local FinalMap = {}
	local LinesSplit = string.split(FastMap, "\n")
	
	for _, Line in LinesSplit do
		if Line == "" then
			continue
		end
		
		if string.sub(Line, 1, 2) == "--" then
			continue
		end
		
		local Properties = {}
		
		-- Format looks like K|D@2@4 for example
		
		local BarSplit = string.split(Line, "|")
		local AtSplit = string.split(BarSplit[#BarSplit], "@")
		local Type
		
		if #BarSplit ~= 1 then
			Type = Parser.ConvertType(BarSplit[1])
		else
			Type = Parser.ConvertType(AtSplit[1])
		end
		
		if Type == "DOOR" or Type == "KEY" then
			Properties.TYPE = Type
			Properties.COLOR_COUNT = {}

			if #AtSplit ~= 1 then
				Properties.REQUIREMENTS = {}
			end

			for Index = 2, #BarSplit do
				local ColorCount = BarSplit[Index]

				if Index == #BarSplit then
					ColorCount = string.split(ColorCount, "@")[1]
				end

				local SpaceSplit = string.split(ColorCount, " ")

				if #SpaceSplit == 1 then
					table.insert(Properties.COLOR_COUNT, {SpaceSplit[1], 1})
				else
					table.insert(Properties.COLOR_COUNT, {SpaceSplit[1], tonumber(SpaceSplit[2])})
				end
			end

			for Index = 2, #AtSplit do
				table.insert(Properties.REQUIREMENTS, tonumber(AtSplit[Index]))
			end
			
			table.insert(FinalMap, Properties)
		elseif Type == "END_REQUIREMENT" then
			local AtSplit = string.split(Line, "@")
			for Index = 2, #AtSplit do
				table.insert(Config.END_REQUIREMENT, tonumber(AtSplit[Index]))
			end
		end
	end
	
	return FinalMap
end

return Parser
