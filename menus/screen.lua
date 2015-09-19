local setmetatable = setmetatable
local print,ipairs  = print,ipairs
local awful     = require( "awful"                   )
local wibox     = require( "wibox"                   )
local beautiful = require( "beautiful"               )
local radical = require("radical")
local menu_timer = require("pretty.menus.timer")
local module = {}
module.screen = function(s)
	local menu = radical.context{}
	menu_timer.attach(menu, 1)
	if true then
		menu:add_item {text="Tags", sub_menu = function()
			local menu = require("pretty.menus.tag").tags(s)
			menu_timer.attach(menu, 1)
			return menu
		end}
		menu:add_item {text="Layout", sub_menu = function()
			local menu = require("pretty.menus.layout")()
			menu_timer.attach(menu, 1)
			return menu
		end}
		--[[
		menu:add_item {text="History", sub_menu = function()
			local menu = require("pretty.menus.history")()
			menu_timer.attach(menu, 1)
			return menu
		end}
		---]]
	end
	return menu
end
module.screens = function()
	local menu = radical.context{}
	menu_timer.attach(menu, 1)

	menu.style = radical.style.arrow
	
	for s = 1, screen.count() do
		menu:add_item {text="Screen " .. tostring(s) ,sub_menu = function()
			local menu = module.screen(s)
			menu_timer.attach(menu, 1)
			return menu
		 end}
	end
	return menu
end
local function new()
	return module.screen(mouse.screen)
end
return setmetatable(module, { __call = function(_, ...) return new(...) end })
