local awful     = require("awful")
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


-- }}}
return {
	widgets = require("eucalyptus.widgets"),
	menus = require("eucalyptus.menus")
}
