dirx = { -1, 1, 0, 0 }
diry = { 0, 0, -1, 1 }

function build_grid(mapx, mapy, lvl)
	local grid = init_grid(max)
	local cand = {}
	local step = 0

	pq("building grid")

	--initialize with player position
	add(cand, { x = px, y = py })

	repeat
		local candnew = {}
		for c in all(cand) do
			grid[c.x + 1][c.y + 1].count = step
						
			for d = 1, 4 do
				local dx = c.x + dirx[d]
				local dy = c.y + diry[d]

				if inbounds(dx, dy)
				and grid[dx + 1][dy + 1].count == max
				and not fget(mget(mapx + dx, mapy + dy), 0) then
					grid[dx + 1][dy + 1].count = max - 1
					add(candnew, { x = dx, y = dy })
				end
			end
		end

		cand = candnew
		step += 1
	until #cand == 0

	return grid
end

function init_grid(val)
	local grid = {}
	for x = 1, playablex + 1 do
		grid[x] = {}
		for y = 1, playabley + 1 do
			grid[x][y] = { count = val }
		end
	end
	return grid
end

function inbounds(x, y)
	return x >= 0 and x <= playablex and y >= 0 and y <= playabley
end
