local setmetatable = setmetatable
local print,ipairs  = print,ipairs
local awful     = require( "awful"                   )

local module = {}
function new()
end
local menu_timer = {timer = nil, init, start, stop, func, menu}
menu_timer.init = function (second)
	
	menu_timer.stop()
	menu_timer.timer =  timer { timeout = second } -- init timer with interval seconds
	menu_timer.start()
end
menu_timer.start = function ()
	menu_timer.timer:connect_signal("timeout", menu_timer.func)
	menu_timer.timer:start()
end
menu_timer.stop = function ()
	if menu_timer.timer == nil then
		return
	end
	menu_timer.timer:stop()
	menu_timer.timer:disconnect_signal("timeout", menu_timer.func)
end
menu_timer.func = function()
	menu_timer.stop()
	menu_timer.menu:hide()
end

module.create = function (menu, second, func)
	if menu == nil then
		return nil
	end
	if menu_timer.menu ~= nil then
		menu_timer.func()
	end
	menu_timer.stop()
	if second == nil then
		second = 1
	end
	menu_timer.menu = menu
	if func ~= nil then
		menu_timer.func = func
	end
	menu_timer.init(second)
end
module.attach = function(menu, second)
	if menu == nil then
		return nil
	end
	if second == nil then
		second = 1
	end
--	second = 5
	if menu_timer.timer == nil then
		module.create(menu, second)
	end
	menu:connect_signal("mouse::enter", function()
		menu_timer.stop()
	end)
	menu:connect_signal("mouse::leave", function()
		menu_timer.init(second)
	end)
end
return setmetatable(module, { __call = function(_, ...) return new(...) end })
