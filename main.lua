require "requires"

function love.load()
	gui_frame = 0

	window_w, window_h = 1280, 1024
	love.graphics.setBackgroundColor( color.rouge )

	controller = input.setup_controller()
	love.mouse.setVisible( false )
	love.mouse.setGrabbed( true )
	mouse_sx, mouse_sy = 0, 0

	img.setup()
	love.graphics.setFont( font )
	love.graphics.setLineWidth( 1 )

	-- world = tiny.world(
	-- 	PlayerControlSystem,
	-- 	AIControlSystem,
	-- 	WeaponSystem,
	-- 	PhysicsSystem,
	-- 	ZoneSystem,
	-- 	TimerSystem,
	-- 	MortalSystem,
	-- 	img.DrawingSystem
	-- )

	gamestate = StateManager({
		Splash = require "gamestates/SplashState",
		Play = require "gamestates/PlayState",
		GameOver = require "gamestates/GameOverState",
	},
	"Splash")
end

function love.update( dt )
	gamestate.state:update( dt )
end

function love.draw()
	gamestate.state:draw()
end

function love.focus( f )
	gamestate.state:focus( f )
end
