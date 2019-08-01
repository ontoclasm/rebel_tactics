local OpenState = class("OpenState")

OpenState.name = "Splash Screen"

function OpenState:init( manager )
	self.manager = manager
end

-- function OpenState:enter()
-- end

function OpenState:update( playstate )
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
		if pid then
			if not playstate.pawn_list[pid] then
				error()
			end
			playstate.selected_pawn = pid
			self.manager:switch_to("Selected")
		end
	end
end

function OpenState:draw( playstate )
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