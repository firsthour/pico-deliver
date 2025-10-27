function draw()
	cls()

	if show_title_screen then
		draw_title_screen()
		return
	end

	if show_win_screen then
		draw_win_screen()
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

function draw_title_screen()
	       --------------------------------
	local y = 0
	local dy = 10

	print_centered("step and deliver by first hour", y, 14)
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
	spr(76, 31, y - 2)
	spr(7, 40, y - 2)
	spr(40, 88, y - 2)
	print("dog       boulder     rock", 10, y, 7)
	y += dy
	print_centered("... and more!", y, 7)
	y += dy
	print("🅾️ toggle music         ❎ pause", 0, y, 13)

	       --------------------------------
	print("   press ⬆️ ⬇️ ⬅️ ➡️ to play!", 0, 123, 14)
end

function print_centered(str, y, color)
  print(str, 64 - (#str * 2), y, color) 
end

function draw_win_screen()
	       --------------------------------
	local y = 0
	local dy = 10

	print_centered("you win! thank you for playing..", y, 9)
	y += dy
	print_centered("step and deliver by: first hour", y, 14)
	y += dy
	print_centered("steps: " .. total_step_count, y, 4)
	y += dy
	print_centered("deaths: " .. total_death_count, y, 5)
	y += dy
	print_centered("time: " .. second_counter .. " seconds", y, 2)
	y += dy
	print("music credits:", 0, y, 13)
	y += dy
	print("the sailor's hornpipe", 0, y, 11)
	y += dy + 2
	print("vesuvius (clarinet part)", 0, y, 8)
	print("- frank ticheli", 0, y + 8, 8)
	y += dy + dy
	print("in the evening mist (from hausu)", 0, y, 12)
	print("- asei kobayashi, mickie yoshino", 0, y + 8, 12)
	y += dy + dy
	print("main theme (from only yesterday)", 0, y, 7)
	print("- katsu hoshi", 0, y + 8, 7)
end
