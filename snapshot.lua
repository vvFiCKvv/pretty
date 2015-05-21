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
		active_tag = nil,
		multi_tag = nil
	}
	end,
	tag = function () return {
		client = {},
		layout = nil,
		name = ""
	}
	end,
	client = function () return {
		geometry = {},
		class = ""
	}
	end,
	snapshot = function () return {
		screen = {},
		count = 0
	}
	end
}
local snapshot = {}
local function new()
	
end
local print_status = function(func, name, s, t, c, g, options)
	result = "<"
	result = result .. func
	result = result .. "> name:" .. name
	result = result .." screen: " .. s
	if snapshot[name] ~= nil and snapshot[name].screen[s] ~= nil and snapshot[name].screen[s].multi_tag then
		result = result .. " multitag"
	end
	if t ~=nil then
		result = result .." tag: " .. t.name
	end
	if c ~=nil then
		result = result .." client: " .. c.pid
	end
	if g ~=nil then
		result = result ..  g.x .. ", " ..g.y .. ", " .. g.width .. ", " .. g.height
	end
	if options ~=nil and options.targets ~= nil and options.targets.layout then
		result = result .." layout"
	end
	print(result)
end
module.client = {}
module.client.update = function (name, s, t, c, options)
	print_status("client.update", name, s, t, c, c:geometry(),options)
	local tag_data = snapshot[name].screen[s].tag[t.name]
	if snapshot[name].screen[s].multi_tag then
		tag_data = snapshot[name].screen[s].multi_tag
	end
	tag_data.client[c.pid] = implements.client()
	tag_data.client[c.pid].geometry = c:geometry()
end
module.client.restore = function (name, s, t, c, options)
	local tag_data = snapshot[name].screen[s].tag[t.name]
	if snapshot[name].screen[s].multi_tag then
		tag_data = snapshot[name].screen[s].multi_tag
	end
	if tag_data.client[c.pid] ~= nil then
		g = tag_data.client[c.pid].geometry
		c:geometry(g)
	end
	print_status("client.restore", name, s, t, c, g,options)
end
module.tag = {}
module.tag.update =  function (name, s, t, options)
	print_status("tag.update", name, s, t, c, g,options)
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
		tag_data.client =  t:clients()
	end
--TODO: add cords and move clients to client table
--	print("save name: " .. name .. " screen: " .. s .. " tag: " .. t.name .. " client: ", snapshot[name].screen[s].tag[t].client)
	if options and options.targets and options.targets.layout == true then
		tag_data.layout = awful.tag.getproperty(t,"layout")
	end
	if options and options.targets and options.targets.geometry == true then
		clients = t:clients()
		for c in pairs(clients) do
			module.client.update(name, s, t, clients[c], options)
		end
	end
end
module.tag.get = function (name, s, t, options)
	print_status("tag.get", name, s, t, c, g,options)
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
	print_status("tag.restore", name, s, t, c, g,options)
	if snapshot[name] == nil 
	or snapshot[name].screen[s] == nil  
	or snapshot[name].screen[s].tag[t.name] == nil then
		return
	end
	local tag_data = snapshot[name].screen[s].tag[t.name]
	if snapshot[name].screen[s].multi_tag then
		tag_data = snapshot[name].screen[s].multi_tag
	end
	clients = tag_data.client
	if options and options.targets and options.targets.client == true then
		for c in pairs(clients) do
			awful.client.movetotag(t, clients[c])
			awful.client.toggletag(t, clients[c])
		end
	end
	if options and options.targets and options.targets.layout == true  and tag_data.layout ~= nil then
		awful.tag.setproperty(t,"layout", tag_data.layout)
	end
	if options and options.targets and options.targets.geometry == true then
		clients = t:clients()
		for c in pairs(clients) do
			module.client.restore(name, s, t, clients[c], options)
		end
	end
	if options and options.remove == true then
		tag_data = nil
	end
end
module.screen = {}
module.screen.update = function (name, s, options)
print_status("screen.update", name, s, t, c, g,options)
	if snapshot[name] == nil then
		snapshot[name] = implements.snapshot()
	end
	if snapshot[name].screen[s] == nil then
		snapshot[name].screen[s] = implements.screen()
	end
	if options and options.multiTag then
		if options.multiTag[1] == true then
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
		tags = awful.tag.gettags(s)
		for t in pairs(tags) do
			module.tag.update(name, s, tags[t], options)
		end
	end
end
module.screen.restore = function (name, s, options)
print_status("screen.restore", name, s, t, c, g,options)
	if options and options.targets and options.targets.active_tag == true then
		awful.tag.setscreen(snapshot[name].screen[s].active_tag, s)
	end
	if options and options.targets and options.targets.tags == true then
		tags = awful.tag.gettags(s)
		for t in pairs(tags) do
			module.tag.restore(name, s, tags[t], options)
		end
		if options and options.remove == true then
			snapshot[name].screen[s] = nil
		end
	end
end
module.screen.get = function (name, s, options)
print_status("screen.get", name, s, t, c, g,options)
	result = nil
	if snapshot[name] == nil or snapshot[name].screen[s] == nil then
		return nil
	end
	if options and options.targets and options.targets.active_tag == true then
		result = snapshot[name].screen[s].active_tag
	end
	if options and options.multiTag then
		result = not (snapshot[name].screen[s].multi_tag == nil)
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
