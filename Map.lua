local Map = class( "Map" )

local MAP_HASH = 512
local EDGE_ROW_HASH_OFFSET = ( MAP_HASH * 2 ) + 1

function Map:init( width, height )
	if ( not width ) or width <= 0 or ( not height ) or height <= 0 then
		error( "bad map bounds: " .. width .. ", " .. height )
	end
	self.width, self.height = width, height
	self.blocks = {}
	self.edges = {}
	self.pawns = {}
end

function Map:in_bounds( x, y )
	return x >= 1 and x <= self.width and y >= 1 and y <= self.height
end

-- the block at (x, y) is stored at [x + (y - 1) * width]
function Map:set_block( x, y, kind, elev)
	if not self:in_bounds( x, y ) then
		error( "out of bounds: " .. x .. ", " .. y )
	else
		self.blocks[ x + (y - 1) * MAP_HASH ] = kind + 1000 * elev
	end
end

function Map:get_block( x, y )
	if not self:in_bounds( x, y ) then
		error( "out of bounds: " .. x .. ", " .. y )
	else
		local h = self.blocks[ x + (y - 1) * MAP_HASH ]
		if h then
			return h % 1000, math.floor(h / 1000)
		else
			return nil, nil
		end
	end
end

function Map:get_block_kind( x, y )
	if not self:in_bounds( x, y ) then
		error( "out of bounds: " .. x .. ", " .. y )
	else
		local h = self.blocks[ x + (y - 1) * MAP_HASH ]
		if h then
			return h % 1000
		else
			return nil
		end
	end
end

function Map:get_block_elev( x, y )
	if not self:in_bounds( x, y ) then
		error( "out of bounds: " .. x .. ", " .. y )
	else
		local h = self.blocks[ x + (y - 1) * MAP_HASH ]
		if h then
			return math.floor(h / 1000)
		else
			return nil
		end
	end
end

function Map:set_edge( x, y, side, kind )
	if not self:in_bounds( x, y ) then
		error( "out of bounds: " .. x .. ", " .. y )
	else
		local elev
		if side == "n" then
			self.edges[ x + (y - 1) * EDGE_ROW_HASH_OFFSET ] = kind
		elseif side == "w" then
			self.edges[ x + (y - 1) * EDGE_ROW_HASH_OFFSET + MAP_HASH ] = kind
		elseif side == "s" then
			self.edges[ x + y * EDGE_ROW_HASH_OFFSET ] = kind
		elseif side == "e" then
			self.edges[ (x + 1) + (y - 1) * EDGE_ROW_HASH_OFFSET + MAP_HASH ] = kind
		else
			error( "bad edge: " .. side )
		end
	end
end

function Map:get_edge( x, y, side )
	if not self:in_bounds( x, y ) then
		error( "out of bounds: " .. x .. ", " .. y )
	else
		local edge, elev
		if side == "n" then
			edge = self.edges[ x + (y - 1) * EDGE_ROW_HASH_OFFSET ]
			elev = self:in_bounds(x, y-1) and (math.max(self:get_block_elev(x,y), self:get_block_elev(x,y-1))) or 999
		elseif side == "w" then
			edge = self.edges[ x + (y - 1) * EDGE_ROW_HASH_OFFSET + MAP_HASH ]
			elev = self:in_bounds(x-1, y) and (math.max(self:get_block_elev(x,y), self:get_block_elev(x-1,y))) or 999
		elseif side == "s" then
			edge = self.edges[ x + y * EDGE_ROW_HASH_OFFSET ]
			elev = self:in_bounds(x, y+1) and (math.max(self:get_block_elev(x,y), self:get_block_elev(x,y+1))) or 999
		elseif side == "e" then
			edge = self.edges[ (x + 1) + (y - 1) * EDGE_ROW_HASH_OFFSET + MAP_HASH ]
			elev = self:in_bounds(x+1, y) and (math.max(self:get_block_elev(x,y), self:get_block_elev(x+1,y))) or 999
		else
			error( "bad edge: " .. side )
		end

		if edge then
			elev = elev + edge_data[edge].elev
			return edge, elev -- kind, elev
		else
			return nil, nil
		end
	end
end

function Map:get_nw_cap( x, y )
	if not ( x >= 1 and x <= self.width + 1 and y >= 1 and y <= self.height + 1 ) then
		error( "out of bounds: " .. x .. ", " .. y )
	else
		local cap, cap_elev = -999, -999
		local edge, edge_elev

		local h = self.edges[ x + (y - 1) * EDGE_ROW_HASH_OFFSET ]
		if h then
			edge, edge_elev = x % 1000, math.floor(x / 1000)
			if edge_elev > cap_elev or (edge_elev == cap_elev and edge_data[edge].draw_priority > edge_data[edge].draw_priority) then
				cap, elev = edge, edge_elev
			end
		end

		h = self.edges[ x + (y - 1) * EDGE_ROW_HASH_OFFSET + MAP_HASH ]
		if h then
			edge, edge_elev = x % 1000, math.floor(x / 1000)
			if edge_elev > cap_elev or (edge_elev == cap_elev and edge_data[edge].draw_priority > edge_data[edge].draw_priority) then
				cap, elev = edge, edge_elev
			end
		end

		h = self.edges[ (x - 1) + (y - 1) * EDGE_ROW_HASH_OFFSET ]
		if h then
			edge, edge_elev = x % 1000, math.floor(x / 1000)
			if edge_elev > cap_elev or (edge_elev == cap_elev and edge_data[edge].draw_priority > edge_data[edge].draw_priority) then
				cap, elev = edge, edge_elev
			end
		end

		h = self.edges[ x + (y - 2) * EDGE_ROW_HASH_OFFSET + MAP_HASH ]
		if h then
			edge, edge_elev = x % 1000, math.floor(x / 1000)
			if edge_elev > cap_elev or (edge_elev == cap_elev and edge_data[edge].draw_priority > edge_data[edge].draw_priority) then
				cap, elev = edge, edge_elev
			end
		end

		if cap > -999 then
			return cap, elev
		else
			return nil, nil
		end
	end
end

function Map:set_pawn( x, y, pawn_id )
	if not self:in_bounds( x, y ) then
		error( "out of bounds: " .. x .. ", " .. y )
	else
		self.pawns[ x + (y - 1) * MAP_HASH ] = pawn_id
	end
end

function Map:get_pawn( x, y )
	if not self:in_bounds( x, y ) then
		error( "out of bounds: " .. x .. ", " .. y )
	else
		return self.pawns[ x + (y - 1) * MAP_HASH ]
	end
end

function Map:delete_pawn( x, y )
	if not self:in_bounds( x, y ) then
		error( "out of bounds: " .. x .. ", " .. y )
	else
		local pid = self.pawns[ x + (y - 1) * MAP_HASH ]
		self.pawns[ x + (y - 1) * MAP_HASH ] = nil
		return pid
	end
end

function Map:move_pawn( from_x, from_y, to_x, to_y )
	local pid = self:delete_pawn( from_x, from_y )
	if not pid then
		error( "missing pawn at " .. from_x .. ", " .. from_y )
	else
		self:set_pawn( to_x, to_y, pid )
	end
end

function Map:edge_is_translucent(x,y,dir)
	if (not self:in_bounds(x,y)) then
		return false
	else
		local edge, _ = self:get_edge(x,y,dir)
		return block_data[self:get_block_kind(x,y)].translucent and (not edge or edge_data[edge].translucent)
	end
end

function Map:find_random_floor()
	local x, y, b
	for tries = 1, 1000 do
		x = love.math.random( 1, self.width )
		y = love.math.random( 1, self.height )
		if block_data[self:get_block_kind( x, y )].floor and not self:get_pawn( x, y ) then
			return x, y
		end
	end
	error( "couldn't find floor" )
end

function Map:can_lean_south(x,y)
	if not self:in_bounds(x,y) or not self:in_bounds(x,y+1) then
		return false
	else

		return self:step_cost(x, y, 0, 1) == 1
			and ((self:get_edge( x, y, "w") and not self:get_edge( x, y+1, "w")) or (self:get_edge( x, y, "e") and not self:get_edge( x, y+1, "e")))
	end
end

function Map:can_lean_north(x,y)
	if not self:in_bounds(x,y) or not self:in_bounds(x,y-1) then
		return false
	else
		return self:step_cost(x, y, 0, -1) == 1
			and ((self:get_edge( x, y, "w") and not self:get_edge( x, y-1, "w")) or (self:get_edge( x, y, "e") and not self:get_edge( x, y-1, "e")))
	end
end

function Map:can_lean_west(x,y)
	if not self:in_bounds(x,y) or not self:in_bounds(x-1,y) then
		return false
	else
		return self:step_cost(x, y, -1, 0) == 1
			and ((self:get_edge( x, y, "n") and not self:get_edge( x-1, y, "n")) or (self:get_edge( x, y, "s") and not self:get_edge( x-1, y, "s")))
	end
end

function Map:can_lean_east(x,y)
	if not self:in_bounds(x,y) or not self:in_bounds(x+1,y) then
		return false
	else
		return self:step_cost(x, y, 1, 0) == 1
			and ((self:get_edge( x, y, "n") and not self:get_edge( x+1, y, "n")) or (self:get_edge( x, y, "s") and not self:get_edge( x+1, y, "s")))
	end
end

function Map:step_cost( from_x, from_y, dx, dy )
	-- XXX rewrite


	-- 99: can't move there
	-- 10: ends move to step here
	--  1: takes a normal step

	if math.abs( dx ) > 1 or math.abs( dy ) > 1
		or (not self:in_bounds(from_x, from_y)) or (not self:in_bounds(from_x + dx, from_y + dy))
		or self:get_pawn( from_x + dx, from_y + dy ) then
		return 99
	else
		if math.abs(dx) + math.abs(dy) == 2 then
			-- diagonal
			-- can only move diagonally in a very specific case
			return self:diagonal_step_cost( from_x, from_y, dx, dy )
		else
			-- orth
			return self:orth_step_cost( from_x, from_y, dx, dy )
		end

		-- return self:terrain_move_cost( from_x, from_y, dx, dy )
	end
end

function Map:diagonal_step_cost( from_x, from_y, dx, dy )
	local a, a_e = self:get_block( from_x, from_y )
	local b, b_e = self:get_block( from_x + dx, from_y + dy )
	return (a_e == b_e and math.max( self:orth_step_cost( from_x, from_y, dx,0 ),
									 self:orth_step_cost( from_x+dx, from_y, 0,dy ),
									 self:orth_step_cost( from_x, from_y, 0,dy ),
									 self:orth_step_cost( from_x, from_y+dy, dx,0 ) ) == 1) and 1 or 99
end

function Map:orth_step_cost( from_x, from_y, dx, dy )
	local a, a_e = self:get_block( from_x, from_y )
	local b, b_e = self:get_block( from_x + dx, from_y + dy )
	local edge, edge_elev = self:get_edge( from_x, from_y, grid.orth_dir_from_delta( dx, dy ))
	if a and b then
		local elev_diff
		if edge then
			elev_diff = math.max(edge_elev - a_e, b_e - a_e)
		else
			elev_diff = b_e - a_e
		end

		if elev_diff > 10 then
			-- too high
			return 99
		elseif elev_diff == 10 then
			-- hop up one level
			if block_data[b].floor then
				return 10
			else
				return 99
			end
		else
			-- same level or below
			if block_data[b].floor then
				return 1
			else
				return 99
			end
		end
	else
		return 99
	end
end

-- function Map:terrain_move_cost( from_x, from_y, dx, dy )
-- 	if dx == 1 then
-- 		if dy == 1 then
-- 			-- se
-- 			if math.max( self:terrain_move_cost( from_x, from_y, 1,0 ),
-- 						 self:terrain_move_cost( from_x+1, from_y, 0,1 ),
-- 						 self:terrain_move_cost( from_x, from_y, 0,1 ),
-- 						 self:terrain_move_cost( from_x, from_y+1, 1,0 ),
-- 						 diagonal_move_cost( self:get_block( from_x, from_y ), self:get_block( from_x + dx, from_y + dy ) ) ) == 1 then
-- 				return 1
-- 			else
-- 				return 99
-- 			end
-- 		elseif dy == 0 then
-- 			-- e
-- 			return orth_block_move_cost( from_x, from_y, dx, dy )
-- 		else -- dy == -1
-- 			-- ne
-- 			if math.max( self:terrain_move_cost( from_x, from_y, 1,0 ),
-- 						 self:terrain_move_cost( from_x+1, from_y, 0,-1 ),
-- 						 self:terrain_move_cost( from_x, from_y, 0,-1 ),
-- 						 self:terrain_move_cost( from_x, from_y-1, 1,0 ),
-- 						 diagonal_move_cost( self:get_block( from_x, from_y ), self:get_block( from_x + dx, from_y + dy ) ) ) == 1 then
-- 				return 1
-- 			else
-- 				return 99
-- 			end
-- 		end
-- 	elseif dx == 0 then
-- 		if dy == 1 then
-- 			-- s
-- 			return orth_block_move_cost( from_x, from_y, dx, dy )
-- 		elseif dy == 0 then
-- 			-- ???
-- 			error()
-- 		else -- dy == -1
-- 			-- n
-- 			return orth_block_move_cost( from_x, from_y, dx, dy )
-- 		end
-- 	else -- dx == -1
-- 		if dy == 1 then
-- 			-- sw
-- 			if math.max( self:terrain_move_cost( from_x, from_y, -1,0 ),
-- 						 self:terrain_move_cost( from_x-1, from_y, 0,1 ),
-- 						 self:terrain_move_cost( from_x, from_y, 0,1 ),
-- 						 self:terrain_move_cost( from_x, from_y+1, -1,0 ),
-- 						 diagonal_move_cost( self:get_block( from_x, from_y ), self:get_block( from_x + dx, from_y + dy ) ) ) == 1 then
-- 				return 1
-- 			else
-- 				return 99
-- 			end
-- 		elseif dy == 0 then
-- 			-- w
-- 			return orth_block_move_cost( from_x, from_y, dx, dy )
-- 		else -- dy == -1
-- 			-- nw
-- 			if math.max( self:terrain_move_cost( from_x, from_y, -1,0 ),
-- 						 self:terrain_move_cost( from_x-1, from_y, 0,-1 ),
-- 						 self:terrain_move_cost( from_x, from_y, 0,-1 ),
-- 						 self:terrain_move_cost( from_x, from_y-1, -1,0 ),
-- 						 diagonal_move_cost( self:get_block( from_x, from_y ), self:get_block( from_x + dx, from_y + dy ) ) ) == 1 then
-- 				return 1
-- 			else
-- 				return 99
-- 			end
-- 		end
-- 	end
-- end

-- function orth_move_cost( from, to )


-- 	if from == 1 then
-- 		if to == 1 then
-- 			return 1
-- 		elseif to == 2 then
-- 			return 10
-- 		end
-- 	elseif from == 2 then
-- 		if to == 1 or to == 2 then
-- 			return 1
-- 		elseif to == 3 then
-- 			return 10
-- 		end
-- 	elseif from == 3 then
-- 		if to == 3 or to == 2 then
-- 			return 1
-- 		end
-- 	end

-- 	return 99
-- end

-- function diagonal_block_move_cost( from, to )
-- 	if ( to == 1 and from == 1 ) or ( to == 2 and from == 2 ) or ( to == 3 and from == 3 ) then
-- 		return 1
-- 	end

-- 	return 99
-- end

-- function edge_move_cost( edge )
-- 	if edge then
-- 		if edge == 99 then
-- 			return 99
-- 		else
-- 			return 10
-- 		end
-- 	else
-- 		return 1
-- 	end
-- end

-- debug
function Map:fill_debug()
	for x = 1, self.width do
		for y = 1, self.height do
			self:set_block(x, y, 999, 999)
		end
	end

	for room = 1, love.math.random(4,6) do
		local room_width, room_height = love.math.random(5,9), love.math.random(7,11)
		local corner_x, corner_y = love.math.random(1, self.width - room_width), love.math.random(1, self.height - room_height)
		for x = corner_x, corner_x + room_width do
			for y = corner_y, corner_y + room_height do
				local roll = love.math.random( 1, 100 )
				if roll > 20 then
					self:set_block(x, y, 10, 10)
				elseif roll > 5 then
					self:set_block(x, y, 10, 20)
				else
					self:set_block(x, y, 10, 30)
				end
			end
		end
	end

	for room = 1, love.math.random(3,5) do
		local room_width, room_height = love.math.random(4,7), love.math.random(6,9)
		local corner_x, corner_y = love.math.random(1, self.width - room_width), love.math.random(1, self.height - room_height)
		for x = corner_x, corner_x + room_width do
			for y = corner_y, corner_y + room_height do
				local roll = love.math.random( 1, 100 )
				if roll > 20 then
					self:set_block(x, y, 10, 20)
				elseif roll > 10 then
					self:set_block(x, y, 10, 10)
				else
					self:set_block(x, y, 10, 30)
				end
			end
		end
	end

	for room = 1, love.math.random(2,4) do
		local room_width, room_height = love.math.random(3,5), love.math.random(6,9)
		local corner_x, corner_y = love.math.random(1, self.width - room_width), love.math.random(1, self.height - room_height)
		for x = corner_x, corner_x + room_width do
			for y = corner_y, corner_y + room_height do
				local roll = love.math.random( 1, 100 )
				if roll > 20 then
					self:set_block(x, y, 10, 30)
				elseif roll > 5 then
					self:set_block(x, y, 10, 20)
				else
					self:set_block(x, y, 10, 10)
				end
			end
		end
	end

	for anti_room = 1, love.math.random(3,5) do
		local room_width, room_height = love.math.random(1,3), love.math.random(2,4)
		local corner_x, corner_y = love.math.random(1, self.width - room_width), love.math.random(1, self.height - room_height)
		for x = corner_x, corner_x + room_width do
			for y = corner_y, corner_y + room_height do
				self:set_block(x, y, 999, 999)
			end
		end
	end

	for x = 1, self.width do
		for y = 1, self.height do
			if y == 1 then
				if self:get_block_kind(x,y) ~= 999 then
					self:set_edge(x, y, "n", 999)
				end
			else
				local c = (self:get_block_kind(x,y) == 999 and 1 or 0) + (self:get_block_kind(x,y-1) == 999 and 1 or 0)
				if c == 1 or (c == 0 and mymath.one_chance_in(16)) then
					self:set_edge(x, y, "n", 999)
				elseif c == 0 and mymath.one_chance_in(16) then
					self:set_edge(x, y, "n", 10)
				end
			end
			if y == self.height then
				if self:get_block_kind(x,y) ~= 999 then
					self:set_edge(x, y, "s", 999)
				end
			end

			if x == 1 then
				if self:get_block_kind(x,y) ~= 999 then
					self:set_edge(x, y, "w", 999)
				end
			else
				local c = (self:get_block_kind(x,y) == 999 and 1 or 0) + (self:get_block_kind(x-1,y) == 999 and 1 or 0)
				if c == 1 or (c == 0 and mymath.one_chance_in(16)) then
					self:set_edge(x, y, "w", 999)
				elseif c == 0 and mymath.one_chance_in(16) then
					self:set_edge(x, y, "w", 10)
				end
			end
			if x == self.width then
				if self:get_block_kind(x,y) ~= 999 then
					self:set_edge(x, y, "e", 999)
				end
			end
		end
	end
end

function Map:fill_debug_empty()
	for x = 1, self.width do
		for y = 1, self.height do
			self:set_block(x, y, 1)
		end
	end

	for x = 6, 11 do
		for y = 9, 11 do
			self:set_block(x, y, 99)
		end
	end
	for x = 13, 16 do
		for y = 6, 11 do
			self:set_block(x, y, 99)
		end
	end

	for x = 1, self.width do
		for y = 1, self.height do
			if y == 1 then
				if self:get_block(x,y) ~= 99 then
					self:set_edge(x, y, "n", 99)
				end
			else
				local c = (self:get_block(x,y) == 99 and 1 or 0) + (self:get_block(x,y-1) == 99 and 1 or 0)
				if c == 1 then
					self:set_edge(x, y, "n", 99)
				end
			end
			if y == self.height then
				if self:get_block(x,y) ~= 99 then
					self:set_edge(x, y, "s", 99)
				end
			end

			if x == 1 then
				if self:get_block(x,y) ~= 99 then
					self:set_edge(x, y, "w", 99)
				end
			else
				local c = (self:get_block(x,y) == 99 and 1 or 0) + (self:get_block(x-1,y) == 99 and 1 or 0)
				if c == 1 then
					self:set_edge(x, y, "w", 99)
				end
			end
			if x == self.width then
				if self:get_block(x,y) ~= 99 then
					self:set_edge(x, y, "e", 99)
				end
			end
		end
	end
end

return Map
