local setmetatable = setmetatable
local print,ipairs  = print,ipairs
local awful     = require( "awful"                   )
local wibox     = require( "wibox"                   )
local beautiful = require( "beautiful"               )
local radical = require("radical")
local module = {}
module.widget = {}
--- Create a new maximize button for a client.
-- @param c The client for which the button is wanted.
module.widget.maximizedbutton = function(c)
    local widget = titlebar.widget.button(c, "maximized", function(c)
        return c.maximized_horizontal or c.maximized_vertical
    end, function(c, state)
        c.maximized_horizontal = not state
        c.maximized_vertical = not state
    end)
    c:connect_signal("property::maximized_vertical", widget.update)
    c:connect_signal("property::maximized_horizontal", widget.update)
    return widget
end
local function new(c, menu)
	local titlebars_enabled = beautiful.titlebar_enabled == nil and true or beautiful.titlebar_enabled
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
--TODO: Add more functionality
        -- buttons for the titlebar
--TODO: on mouse grab disable maximization
        local buttons = awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end)
                )
		local infoBox = {}
		infoBox.textbox = wibox.widget.textbox()
		infoBox.reset_text = function(this)
			local infoString = "" .. c.window
			--[[
			local space = ""
			for k,v in ipairs(c:tags()) do
				if infoString ~= "" then
					space = ", "
				end
				infoString = infoString .. space .. v.name
			end
			---]]
			this:set_text(infoString)
		end
		infoBox.set_text = function(this, text)
			infoString = " < "
			infoString = infoString .. text
			infoString = infoString .. " > "
			this.textbox:set_text(infoString)
		end
		infoBox:reset_text()
		c:connect_signal("tagged",function()
			infoBox:reset_text()
		end)
		c:connect_signal("untagged",function()
			infoBox:reset_text()
		end)
		-- Widgets that are aligned to the left
		local left_layout = wibox.layout.fixed.horizontal()
		widget = awful.titlebar.widget.floatingbutton(c)
		widget:set_tooltip("Floating")
		widget:connect_signal("mouse::enter",function()
			infoBox:set_text("Floating")
		end)
		widget:connect_signal("mouse::leave",function()
			infoBox:reset_text()
		end)
		left_layout:add(widget)
		
		widget = awful.titlebar.widget.stickybutton(c)
		widget:set_tooltip("Sticky")
		widget:connect_signal("mouse::enter",function()
			infoBox:set_text("Sticky")
		end)
		widget:connect_signal("mouse::leave",function()
			infoBox:reset_text()
		end)
		left_layout:add(widget)
		left_layout:add(infoBox.textbox)
		
        -- The title goes in the middle
        local middle_layout = wibox.layout.flex.horizontal()
		if beautiful.titlebar_disable_icon == false then
			local icon = awful.titlebar.widget.iconwidget(c)
			middle_layout:add(icon)
		end
		local title = wibox.widget.textbox()
		local function update()
			if c~=nil and c.name~=nil then
					title:set_text(" " .. c.class ..": " .. c.name or "<unknown>")
			end
		end
		c:connect_signal("property::name", update)
		update()
		if menu then
			title:set_menu(menu,3)
		end
		
        title:set_align("center")
        middle_layout:add(title)
        middle_layout:buttons(buttons)

		-- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        
        widget = awful.titlebar.widget.ontopbutton(c)
        widget:set_tooltip("On Top")
		widget:connect_signal("mouse::enter",function()
			infoBox:set_text("On Top")
		end)
		widget:connect_signal("mouse::leave",function()
			infoBox:reset_text()
		end)
        right_layout:add(widget)
        
		widget = awful.titlebar.widget.maximizedbutton(c)
		widget:set_tooltip("Maximize")
		widget:connect_signal("mouse::enter",function()
			infoBox:set_text("Maximize")
		end)
		widget:connect_signal("mouse::leave",function()
			infoBox:reset_text()
		end)
        right_layout:add(widget)
        
		widget = awful.titlebar.widget.closebutton(c)
		widget:set_tooltip("Close")
		widget:connect_signal("mouse::enter",function()
			infoBox:set_text("Close")
		end)
		widget:connect_signal("mouse::leave",function()
			infoBox:reset_text()
		end)
        right_layout:add(widget)
		
        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_right(right_layout)
        layout:set_middle(middle_layout)
        layout:set_left(left_layout)

		awful.titlebar(c,{size=16}):set_widget(layout)
        
        local buttons = awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                )
        local middle_layout = wibox.layout.flex.horizontal()
        middle_layout:buttons(buttons)
        local layout = wibox.layout.align.horizontal()
         layout:set_middle(middle_layout)
        local size = 4
        titlebar = awful.titlebar(c,{size=size,position="bottom"})
        titlebar:set_widget(layout)
        titlebar:connect_signal("mouse::enter",function()
			infoBox:set_text("Resize")
		end)
		titlebar:connect_signal("mouse::leave",function()
			infoBox:reset_text()
		end)
		titlebar = awful.titlebar(c,{size=size,position="left"})
        titlebar:set_widget(layout)
        titlebar:connect_signal("mouse::enter",function()
			infoBox:set_text("Resize")
		end)
		titlebar:connect_signal("mouse::leave",function()
			infoBox:reset_text()
		end)
		titlebar = awful.titlebar(c,{size=size,position="right"})
        titlebar:set_widget(layout)
        titlebar:connect_signal("mouse::enter",function()
			infoBox:set_text("Resize")
		end)
		titlebar:connect_signal("mouse::leave",function()
			infoBox:reset_text()
		end)
    end
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
