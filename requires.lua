-- libraries
class = require "lib/30log"
baton = require "lib/baton"
tiny = require "lib/tiny"

color = require "color"
gamestate_manager = require "gamestate_manager"
input = require "input"

font = love.graphics.newImageFont("assets/font.png",
		" abcdefghijklmnopqrstuvwxyz" ..
		"ABCDEFGHIJKLMNOPQRSTUVWXYZ0" ..
		"123456789.,!?-+/():;%&`'*#=[]\"|_")
