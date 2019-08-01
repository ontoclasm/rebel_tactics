-- libraries
class = require "lib/30log"
baton = require "lib/baton"
tiny = require "lib/tiny"
fov = require "lib/rsfov"

camera = require "camera"
color = require "color"
grid = require "grid"
input = require "input"
img = require "img"
mymath = require "mymath"
pathfinder = require "pathfinder"

Map = require "Map"
Queue = require "Queue"
StateManager = require "StateManager"

font = love.graphics.newImageFont("assets/img/font.png",
		" abcdefghijklmnopqrstuvwxyz" ..
		"ABCDEFGHIJKLMNOPQRSTUVWXYZ0" ..
		"123456789.,!?-+/():;%&`'*#=[]\"|_")

-- constants
PI_2 = math.pi / 2
