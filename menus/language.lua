local setmetatable = setmetatable
local print,ipairs,table  = print,ipairs,table
local awful     = require( "awful"                   )
local wibox     = require( "wibox"                   )
local beautiful = require( "beautiful"               )
local radical = require("radical")
local menu_timer = require("pretty.menus.timer")
local module = {}
local languages = {
	"us", "el"
}
local command = "setxkbmap "
local index = 1

module.init = function(_languages, _command)
	languages = _languages
	if _command ~= nil then
		command = _command
	end
end

module.language = function(delta)
	local menu = radical.context{}
	
	menu_timer.attach(menu, 1)
	for l in pairs(languages) do
		item = menu:add_item {text=languages[l], button1 = function(_menu,item,mods)
			index = l
			menu.items[index].selected = true
			menu:hide()
			awful.util.spawn(command .. languages[index])
		end}
	end
	return menu
end

local function new(delta)
	local menu = module.language(delta)
	if delta ~= nil then 
		menu:connect_signal("visible::changed", function()
			if menu.visible == true then
				local menu_start = 1
				local menu_length = #languages
				index = (index - menu_start + delta) % (menu_length)  +  menu_start
				menu.items[index].selected = true
				awful.util.spawn(command .. languages[index])
			end
		end)
	end
	return menu
end
return setmetatable(module, { __call = function(_, ...) return new(...) end })
