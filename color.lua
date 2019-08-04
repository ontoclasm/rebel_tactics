color = {
		white =				{1.00,	1.00,	1.00},
		grey06 =			{0.70,	0.70,	0.80},
		grey05 =			{0.55,	0.55,	0.65},
		grey04 =			{0.40,	0.40,	0.50},
		grey03 =			{0.27,	0.27,	0.37},
		grey02 =			{0.17,	0.17,	0.23},
		grey01 =			{0.10,	0.10,	0.15},
		black =				{0.00,	0.00,	0.00},
		dkrouge =			{0.50,	0.10,	0.10},
		rouge =				{0.90,	0.20,	0.10},
		actinic =			{0.60,	0.10,	0.95},
		dkblue =			{0.15,	0.15,	0.70},
		blue =				{0.20,	0.30,	0.90},
		green =				{0.30,	0.80,	0.30},
		brown =				{0.50,	0.30,	0.20},
		blood =				{0.30,	0.05,	0.10},
		bg =				{0.20,	0.10,	0.30},

		mvblue06 =			{0.20,	0.60,	1.00},
		mvblue03 =			{0.20,	0.40,	0.65},
		mvblue02 =			{0.15,	0.30,	0.55},
		mvblue01 =			{0.10,	0.20,	0.40},

		mvorange06 =		{0.80,	0.40,	0.07},
		mvorange03 =		{0.50,	0.30,	0.07},
		mvorange02 =		{0.40,	0.20,	0.06},
		mvorange01 =		{0.30,	0.12,	0.04},

		yellow04 =			{1.00,	0.80,	0.40},
		yellow03 =			{0.80,	0.70,	0.10},
		yellow02 =			{0.70,	0.60,	0.08},
		yellow01 =			{0.50,	0.40,	0.05},

		oops =				{1.00,	0.00,	1.00},
}

function color.r(name)
	return color[name][1]
end

function color.g(name)
	return color[name][2]
end

function color.b(name)
	return color[name][3]
end

function color.rgb(name)
	return color[name][1],color[name][2],color[name][3]
end

function color.mix(a, b, t)
	v = 1-t
	return {v*a[1] + t*b[1], v*a[2] + t*b[2], v*a[3] + t*b[3]}
end

return color
