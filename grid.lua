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

-- offsets for neighbors, ccw from east
dir_x = { 1,  1,  0, -1, -1, -1,  0,  1 }
dir_y = { 0,  1,  1,  1,  0, -1, -1, -1 }

return grid
