local setmetatable = setmetatable
local print,ipairs  = print,ipairs
local awful     = require("awful")
local beautiful = require("beautiful")

local module = {
	widgets = require("pretty.widgets"),
	menus = require("pretty.menus"),
	layout = require("pretty.layout"),
	snapshot = require("pretty.snapshot"),
	history = require("pretty.history"),
	mouse = {},
	client = {
		focus = {
			history = {}
		}
	},
	tag = {
		history = {}
	},
	screen = {},
	layout = {}
}

-- {{{ Functions

--- Move mouse to center of a client
-- @param a client to move the mouse.
module.mouse.moveto_client = function (c, togle_tag_enabled)
	mCords = mouse.coords()
	cCords = c:geometry()
	if mCords.x < cCords.x or mCords.y < cCords.y
	or mCords.x > cCords.x + cCords.width
	or mCords.y > cCords.y + cCords.height then
		x0 = cCords.x + cCords.width/2
		y0 = cCords.y + cCords.height/2
		mouse.coords({x = x0, y = y0})
	end
	if togle_tag_enabled and c:isvisible() == false then
		awful.tag.viewmore(c:tags())
	end
end


module.client.maximize = function(c, status, orientation, filter)
	if filter == nil then
		filter = "normal"
	end
	if c.type ~= filter and filter~="all" then
		return
	end
	if orientation == nil then 
		orientation = "both"
	end
	if status == nil then
		local t = awful.tag.selected()
		if awful.tag.getproperty(t,"max_layout") ~= true then
			return
		end
		status = true
	end
	c:disconnect_signal("property::maximized_vertical", module.tag.max_toggle)
	if orientation == "horizontal" or orientation == "both" then
		if status == "toggle" then
			c.maximized_horizontal = not clients[c].maximized_horizontal
		else
			c.maximized_horizontal = status
		end
	end
	if orientation == "vertical" or orientation == "both" then
		if status == "toggle" then
			c.maximized_vertical = not clients[c].maximized_vertical
		else
			c.maximized_vertical = status
		end
	end
	if status == false then
		c.fullscreen = false
	end
	if orientation == "both" and status == true then
		c:connect_signal("property::maximized_vertical", module.tag.max_toggle)
	end
end

--- view only the tags the given/active client has
module.tag.view_client = function (c)
	-- mouse.screen fails if a tag has none clients.
	local s = mouse.screen
	if c == nil then
		c = awful.mouse.client_under_pointer() -- get the client under the mouse
	end
	if c ~=nil then -- view only the tag witch the client under the mouse is
		awful.tag.viewmore(c:tags(),s)
		if client.focus then
			client.focus:raise() -- focus to the client
		end
	else -- Screen has none clients
		local tags = awful.tag.gettags(s) -- all tags of current screen
		awful.tag.viewonly(tags[1],s) -- view 1st tag
	end
end
--- toggle active's screen tags between all tags and tags where focus client is
module.tag.viewall_toggle = function ()
--TODO: use lain.layout.uselessfair
--TODO: rewrite using snapshot
	-- mouse.screen fails if a tag has none clients.
	local s = mouse.screen
	local tags = awful.tag.gettags(s) -- all tags of current screen
	local selectedTags = awful.tag.selectedlist(s) -- get the tags witch are selected
	if #tags==#selectedTags then -- all tags of the current screen are selected
		module.tag.view_client()
	else -- select all the tags of the current screen
		awful.tag.viewmore(tags,s)
		local currentLayout = awful.layout.get() -- get the current layout
		if currentLayout == awful.layout.suit.floating then
			local t=awful.tag.selected() -- get the 1st selected tag
			module.layout.floating_toggle(s,t)
		end
		tags = awful.tag.gettags(s)
		for t in pairs(tags) do
			module.tag.max_toggle(false, tags[t])
		end
	end
end
function signal_tag_sync()
	local active_tags = awful.tag.selectedlist(mouse.screen)
	for s = 1, screen.count() do
		screen[s]:disconnect_signal("tag::history::update", signal_tag_sync)
		if s ~= mouse.screen then
			local tags = awful.tag.gettags(s)
			awful.tag.viewnone(s)
			for t in pairs(active_tags) do
				i = awful.tag.getidx(active_tags[t])
				awful.tag.viewtoggle(tags[i])
			end
			-- sync screen tag history
			module.history.signal_tag_change(nil, s)
		end
		screen[s]:connect_signal("tag::history::update", signal_tag_sync)
	end
end
local tag_sync_status = false
module.tag.sync_toggle = function (status)
	if status == nil then
		tag_sync_status = not tag_sync_status
	else
		tag_sync_status = status
	end
	if tag_sync_status == true then
		signal_tag_sync()
	else
		for s = 1, screen.count() do
			screen[s]:disconnect_signal("tag::history::update", signal_tag_sync)
		end
	end
end
module.tag.max_toggle = function (status, t)
	if t == nil then
		t = awful.tag.selected()
	end
	if status == nil then
		status = false
	end
	if status == "toggle" then
		status = not awful.tag.getproperty(t,"max_layout")
	end
	if status ~= true and status ~=false then
		status = false
	end
	awful.tag.setproperty(t, "max_layout", status)
	if status then
		-- prevent double connection
		client.disconnect_signal("focus", module.client.maximize)
		client.connect_signal("focus", module.client.maximize)
		if client.focus then
			client.focus:emit_signal("focus")
			client.focus:raise()
		end
	else
--		client.disconnect_signal("focus", module.client.maximize)
		local clients = t:clients()
		for c in pairs(clients) do
			module.client.maximize(clients[c],false)
		end
	end
end

module.tag.viewall_screens_toggle = function ()
	if snapshot.count("viewall_screens_toggle") == 0 then
		snapshot.update("viewall_screens_toggle", {targets = {client = true, tags = true, geometry = true}})
		module.screen.move_all_clients()
		module.tag.viewall_toggle()
	else
--TODO: focus client and client's tag, move mouse to client's screen or move screens to mouse
		local c = awful.mouse.client_under_pointer()
		module.tag.viewall_toggle()
		local s0 =  mouse.screen
		snapshot.restore("viewall_screens_toggle", {remove = true, targets = {client = true, tags = true, geometry = true}})
		if c ~= nil then
			module.mouse.moveto_client(c,true)
		end
		local s1 =  mouse.screen

--		module.screen.toggle(s0 - s1)
		
--		awful.tag.viewmore(c:tags())
		if c ~= nil then
			module.mouse.moveto_client(c, true)
		end
	end
end
--- move all clients to the active screen
module.screen.move_all_clients = function ()
--TODO: use awful.screen getbycoord (x, y, default)	 Return Xinerama screen number corresponding to the given (pixel) coordinates.
	local activeScreen =  mouse.screen
	local activeScreenTags = awful.tag.gettags(s) -- all tags of current screen
	for s = 1, screen.count() do -- for each screen 
		if s ~= activeScreen then -- except active screen
			tags = awful.tag.gettags(s) -- all tags of current screen
			for t in pairs(tags) do
				local clients = tags[t]:clients()
				for c in pairs(clients) do
					if t <= #activeScreenTags and false then -- move the clients to corresponding tags
						awful.client.movetotag(activeScreenTags[t], clients[c])
						awful.client.toggletag(activeScreenTags[t], clients[c])
					else -- move clients to active tag
						awful.client.movetoscreen(clients[c], activeScreen)
					end
				end
			end
		end
	end
end
--- toggle screens
-- @param index how many times it will move, < 0 for counter-clock wise > 0 for clock wise
module.screen.toggle = function (index)
	if index == 0 then
		return 
	end
	if index > 0 then
		return module.screen.toggle(index - screen.count())
	end
	local firstScreenTags =  awful.tag.gettags(1) -- all tags of 1st screen
	local selectedTagsList = {} -- a list of selected tags list per screen
	table.insert(selectedTagsList, awful.tag.selectedlist(1)) -- add selected tags of 1st screen
	for s = 2, screen.count() do -- for each screen from 2nt to last move tags and selected tags to the previous screen
		local tags = awful.tag.gettags(s) -- all tags of current screen
		table.insert(selectedTagsList, awful.tag.selectedlist(s)) -- add selected tags list of current screen
		for t in pairs(tags) do -- for each tag
			awful.tag.setscreen(tags[t],s - 1) -- move tags to previous screen
		end
	end
	-- move first screen backup to the last one
	for t in pairs(firstScreenTags) do -- for each tag
			awful.tag.setscreen(firstScreenTags[t], screen.count())  -- move tags to last screen
	end
	-- restore selected tags values
	for s in pairs(selectedTagsList) do -- for each screen
		if selectedTagsList[s] ~=nil then --move selected tags list to previous screen
			awful.tag.viewmore(selectedTagsList[s], ((s - 2) % screen.count())+1) -- simple maths, not counting from 0
		end
	end
	if index ~= -1 then
		module.screen.toggle(index + 1)
	end
end

module.layout.floating_toggle = function (s,t)
	if s == nil then
		s = mouse.screen
	end
	if t == nil then
		t = awful.tag.selected()
	end
	if awful.tag.getproperty(t,"layout") == awful.layout.suit.floating then
		if awful.layout.multi_tags then
--TODO: multi_tag
--			awful.layout.set(awful.layout.multi_tags.last_layout)
		else
			snapshot.tag.restore("floating_toggle", s, t, {remove = true, targets = {layout = true}})
		end
	else
		snapshot.tag.update("floating_toggle",s, t, {targets = {layout = true}})
		awful.layout.set(awful.layout.suit.floating, t)
	end
--[[	if snapshot.count("floating_toggle") == 0 then
		snapshot.tag.update("floating_toggle",s, t {targets = {layout = true}})
	else
		snapshot.tag.restore("floating_toggle", s, t, {remove = true, targets = {layout = true}})
	end
---]]
end



-- No border for maximized clients
client.connect_signal("focus", function(c)
	if c.maximized_horizontal == true and c.maximized_vertical == true then
		c.border_color = beautiful.border_normal
	else
		c.border_color = beautiful.border_focus
	end
end)
client.connect_signal("unfocus", function(c)
	c.border_color = beautiful.border_normal
end)
-- }}}

-- {{{ Arrange signal handler
for s = 1, screen.count() do screen[s]:connect_signal("arrange", function ()
        local clients = awful.client.visible(s)
        local layout  = awful.layout.getname(awful.layout.get(s))
        if #clients > 0 then -- Fine grained borders and floaters control
            for _, c in pairs(clients) do -- Floaters always have borders
                if awful.client.floating.get(c) or layout == "floating" then
                    c.border_width = beautiful.border_width

                -- No borders with only one visible client
                elseif #clients == 1 or layout == "max" then
                    c.border_width = 0
                else
                    c.border_width = beautiful.border_width
                end
            end
        end
      end)
end


-- }}}
return module
