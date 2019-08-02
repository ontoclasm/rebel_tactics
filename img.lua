local img = {tile = {}}

function img.setup()
	img.cursor = love.graphics.newImage("assets/img/cursor.png")

	img.tileset = love.graphics.newImage("assets/img/tileset.png")
	img.tileset:setFilter("nearest", "linear")

	img.nq("block",					 0,	 0)
	img.nq("pawn",					 0,	 2)
	img.nq("cursor_mouse",			 0,	 3)
	img.nq("dot",					 1,	 3)
	img.nq("hatching",				 2,	 3)

	img.nq_edge("edge_thick",		 0,	 0)
	img.nq_edge("edge_thin",		 1,	 0)
	img.nq_edge("edge_dotted",		 2,	 0)

	img.view_tilewidth = math.ceil(window_w / TILE_SIZE)
	img.view_tileheight = math.ceil(window_h / TILE_SIZE)

	img.tileset_batch = love.graphics.newSpriteBatch(img.tileset, 2 * (img.view_tilewidth + 1) * (img.view_tileheight + 1))
	img.tileset_batch_is_dirty = true
end

function img.nq(name, imgx, imgy)
	img.tile[name] = love.graphics.newQuad(imgx * TILE_SIZE, imgy * TILE_SIZE, TILE_SIZE, TILE_SIZE,
										   img.tileset:getWidth(), img.tileset:getHeight())
end

function img.nq_edge(name, imgx, imgy)
	img.tile[name] = love.graphics.newQuad(imgx * 32, 168 + imgy * 8, 32, 8,
										   img.tileset:getWidth(), img.tileset:getHeight())
end

local old_corner_x = -9999
local old_corner_y = -9999
function img.update_tileset_batch(map)
	corner_x, corner_y = math.floor(camera.px/TILE_SIZE), math.floor(camera.py/TILE_SIZE)

	-- rebuild the batch if we need to recenter it, or if the dirty flag is set
	if img.tileset_batch_is_dirty or corner_x ~= old_corner_x or corner_y ~= old_corner_y then
		img.tileset_batch:clear()

		local thing, thing_elev

		-- draw blocks
		for x=0, img.view_tilewidth do
			for y=0, img.view_tileheight do
				if map:in_bounds(x + corner_x, y + corner_y) then
					thing, thing_elev = map:get_block(x + corner_x, y + corner_y)
					if thing then
						img.tileset_batch:setColor(block_data[thing].colors[thing_elev] or block_data[thing].colors[-1])
						img.tileset_batch:add(img.tile[block_data[thing].tile], x * TILE_SIZE, y * TILE_SIZE)
					end
				end
			end
		end

		-- draw edges
		for x=0, img.view_tilewidth do
			for y=0, img.view_tileheight do
				if map:in_bounds(x + corner_x, y + corner_y) then
					thing, thing_elev = map:get_edge(x + corner_x, y + corner_y, "n")
					if thing then
						img.tileset_batch:setColor(edge_data[thing].colors[thing_elev] or edge_data[thing].colors[-1])
						img.tileset_batch:add(img.tile[edge_data[thing].tile], x * TILE_SIZE - 4, y * TILE_SIZE - 4)
					end
				elseif map:in_bounds(x + corner_x, y + corner_y - 1) then -- southern edge
					thing, thing_elev = map:get_edge(x + corner_x, y + corner_y - 1, "s")
					if thing then
						img.tileset_batch:setColor(edge_data[thing].colors[thing_elev] or edge_data[thing].colors[-1])
						img.tileset_batch:add(img.tile[edge_data[thing].tile], x * TILE_SIZE - 4, y * TILE_SIZE - 4)
					end
				end
			end
		end
		for x=0, img.view_tilewidth do
			for y=0, img.view_tileheight do
				if map:in_bounds(x + corner_x, y + corner_y) then
					thing, thing_elev = map:get_edge(x + corner_x, y + corner_y, "w")
					if thing then
						img.tileset_batch:setColor(edge_data[thing].colors[thing_elev] or edge_data[thing].colors[-1])
						img.tileset_batch:add(img.tile[edge_data[thing].tile], x * TILE_SIZE + 4, y * TILE_SIZE - 4, PI_2)
					end
				elseif map:in_bounds(x + corner_x - 1, y + corner_y) then -- eastern edge
					thing, thing_elev = map:get_edge(x + corner_x - 1, y + corner_y, "e")
					if thing then
						img.tileset_batch:setColor(edge_data[thing].colors[thing_elev] or edge_data[thing].colors[-1])
						img.tileset_batch:add(img.tile[edge_data[thing].tile], x * TILE_SIZE + 4, y * TILE_SIZE - 4, PI_2)
					end
				end
			end
		end

		-- draw wall caps
		-- for x=0, img.view_tilewidth+1 do
		-- 	for y=0, img.view_tileheight+1 do
		-- 		if x + corner_x >= 1 and x + corner_x <= map.width + 1 and y + corner_y >= 1 and y + corner_y <= map.height + 1 then
		-- 			thing, thing_elev = map:get_nw_cap(x + corner_x, y + corner_y)
		-- 			if thing then
		-- 				img.tileset_batch:setColor(edge_data[thing].colors[thing_elev] or edge_data[thing].colors[-1])
		-- 				img.tileset_batch:add(img.tile[edge_data[thing].cap_tile], x * TILE_SIZE, y * TILE_SIZE - 2)
		-- 			end
		-- 		end
		-- 	end
		-- end

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

function img.set_color_by_dir( dir )
	if dir == "s" then
		love.graphics.setColor( color.green )
	elseif dir == "n" then
		love.graphics.setColor( color.ltblue )
	elseif dir == "e" then
		love.graphics.setColor( color.yellow )
	elseif dir == "w" then
		love.graphics.setColor( color.orange )
	else
		love.graphics.setColor( color.white )
	end
end

--

-- img.block_tile = {}

-- img.block_tile[ 1] = { "block", color.grey01 }
-- img.block_tile[ 2] = { "block", color.grey02 }
-- img.block_tile[ 3] = { "block", color.grey03 }
-- img.block_tile[99] = { "block", color.bg }

-- img.edge_tile = {}

-- img.edge_tile[ 3] = { "edge_thin", color.brown }
-- img.edge_tile[99] = { "edge_thick", color.grey06 }

-- img.cap_tile = {}

-- img.cap_tile[ 3] = { "cap_thin", color.brown }
-- img.cap_tile[99] = { "cap_thick", color.grey06 }

return img
