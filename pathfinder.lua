grid = require "grid"

local pathfinder = { fringes = {} }

function pathfinder:reset()
	-- self:clear_move_radius()
	-- self:clear_path()
	self.origin_x = nil
	self.origin_y = nil
	self.start_energy = nil
	self.energies = {}
	self.came_from = {}
	self.fringes = {}
	self.on = false
end

local hash = grid.hash
local unhash = grid.unhash
local nbr = grid.neighbor
function pathfinder:build_move_radius( map, origin_x, origin_y, start_energy )
	self:reset()
	self.origin_x, self.origin_y = origin_x, origin_y
	self.start_energy = start_energy

	self.energies[ hash( origin_x, origin_y ) ] = start_energy
	self.fringes[ hash( origin_x, origin_y ) ] = true

	local h, x, y, energy
	local neighbor_hash, neighbor_x, neighbor_y
	local cost

	while true do
		-- grab the first fringe
		h = next( self.fringes, nil )
		if not h then
			break
		end
		x, y = unhash( h )
		energy = self.energies[ h ]

		for dir = 1, 8 do
			neighbor_x, neighbor_y = nbr( x, y, dir )
			if map:in_bounds( neighbor_x, neighbor_y ) then
				cost = map:move_cost( x, y, neighbor_x - x, neighbor_y - y )
				-- costs:
				-- -1: can't step here
				-- 1: normal step
				if cost == 1 then
					neighbor_hash = hash( neighbor_x, neighbor_y )
					-- if energy is a multiple of 1000, this step starts a second move
					new_en = (energy >= 1000 and energy % 1000 == 0) and (energy / 1000) - 1 or energy - 1
					if ( not self.energies[ neighbor_hash ] ) or self.energies[ neighbor_hash ] < new_en then
						-- this step is better than what we had
						self.energies[ neighbor_hash ] = new_en
						self.came_from[ neighbor_hash ] = h

						if new_en > 0 then
							self.fringes[ neighbor_hash ] = true
						end
					end
				elseif cost == 10 then
					neighbor_hash = hash( neighbor_x, neighbor_y )
					if ( not self.energies[ neighbor_hash ] ) then
						-- this is a deadend; it's only better than nothing
						-- costs whatever is left from the current move
						new_en = (energy % 1000 == 0) and (energy / 1000) - ((energy / 1000) % 1000) or energy - (energy % 1000)
						self.energies[ neighbor_hash ] = new_en
						self.came_from[ neighbor_hash ] = h

						if new_en > 0 then
							self.fringes[ neighbor_hash ] = true
						end
					end
				end -- cost == 99, do nothing
			end
		end

		self.fringes[ h ] = nil
	end

	self.on = true
end

-- function pathfinder:find_path(t)
-- 	if not self.radius then return false end
-- 	self:clear_path()

-- 	local t_hash = t:hash()
-- 	if not self.reached[t_hash] then return false end

-- 	local distance = nil
-- 	for k = 0, self.radius do
-- 		if self.fringes[k][t_hash] then
-- 			distance = k
-- 			self.path[k] = t:clone()
-- 		end
-- 		if distance then break end
-- 	end

-- 	if distance == 0 then return distance end -- that was easy

-- 	local neighbor = {}
-- 	local neighbor_hash = nil
-- 	for k = distance - 1, 0, -1 do
-- 		for d = 1, 6 do
-- 			neighbor = t:adjacent(d)
-- 			if map:in_bounds(neighbor.x, neighbor.y) then
-- 				neighbor_hash = neighbor:hash()
-- 				if self.fringes[k][neighbor_hash] and not self.deadends[neighbor_hash] then
-- 					self.path[k] = neighbor
-- 					t = neighbor
-- 					break
-- 				end
-- 			end
-- 		end
-- 	end

-- 	return distance
-- end

-- function pathfinder:display_move_radius()
-- 	local c
-- 	for k = 0, self.radius do
-- 		for i,_ in pairs(self.fringes[k]) do
-- 			c = Hex.unhash(i)
-- 			map[c.x][c.y].underlays.movement_a = true
-- 		end
-- 	end
-- 	redraw = true
-- end

-- function pathfinder:clear_move_radius()
-- 	if self.radius then
-- 		local c
-- 		for k=0, self.radius do
-- 			for i,_ in pairs(self.fringes[k]) do
-- 				c = Hex.unhash(i)
-- 				map[c.x][c.y].underlays.movement_a = nil
-- 				map[c.x][c.y].underlays.movement_b = nil
-- 			end
-- 		end
-- 		redraw = true
-- 	end
-- end

-- function pathfinder:display_path()
-- 	for k = 1, self.radius do
-- 		if not self.path[k] then break end
-- 		map[self.path[k].x][self.path[k].y].underlays.nav_node = true
-- 	end
-- 	redraw = true
-- end

-- function pathfinder:clear_path()
-- 	if self.radius then
-- 		for k = 0, self.radius do
-- 			if not self.path[k] then break end
-- 			map[self.path[k].x][self.path[k].y].underlays.nav_node = nil
-- 		end
-- 		redraw = true
-- 	end
-- 	self.path = {}
-- end

return pathfinder
