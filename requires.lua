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

require "data"

font = love.graphics.newImageFont("assets/img/font.png",
		" abcdefghijklmnopqrstuvwxyz" ..
		"ABCDEFGHIJKLMNOPQRSTUVWXYZ0" ..
		"123456789.,!?-+/():;%&`'*#=[]\"|_")

-- constants
TILE_SIZE = 32
TILE_SIZE_HALF = TILE_SIZE / 2
TILE_SIZE_QUARTER = TILE_SIZE / 4

PI_2 = math.pi / 2
PI = math.pi
TAU = math.pi * 2
