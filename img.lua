local img = {tile = {}}

function img.render(state)
	love.graphics.setColor(color.white)

	img.update_tileset_batch(state.current_map)
	love.graphics.draw(img.tileset_batch, -(camera.px % TILE_SIZE), -(camera.py % TILE_SIZE))

	-- draw mouse cursor
	if state.current_map:in_bounds(state.mouse_x, state.mouse_y) then
		love.graphics.setColor(color.rouge)
		img.draw_to_grid("cursor_mouse", state.mouse_x, state.mouse_y)

		-- love.graphics.setColor(color.rouge)
		-- love.graphics.draw(img.tileset, img.tile["cursor_mouse"], camera.screen_point_from_grid_point(state.mouse_x, state.mouse_y))
	end

	-- pathfinder debug
	if pathfinder.on then
		local en
		for x = 1, state.current_map.width do
			for y = 1, state.current_map.height do
				en = pathfinder.energies[ grid.hash( x, y ) ]
				if en then
					if en >= 1000000 then
						love.graphics.setColor( color.white )
						img.draw_to_grid("dot", x, y)
						love.graphics.print( pathfinder.hops[ grid.hash( x, y ) ] or "", camera.screen_point_from_grid_point( x, y ) )
					elseif en >= 1000 then
						love.graphics.setColor( color.ltblue )
						img.draw_to_grid("dot", x, y)
						love.graphics.print( pathfinder.hops[ grid.hash( x, y ) ] or "", camera.screen_point_from_grid_point( x, y ) )
					else
						love.graphics.setColor( color.orange )
						img.draw_to_grid("dot", x, y)
						love.graphics.print( pathfinder.hops[ grid.hash( x, y ) ] or "", camera.screen_point_from_grid_point( x, y ) )
					end
				end
			end
		end

		local path = pathfinder:path_to( state.mouse_x, state.mouse_y )
		if path then
			local a, b, c, d, en
			for i = 1, #path - 1 do
				en = pathfinder.energies[ path[ i+1 ] ]
				if en >= 1000000 then
					love.graphics.setColor( color.white )
				elseif en >= 1000 then
					love.graphics.setColor( color.ltblue )
				else
					love.graphics.setColor( color.orange )
				end
				a, b = grid.unhash( path[ i ] )
				c, d = grid.unhash( path[ i+1 ] )
				a, b = camera.screen_point_from_grid_point( a, b )
				c, d = camera.screen_point_from_grid_point( c, d )
				love.graphics.line( a, b, c, d )
			end
		end
	end

	-- draw pawns
	for _, p in pairs(state.pawn_list) do
		-- xxx cull off-screens?
		love.graphics.setColor((p.id == state.selected_pawn) and color.mix(p.color, color.white, 0.5 + 0.5 * math.sin((gui_frame - state.selected_start_frame) / 15))
			or p.color)
		img.draw_to_grid("pawn", p.x, p.y)

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
	img.nq("edge_dotted",			 2,	 0)
	img.nq("pawn",					 3,	 0)
	img.nq("cursor_mouse",			 4,	 0)
	img.nq("dot",					 5,	 0)
	img.nq("arrow_n",				 0,	 1)
	img.nq("arrow_ne",				 1,	 1)

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
					tile_name, tile_color = img.block_tile(map:get_block(x + corner_x, y + corner_y))
					if tile_name then
						img.tileset_batch:setColor(tile_color)
						img.tileset_batch:add(img.tile[tile_name], x * TILE_SIZE, y * TILE_SIZE)
					end
				end
			end
		end

		-- draw edges
		for x=0, img.view_tilewidth do
			for y=0, img.view_tileheight do
				if map:in_bounds(x + corner_x, y + corner_y) then
					tile_name, tile_color = img.edge_tile(map:get_edge(x + corner_x, y + corner_y, "n"))
					if tile_name then
						img.tileset_batch:setColor(tile_color)
						img.tileset_batch:add(img.tile[tile_name], x * TILE_SIZE, y * TILE_SIZE - 2)
					end
				elseif map:in_bounds(x + corner_x, y + corner_y - 1) then -- southern edge
					tile_name, tile_color = img.edge_tile(map:get_edge(x + corner_x, y + corner_y - 1, "s"))
					if tile_name then
						img.tileset_batch:setColor(tile_color)
						img.tileset_batch:add(img.tile[tile_name], x * TILE_SIZE, y * TILE_SIZE - 2)
					end
				end
			end
		end
		for x=0, img.view_tilewidth do
			for y=0, img.view_tileheight do
				if map:in_bounds(x + corner_x, y + corner_y) then
					tile_name, tile_color = img.edge_tile(map:get_edge(x + corner_x, y + corner_y, "w"))
					if tile_name then
						img.tileset_batch:setColor(tile_color)
						img.tileset_batch:add(img.tile[tile_name], x * TILE_SIZE + 2, y * TILE_SIZE, PI_2)
					end
				elseif map:in_bounds(x + corner_x - 1, y + corner_y) then -- eastern edge
					tile_name, tile_color = img.edge_tile(map:get_edge(x + corner_x - 1, y + corner_y, "e"))
					if tile_name then
						img.tileset_batch:setColor(tile_color)
						img.tileset_batch:add(img.tile[tile_name], x * TILE_SIZE + 2, y * TILE_SIZE, PI_2)
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

function img.block_tile(block)
	if block == 2 then
		return "block", color.ltgrey
	else
		return "block", color.blue
	end
end

function img.edge_tile(edge)
	if edge == 2 then
		return "edge_thick", color.white
	elseif edge == 3 then
		return "edge_dotted", color.yellow
	else
		return nil, nil
	end
end

local px, py
function img.draw_to_grid(tilename, x, y)
	px, py = camera.screen_point_from_grid_point(x, y)
	love.graphics.draw(img.tileset, img.tile[tilename], px, py, 0, 1, 1, TILE_CENTER, TILE_CENTER)
end

return img
