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

		tile = "edge_thin",
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

		tile = "edge_thick",
		colors = {
			[-1] = color.rouge,
			[30] = color.grey03,
			[40] = color.grey04,
			[50] = color.grey05,
		}
	},

	[999] = {
		name = "impassable wall",
		floor = false,
		translucent = false,
		permeable = false,
		elev = 999,

		tile = "edge_thick",
		colors = {
			[-1] = color.grey06,
		}
	},
}
