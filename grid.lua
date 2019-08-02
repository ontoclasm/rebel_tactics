local grid = {}

function grid.hash( x, y )
	return x + y * 512
end

function grid.unhash( h )
	return h % 512, math.floor( h / 512 )
end

function grid.neighbor( x, y, dir )
	return x + dir_x[ dir ], y + dir_y[ dir ]
end

function grid.orth_dir_from_delta( dx, dy )
	if dx == 1 and dy == 0 then
		return "e"
	elseif dx == -1 and dy == 0 then
		return "w"
	elseif dx == 0 and dy == 1 then
		return "s"
	elseif dx == 0 and dy == -1 then
		return "n"
	else
		error("bad dir: "..dx..", "..dy)
	end
end

-- offsets for neighbors, ccw from east
dir_x = { 1,  1,  0, -1, -1, -1,  0,  1 }
dir_y = { 0,  1,  1,  1,  0, -1, -1, -1 }

return grid
