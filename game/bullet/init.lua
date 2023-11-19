local event = require "lib.event"
local action = require "lib.event.action"

local log = Logger:spec("Bullet")

---@class BulletEvents
---@field destroy 	Event
---@field collide 	Event
---@field damage  	Event
---@field move		Event
---@field rotate	Event
---@field update	Event
---@field draw		Event

---@class Bullet
local Bullet = {
	id = -1,
	layer = 2,
	---@type BulletData
	data = nil,
	health = -1,
	x = 0.0,
	y = 0.0,
	direction = 0.0,
	velocity = 1.0,
	playerOwned = false,
	---@type Action
	timeline = nil,
	speed = 200.0,
	size = 2,
	scale = 1,
	damage = 1,
	checkCols = true,
	inactiveStack = nil,
	t = 0.0,
	r = 1,
	g = 0,
	b = 0,
	a = 1,
	---@type BulletEvents
	events = nil,
	---@type HardonCollider.Shape
	collider = nil,
	---@type table<Bullet, number>
	collisions = nil,
	pulseTime = -1.0
}

---@param b Bullet
---@return Bullet
function Bullet:new(b)
	b = b or {}
	b.collisions = {}
	b.inactiveStack = {}
	b.events = {
		destroy = event:new(),
		collide = event:new(),
		damage  = event:new(),
		move	= event:new(),
		rotate	= event:new(),
		update	= event:new(),
		draw	= event:new(),
	}
	b.events.destroy:register_wrapped(b, self.onDestroy)
	b.events.collide:register_wrapped(b, self.onCollide)
	b.events.damage:register_wrapped(b, self.onDamage)
	return setmetatable(b, { __index = self })
end

function Bullet:getGrazeType()
	return 1
end

function Bullet:activate(s)
	if s then
		table.remove(self.inactiveStack, #self.inactiveStack)
	else
		table.insert(self.inactiveStack, true)
	end
end

function Bullet:pulse()
	self.pulseTime = 0.0
end

function Bullet:draw()
	DEEP[self.layer]:enqueue(self.id, function ()
		self.data.vis:draw(self)
		self.events.draw()
		-- self.collider:draw("line")
	end)
	-- love.graphics.circle("line", self.x, self.y, self.size * self.scale)
end

function Bullet:update(dt)
	self.t = self.t + dt
	if self.pulseTime >= 0 then
		self.pulseTime = self.pulseTime + dt
	end

	if self.timeline then
		local timelineValid = self.timeline:update(dt)

		if not timelineValid then
			self.timeline = nil
		else
			self:moveForward(self.velocity * self.speed * dt)
			self.events.update(dt)
			if self.checkCols then
				self:checkCollisions()
			end
		end
	end
end

function Bullet:moveTo(x, y)
	self.x = x
	self.y = y
	self.collider:moveTo(self.x, self.y)
end

function Bullet:isActive()
	return self.scale > 0 and #self.inactiveStack == 0
end

---@param dist number
function Bullet:moveForward(dist)
	local rot = math.pi * 2 * math.deg(self.direction) / 360
	local tx = math.cos(rot) * dist
	local ty = math.sin(rot) * dist

	self:moveTo(self.x + tx, self.y + ty)
	self.events.move(tx, ty)
end

function Bullet:setScale(s)
	self.scale = s
	self:makeCollider()
end

function Bullet:setRotation(r)
	self:rotate(r - self.direction)
end

function Bullet:rotate(r)
	self.direction = self.direction + r
	self.events.rotate(r)
end

function Bullet:rotateRelative(px, py, r)
	-- Calculate the sine and cosine of the angle
	local cosA = math.cos(r)
	local sinA = math.sin(r)

	-- Translate the point to the origin (pivot point)
	local translatedX = self.x - px
	local translatedY = self.y - py

	-- Perform the rotation
	local rotatedX = cosA * translatedX - sinA * translatedY
	local rotatedY = sinA * translatedX + cosA * translatedY

	-- Translate the point back to its original position
	rotatedX = rotatedX + px
	rotatedY = rotatedY + py
	self:moveTo(rotatedX, rotatedY)
	self:rotate(r)
end

function Bullet:onDestroy()
	Game.colWorld:remove(self.collider)
	if self.timeline and self.timeline:isValid() then
		self.timeline:cancel()
	end
end

---@param other Bullet
function Bullet:onCollide(other)
	if other.playerOwned == self.playerOwned then
		return
	end
	if not self:isActive() or not other:isActive() then
		return
	end
	if self.damage > 0 and other.health > 0 then
		other.events.damage(self.damage, self)
	end
end

---@param amt number
---@param src Bullet
function Bullet:onDamage(amt, src)
	self.health = self.health - amt
	if self.health <= 0 then
		self:destroy()
	end
end

function Bullet:makeCollider()
	if self.collider then
		Game.colWorld:remove(self.collider)
	end
	self.collider = Game.colWorld:circle(0, 0, self.size * self.scale)
	self.collider.bullet = self
end

function Bullet:destroy(...)
	local bulletManager = require "game.bulletManager"
	bulletManager:destroyBullet(self, ...)
end

function Bullet:getCollisions()
	return Game.colWorld:collisions(self.collider)
end

function Bullet:collideWith(other)
	local a_b = self.events.collide(self, other)
	local b_a = self.events.collide(other, self)
	return a_b or b_a
end

function Bullet:checkCollisions()
	for shape, _ in pairs(self:getCollisions()) do
		if shape.bullet and self:collideWith(shape.bullet) then
			self:destroy()
		end
	end
end

---@param b Bullet
---@param stopself? boolean
function Bullet:connect(b, stopself)
	self:followMovement(b, stopself)
	self:followRotation(b)
end

---@param b Bullet
---@param stopself? boolean
function Bullet:followMovement(b, stopself)
	local mreg = {}
	local ov = self.velocity
	if stopself then
		self.velocity = 0
	end
	local function _unreg()
		b.events.move:unregister(mreg)
		b.events.destroy:unregister(mreg)
		if stopself then
			self.velocity = ov
		end
		_unreg = function () end
	end
	self.events.destroy:register(mreg, function (...)
		_unreg()
	end)
	b.events.move:register(mreg, function (x, y)
		self:moveTo(self.x + x, self.y + y)
	end)
	b.events.destroy:register(mreg, function (...)
		_unreg()
	end)
end

---@param b Bullet
function Bullet:followRotation(b)
	local rreg = {}
	local function _unreg()
		b.events.rotate:unregister(rreg)
		b.events.destroy:unregister(rreg)
		_unreg = function() end
	end
	self.events.destroy:register(rreg, function (...)
		_unreg()
	end)
	b.events.rotate:register(rreg, function (r)
		self:rotateRelative(b.x, b.y, r)
	end)
	b.events.destroy:register(rreg, function (...)
		_unreg()
	end)
end

return Bullet