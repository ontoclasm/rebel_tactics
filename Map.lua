local Map = class("Map")

local MAP_HASH = 512
local EDGE_ROW_HASH_OFFSET = (MAP_HASH * 2) + 1

function Map:init(width, height)
	if (not width) or width <= 0 or (not height) or height <= 0 then
		error("bad map bounds: " .. width .. ", " .. height)
	end
	self.width, self.height = width, height
	self.blocks = {}
	self.edges = {}
	self.pawns = {}
end

function Map:in_bounds(x, y)
	return x >= 1 and x <= self.width and y >= 1 and y <= self.height
end

-- the block at (x, y) is stored at [x + (y - 1) * width]
function Map:set_block(x, y, enum)
	if not self:in_bounds(x, y) then
		error("out of bounds: " .. x .. ", " .. y)
	else
		self.blocks[x + (y - 1) * MAP_HASH] = enum
	end
end

function Map:get_block(x, y)
	if not self:in_bounds(x, y) then
		error("out of bounds: " .. x .. ", " .. y)
	else
		return self.blocks[x + (y - 1) * MAP_HASH]
	end
end

-- for each row of tiles we need (2 * width + 1) edges
-- thus, the edges around (x, y) are stored at:
-- n: [x + (y - 1) * (2 * self.width + 1)]
-- w: [x + (y - 1) * (2 * self.width + 1) + self.width]
-- s: [x + y * (2 * self.width + 1)]
-- e: [(x + 1) + (y - 1) * (2 * self.width + 1) + self.width]
function Map:set_edge(x, y, side, enum)
	if not self:in_bounds(x, y) then
		error("out of bounds: " .. x .. ", " .. y)
	else
		if side == "n" then
			self.edges[x + (y - 1) * EDGE_ROW_HASH_OFFSET] = enum
		elseif side == "w" then
			self.edges[x + (y - 1) * EDGE_ROW_HASH_OFFSET + MAP_HASH] = enum
		elseif side == "s" then
			self.edges[x + y * EDGE_ROW_HASH_OFFSET] = enum
		elseif side == "e" then
			self.edges[(x + 1) + (y - 1) * EDGE_ROW_HASH_OFFSET + MAP_HASH] = enum
		else
			error("bad edge: " .. side)
		end
	end
end

function Map:get_edge(x, y, side)
	if not self:in_bounds(x, y) then
		error("out of bounds: " .. x .. ", " .. y)
	else
		if side == "n" then
			return self.edges[x + (y - 1) * EDGE_ROW_HASH_OFFSET]
		elseif side == "w" then
			return self.edges[x + (y - 1) * EDGE_ROW_HASH_OFFSET + MAP_HASH]
		elseif side == "s" then
			return self.edges[x + y * EDGE_ROW_HASH_OFFSET]
		elseif side == "e" then
			return self.edges[(x + 1) + (y - 1) * EDGE_ROW_HASH_OFFSET + MAP_HASH]
		else
			error("bad edge: " .. side)
		end
	end
end

function Map:set_pawn(x, y, pawn_id)
	if not self:in_bounds(x, y) then
		error("out of bounds: " .. x .. ", " .. y)
	else
		self.pawns[x + (y - 1) * MAP_HASH] = pawn_id
	end
end

function Map:get_pawn(x, y)
	if not self:in_bounds(x, y) then
		error("out of bounds: " .. x .. ", " .. y)
	else
		return self.pawns[x + (y - 1) * MAP_HASH]
	end
end

function Map:find_random_floor()
	local x, y
	for tries = 1, 1000 do
		x = love.math.random(1, self.width)
		y = love.math.random(1, self.height)
		if self:get_block(x, y) == 1 then
			return x, y
		end
	end
	error("couldn't find floor")
end

-- debug
function Map:fill_debug()
	for x = 1, self.width do
		for y = 1, self.height do
			if mymath.one_chance_in(8) then
				self:set_block(x, y, 2)
			else
				self:set_block(x, y, 1)
			end

			if mymath.one_chance_in(32) then
				self:set_edge(x, y, "n", 3)
				self:set_edge(x, y, "s", 3)
				self:set_edge(x, y, "e", 3)
				self:set_edge(x, y, "w", 3)
			end

			if y == 1 or mymath.one_chance_in(32) then
				self:set_edge(x, y, "n", 2)
			end
			if x == 1 or mymath.one_chance_in(32) then
				self:set_edge(x, y, "w", 2)
			end
			if y == self.height or mymath.one_chance_in(32) then
				self:set_edge(x, y, "s", 2)
			end
			if x == self.width or mymath.one_chance_in(32) then
				self:set_edge(x, y, "e", 2)
			end
		end
	end
end

return Map
