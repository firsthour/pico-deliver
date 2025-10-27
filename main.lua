function _init()
	version = "1.0.0"

	--globals
	max = 0x7fff
	debug = false
	open_gate_sprite = 21
	base_floor_sprite = 48
	floor_sprite = base_floor_sprite
	debug_world = 0

	tick = 0
	teleport_tick = 8
	teleport_slide_tick = 4
	grass_tick = 4
	slide_tick = 4
	rock_slide_tick = 2
	shop_flash_tick = 8
	inventory_flash_tick = 8

	--enable keyboard for wasd
	poke(0x5f2d, 1)
	
	--hold down button frames
	poke(0x5f5c, 5) --start
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
	reset_level_flag = false
	reset_grass_flag = false
	boating = false
	lavad = {}
	lavad[playabley] = true
	lavad[playabley * 2] = true
	lavad[playabley * 3] = true
	sliding = false
	last_move = ""
	booting = false
	show_coins = true
	flash_coins = false
	show_title_screen = false
	warping = false
	latest_level = 0
	latest_level_change_map = 0
	music_track = -1
	music_on = true
	show_win_screen = false
	total_death_count = 0
	total_step_count = 0
	ice_sfx = false
	death_flag = false
	second_counter = 0

	scan_and_update_full_map()

	setup_starting_level()
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

	floor_sprite = calc_floor_sprite(lvl.mapx, lvl.mapy)

	return lvl
end

function calc_floor_sprite(x, y)
	if x >= 0 and x < playablex then
		return base_floor_sprite
	elseif x >= playablex and x < playablex * 2 then
		return base_floor_sprite + 4
	elseif x >= playablex * 2 and y >= playabley * 2 then
		return base_floor_sprite + 8
	elseif x >= playablex * 2 and y < playabley * 2 then
		return base_floor_sprite + 12
	end
end

function scan_and_update_full_map()
	for x = 0, 127 do
		for y = 0, 63 do
			local loc = mget(x, y)
			local fs = calc_floor_sprite(x, y)
			
			if loc == fs then
				--draw sad textured ground
				mset(x, y, fs + 1)
			elseif loc == 67 then
				--envelope
				mset(x, y, fs + 1)
				add(stuff, envelope:new("envelope", x, y))
			elseif loc == 65 then
				--mailbox
				mset(x, y, fs)
				add(stuff, mailbox:new("mailbox", x, y))
			elseif loc == 68 or loc == 74 or loc == 85 then
				--gate
				mset(x, y, fs)
				local gate = gate:new("gate", x, y)
				if loc == 74 or loc == 85 then
					gate.open = true
					gate.sprite = open_gate_sprite
				end
				if loc == 74 or loc == 85 then
					gate.lock_behind = true
				end
				add(stuff, gate)
			elseif loc == 69 then
				--apple
				mset(x, y, fs)
				add(stuff, food:new("apple", x, y, 35))
			elseif loc == 70 then
				--shop bridge
				mset(x, y, fs)
				local shop = shop:new("shop", x, y)
				shop.price = 3
				shop.item = bridge:new("bridge", 0, 0)
				add(stuff, shop)
			elseif loc == 83 then
				--shop boot
				mset(x, y, fs)
				local shop = shop:new("shop", x, y)
				shop.price = 4
				shop.item = boot:new("boot", 0, 0)
				add(stuff, shop)
			elseif loc == 71 then
				--river
				mset(x, y, fs + 3)
			elseif loc == 72 or loc == 73 then
				--dog
				mset(x, y, fs + 1)
				local dog = dog:new("dog", x, y)
				if loc == 73 then
					dog.xdirection = -1
					dog.oxdirection = -1
				end
				add(stuff, dog)
			elseif loc == 75 then
				--rope
				mset(x, y, fs + 1)
				add(stuff, rope:new("rope", x, y))
			elseif loc == 76 then
				--cave
				add(stuff, cave:new("cave", x, y))
			elseif loc == 77 then
				--bridge
				mset(x, y, fs)
				add(stuff, bridge:new("bridge", x, y, 27))
			elseif loc == 78 then
				--boat
				mset(x, y, fs)
				add(stuff, boat:new("boat", x, y, 78))
			elseif loc == 79 then
				--lava gate
				add(stuff, lavagate:new("lava gate", x, y))
			elseif loc == 94 then
				--lava mailbox
				add(stuff, lavamailbox:new("lava mailbox", x, y))
			elseif loc == 80 then
				--ice
				add(stuff, ice:new("ice", x, y))
			elseif loc == 81 then
				--rock
				mset(x, y, fs)
				add(stuff, rock:new("rock", x, y))
			elseif loc == 82 then
				--boot
				mset(x, y, fs)
				add(stuff, boot:new("boot", x, y))
			elseif loc == 84 then
				--banana
				mset(x, y, fs)
				add(stuff, banana:new("banana", x, y))
			elseif loc == 86 then
				--disappearing block
				mset(x, y, 64)
				add(stuff, disappearing_block:new("disappearing_block", x, y))
			elseif loc == 87 then
				--warp
				mset(x, y, 87)
				add(stuff, warp:new("warp", x, y))
			elseif loc == 66 then
				--player, should only be at the very start
				mset(x, y, fs)
				px = x
				py = y
			end
		end
	end
end

function setup_starting_level()
	if debug_world == 1 then
		steps = 5
		coins = 0
		level = build_level(0, 0)
		px = 1
		py = 2
	elseif debug_world == 2 then
		steps = 6
		coins = 3
		level = build_level(0, playabley * 2)
		px = 8
		py = 13
	elseif debug_world == 3 then
		steps = 7
		coins = 1
		level = build_level(0, playabley * 3)
		px = 15
		py = 12
	elseif debug_world == 4 then
		steps = 7
		level = build_level(playablex, playabley * 3)
		px = 13
		py = 0
	elseif debug_world == 5 then
		steps = 7
		level = build_level(playablex, playabley)
		px = 8
		py = 0
	elseif debug_world == 6 then
		steps = 7
		coins = 5
		level = build_level(playablex, playabley * 3)
		px = 15
		py = 12
	elseif debug_world == 7 then
		steps = 8
		level = build_level(playablex * 2, playabley * 3)
		px = 15
		py = 11
	elseif debug_world == 8 then
		steps = 8
		coins = 7
		level = build_level(playablex * 3, playabley * 3)
		px = 11
		py = 0
	elseif debug_world == 9 then
		steps = 8
		coins = 5
		level = build_level(playablex * 2, playabley * 2)
		px = 7
		py = 0
	elseif debug_world == 10 then
		steps = 8
		coins = 6
		level = build_level(playablex * 2, playabley)
		px = 7
		py = 0
	elseif debug_world == 11 then
		steps = 8
		coins = 7
		level = build_level(playablex * 2, 0)
		latest_level_change_map = 12
		px = 15
		py = 3
	elseif debug_world == 12 then
		steps = 8
		coins = 8
		level = build_level(playablex * 3, 0)
		latest_level = 15
		latest_level_change_map = 12
		px = 8
		py = 13
	else
		level = build_level(0, 0)
		show_title_screen = true
	end
end