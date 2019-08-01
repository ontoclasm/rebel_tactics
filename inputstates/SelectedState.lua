local SelectedState = class("SelectedState")

SelectedState.name = "Selected State"

function SelectedState:init( manager )
	self.manager = manager
end

function SelectedState:enter()
	pathfinder:reset()
	self.start_frame = gui_frame
	self.move_radius_is_dirty = true
end

function SelectedState:update( playstate, dt )
	local p = playstate:get_selected_pawn()
	if p.actions > 0 and not pathfinder.on and not playstate.animating then
		if p.actions == 2 then
			-- pathfinder:build_move_radius_debug_start( self.current_map, self.pawn_list[pid].x, self.pawn_list[pid].y, 5005000 )
			pathfinder:build_move_radius( playstate.current_map, p.x, p.y, 5005000 )
		elseif p.actions == 1 then
			pathfinder:build_move_radius( playstate.current_map, p.x, p.y, 5000 )
		else
			pathfinder:reset()
		end
	end

	if pathfinder.debug_running and ( gui_frame - self.start_frame ) % 5 == 0 then
		pathfinder:build_move_radius_debug_step( playstate.current_map )
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

	if controller:pressed( 'r1' ) then
		local pid = playstate.current_map:get_pawn( playstate.mouse_x, playstate.mouse_y )
		if not pid then
			-- unselect
			playstate.selected_pawn = nil
			self.manager:switch_to("Open")
		elseif pid ~= playstate.selected_pawn then
			if not playstate.pawn_list[pid] then
				error()
			end
			playstate.selected_pawn = pid
			self.manager:switch_to("Selected")
		end
	elseif controller:pressed( 'a' ) and p.actions >= 1 then
		self.manager:switch_to("Aiming")
	elseif controller:pressed( 'x' ) then
		if p.actions == 2 then
			-- pathfinder:build_move_radius_debug_start( self.current_map, self.pawn_list[pid].x, self.pawn_list[pid].y, 5005000 )
			pathfinder:build_move_radius_debug_start( playstate.current_map, p.x, p.y, 5005000 )
		elseif p.actions == 1 then
			pathfinder:build_move_radius_debug_start( playstate.current_map, p.x, p.y, 5000 )
		end
	elseif not playstate.animating then
		-- enact orders
		if controller:pressed( 'r2' ) then
			-- move selected pawn to mouse point
			local path, action_cost = pathfinder:path_to( playstate.mouse_x, playstate.mouse_y )
			if path and #path > 1 then
				-- playstate:order_move_pawn( playstate.selected_pawn, path, energy_cost )
				if p.actions < action_cost then
					error( "not enough actions" )
				else
					p.actions = p.actions - action_cost

					for step = 1, #path - 1 do
						x1, y1 = grid.unhash(path[step])
						x2, y2 = grid.unhash(path[step+1])

						-- step from x1y1 to x2y2
						-- XXX check for reactions etc.
						playstate.animation_queue:enqueue({ kind = "step", pid = p.id, x1 = x1, y1 = y1, x2 = x2, y2 = y2, t = 0 })
						playstate.animating = true

						pathfinder:reset()
					end

					if p.actions == 0 then
						local next = playstate:get_next_pawn()
						playstate.selected_pawn = next.id
						camera.set_target_by_grid_point(next.x, next.y)
						self.manager:switch_to("Selected")
					end
				end
			end
		end
	end
end

function SelectedState:draw( playstate )
	love.graphics.setColor(color.white)

	img.update_tileset_batch(playstate.current_map)
	love.graphics.draw(img.tileset_batch, -(camera.px % TILE_SIZE), -(camera.py % TILE_SIZE))

	-- draw mouse cursor
	if playstate.current_map:in_bounds(playstate.mouse_x, playstate.mouse_y) and playstate.current_map:get_block(playstate.mouse_x, playstate.mouse_y) ~= 99 then
		love.graphics.setColor(color.rouge)
		img.draw_to_grid("cursor_mouse", playstate.mouse_x, playstate.mouse_y)

		-- love.graphics.setColor(color.rouge)
		-- love.graphics.draw(img.tileset, img.tile["cursor_mouse"], camera.screen_point_from_grid_point(playstate.mouse_x, playstate.mouse_y))
	end

	-- -- draw FOV
	-- local x, y
	-- for hash,v in pairs( playstate.visible_tiles ) do
	-- 	x, y = grid.unhash(hash)
	-- 	img.set_color_by_dir(v)
	-- 	img.draw_to_grid("cursor_mouse", x, y)
	-- end

	-- pathfinder debug
	if pathfinder.on then
		if pathfinder.debug_last_h then
			for h, _ in pairs( pathfinder.fringes ) do
				x, y = grid.unhash( h )
				img.set_color_by_energy( pathfinder.energies[ h ] )
				img.draw_to_grid("cursor_mouse", x, y)
			end

			local path = pathfinder:path_to( grid.unhash( pathfinder.debug_last_h ) )
			if path then
				local a, b, c, d, en
				for i = 1, #path - 1 do
					img.set_color_by_energy( pathfinder.energies[ path[ i+1 ] ] )
					a, b = grid.unhash( path[ i ] )
					c, d = grid.unhash( path[ i+1 ] )
					a, b = camera.screen_point_from_grid_point( a, b )
					c, d = camera.screen_point_from_grid_point( c, d )
					love.graphics.line( a, b, c, d )
				end
			end
		elseif not playstate.animating then
			local path = pathfinder:path_to( playstate.mouse_x, playstate.mouse_y )
			if path then
				local a, b, c, d, en
				for i = 1, #path - 1 do
					img.set_color_by_energy( pathfinder.energies[ path[ i+1 ] ] )
					a, b = grid.unhash( path[ i ] )
					c, d = grid.unhash( path[ i+1 ] )
					a, b = camera.screen_point_from_grid_point( a, b )
					c, d = camera.screen_point_from_grid_point( c, d )
					love.graphics.line( a, b, c, d )
				end
			end
		end

		local en
		for x = 1, playstate.current_map.width do
			for y = 1, playstate.current_map.height do
				en = pathfinder.energies[ grid.hash( x, y ) ]
				if en then
					img.set_color_by_energy( en )
					img.draw_to_grid("dot", x, y)
				end
			end
		end
	end

	-- draw pawns
	for _, p in pairs(playstate.pawn_list) do
		-- xxx cull off-screens?
		love.graphics.setColor((p.id == playstate.selected_pawn) and color.mix(p.color, color.white, 0.5 + 0.5 * math.sin((gui_frame - self.start_frame) / 15))
			or p.color)
		img.draw_to_grid("pawn", p.x, p.y, p.offset_x, p.offset_y)

		-- if p.id == playstate.selected_pawn then
		-- 	love.graphics.setColor(color.mix(p.color, color.white, 0.5 + 0.5 * math.sin((gui_frame - playstate.selected_start_frame) / 15)))
		-- else
		-- 	love.graphics.setColor(p.color)
		-- end
		-- love.graphics.draw(img.tileset, img.tile["pawn"], camera.screen_point_from_grid_point(p.x, p.y))
	end

	-- draw FoV
	if playstate.visible_tiles then
		love.graphics.setColor(color.bg)
		for x = 1, playstate.current_map.width do
			for y = 1, playstate.current_map.height do
				if not playstate.visible_tiles[grid.hash(x,y)] then
					img.draw_to_grid("hatching", x, y)
				end
			end
		end
	end

	-- tiny.refresh(world)
	-- if img.DrawingSystem.modified then
	-- 	img.DrawingSystem:onModify()
	-- end
	-- img.DrawingSystem:update()

	love.graphics.setColor(color.white)
end

-- function SelectedState:exit()
-- end

return SelectedState
