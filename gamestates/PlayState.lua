local PlayState = class("PlayState")

PlayState.name = "Play Screen"

function PlayState:enter()
	self.game_frame = 0

	self.current_map = Map(16, 12)
	self.current_map:fill_debug()

	-- img.blood_canvas = love.graphics.newCanvas((mainmap.width + 4) * TILE_SIZE, (mainmap.height + 4) * TILE_SIZE)
	-- img.blood_canvas:setFilter("linear", "nearest")

	-- camera.update()
end

function PlayState:update(dt)
	gui_frame = gui_frame + 1

	-- handle input
	controller:update()
	mouse_sx, mouse_sy = love.mouse.getPosition()

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

	img.render(self)

	-- gui

	-- debug msg
	love.graphics.setColor(color.ltblue)
	love.graphics.print("Time: "..string.format("%.0f", self.game_frame / 60), 2, 2)
	love.graphics.setColor(color.white)
	local mouse_gx, mouse_gy = math.floor(mouse_sx / TILE_SIZE), math.floor(mouse_sy / TILE_SIZE)
	if self.current_map:in_bounds(mouse_gx, mouse_gy) then
		love.graphics.print("n: "..(self.current_map:get_edge(mouse_gx, mouse_gy, "n") or "x")..
			", w: "..(self.current_map:get_edge(mouse_gx, mouse_gy, "w") or "x")..
			", s: "..(self.current_map:get_edge(mouse_gx, mouse_gy, "s") or "x")..
			", e: "..(self.current_map:get_edge(mouse_gx, mouse_gy, "e") or "x"), 2, window_h - 58)
	end
	love.graphics.print("Cursor: "..mouse_gx..", "..mouse_gy, 2, window_h - 38)
	love.graphics.print("FPS: "..love.timer.getFPS(), 2, window_h - 18)
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

	love.graphics.draw(img.cursor, mouse_sx - 5, mouse_sy - 5)
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
