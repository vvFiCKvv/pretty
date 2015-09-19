local setmetatable = setmetatable
local print,ipairs  = print,ipairs
local awful     = require("awful")
local beautiful = require("beautiful")
local module = {
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
module.signal = {}
module.signal_arrange = function ()
	local s = mouse.screen 
	local active_tag = awful.tag.selected(s)
	if active_tag == nil then
		return
	end
	local old_tag = snapshot.screen.get("history_update", s, {targets = {active_tag = true}})
--	print("s",s, "old", old_tag.name, "t", active_tag.name)
	if old_tag == active_tag then
--		print("signal_arrange")
		snapshot.tag.update("history_update", s, active_tag, {targets = module.options.tag})
	end
end

module.signal_tag_change =  function (data, s)
	if s == nil then
		s = mouse.screen
	end
	local active_tag = awful.tag.selected(s)
	if active_tag ==nil then
		return
	end
--	print("signal_tag_change", s, active_tag.name)
	module.pause(s)
	local old_tag = snapshot.screen.get("history_update", s, {targets = {active_tag = true}})
	snapshot.screen.update("history_update", s, {targets = {active_tag = true}})
	snapshot.screen.update("history_update", s, {targets = {history = true}})
	if module.options.multi_tag.enabled then
		if #awful.tag.selectedlist(s) > 1 then
			snapshot.screen.update("history_update", s, {multi_tag = {enabled = true, separate = module.options.multi_tag.separate}})
		else
			snapshot.screen.update("history_update", s, {multi_tag = {enabled = false, separate = module.options.multi_tag.separate}})
		end
	end
	snapshot.tag.restore("history_update", s, active_tag, {targets = module.options.tag})
	module.start(s)
end


---[[
--TODO: multiple tags selection have its one history like a meta-tag fixes needing
module.init = function ()
	for s = 1, screen.count() do
		module.start(s)
		snapshot.screen.update("history_update", s, {targets = {active_tag = true}})
		snapshot.screen.update("history_update", s, {targets = {history = true}})
	end
end
module.pause = function(s)
	if s == nil then
		for s = 1, screen.count() do
			module.start(s)
		end
		return
	end
	screen[s]:disconnect_signal("tag::history::update", module.signal_tag_change)
	screen[s]:disconnect_signal("arrange", module.signal_arrange)
end
module.start = function(s)
	if s == nil then
		for s = 1, screen.count() do
			module.start(s)
		end
		return
	end
	screen[s]:connect_signal("tag::history::update", module.signal_tag_change)
	screen[s]:connect_signal("arrange", module.signal_arrange)
end
module.get_clients = function(t, start_index, end_index)
	if start_index == nil then
		start_index = 1
	end
	if end_index == nil then
		end_index = #t:clients()
	end
	local clients = {}
	for i = start_index, end_index do
		local c = awful.client.focus.history.get(mouse.screen, i - 1)
		clients[i + 1 - start_index] = c
	end
	return clients
end
module.get_tags = function(s, start_index, end_index)
	if start_index == nil then
		start_index = 1
	end
	if end_index == nil then
		end_index = 100
	end
	---[[
	local tags = {}
	local t = awful.tag.selected()
	local i = start_index
	while true do
		local result = snapshot.screen.get("history_update", s, {targets = {history = i}})
		i = i + 1
		if result == nil or i > end_index then
			break
		end
		tags[i - start_index] = result
	end
	return tags
	---]]
	--return awful.tag.gettags(s)
end
return module
--]]
