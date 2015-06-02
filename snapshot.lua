local setmetatable = setmetatable
local print,ipairs  = print,ipairs
local awful     = require( "awful"                   )
local wibox     = require( "wibox"                   )
local beautiful = require( "beautiful"               )
local radical = require("radical")
local module = {}
local implements = {
	screen = function () return {
		tag = {},
		history = {},
		active_tag = nil,
		multi_tag = nil
	} end,
	tag = function () return {
		client = {},
		layout = nil,
		name = ""
	} end,
	history = function () return {
		tag = {},
		max = 10,
		active = 1
	} end,
	client = function (c) return {
		_data = c,
		geometry = {},
		class = "",
		maximized_vertical = nil,
		maximized_horizontal = nil,
		fullscreen = nil,
		get = function (this) return this._data end,
		set = function (this, c) this._data = c end
	} end,
	snapshot = function () return {
		screen = {},
		count = 0
	} end
}
local snapshot = {}
local function new()
	
end

---[[
tostringR = function (x)
	local s
	if type(x) == "table" then
		s = "{"
		local i, v = next(x)
		while i do
			s = s .. tostring(i) .. "=" .. tostringR(v)
			i, v = next(x, i)
			if i then s = s .. "," end
		end
		return s .. "}"
	end
	if type(x) == "tag" then
		return x.name
	end
	if type(x) == "client" then
		return x.window .. "g=" .. tostringR(x:geometry())
	end
	return tostring(x)
end
local debugTabs = 0
function debug_status(func)
	local base_level = 3
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
        result = result .. "\n" .. string.rep("\t", level+1) .. string.format("%s='%s'", name, tostringR(value))
     
        i = i + 1
      end
    result =  result .. "\n" .. string.rep("\t", level)
	result = result .. "</" .. func .. ">"
	print (result)
end
---]]
local print_status = function(func, name, s, t, c, g, options)
	if true then 
		return
	end
	debug_status(func)
end
module.client = {}
module.client.update = function (name, s, t, c, options)
	print_status("client.update", name, s, t, c, c:geometry(),options)
	local tag_data = snapshot[name].screen[s].tag[t.name]
	if snapshot[name].screen[s].multi_tag then
		tag_data = snapshot[name].screen[s].multi_tag
	end
	tag_data.client[c.window] = implements.client(c)
--	tag_data.client[c.window]:set(c)
	tag_data.client[c.window].geometry = c:geometry()
	tag_data.client[c.window].maximized_vertical = c.maximized_vertical
	tag_data.client[c.window].maximized_horizontal = c.maximized_horizontal
	tag_data.client[c.window].fullscreen = c.fullscreen
end
module.client.restore = function (name, s, t, c, options)
	local tag_data = snapshot[name].screen[s].tag[t.name]
	local g = nil
	if snapshot[name].screen[s].multi_tag then
		tag_data = snapshot[name].screen[s].multi_tag
	end
	if tag_data.client[c.window] ~= nil then
		g = tag_data.client[c.window].geometry
		c:geometry(g)
		c.maximized_vertical = tag_data.client[c.window].maximized_vertical
		c.maximized_horizontal = tag_data.client[c.window].maximized_horizontal
		c.fullscreen = tag_data.client[c.window].fullscreen
	end
	print_status("client.restore", name, s, t, c, g,options)
end
module.tag = {}
module.tag.update =  function (name, s, t, options)
	print_status("tag.update", name, s, t, nil, nil,options)
	if snapshot[name] == nil then
		snapshot[name] = implements.snapshot()
	end
	if snapshot[name].screen[s] == nil then
		snapshot[name].screen[s] = implements.screen()
	end
	if snapshot[name].screen[s].tag[t.name] == nil then
		snapshot[name].screen[s].tag[t.name] = implements.tag()
	end
	local tag_data = snapshot[name].screen[s].tag[t.name]
	if snapshot[name].screen[s].multi_tag then
		tag_data = snapshot[name].screen[s].multi_tag
	end
	if options and options.targets and options.targets.client == true then
		local clients = t:clients()
		for c in pairs(clients) do
			module.client.update(name, s, t, clients[c], options)
		end
--		tag_data.client =  t:clients()
	end
	if options and options.targets and options.targets.layout == true then
		tag_data.layout = awful.tag.getproperty(t,"layout")
	end
	if options and options.targets and options.targets.geometry == true then
		local clients = t:clients()
		for c in pairs(clients) do
			module.client.update(name, s, t, clients[c], options)
		end
	end
end
module.tag.get = function (name, s, t, options)
	print_status("tag.get", name, s, t, nil, nil,options)
	local result = nil
	if snapshot[name] == nil 
	or snapshot[name].screen[s] == nil  
	or snapshot[name].screen[s].tag[t.name] == nil then
		return
	end
	local tag_data = snapshot[name].screen[s].tag[t.name]
	if snapshot[name].screen[s].multi_tag then
		tag_data = snapshot[name].screen[s].multi_tag
	end
	if options and options.targets and options.targets.layout == true then
		 result = tag_data.layout
	end
	return result
end
module.tag.restore = function (name, s, t, options)
	print_status("tag.restore", name, s, t, nil, nil,options)
	if snapshot[name] == nil 
	or snapshot[name].screen[s] == nil  
	or snapshot[name].screen[s].tag[t.name] == nil then
		return
	end
	local tag_data = snapshot[name].screen[s].tag[t.name]
	if snapshot[name].screen[s].multi_tag then
		tag_data = snapshot[name].screen[s].multi_tag
	end
	if options and options.targets and options.targets.client == true then
		local clients = tag_data.client
		for i in pairs(clients) do
			local c = (clients[i]):get()
			awful.client.movetotag(t, c)
			awful.client.toggletag(t, c)
		end
	end
	if options and options.targets and options.targets.layout == true  and tag_data.layout ~= nil then
		awful.tag.setproperty(t,"layout", tag_data.layout)
	end
	if options and options.targets and options.targets.geometry == true then
		local clients = t:clients()
		for i in pairs(clients) do
			module.client.restore(name, s, t, clients[i], options)
		end
	end
	if options and options.remove == true then
		if snapshot[name].screen[s].multi_tag then
			snapshot[name].screen[s].multi_tag = nil
		else
			snapshot[name].screen[s].tag[t.name] = nil
		end
	end
end
module.screen = {}
module.screen.update = function (name, s, options)
print_status("screen.update", name, s, t, nil, nil,options)
	if snapshot[name] == nil then
		snapshot[name] = implements.snapshot()
	end
	if snapshot[name].screen[s] == nil then
		snapshot[name].screen[s] = implements.screen()
	end
	if options and options.multi_tag then
		if options.multi_tag[1] == true then
			if snapshot[name].screen[s].multi_tag == nil then
				snapshot[name].screen[s].multi_tag = implements.tag{}
			end
		else
			snapshot[name].screen[s].multi_tag = nil
		end
	end
	if options and options.targets and options.targets.active_tag == true then
		snapshot[name].screen[s].active_tag = awful.tag.selected(s)
	end
	if options and options.targets and options.targets.tags == true then
		local tags = awful.tag.gettags(s)
		for t in pairs(tags) do
			module.tag.update(name, s, tags[t], options)
		end
	end
	if options and options.targets and options.targets.history == true then
		local h = snapshot[name].screen[s].history
		h.tag[h.active] = awful.tag.selectedlist(s)
--		h.tag[h.active] = awful.tag.selected(s)
		h.active = h.active  % h.max + 1
	end
end
module.screen.restore = function (name, s, options)
print_status("screen.restore", name, s, nil, nil, nil,options)
	if options and options.targets and options.targets.active_tag == true then
		awful.tag.setscreen(snapshot[name].screen[s].active_tag, s)
	end
	if options and options.targets and options.targets.tags == true then
--TODO: load tags from snapshot
		local tags = awful.tag.gettags(s)
		for t in pairs(tags) do
			module.tag.restore(name, s, tags[t], options)
		end
		if options and options.remove == true then
			snapshot[name].screen[s] = nil
		end
	end
	if options and options.targets and options.targets.history ~= nil then
		local h = snapshot[name].screen[s].history
		h.active = (h.active - 1 - 1) % h.max + 1
		awful.tag.viewmore(h.tag[h.active], s)
	end
end
module.screen.get = function (name, s, options)
print_status("screen.get", name, s, nil, nil, nil,options)
	local result = nil
	if snapshot[name] == nil or snapshot[name].screen[s] == nil then
		return nil
	end
	if options and options.targets and options.targets.active_tag == true then
		result = snapshot[name].screen[s].active_tag
	end
	if options and options.multi_tag then
		result = not (snapshot[name].screen[s].multi_tag == nil)
	end
		if options and options.targets and options.targets.history ~= nil then
		local h = snapshot[name].screen[s].history
		local i = options.targets.history
		h.active = (h.active + - i - 1) % h.max + 1
		awful.tag.viewmore(h.tag[h.active], s)
	end
	return result
end

module.update = function (name, options)
	for s = 1, screen.count() do -- for each screen 
			module.screen.update(name, s, options)
	end
	snapshot[name].count = snapshot[name].count + 1
end
module.restore = function (name, options)
	for s = 1, screen.count() do -- for each screen 
			module.screen.restore(name, s, options)
	end
	snapshot[name].count = snapshot[name].count -1
end
module.count = function (name)
	if snapshot[name] then
		return snapshot[name].count
	end
	return 0
end
return setmetatable(module, { __call = function(_, ...) return new(...) end })
