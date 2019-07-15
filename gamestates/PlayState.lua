local PlayState = class("PlayState")

PlayState.name = "Play Screen"

function PlayState:enter()
	self.game_frame = 0

	-- self.mainmap = map:new(64, 64)
	-- self.mainmap:fill_main()
	-- _G.mainmap = self.mainmap

	-- img.blood_canvas = love.graphics.newCanvas((mainmap.width + 4) * TILE_SIZE, (mainmap.height + 4) * TILE_SIZE)
	-- img.blood_canvas:setFilter("linear", "nearest")

	-- camera.update()
end

function PlayState:update(dt)
	gui_frame = gui_frame + 1

	-- handle input
	controller:update()
	mouse_x, mouse_y = love.mouse.getPosition()

	if not self.paused then
		if controller:pressed('menu') then
			self:pause()
			return
		end

		self.game_frame = self.game_frame + 1

		-- tiny.update(world, TIMESTEP)

		-- if self.gameover then
		-- 	gamestate_manager.switch_to("GameOver")
		-- 	break
		-- else
		-- 	camera.update()
		-- end
	else
		if controller:pressed('menu') then
			self:unpause()
		end
		if controller:pressed('view') then
			gamestate_manager.switch_to("Splash")
		end
	end
end

function PlayState:draw()
	if self.paused then
		love.graphics.setShader(shader_desaturate)
	end

	-- love.graphics.setCanvas(game_canvas)
	love.graphics.clear(color.bg)

	-- img.render()

	-- gui

	-- debug msg
	love.graphics.print("Time: "..string.format("%.0f", self.game_frame / 60), 0, 0)
	love.graphics.setColor(color.yellow)
	love.graphics.print("FPS: "..love.timer.getFPS(), 2, window_h - 80)
	love.graphics.setColor(color.white)
	love.graphics.setShader()
	if self.paused then
		-- draw pause menu
		love.graphics.setColor(color.rouge)
		love.graphics.circle("fill", window_w/2, window_h/2, 50)
		love.graphics.setColor(color.white)
		love.graphics.printf("Press Q to quit", math.floor(window_w/2 - 100), math.floor(window_h/2 - font:getHeight()/2), 200, "center")
		love.graphics.setColor(color.white)
	end

	love.graphics.circle("fill", mouse_x, mouse_y, 2)
	-- love.graphics.setCanvas()
	-- love.graphics.draw(game_canvas)
end

function PlayState:focus(f)
	if f then
		love.mouse.setVisible(false)
		love.mouse.setGrabbed(true)
	else
		if not self.paused then
			self:pause()
		end
		love.mouse.setVisible(true)
		love.mouse.setGrabbed(false)
	end
end

-- function PlayState:exit()
-- 	tiny.clearEntities(world)
-- end

-- -- -- --

function PlayState:pause()
	self.paused = true
end

function PlayState:unpause()
	self.paused = false
end

return PlayState
