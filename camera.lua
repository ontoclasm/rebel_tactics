local camera = { px=0, py=0, real_px=0, real_py=0, target_px=0, target_py=0 }

function camera.update()
	-- lerp the camera
	-- if controller:getActiveDevice() == "joystick" then
	-- 	camera.tx = target_pos.x - window_w/2
	-- 	camera.ty = target_pos.y - window_h/2
	-- else
		-- camera.tx = target_pos.x - window_w/2
		-- camera.ty = target_pos.y - window_h/2
	-- end

	-- don't move if it's only a 1px adjustment; this avoids irritating little twitches due to rounding error in some cases
	if math.abs(camera.target_px - camera.real_px) >= 2 then
		camera.real_px = camera.real_px - (camera.real_px - camera.target_px) * 0.1
	end
	if math.abs(camera.target_py - camera.real_py) >= 2 then
		camera.real_py = camera.real_py - (camera.real_py - camera.target_py) * 0.1
	end

	camera.px, camera.py = math.floor(camera.real_px - window_w/2), math.floor(camera.real_py - window_h/2)
end

function camera.shift_target(dpx, dpy)
	camera.target_px = camera.target_px + dpx
	camera.target_py = camera.target_py + dpy
end

function camera.set_location(px, py)
	camera.target_px = px
	camera.real_px = px
	camera.target_py = py
	camera.real_py = py
	camera.update()
end

function camera.grid_point_from_screen_point(sx, sy)
	return math.floor((sx + camera.px) / TILE_SIZE), math.floor((sy + camera.py) / TILE_SIZE)
end

function camera.screen_point_from_grid_point(gx, gy)
	return (gx * TILE_SIZE) - camera.px, (gy * TILE_SIZE) - camera.py
end

-- #verifyvenuz
function camera.shake(v, angle)
	angle = angle or love.math.random() * 2 * math.pi
	camera.real_px = camera.real_px + v * math.cos(angle)
	camera.real_py = camera.real_py + v * math.sin(angle)
end

return camera
