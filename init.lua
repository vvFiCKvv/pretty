local setmetatable = setmetatable
local print,ipairs  = print,ipairs
local awful     = require("awful")
local beautiful = require("beautiful")

local module = {
	widgets = require("pretty.widgets"),
	menus = require("pretty.menus"),
	layout = require("pretty.layout"),
	snapshot = require("pretty.snapshot"),
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
--require("pretty.layout")
--TODO: one timer per tag
local switchTimer = { 
	index = 1,
	timer = nil,
	type = nil,
	types = { client = 0, tag = 1, tagScreens = 2 },
	screen = nil,
	tag = nil,
	clear = function (this)
				if this.timer then
					this.timer:stop() -- stop and clear the timer
				end
				this.timer = nil
				this.index = 1
				this.type = nil
				this.screen = nil
				this.tag = nil
			end,
	init = function (this, seconds, type)
		this.timer = timer { timeout = seconds } -- init timer with interval 1 sec
		this.type = type
		this.screen = mouse.screen
		this.tag = awful.tag.selected()
		this.timer:connect_signal("timeout",-- on timeout
			function()
				this:clear()
			end)
	end
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

--- Switch client history backwards.
module.client.focus.history.switch = function (multiple_switch_enabled, mouse_move_enabled)
	if multiple_switch_enabled then
		if switchTimer.type ~= switchTimer.types.client 
		or switchTimer.screen ~= mouse.screen 
		or switchTimer.tag ~= awful.tag.selected() then
			switchTimer:clear()
		end
		if switchTimer.timer == nil then -- FirstTime
			switchTimer:init(1, switchTimer.types.client)
			
		else -- multiple calls 
			switchTimer.timer:stop()
			i = 1 -- count the focus length
			while awful.client.focus.history.get(mouse.screen, i) do
				i = i + 1
			end
			if switchTimer.index < i - 1 then -- increase the index until focus history length
				switchTimer.index = switchTimer.index + 1
			end
			if switchTimer.index > i - 1 then -- if greater than focus history
				switchTimer.index = 1 -- something happened, reset index.
			end
		end
		switchTimer.timer:start()
	else
	switchTimer.index = 1
	end
	c = awful.client.focus.history.get(mouse.screen, switchTimer.index )
	if c then
		client.focus = c
		if mouse_move_enabled then
			module.mouse.moveto_client(c)
		end
	end
	if client.focus then
		client.focus:raise()
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
	if orientation == "both" and status == true then
		c:connect_signal("property::maximized_vertical", module.tag.max_toggle)
	end
end
--- Switch tag history backwards.
--- mouse.screen fails if a tag has none clients.
module.tag.history.switch = function()
	if switchTimer.type ~= switchTimer.types.tag 
	or switchTimer.screen ~= mouse.screen  then
		switchTimer:clear()
	end
	if switchTimer.timer == nil then -- FirstTime
		switchTimer:init(1, switchTimer.types.tag)
		awful.tag.history.restore(mouse.screen, "previous")
	else -- multiple calls 
		switchTimer.timer:stop()
		awful.tag.history.restore(mouse.screen,2)
	end
	awful.tag.history.update(screen[mouse.screen])
	switchTimer.timer:start()
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

module.tag.max_toggle = function(status, t)
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
module.history = {
	options = {
		multi_tag = {
			enabled = true,
			seprate = false,
		},
		layout = {
			unified = false,
		},
		tag = {
			layout = true,
			geometry = true,
		},
		size = 20
	}
}
module.history.signal = {}
module.history.signal_arrange = function ()
	local s = mouse.screen 
	local active_tag = awful.tag.selected(s)
	if active_tag == nil then
		return
	end
	local old_tag = snapshot.screen.get("history_update", s, {targets = {active_tag = true}})
	print("s",s, "old", old_tag.name, "t", active_tag.name)
	if old_tag == active_tag then
		print("signal_arrange")
		snapshot.tag.update("history_update", s, active_tag, {targets = module.history.options.tag})
	end
end

module.history.signal_tag_change =  function ()
	local s = mouse.screen
	local active_tag = awful.tag.selected(s)
	if active_tag ==nil then
		return
	end
	print("signal_tag_change", s, active_tag.name)
	module.history.pause(s)
	local old_tag = snapshot.screen.get("history_update", s, {targets = {active_tag = true}})
	snapshot.screen.update("history_update", s, {targets = {active_tag = true}})
	if module.history.options.multi_tag.enabled then
		if #awful.tag.selectedlist(s) > 1 then
			snapshot.screen.update("history_update", s, {multi_tag = {enabled = true, separate = module.history.options.multi_tag.separate}})
		else
			snapshot.screen.update("history_update", s, {multi_tag = {enabled = false, separate = module.history.options.multi_tag.separate}})
		end
	end
	snapshot.tag.restore("history_update", s, active_tag, {targets = module.history.options.tag})
	module.history.start(s)
end


---[[
--TODO: multiple tags selection have its one history like a meta-tag fixes needing
module.history.init = function ()
	for s = 1, screen.count() do
		module.history.start(s)
		snapshot.screen.update("history_update", s, {targets = {active_tag = true}})
	end
end
module.history.pause = function(s)
	if s == nil then
		for s = 1, screen.count() do
			module.history.start(s)
		end
		return
	end
	screen[s]:disconnect_signal("tag::history::update", module.history.signal_tag_change)
	screen[s]:disconnect_signal("arrange", module.history.signal_arrange)
end
module.history.start = function(s)
	if s == nil then
		for s = 1, screen.count() do
			module.history.start(s)
		end
		return
	end
	screen[s]:connect_signal("tag::history::update", module.history.signal_tag_change)
	screen[s]:connect_signal("arrange", module.history.signal_arrange)
end
--]]

-- }}}
return module
