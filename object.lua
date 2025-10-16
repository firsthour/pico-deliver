--https://www.lexaloffle.com/bbs/?tid=141946

object = {
	x,
	y,
	originx,
	originy,
	sprite,
	ground = true,
	deliverable = false,
	bridge = false,
	direction = 1,
	mover = false
}

function object:new(x, y, sprite)
	local obj = { x = x, y = y, sprite = sprite, originx = x, originy = y }
	return setmetatable(obj, {__index = self})
end

function draw_object(obj)
	spr(obj.sprite, (obj.x - level.mapx) * size, (obj.y - level.mapy) * size, 1, 1, obj.direction == -1)
end

function object:draw()
	if self.ground and self:same_level() then
		draw_object(self)
	end
end

function object:coll()
	return self.ground and self:same_level() and px == self.x - level.mapx and py == self.y - level.mapy
end

function object:same_level()
	return self.x >= level.mapx and self.x <= level.mapx + playablex and self.y >= level.mapy and self.y <= level.mapy + playabley
end

--on collision
function object:handle()
end

--on teleporting to put it back
function object:unhandle()
end

function object:reset()
end

envelope = object:new()
envelope.sprite = 32
envelope.deliverable = true

function envelope:handle()
	if self:coll() then
		sfx(0)
		self.ground = false
		path[1].item = self
		add(inventory, self)
		--coins += 1

		reset_level_steps()

		path[1].s = current_step_count
	end
end

function envelope:unhandle()
	del(inventory, self)
	self.ground = true
	--coins -= 1
end

mailbox = object:new()
mailbox.sprite = 33

function mailbox:handle()
	if self.sprite == 33 and self:coll() then
		for i in all(inventory) do
			if(i.deliverable) then
				sfx(1)
				del(inventory, i)
				self.sprite = 34
				level.completed = true
				store_level_completion()
				coins += 1
				break
			end
		end
	end
end

gate = object:new()
gate.sprite = 20
gate.open = false

function gate:handle()
	if level.completed and not self.open then
		mset(self.x, self.y, floor_sprite)
		self.open = true
		self.sprite = open_gate_sprite
	end

	if not pt and self:coll() then
		pt = true
		change_map()
	end
end

food = object:new()

function food:handle()
	if self:coll() then
		sfx(0)
		self.ground = false
		path[1].item = self
		steps += 1
		
		reset_level_steps()

		path[1].s = current_step_count
	end
end

function food:unhandle()
	self.ground = true
	steps -= 1
	current_step_count -= 1
end

shop = object:new()

function shop:draw()
	if self.ground and self:same_level() then
		--draw stamp
		draw_object(self)

		--draw object to sell
		spr(19, (self.x - level.mapx) * size, (self.y - level.mapy - 1) * size)

		local x = (self.x - level.mapx) * size
		local y = (self.y - level.mapy) * size + 2
		print("3", x, y, 0)
		print("♪", x + 3, y, 0)
		print("shop", x - 4, y + 8, 0)
	end
end

function shop:handle()
	if self:coll() and coins >= 3 then
		self.ground = false
		add(inventory, bridge:new(0, 0))
		coins -= 3
	end
end

bridge = object:new()
bridge.bridge = true
bridge.sprite = 19

dog = object:new()
dog.sprite = 6
dog.mover = true

function dog:handle()
	if self:coll() then
		die()
	elseif moved and not pt then
		self:move()
	end
end

function dog:move()
	pq("dog move")
	if check_enemy_move(self.x + self.direction - level.mapx, self.y - level.mapy) then
		self.x += self.direction
	else
		self.direction = self.direction * -1
		self.x += self.direction
	end
end

function dog:unmove()
	if check_enemy_move(self.x + self.direction * -1 - level.mapx, self.y - level.mapy) then
		self.x += self.direction * -1
	else
		self.direction = self.direction * -1
		self.x += self.direction * -1
	end
end

function dog:reset()
	self.x = self.originx
	self.y = self.originy
	self.direction = 1
end

function check_enemy_move(nextx, nexty)
	return not (nextx < 0 or nextx > playablex or nexty < 0 or nexty > playabley or level.grid[nextx + 1][nexty + 1].count == max)
end
