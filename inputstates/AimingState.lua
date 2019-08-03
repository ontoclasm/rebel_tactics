local AimingState = class("AimingState")

AimingState.name = "Aiming State"

function AimingState:init( manager )
	self.manager = manager
end

function AimingState:enter()
	pathfinder:reset()
	self.start_frame = gui_frame
end

function AimingState:update( playstate, dt )
	local next_input_state = nil

	local p = playstate:get_selected_pawn()
	if not self.visible_tiles then
		--calculate FOV
		self.visible_tiles = {}
		playstate.current_map:calculate_fov(p.x, p.y, self.visible_tiles)
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
	elseif controller:pressed( 'b' ) then
		next_input_state = "Selected"
	elseif not playstate.animating then
		-- enact orders
		if controller:pressed( 'r2' ) and p.actions >= 1 and self.visible_tiles and self.visible_tiles[grid.hash(playstate.mouse_x, playstate.mouse_y)] then
			local target = playstate.current_map:get_pawn(playstate.mouse_x, playstate.mouse_y)
			if target then
				-- FIRE
				p.actions = p.actions - 1
				playstate.pawn_list[target].alive = false
				if p.actions > 0 then
					next_input_state = "Selected"
				else
					local next = playstate:get_next_pawn()
					playstate.selected_pawn = next.id
					camera.set_target_by_grid_point(next.x, next.y)
					next_input_state = "Selected"
				end
			end
		end
	end

	return next_input_state
end

function AimingState:draw( playstate )
	love.graphics.setColor(color.white)

	img.update_terrain_batches(playstate.current_map)
	for i = 1, img.NUM_TERRAIN_LAYERS do
		love.graphics.draw(img.tileset_batches[i], -(camera.px % TILE_SIZE), -(camera.py % TILE_SIZE))

		-- draw FoV
		if self.visible_tiles then
			local b, b_elev
			love.graphics.setColor(color.blood)
			for x = 1, playstate.current_map.width do
				for y = 1, playstate.current_map.height do
					b, b_elev = playstate.current_map:get_block( x, y )
					if b ~= 999 and not self.visible_tiles[grid.hash(x,y)] and img.layer_from_elev( b_elev) == i then
						img.draw_to_grid("hatching", x, y)
					end
				end
			end
			love.graphics.setColor(color.white)
		end
	end

	if self.visible_tiles and self.visible_tiles[grid.hash(playstate.mouse_x, playstate.mouse_y)] then
		-- draw aim line for funsies
		love.graphics.setColor(color.rouge)
		local p = playstate:get_selected_pawn()
		local p_sx, p_sy = camera.screen_point_from_grid_point(p.x, p.y)
		local m_sx, m_sy = camera.screen_point_from_grid_point(playstate.mouse_x, playstate.mouse_y)
		love.graphics.line(p_sx, p_sy, m_sx, m_sy)
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

	if self.visible_tiles and self.visible_tiles[grid.hash(playstate.mouse_x, playstate.mouse_y)] then
		love.graphics.setColor(color.rouge)
		img.draw_to_grid("cursor_crosshairs", playstate.mouse_x, playstate.mouse_y)
	elseif playstate.current_map:in_bounds(playstate.mouse_x, playstate.mouse_y) and playstate.current_map:get_block(playstate.mouse_x, playstate.mouse_y) ~= 99 then
		love.graphics.setColor(color.white)
		if playstate.current_map:get_pawn(playstate.mouse_x, playstate.mouse_y) then
			img.draw_to_grid("cursor_corners_medium", playstate.mouse_x, playstate.mouse_y)
		else
			img.draw_to_grid("cursor_corners_small", playstate.mouse_x, playstate.mouse_y)
		end
	end

	-- tiny.refresh(world)
	-- if img.DrawingSystem.modified then
	-- 	img.DrawingSystem:onModify()
	-- end
	-- img.DrawingSystem:update()

	love.graphics.setColor(color.white)
end

-- function AimingState:exit()
-- end

return AimingState
