require "requires"

TILE_SIZE = 24
TILE_CENTER = 12

function love.load()
	gui_frame = 0

	window_w, window_h = 800, 600
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

	gamestate = gamestate_manager.states.Splash:new()
	if gamestate.enter then
		gamestate:enter()
	end
end

function love.update( dt )
	gamestate:update( dt )
end

function love.draw()
	gamestate:draw()
end

function love.focus( f )
	gamestate:focus( f )
end
