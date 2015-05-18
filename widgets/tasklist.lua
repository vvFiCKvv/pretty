local awful     = require( "awful"                   )
local wibox     = require( "wibox"                   )
local beautiful = require( "beautiful"               )
local radical = require("radical")
local module = {}
local function new(menu)
	
end
return setmetatable(module, { __call = function(_, ...) return new(...) end })
