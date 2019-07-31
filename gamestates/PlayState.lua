local PlayState = class( "PlayState" )

PlayState.name = "Play Screen"

function PlayState:enter()
	self.game_frame = 0

	self.current_map = Map(28, 18)
	self.current_map:fill_debug()
	pathfinder:reset()

	self.pawn_list = {}
	for pawn_id = 1, 8 do
		-- place a pawn
		local spawn_x, spawn_y = self.current_map:find_random_floor()
		table.insert( self.pawn_list, {
			id = pawn_id, color = {1, pawn_id/8, 0},
			x = spawn_x, y = spawn_y,
			actions = 2
		} )
		self.current_map:set_pawn( spawn_x, spawn_y, pawn_id )
	end

	self.selected_pawn = nil
	self.input_mode = "open"
	self.animation_queue = Queue()

	-- img.blood_canvas = love.graphics.newCanvas((mainmap.width + 4) * TILE_SIZE, (mainmap.height + 4) * TILE_SIZE)
	-- img.blood_canvas:setFilter("linear", "nearest")

	camera.set_location( 12 * 24 + 12, 8 * 24 + 12 )

	mouse_sx, mouse_sy = love.mouse.getPosition()
	self.mouse_x, self.mouse_y = camera.grid_point_from_screen_point( mouse_sx, mouse_sy )
	self.mouse_fov_is_dirty = true
	self.visible_tiles = nil

	img.tileset_batch_is_dirty = true
end

function PlayState:update( dt )
	gui_frame = gui_frame + 1

	-- handle input
	controller:update()
	mouse_sx, mouse_sy = love.mouse.getPosition()
	self.mouse_x, self.mouse_y = camera.grid_point_from_screen_point( mouse_sx, mouse_sy )

	-- updates even when paused?
	camera.update()

	if not self.paused then
		if controller:pressed( 'menu' ) then
			self:pause()
			return
		end

		self.game_frame = self.game_frame + 1

		if self.mouse_fov_is_dirty or self.mouse_x ~= self.old_mouse_x or self.mouse_y ~= self.old_mouse_y then
			-- mouse is over a new square

			--calculate FOV
			self.visible_tiles = {}
			if self.current_map:in_bounds(self.mouse_x, self.mouse_y) and self.current_map:get_block(self.mouse_x, self.mouse_y) ~= 99 then
				self:calculate_fov(self.mouse_x, self.mouse_y, self.visible_tiles)
			else
				self.visible_tiles = nil
			end

			self.mouse_fov_is_dirty = false
			self.old_mouse_x, self.old_mouse_y = self.mouse_x, self.mouse_y
		end

		if controller:pressed( 'r_left' ) then
			camera.shift_target( -24, 0 )
		end
		if controller:pressed( 'r_right' ) then
			camera.shift_target( 24, 0 )
		end
		if controller:pressed( 'r_up' ) then
			camera.shift_target( 0, -24 )
		end
		if controller:pressed( 'r_down' ) then
			camera.shift_target( 0, 24 )
		end

		if self.input_mode == "open" then
			if controller:pressed( 'r1' ) then
				local pid = self.current_map:get_pawn( self.mouse_x, self.mouse_y )
				if not pid then
					self:unselect_pawn()
				elseif pid ~= self.selected_pawn then
					self:select_pawn( pid )
				end
			end
			if controller:pressed( 'r2' ) and self.selected_pawn then
				-- move selected pawn to mouse point
				local path, energy_cost = pathfinder:path_to( self.mouse_x, self.mouse_y )
				if path and #path > 1 then
					self:order_move_pawn( self.selected_pawn, path, energy_cost )
				end
			end
		end

		if self.current_animation then
			-- currently only steps exist
			if self.current_animation.t == 0 then
				--start the animation
				if self.current_map:get_pawn( self.current_animation.x1, self.current_animation.y1 ) ~= self.current_animation.pid then
					error("pawn in wrong place??")
				end

				local p = self.pawn_list[self.current_animation.pid]
				p.offset_x = TILE_SIZE * (self.current_animation.x1 - self.current_animation.x2)
				p.offset_y = TILE_SIZE * (self.current_animation.y1 - self.current_animation.y2)
				self.current_map:move_pawn( self.current_animation.x1, self.current_animation.y1, self.current_animation.x2, self.current_animation.y2 )
				p.x, p.y = self.current_animation.x2, self.current_animation.y2

				self.current_animation.t = self.current_animation.t + 12 * dt
			elseif self.current_animation.t < 1 then
				local p = self.pawn_list[self.current_animation.pid]
				p.offset_x = mymath.abs_floor(TILE_SIZE * (self.current_animation.x1 - self.current_animation.x2) * (1 - self.current_animation.t))
				p.offset_y = mymath.abs_floor(TILE_SIZE * (self.current_animation.y1 - self.current_animation.y2) * (1 - self.current_animation.t))

				self.current_animation.t = self.current_animation.t + 12 * dt
			else
				-- anim finished
				local p = self.pawn_list[self.current_animation.pid]
				p.offset_x = 0
				p.offset_y = 0

				self.current_animation = nil
			end
		end

		if (not self.current_animation) and (not self.animation_queue:is_empty()) then
			self.current_animation = self.animation_queue:dequeue()
		end

		if pathfinder.debug_running and ( gui_frame - self.selected_start_frame ) % 5 == 0 then
			pathfinder:build_move_radius_debug_step( self.current_map )
		end

		-- if pathfinder.on then
		-- 	if not self.current_map:in_bounds( self.mouse_x, self.mouse_y ) then
		-- 		pathfinder:reset()
		-- 	elseif self.mouse_x ~= pathfinder.origin_x or self.mouse_y ~= pathfinder.origin_y then
		-- 		pathfinder:build_move_radius( self.current_map, self.mouse_x, self.mouse_y, 6006 )
		-- 	end
		-- elseif self.current_map:in_bounds( self.mouse_x, self.mouse_y ) then
		-- 	pathfinder:build_move_radius( self.current_map, self.mouse_x, self.mouse_y, 6006 )
		-- end

		-- tiny.update(world, TIMESTEP)

		-- if self.gameover then
		-- 	gamestate_manager.switch_to("GameOver")
		-- 	break
		-- end
	else
		if controller:pressed( 'menu' ) then
			self:unpause()
		end
		if controller:pressed( 'view' ) then
			gamestate_manager.switch_to( "Splash" )
		end
	end
end

function PlayState:draw()
	if self.paused then
		love.graphics.setShader( shader_desaturate )
	end

	-- love.graphics.setCanvas( game_canvas )
	love.graphics.clear( color.bg )

	img.render( self )

	-- gui

	-- debug msg
	love.graphics.setColor( color.ltblue )
	love.graphics.print( "Time: "..string.format("%.0f", self.game_frame / 60), 2, 2 )
	love.graphics.setColor( color.white )
	if self.current_map:in_bounds( self.mouse_x, self.mouse_y ) then
		love.graphics.print( "b: "..(self.current_map:get_block(self.mouse_x, self.mouse_y) or "x")..
			", n: "..(self.current_map:get_edge(self.mouse_x, self.mouse_y, "n") or "x")..
			", w: "..(self.current_map:get_edge(self.mouse_x, self.mouse_y, "w") or "x")..
			", s: "..(self.current_map:get_edge(self.mouse_x, self.mouse_y, "s") or "x")..
			", e: "..(self.current_map:get_edge(self.mouse_x, self.mouse_y, "e") or "x")..
			", pawn: "..(self.current_map:get_pawn(self.mouse_x, self.mouse_y, "e") or "x"), 2, window_h - 58 )
	end
	love.graphics.print( "Cursor: "..self.mouse_x..", "..self.mouse_y, 2, window_h - 38 )
	love.graphics.print( "FPS: "..love.timer.getFPS(), 2, window_h - 18 )
	love.graphics.setColor( color.white )
	love.graphics.setShader()
	if self.paused then
		-- draw pause menu
		love.graphics.setColor( color.rouge )
		love.graphics.circle( "fill", window_w/2, window_h/2, 50 )
		love.graphics.setColor( color.white )
		love.graphics.printf( "Press Q to quit", math.floor(window_w/2 - 100), math.floor(window_h/2 - font:getHeight()/2), 200, "center" )
		love.graphics.setColor( color.white )
	end

	love.graphics.draw( img.cursor, mouse_sx - 5, mouse_sy - 5 )
	-- love.graphics.setCanvas()
	-- love.graphics.draw(game_canvas)
end

function PlayState:focus( f )
	if f then
		love.mouse.setVisible( false )
		love.mouse.setGrabbed( true )
	else
		if not self.paused then
			self:pause()
		end
		love.mouse.setVisible( true )
		love.mouse.setGrabbed( false )
	end
end

function PlayState:exit()
	pathfinder:reset()
end

-- -- -- --

function PlayState:select_pawn( pid )
	local p = self.pawn_list[pid]
	if not p then
		error("missing pawn: "..pid)
	end

	-- build move radius
	if p.actions == 2 then
		-- pathfinder:build_move_radius_debug_start( self.current_map, self.pawn_list[pid].x, self.pawn_list[pid].y, 5005000 )
		pathfinder:build_move_radius( self.current_map, p.x, p.y, 5005000 )
	elseif p.actions == 1 then
		pathfinder:build_move_radius( self.current_map, p.x, p.y, 5000 )
	else
		pathfinder:reset()
	end

	self.selected_pawn = pid
	self.selected_start_frame = gui_frame
end

function PlayState:unselect_pawn()
	self.selected_pawn = nil
	pathfinder:reset()
end

function PlayState:order_move_pawn( pid, path, action_cost )
	p = self.pawn_list[pid]
	if not p then
		error( "missing pawn: " .. pid )
	elseif p.actions < action_cost then
		error( "not enough actions" )
	else
		p.actions = p.actions - action_cost

		for step = 1, #path - 1 do
			x1, y1 = grid.unhash(path[step])
			x2, y2 = grid.unhash(path[step+1])

			-- step from x1y1 to x2y2
			-- XXX check for reactions etc.
			self.animation_queue:enqueue({ kind = "step", pid = pid, x1 = x1, y1 = y1, x2 = x2, y2 = y2, t = 0 })
		end

		-- x, y = grid.unhash(path[#path]) -- end of the path
		-- self.current_map:move_pawn( p.x, p.y, x, y )
		-- p.x = x
		-- p.y = y

		self:unselect_pawn()

		-- if p.actions == 0 then
		-- 	self:unselect_pawn()
		-- elseif p.actions == 2 then
		-- 	-- pathfinder:build_move_radius_debug_start( self.current_map, self.pawn_list[pid].x, self.pawn_list[pid].y, 5005000 )
		-- 	pathfinder:build_move_radius( self.current_map, p.x, p.y, 5005000 )
		-- elseif p.actions == 1 then
		-- 	pathfinder:build_move_radius( self.current_map, p.x, p.y, 5000 )
		-- end
	end
end

function PlayState:calculate_fov(ox, oy, vis_table)
	-- visible from the given point
	fov(ox,oy,28,
		function(x, y, dir)	-- get_transparent_edge
			if not self.current_map:in_bounds(x,y) or self.current_map:get_block(x,y) == 99 then
				return false
			else
				return (self.current_map:get_edge(x, y, dir) ~= 99)
			end
		end,
		function(x, y)	-- set_visible
			vis_table[grid.hash(x,y)] = "c"
		end)

	if self.current_map:can_lean_south(ox,oy) then
		-- lean south
		fov(ox,oy+1,28,
			function(x, y, dir)	-- get_transparent_edge
				if not self.current_map:in_bounds(x,y) or self.current_map:get_block(x,y) == 99 then
					return false
				else
					return (self.current_map:get_edge(x, y, dir) ~= 99)
				end
			end,
			function(x, y)	-- set_visible
				vis_table[grid.hash(x,y)] = vis_table[grid.hash(x,y)] or "s"
			end)
	end

	if self.current_map:can_lean_north(ox,oy) then
		-- lean north
		fov(ox,oy-1,28,
			function(x, y, dir)	-- get_transparent_edge
				if not self.current_map:in_bounds(x,y) or self.current_map:get_block(x,y) == 99 then
					return false
				else
					return (self.current_map:get_edge(x, y, dir) ~= 99)
				end
			end,
			function(x, y)	-- set_visible
				vis_table[grid.hash(x,y)] = vis_table[grid.hash(x,y)] or "n"
			end)
	end

	if self.current_map:can_lean_west(ox,oy) then
		-- lean west
		fov(ox-1,oy,28,
			function(x, y, dir)	-- get_transparent_edge
				if not self.current_map:in_bounds(x,y) or self.current_map:get_block(x,y) == 99 then
					return false
				else
					return (self.current_map:get_edge(x, y, dir) ~= 99)
				end
			end,
			function(x, y)	-- set_visible
				vis_table[grid.hash(x,y)] = vis_table[grid.hash(x,y)] or "w"
			end)
	end

	if self.current_map:can_lean_east(ox,oy) then
		-- lean east
		fov(ox+1,oy,28,
			function(x, y, dir)	-- get_transparent_edge
				if not self.current_map:in_bounds(x,y) or self.current_map:get_block(x,y) == 99 then
					return false
				else
					return (self.current_map:get_edge(x, y, dir) ~= 99)
				end
			end,
			function(x, y)	-- set_visible
				vis_table[grid.hash(x,y)] = vis_table[grid.hash(x,y)] or "e"
			end)
	end
end

function PlayState:pause()
	self.paused = true
end

function PlayState:unpause()
	self.paused = false
end

return PlayState
