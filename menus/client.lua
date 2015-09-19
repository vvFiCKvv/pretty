local setmetatable = setmetatable
local print,ipairs  = print,ipairs
local awful     = require( "awful"                   )
local cairo     = require( "lgi"              ).cairo
local surface = require("gears.surface")
local wibox     = require( "wibox"                   )
local beautiful = require( "beautiful"               )
local radical = require("radical")
local menu_timer = require("pretty.menus.timer")
local rad_client = require( "radical.impl.common.client")
local history = require("pretty.history")
function get_screenshot(c, size)
	local geom = c:geometry()
    local ratio,h_or_w = geom.width/geom.height,geom.width>geom.height
	if size == nil then
		size = 140
	end
    local w,h,scale = h_or_w and size or (size*ratio),h_or_w and (size*ratio) or size,h_or_w and size/geom.width or size/geom.height
	local w,h,scale = size*ratio, size*ratio, size/geom.height

    -- Create a working surface
    local img = cairo.ImageSurface(cairo.Format.ARGB32, w, h)
    local cr = cairo.Context(img)

    -- Create a mask
    cr:arc(10,10,10,0,math.pi*2)
    cr:fill()
    cr:arc(w-10,10,10,0,math.pi*2)
    cr:fill()
    cr:arc(w-10,h-10,10,0,math.pi*2)
    cr:fill()
    cr:arc(10,h-10,10,0,math.pi*2)
    cr:fill()
    cr:rectangle(10,0,w-20,h)
    cr:rectangle(0,10,w,h-20)
    cr:fill()

    -- Create a matrix to scale down the screenshot
    cr:scale(scale+0.05,scale+0.05)

    -- Paint the screenshot in the rounded rectangle
    cr:set_source_surface(surface(c.content))
    cr:set_operator(cairo.Operator.IN)
    cr:paint()
    return img
end
local module = {}
module.switch = {
	index = 0,
}
module.switch.next = function (delta)
	local t = awful.tag.selected()
	module.switch.index = 0
	module.switch.clients = history.get_clients(awful.tag.selected(), 2)
	if #module.switch.clients < 1 then
		return radical.context{}
	end
	local menu = module.clients(t, {snapshots = true, switch = true})
	if delta ~= nil then 
		menu:connect_signal("visible::changed", function()
			if menu.visible == true then
				local menu_start = 1
				local menu_length = #module.switch.clients
				module.switch.index = (module.switch.index - menu_start + delta) % (menu_length)  +  menu_start
				menu.items[module.switch.index].selected = true
			else
				client.focus = module.switch.clients[module.switch.index]
				if client.focus then
					client.focus:raise()
				end
			end
		end)
	end
	return menu
end

module.clients = function (t, options)
	local menu = radical.context{}
	if options and options.snapshots == true then
		menu.default_width = 300
		menu.item_height=140
		menu.icon_size=140
	end
	menu_timer.attach(menu, 1)
	menu.style = radical.style.arrow
	local clients = nil
	if options and options.switch == true then
		clients = module.switch.clients
	else
		clients = t:clients()
	end
	for c in pairs(clients) do
		local item = nil
		if options and options.switch == true then
			item = menu:add_item {text=clients[c].name, button1 = function(_menu,item,mods)
				module.switch.index = c
				menu:hide()
			end}
			item:connect_signal("mouse::enter", function()
				module.switch.index = c
			end)
		else
			item = menu:add_item {text=clients[c].name, sub_menu = function()
				local menu = module.client(clients[c])
				menu_timer.attach(menu, 1)
				return menu
			end}
		end
		if options and options.snapshots == true then
			item.icon = get_screenshot(clients[c])
		end
		
	end
	return menu
end
module.client = function (c)
	local menu = radical.context{}
	menu_timer.attach(menu, 1)
	
	menu.style = radical.style.arrow
	local tags = awful.tag.gettags(c.screen)
	menu:add_item {text="Move", sub_menu = function()
		local menu = radical.context{}
		menu_timer.attach(menu, 1)
		menu:add_item{text="Tag",sub_menu = function()
			local menu = radical.context{}
			menu_timer.attach(menu, 1)
			for t in pairs(tags) do
				local tag = tags[t]
				local isTagPartOfC = false
				c_tags = c:tags()
				for i in pairs(c_tags) do
					if c_tags[i] == tag then
						isTagPartOfC = true
					end
				end
				local item = menu:add_item {text=tag.name, checkable = true, button1 = function(_menu,item,mods)
					local item = menu._current_item
					item.checked = not item.checked
					awful.client.toggletag(tag, c)
				end}
				item.checked = isTagPartOfC
			end
			return menu
		end}
		menu:add_item{text="Screen",sub_menu = function()
			local menu = radical.context{}
			menu_timer.attach(menu, 1)
			for s = 1, screen.count() do
				if s~= mouse.screen then
					menu:add_item {text="Screen " .. s, sub_menu = function()
						local menu = radical.context{}
						menu_timer.attach(menu, 1)
						menu:add_item {text="Active Tag", button1 = function(_menu,item,mods)
							menu:hide()
							awful.client.movetoscreen(c, s)
						end}
						menu:add_item {text="Same Tags", button1 = function(_menu,item,mods)
							menu:hide()
							awful.client.movetoscreen(c, s)
						end}
						--[[
						menu:add_item {text="Tags", sub_menu = function()
							local menu = radical.context{}
							menu_timer.attach(menu, 1)
							local tags = awful.tag.gettags(s)
							for t in pairs(tags) do
								local tag = tags[t]
								local item = menu:add_item {text=tag.name, checkable = true, button1 = function(_menu,item,mods)
									local item = menu._current_item
									item.checked = not item.checked
								end}
								item.checked = false
							end
							menu:connect_signal("visible::changed", function()
								if menu.visible == false then
									awful.client.movetoscreen(c, s)
									local tags = awful.tag.gettags(s)
									for t in pairs(tags) do
										if menu.items[t].checked then
											awful.client.toggletag(tags[t], c)
										end
									end
								end
							end)
							return menu
						end}
						---]]
						--return menu
					end, button1 = function(_menu,item,mods)
							menu:hide()
							awful.client.movetoscreen(c, s)
					end}
				end
			end
			return menu
		end}
		return menu
	end}

--[[
	menu:add_item {text="Move",button1=function(_menu,item,mods)
		menu:hide()
		--awful.mouse.client.move()
		--mousegrabber.stop()

	end}
	menu:connect_signal("visible::changed", function()
		if menu.visible == false then
			mousegrabber.stop()
		--awful.mouse.client.move()
			local orig = mouse.coords()
			mousegrabber.run(function(_mouse)
				local x = orig.x - _mouse.x
				local y = orig.y - _mouse.y
				awful.client.moveresize(x, y, 0, 0, c)
				return false
			end, "fleur")
		
		end

	end)
--TODO fix mousegrabber move resize

	menu:add_item {text="Resize",button1=function(_menu,item,mods)
		menu:hide()
		--awful.mouse.client.resize()
		awful.client.moveresize(x, y, w, h, c)
	end}
---]]
	menu:add_item {text="Close",button1=function(_menu,item,mods)
		menu:hide()
		c:kill()
	end}
	--menu_timer
	return menu
end
local function new(c)
	return module.client(c)
end
-- }}}
return setmetatable(module, { __call = function(_, ...) return new(...) end })
