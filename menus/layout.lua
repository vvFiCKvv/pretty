local setmetatable = setmetatable
local print,ipairs,table  = print,ipairs,table
local awful     = require( "awful"                   )
local wibox     = require( "wibox"                   )
local beautiful = require( "beautiful"               )
local radical = require("radical")
local menu_timer = require("pretty.menus.timer")
local module = {}
local layouts = {
	awful.layout.suit.tile.top,
	awful.layout.suit.tile,
	awful.layout.suit.tile.left,
}
local layouts_hidden = {}
local layouts_hidden_size = 0
local index = 1

module.init = function(_layous, _hidden)
	layouts = _layous
	if _hidden == nil then
		return
	end
	for h in pairs(_hidden) do
		if _hidden[h] ~= nil then
			layouts_hidden[h] = true
			layouts_hidden_size = layouts_hidden_size + 1
		end
	end
end

module.layout = function(delta)
	local menu = radical.context{}
	
	menu_timer.attach(menu, 1)
	for l in pairs(layouts) do
		if layouts_hidden[l]~= true then
			local layout_name = awful.layout.getname(layouts[l])
			item = menu:add_item {text=layout_name,icon=beautiful["layout_" .. layout_name],  button1 = function(_menu,item,mods)
				index = l
				menu.items[index].selected = true
				menu:hide()
				awful.layout.set(layouts[index])
			end}
		end
	end
	menu:add_widget(radical.widgets.separator())
    menu:add_item {text="edit", sub_menu = module.layout_selection}
	return menu
end

module.layout_selection = function(delta)
	local menu = radical.context{}
	menu_timer.attach(menu, 1)
	for l in pairs(layouts) do 
		local layout_name = awful.layout.getname(layouts[l])
		item = menu:add_item {text=layout_name, checkable = true, icon=beautiful["layout_" .. layout_name],  button1 = function(_menu,item,mods)
			index = l
			--menu.items[index].selected = true
			menu.items[index].checked = not menu.items[index].checked
			if menu.items[index].checked == false then
				if #layouts > layouts_hidden_size + 1 then
					layouts_hidden[l] = true
					layouts_hidden_size = layouts_hidden_size  + 1
				else
					menu.items[index].checked = true
				end

			else
				layouts_hidden[l] = nil
				layouts_hidden_size = layouts_hidden_size - 1
			end
		end}
		item.checked =  not layouts_hidden[l] == true
--TODO: update base menu
	end
	return menu
end

local function new(delta)
	local menu = module.layout(delta)
	if delta ~= nil then 
		menu:connect_signal("visible::changed", function()
			if menu.visible == true then
				local menu_start = 1
				local menu_length = #layouts - layouts_hidden_size
				index = (index - menu_start + delta) % (menu_length)  +  menu_start
				menu.items[index].selected = true
				awful.layout.set(layouts[index])
			end
		end)
	end
	return menu
end
return setmetatable(module, { __call = function(_, ...) return new(...) end })
