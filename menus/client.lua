local setmetatable = setmetatable
local print,ipairs  = print,ipairs
local awful     = require( "awful"                   )
local wibox     = require( "wibox"                   )
local beautiful = require( "beautiful"               )
local radical = require("radical")
local menu_timer = require("pretty.menus.timer")
local module = {}
--TODO:update menus
-- menu functions
module.clients = function (t)
	local menu = radical.context{}
	menu_timer.attach(menu, 1)
	
	menu.style = radical.style.arrow
	local clients = t:clients()
	for c in pairs(clients) do
		menu:add_item {text=clients[c].name, sub_menu = function()
			local menu = module.client(clients[c])
			menu_timer.attach(menu, 1)
			return menu
		end}
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
				if not isTagPartOfC then
					menu:add_item {text=tag.name, button1 = function(_menu,item,mods)
						awful.client.movetotag(tag, c)
						menu:hide()
					end}
				end
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
						menu:add_item {text="Tags", sub_menu = function()
							local menu = radical.context{}
							menu_timer.attach(menu, 1)
							for t in pairs(tags) do
								local tag = tags[t]
								menu:add_item {text=tag.name, button1 = function(_menu,item,mods)
										menu:hide()
										awful.client.movetoscreen(c, s)
								end}
							end
							return menu
						end}
						return menu
					end}
				end
			end
			return menu
		end}
		return menu
	end}
	
	menu:add_item {text="Add", sub_menu = function()
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
			if not isTagPartOfC then
				menu:add_item {text=tag.name, checkable = true,  button1 = function(_menu,item,mods)
					awful.client.toggletag(tag, c)
					menu:hide()
				end}
			end
		end
		return menu
	end}
	c_tags = c:tags()
	if #c_tags > 1 then
		menu:add_item {text="Remove", sub_menu = function()
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
				if isTagPartOfC then
					menu:add_item {text=tag.name, button1 = function(_menu,item,mods)
						awful.client.toggletag(tag, c)
						menu:hide()
					end}
				end
			end
			return menu
		end}
	end

--[[
	menu:add_item {text="Move",button1=function(_menu,item,mods)
		menu:hide()
		awful.mouse.client.move()
	end}
--TODO fix mousegrabber move resize

	menu:add_item {text="Resize",button1=function(_menu,item,mods)
		menu:hide()
		awful.mouse.client.resize()
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
