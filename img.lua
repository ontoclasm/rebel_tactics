local img = {tile = {}}

img.NUM_TERRAIN_LAYERS = 7

function img.setup()
	img.cursor = love.graphics.newImage("assets/img/cursor.png")

	img.tileset = love.graphics.newImage("assets/img/tileset_32.png")
	img.tileset:setFilter("nearest", "linear")

	img.nq("block",							 0,	 0)
	img.nq("dot",							 1,	 0)
	img.nq("hatching",						 2,	 0)
	img.nq("hatching_half",					 3,	 0)
	img.nq("pawn",							 0,	 1)

	img.nq("cursor_base",					 0,	 2)
	img.nq("cursor_corners_medium",			 1,	 2)
	img.nq("cursor_corners_small",			 2,	 2)
	img.nq("cursor_hard_cover_n",			 3,	 2)
	img.nq("cursor_soft_cover_n",			 4,	 2)
	img.nq("cursor_circle_large",			 5,	 2)
	img.nq("cursor_circle_small",			 6,	 2)
	img.nq("cursor_crosshairs",				 7,	 2)

	img.nq_region("region_move",			 0,	 6)

	img.nq_edge("edge_thick",				 0,	 0)
	img.nq_edge("edge_thin",				 1,	 0)
	img.nq_edge("edge_dotted",				 2,	 0)

	img.view_tilewidth = math.ceil(window_w / TILE_SIZE)
	img.view_tileheight = math.ceil(window_h / TILE_SIZE)

	img.tileset_batches = {}
	for i = 1, img.NUM_TERRAIN_LAYERS do
		img.tileset_batches[i] = love.graphics.newSpriteBatch(img.tileset, 2 * (img.view_tilewidth + 1) * (img.view_tileheight + 1))
	end
	-- img.tileset_batch = love.graphics.newSpriteBatch(img.tileset, 2 * (img.view_tilewidth + 1) * (img.view_tileheight + 1))
	img.tileset_batches_are_dirty = true
end

function img.nq(name, imgx, imgy)
	img.tile[name] = love.graphics.newQuad(imgx * TILE_SIZE, imgy * TILE_SIZE, TILE_SIZE, TILE_SIZE,
										   img.tileset:getWidth(), img.tileset:getHeight())
end

function img.nq_edge(name, imgx, imgy)
	img.tile[name] = love.graphics.newQuad(imgx * 1.5 * TILE_SIZE, TILE_SIZE * 7 + imgy * 8, TILE_SIZE * 1.5, 8,
										   img.tileset:getWidth(), img.tileset:getHeight())
end

function img.nq_region(name, imgx, imgy)
	img.tile[name.."_ec"] = love.graphics.newQuad(imgx * TILE_SIZE, imgy * TILE_SIZE, TILE_SIZE / 2, TILE_SIZE / 2,
												  img.tileset:getWidth(), img.tileset:getHeight())
	img.tile[name.."_fe"] = love.graphics.newQuad((imgx+0.5) * TILE_SIZE, imgy * TILE_SIZE, TILE_SIZE / 2, TILE_SIZE / 2,
												  img.tileset:getWidth(), img.tileset:getHeight())
	img.tile[name.."_ic"] = love.graphics.newQuad(imgx * TILE_SIZE, (imgy+0.5) * TILE_SIZE, TILE_SIZE / 2, TILE_SIZE / 2,
												  img.tileset:getWidth(), img.tileset:getHeight())
	img.tile[name.."_in"] = love.graphics.newQuad((imgx+0.5) * TILE_SIZE, (imgy+0.5) * TILE_SIZE, TILE_SIZE / 2, TILE_SIZE / 2,
												  img.tileset:getWidth(), img.tileset:getHeight())
end

local old_corner_x = -9999
local old_corner_y = -9999
function img.update_terrain_batches(map)
	corner_x, corner_y = math.floor(camera.px/TILE_SIZE), math.floor(camera.py/TILE_SIZE)

	-- rebuild the batch if we need to recenter it, or if the dirty flag is set
	if img.tileset_batches_are_dirty or corner_x ~= old_corner_x or corner_y ~= old_corner_y then
		for i = 1, img.NUM_TERRAIN_LAYERS do
			img.tileset_batches[i]:clear()
		end

		local thing, thing_elev, layer

		-- draw blocks
		for x=0, img.view_tilewidth do
			for y=0, img.view_tileheight do
				if map:in_bounds(x + corner_x, y + corner_y) then
					thing, thing_elev = map:get_block(x + corner_x, y + corner_y)
					if thing then
						layer = img.layer_from_elev( thing_elev )
						img.tileset_batches[layer]:setColor(block_data[thing].colors[thing_elev] or block_data[thing].colors[-1])
						img.tileset_batches[layer]:add(img.tile[block_data[thing].tile], x * TILE_SIZE, y * TILE_SIZE)
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
						layer = img.layer_from_elev( thing_elev )
						img.tileset_batches[layer]:setColor(edge_data[thing].colors[thing_elev] or edge_data[thing].colors[-1])
						img.tileset_batches[layer]:add(img.tile[edge_data[thing].tile], x * TILE_SIZE - TILE_SIZE_QUARTER, y * TILE_SIZE - 4)
					end
				elseif map:in_bounds(x + corner_x, y + corner_y - 1) then -- southern edge
					thing, thing_elev = map:get_edge(x + corner_x, y + corner_y - 1, "s")
					if thing then
						layer = img.layer_from_elev( thing_elev )
						img.tileset_batches[layer]:setColor(edge_data[thing].colors[thing_elev] or edge_data[thing].colors[-1])
						img.tileset_batches[layer]:add(img.tile[edge_data[thing].tile], x * TILE_SIZE - TILE_SIZE_QUARTER, y * TILE_SIZE - 4)
					end
				end
			end
		end
		for x=0, img.view_tilewidth do
			for y=0, img.view_tileheight do
				if map:in_bounds(x + corner_x, y + corner_y) then
					thing, thing_elev = map:get_edge(x + corner_x, y + corner_y, "w")
					if thing then
						layer = img.layer_from_elev( thing_elev )
						img.tileset_batches[layer]:setColor(edge_data[thing].colors[thing_elev] or edge_data[thing].colors[-1])
						img.tileset_batches[layer]:add(img.tile[edge_data[thing].tile], x * TILE_SIZE + 4, y * TILE_SIZE - TILE_SIZE_QUARTER, PI_2)
					end
				elseif map:in_bounds(x + corner_x - 1, y + corner_y) then -- eastern edge
					thing, thing_elev = map:get_edge(x + corner_x - 1, y + corner_y, "e")
					if thing then
						layer = img.layer_from_elev( thing_elev )
						img.tileset_batches[layer]:setColor(edge_data[thing].colors[thing_elev] or edge_data[thing].colors[-1])
						img.tileset_batches[layer]:add(img.tile[edge_data[thing].tile], x * TILE_SIZE + 4, y * TILE_SIZE - TILE_SIZE_QUARTER, PI_2)
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

		for i = 1, img.NUM_TERRAIN_LAYERS do
			img.tileset_batches[i]:setColor(color.white)
		end

		old_corner_x, old_corner_y = corner_x, corner_y
		img.tileset_batches_are_dirty = false
	end
end

local px, py
function img.draw_to_grid(tilename, x, y, offset_px, offset_py, rotation)
	px, py = camera.screen_point_from_grid_point(x, y)
	px = px + (offset_px or 0)
	py = py + (offset_py or 0)
	love.graphics.draw(img.tileset, img.tile[tilename], px, py, rotation or 0, 1, 1, TILE_SIZE_HALF, TILE_SIZE_HALF)
end

function img.draw_to_grid_edge(tilename, x, y, offset_px, offset_py, rotation)
	px, py = camera.screen_point_from_grid_point(x, y)
	px = px + (offset_px or 0)
	py = py + (offset_py or 0)
	love.graphics.draw(img.tileset, img.tile[tilename], px, py, rotation or 0, 1, 1, TILE_SIZE_HALF + TILE_SIZE_QUARTER, TILE_SIZE_HALF + 4)
end

function img.draw_region_tile(name, x, y, neighborhood )
	-- neighborhood:
	-- [6][7][8]
	-- [5]   [1]
	-- [4][3][2]
	local offset = TILE_SIZE_QUARTER
	px, py = camera.screen_point_from_grid_point(x, y)

	-- top left
	if neighborhood[5] then
		if neighborhood[7] then
			if neighborhood[6] then
				love.graphics.draw(img.tileset, img.tile[name.."_in"], px - offset, py - offset, 0, 1, 1, offset, offset)
			else
				love.graphics.draw(img.tileset, img.tile[name.."_ic"], px - offset, py - offset, 0, 1, 1, offset, offset)
			end
		else
			love.graphics.draw(img.tileset, img.tile[name.."_fe"], px - offset, py - offset, 0, 1, 1, offset, offset)
		end
	else
		if neighborhood[7] then
			love.graphics.draw(img.tileset, img.tile[name.."_fe"], px - offset, py - offset, -PI_2, 1, 1, offset, offset)
		else
			love.graphics.draw(img.tileset, img.tile[name.."_ec"], px - offset, py - offset, 0, 1, 1, offset, offset)
		end
	end

	-- top right
	if neighborhood[1] then
		if neighborhood[7] then
			if neighborhood[8] then
				love.graphics.draw(img.tileset, img.tile[name.."_in"], px + offset, py - offset, 0, 1, 1, offset, offset)
			else
				love.graphics.draw(img.tileset, img.tile[name.."_ic"], px + offset, py - offset, PI_2, 1, 1, offset, offset)
			end
		else
			love.graphics.draw(img.tileset, img.tile[name.."_fe"], px + offset, py - offset, 0, 1, 1, offset, offset)
		end
	else
		if neighborhood[7] then
			love.graphics.draw(img.tileset, img.tile[name.."_fe"], px + offset, py - offset, PI_2, 1, 1, offset, offset)
		else
			love.graphics.draw(img.tileset, img.tile[name.."_ec"], px + offset, py - offset, PI_2, 1, 1, offset, offset)
		end
	end

	-- bottom left
	if neighborhood[5] then
		if neighborhood[3] then
			if neighborhood[4] then
				love.graphics.draw(img.tileset, img.tile[name.."_in"], px - offset, py + offset, 0, 1, 1, offset, offset)
			else
				love.graphics.draw(img.tileset, img.tile[name.."_ic"], px - offset, py + offset, -PI_2, 1, 1, offset, offset)
			end
		else
			love.graphics.draw(img.tileset, img.tile[name.."_fe"], px - offset, py + offset, PI, 1, 1, offset, offset)
		end
	else
		if neighborhood[3] then
			love.graphics.draw(img.tileset, img.tile[name.."_fe"], px - offset, py + offset, -PI_2, 1, 1, offset, offset)
		else
			love.graphics.draw(img.tileset, img.tile[name.."_ec"], px - offset, py + offset, -PI_2, 1, 1, offset, offset)
		end
	end

	-- bottom right
	if neighborhood[1] then
		if neighborhood[3] then
			if neighborhood[2] then
				love.graphics.draw(img.tileset, img.tile[name.."_in"], px + offset, py + offset, 0, 1, 1, offset, offset)
			else
				love.graphics.draw(img.tileset, img.tile[name.."_ic"], px + offset, py + offset, PI, 1, 1, offset, offset)
			end
		else
			love.graphics.draw(img.tileset, img.tile[name.."_fe"], px + offset, py + offset, PI, 1, 1, offset, offset)
		end
	else
		if neighborhood[3] then
			love.graphics.draw(img.tileset, img.tile[name.."_fe"], px + offset, py + offset, PI_2, 1, 1, offset, offset)
		else
			love.graphics.draw(img.tileset, img.tile[name.."_ec"], px + offset, py + offset, PI, 1, 1, offset, offset)
		end
	end
end

function img.draw_cover( x, y, map )
	local cover = map:get_cover(x, y, "n")
	if cover == 2 then
		img.draw_to_grid("cursor_hard_cover_n", x, y, 0, 0, 0)
	elseif cover == 1 then
		img.draw_to_grid("cursor_soft_cover_n", x, y, 0, 0, 0)
	end
	cover = map:get_cover(x, y, "s")
	if cover == 2 then
		img.draw_to_grid("cursor_hard_cover_n", x, y, 0, 0, math.pi)
	elseif cover == 1 then
		img.draw_to_grid("cursor_soft_cover_n", x, y, 0, 0, math.pi)
	end
	cover = map:get_cover(x, y, "e")
	if cover == 2 then
		img.draw_to_grid("cursor_hard_cover_n", x, y, 0, 0, PI_2)
	elseif cover == 1 then
		img.draw_to_grid("cursor_soft_cover_n", x, y, 0, 0, PI_2)
	end
	cover = map:get_cover(x, y, "w")
	if cover == 2 then
		img.draw_to_grid("cursor_hard_cover_n", x, y, 0, 0, 1.5 * math.pi)
	elseif cover == 1 then
		img.draw_to_grid("cursor_soft_cover_n", x, y, 0, 0, 1.5 * math.pi)
	end
end

function img.color_name_by_actions( act, elev )
	if act >= 2 then
		return "white"
	elseif act == 1 then
		return "mvblue"..((elev and img.color_suffix_from_elev(elev)) or "06")
	elseif act == 0 then
		return "mvorange"..((elev and img.color_suffix_from_elev(elev)) or "06")
	else
		return "oops"
	end
end

function img.color_suffix_from_elev(elev)
	if elev == 10 then
		return "01"
	elseif elev == 20 then
		return "02"
	else
		return "03"
	end
end

-- function img.set_color_by_dir( dir )
-- 	if dir == "s" then
-- 		love.graphics.setColor( color.green )
-- 	elseif dir == "n" then
-- 		love.graphics.setColor( color.ltblue )
-- 	elseif dir == "e" then
-- 		love.graphics.setColor( color.yellow )
-- 	elseif dir == "w" then
-- 		love.graphics.setColor( color.orange )
-- 	else
-- 		love.graphics.setColor( color.white )
-- 	end
-- end

function img.layer_from_elev( elev )
	if elev < 10 then
		return 1
	elseif elev < 20 then
		return 2
	elseif elev < 30 then
		return 3
	elseif elev < 40 then
		return 4
	elseif elev < 50 then
		return 5
	elseif elev < 60 then
		return 6
	else
		return 7
	end
end

return img
