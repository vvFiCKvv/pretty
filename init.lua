local setmetatable = setmetatable
local print,ipairs  = print,ipairs
local awful     = require("awful")
local beautiful = require("beautiful")
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
awful.mouse.moveto_client = function (c, togle_tag_enabled)
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
awful.client.focus.history.switch = function (multiple_switch_enabled, mouse_move_enabled)
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
			awful.mouse.moveto_client(c)
		end
	end
	if client.focus then
		client.focus:raise()
	end
end
--- Switch tag history backwards.
--- mouse.screen fails if a tag has none clients.
awful.tag.history.switch = function()
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

--- toggle active's screen tags between all tags and tags where focus client is
awful.tag.viewall_toggle = function ()
--TODO: use lain.layout.uselessfair
	-- mouse.screen fails if a tag has none clients.
	s = mouse.screen
	tags = awful.tag.gettags(s) -- all tags of current screen
	selectedTags = awful.tag.selectedlist(s) -- get the tags witch are selected
	if #tags==#selectedTags then -- all tags of the current screen are selected
		c=awful.mouse.client_under_pointer() -- get the client under the mouse
		if c ~=nil then -- view only the tag witch the client under the mouse is
			awful.tag.viewmore(c:tags(),s)
			if client.focus then
				client.focus:raise() -- focus to the client
			end
		else -- Screen has none clients
			awful.tag.viewonly(tags[1],s) -- view 1st tag
		end
	else -- select all the tags of the current screen
		awful.tag.viewmore(tags,s)
		currentLayout = awful.layout.get() -- get the current layout
		if currentLayout == awful.layout.suit.max or currentLayout == awful.layout.suit.floating then
			t=awful.tag.selected() -- get the 1st selected tag
			last_layout = awful.tag.getproperty(t,"last_layout") -- get the last layout of the tag before the max/float layout
			awful.layout.set(last_layout) -- restore the layout
		end
	end
end
--- move all clients to the active screen
awful.screen.move_all_clients = function ()
--TODO: use awful.screen getbycoord (x, y, default)	 Return Xinerama screen number corresponding to the given (pixel) coordinates.
	activeScreen =  mouse.screen
	activeScreenTags = awful.tag.gettags(s) -- all tags of current screen
	for s = 1, screen.count() do -- for each screen 
		if s~=activeScreen then -- except active screen
			tags = awful.tag.gettags(s) -- all tags of current screen
			for t in pairs(tags) do
				clients = tags[t]:clients()
				for c in pairs(clients) do
					if t <= #activeScreenTags then -- move the clients to corresponding tags
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
awful.screen.toggle = function (index)
	if index == 0 then
		return 
	end
	if index > 0 then
		return awful.screen.toggle(index - screen.count())
	end
	firstScreenTags =  awful.tag.gettags(1) -- all tags of 1st screen
	selectedTagsList = {} -- a list of selected tags list per screen
	table.insert(selectedTagsList, awful.tag.selectedlist(1)) -- add selected tags of 1st screen
	for s = 2, screen.count() do -- for each screen from 2nt to last move tags and selected tags to the previous screen
		tags = awful.tag.gettags(s) -- all tags of current screen
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
		awful.screen.toggle(index + 1)
	end
end
awful.screen.take_snapshot = function (s)
	tags = awful.tag.gettags(s)
	awful.snapshot[s] = {}
	for t in pairs(tags) do
		-- may be need {unpack(tags[t]:clients())}
		awful.snapshot[s][t] = tags[t]:clients()
	end
end
awful.screen.restore_snapshot = function (s)
	tags = awful.tag.gettags(s)
	for t in pairs(tags) do
--		tags[t]:clients(awful.snapshot[s][t])
		clients = awful.snapshot[s][t]
		for c in pairs(clients) do
			awful.client.movetotag(tags[t], clients[c])
			awful.client.toggletag(tags[t], clients[c])
		end
		awful.snapshot[s][t] = nil
	end
	awful.snapshot[s] = nil
end
awful.snapshot = nil
awful.take_snapshot = function ()
	awful.snapshot = {}
	for s = 1, screen.count() do -- for each screen 
			awful.screen.take_snapshot(s)
	end
end
awful.restore_snapshot = function ()
	for s = 1, screen.count() do -- for each screen 
			awful.screen.restore_snapshot(s)
	end
	awful.snapshot = nil
end
awful.tag.viewall_screens_toggle = function ()
	if awful.snapshot == nil then
		awful.take_snapshot()
		awful.screen.move_all_clients()
		awful.tag.viewall_toggle()
	else
--TODO: focus client and client's tag, move mouse to client's screen or move screens to mouse
		c = awful.mouse.client_under_pointer()
		awful.tag.viewall_toggle()
		s0 =  mouse.screen
		awful.restore_snapshot()
--		s1 = c.screen
		awful.mouse.moveto_client(c,true)
		s1 =  mouse.screen

		awful.screen.toggle(s0 - s1)
		
--		awful.tag.viewmore(c:tags())
		awful.mouse.moveto_client(c, true)
	end
end
awful.client.maximize = function(c, status, orientation, filter)
	if filter == nil then
		filter = "normal"
	end
	if c.type ~= filter and filter~="all" then
		return
	end
	if orientation == nil then 
		orientation = "both"
	end
	if status == nil or status == "true" then
		status = true
	end
	if status == "false" then
		status = false
	end
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
end
awful.tag.max_toggle = function()
	local t = awful.tag.selected()
	max_layout = not awful.tag.getproperty(t,"max_layout")
	awful.tag.setproperty(t, "max_layout", max_layout)
	if max_layout then
		client.connect_signal("focus", awful.client.maximize)
		if client.focus then
			client.focus:emit_signal("focus")
			client.focus:raise()
		end
	else
		client.disconnect_signal("focus", awful.client.maximize)
			clients = t:clients()
		for c in pairs(clients) do
			awful.client.maximize(clients[c],false)
		end
	end
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

--keep the history of layouts per tag
awful.tag.attached_connect_signal(nil, "property::layout", function(t)
	s = awful.tag.getscreen(t)
	currentLayout = awful.layout.get()
	if currentLayout == awful.layout.suit.max or currentLayout == awful.layout.suit.floating then
		awful.tag.setproperty(t,"tilingLayout", false)
	else
		selectedTags = awful.tag.selectedlist(s)
		if #selectedTags == 1 then -- sigle tag selected
			awful.tag.setproperty(t,"last_layout", currentLayout)
			awful.tag.setproperty(t,"tilingLayout", true)
		end
	end
	if client.focus then
		client.focus:raise()
	end
end)
---[[
--TODO: multiple tags selection have its one history like a meta-tag fixes needing
for s = 1, screen.count() do
	screen[s]:connect_signal("tag::history::update", function()
		t = awful.tag.selected(s)
		if t~=nil then
			selectedTags = awful.tag.selectedlist(s)
			if #selectedTags > 1 then -- multiple tags selected
				if awful.layout.get() ~= awful.layout.suit.floating and  awful.layout.get() ~= awful.layout.suit.max then
					awful.layout.multiTags = {}
					awful.layout.multiTags.last_layout =  awful.layout.get()
				end
			else -- single tag selected
				if awful.layout.multiTags ~= nil then -- deselecting multiple tags
					if awful.tag.getproperty(t,"last_layout") ~= nil then
						awful.layout.set(awful.tag.getproperty(t,"last_layout"))
						awful.layout.multiTags = nil
					end
				end
				if awful.tag.getproperty(t,"last_layout") == nil then
					awful.tag.setproperty(t,"last_layout", awful.layout.get())
				   --do some stuff when virtual desktop has changed
				end
			   --TODO:Correct the focus
				c = awful.mouse.client_under_pointer()
				if c ~= nil then
					if c:isvisible() == false then
					else
						client.focus = c
						client.focus:raise()
					end
				end
					--awful.client.focus.byidx(-1)
			end
		end
	end)
--TODO: remove last_layout and similar stuff
	--initialize visible tag for each screen
	t = awful.tag.selected(s)
	if t~=nil then
		awful.tag.setproperty(t,"last_layout", awful.layout.get())
	end
end
--]]
--local tag = require("awful.tag")
local function tag_history_count(screen, idx)
	local s = screen or capi.mouse.screen
	return #data.history[s]
end
--awful.tag.history.restore = tag_history_count



-- }}}
return {
	widgets = require("eucalyptus.widgets"),
	menus = require("eucalyptus.menus"),
	layout = require("eucalyptus.layout")
}
