local setmetatable = setmetatable
local print,ipairs  = print,ipairs
local module = {}
---[[
module.tostringR = function (x)
	local s
	if type(x) == "table" then
		s = "{"
		local i, v = next(x)
		while i do
			s = s .. tostring(i) .. "=" .. module.tostringR(v)
			i, v = next(x, i)
			if i then s = s .. "," end
		end
		return s .. "}"
	end
	if type(x) == "tag" then
		return x.name
	end
	if type(x) == "client" then
		return x.window .. "g=" .. module.tostringR(x:geometry())
	end
	return tostring(x)
end
---]
local debugTabs = 0
module.status = function (func, base_level)
	if base_level == nil then
		base_level = 2
	end
	local level = base_level
	local cont = true
	while cont ~=nil do
		local info = debug.getinfo(level, "S")
		cont = string.find(info.source, "snapshot.lua")
		level = level + 1
	end
	level = level - base_level - 2
	local result = string.rep("\t", level)
	result = result .. "<" .. func
	local info = debug.getinfo(base_level, "Sl")
	result = result .. string.format(" line='%d'", info.currentline)
	result = result .. ">"
	local i = 1
      while true do
        local name, value = debug.getlocal(base_level, i)
        if not name or string.find(name, "temporary") then break end
        result = result .. "\n" .. string.rep("\t", level+1) .. string.format("%s='%s'", name, module.tostringR(value))
     
        i = i + 1
      end
    result =  result .. "\n" .. string.rep("\t", level)
	result = result .. "</" .. func .. ">"
	return result
end
---]]
return setmetatable(module, { __call = function(_, ...) return new(...) end })
