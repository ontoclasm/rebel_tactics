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
	local next_input_state = nil

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
		camera.shift_target( -TILE_SIZE, 0 )
	end
	if controller:pressed( 'r_right' ) then
		camera.shift_target( TILE_SIZE, 0 )
	end
	if controller:pressed( 'r_up' ) then
		camera.shift_target( 0, -TILE_SIZE )
	end
	if controller:pressed( 'r_down' ) then
		camera.shift_target( 0, TILE_SIZE )
	end

	if controller:pressed( 'r1' ) and playstate.current_map:in_bounds( playstate.mouse_x, playstate.mouse_y ) then
		local pid = playstate.current_map:get_pawn( playstate.mouse_x, playstate.mouse_y )
		if not pid then
			-- unselect
			playstate.selected_pawn = nil
			next_input_state = "Open"
		elseif pid ~= playstate.selected_pawn then
			if not playstate.pawn_list[pid] then
				error()
			end
			playstate.selected_pawn = pid
			next_input_state = "Selected"
		end
	elseif controller:pressed( 'a' ) and p.actions >= 1 then
		next_input_state = "Aiming"
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
						next_input_state = "Selected"
					end
				end
			end
		end
	end

	return next_input_state
end

function SelectedState:draw( playstate )
	love.graphics.setColor(color.white)

	local p = playstate:get_selected_pawn()

	img.update_terrain_batches(playstate.current_map)
	local elev, nbr_elev, act, nbr_act
	local neighborhood = {}
	local diff_nbr, has_diff_nbr = false, false
	local nx, ny
	for i = 1, img.NUM_TERRAIN_LAYERS do
		love.graphics.draw(img.tileset_batches[i], -(camera.px % TILE_SIZE), -(camera.py % TILE_SIZE))
		--draw move radius by edges
		-- for x = 1, playstate.current_map.width do
		-- 	for y = 1, playstate.current_map.height do
		-- 		act = pathfinder:get_actions_remaining( x, y )
		-- 		elev = playstate.current_map:get_block_elev( x, y )
		-- 		if act >= 0 then
		-- 			local act_color = color[img.color_name_by_actions( act, elev )]

		-- 			-- love.graphics.setColor(act_color[1], act_color[2], act_color[3], 0.1)
		-- 			-- if img.layer_from_elev( elev ) == i then
		-- 			-- 	img.draw_to_grid( "block", x, y )
		-- 			-- end

		-- 			love.graphics.setColor(act_color)
		-- 			-- north edge
		-- 			if playstate.current_map:in_bounds( x, y-1 ) and not playstate.current_map:get_edge(x, y, "n") then
		-- 				nbr_elev = playstate.current_map:get_block_elev( x, y-1 )
		-- 				nbr_act = pathfinder:get_actions_remaining( x, y-1 )
		-- 				if nbr_elev <= elev and math.max(img.layer_from_elev( elev ) , img.layer_from_elev( nbr_elev )) == i-1 and act > nbr_act then
		-- 					img.draw_to_grid_edge("edge_dotted", x, y)
		-- 				end
		-- 			end

		-- 			-- south edge
		-- 			if playstate.current_map:in_bounds( x, y+1 ) and not playstate.current_map:get_edge(x, y, "s") then
		-- 				nbr_elev = playstate.current_map:get_block_elev( x, y+1 )
		-- 				nbr_act = pathfinder:get_actions_remaining( x, y+1 )
		-- 				if nbr_elev <= elev and math.max(img.layer_from_elev( elev ) , img.layer_from_elev( nbr_elev )) == i-1 and act > nbr_act then
		-- 					img.draw_to_grid_edge("edge_dotted", x, y, 0, 0, PI)
		-- 				end
		-- 			end

		-- 			-- west edge
		-- 			if playstate.current_map:in_bounds( x-1, y ) and not playstate.current_map:get_edge(x, y, "w") then
		-- 				nbr_elev = playstate.current_map:get_block_elev( x-1, y )
		-- 				nbr_act = pathfinder:get_actions_remaining( x-1, y )
		-- 				if nbr_elev <= elev and math.max(img.layer_from_elev( elev ) , img.layer_from_elev( nbr_elev )) == i-1 and act > nbr_act then
		-- 					img.draw_to_grid_edge("edge_dotted", x, y, 0, 0, -PI_2)
		-- 				end
		-- 			end

		-- 			-- east edge
		-- 			if playstate.current_map:in_bounds( x+1, y ) and not playstate.current_map:get_edge(x, y, "e") then
		-- 				nbr_elev = playstate.current_map:get_block_elev( x+1, y )
		-- 				nbr_act = pathfinder:get_actions_remaining( x+1, y )
		-- 				if nbr_elev <= elev and math.max(img.layer_from_elev( elev ) , img.layer_from_elev( nbr_elev )) == i-1 and act > nbr_act then
		-- 					img.draw_to_grid_edge("edge_dotted", x, y, 0, 0, PI_2)
		-- 				end
		-- 			end
		-- 		elseif img.layer_from_elev( elev ) == i and playstate.current_map:get_block_kind(x,y) ~= 999 then
		-- 			love.graphics.setColor(0,0,0,0.3)
		-- 			img.draw_to_grid("hatching_half", x, y)
		-- 		end
		-- 	end
		-- end

		--draw move radius by region
		for x = 1, playstate.current_map.width do
			for y = 1, playstate.current_map.height do
				elev = playstate.current_map:get_block_elev( x, y )
				if img.layer_from_elev( elev ) == i then
					act = pathfinder:get_actions_remaining( x, y )
					if act >= 1 then
						-- draw orange first...
						act = 0
						love.graphics.setColor(color[img.color_name_by_actions( act, elev )])
						neighborhood = {}
						has_diff_nbr = false
						for dir = 1, 8 do
							nx, ny = grid.neighbor(x,y,dir)
							diff_nbr = pathfinder:get_actions_remaining( nx, ny ) >= act
							table.insert(neighborhood, diff_nbr)
							if diff_nbr and dir % 2 == 1 then
								has_diff_nbr = true
							end
						end
						if has_diff_nbr then
							img.draw_region_tile("region_move", x, y, neighborhood)
						end

						-- then blue
						act = 1
						love.graphics.setColor(color[img.color_name_by_actions( act, elev )])
						neighborhood = {}
						has_diff_nbr = false
						for dir = 1, 8 do
							nx, ny = grid.neighbor(x,y,dir)
							diff_nbr = pathfinder:get_actions_remaining( nx, ny ) >= act
							table.insert(neighborhood, diff_nbr)
							if diff_nbr and dir % 2 == 1 then
								has_diff_nbr = true
							end
						end
						if has_diff_nbr then
							img.draw_region_tile("region_move", x, y, neighborhood)
						end
					elseif act == 0 then
						love.graphics.setColor(color[img.color_name_by_actions( act, elev )])
						neighborhood = {}
						has_diff_nbr = false
						for dir = 1, 8 do
							nx, ny = grid.neighbor(x,y,dir)
							diff_nbr = pathfinder:get_actions_remaining( nx, ny ) >= act
							table.insert(neighborhood, diff_nbr)
							if diff_nbr and dir % 2 == 1 then
								has_diff_nbr = true
							end
						end
						if has_diff_nbr then
							img.draw_region_tile("region_move", x, y, neighborhood)
						end
					end
				end
			end
		end

		love.graphics.setColor(color.white)
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
				love.graphics.setColor( color[ img.color_name_by_actions( pathfinder:get_actions_remaining(x, y), playstate.current_map:get_block_elev( x, y ) ) ] )
				img.draw_to_grid("cursor_base", x, y)
			end

			local path = pathfinder:path_to( grid.unhash( pathfinder.debug_last_h ) )
			if path then
				local a, b, c, d, en
				for i = 1, #path - 1 do
					a, b = grid.unhash( path[ i ] )
					c, d = grid.unhash( path[ i+1 ] )
					love.graphics.setColor( color[ img.color_name_by_actions( pathfinder:get_actions_remaining( c, d ) ) ] )
					a, b = camera.screen_point_from_grid_point( a, b )
					c, d = camera.screen_point_from_grid_point( c, d )
					love.graphics.line( a, b, c, d )
				end

				for i = 2, #path do
					a, b = grid.unhash( path[ i ] )
					love.graphics.setColor( color[ img.color_name_by_actions( pathfinder:get_actions_remaining( a,b ) ) ] )
					img.draw_to_grid("dot", a, b)
				end
			end
		elseif not playstate.animating then
			local path = pathfinder:path_to( playstate.mouse_x, playstate.mouse_y )
			if path then
				local a, b, c, d, en
				for i = 1, #path - 1 do
					a, b = grid.unhash( path[ i ] )
					c, d = grid.unhash( path[ i+1 ] )
					love.graphics.setColor( color[ img.color_name_by_actions( pathfinder:get_actions_remaining( c, d ) ) ] )
					a, b = camera.screen_point_from_grid_point( a, b )
					c, d = camera.screen_point_from_grid_point( c, d )
					love.graphics.line( a, b, c, d )
				end

				for i = 2, #path do
					a, b = grid.unhash( path[ i ] )
					love.graphics.setColor( color[ img.color_name_by_actions( pathfinder:get_actions_remaining( a,b ) ) ] )
					img.draw_to_grid("dot", a, b)
				end
			end
		end
	end

	-- draw cover for the selected pawn?
	-- love.graphics.setColor(color["yellow"..img.color_suffix_from_elev(playstate.current_map:get_block_elev(p.x,p.y))])
	-- img.draw_cover(p.x, p.y, playstate.current_map)

	-- draw pawns
	for _, p in pairs(playstate.pawn_list) do
		-- xxx cull off-screens?
		love.graphics.setColor((p.id == playstate.selected_pawn) and color.mix(p.color, color.white, 0.5 + 0.5 * math.sin((gui_frame - self.start_frame) / 15))
			or p.color)
		img.draw_to_grid("pawn", p.x, p.y, p.offset_x, p.offset_y)
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

	-- draw mouse cursor
	if playstate.current_map:in_bounds(playstate.mouse_x, playstate.mouse_y) and playstate.current_map:get_block(playstate.mouse_x, playstate.mouse_y) ~= 99 then
		local cursor_name
		if pathfinder.on and pathfinder.energies[ grid.hash(playstate.mouse_x, playstate.mouse_y) ] then
			love.graphics.setColor(color[img.color_name_by_actions( pathfinder:get_actions_remaining(playstate.mouse_x, playstate.mouse_y) )] )
			-- img.draw_to_grid("cursor_base", playstate.mouse_x, playstate.mouse_y)
			if playstate.mouse_x ~= pathfinder.origin_x or playstate.mouse_y ~= pathfinder.origin_y then
				img.draw_to_grid("cursor_circle_small", playstate.mouse_x, playstate.mouse_y)
			end

			-- draw cover at mouse position
			love.graphics.setColor(color.yellow04)
			img.draw_cover(playstate.mouse_x, playstate.mouse_y, playstate.current_map)

			-- ...and in the surrounding 8 tiles
			-- for i = 1, 8 do
			-- 	nx, ny = grid.neighbor(playstate.mouse_x, playstate.mouse_y, i)
			-- 	if playstate.current_map:in_bounds(nx, ny) then
			-- 		local b, b_elev = playstate.current_map:get_block(nx, ny)
			-- 		love.graphics.setColor(color["yellow"..img.color_suffix_from_elev(b_elev)])
			-- 		if b and block_data[b].floor then
			-- 			img.draw_cover(nx, ny, playstate.current_map)
			-- 		end
			-- 	end
			-- end
		else
			love.graphics.setColor(color.white)
			-- img.draw_to_grid("cursor_base", playstate.mouse_x, playstate.mouse_y)
			if playstate.current_map:get_pawn(playstate.mouse_x, playstate.mouse_y) then
				img.draw_to_grid("cursor_corners_medium", playstate.mouse_x, playstate.mouse_y)
			else
				img.draw_to_grid("cursor_corners_small", playstate.mouse_x, playstate.mouse_y)
			end
		end

		-- for dx = -2, 2 do
		-- 	for dy = -2, 2 do
		-- 		if playstate.current_map:in_bounds(playstate.mouse_x + dx, playstate.mouse_y + dy) then
		-- 			local b, b_elev = playstate.current_map:get_block(playstate.mouse_x + dx, playstate.mouse_y + dy)
		-- 			love.graphics.setColor(color["yellow"..img.color_suffix_from_elev(b_elev)])
		-- 			if b and block_data[b].floor then
		-- 				img.draw_cover(playstate.mouse_x + dx, playstate.mouse_y + dy, playstate.current_map)
		-- 			end
		-- 		end
		-- 	end
		-- end
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
