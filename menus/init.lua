local setmetatable = setmetatable
local print,ipairs  = print,ipairs
local awful     = require( "awful"                   )
local wibox     = require( "wibox"                   )
local beautiful = require( "beautiful"               )
local radical = require("radical")
local menu_timer = require("pretty.menus.timer")
local module = {
	client=            require( "pretty.menus.client" ),
	tag=            require( "pretty.menus.tag" ),
	layout=            require( "pretty.menus.layout" ),
	screen=            require( "pretty.menus.screen" ),
	language=             require( "pretty.menus.language" ),
	application=              require( "pretty.menus.application" ),
	timer=            require( "pretty.menus.timer" )
}

module.popup = function (menu)
	module.timer.create(menu, 2)
	menu.visible = true
end
module.main = function ()
	local menu = radical.context{}
	--items = require("menugen").build_menu()
	--menu:add_items()
	menu = awful.menu.new({ items = require("menugen").build_menu(),
                              theme = { height = 20, width = 200 }})
	
--	menu_timer.attach(menu, 1)
	
	return menu
end
return module
