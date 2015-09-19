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
		history = nil,
		active_tag = nil,
		multi_tag = {
			enabled = false,
			separate = false,
			tag = {}
		}
	} end,
	tag = function () return {
		client = {},
		layout = nil,
		name = "",
		max_layout = false
	} end,
	history = function () return {
		tag = {},
		max = 10,
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


local print_status = function(func, name, s, t, c, g, options)
	if true then
	--if func ~= "client.update" and func ~= "client.restore" then 
		return
	end
	print(require("pretty.debug").status(func, 3))
end
module.client = {}
module.client.update = function (name, s, t, c, options)
	print_status("client.update", name, s, t, c, c:geometry(),options)
	local tag_data = module.tag.get(name, s, t)
	tag_data.client[c.window] = implements.client(c)
--	tag_data.client[c.window]:set(c)
	tag_data.client[c.window].geometry = c:geometry()
	tag_data.client[c.window].maximized_vertical = c.maximized_vertical
	tag_data.client[c.window].maximized_horizontal = c.maximized_horizontal
	tag_data.client[c.window].fullscreen = c.fullscreen
end
module.client.restore = function (name, s, t, c, options)
	local tag_data = module.tag.get(name, s, t)
	local g = nil
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
module.tag.get = function (name, s, t, options)
	print_status("tag.get", name, s, t, nil, nil,options)
	if snapshot[name] == nil then
		snapshot[name] = implements.snapshot()
	end
	if snapshot[name].screen[s] == nil then
		snapshot[name].screen[s] = implements.screen()
	end
	local result = nil
	if snapshot[name].screen[s].multi_tag.enabled then
		if snapshot[name].screen[s].multi_tag.separate then
			if snapshot[name].screen[s].multi_tag.tag[t.name] == nil then
				snapshot[name].screen[s].multi_tag.tag[t.name] = implements.tag()
			end
			result =  snapshot[name].screen[s].multi_tag.tag[t.name]
		else
			if snapshot[name].screen[s].multi_tag.tag[1] == nil then
				snapshot[name].screen[s].multi_tag.tag[1] = implements.tag()
			end
			result =  snapshot[name].screen[s].multi_tag.tag[1]
		end
	else
		if snapshot[name].screen[s].tag[t.name] == nil then
			snapshot[name].screen[s].tag[t.name] = implements.tag()
		end
		result = snapshot[name].screen[s].tag[t.name]
	end
	if options and options.targets and options.targets.layout == true then
		result = module.tag.get(name, s, t, nil).layout
	end
	return result
end
module.tag.remove = function (name, s, t, options)
	print_status("tag.remove", name, s, t, nil, nil,options)
	if snapshot[name] == nil then
		return
	end
	if snapshot[name].screen[s] == nil then
		return
	end
	if snapshot[name].screen[s].multi_tag.enabled then
		if snapshot[name].screen[s].multi_tag.separate then
			snapshot[name].screen[s].multi_tag.tag[t.name] = nil
		else
			snapshot[name].screen[s].multi_tag.tag[1] = nil
		end
	else
		snapshot[name].screen[s].tag[t.name] = nil
	end
end

module.tag.update =  function (name, s, t, options)
	print_status("tag.update", name, s, t, nil, nil,options)
	if snapshot[name] == nil then
		snapshot[name] = implements.snapshot()
	end
	if snapshot[name].screen[s] == nil then
		snapshot[name].screen[s] = implements.screen()
	end
	local tag_data = module.tag.get(name, s, t)
	if options and options.targets and options.targets.client == true then
		local clients = t:clients()
		for c in pairs(clients) do
			module.client.update(name, s, t, clients[c], options)
		end
--		tag_data.client =  t:clients()
	end
	if options and options.targets and options.targets.layout == true then
		tag_data.layout = awful.tag.getproperty(t,"layout")
		tag_data.max_layout = awful.tag.getproperty(t, "max_layout")
	end
	if options and options.targets and options.targets.geometry == true then
		local clients = t:clients()
		for c in pairs(clients) do
			module.client.update(name, s, t, clients[c], options)
		end
	end
end

module.tag.restore = function (name, s, t, options)
	print_status("tag.restore", name, s, t, nil, nil,options)
	if snapshot[name] == nil 
	or snapshot[name].screen[s] == nil  
	or snapshot[name].screen[s].tag[t.name] == nil then
		return
	end
	local tag_data = module.tag.get(name, s, t)
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
		awful.tag.setproperty(t, "max_layout", tag_data.max_layout)
	end
	if options and options.targets and options.targets.geometry == true then
		local clients = t:clients()
		for i in pairs(clients) do
			module.client.restore(name, s, t, clients[i], options)
		end
	end
	if options and options.remove == true then
		module.tag.remove(name, s, t, options)
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
		snapshot[name].screen[s].multi_tag.enabled = options.multi_tag.enabled
		snapshot[name].screen[s].multi_tag.separate = options.multi_tag.separate
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
		if snapshot[name].screen[s].history == nil then
			snapshot[name].screen[s].history = implements.history()
		end
		local h = snapshot[name].screen[s].history
		local taglist = awful.tag.selectedlist(s)
		for t in pairs(h.tag) do
			local identical = true
			if #h.tag[t] == #taglist then
				for i in pairs(taglist) do
					if h.tag[t][i] ~= taglist[i] then
						identical = false
						break
					end
				end
			else
				identical = false
			end
			if identical == true then
				table.remove(h.tag, t)
			end
		end
		table.insert(h.tag, 1, taglist)
		if #h.tag > h.max + 1 then
			table.remove(h.tag, h.max)
		end
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
	end
	if options and options.targets and options.targets.history ~= nil then
		local h = snapshot[name].screen[s].history
		awful.tag.viewmore(h.tag[1], s)
		table.remove(h.tag, 1)
	end
	if options and options.remove == true then
		snapshot[name].screen[s] = nil
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
		if i < h.max + 1 then
			result = h.tag[i]
		end
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
