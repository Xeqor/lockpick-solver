local MiscFunctions = {}

function MiscFunctions.DeepCopy(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			v = MiscFunctions.DeepCopy(v)
		end
		copy[k] = v
	end
	return copy
end

function MiscFunctions.IsTableEqual(t1, t2)
	if #t1 ~= #t2 then
		return false
	end

	for i, v in t1 do
		if t2[i] ~= v then
			return false
		end
	end

	return true
end

function MiscFunctions.LengthOfDict(t)
	local count = 0
	for _ in t do
		count += 1
	end
	return count
end

return MiscFunctions
