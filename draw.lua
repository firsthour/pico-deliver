function draw()
	cls()
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
	print(level.completed
		and "delivered!"
		or "♥ " .. current_step_count .. " / " .. steps,
			2,
			(playabley + 1) * size + 2,
			14)

	print("♪ " .. coins,
		2,
		(playabley + 2) * size + 2,
		14)

	for i = 1, #inventory do
		spr(inventory[i].sprite, (i + 2) * size, 15 * size)
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
	return mget(x, y) == 63
end

function tiler(sprite, x, y)
	spr(sprite, (x - level.mapx) * size, (y - level.mapy) * size)
end
