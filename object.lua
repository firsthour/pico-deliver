--https://www.lexaloffle.com/bbs/?tid=141946

object = {
	type,
	x,
	y,
	originx,
	originy,
	sprite,
	ground = true,
	deliverable = false,
	bridge = false,
	rope = false,	
	xdirection = 1,
	oxdirection = 1,
	mover = false,
	pushable = false
}

function object:new(type, x, y, sprite)
	pq("new", type, x, y)
	local obj = { type = type, x = x, y = y, sprite = sprite, originx = x, originy = y }
	return setmetatable(obj, {__index = self})
end

function draw_object(obj)
	spr(obj.sprite, (obj.x - level.mapx) * size, (obj.y - level.mapy) * size, 1, 1, obj.xdirection == -1)
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

function object:same_row()
	return self:same_level() and self.y - level.mapy == py
end

function object:above_row()
	return self:same_level() and self.y - level.mapy == py - 1
end

--on collision
function object:handle()
end

--on teleporting to put it back
function object:unhandle()
end

function object:reset()
end

function object:level_complete()
end

function object:unpush()
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

		reset_level_steps()

		path[1].s = current_step_count
	end
end

function envelope:unhandle()
	del(inventory, self)
	self.ground = true
end

mailbox = object:new()
mailbox.sprite = 33

function mailbox:handle()
	if self.sprite == 33 and self:coll() then
		local comp = false

		for i in all(inventory) do
			if(i.deliverable) then
				del(inventory, i)
				coins += 1
				comp = true
			end
		end

		if comp then
			sfx(1)
			self.sprite = 34
			level.completed = true
			store_level_completion()
			current_step_count = -1

			for s in all(stuff) do
				if(s:same_level()) s:level_complete()
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
		spr(27, (self.x - level.mapx) * size, (self.y - level.mapy - 1) * size)

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
		add(inventory, bridge:new("bridge", 0, 0))
		coins -= 3
	end
end

bridge = object:new()
bridge.bridge = true
bridge.sprite = 27
bridge.placed = false

function bridge:handle()
	if not bridge.placed and self:coll() then
		sfx(0)
		self.ground = false
		path[1].item = self
		add(inventory, self)

		reset_level_steps()

		path[1].s = current_step_count
		
		for i in all(inventory) do
			if(i.rope) then
				paint_walls()
				break
			end
		end
	end
end

function bridge:unhandle()
	del(inventory, self)
	self.ground = true
end

dog = object:new()
dog.sprite = 6
dog.mover = true

function dog:handle()
	if not debug and self:coll() then
		die()
	elseif self.ground and moved and not pt and self:same_level() then
		self:move()
	end
end

function dog:move()
	if check_enemy_move(self.x + self.xdirection - level.mapx, self.y - level.mapy) then
		self.x += self.xdirection
	else
		self.xdirection = self.xdirection * -1
		self.x += self.xdirection
	end
end

function dog:unmove()
	if check_enemy_move(self.x + self.xdirection * -1 - level.mapx, self.y - level.mapy) then
		self.x += self.xdirection * -1
	else
		self.xdirection = self.xdirection * -1
		self.x += self.xdirection * -1
	end
end

function dog:reset()
	self.x = self.originx
	self.y = self.originy
	self.xdirection = self.oxdirection
end

function dog:level_complete()
	self.ground = false
end

function check_enemy_move(nextx, nexty)
	return not (nextx < 0 or nextx > playablex or nexty < 0 or nexty > playabley or fget(mget(nextx + level.mapx, nexty + level.mapy), 0))
end

rope = object:new()
rope.sprite = 37
rope.rope = true

function rope:handle()
	if self:coll() then
		sfx(0)
		self.ground = false
		path[1].item = self
		add(inventory, self)

		paint_walls()
	end
end

function rope:unhandle()
	del(inventory, self)
	self.ground = true

	local has_rope = false
	for i in all(inventory) do
		if i.rope then
			has_rope = true
			break
		end
	end

	unpaint_walls()
end

cave = object:new()
cave.sprite = 76
cave.spawned = false

function cave:handle()
	if not self.spawned and self:same_row() then
		self.spawned = true
		local xdir = px > self.x - level.mapx and 1 or -1
		local boulder = boulder:new("boulder", self.x, self.y)
		boulder.xdirection = xdir
		boulder.cave = self
		add(stuff, boulder)
	end
end

function cave:reset()
	self.spawned = false
end

boulder = object:new()
boulder.sprite = 7
boulder.mover = true
boulder.just_spawned = true

function boulder:handle()
	if not debug and self:coll() then
		die()
	elseif self.ground and moved and not pt and self:same_level() then
		self:move()
	end
end

function boulder:move()
	if self.just_spawned then
		self.just_spawned = false
	elseif check_enemy_move(self.x + self.xdirection - level.mapx, self.y - level.mapy) then
		self.x += self.xdirection
	else
		self.cave.spawned = false
		del(stuff, self)
	end
end

function boulder:unmove()
	if self.x == self.cave.x then
		self.cave.spawned = false
		del(stuff, self)
	elseif check_enemy_move(self.x + self.xdirection * -1 - level.mapx, self.y - level.mapy) then
		self.x += self.xdirection * -1
	end
end

function boulder:reset()
	del(stuff, self)
end

boat = object:new()

function boat:handle()
	if self:coll() then
		psp = 8
		boating = true
		self.ground = false
		update_lava_gates()
	end
end

lavagate = object:new()

function lavagate:handle()
	if not pt and self:coll() then
		pt = true
		change_map()
	end
end

lavamailbox = object:new()
lavamailbox.sprite = 9

function lavamailbox:handle()
	if self.sprite == 9 and self:coll() then
		local comp = false

		for i in all(inventory) do
			if(i.deliverable) then
				del(inventory, i)
				coins += 1
				comp = true
			end
		end

		if comp then
			sfx(1)
			psp = 1
			boating = false
			self.sprite = 10
			level.completed = true
			store_level_completion()
			store_level_completion_impl(playablex, 0)
			store_level_completion_impl(playablex, playabley)
			store_level_completion_impl(playablex, playabley * 2)
			current_step_count = -1
			level.grid = build_grid(level.mapx, level.mapy, level)
			level.grass = 0
		end
	end
end

ice = object:new()
ice.sprite = 80

function ice:handle()
	if self:coll() then
		sliding = true
	end
end

rock = object:new()
rock.sprite = 40
rock.pushable = true

function rock:handle()
	if self.pushing then
		pq("pushed", self.x, self.y, self.pushingx, self.pushingy)
		path[2].pushed = self
		path[2].pushx = self.x
		path[2].pushy = self.y
		self.pushing = false
		self.x = self.pushingx
		self.y = self.pushingy
	end
end

function rock:unpush()
	pq("rock unpush", path[1].pushx, path[1].pushy)
	self.x = path[1].pushx
	self.y = path[1].pushy
end
