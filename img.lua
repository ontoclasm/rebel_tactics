local img = {tile = {}}

function img.render(state)
	love.graphics.setColor(color.white)

	img.update_tileset_batch(state.current_map)
	love.graphics.draw(img.tileset_batch, -(camera.px % TILE_SIZE), -(camera.py % TILE_SIZE))

	-- draw mouse cursor
	if state.current_map:in_bounds(state.mouse_x, state.mouse_y) and state.current_map:get_block(state.mouse_x, state.mouse_y) ~= 99 then
		love.graphics.setColor(color.rouge)
		img.draw_to_grid("cursor_mouse", state.mouse_x, state.mouse_y)

		-- love.graphics.setColor(color.rouge)
		-- love.graphics.draw(img.tileset, img.tile["cursor_mouse"], camera.screen_point_from_grid_point(state.mouse_x, state.mouse_y))
	end

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
		else
			local path = pathfinder:path_to( state.mouse_x, state.mouse_y )
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
		for x = 1, state.current_map.width do
			for y = 1, state.current_map.height do
				en = pathfinder.energies[ grid.hash( x, y ) ]
				if en then
					img.set_color_by_energy( en )
					img.draw_to_grid("dot", x, y)
				end
			end
		end
	end

	-- draw pawns
	for _, p in pairs(state.pawn_list) do
		-- xxx cull off-screens?
		love.graphics.setColor((p.id == state.selected_pawn) and color.mix(p.color, color.white, 0.5 + 0.5 * math.sin((gui_frame - state.selected_start_frame) / 15))
			or p.color)
		img.draw_to_grid("pawn", p.x, p.y, p.offset_x, p.offset_y)

		-- if p.id == state.selected_pawn then
		-- 	love.graphics.setColor(color.mix(p.color, color.white, 0.5 + 0.5 * math.sin((gui_frame - state.selected_start_frame) / 15)))
		-- else
		-- 	love.graphics.setColor(p.color)
		-- end
		-- love.graphics.draw(img.tileset, img.tile["pawn"], camera.screen_point_from_grid_point(p.x, p.y))
	end

	-- tiny.refresh(world)
	-- if img.DrawingSystem.modified then
	-- 	img.DrawingSystem:onModify()
	-- end
	-- img.DrawingSystem:update()

	love.graphics.setColor(color.white)
end

function img.setup()
	img.cursor = love.graphics.newImage("assets/img/cursor.png")

	img.tileset = love.graphics.newImage("assets/img/tileset.png")
	img.tileset:setFilter("nearest", "linear")

	img.nq("block",					 0,	 0)
	img.nq("edge_thick",			 1,	 0)
	img.nq("edge_thin",				 2,	 0)
	img.nq("edge_dotted",			 3,	 0)
	img.nq("cap_thick",				 1,	 1)
	img.nq("cap_thin",				 2,	 1)
	img.nq("cap_dotted",			 3,	 1)
	img.nq("pawn",					 0,	 2)
	img.nq("cursor_mouse",			 0,	 3)
	img.nq("dot",					 1,	 3)

	img.view_tilewidth = math.ceil(window_w / TILE_SIZE)
	img.view_tileheight = math.ceil(window_h / TILE_SIZE)

	img.tileset_batch = love.graphics.newSpriteBatch(img.tileset, 2 * (img.view_tilewidth + 1) * (img.view_tileheight + 1))
	img.tileset_batch_is_dirty = true
end

function img.nq(name, imgx, imgy)
	img.tile[name] = love.graphics.newQuad(imgx * TILE_SIZE, imgy * TILE_SIZE, TILE_SIZE, TILE_SIZE,
										   img.tileset:getWidth(), img.tileset:getHeight())
end

local old_corner_x = -9999
local old_corner_y = -9999
function img.update_tileset_batch(map)
	corner_x, corner_y = math.floor(camera.px/TILE_SIZE), math.floor(camera.py/TILE_SIZE)

	-- rebuild the batch if we need to recenter it, or if the dirty flag is set
	if img.tileset_batch_is_dirty or corner_x ~= old_corner_x or corner_y ~= old_corner_y then
		img.tileset_batch:clear()

		local tile_name = nil
		local tile_color = nil

		-- draw blocks
		for x=0, img.view_tilewidth do
			for y=0, img.view_tileheight do
				if map:in_bounds(x + corner_x, y + corner_y) then
					block_tile = img.block_tile[map:get_block(x + corner_x, y + corner_y)]
					if block_tile then
						img.tileset_batch:setColor(block_tile[2])
						img.tileset_batch:add(img.tile[block_tile[1]], x * TILE_SIZE, y * TILE_SIZE)
					end
				end
			end
		end

		-- draw edges
		for x=0, img.view_tilewidth do
			for y=0, img.view_tileheight do
				if map:in_bounds(x + corner_x, y + corner_y) then
					edge_tile = img.edge_tile[map:get_edge(x + corner_x, y + corner_y, "n")]
					if edge_tile then
						img.tileset_batch:setColor(edge_tile[2])
						img.tileset_batch:add(img.tile[edge_tile[1]], x * TILE_SIZE, y * TILE_SIZE - 2)
					end
				elseif map:in_bounds(x + corner_x, y + corner_y - 1) then -- southern edge
					edge_tile = img.edge_tile[map:get_edge(x + corner_x, y + corner_y - 1, "s")]
					if edge_tile then
						img.tileset_batch:setColor(edge_tile[2])
						img.tileset_batch:add(img.tile[edge_tile[1]], x * TILE_SIZE, y * TILE_SIZE - 2)
					end
				end
			end
		end
		for x=0, img.view_tilewidth do
			for y=0, img.view_tileheight do
				if map:in_bounds(x + corner_x, y + corner_y) then
					edge_tile = img.edge_tile[map:get_edge(x + corner_x, y + corner_y, "w")]
					if edge_tile then
						img.tileset_batch:setColor(edge_tile[2])
						img.tileset_batch:add(img.tile[edge_tile[1]], x * TILE_SIZE + 2, y * TILE_SIZE, PI_2)
					end
				elseif map:in_bounds(x + corner_x - 1, y + corner_y) then -- eastern edge
					edge_tile = img.edge_tile[map:get_edge(x + corner_x - 1, y + corner_y, "e")]
					if edge_tile then
						img.tileset_batch:setColor(edge_tile[2])
						img.tileset_batch:add(img.tile[edge_tile[1]], x * TILE_SIZE + 2, y * TILE_SIZE, PI_2)
					end
				end
			end
		end

		-- draw wall caps
		for x=0, img.view_tilewidth+1 do
			for y=0, img.view_tileheight+1 do
				if x + corner_x >= 1 and x + corner_x <= map.width + 1 and y + corner_y >= 1 and y + corner_y <= map.height + 1 then
					cap_tile = img.cap_tile[map:get_nw_cap(x + corner_x, y + corner_y)]
					if cap_tile then
						img.tileset_batch:setColor(cap_tile[2])
						img.tileset_batch:add(img.tile[cap_tile[1]], (x - 0.5) * TILE_SIZE, (y - 0.5) * TILE_SIZE)
					end
				end
			end
		end

		img.tileset_batch:setColor(color.white)

		img.tileset_batch:flush()

		old_corner_x, old_corner_y = corner_x, corner_y
		img.tileset_batch_is_dirty = false
	end
end

local px, py
function img.draw_to_grid(tilename, x, y, offset_x, offset_y)
	px, py = camera.screen_point_from_grid_point(x, y)
	px = px + (offset_x or 0)
	py = py + (offset_y or 0)
	love.graphics.draw(img.tileset, img.tile[tilename], px, py, 0, 1, 1, TILE_CENTER, TILE_CENTER)
end

function img.set_color_by_energy( en )
	if en >= 1000000 then
		love.graphics.setColor( color.white )
	elseif en >= 1000 then
		love.graphics.setColor( color.ltblue )
	else
		love.graphics.setColor( color.orange )
	end
end

--

img.block_tile = {}

img.block_tile[ 1] = { "block", color.grey01 }
img.block_tile[ 2] = { "block", color.grey02 }
img.block_tile[ 3] = { "block", color.grey03 }
img.block_tile[99] = { "block", color.bg }

img.edge_tile = {}

img.edge_tile[ 3] = { "edge_thin", color.brown }
img.edge_tile[99] = { "edge_thick", color.grey06 }

img.cap_tile = {}

img.cap_tile[ 3] = { "cap_thin", color.brown }
img.cap_tile[99] = { "cap_thick", color.grey06 }

return img
