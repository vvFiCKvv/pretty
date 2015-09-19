local setmetatable = setmetatable
local print,ipairs  = print,ipairs
local awful     = require( "awful"                   )
local wibox     = require( "wibox"                   )
local beautiful = require( "beautiful"               )
local radical = require("radical")
local menu_timer = require("pretty.menus.timer")
local history = require("pretty.history")
local module = {}

module.tag = function (s, t)
	local menu = radical.context{}
	menu_timer.attach(menu, 1)
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
module.tags = function (s, options)
	local menu = radical.context{}
	menu_timer.attach(menu, 1)
	
	menu.style = radical.style.arrow
	local tags = nil
	if options and options.switch == true then
		tags = module.switch.tags
	else
		tags = awful.tag.gettags(s)
	end
	for t in pairs(tags) do
		local tag = tags[t]
		if options and options.switch == true then
			local name = ""
			for i in pairs(tag) do
				name = name .. tag[i].name .. " "
			end
			local item = menu:add_item {text = name , button1 = function(_menu,item,mods)
				module.switch.index = t
				menu:hide()
			end}
			item:connect_signal("mouse::enter", function()
				module.switch.index = t
			end)
		else
			local item = menu:add_item {text=tag.name ,checkable = true, sub_menu = function()
				local menu = module.tag(s, tag)
				menu_timer.attach(menu, 1)
				return menu
			end, button1 = function(_menu,item,mods)
				--module.switch.index = t
				local item = menu._current_item
				item.checked = not item.checked
				awful.tag.viewtoggle(tags[t])
				--menu:hide()
			end}
			item.checked = tags[t].selected
		end
	end
	return menu
end

module.switch = {
	index = 0,
}
module.switch.next = function (delta)
	local t = awful.tag.selected()
	module.switch.index = 0
	module.switch.tags = history.get_tags(mouse.screen, 2)
	if #module.switch.tags < 1 then
		return radical.context{}
	end
	local menu = module.tags(mouse.screen, {snapshots = true, switch = true})
	if delta ~= nil then 
		menu:connect_signal("visible::changed", function()
			if menu.visible == true then
				local menu_start = 1
				local menu_length = #module.switch.tags
				module.switch.index = (module.switch.index - menu_start + delta) % (menu_length)  +  menu_start
				local debug_tags = module.switch.tags
				local debug_index = module.switch.index
				print(require("pretty.debug").status("switch.next", 2))
				menu.items[module.switch.index].selected = true
			else
				local t = module.switch.tags[module.switch.index]
				awful.tag.viewmore(t,mouse.screen)
			end
		end)
	end
	return menu
end

local function new()
	return module.tags(mouse.screen)
end
return setmetatable(module, { __call = function(_, ...) return new(...) end })
