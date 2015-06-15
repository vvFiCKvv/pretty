local setmetatable = setmetatable
local print,ipairs  = print,ipairs
local awful     = require( "awful"                   )
local wibox     = require( "wibox"                   )
local beautiful = require( "beautiful"               )
local radical = require("radical")
local menu_timer = require("pretty.menus.timer")
local module = {}

module.tag = function (s, t)
	local menu = radical.context{}
	menu_timer.attach(menu, 1)
	menu:add_item {text="View", sub_menu = function()
		local menu = radical.context{}
		menu_timer.attach(menu, 1)
		
		local isTagPartOfSelected = false
		local tags = awful.tag.selectedlist(s)
		for i in pairs(tags) do
			if tags[i] == t then
				isTagPartOfSelected = true
			end
		end
		if not isTagPartOfSelected then
			menu:add_item {text="Add", button1 = function(_menu,item,mods)
				
				menu:hide()
			end}
		end
		if not isTagPartOfSelected then
			menu:add_item {text="Select", button1 = function(_menu,item,mods)
				
				menu:hide()
			end}
		end
		if isTagPartOfSelected then
			menu:add_item {text="Remove", button1 = function(_menu,item,mods)
				
				menu:hide()
			end}
		end
		return menu
	end}
	if true then
		menu:add_item {text="Rename", button1 = function(_menu,item,mods)
			
			menu:hide()
		end}
	end
	if #t:clients() > 0 then
		menu:add_item {text="Clients" ,sub_menu = function()
			local menu = require("pretty.menus.client").clients(t)
			menu_timer.attach(menu, 1)
			return menu
		end}
	end
	return menu
end
module.tags = function (s)
	local menu = radical.context{}
	menu_timer.attach(menu, 1)
	
	menu.style = radical.style.arrow
	
	local tags = awful.tag.gettags(s)
	for t in pairs(tags) do
		local tag = tags[t]
		menu:add_item {text=tag.name ,sub_menu = function()
			local menu = module.tag(s, tag)
			menu_timer.attach(menu, 1)
			return menu
		 end}
	end
	return menu
end
local function new()
	return module.tags(mouse.screen)
end
return setmetatable(module, { __call = function(_, ...) return new(...) end })
