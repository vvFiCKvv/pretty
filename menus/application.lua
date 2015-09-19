local setmetatable = setmetatable
local print,ipairs,table,string,next  = print,ipairs,table,string,next
local awful     = require( "awful"                   )
local wibox     = require( "wibox"                   )
local beautiful = require( "beautiful"               )
local radical = require("radical")
local menu_timer = require("pretty.menus.timer")

local beautiful = require("beautiful")

local module = {}
local index = 1
local  id = {name = 1,  data = 2, icon = 3, command = 3}
local function escape(s)
	s = string.gsub(s, "([&=+%c])", function(c)return string.format("%%%02X", string.byte(c))end)
	return s
end
local applications = require("menugen").build_menu()
module.build_menu = function ()
	local menu = radical.context{}
	
	menu_timer.attach(menu, 1)
	for c, category in pairs(applications) do
		menu:add_item {text=category[id.name] ,sub_menu = function()
			local menu = radical.context{}
			menu_timer.attach(menu, 1)
			for a, app in pairs(category[id.data]) do
				menu:add_item {text=escape(app[id.name]), icon=app[id.icon], button1 = function(_menu,item,mods)
					--index = l
					--menu.items[index].selected = true
					menu:hide()
					awful.util.spawn(app[id.command])
				end}
			end
			return menu
		end}
		
	end
--]]
	return menu
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
