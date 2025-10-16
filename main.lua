function _init()
	pq("start")

	--globals
	max = 0x7fff
	--debug = true
	open_gate_sprite = 21
	floor_sprite = 48

	tick = 0
	teleport_tick = 8
	grass_tick = 4
	
	--hold down button frames
	poke(0x5f5c, 4) --start
	poke(0x5f5d, 2) --continue

	--map size
	size = 8
	playablex = 15
	playabley = 13

	-- player info
	psp = 1 --player sprite
	px = 0 --player x tile
	py = 0 --player y tile
	pd = 0 --player direction
	pt = false --is player traveling
	teleporting = false
	teleport_started = false
	steps = 5 --player steps
	current_step_count = steps --current step count
	path = {}
	inventory = {}
	stuff = {} --loaded up in scan_and_update_full_map()
	completed_levels = {} --use helper methods for lookup
	grass_levels = {} --use helper methods for lookup
	coins = 0
	moved = false
	enemies = {}

	scan_and_update_full_map()

	level = build_level(0, 0)

	--music(4)
end

function _update60()
	move()
end

function _draw()
	draw()
end

function build_level(x, y, comp)
	local lvl = {
		mapx = x,
		mapy = y,
		completed = comp or false,
		grid, --initialized below after scan_and_update_map()
	}

	lvl.grid = build_grid(x, y, lvl)
	lvl.grass = get_level_grass(x, y)
	lvl.originx = px
	lvl.originy = py

	path = {}
	add(path, {
		x = px,
		y = py,
		d = pd,
		s = current_step_count
	})

	return lvl
end

function scan_and_update_full_map()
	for x = 0, 127 do
		for y = 0, 63 do
			local loc = mget(x, y)
			
			if loc == floor_sprite then
				--draw sad textured ground
				mset(x, y, floor_sprite + 1)
			elseif loc == 60 then
				--envelope
				pq("envelope", x, y)
				mset(x, y, floor_sprite)
				add(stuff, envelope:new(x, y))
			elseif loc == 62 then
				--mailbox
				pq("mailbox", x, y)
				mset(x, y, floor_sprite)
				add(stuff, mailbox:new(x, y))
			elseif loc == 59 then
				--gate
				pq("gate", x, y)
				mset(x, y, floor_sprite)
				add(stuff, gate:new(x, y))
			elseif loc == 58 then
				--apple
				pq("apple", x, y)
				mset(x, y, floor_sprite)
				add(stuff, food:new(x, y, 35))
			elseif loc == 57 then
				--shop
				pq("shop", x, y)
				mset(x, y, floor_sprite)
				add(stuff, shop:new(x, y, 36))
			elseif loc == 56 then
				--river
				pq("river", x, y)
				mset(x, y, floor_sprite + 3)
			elseif loc == 55 then
				--dog
				pq("dog", x, y)
				mset(x, y, floor_sprite)
				add(stuff, dog:new(x, y))
			elseif loc == 61 then
				--player, should only be at the very start
				pq("player", x, y)
				mset(x, y, floor_sprite)
				px = x
				py = y
			end
		end
	end
end

function change_map()
	local newx, newy = level.mapx, level.mapy

	if py == 0 then
		pq("north")
		py = playabley
		newy -= playabley
	elseif py == playabley then
		pq("south")
		py = 0
		newy += playabley
	elseif px == 0 then
		pq("west")
		px = playablex
		newx -= playablex
	else
		pq("east")
		px = 0
		newx += playablex
	end

	current_step_count = steps

	local lvl = build_level(newx, newy, is_level_completed(newx, newy))

	level = lvl

	reset()
end

function store_level_completion()
	completed_levels[level.mapx * 13 + level.mapy * 9] = true
end

function is_level_completed(mapx, mapy)
	return completed_levels[mapx * 13 + mapy * 9]
end

function store_level_grass(grass)
	grass_levels[level.mapx * 13 + level.mapy * 9] = grass
end

function get_level_grass(mapx, mapy)
	return grass_levels[mapx * 13 + mapy * 9] or 0
end
