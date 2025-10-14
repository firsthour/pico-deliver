--https://www.lexaloffle.com/bbs/?tid=141946

object = {
	x,
	y,
	sprite,
	ground = true,
	deliverable = false
}

function object:new(x, y, sprite)
	local obj = { x = x, y = y, sprite = sprite }
	return setmetatable(obj, {__index = self})
end

function object:draw()
	if self.ground and self:same_level() then
		spr(self.sprite, (self.x - level.mapx) * size, (self.y - level.mapy) * size)
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

envelope = object:new()
envelope.sprite = 32
envelope.deliverable = true

function envelope:handle()
	if(self:coll()) then
		sfx(0)
		self.ground = false
		path[1].item = self
		add(inventory, self)
		coins += 1

		reset_level_steps()

		path[1].s = current_step_count
	end
end

function envelope:unhandle()
	del(inventory, self)
	self.ground = true
	coins -= 1
end

mailbox = object:new()
mailbox.sprite = 33

function mailbox:handle()
	if(self.sprite == 33 and self:coll()) then
		for i in all(inventory) do
			if(i.deliverable) then
				sfx(1)
				del(inventory, i)
				self.sprite = 34
				level.completed = true
				store_level_completion()
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

	if(not pt and self:coll()) then
		pt = true
		change_map()
	end
end

food = object:new()

function food:handle()
	if(self:coll()) then
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
