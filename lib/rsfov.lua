--[[
zlib License:

Copyright (c) 2014 Minh Ngo

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

   1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgment in the product documentation would be
   appreciated but is not required.

   2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.

   3. This notice may not be removed or altered from any source
   distribution.
--]]

-- Based on recursive shadowcasting by Björn Bergström

-- modified by Samuel Wilson; see https://github.com/markandgo/Lua-FOV for the original

local octants = {
	function(x,y) return x,y end,
	function(x,y) return y,x end,
	function(x,y) return -y,x end,
	function(x,y) return -x,y end,
	function(x,y) return -x,-y end,
	function(x,y) return -y,-x end,
	function(x,y) return y,-x end,
	function(x,y) return x,-y end,
}

local tau         = 2*math.pi
local octant_angle= math.pi / 4
local epsilon     = 1e-5

local right_edge_dirs = {
	"e",
	"s",
	"s",
	"w",
	"w",
	"n",
	"n",
	"e"
}
local bottom_edge_dirs = {
	"n",
	"w",
	"e",
	"n",
	"s",
	"e",
	"w",
	"s"
}

local fov = function(x0, y0, radius, get_transparent_edge, set_visible, start_angle, last_angle)
	-- **NOTE** Assumed orientation in notes is x+ right, y+ up

	--[[
	Octant designation
	   \  |  /
	   4\3|2/1
	 ____\|/____
	     /|\
	   5/6|7\8
	   /  |  \

	   All calculations are done on the first octant
	   To calculate FOV on other octants, reflect the cells onto the first octant

	   The bottom left corner is the coordinates of a cell:

	   (0,1)------(1,1)
	        |Cell|
	        |0,0 |
	   (0,0)------(1,0)

	   **ARC NOTE**

	   The arc angle of vision defaults to 360 degrees.
	   Arc angle is measured counterclockwise from starting to last.
	   The shortest arc is used so if start = 0 and last = 370 deg then arc angle = 10 deg.
	   To get full field of view, add 2*math.pi to starting angle. This is
	   the only way to get a full view. Any other case will result in the
	   smallest arc possible.

	   For example:
	   start = 0 ; last = 0         --> line field of view
	   start = 0 ; last = 2*math.pi --> full field of view
	]]

	start_angle    = start_angle or 0
	last_angle     = last_angle or tau
	local arc_angle= (last_angle-start_angle)
	-- Clamp angles or else some checks won't work correctly
	if arc_angle - tau > epsilon or arc_angle < 0 then arc_angle = arc_angle % tau end
	start_angle = start_angle % tau
	last_angle  = last_angle % tau

	-- Angle interval of first octant [inclusive,exclusive)
	-- Touching the end of the interval moves onto the next octant
	-- Example: [0,pi/4)
	local first_octant = (math.floor(start_angle / octant_angle) % 8) + 1
	-- Angle interval of last octant (exclusive,inclusive]
	-- Touching the beginning of the interval moves to the prev octant
	-- Example: (0,pi/4]
	local last_octant  = ((math.ceil(last_angle / octant_angle) - 1) % 8) + 1

	-- Hack to make large angles work when start/last are in the same octant
	if last_octant == first_octant and arc_angle > octant_angle then
		first_octant = (first_octant % 8) + 1
	end

	local octant = first_octant - 1

	-- Always see the origin
	set_visible(x0,y0)

	repeat
		octant       = (octant % 8) + 1

		-- if there is an edge directly to the right of us, the whole octant is pointless
		if get_transparent_edge( x0, y0, right_edge_dirs[octant]) then
			local coords = octants[octant]
			local views  = {}
			-- A view is represented by two lines (steep & shallow)
			views[1]    = {
				-- {x,y,x2,y2}
				steep    = {0.5,0.5,0,radius},
				shallow  = {0.5,0.5,radius,0},
			}

			for x = 1,radius do
				-- first cycle: handle bottom edges
				if not views[1] then break end
				-- Process all remaining views
				-- Iterate backward to be able to delete views
				for i = #views,1,-1 do
					local view           = views[i]
					local steep,shallow  = view.steep,view.shallow
					local top_entered_from_side = false

					-- Calculate the maximum and minimum height of the column to scan
					-- y = slope * dx + y0
					local steep_slope, shallow_slope
					local yi,yf

					-- Don't calculate if the view lines didn't change
					if steep[3] > steep[1] then
						steep_slope  = (steep[4]-steep[2]) / (steep[3]-steep[1])
						yi = math.floor( steep[2] + steep_slope*(x+1-steep[1]) - epsilon )
						top_entered_from_side = ( steep[2] + steep_slope*(x-steep[1]) ) > yi
					else
						steep_slope = 1
						yi = x
						top_entered_from_side = false
					end

					if shallow[4] > shallow[2] then
						shallow_slope = (shallow[4]-shallow[2]) / (shallow[3]-shallow[1])
						yf = math.floor( shallow[2] + shallow_slope*(x-shallow[1]) + epsilon )
					else
						shallow_slope = -1
						yf = 0
					end

					if steep_slope >= shallow_slope then
						for y = yi,yf,-1 do
							local tx,ty = coords(x,y)
							local transparent_bottom = get_transparent_edge( x0+tx, y0+ty, bottom_edge_dirs[octant] )

							-- The tile is visible if it is within the cone field of view
							-- the very top square is NOT visible if its bottom edge is solid and it was entered from the bottom
							if (arc_angle >= tau or arc_angle >= (math.atan2(ty,tx)-start_angle) % tau) then
								if y < yi or transparent_bottom or top_entered_from_side then
									set_visible( x0+tx,y0+ty )
								end
							end

							if not transparent_bottom then
								-- this block has a solid edge below it; this cuts the view in two
								-- unless this is the top square and we entered it from below, in which case we only bump down
								-- or this is the very bottom, in which case nothing happens
								if y == yi then
									if top_entered_from_side then
										-- this is no different from the normal case below
										local new_view = {
											-- Inherit the current view steep line
											steep       = {steep[1],steep[2],steep[3],steep[4]},
											-- Shallow line bumps into bottom left corner of this block
											shallow     = {shallow[1],shallow[2],x,y},
										}

										table.insert(views,new_view)

										steep[3],steep[4]= x+1,y
									else
										-- but here we don't need the new view since we entered from below
										steep[3],steep[4]= x+1,y
									end
								elseif y > yf then
									local new_view = {
										-- Inherit the current view steep line
										steep       = {steep[1],steep[2],steep[3],steep[4]},
										-- Shallow line bumps into bottom left corner of this block
										shallow     = {shallow[1],shallow[2],x,y},
									}

									table.insert(views,new_view)

									steep[3],steep[4]= x+1,y
								end
							end
						end
					else
						-- our slopes are in the wrong order
						-- happens when looking through tiny gaps; just delete the view
						table.remove(views,i)
					end
				end

				-- go down again and handle right edges
				if not views[1] then break end
				for i = #views,1,-1 do
					local prev_cell_solid_right = false

					local view           = views[i]
					local steep,shallow  = view.steep,view.shallow

					-- Calculate the maximum and minimum height of the column to scan
					-- y = slope * dx + y0
					local yi,yf

					-- Don't calculate if the view lines didn't change
					if steep[3] > steep[1] then
						local steep_slope  = (steep[4]-steep[2]) / (steep[3]-steep[1])
						yi = math.floor( steep[2] + steep_slope*(x+1-steep[1]) - epsilon )
					else
						yi = x
					end

					if shallow[4] > shallow[2] then
						local shallow_slope = (shallow[4]-shallow[2]) / (shallow[3]-shallow[1])
						yf = math.floor( shallow[2] + shallow_slope*(x-shallow[1]) + epsilon )
					else
						yf = 0
					end

					for y = yi,yf,-1 do
						local tx,ty = coords(x,y)
						local transparent_right = get_transparent_edge( x0+tx, y0+ty, right_edge_dirs[octant] )

						if not transparent_right then
							-- | *    | *
							-- |__ or |

							-- If the above cell had no right edge
							-- and it is not the first cell then
							-- add another view for the remaining columns
							if (not prev_cell_solid_right) and y < yi then
								local new_view = {
									-- Inherit the current view steep line
									steep       = {steep[1],steep[2],steep[3],steep[4]},
									-- Shallow line bumps into top right corner of block
									shallow     = {shallow[1],shallow[2],x+1,y+1},
								}

								table.insert(views,new_view)
							end
						elseif prev_cell_solid_right then
							-- Above cell was solid, but this one isn't
							-- Steep slope bumps to the bottom right of the above block
							steep[3],steep[4]= x+1,y+1
						end

						-- -- Found a blocking cell
						-- if not transparent then
						-- 	-- If the previous cell is non blocking
						-- 	-- and it is not the first cell then
						-- 	-- add another view for the remaining columns
						-- 	if not prev_cell_solid and y < yi then
						-- 		local new_view = {
						-- 			-- Inherit the current view steep line
						-- 			steep       = {steep[1],steep[2],steep[3],steep[4]},
						-- 			-- Shallow line bumps into top left corner of block
						-- 			shallow     = {shallow[1],shallow[2],x,y+1},
						-- 		}

						-- 		table.insert(views,new_view)
						-- 	end

						-- 	prev_cell_solid = true
						-- elseif prev_cell_solid then
						-- 	-- Cell is transparent and moving from blocking to non-blocking
						-- 	-- Readjust steep line to steep bump
						-- 	steep[3],steep[4]= x+1,y+1
						-- 	prev_cell_solid  = false
						-- end

						prev_cell_solid_right = not transparent_right
					end

					-- Remove the view if the last cell is blocking
					if prev_cell_solid_right then
						table.remove(views,i)
					end
				end
			end
		end
	until octant == last_octant
end

return fov
