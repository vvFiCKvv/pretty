local setmetatable = setmetatable
local print,ipairs  = print,ipairs

local awful     = require("awful")
local drop      = require("scratchdrop")

local module = {}
module.globalkeys = {}
module.clientbuttons = {}
module.clientkeys = {}
-- common
module.modkey     = "Mod4"
module.altkey     = "Mod1"
module.terminal   = "urxvtc" or "xterm"
module.editor     = os.getenv("EDITOR") or "nano" or "vi"
module.editor_cmd = module.terminal .. " -e " .. module.editor

-- user defined
module.browser    = "google-chrome-unstable"
module.browser2   = "firefox"
module.gui_editor = "geany"
module.graphics   = "gimp"
module.filemanager = "nemo --no-desktop"

local function init()
	-- {{{ Key bindings
	module.globalkeys = awful.util.table.join(
		-- Take a screenshot
		-- https://github.com/copycat-killer/dots/blob/master/bin/screenshot
	--TODO: copy it from cinnamon
		awful.key({ module.altkey }, "p", function() os.execute("screenshot") end),

		-- Tag browsing
		awful.key({ module.modkey }, "Left",   awful.tag.viewprev       ),
		awful.key({ module.modkey }, "Right",  awful.tag.viewnext       ),
	--TODO: functionality to do multiple history changes

		awful.key({ module.modkey }, "Tab", function () awful.tag.history.switch() end),
		
	--TODO: functionality to do multiple history changes
		awful.key({ module.modkey }, "Caps_Lock", 	
			function()
				for i =1, screen.count() do
					awful.tag.history.restore(i)
				end
			end ),
		-- Non-empty tag browsing
	--    awful.key({ module.altkey }, "Left", function () lain.util.tag_view_nonempty(-1) end),
	--    awful.key({ module.altkey }, "Right", function () lain.util.tag_view_nonempty(1) end),

		-- Default client focus
		--awful.key({ module.altkey }, "k",
			--function ()
				--awful.client.focus.byidx( 1)
				--if client.focus then client.focus:raise() end
			--end),
		--awful.key({ module.altkey }, "j",
			--function ()
				--awful.client.focus.byidx(-1)
				--if client.focus then client.focus:raise() end
			--end),

		-- By direction client focus
		awful.key({ module.modkey }, "j",
			function()
				awful.client.focus.bydirection("down")
				if client.focus then client.focus:raise() end
			end),
		awful.key({ module.modkey }, "k",
			function()
				awful.client.focus.bydirection("up")
				if client.focus then client.focus:raise() end
			end),
		awful.key({ module.modkey }, "h",
			function()
				awful.client.focus.bydirection("left")
				if client.focus then client.focus:raise() end
			end),
		awful.key({ module.modkey }, "l",
			function()
				awful.client.focus.bydirection("right")
				if client.focus then client.focus:raise() end
			end),

		-- Show Menu
		awful.key({ module.modkey }, "w",
			function ()
				mymainmenu:show({ keygrabber = true })
			end),
	--TODO: mywibox keys
		-- Show/Hide Wibox
	--    awful.key({ module.modkey }, "b", function ()
	--        mywibox[mouse.screen].visible = not mywibox[mouse.screen].visible
	--    end),

		---- On the fly useless gaps change
		--awful.key({ module.altkey, "Control" }, "+", function () lain.util.useless_gaps_resize(1) end),
		--awful.key({ module.altkey, "Control" }, "-", function () lain.util.useless_gaps_resize(-1) end),

	--TODO: change shortcat for rename
		-- Rename tag
	--    awful.key({ module.altkey, "Shift"   }, "r", function () lain.util.rename_tag(mypromptbox) end),

		-- Layout manipulation
		awful.key({ module.modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
		awful.key({ module.modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
		awful.key({ module.modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
		awful.key({ module.modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
		awful.key({ module.modkey,           }, "u", awful.client.urgent.jumpto),
		awful.key({ module.altkey,           }, "Tab", function ()  awful.client.focus.history.switch(true, true) end),
	--TODO: change shortcat for rename
	--    awful.key({ module.altkey, "Shift"   }, "l",      function () awful.tag.incmwfact( 0.05)     end),
	--    awful.key({ module.altkey, "Shift"   }, "h",      function () awful.tag.incmwfact(-0.05)     end),
		awful.key({ module.modkey, "Shift"   }, "l",      function () awful.tag.incnmaster(-1)       end),
		awful.key({ module.modkey, "Shift"   }, "h",      function () awful.tag.incnmaster( 1)       end),
		awful.key({ module.modkey, "Control" }, "l",      function () awful.tag.incncol(-1)          end),
		awful.key({ module.modkey, "Control" }, "h",      function () awful.tag.incncol( 1)          end),
	--    awful.key({ module.modkey,           }, "space",  function () awful.layout.inc(layouts,  1)  end),
		awful.key({ module.modkey, "Shift"   }, "space",  function () awful.layout.inc(layouts, -1)  end),
		awful.key({ module.modkey, "Control" }, "n",      awful.client.restore),
		awful.key({ module.modkey,           }, "q", 
		function ()
			local t = awful.tag.selected()
			awful.layout.floating_toggle(mouse.screen,t)
		end ),
		awful.key({ module.modkey,           }, "space", awful.tag.max_toggle),

		-- Standard program
		awful.key({ module.modkey,           }, "Return", function () awful.util.spawn(module.terminal) end),
		awful.key({ module.modkey, "Control" }, "r",      awesome.restart),
		awful.key({ module.altkey, "Control"   }, "BackSpace", awesome.quit),

		-- Dropdown module.terminal
		awful.key({ module.modkey,	          }, "z",      function () drop(module.terminal) end),

		---- Widgets popups
		--awful.key({ module.altkey,           }, "c",      function () lain.widgets.calendar:show(7) end),
		--awful.key({ module.altkey,           }, "h",      function () fshomeupd.show(7) end),
		--awful.key({ module.altkey,           }, "w",      function () yawn.show(7) end),

	--TODO: change shortcat for rename
		---- ALSA volume control
		--awful.key({ module.altkey }, "Up",
			--function ()
				--os.execute(string.format("amixer -c %s set %s %s+", volume.card, volume.channel, volume.step))
				--volume.update()
			--end),
		--awful.key({ module.altkey }, "Down",
			--function ()
				--os.execute(string.format("amixer -c %s set %s %s-", volume.card, volume.channel, volume.step))
				--volume.update()
			--end),
		--awful.key({ module.altkey }, "m",
			--function ()
				--os.execute(string.format("amixer -c %s set %s toggle", volume.card, volume.channel))
				----os.execute(string.format("amixer set %s toggle", volume.channel))
				--volume.update()
			--end),
		--awful.key({ module.altkey, "Control" }, "m",
			--function ()
				--os.execute(string.format("amixer -c %s set %s 100", volume.card, volume.channel))
				--volume.update()
			--end),

		---- MPD control
		--awful.key({ module.altkey, "Control" }, "Up",
			--function ()
				--awful.util.spawn_with_shell("mpc toggle || ncmpc toggle || pms toggle")
				--mpdwidget.update()
			--end),
		--awful.key({ module.altkey, "Control" }, "Down",
			--function ()
				--awful.util.spawn_with_shell("mpc stop || ncmpc stop || pms stop")
				--mpdwidget.update()
			--end),
		--awful.key({ module.altkey, "Control" }, "Left",
			--function ()
				--awful.util.spawn_with_shell("mpc prev || ncmpc prev || pms prev")
				--mpdwidget.update()
			--end),
		--awful.key({ module.altkey, "Control" }, "Right",
			--function ()
				--awful.util.spawn_with_shell("mpc next || ncmpc next || pms next")
				--mpdwidget.update()
			--end),

		-- Copy to clipboard
		awful.key({ module.modkey }, "c", function () os.execute("xsel -p -o | xsel -i -b") end),

		---- User programs
		--awful.key({ module.modkey }, "q", function () awful.util.spawn(module.browser) end),
		--awful.key({ module.modkey }, "i", function () awful.util.spawn(module.browser2) end),
		--awful.key({ module.modkey }, "s", function () awful.util.spawn(module.gui_editor) end),
		--awful.key({ module.modkey }, "g", function () awful.util.spawn(module.graphics) end),
		awful.key({ module.modkey }, "e", function () awful.util.spawn( module.filemanager) end),

		-- Prompt
--TODO: fix
--[[		awful.key({ module.modkey }, "r", function () mypromptbox[mouse.screen]:run() end),
		awful.key({ module.modkey }, "x",
				  function ()
					  awful.prompt.run({ prompt = "Run Lua code: " },
					  mypromptbox[mouse.screen].widget,
					  awful.util.eval, nil,
					  awful.util.getdir("cache") .. "/history_eval")
				  end),
---]]
		awful.key({ module.modkey,           }, "`", function () awful.tag.viewall_toggle() end),

		awful.key({ module.modkey, "Shift" }, "o", function () awful.screen.move_all_clients() end),
		awful.key({ module.modkey, "Shift" }, "`", function () awful.tag.viewall_screens_toggle() end),
		awful.key({ module.modkey, }, "[",  function () awful.screen.toggle(-1) end),
		awful.key({ module.modkey, }, "]",  function () awful.screen.toggle(1) end)
	)

	module.clientkeys = awful.util.table.join(
	--    awful.key({ module.altkey, "Shift"   }, "m",      lain.util.magnify_client                         ),
		awful.key({ module.modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
		awful.key({ module.modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
		awful.key({ module.altkey,           }, "F4",      function (c) c:kill()                         end),
		awful.key({ module.modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
		awful.key({ module.modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
		awful.key({ module.modkey,           }, "o",      awful.client.movetoscreen                        ),
		awful.key({ module.modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
		awful.key({ module.modkey,           }, "n",
			function (c)
				-- The client currently has the input focus, so it cannot be
				-- minimized, since minimized clients can't have the focus.
				c.minimized = true
			end),
		awful.key({ module.modkey,           }, "m",
			function (c)
				c.maximized_horizontal = not c.maximized_horizontal
				c.maximized_vertical   = not c.maximized_vertical
			end)

	)

	-- Bind all key numbers to tags.
	-- Be careful: we use keycodes to make it works on any keyboard layout.
	-- This should map on the top row of your keyboard, usually 1 to 9.
	for i = 1, 9 do
		module.globalkeys = awful.util.table.join(module.globalkeys,
			-- View tag only.
			awful.key({ module.modkey }, "#" .. i + 9,
					  function ()
							local screen = mouse.screen
							local tag = awful.tag.gettags(screen)[i]
							if tag then
							   awful.tag.viewonly(tag)
							end
					  end),
			-- Toggle tag.
			awful.key({ module.modkey, "Control" }, "#" .. i + 9,
					  function ()
						  local screen = mouse.screen
						  local tag = awful.tag.gettags(screen)[i]
						  if tag then
							 awful.tag.viewtoggle(tag)
						  end
					  end),
			-- Move client to tag.
			awful.key({ module.modkey, "Shift" }, "#" .. i + 9,
					  function ()
						  if client.focus then
							  local tag = awful.tag.gettags(client.focus.screen)[i]
							  if tag then
								  awful.client.movetotag(tag)
							  end
						 end
					  end),
			-- Toggle tag.
			awful.key({ module.modkey, "Control", "Shift" }, "#" .. i + 9,
					  function ()
						  if client.focus then
							  local tag = awful.tag.gettags(client.focus.screen)[i]
							  if tag then
								  awful.client.toggletag(tag)
							  end
						  end
					  end))
	end

	module.clientbuttons = awful.util.table.join(
		awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
		awful.button({ module.modkey }, 1, awful.mouse.client.move),
		awful.button({ module.modkey }, 3, awful.mouse.client.resize))

	-- }}}
end
init()
return setmetatable(module, { __call = function(_, ...) return new(...) end })
