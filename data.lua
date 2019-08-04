block_data = {
	[ 10] = {
		name = "floor",
		floor = true,
		translucent = true, -- can see through
		permeable = true, -- can shoot through

		tile = "block",
		colors = {
			[-1] = color.rouge,
			[10] = color.grey01,
			[20] = color.grey02,
			[30] = color.grey03,
		}
	},

	[999] = {
		name = "impassable stone",
		floor = false,
		translucent = false,
		permeable = false,

		tile = "block",
		colors = {
			[-1] = color.bg,
		}
	},
}

edge_data = {
	[ 10] = {
		name = "low cover",
		floor = false,
		translucent = true,
		permeable = true,
		elev = 10,
		cover_when_level = 1,
		cover_when_above = 2,

		tile = "edge_wall_thin",
		colors = {
			[-1] = color.rouge,
			[20] = color.grey02,
			[30] = color.grey03,
			[40] = color.grey04,
		}
	},

	[ 20] = {
		name = "high cover",
		floor = false,
		translucent = true,
		permeable = true,
		elev = 20,
		cover_when_level = 2,
		cover_when_above = 2,

		tile = "edge_cover_thick",
		colors = {
			[-1] = color.rouge,
			[30] = color.grey03,
			[40] = color.grey04,
			[50] = color.grey05,
		}
	},

	[ 30] = {
		name = "door",
		floor = false,
		translucent = true,
		permeable = true,
		elev = 999,
		cover_when_level = 2,
		cover_when_above = 2,

		is_door = true,
		door_opens_to = 31,

		tile = "edge_door",
		colors = {
			[-1] = color.brown,
		}
	},

	[ 31] = {
		name = "door_open",
		floor = false,
		translucent = true,
		permeable = true,
		elev = 999,
		cover_when_level = 0,
		cover_when_above = 1,

		is_door = true,
		tile = "edge_door_open",
		colors = {
			[-1] = color.brown,
		}
	},

	[999] = {
		name = "impassable wall",
		floor = false,
		translucent = false,
		permeable = false,
		elev = 999,
		cover_when_level = 2,
		cover_when_above = 2,

		tile = "edge_wall_thick",
		colors = {
			[-1] = color.white,
		}
	},
}
