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
function Map:set_block( x, y, enum )
	if not self:in_bounds( x, y ) then
		error( "out of bounds: " .. x .. ", " .. y )
	else
		self.blocks[ x + (y - 1) * MAP_HASH ] = enum
	end
end

function Map:get_block( x, y )
	if not self:in_bounds( x, y ) then
		error( "out of bounds: " .. x .. ", " .. y )
	else
		return self.blocks[ x + (y - 1) * MAP_HASH ]
	end
end

function Map:set_edge( x, y, side, enum )
	if not self:in_bounds( x, y ) then
		error( "out of bounds: " .. x .. ", " .. y )
	else
		if side == "n" then
			self.edges[ x + (y - 1) * EDGE_ROW_HASH_OFFSET ] = enum
		elseif side == "w" then
			self.edges[ x + (y - 1) * EDGE_ROW_HASH_OFFSET + MAP_HASH ] = enum
		elseif side == "s" then
			self.edges[ x + y * EDGE_ROW_HASH_OFFSET ] = enum
		elseif side == "e" then
			self.edges[ (x + 1) + (y - 1) * EDGE_ROW_HASH_OFFSET + MAP_HASH ] = enum
		else
			error( "bad edge: " .. side )
		end
	end
end

function Map:get_edge( x, y, side )
	if not self:in_bounds( x, y ) then
		error( "out of bounds: " .. x .. ", " .. y )
	else
		if side == "n" then
			return self.edges[ x + (y - 1) * EDGE_ROW_HASH_OFFSET ]
		elseif side == "w" then
			return self.edges[ x + (y - 1) * EDGE_ROW_HASH_OFFSET + MAP_HASH ]
		elseif side == "s" then
			return self.edges[ x + y * EDGE_ROW_HASH_OFFSET ]
		elseif side == "e" then
			return self.edges[ (x + 1) + (y - 1) * EDGE_ROW_HASH_OFFSET + MAP_HASH ]
		else
			error( "bad edge: " .. side )
		end
	end
end

function Map:get_nw_cap( x, y )
	if not ( x >= 1 and x <= self.width + 1 and y >= 1 and y <= self.height + 1 ) then
		error( "out of bounds: " .. x .. ", " .. y )
	else
		local cap = -1

		local edge = self.edges[ x + (y - 1) * EDGE_ROW_HASH_OFFSET ]
		if edge then
			cap = math.max( cap, edge )
		end

		edge = self.edges[ x + (y - 1) * EDGE_ROW_HASH_OFFSET + MAP_HASH ]
		if edge then
			cap = math.max( cap, edge )
		end

		edge = self.edges[ (x - 1) + (y - 1) * EDGE_ROW_HASH_OFFSET ]
		if edge then
			cap = math.max( cap, edge )
		end

		edge = self.edges[ x + (y - 2) * EDGE_ROW_HASH_OFFSET + MAP_HASH ]
		if edge then
			cap = math.max( cap, edge )
		end

		return cap
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

function Map:find_random_floor()
	local x, y, b
	for tries = 1, 1000 do
		x = love.math.random( 1, self.width )
		y = love.math.random( 1, self.height )
		if self:get_block( x, y ) >= 1 and self:get_block( x, y ) <= 3 then
			return x, y
		end
	end
	error( "couldn't find floor" )
end

function Map:move_cost( from_x, from_y, dx, dy )
	-- XXX rewrite
	-- don't want to hop over walls diagonally, it looks weird

	-- 99: can't move there
	-- 10: ends move to step here
	--  1: takes a normal step

	if math.abs( dx ) > 1 or math.abs( dy ) > 1 or self:get_pawn( from_x + dx, from_y + dy ) then
		return 99
	else
		return self:terrain_move_cost( from_x, from_y, dx, dy )
	end
end

function Map:terrain_move_cost( from_x, from_y, dx, dy )
	if dx == 1 then
		if dy == 1 then
			-- se
			if math.max( self:terrain_move_cost( from_x, from_y, 1,0 ),
						 self:terrain_move_cost( from_x+1, from_y, 0,1 ),
						 self:terrain_move_cost( from_x, from_y, 0,1 ),
						 self:terrain_move_cost( from_x, from_y+1, 1,0 ),
						 diagonal_block_move_cost( self:get_block( from_x, from_y ), self:get_block( from_x + dx, from_y + dy ) ) ) == 1 then
				return 1
			else
				return 99
			end
		elseif dy == 0 then
			-- e
			return math.max( block_move_cost( self:get_block( from_x, from_y ), self:get_block( from_x + dx, from_y + dy ) ) ,
							 edge_move_cost( self:get_edge( from_x, from_y, "e" ) ) )
		else -- dy == -1
			-- ne
			if math.max( self:terrain_move_cost( from_x, from_y, 1,0 ),
						 self:terrain_move_cost( from_x+1, from_y, 0,-1 ),
						 self:terrain_move_cost( from_x, from_y, 0,-1 ),
						 self:terrain_move_cost( from_x, from_y-1, 1,0 ),
						 diagonal_block_move_cost( self:get_block( from_x, from_y ), self:get_block( from_x + dx, from_y + dy ) ) ) == 1 then
				return 1
			else
				return 99
			end
		end
	elseif dx == 0 then
		if dy == 1 then
			-- s
			return math.max( block_move_cost( self:get_block( from_x, from_y ), self:get_block( from_x + dx, from_y + dy ) ) ,
							 edge_move_cost( self:get_edge( from_x, from_y, "s" ) ) )
		elseif dy == 0 then
			-- ???
			error()
		else -- dy == -1
			-- n
			return math.max( block_move_cost( self:get_block( from_x, from_y ), self:get_block( from_x + dx, from_y + dy ) ) ,
							 edge_move_cost( self:get_edge( from_x, from_y, "n" ) ) )
		end
	else -- dx == -1
		if dy == 1 then
			-- sw
			if math.max( self:terrain_move_cost( from_x, from_y, -1,0 ),
						 self:terrain_move_cost( from_x-1, from_y, 0,1 ),
						 self:terrain_move_cost( from_x, from_y, 0,1 ),
						 self:terrain_move_cost( from_x, from_y+1, -1,0 ),
						 diagonal_block_move_cost( self:get_block( from_x, from_y ), self:get_block( from_x + dx, from_y + dy ) ) ) == 1 then
				return 1
			else
				return 99
			end
		elseif dy == 0 then
			-- w
			return math.max( block_move_cost( self:get_block( from_x, from_y ), self:get_block( from_x + dx, from_y + dy ) ) ,
							 edge_move_cost( self:get_edge( from_x, from_y, "w" ) ) )
		else -- dy == -1
			-- nw
			if math.max( self:terrain_move_cost( from_x, from_y, -1,0 ),
						 self:terrain_move_cost( from_x-1, from_y, 0,-1 ),
						 self:terrain_move_cost( from_x, from_y, 0,-1 ),
						 self:terrain_move_cost( from_x, from_y-1, -1,0 ),
						 diagonal_block_move_cost( self:get_block( from_x, from_y ), self:get_block( from_x + dx, from_y + dy ) ) ) == 1 then
				return 1
			else
				return 99
			end
		end
	end
end

function block_move_cost( from, to )
	if from == 1 then
		if to == 1 then
			return 1
		elseif to == 2 then
			return 10
		end
	elseif from == 2 then
		if to == 1 or to == 2 then
			return 1
		elseif to == 3 then
			return 10
		end
	elseif from == 3 then
		if to == 3 or to == 2 then
			return 1
		end
	end

	return 99
end

function diagonal_block_move_cost( from, to )
	if ( to == 1 and from == 1 ) or ( to == 2 and from == 2 ) or ( to == 3 and from == 3 ) then
		return 1
	end

	return 99
end

function edge_move_cost( edge )
	if edge then
		if edge == 99 then
			return 99
		else
			return 10
		end
	else
		return 1
	end
end

-- debug
function Map:fill_debug()
	for x = 1, self.width do
		for y = 1, self.height do
			self:set_block(x, y, 99)
		end
	end

	for room = 1, love.math.random(4,6) do
		local room_width, room_height = love.math.random(5,9), love.math.random(7,11)
		local corner_x, corner_y = love.math.random(1, self.width - room_width), love.math.random(1, self.height - room_height)
		for x = corner_x, corner_x + room_width do
			for y = corner_y, corner_y + room_height do
				local roll = love.math.random( 1, 100 )
				if roll > 20 then
					self:set_block(x, y, 1)
				elseif roll > 5 then
					self:set_block(x, y, 2)
				else
					self:set_block(x, y, 3)
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
					self:set_block(x, y, 2)
				elseif roll > 10 then
					self:set_block(x, y, 1)
				else
					self:set_block(x, y, 3)
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
					self:set_block(x, y, 3)
				elseif roll > 5 then
					self:set_block(x, y, 2)
				else
					self:set_block(x, y, 1)
				end
			end
		end
	end

	for anti_room = 1, love.math.random(3,5) do
		local room_width, room_height = love.math.random(1,3), love.math.random(2,4)
		local corner_x, corner_y = love.math.random(1, self.width - room_width), love.math.random(1, self.height - room_height)
		for x = corner_x, corner_x + room_width do
			for y = corner_y, corner_y + room_height do
				self:set_block(x, y, 99)
			end
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
				if c == 1 or (c == 0 and mymath.one_chance_in(16)) then
					self:set_edge(x, y, "n", 99)
				elseif c == 0 and mymath.one_chance_in(16) then
					self:set_edge(x, y, "n", 3)
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
				if c == 1 or (c == 0 and mymath.one_chance_in(16)) then
					self:set_edge(x, y, "w", 99)
				elseif c == 0 and mymath.one_chance_in(16) then
					self:set_edge(x, y, "w", 3)
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
