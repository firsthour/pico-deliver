function move()
	tick += 1
	moved = false

	if teleporting then
		teleport()
		return
	end

	grow_grass()
	
	if not sliding then
		walk()
	elseif tick % slide_tick == 0 then
		slide()
	end

	handle()

	if reset_level_flag then
		reset_level_steps()
		path[1].s = current_step_count
		reset_level_flag = false
	end
end

function walk()
	local bl = btnp(⬅️)
	local br = btnp(➡️)
	local bu = btnp(⬆️)
	local bd = btnp(⬇️)

	if(btnp(❎)) debug = not debug

	--flip direction
	pd = bl and -1 or br and 1 or pd

	--move player
	if bl and px > 0 and check(px - 1, py) then
		px -= 1
		pt = false
		if not boating then
			current_step_count -= 1
			store_path()
		else
			lava_flow()
		end
		moved = true
		last_move = "left"
	elseif br and px < playablex and check(px + 1, py) then
		px += 1
		pt = false
		if not boating then
			current_step_count -= 1
			store_path()
		else
			lava_flow()
		end
		moved = true
		last_move = "right"
	elseif bu and py > 0 and check(px, py - 1) then
		py -= 1
		pt = false
		if not boating then
			current_step_count -= 1
			store_path()
		else
			lava_flow()
		end
		moved = true
		last_move = "up"
	elseif bd and py < playabley and check(px, py + 1) then
		py += 1
		pt = false
		if not boating then
			current_step_count -= 1
			store_path()
		else
			lava_flow()
		end
		moved = true
		last_move = "down"
	elseif pt and (bl and px == 0 or br and px == playablex or bu and py == 0 or bd and py == playabley) then
		--move between maps while traveling
		change_map()
		moved = true
		level.grid = build_grid(level.mapx, level.mapy, level)
		level.grass = 0
	end

	if(moved) pq(last_move)

	--player has run out of steps so teleport them to the level's origin
	if not debug and not level.completed and current_step_count < 0 then
		die()
		teleport_started = true
	end
end

function die()
	sfx(18)
	current_step_count = 0
	psp = 5
	pt = true
	teleporting = true
	booting = false
	del(path, path[1])
	pq("path =", path)

	for i = 1, #inventory do
		if inventory[i].type == "boot" and inventory[i].flash then
			inventory[i].flash = false
		end
	end
end

function check(nextx, nexty)
	if(nextx < 0 or nextx > playablex or nexty < 0 or nexty > playabley) return false
	if(debug or current_step_count == 0) return true
	
	local checkx = nextx + level.mapx
	local checky = nexty + level.mapy

	if boating then
		local loc = mget(checkx, checky)
		return loc == 22 or loc == 26 or loc == 55 or loc == 27 or loc == 28 or loc == 95 or loc == 94
	end
	
	local disable_booting = false
	local loc = mget(checkx, checky)
	if loc == floor_sprite + 3 then
		--water, bridge
		for i in all(inventory) do
			if i.bridge then
				sfx(1)
				i.placed = true
				del(inventory, i)
				mset(checkx, checky, i.sprite)
				reset_level_flag = true
				level.grid = build_grid(level.mapx, level.mapy, level)
				level.grass = 0
				paint_walls()
				break
			end
		end
	elseif loc == 25 and nexty == py - 1 then
		--below wall, rope
		for i in all(inventory) do
			if i.rope then
				sfx(1)
				del(inventory, i)
				mset(checkx, checky, 38)
				reset_level_flag = true
				unpaint_walls()
				return true
			end
		end
	elseif (loc == 24 or loc == 25 or loc == 38 or loc == 39) and nexty == py + 1 then
		--above wall, jump
		sfx(19)
		py += 1
		level.grid = build_grid(level.mapx, level.mapy, level)
		grow_grass_impl(current_step_count)
		return true
	elseif booting and loc != 80 then
		disable_booting = true
	end
	
	local push_ok = push_check(nextx, nexty)
	if(not push_ok) return false

	local counter = level.grid[nextx + 1][nexty + 1].count
	local okay = level.completed and counter < max or counter <= steps and current_step_count > 0
	if(not okay) return false

	pq("gate check", nextx + level.mapx, nexty + level.mapy)
	for s in all(stuff) do
		if(s.gate and not s.open and s.x == nextx + level.mapx and s.y == nexty + level.mapy) return false
	end

	if disable_booting then
		booting = false
		
		for i = 1, #inventory do
			local flashing_boot
			if inventory[i].type == "boot" and inventory[i].flash then
				flashing_boot = inventory[i]
				flashing_boot.flash = false
			end

			if flashing_boot then
				path[1].boot = flashing_boot
				del(inventory, flashing_boot)
			end
		end
	end

	return true
end

function handle()
	for s in all(stuff) do
		if(not teleporting and s:same_level()) s:handle()
	end
end

function unmove()
	for s in all(stuff) do
		if(s.mover and s.ground and s:same_level()) s:unmove()
	end
end

function reset()
	for s in all(stuff) do
		if(s.ground and s:same_level()) s:reset()
	end
end

function grow_grass()
	if tick % grass_tick == 0 and (level.grass < steps or level.completed and level.grass < playablex + playabley) then
		level.grass += 1
		grow_grass_impl(level.grass)
	end
end

function grow_grass_impl(limit)
	--don't grow grass along edges
	for x = 2, playablex do
		for y = 2, playabley do
			local loc = mget(x - 1 + level.mapx, y - 1 + level.mapy)
			if level.grid[x][y].count <= limit then
				if loc == floor_sprite or loc == floor_sprite + 1 then
					mset(x - 1 + level.mapx, y - 1 + level.mapy, floor_sprite + 2)
				end
			elseif loc == floor_sprite + 2 then
				mset(x - 1 + level.mapx, y - 1 + level.mapy, floor_sprite + 1)
			end
		end
	end

	store_level_grass(limit)
end

function teleport()
	--only move every X frames
	if(tick % (path[1].sliding and teleport_slide_tick or teleport_tick) != 0) return

	pq("teleporting", path[1], path[1].x, path[1].y)
	if #path > 0 then
		px = path[1].x
		py = path[1].y
		pd = path[1].d
		current_step_count = path[1].s

		if(current_step_count < 0) current_step_count = 0

		if(path[1].item) path[1].item:unhandle()

		if path[1].boot then
			pq("greg path booted")
			add(inventory, path[1].boot)
		end

		local checkx = px + level.mapx
		local checky = py + level.mapy
		
		--remove rope during rewind
		if mget(checkx, checky) == 38 then
			mset(checkx, checky, 24)
		end

		--remove bridge during rewind
		if mget(checkx, checky) == 27 then
			mset(checkx, checky, floor_sprite + 3)
		end

		--wait one set of ticks for the player to actually rewind
		if not teleport_started then
			unmove()
			if(path[1].pushed) path[1].pushed:unpush()
		end
		teleport_started = false
		
		del(path, path[1])
	end

	if #path == 0 then
		teleporting = false
		current_step_count = steps
		px = level.originx
		py = level.originy
		psp = 1
		path = {}
		add(path, {
			x = level.originx,
			y = level.originy,
			d = pd,
			s = current_step_count
		})

		reset_level_steps()
	end
end

function reset_level_steps()
	current_step_count = steps
	level.grid = build_grid(level.mapx, level.mapy, level)
	level.grass = 0
end

function store_path()
	if not level.completed then
		add(path, {
			x = px,
			y = py,
			d = pd,
			s = current_step_count
		}, 1)
	end
end

function paint_walls()
	for x = 1, playablex do
		for y = 1, playabley do
			local loc = mget(x + level.mapx, y + level.mapy)
			if loc == 24 and level.grid[x + 1][y + 2].count <= steps then
				mset(x + level.mapx, y + level.mapy, 25)
			end
		end
	end
end

function unpaint_walls()
	if not has_rope then
		for x = 1, playablex do
			for y = 1, playabley do
				local loc = mget(x + level.mapx, y + level.mapy)
				if loc == 25 then
					mset(x + level.mapx, y + level.mapy, 24)
				end
			end
		end
	end
end

function update_lava_gates()
	for x = 0, 127 do
		for y = 0, 63 do
			local loc = mget(x, y)
			if(loc == 79) mset(x, y, 95)
		end
	end
end

function lava_flow()
	if(lavad[py - 1 + level.mapy]) return

	local row_above = py - 1 + level.mapy
	lavad[row_above] = true

	if row_above == 3 then
		for x = 7, 8 do
			mset(x + level.mapx, row_above, 22)
		end
	elseif row_above == 4 then
		mset(8 + level.mapx, row_above, 22)
	elseif row_above == 5 then
		for x = 8, 9 do
			mset(x + level.mapx, row_above, 26)
		end
	elseif row_above == 6 then
		for x = 8, 10 do
			mset(x + level.mapx, row_above, 22)
		end
	elseif row_above == 7 then
		for x = 8, 11 do
			mset(x + level.mapx, row_above, 26)
		end
	elseif row_above == 8 then
		for x = 8, 12 do
			mset(x + level.mapx, row_above, 22)
		end
	elseif row_above == 9 then
		for x = 8, 13 do
			mset(x + level.mapx, row_above, 26)
		end
	elseif row_above == 47 or row_above == 49 or row_above == 50 then
		for x = 1, playablex - 1 do
			mset(x + level.mapx, row_above, 22)
		end
	elseif row_above == 48 then
		for x = 1, playablex - 1 do
			mset(x + level.mapx, row_above, 26)
		end
	else
		--find the lava map tile on the row above
		local loc = mget(3 + level.mapx, py - 1 + level.mapy)
		for x = 1, playablex - 1 do
			mset(x + level.mapx, py - 1 + level.mapy, loc)
		end
	end

	for s in all(stuff) do
		if(s.ground and s:above_row()) s.ground = false
	end
end

function slide()
	local dx = 0
	local dy = 0
	if last_move == "right" then
		dx = 1
	elseif last_move == "left" then
		dx = -1
	elseif last_move == "up" then
		dy = -1
	else
		dy = 1
	end

	local counter = level.grid[px + dx + 1][py + dy + 1].count
	if counter == max then
		pq("blocked wall")
		sliding = false
	else
		local blocked = false
		for s in all(stuff) do
			if s.ground and s.pushable and s.x == level.mapx + px + dx and s.y == level.mapy + py + dy then
				blocked = true
				break
			end
		end

		if not blocked then
			px += dx
			py += dy
			pt = false
			store_path()
			moved = true
			path[1].sliding = true

			local loc = mget(px + level.mapx, py + level.mapy)
			if loc != 80 then
				sliding = false
			end
		else
			pq("blocked item")
			sliding = false
		end
	end
	
	if not level.completed then
		level.grid = build_grid(level.mapx, level.mapy, level)
		grow_grass_impl(current_step_count)
	end
end

function push_check(nextx, nexty)
	for s in all(stuff) do
		if s.pushable and s.ground and s:same_level() and s.x == level.mapx + nextx and s.y == level.mapy + nexty then
			local dx = nextx - px
			local dy = nexty - py

			local dest = level.grid[nextx + 1 + dx][nexty + 1 + dy].count
			if dest == max then
				return false
			else
				for s2 in all(stuff) do
					if s2.ground and not s2.ice and s2:same_level() and s2.x == nextx + dx + level.mapx and s2.y == nexty + dy + level.mapy then
						return false
					end
				end
			end

			s.pushing = true
			s.pushingx = nextx + dx + level.mapx
			s.pushingy = nexty + dy + level.mapy
			return true
		end
	end

	return true
end