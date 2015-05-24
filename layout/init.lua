local ipairs = ipairs
local type = type
local awful = require("awful")
snapshot = require("eucalyptus.snapshot")
local capi = {
    awesome = awesome,
    root = root,
    mouse = mouse,
    screen = screen,
    client = client,
    mousegrabber = mousegrabber,
}
local aclient = require("awful.client")

--- Layout module for awful
-- awful.layout
local eucalyptus_layout = {
	test = require("eucalyptus.layout.test")
}
-- using code from official awesome git to port new functionality to 3.6.5 version
-- https://github.com/awesomeWM/awesome/blob/98dd0d6b63c0b77b29f625dada299745ccccb444/lib/awful/mouse/init.lua.in
-- overloading functions awful.mouse.client.resize and awful.mouse.client.move
local mouse_client_resize = awful.mouse.client.resize
--- Resize a client.
-- @param c The client to resize, or the focused one by default.
-- @param corner The corner to grab on resize. Auto detected by default.
awful.mouse.client.resize = function(c, corner)
    local c = c or awfulz.client.focus

    if not c then return end
    c.maximized_horizontal = false
	c.maximized_vertical = false
	if awful.layout.get(c.screen) ~= eucalyptus_layout.test then
		return mouse_client_resize(c, corner)
	end

    if c.fullscreen
        or c.type == "desktop"
        or c.type == "splash"
        or c.type == "dock" then
        return
    end

    local lay = awful.layout.get(c.screen)
    local corner, x, y = awful.mouse.client.corner(c, corner)
	return lay.mouse_resize_handler(c, corner, x, y)
end
local mouse_client_move = awful.mouse.client.move
--- Move a client.
-- @param c The client to move, or the focused one if nil.
-- @param snap The pixel to snap clients.

awful.mouse.client.move = function(c, snap)
	local c = c or capi.client.focus
	c.maximized_horizontal = false
	c.maximized_vertical = false
	if awful.layout.get(c.screen) ~= eucalyptus_layout.test then
		return mouse_client_move(c, snap)
	end
    if not c
        or c.fullscreen
        or c.type == "desktop"
        or c.type == "splash"
        or c.type == "dock" then
        return
    end

    local orig = c:geometry()
    local m_c = capi.mouse.coords()
    local dist_x = m_c.x - orig.x
    local dist_y = m_c.y - orig.y
    -- Only allow moving in the non-maximized directions
    local fixed_x = c.maximized_horizontal
    local fixed_y = c.maximized_vertical

    capi.mousegrabber.run(function (_mouse)
                              for k, v in ipairs(_mouse.buttons) do
                                  if v then
                                          local x = _mouse.x - dist_x
                                          local y = _mouse.y - dist_y
                                          c:geometry(awful.mouse.client.snap(c, snap, x, y, fixed_x, fixed_y))
                                      return true
                                  end
                              end
                              return false
                          end, "fleur")
end

return eucalyptus_layout
