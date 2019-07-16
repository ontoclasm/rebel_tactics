local img = {tile = {}}

function img.render(state)
	love.graphics.setColor(color.white)

	img.update_tileset_batch(state.current_map)
	-- love.graphics.draw(img.tileset_batch, -(camera.px % TILE_SIZE), -(camera.py % TILE_SIZE))
	love.graphics.draw(img.tileset_batch, 0, 0)

	-- draw all drawables
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


	img.view_tilewidth = math.ceil(window_w / TILE_SIZE)
	img.view_tileheight = math.ceil(window_h / TILE_SIZE)

	img.tileset_batch = love.graphics.newSpriteBatch(img.tileset, 2 * (img.view_tilewidth + 1) * (img.view_tileheight + 1))
	img.tileset_batch_is_dirty = true
end

function img.nq(name, x, y)
	img.tile[name] = love.graphics.newQuad(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE,
										   img.tileset:getWidth(), img.tileset:getHeight())
end

local tileset_batch_old_gx = -9999
local tileset_batch_old_gy = -9999
function img.update_tileset_batch(map)
	-- new_gx, new_gy = math.floor(camera.x/TILE_SIZE), math.floor(camera.y/TILE_SIZE)
	new_gx, new_gy = 0, 0

	-- rebuild the batch if we need to recenter it, or if the dirty flag is set
	if img.tileset_batch_is_dirty or new_gx ~= tileset_batch_old_gx or new_gy ~= tileset_batch_old_gy then
		img.tileset_batch:clear()

		local tile_name = nil
		local tile_color = nil

		-- draw blocks
		for gx=0, img.view_tilewidth-1 do
			for gy=0, img.view_tileheight-1 do
				if map:in_bounds(gx, gy) then
					tile_name, tile_color = img.block_tile(map:get_block(gx, gy))
					if tile_name then
						img.tileset_batch:setColor(tile_color)
						img.tileset_batch:add(img.tile[tile_name], gx * TILE_SIZE, gy * TILE_SIZE)
					end
				end
			end
		end

		-- draw edges
		for gx=0, img.view_tilewidth-1 do
			for gy=0, img.view_tileheight-1 do
				if map:in_bounds(gx, gy) then
					tile_name, tile_color = img.edge_tile(map:get_edge(gx, gy, "n"))
					if tile_name then
						img.tileset_batch:setColor(tile_color)
						img.tileset_batch:add(img.tile[tile_name], gx * TILE_SIZE, gy * TILE_SIZE - 2)
					end
				elseif map:in_bounds(gx, gy - 1) then -- southern edge
					tile_name, tile_color = img.edge_tile(map:get_edge(gx, gy - 1, "s"))
					if tile_name then
						img.tileset_batch:setColor(tile_color)
						img.tileset_batch:add(img.tile[tile_name], gx * TILE_SIZE, gy * TILE_SIZE - 2)
					end
				end
			end
		end
		for gx=0, img.view_tilewidth-1 do
			for gy=0, img.view_tileheight-1 do
				if map:in_bounds(gx, gy) then
					tile_name, tile_color = img.edge_tile(map:get_edge(gx, gy, "w"))
					if tile_name then
						img.tileset_batch:setColor(tile_color)
						img.tileset_batch:add(img.tile[tile_name], gx * TILE_SIZE + 2, gy * TILE_SIZE, PI_2)
					end
				elseif map:in_bounds(gx - 1, gy) then -- eastern edge
					tile_name, tile_color = img.edge_tile(map:get_edge(gx - 1, gy, "e"))
					if tile_name then
						img.tileset_batch:setColor(tile_color)
						img.tileset_batch:add(img.tile[tile_name], gx * TILE_SIZE + 2, gy * TILE_SIZE, PI_2)
					end
				end
			end
		end

		img.tileset_batch:setColor(color.white)

		img.tileset_batch:flush()

		tileset_batch_old_gx, tileset_batch_old_gy = new_gx, new_gy
		img.tileset_batch_is_dirty = false
	end
end

function img.block_tile(block)
	if block == 2 then
		return "block", color.dkblue
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

return img
