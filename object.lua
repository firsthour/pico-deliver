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
	pushable = false,
	slidex = 0,
	slidey = 0,
	ice = false,
	gate = false,
	warp = false,
	rock = false
}

function object:new(type, x, y, sprite)
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
gate.gate = true
gate.sprite = 20
gate.open = false
gate.lock_behind = false
gate.collided = false

function gate:handle()
	if level.completed and not self.open and not self.lock_behind then
		mset(self.x, self.y, floor_sprite)
		self.open = true
		self.sprite = open_gate_sprite
	end

	if moved and self.lock_behind and self.collided then
		self.collided = false
		self.open = false
		self.sprite = 11
	end

	if not pt and self:coll() then
		pt = true
		change_map()
		self.collided = true
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
shop.show_price = true
shop.flashing = false
shop.flash_count = 0
shop.standing = false
shop.price = 0
shop.item = nil

function shop:draw()
	if self.ground and self:same_level() then
		--draw object to sell
		spr(self.item.sprite, (self.x - level.mapx) * size, (self.y - level.mapy) * size)

		local x = (self.x - level.mapx) * size
		local y = (self.y - level.mapy) * size + 2

		if self.flashing and tick % shop_flash_tick == 0 then
			self.show_price = not self.show_price
			self.flash_count += 1
			if self.flash_count == 8 then
				self.flashing = false
				self.show_price = true
				flash_coins = false
				show_coins = true
			end
		end

		if self.show_price then
			print(self.price, x, y + size - 1, 0)
			print("♪", x + 3, y + size - 1, 0)
		end
	end
end

function shop:handle()
	if self:coll() then
		if coins >= self.price then	
			sfx(0)
			self.ground = false
			add(inventory, self.item)
			coins -= self.price
			path[1].item = self
			for s in all(stuff) do
				if s.gate and not s.open and s.lock_behind and s:same_level() then
					s.open = true
					s.sprite = 21
				end
			end
		elseif not self.flashing and not self.standing then
			sfx(2)
			self.flashing = true
			self.flash_count = 0
			self.standing = true
			flash_coins = true
			flash_coin_count = 0
		end
	else
		self.standing = false
	end
end

function shop:unhandle()
	del(inventory, self.item)
	self.ground = true
	coins += self.price
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
		if(moved) self:move()
		death_flag = true
	elseif self.ground and moved and not pt then
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
	local blocked = nextx < 0 or nextx > playablex or nexty < 0 or nexty > playabley or fget(mget(nextx + level.mapx, nexty + level.mapy), 0)
	if(blocked) return false

	for s in all(stuff) do
		if s.ground and s.pushable and s.x == nextx + level.mapx and s.y == nexty + level.mapy then
			return false
		end
	end

	return true
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
		--die()
		--self:move()
		death_flag = true
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
		sfx(3)
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
ice.ice = true

function ice:handle()
	if not booting and moved and self:coll() then
		for i in all(inventory) do
			if(i.type == "boot") then
				i.flash = true
				booting = true
				break
			end
		end

		if not booting then
			sliding = true
			if not ice_sfx then
				sfx(5)
				ice_sfx = true
			end
		end
	end
end

rock = object:new()
rock.sprite = 40
rock.pushable = true
rock.rock = true

function rock:handle()
	if self.slidex != 0 or self.slidey != 0 then
		if(tick % rock_slide_tick != 0) return

		self.x += self.slidex
		self.y += self.slidey

		local blocked = false
		local loc = mget(self.x, self.y)
		if loc != 80 then
			blocked = true
		else
			for s in all(stuff) do
				if s.ground and s.pushable and s.x == self.x + self.slidex and s.y == self.y + self.slidey then
					blocked = true
					break
				end
			end

			if not blocked then
				local counter = level.grid[self.x + self.slidex - level.mapx + 1][self.y + self.slidey - level.mapy + 1].count
				if(counter == max) blocked = true
			end
		end

		if blocked then
			self.slidex = 0
			self.slidey = 0
		end
	end

	if self.pushing then
		path[2].pushed = self
		path[2].pushx = self.x
		path[2].pushy = self.y
		self.pushing = false
		self.x = self.pushingx
		self.y = self.pushingy
		sfx(4)

		local loc = mget(self.x, self.y)
		if loc == 80 then
			self.slidex = self.x - path[2].pushx
			self.slidey = self.y - path[2].pushy
		end
	end
end

function rock:unpush()
	self.x = path[1].pushx
	self.y = path[1].pushy
end

boot = object:new()
boot.sprite = 41

function boot:handle()
	if self:coll() then
		sfx(0)
		self.ground = false
		path[1].item = self
		add(inventory, self)

		reset_level_steps()

		path[1].s = current_step_count
	end
end

function boot:unhandle()
	del(inventory, self)
	self.ground = true
end

banana = object:new()
banana.sprite = 84

function banana:handle()
	if self:coll() then
		sfx(0)
		self.ground = false
		path[1].item = self
		reset_level_steps()
		path[1].s = current_step_count
	end
end

function banana:unhandle()
	self.ground = true
	current_step_count -= 1
end

disappearing_block = object:new()
disappearing_block.sprite = 64

function disappearing_block:handle()
	if self.ground and level.completed and self.sprite == 64 then
		self.ground = false
		mset(self.x, self.y, floor_sprite)
		level.grid = build_grid(level.mapx, level.mapy, level)
		level.grass = 0
	end
end

warp = object:new()
warp.warp = true

function warp:handle()
	if not warping and self:coll() then

		for s in all(stuff) do
			if s:same_level() and s.warp and px != s.x - level.mapx and py != s.y - level.mapy then
				local rock_block = false
				for s2 in all(stuff) do
					if s2.rock and s2.x == s.x and s2.y == s.y then
						rock_block = true
					end
				end

				if not rock_block then
					sfx(37)
					warping = true
					px = s.x - level.mapx
					py = s.y - level.mapy
					level.grid = build_grid(level.mapx, level.mapy, level)
					grow_grass_impl(level.completed and 50 or current_step_count)
					break
				end
			end
		end
	end
end