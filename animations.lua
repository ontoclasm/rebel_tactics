local animations = {}

function animations.process(anim, playstate, dt)
	if not anim.kind or not animations.functions[anim.kind] then
		error()
	else
		return animations.functions[anim.kind](anim, playstate, dt)
	end
end

-- move the thing forward by dt
-- return true if the animation is done, false otherwise
animations.functions = {}

animations.functions["wait"] = function(anim, playstate, dt)
	if anim.t < 1 then
		anim.t = anim.t + (anim.duration and (1 / anim.duration) or 3) * dt
	else
		return true
	end

	return false
end

animations.functions["step"] = function(anim, playstate, dt)
	if anim.t == 0 then
		--start the animation
		if playstate.current_map:get_pawn( anim.x1, anim.y1 ) ~= anim.pid then
			error("pawn in wrong place??")
		end

		local p = playstate.pawn_list[anim.pid]
		p.offset_px = TILE_SIZE * (anim.x1 - anim.x2)
		p.offset_py = TILE_SIZE * (anim.y1 - anim.y2)
		playstate.current_map:move_pawn( anim.x1, anim.y1, anim.x2, anim.y2 )
		p.x, p.y = anim.x2, anim.y2

		anim.t = anim.t + 8 * dt
	elseif anim.t < 1 then
		local p = playstate.pawn_list[anim.pid]
		p.offset_px = mymath.abs_floor(TILE_SIZE * (anim.x1 - anim.x2) * (1 - anim.t))
		p.offset_py = mymath.abs_floor(TILE_SIZE * (anim.y1 - anim.y2) * (1 - anim.t))

		anim.t = anim.t + 8 * dt
	else
		-- anim finished
		local p = playstate.pawn_list[anim.pid]
		p.offset_px = 0
		p.offset_py = 0

		return true
	end

	return false
end

animations.functions["first step"] = function(anim, playstate, dt)
	if anim.t == 0 then
		--start the animation
		if playstate.current_map:get_pawn( anim.x1, anim.y1 ) ~= anim.pid then
			error("pawn in wrong place??")
		end

		local p = playstate.pawn_list[anim.pid]
		p.offset_px = TILE_SIZE * (anim.x1 - anim.x2)
		p.offset_py = TILE_SIZE * (anim.y1 - anim.y2)
		playstate.current_map:move_pawn( anim.x1, anim.y1, anim.x2, anim.y2 )
		p.x, p.y = anim.x2, anim.y2

		anim.t = anim.t + 4 * dt
	elseif anim.t < 1 then
		local p = playstate.pawn_list[anim.pid]
		p.offset_px = mymath.abs_floor(TILE_SIZE * (anim.x1 - anim.x2) * (1 - anim.t))
		p.offset_py = mymath.abs_floor(TILE_SIZE * (anim.y1 - anim.y2) * (1 - anim.t))

		anim.t = anim.t + (4 + 4 * anim.t) * dt
	else
		-- anim finished
		local p = playstate.pawn_list[anim.pid]
		p.offset_px = 0
		p.offset_py = 0

		return true
	end

	return false
end

animations.functions["last step"] = function(anim, playstate, dt)
	if anim.t == 0 then
		--start the animation
		if playstate.current_map:get_pawn( anim.x1, anim.y1 ) ~= anim.pid then
			error("pawn in wrong place??")
		end

		local p = playstate.pawn_list[anim.pid]
		p.offset_px = TILE_SIZE * (anim.x1 - anim.x2)
		p.offset_py = TILE_SIZE * (anim.y1 - anim.y2)
		playstate.current_map:move_pawn( anim.x1, anim.y1, anim.x2, anim.y2 )
		p.x, p.y = anim.x2, anim.y2

		anim.t = anim.t + 8 * dt
	elseif anim.t < 1 then
		local p = playstate.pawn_list[anim.pid]
		p.offset_px = mymath.abs_floor(TILE_SIZE * (anim.x1 - anim.x2) * (1 - anim.t))
		p.offset_py = mymath.abs_floor(TILE_SIZE * (anim.y1 - anim.y2) * (1 - anim.t))

		anim.t = anim.t + (8 - 7 * anim.t) * dt
	else
		-- anim finished
		local p = playstate.pawn_list[anim.pid]
		p.offset_px = 0
		p.offset_py = 0

		return true
	end

	return false
end

animations.functions["hop"] = function(anim, playstate, dt)
	if anim.t == 0 then
		--start the animation
		if playstate.current_map:get_pawn( anim.x1, anim.y1 ) ~= anim.pid then
			error("pawn in wrong place??")
		end

		local p = playstate.pawn_list[anim.pid]
		p.offset_px = TILE_SIZE * (anim.x1 - anim.x2)
		p.offset_py = TILE_SIZE * (anim.y1 - anim.y2)
		playstate.current_map:move_pawn( anim.x1, anim.y1, anim.x2, anim.y2 )
		p.x, p.y = anim.x2, anim.y2

		anim.t = anim.t + 2 * dt
	elseif anim.t < 1 then
		local p = playstate.pawn_list[anim.pid]
		p.offset_px = mymath.abs_floor(TILE_SIZE * (anim.x1 - anim.x2) * math.pow(1 - anim.t, 3))
		p.offset_py = mymath.abs_floor(TILE_SIZE * (anim.y1 - anim.y2) * math.pow(1 - anim.t, 3))

		anim.t = anim.t + 2 * dt
	else
		-- anim finished
		local p = playstate.pawn_list[anim.pid]
		p.offset_px = 0
		p.offset_py = 0

		return true
	end

	return false
end

animations.functions["shoot"] = function(anim, playstate, dt)
	if anim.t == 0 then
		--start the animation
		if playstate.current_map:get_pawn( anim.x, anim.y ) ~= anim.pid then
			error("pawn in wrong place??")
		end

		local p = playstate.pawn_list[anim.pid]
		p.offset_px = 0
		p.offset_py = 0

		anim.shot_timer = 0

		anim.t = anim.t + 0.5 * dt
	elseif anim.t < 1 then
		if anim.shot_timer > 0.1 then
			local p = playstate.pawn_list[anim.pid]
			local p_sx, p_sy = camera.screen_point_from_grid_point(p.x, p.y)
			local t_sx, t_sy = camera.screen_point_from_grid_point(anim.target_x, anim.target_y)
			local angle = love.math.random() * TAU
			local radius = love.math.random() * 20
			t_sx = t_sx + mymath.abs_floor(math.cos(angle) * radius)
			t_sy = t_sy + mymath.abs_floor(math.sin(angle) * radius)
			table.insert(playstate.gun_lines, {p_sx + p.offset_px, p_sy + p.offset_py, t_sx, t_sy})
			anim.shot_timer = anim.shot_timer - 0.1
		end

		anim.shot_timer = anim.shot_timer + dt

		anim.t = anim.t + 0.5 * dt
	else
		-- anim finished
		local p = playstate.pawn_list[anim.pid]
		p.offset_px = 0
		p.offset_py = 0

		return true
	end

	return false
end

animations.functions["lean and shoot"] = function(anim, playstate, dt)
	if anim.t == 0 then
		--start the animation
		-- don't actually move!!!
		if playstate.current_map:get_pawn( anim.x1, anim.y1 ) ~= anim.pid then
			error("pawn in wrong place??")
		end

		local p = playstate.pawn_list[anim.pid]
		p.offset_px = 0
		p.offset_py = 0

		anim.shot_timer = 0

		anim.t = anim.t + 0.5 * dt
	elseif anim.t < 0.2 then
		local p = playstate.pawn_list[anim.pid]
		p.offset_px = mymath.abs_floor(TILE_SIZE * (anim.x2 - anim.x1) * (5 * anim.t))
		p.offset_py = mymath.abs_floor(TILE_SIZE * (anim.y2 - anim.y1) * (5 * anim.t))

		anim.t = anim.t + 0.5 * dt
	elseif anim.t < 0.8 then
		if anim.shot_timer > 0.1 then
			local p = playstate.pawn_list[anim.pid]
			local p_sx, p_sy = camera.screen_point_from_grid_point(p.x, p.y)
			local t_sx, t_sy = camera.screen_point_from_grid_point(anim.target_x, anim.target_y)
			local angle = love.math.random() * TAU
			local radius = love.math.random() * 20
			t_sx = t_sx + mymath.abs_floor(math.cos(angle) * radius)
			t_sy = t_sy + mymath.abs_floor(math.sin(angle) * radius)
			table.insert(playstate.gun_lines, {p_sx + p.offset_px, p_sy + p.offset_py, t_sx, t_sy})
			anim.shot_timer = anim.shot_timer - 0.1
		end

		anim.shot_timer = anim.shot_timer + dt

		anim.t = anim.t + 0.5 * dt
	elseif anim.t < 1 then
		local p = playstate.pawn_list[anim.pid]
		p.offset_px = mymath.abs_floor(TILE_SIZE * (anim.x2 - anim.x1) * (5 - 5 * anim.t))
		p.offset_py = mymath.abs_floor(TILE_SIZE * (anim.y2 - anim.y1) * (5 - 5 * anim.t))

		anim.t = anim.t + 0.5 * dt
	else
		-- anim finished
		local p = playstate.pawn_list[anim.pid]
		p.offset_px = 0
		p.offset_py = 0

		return true
	end

	return false
end


return animations
