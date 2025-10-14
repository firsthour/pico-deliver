function move()
	tick += 1

	if teleporting then
		teleport()
		return
	end

	grow_grass()
	walk()
	handle()
end

function walk()
	local bl = btnp(⬅️)
	local br = btnp(➡️)
	local bu = btnp(⬆️)
	local bd = btnp(⬇️)

	--flip direction
	pd = bl and -1 or br and 1 or pd
	
	--move player
	if bl and px > 0 and check(px - 1, py) then
		px -= 1
		pt = false
		current_step_count -= 1
		add(path, {
			x = px,
			y = py,
			d = pd,
			s = current_step_count
		}, 1)
	elseif br and px < playablex and check(px + 1, py) then
		px += 1
		pt = false
		current_step_count -= 1
		add(path, {
			x = px,
			y = py,
			d = pd,
			s = current_step_count
		}, 1)
	elseif bu and py > 0 and check(px, py - 1) then
		py -= 1
		pt = false
		current_step_count -= 1
		add(path, {
			x = px,
			y = py,
			d = pd,
			s = current_step_count
		}, 1)
	elseif bd and py < playabley and check(px, py + 1) then
		py += 1
		pt = false
		current_step_count -= 1
		add(path, {
			x = px,
			y = py,
			d = pd,
			s = current_step_count}, 1)
	end

	--player has run out of steps so teleport them to the level's origin
	if not debug and not level.completed and current_step_count < 0 then
		current_step_count = 0
		psp = 5
		pt = true
		teleporting = true
		pq("path =", path)
	end
end

function check(nextx, nexty)
	if(nextx < 0 or nextx > playablex or nexty < 0 or nexty > playabley) return false
	if(debug or current_step_count == 0) return true
	local counter = level.grid[nextx + 1][nexty + 1].count
	return level.completed and counter < max or counter <= steps and current_step_count > 0
end

function handle()
	--for s in all(level.stuff) do
	for s in all(stuff) do
		if(not teleporting and s.x >= level.mapx and s.x <= level.mapx + playablex and s.y >= level.mapy and s.y <= level.mapy + playabley) s:handle()
	end
end

function grow_grass()
	if tick % grass_tick == 0 and (level.grass < steps or level.completed and level.grass < playablex + playabley) then
		level.grass += 1

		--don't grow grass along edges
		for x = 2, playablex do
			for y = 2, playabley do
				local loc = mget(x - 1 + level.mapx, y - 1 + level.mapy)
				if level.grid[x][y].count <= level.grass then
					if loc == floor_sprite or loc == floor_sprite + 1 then
						mset(x - 1 + level.mapx, y - 1 + level.mapy, floor_sprite + 2)
					end
				elseif loc == floor_sprite + 2 then
					mset(x - 1 + level.mapx, y - 1 + level.mapy, floor_sprite + 1)
				end
			end
		end

		store_level_grass(level.grass)
	end
end

function teleport()
	--only move every X frames
	if(tick % teleport_tick != 0) return

	pq("teleporting", path[1], path[1].x, path[1].y)
	if #path > 0 then
		px = path[1].x
		py = path[1].y
		pd = path[1].d
		current_step_count = path[1].s

		if(current_step_count < 0) current_step_count = 0

		if(path[1].item) path[1].item:unhandle()

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
