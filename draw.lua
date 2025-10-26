function draw()
	cls()

	if show_title_screen then
		draw_title_screen()
		return
	end

	map(level.mapx, level.mapy, 0, 0, playablex + 1, playabley + 1)

	--draws the fences, actaully quite expensive, 17% of frame time
	--tile()

	if(debug) draw_steps()

	-- draw stuff
	for s in all(stuff) do
		s:draw()
	end

	-- draw player
	spr(psp, px * size, py * size, 1, 1, pd == -1)

	draw_bottom()
end

function draw_steps()
	for x = 0, playablex do
		for y = 0, playabley do
			local counter = level.grid[x + 1][y + 1].count
			if(counter <= 10) print(counter, x * size + 2, y * size + 2, 0)
		end
	end
end

function draw_bottom()
	draw_health()
	draw_coins()
	draw_inventory()
	draw_map()
end

function draw_health()
	print(level.completed
		and "delivered!"
		or "♥ " .. current_step_count .. " / " .. steps,
			2,
			(playabley + 1) * size + 2,
			14)
end

function draw_coins()
	if flash_coins and tick % shop_flash_tick == 0 then
		show_coins = not show_coins
	end

	if show_coins then
		print("♪ " .. coins,
			2,
			(playabley + 2) * size + 2,
			14)
	end
end

function draw_inventory()
	for i = 1, #inventory do
		local inv = inventory[i]

		if inv.flash and tick % inventory_flash_tick == 0 then
			inv.show = not inv.show
		end

		if not inv.flash or inv.flash and inv.show then
			spr(inv.sprite, (i + 2) * size, 15 * size)
		end
	end
end

function draw_map()
	local offsetx = 115
	local offsety = 114

	for x = 0, 3, 1 do
		for y = 0, 3, 1 do
			if is_level_completed(x * playablex, y * playabley) then
				rectfill(offsetx + x * 3, offsety + y * 3, offsetx + 3 + x * 3, offsety + 3 + y * 3, 7)
			else
				rect(offsetx + x * 3, offsety + y * 3, offsetx + 3 + x * 3, offsety + 3 + y * 3, 7)
			end
		end
	end
end

function tile()
	for x = level.mapx, level.mapx + playablex do
		for y = level.mapy, level.mapy + playabley do
			if full(x, y) then
				--first draw the base sprite so other sprites can draw on top
				tiler(floor_sprite, x, y)

				local left = full(x - 1, y)
				local right = full(x + 1, y)
				local up = full(x, y - 1)
				local down = full(x, y + 1)
				
				if left then
					if right then
						if up then
							if(down) tiler(96, x, y) else tiler(97, x, y)
						else
							if(down) tiler(98, x, y) else tiler(99, x, y)
						end
					else
						if up then
							if(down) tiler(100, x, y) else tiler(101, x, y)
						else
							if(down) tiler(102, x, y) else tiler(103, x, y)
						end
					end
				else
					if right then
						if up then
							if(down) tiler(104, x, y) else tiler(105, x, y)
						else
							if(down) tiler(106, x, y) else tiler(107, x, y)
						end
					else
						if up then
							if(down) tiler(108, x, y) else tiler(109, x, y)
						else
							if(down) tiler(110, x, y) else tiler(111, x, y)
						end
					end
				end
			end
		end
	end
end

function full(x, y)
	return mget(x, y) == 64
end

function tiler(sprite, x, y)
	spr(sprite, (x - level.mapx) * size, (y - level.mapy) * size)
end

function draw_title_screen()
	       --------------------------------
	local y = 0
	local dy = 10

	print_centered("strand and deliver", y, 14)
	y += dy + 1
	print_centered("developed by: first hour", y, 11)
	y += dy + 1
	print("goal: deliver the mail!", 0, y, 9)
	y += dy
	spr(1, 0, y - 2)
	spr(32, 32, y - 2)
	spr(33, 68, y - 2)
	spr(34, 86, y - 2)
	print("you", 10, y, 12)
	print("mail", 42, y, 8)
	print("▶", 80, y, 8)
	print("mailbox", 98, y, 4)
	y += dy
	print("earn", 0, y, 7)
	print("♪", 18, y, 14)
	print("and thankful citizens!", 27, y, 7)
	y += dy
	print("♥ 5 / 5 step limit-watch out!", 0, y, 8)
	spr(5, 120, y - 2, 1, 1, true)
	y += dy
	spr(48, 0, y - 2)
	spr(20, 0, y - 2)
	print("goal opens", 10, y, 15)
	spr(48, 51, y - 2)
	spr(21, 51, y - 2)
	print("when", 61, y, 15)
	print("▶", 88, y, 15)
	spr(32, 78, y - 2)
	spr(33, 93, y - 2)
	y += dy
	spr(19, 0, y - 2)
	print("bridge - place on   or", 10, y, 2)
	spr(51, 80, y - 2)
	spr(55, 100, y - 2)
	y += dy
	spr(37, 0, y - 2)
	print("rope - climb walls   ▶", 10, y, 9)
	spr(25, 84, y - 2)
	spr(38, 99, y - 2)
	y += dy
	spr(35, 0, y - 2)
	spr(42, 32, y - 2)
	spr(41, 68, y - 2)
	spr(8, 100, y - 2)
	print("apple   banana   boots   boat", 10, y, 7)
	y += dy
	spr(6, 0, y - 2)
	spr(76, 24, y - 2)
	spr(7, 33, y - 2)
	spr(40, 73, y - 2)
	print("dog     boulder   rock", 10, y, 7)
	y += dy
	print_centered("... and more!", y, 13)

	       --------------------------------
	print("   press ⬆️ ⬇️ ⬅️ ➡️ to play!", 0, 123, 14)
end

function print_centered(str, y, color)
  print(str, 64 - (#str * 2), y, color) 
end
