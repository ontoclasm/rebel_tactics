local OpenState = class("OpenState")

OpenState.name = "Open State"

function OpenState:init( manager )
	self.manager = manager
end

-- function OpenState:enter()
-- end

function OpenState:update( playstate )
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

	if controller:pressed( 'r1' ) then
		local pid = playstate.current_map:get_pawn( playstate.mouse_x, playstate.mouse_y )
		if pid then
			if not playstate.pawn_list[pid] then
				error()
			end
			playstate.selected_pawn = pid
			self.manager:switch_to("Selected")
		end
	elseif controller:pressed( 'x' ) then
		self.debug_cover = not self.debug_cover
	end
end

function OpenState:draw( playstate )
	love.graphics.setColor(color.white)

	img.update_terrain_batches(playstate.current_map)
	for i = 1, img.NUM_TERRAIN_LAYERS do
		love.graphics.draw(img.tileset_batches[i], -(camera.px % TILE_SIZE), -(camera.py % TILE_SIZE))
	end

	-- draw mouse cursor
	if playstate.current_map:in_bounds(playstate.mouse_x, playstate.mouse_y) and playstate.current_map:get_block(playstate.mouse_x, playstate.mouse_y) ~= 99 then
		love.graphics.setColor(color.white)
		img.draw_to_grid("cursor_base", playstate.mouse_x, playstate.mouse_y)
		img.draw_to_grid("cursor_corners", playstate.mouse_x, playstate.mouse_y)
	end

	-- draw cover
	if self.debug_cover then
		love.graphics.setColor(color.yellow)
		for x = 1, playstate.current_map.width do
			for y = 1, playstate.current_map.height do
				img.draw_cover(x,y,playstate.current_map)
			end
		end
	end

	-- draw pawns
	for _, p in pairs(playstate.pawn_list) do
		-- xxx cull off-screens?
		love.graphics.setColor((p.id == playstate.selected_pawn) and color.mix(p.color, color.white, 0.5 + 0.5 * math.sin((gui_frame - playstate.selected_start_frame) / 15))
			or p.color)
		img.draw_to_grid("pawn", p.x, p.y, p.offset_x, p.offset_y)

		-- if p.id == playstate.selected_pawn then
		-- 	love.graphics.setColor(color.mix(p.color, color.white, 0.5 + 0.5 * math.sin((gui_frame - playstate.selected_start_frame) / 15)))
		-- else
		-- 	love.graphics.setColor(p.color)
		-- end
		-- love.graphics.draw(img.tileset, img.tile["pawn"], camera.screen_point_from_grid_point(p.x, p.y))
	end

	love.graphics.setColor(color.white)
end

-- function OpenState:exit()
-- end

return OpenState
