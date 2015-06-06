local setmetatable = setmetatable
local print,ipairs  = print,ipairs
local awful     = require( "awful"                   )
local wibox     = require( "wibox"                   )
local beautiful = require( "beautiful"               )
local radical = require("radical")
local lain      = require("lain")
local module = {}
local function new(layouts)
	-- {{{ Wibox
	markup = lain.util.markup
	blue   = beautiful.fg_focus
	red    = "#EB8F8F"
	green  = "#8FEB8F"

	-- Textclock
	mytextclock = awful.widget.textclock("<span font='Tamsyn 5'> </span>%H:%M ")

	-- Calendar
	lain.widgets.calendar:attach(mytextclock, {position = "bottom_right"})

	--[[ Mail IMAP check
	-- commented because it needs to be set before use
	mailwidget = lain.widgets.imap({
		timeout  = 180,
		server   = "server",
		mail     = "mail",
		password = "keyring get mail",
		settings = function()
			mail  = ""
			count = ""

			if mailcount > 0 then
				mail = "<span font='Tamsyn 5'> </span>Mail "
				count = mailcount .. " "
			end

			widget:set_markup(markup(blue, mail) .. count)
		end
	})
---]]

	-- MPD
	mpdicon = wibox.widget.imagebox(beautiful.play)
	mpdwidget = lain.widgets.mpd({
		settings = function()
			if mpd_now.state == "play" then
				title = mpd_now.title
				artist  = " - " .. mpd_now.artist  .. markup("#333333", " |<span font='Tamsyn 3'> </span>")
				mpdicon:set_image(beautiful.play)
			elseif mpd_now.state == "pause" then
				title = "mpd "
				artist  = "paused" .. markup("#333333", " |<span font='Tamsyn 3'> </span>")
				mpdicon:set_image(beautiful.pause)
			else
				title  = ""
				artist = ""
				mpdicon:set_image()
			end

			widget:set_markup(markup(blue, title) .. artist)
		end
	})
---[[
	-- Battery
	baticon = wibox.widget.imagebox(beautiful.bat)
	batbar = awful.widget.progressbar()
	batbar:set_color(beautiful.fg_normal)
	batbar:set_width(55)
	batbar:set_ticks(true)
	batbar:set_ticks_size(6)
	batbar:set_background_color(beautiful.bg_normal)
	batmargin = wibox.layout.margin(batbar, 2, 7)
	batmargin:set_top(6)
	batmargin:set_bottom(6)
	batupd = lain.widgets.bat({
		settings = function()
		   if bat_now.perc == "N/A" or bat_now.status == "Not present" then
				bat_perc = 100
				baticon:set_image(beautiful.ac)
			elseif bat_now.status == "Charging" then
				bat_perc = tonumber(bat_now.perc)
				baticon:set_image(beautiful.ac)

				if bat_perc >= 98 then
					batbar:set_color(green)
				elseif bat_perc > 50 then
					batbar:set_color(beautiful.fg_normal)
				elseif bat_perc > 15 then
					batbar:set_color(beautiful.fg_normal)
				else
					batbar:set_color(red)
				end
			else
				bat_perc = tonumber(bat_now.perc)

				if bat_perc >= 98 then
					batbar:set_color(green)
				elseif bat_perc > 50 then
					batbar:set_color(beautiful.fg_normal)
					baticon:set_image(beautiful.bat)
				elseif bat_perc > 15 then
					batbar:set_color(beautiful.fg_normal)
					baticon:set_image(beautiful.bat_low)
				else
					batbar:set_color(red)
					baticon:set_image(beautiful.bat_no)
				end
			end
			batbar:set_value(bat_perc / 100)
		end
	})
	batwidget = wibox.widget.background(batmargin)
	batwidget:set_bgimage(beautiful.widget_bg)
---]]
	-- /home fs
	diskicon = wibox.widget.imagebox(beautiful.disk)
	diskbar = awful.widget.progressbar()
	diskbar:set_color(beautiful.fg_normal)
	diskbar:set_width(55)
	diskbar:set_ticks(true)
	diskbar:set_ticks_size(6)
	diskbar:set_background_color(beautiful.bg_normal)
	diskmargin = wibox.layout.margin(diskbar, 2, 7)
	diskmargin:set_top(6)
	diskmargin:set_bottom(6)
	fshomeupd = lain.widgets.fs({
		partition = "/home",
		settings  = function()
			if fs_now.used < 90 then
				diskbar:set_color(beautiful.fg_normal)
			else
				diskbar:set_color("#EB8F8F")
			end
			diskbar:set_value(fs_now.used / 100)
		end
	})
	diskwidget = wibox.widget.background(diskmargin)
	diskwidget:set_bgimage(beautiful.widget_bg)

	-- ALSA volume bar
	volicon = wibox.widget.imagebox(beautiful.vol)
	volume = lain.widgets.alsabar({width = 55, ticks = true, ticks_size = 6,
	card = "0", step = "2%",
	settings = function()
		if volume_now.status == "off" then
			volicon:set_image(beautiful.vol_mute)
		elseif volume_now.level == 0 then
			volicon:set_image(beautiful.vol_no)
		elseif volume_now.level <= 50 then
			volicon:set_image(beautiful.vol_low)
		else
			volicon:set_image(beautiful.vol)
		end
	end,
	colors =
	{
		background = beautiful.bg_normal,
		mute = red,
		unmute = beautiful.fg_normal
	}})
	volmargin = wibox.layout.margin(volume.bar, 2, 7)
	volmargin:set_top(6)
	volmargin:set_bottom(6)
	volumewidget = wibox.widget.background(volmargin)
	volumewidget:set_bgimage(beautiful.widget_bg)

	-- Weather
	yawn = lain.widgets.yawn(123456)

	-- Separators
	spr = wibox.widget.textbox(' ')
	small_spr = wibox.widget.textbox('<span font="Tamsyn 4"> </span>')
	bar_spr = wibox.widget.textbox('<span font="Tamsyn 3"> </span>' .. markup("#333333", "|") .. '<span font="Tamsyn 3"> </span>')

	-- Create a wibox for each screen and add it
	mywibox = {}
	mypromptbox = {}
	mylayoutbox = {}
	mytaglist = {}
	mytaglist.buttons = awful.util.table.join(
						awful.button({ }, 1, awful.tag.viewonly),
						awful.button({ modkey }, 1, awful.client.movetotag),
						awful.button({ }, 3, awful.tag.viewtoggle),
						awful.button({ modkey }, 3, awful.client.toggletag),
						awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
						awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
						)
	mytasklist = {}
	mytasklist.buttons = awful.util.table.join(
						 awful.button({ }, 1, function (c)
												  if c == client.focus then
													  c.minimized = true
												  else
													  -- Without this, the following
													  -- :isvisible() makes no sense
													  c.minimized = false
													  if not c:isvisible() then
														  awful.tag.viewonly(c:tags()[1])
													  end
													  -- This will also un-minimize
													  -- the client, if needed
													  client.focus = c
													  c:raise()
												  end
											  end),
						 awful.button({ }, 3, function ()
												  if instance then
													  instance:hide()
													  instance = nil
												  else
													  instance = awful.menu.clients({ width=250 })
												  end
											  end),
						 awful.button({ }, 4, function ()
												  awful.client.focus.byidx(1)
												  if client.focus then client.focus:raise() end
											  end),
						 awful.button({ }, 5, function ()
												  awful.client.focus.byidx(-1)
												  if client.focus then client.focus:raise() end
											  end))

	for s = 1, screen.count() do
		-- Create a promptbox for each screen
		mypromptbox[s] = awful.widget.prompt()
		-- Create an imagebox widget which will contains an icon indicating which layout we're using.
		-- We need one layoutbox per screen.
		mylayoutbox[s] = awful.widget.layoutbox(s)
		mylayoutbox[s]:buttons(awful.util.table.join(
							   awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
							   awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
							   awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
							   awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
		-- Create a taglist widget
		mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)
	--	local rad_taglist     = require( "radical.impl.taglist"      )
	--	rad_taglist.taglist_watch_name_changes = true
	--	mytaglist[s] = rad_taglist(s)._internal.margin
		-- Create a tasklist widget
	--    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)
		--local rad_task     = require( "radical.impl.tasklist"      )
		local rad_task     = require("pretty.widgets.tasklist")
		mytasklist[s] = rad_task(s)._internal.margin
		-- Create the wibox
		mywibox[s] = awful.wibox({ position = "bottom", screen = s, height = 18 })

		-- Widgets that are aligned to the left
		local left_layout = wibox.layout.fixed.horizontal()
		left_layout:add(small_spr)
		left_layout:add(mylayoutbox[s])
		left_layout:add(bar_spr)
		left_layout:add(mytaglist[s])
		left_layout:add(spr)
		left_layout:add(mypromptbox[s])
		left_layout:add(bar_spr)
		
		-- Widgets that are aligned to the right
		local right_layout = wibox.layout.fixed.horizontal()
		if s == 1 then right_layout:add(wibox.widget.systray()) end
		right_layout:add(small_spr)
		right_layout:add(mpdicon)
		right_layout:add(mpdwidget)
		--right_layout:add(mailwidget)
		right_layout:add(baticon)
		right_layout:add(batwidget)
		right_layout:add(bar_spr)
		right_layout:add(diskicon)
		right_layout:add(diskwidget)
		right_layout:add(bar_spr)
		right_layout:add(volicon)
		right_layout:add(volumewidget)
		right_layout:add(bar_spr)
		right_layout:add(mytextclock)
		-- Now bring it all together (with the tasklist in the middle)
		local layout = wibox.layout.align.horizontal()
		layout:set_left(left_layout)
		layout:set_middle(mytasklist[s])
		layout:set_right(right_layout)

		mywibox[s]:set_widget(layout)
	end
	-- }}}
	
end
return setmetatable(module, { __call = function(_, ...) return new(...) end })
