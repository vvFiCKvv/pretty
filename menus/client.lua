local setmetatable = setmetatable
local print,ipairs  = print,ipairs
local awful     = require( "awful"                   )
local wibox     = require( "wibox"                   )
local beautiful = require( "beautiful"               )
local radical = require("radical")
local module = {}
--TODO:update menus
-- menu functions
function new(c)
	local menu = radical.context{}
	menu.style = radical.style.arrow
	menu:add_item{text="Tag",sub_menu = function()
		local subMenu = radical.context{}
		tags = awful.tag.gettags(mouse.screen)
		for t in pairs(tags) do
			tag = tags[t]
			local isTagPartOfC = false
			c_tags = c:tags()
			for i in pairs(c_tags) do
				if c_tags[i] == tags[t] then
					isTagPartOfC = true
				end
			end 
			if not isTagPartOfC or #c_tags > 1 then
				subMenu:add_item {text=tag.name ,sub_menu = function()
					local subMenu = radical.context{}
					if not isTagPartOfC or #c_tags > 1 then
						subMenu:add_item {text="Move", button1 = function(_menu,item,mods)
							awful.client.movetotag(tags[t], c)
							menu.visible = false
						end}
					end
					if not isTagPartOfC then
						subMenu:add_item {text="Add", button1 = function(_menu,item,mods)
							awful.client.toggletag(tags[t], c)
							menu.visible = false
						end}
					end
					if isTagPartOfC and #c_tags > 1 then
						subMenu:add_item {text="Remove", button1 = function(_menu,item,mods)
							awful.client.toggletag(tags[t], c)
							menu.visible = false
						end}
					end
					return subMenu
				 end}
			end
		end
		return subMenu
	end}
	menu:add_item{text="Screen",sub_menu = function()
		local subMenu = radical.context{}
		for s = 1, screen.count() do
			if s~= mouse.screen then
				subMenu:add_item {text="Screen " .. s, button1 = function(_menu,item,mods)
					menu.visible = false
					awful.client.movetoscreen(c, s)
				end}
			end
		end
		return subMenu
	end}
--[[
	menu:add_item {text="Move",button1=function(_menu,item,mods)
		menu.visible = false
		awful.mouse.client.move()
	end}
--TODO fix mousegrabber move resize

	menu:add_item {text="Resize",button1=function(_menu,item,mods)
		menu.visible = false
		awful.mouse.client.resize()
	end}
---]]
	menu:add_item {text="Close",button1=function(_menu,item,mods)
		menu.visible = false
		c:kill()
	end}
	c:connect_signal("unfocus",function()
		menu.visible = false
	end)
	return menu
end
-- }}}
return setmetatable(module, { __call = function(_, ...) return new(...) end })
