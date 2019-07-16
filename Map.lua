local Map = class("Map")

function Map:init(width, height)
	if (not width) or width <= 0 or (not height) or height <= 0 then
		error("bad map bounds: " .. width .. ", " .. height)
	end
	self.width, self.height = width, height
	self.blocks = {}
	self.edges = {}
end

function Map:in_bounds(gx, gy)
	return gx >= 1 and gx <= self.width and gy >= 1 and gy <= self.height
end

-- the block at (gx, gy) is stored at [gx + (gy - 1) * width]
function Map:set_block(gx, gy, enum)
	if not self:in_bounds(gx, gy) then
		error("out of bounds: " .. gx .. ", " .. gy)
	else
		self.blocks[gx + (gy - 1) * self.width] = enum
	end
end

function Map:get_block(gx, gy)
	if not self:in_bounds(gx, gy) then
		error("out of bounds: " .. gx .. ", " .. gy)
	else
		return self.blocks[gx + (gy - 1) * self.width]
	end
end

-- for each row of tiles we need (2 * width + 1) edges
-- thus, the edges around (gx, gy) are stored at:
-- n: [gx + (gy - 1) * (2 * self.width + 1)]
-- w: [gx + (gy - 1) * (2 * self.width + 1) + self.width]
-- s: [gx + gy * (2 * self.width + 1)]
-- e: [(gx + 1) + (gy - 1) * (2 * self.width + 1) + self.width]
function Map:set_edge(gx, gy, side, enum)
	if not self:in_bounds(gx, gy) then
		error("out of bounds: " .. gx .. ", " .. gy)
	else
		if side == "n" then
			self.edges[gx + (gy - 1) * (2 * self.width + 1)] = enum
		elseif side == "w" then
			self.edges[gx + (gy - 1) * (2 * self.width + 1) + self.width] = enum
		elseif side == "s" then
			self.edges[gx + gy * (2 * self.width + 1)] = enum
		elseif side == "e" then
			self.edges[(gx + 1) + (gy - 1) * (2 * self.width + 1) + self.width] = enum
		else
			error("bad edge: " .. side)
		end
	end
end

function Map:get_edge(gx, gy, side)
	if not self:in_bounds(gx, gy) then
		error("out of bounds: " .. gx .. ", " .. gy)
	else
		if side == "n" then
			return self.edges[gx + (gy - 1) * (2 * self.width + 1)]
		elseif side == "w" then
			return self.edges[gx + (gy - 1) * (2 * self.width + 1) + self.width]
		elseif side == "s" then
			return self.edges[gx + gy * (2 * self.width + 1)]
		elseif side == "e" then
			return self.edges[(gx + 1) + (gy - 1) * (2 * self.width + 1) + self.width]
		else
			error("bad edge: " .. side)
		end
	end
end

-- debug
function Map:fill_debug()
	for gx = 1, self.width do
		for gy = 1, self.height do
			if mymath.one_chance_in(8) then
				self:set_block(gx, gy, 2)
			else
				self:set_block(gx, gy, 1)
			end

			if gy == 1 then
				self:set_edge(gx, gy, "n", 2)
			end
			if gx == 1 then
				self:set_edge(gx, gy, "w", 2)
			end
			if gy == self.height then
				self:set_edge(gx, gy, "s", 2)
			end
			if gx == self.width then
				self:set_edge(gx, gy, "e", 2)
			end
		end
	end
end

return Map
