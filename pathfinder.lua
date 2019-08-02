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
	self.hops = {}
	self.fringes = {}
	self.on = false

	-- debug
	self.debug_running = false
	self.debug_last_h = nil
end

local hash = grid.hash
local unhash = grid.unhash
local nbr = grid.neighbor
function pathfinder:build_move_radius( map, origin_x, origin_y, start_energy )
	self:reset()
	self.origin_x, self.origin_y = origin_x, origin_y
	self.start_energy = start_energy

	self.energies[ hash( origin_x, origin_y ) ] = start_energy
	self.hops[ hash( origin_x, origin_y ) ] = 0
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
				cost = map:step_cost( x, y, neighbor_x - x, neighbor_y - y )
				-- costs:
				-- -1: can't step here
				-- 1: normal step
				if cost == 1 then
					neighbor_hash = hash( neighbor_x, neighbor_y )
					-- if energy is a multiple of 1000, this step starts a second move
					new_en = (energy >= 1000 and energy % 1000 == 0) and (energy / 1000) - 1 or energy - 1
					if ( not self.energies[ neighbor_hash ] )
						or self.energies[ neighbor_hash ] < new_en
						or ( self.energies[ neighbor_hash ] == new_en and ( self.hops[ h ] < self.hops[ neighbor_hash ] or x == neighbor_x or y == neighbor_y ) ) then
						-- this step is better than what we had
						-- third conditional above makes us prefer cardinal directions and avoid hopping unnecessarily
						self.energies[ neighbor_hash ] = new_en
						self.hops[ neighbor_hash ] = self.hops[ h ]
						self.came_from[ neighbor_hash ] = h

						if new_en > 0 then
							self.fringes[ neighbor_hash ] = true
						end
					end
				elseif cost == 10 and energy >= 1000 then
					neighbor_hash = hash( neighbor_x, neighbor_y )
					new_en = math.floor( energy / 1000 ) - 1
					-- new_en = (energy % 1000 == 0) and (energy / 1000) - ((energy / 1000) % 1000) or energy - (energy % 1000)
					if ( not self.energies[ neighbor_hash ] )
						or self.energies[ neighbor_hash ] < new_en
						or ( self.energies[ neighbor_hash ] == new_en and ( self.hops[ h ] + 1 < self.hops[ neighbor_hash ] or x == neighbor_x or y == neighbor_y ) ) then
						-- this is a deadend; it's only better than nothing
						-- costs whatever is left from the current move

						self.energies[ neighbor_hash ] = new_en
						self.hops[ neighbor_hash ] = self.hops[ h ] + 1
						self.came_from[ neighbor_hash ] = h

						if new_en > 0 then
							self.fringes[ neighbor_hash ] = true
						end
					end
				end -- cost == 99 or can't afford a cost == 10; do nothing
			end
		end

		self.fringes[ h ] = nil
	end

	self.on = true
end

function pathfinder:path_to( target_x, target_y )
	local energy = self.energies[ hash( target_x, target_y ) ]
	if not energy then
		-- can't get there
		return nil, nil
	else
		local h = hash( target_x, target_y )
		path = {}
		table.insert( path, h )
		while true do
			h = self.came_from[ h ]
			if h then
				table.insert( path, h )
			else
				break
			end
		end

		mymath.reverse_array( path )

		local cost = 0
		if self.start_energy >= 1000000 and energy < 1000 then
			cost = 2
		elseif (self.start_energy >= 1000000 and energy < 1000000) or (self.start_energy >= 1000 and energy < 1000) then
			cost = 1
		end

		return path, cost
	end
end

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

-- debug stuff
function pathfinder:build_move_radius_debug_start( map, origin_x, origin_y, start_energy )
	self:reset()
	self.origin_x, self.origin_y = origin_x, origin_y
	self.start_energy = start_energy

	self.energies[ hash( origin_x, origin_y ) ] = start_energy
	self.hops[ hash( origin_x, origin_y ) ] = 0
	self.fringes[ hash( origin_x, origin_y ) ] = true

	self.on = true
	self.debug_running = true
end

function pathfinder:build_move_radius_debug_step( map )
	-- grab a fringe with highest energy
	h = next( self.fringes, nil )
	for new_h, _ in pairs( self.fringes ) do
		if self.energies[ new_h ] > self.energies[ h ] then
			h = new_h
		end
	end

	if not h then
		self.debug_running = false
		self.debug_last_h = nil
		return
	end
	x, y = unhash( h )
	energy = self.energies[ h ]

	for dir = 1, 8 do
		neighbor_x, neighbor_y = nbr( x, y, dir )
		if map:in_bounds( neighbor_x, neighbor_y ) then
			cost = map:step_cost( x, y, neighbor_x - x, neighbor_y - y )
			-- costs:
			-- -1: can't step here
			-- 1: normal step
			if cost == 1 then
				neighbor_hash = hash( neighbor_x, neighbor_y )
				-- if energy is a multiple of 1000, this step starts a second move
				new_en = (energy >= 1000 and energy % 1000 == 0) and (energy / 1000) - 1 or energy - 1
				if ( not self.energies[ neighbor_hash ] )
					or self.energies[ neighbor_hash ] < new_en
					or ( self.energies[ neighbor_hash ] == new_en and ( self.hops[ h ] < self.hops[ neighbor_hash ] or x == neighbor_x or y == neighbor_y ) ) then
					-- this step is better than what we had
					-- third conditional above makes us prefer cardinal directions and avoid hopping unnecessarily
					self.energies[ neighbor_hash ] = new_en
					self.hops[ neighbor_hash ] = self.hops[ h ]
					self.came_from[ neighbor_hash ] = h

					if new_en > 0 then
						self.fringes[ neighbor_hash ] = true
					end
				end
			elseif cost == 10 and energy >= 1000 then
				neighbor_hash = hash( neighbor_x, neighbor_y )
				new_en = math.floor( energy / 1000 ) - 1
				-- new_en = (energy % 1000 == 0) and (energy / 1000) - ((energy / 1000) % 1000) or energy - (energy % 1000)
				if ( not self.energies[ neighbor_hash ] )
					or self.energies[ neighbor_hash ] < new_en
					or ( self.energies[ neighbor_hash ] == new_en and ( self.hops[ h ] + 1 < self.hops[ neighbor_hash ] or x == neighbor_x or y == neighbor_y ) ) then
					-- this is a deadend; it's only better than nothing
					-- costs whatever is left from the current move

					self.energies[ neighbor_hash ] = new_en
					self.hops[ neighbor_hash ] = self.hops[ h ] + 1
					self.came_from[ neighbor_hash ] = h

					if new_en > 0 then
						self.fringes[ neighbor_hash ] = true
					end
				end
			end -- cost == 99 or can't afford a cost == 10; do nothing
		end
	end

	self.debug_last_h = h
	self.fringes[ h ] = nil
end

return pathfinder
