local SplashState = class("SplashState")

SplashState.name = "Splash Screen"

-- function SplashState:enter()
-- end

function SplashState:update(dt)
	gui_frame = gui_frame + 1

	-- handle input
	controller:update()
	mouse_x, mouse_y = love.mouse.getPosition()

	if controller:pressed('r1') then
		gamestate_manager.switch_to("Play")
	elseif controller:pressed('view') or controller:pressed('menu') then
		love.event.push("quit")
	end
end

function SplashState:draw()
	love.graphics.clear(color.bg)

	local k = math.cos(gui_frame / 120) + 2
	love.graphics.setColor(0.3 * k, 0.08 * k, 0.05 * k, 1)
	love.graphics.circle("fill", window_w/2, window_h/2, 50)
	love.graphics.setColor(color.white)
	love.graphics.printf("XCOM?", math.floor(window_w/2 - 100), math.floor(window_h/2 - font:getHeight()/2), 200, "center")
	love.graphics.setColor(color.white)

	love.graphics.circle("fill", mouse_x, mouse_y, 2)
end

function SplashState:focus(f)
	if f then
		love.mouse.setVisible(false)
		love.mouse.setGrabbed(true)
	else
		love.mouse.setVisible(true)
		love.mouse.setGrabbed(false)
	end
end

-- function SplashState:exit()
-- end

return SplashState
