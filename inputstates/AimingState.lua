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
	local p = playstate:get_selected_pawn()
	if not self.visible_tiles then
		--calculate FOV
		self.visible_tiles = {}
		playstate:calculate_fov(p.x, p.y, self.visible_tiles)
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
	elseif controller:pressed( 'b' ) then
		self.manager:switch_to("Selected")
	elseif not playstate.animating then
		-- enact orders
		if controller:pressed( 'r2' ) then
			-- FIRE
			error("BANG")
		end
	end
end

function AimingState:draw( playstate )
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

	-- draw FoV
	if self.visible_tiles then
		love.graphics.setColor(color.bg)
		for x = 1, playstate.current_map.width do
			for y = 1, playstate.current_map.height do
				if not self.visible_tiles[grid.hash(x,y)] then
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

-- function AimingState:exit()
-- end

return AimingState
