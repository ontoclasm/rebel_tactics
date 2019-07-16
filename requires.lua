-- libraries
class = require "lib/30log"
baton = require "lib/baton"
tiny = require "lib/tiny"

color = require "color"
gamestate_manager = require "gamestate_manager"
input = require "input"
img = require "img"
mymath = require "mymath"

Map = require "Map"

font = love.graphics.newImageFont("assets/img/font.png",
		" abcdefghijklmnopqrstuvwxyz" ..
		"ABCDEFGHIJKLMNOPQRSTUVWXYZ0" ..
		"123456789.,!?-+/():;%&`'*#=[]\"|_")
