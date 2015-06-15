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
	timer=            require( "pretty.menus.timer" )
}
module.popup = function (menu)
	module.timer.create(menu, 2)
	menu.visible = true
end
return module
