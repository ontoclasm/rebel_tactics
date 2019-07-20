local PlayState = class("PlayState")

PlayState.name = "Play Screen"

function PlayState:enter()
	self.game_frame = 0

	self.current_map = Map(24, 16)
	self.current_map:fill_debug()

	self.pawn_list = {}
	for pawn_id = 1, 8 do
		-- place a pawn
		local spawn_x, spawn_y = self.current_map:find_random_floor()
		table.insert(self.pawn_list, {id = pawn_id, color = {1, pawn_id/8, 0}, x = spawn_x, y = spawn_y})
		self.current_map:set_pawn(spawn_x, spawn_y, pawn_id)
	end

	-- img.blood_canvas = love.graphics.newCanvas((mainmap.width + 4) * TILE_SIZE, (mainmap.height + 4) * TILE_SIZE)
	-- img.blood_canvas:setFilter("linear", "nearest")

	camera.set_location(36, 36 + 48)

	mouse_sx, mouse_sy = love.mouse.getPosition()
	self.mouse_gx, self.mouse_gy = camera.grid_point_from_screen_point(mouse_sx, mouse_sy)
end

function PlayState:update(dt)
	gui_frame = gui_frame + 1

	-- handle input
	controller:update()
	mouse_sx, mouse_sy = love.mouse.getPosition()
	self.mouse_gx, self.mouse_gy = camera.grid_point_from_screen_point(mouse_sx, mouse_sy)

	-- updates even when paused?
	camera.update()

	if not self.paused then
		if controller:pressed('menu') then
			self:pause()
			return
		end

		self.game_frame = self.game_frame + 1

		if controller:pressed('r_left') then
			camera.shift_target(-24, 0)
		end
		if controller:pressed('r_right') then
			camera.shift_target(24, 0)
		end
		if controller:pressed('r_up') then
			camera.shift_target(0, -24)
		end
		if controller:pressed('r_down') then
			camera.shift_target(0, 24)
		end

		-- tiny.update(world, TIMESTEP)

		-- if self.gameover then
		-- 	gamestate_manager.switch_to("GameOver")
		-- 	break
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
	if self.current_map:in_bounds(self.mouse_gx, self.mouse_gy) then
		love.graphics.print("b: "..(self.current_map:get_block(self.mouse_gx, self.mouse_gy) or "x")..
			", n: "..(self.current_map:get_edge(self.mouse_gx, self.mouse_gy, "n") or "x")..
			", w: "..(self.current_map:get_edge(self.mouse_gx, self.mouse_gy, "w") or "x")..
			", s: "..(self.current_map:get_edge(self.mouse_gx, self.mouse_gy, "s") or "x")..
			", e: "..(self.current_map:get_edge(self.mouse_gx, self.mouse_gy, "e") or "x")..
			", pawn: "..(self.current_map:get_pawn(self.mouse_gx, self.mouse_gy, "e") or "x"), 2, window_h - 58)
	end
	love.graphics.print("Cursor: "..self.mouse_gx..", "..self.mouse_gy, 2, window_h - 38)
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
