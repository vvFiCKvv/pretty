local setmetatable = setmetatable
local print,ipairs  = print,ipairs
local awful     = require( "awful"                   )
local wibox     = require( "wibox"                   )
local beautiful = require( "beautiful"               )
local radical = require("radical")
local module = {}
local implements = {
	screen = function () return {
		tag = {}
	}
	end,
	tag = function () return {
		client = {},
		layout = {},
		name = ""
	}
	end,
	client = function () return {
		cords = {},
		name = "",
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
module.tag = {}
module.tag.update =  function (name, s, t, options)
	if snapshot[name] == nil then
		snapshot[name] = implements.snapshot()
	end
	if snapshot[name].screen[s] == nil then
		snapshot[name].screen[s] = implements.screen()
	end
	if snapshot[name].screen[s].tag[t.name] == nil then
		snapshot[name].screen[s].tag[t.name] = implements.tag()
	end
	if options and options.targets and options.targets.client == true then
		snapshot[name].screen[s].tag[t.name].client =  t:clients()
	end
--TODO: add cords and move clients to client table
--	print("save name: " .. name .. " screen: " .. s .. " tag: " .. t .. " client: ", snapshot[name].screen[s].tag[t].client)
	if options and options.targets and options.targets.layout == true then
		snapshot[name].screen[s].tag[t.name].layout = awful.tag.getproperty(t,"layout")
	end
end
module.tag.restore = function (name, s, t, options)
	clients = snapshot[name].screen[s].tag[t.name].client
--	print("restore name: " .. name .. " screen: " .. s .. " tag: " .. t .. " client: ", clients)
	if options and options.targets and options.targets.client == true then
		for c in pairs(clients) do
			awful.client.movetotag(t, clients[c])
			awful.client.toggletag(t, clients[c])
		end
	end
	if options and options.targets and options.targets.layout == true then
		awful.tag.setproperty(t,"layout", snapshot[name].screen[s].tag[t.name].layout)
	end
	if options and options.remove == true then
		snapshot[name].screen[s].tag[t.name] = nil
	end
end
module.screen = {}
module.screen.update = function (name, s, options)
	if snapshot[name] == nil then
		snapshot[name] = implements.snapshot()
	end
	if snapshot[name].screen[s] == nil then
		snapshot[name].screen[s] = implements.screen()
	end
	tags = awful.tag.gettags(s)
	for t in pairs(tags) do
		module.tag.update(name, s, tags[t], options)
	end
end
module.screen.restore = function (name, s, options)
	tags = awful.tag.gettags(s)
	for t in pairs(tags) do
		module.tag.restore(name, s, tags[t], options)
	end
	if options and options.remove == true then
		snapshot[name].screen[s] = nil
	end
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
