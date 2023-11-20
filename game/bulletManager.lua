local action = require "lib.event.action"
local bullet = require "game.bullet"
local pather = require "game.bullet.pather"

local default_pickup_spread = 30

---@class BulletManager
local BulletManager = {
	bullets = {},	---@type Bullet[]
	pathers = {},	---@type Pather[]
	total = 0,
}

---@class BulletTimelineData
---@field data BulletData
---@field timeline fun(timeline:Action, b:Bullet):boolean?

---@param b Bullet
function BulletManager:abosrb(b)
	if b.timeline and b.timeline:isValid() then
		b.timeline:cancel()
	end
	b.velocity = 0
	b.timeline = self:makeTL(b, function (timeline, _)
		local t = 0
		local spd = 0.9 + (love.math.random() * .2)
		repeat
			t = t + (0.01 * spd)
			b:moveTo(
				math.lerp(b.x, Player.body.x, t),
				math.lerp(b.y, Player.body.y, t)
			)
			timeline:delay()
		until t >= 1
		return true
	end)
end

---@param spread number
---@return fun(timeline:Action, b:Bullet):boolean?
function BulletManager:makePickupTL(spread)
	local function _rand()
		return ((love.math.random() - .5) * 2) * spread
	end
	local x, y = _rand(), _rand() - spread
	return function (tl, b)
		x = x + b.x
		y = y + b.y
		local t = 0
		b.velocity = 0
		b.direction = math.rad(90)
		b.speed = 1.5
		repeat
			t = t + 0.1
			b:moveTo(
				math.lerp(b.x, x, t),
				math.lerp(b.y, y, t)
			)
			tl:delay(Game.ticktime)
		until t >= .9
		t = .1
		repeat
			t = t + 0.01
			b.velocity = t
			tl:delay(Game.ticktime)
		until t >= 1
		return true
	end
end

---@param b Bullet
---@param pckp Pickup.Data
---@param spread? number
function BulletManager:addDrop(b, pckp, spread)
	spread = spread or default_pickup_spread
	b.events.destroy:register({}, function (bound)
		if bound then
			return
		end
		local p = self:spawn(pckp, b.x, b.y, self:makePickupTL(spread))
	end)
end

---@param b Bullet
---@param pckp Pickup.Data
---@param n integer
---@param spread? number
---@return fun() unregister
---@return table reg
function BulletManager:addDrops(b, pckp, n, spread)
	local reg = {}
	spread = spread or default_pickup_spread
	b.events.destroy:register(reg, function (bound)
		if bound then
			return
		end
		for _ = 1, n do
			local p = self:spawn(pckp, b.x, b.y, self:makePickupTL(spread))
		end
	end)
	return function ()
		b.events.destroy:unregister(reg)
	end, reg
end

---@param bdata BulletData
---@param timeline fun(timeline:Action, b:Bullet):boolean?
---@return BulletTimelineData
function BulletManager:makeTLData(bdata, timeline)
	return {
		data = bdata,
		timeline = timeline
	}
end

---@param data BulletData
---@return Bullet
function BulletManager:makeBullet(data)
	local b = data:makeBullet(self.total)
	self.total = self.total + 1
	b:makeCollider()
	return b
end

---@class PatherReg
local PatherReg = {
	pather = nil,	---@type Pather
}

---@param p Pather
---@return PatherReg
function PatherReg:new(p)
	return setmetatable({ pather = p }, { __index = self })
end

---@param b Bullet
function PatherReg:addBullet(b)
	table.insert(self.pather.bullets, b)
	b.checkCols = false
	b.id = self.pather.id
	b.getGrazeType = function (_)
		return 2
	end
	-- self.pather:updateMesh()
end

---@param data PatherData
---@return PatherReg
function BulletManager:makePather(data)
	local p = pather:create()
	p.id = self.total
	self.total = self.total + 1
	data:apply(p)
	table.insert(self.pathers, p)
	return PatherReg:new(p)
end

---@param data Laser.Data
---@param x number
---@param y number
---@param r number
---@param l number
---@param timeline fun(timeline:Action, l:Laser):boolean?
---@param ... unknown
---@return Laser
function BulletManager:laser(data, x, y, r, l, timeline, ...)
	local laser = self:spawn(data, x, y, timeline, ...)--[[@as Laser]]
	laser:setLength(l)
	laser.velocity = 0
	laser:rotate(r)
	return laser
end

---@param data Laser.Data
---@param fromX number
---@param fromY number
---@param toX number
---@param toY number
---@param timeline fun(timeline:Action, l:Laser):boolean?
---@param ... unknown
---@return Laser
function BulletManager:laserFromTo(data, fromX, fromY, toX, toY, timeline, ...)
	local laser = self:spawn(data, fromX, fromY, timeline, ...)--[[@as Laser]]
	local dist = vmath.distance(fromX, fromY, toX, toY)
	laser:setLength(dist)
	laser.velocity = 0
	laser:rotate(math.atan2(toY - fromY, toX - fromX))
	return laser
end

---@param tldata BulletTimelineData
---@param x? number
---@param y? number
function BulletManager:runTL(tldata, x, y, ...)
	self:spawn(tldata.data, x or 0, y or 0, tldata.timeline, ...)
end

---@param b Bullet
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param ... number
---@return fun():boolean isDone
function BulletManager:followCurve(b, x1, y1, x2, y2, ...)
	local reg = {}
---@diagnostic disable-next-line: redundant-parameter
	local curve = love.math.newBezierCurve(0, 0, x1, y1, x2, y2, ...)
	curve:translate(b.x, b.y)
	local deriv = curve:getDerivative()
	local t = .0
	local len = .0
	local res = 5
	local tp = {}
	table.insert(tp, {0, b.x, b.y})
	local points = curve:render(res)
	for i = 1, #points - 3, 2 do
		local x = points[i    ]
		local y = points[i + 1]

		local nx = points[i + 2]
		local ny = points[i + 3]
		local curlen = vmath.distance(x, y, nx, ny)
		len = len + curlen
		table.insert(tp, {len, nx, ny})
	end
	local done = function ()
		return not b.events.update:isRegistered(reg)
	end
	local function _eval(_t)
		_t = _t * len
		local last = tp[0]
		local cur = tp[0]
		for _, value in pairs(tp) do
			if value[1] < _t then
				last = value
			else
				cur = value
				break
			end
		end
		_t = _t / cur[1]
		return
			math.lerp(last[2], cur[2], _t),
			math.lerp(last[3], cur[3], _t)
	end
	b.events.update:register(reg, function (dt)
		t = t + (b.speed * b.velocity * dt / len)
		if t >= 1. then
			if not done() then
				b.events.update:unregister(reg)
			end
			return
		end
		local px, py = _eval(t)-- curve:evaluate(t)
		local dx, dy = deriv:evaluate(t)
		local r = math.atan2(dy, dx)
		-- print(px, py, "|", dx, dy, "|", r)
		b:moveTo(px, py)
		b:setRotation(r)
	end)
	return done
end

---@param x number
---@param y number
---@param n integer
---@param direction? number
---@param tldata BulletTimelineData
---@param spread? number bullet spread in degrees
---@param offset? number
---@return Bullet[]
function BulletManager:fan(x, y, n, direction, tldata, spread, offset, ...)
	direction = direction or Player:getDirection(x, y)
	local actualspread = spread and math.rad(spread) or math.rad(360)
	local res = {}

	--- offset is needed when spread < 360
	local spreadstep = actualspread / (n + (spread and 1 or 0))

	for i = 1, n do
		local b = self:spawn(tldata.data, x, y, tldata.timeline, ...)
		b.direction = direction - (actualspread * .5)
		b.direction = b.direction + i * spreadstep
		if offset then
			b:moveForward(offset)
		end
		table.insert(res, b)
	end
	return res
end

---@param b Bullet
---@param tl fun(timeline:Action, b:Bullet):boolean?
---@return Action
function BulletManager:makeTL(b, tl)
	return action:fromFunc(function(act)
		local done = nil
		repeat
			while act.delta > 0 do
				done = done or tl(act, b)
				if done then
					break
				end
				act.delta = act.delta - 1
			end
			act:delay(Game.ticktime)
		until done

		while true do
			act:delay(Game.ticktime)
		end
	end)
end

---@param data BulletData
---@param x number
---@param y number
---@param timeline fun(timeline:Action, b:Bullet):boolean?
---@param player? boolean
---@return Bullet
function BulletManager:spawn(data, x, y, timeline, player)
	local b = self:makeBullet(data)
	b.playerOwned = (b.playerOwned or player) or false
	b:moveTo(x, y)
	self:setTL(b, timeline)
	if data.spawnPulse then
		b:pulse()
	end
	table.insert(self.bullets, b)
	return b
end

---@param b Bullet
---@param tl fun(timeline:Action, b:Bullet):boolean?
function BulletManager:setTL(b, tl)
	b.timeline = self:makeTL(b, tl)
end

---@param b Bullet
function BulletManager:destroyBullet(b, ...)
	b.events.destroy(...)
	local i = table.getIndex(self.bullets, b)
	self.bullets[i] = nil
end

function BulletManager:update(dt)
	for _, b in pairs(self.bullets) do
		b:update(dt)
	end
	for _, p in pairs(self.pathers) do
		p:update(dt)
	end
end

function BulletManager:draw()
	for _, b in pairs(self.bullets) do
		b:draw()
	end
	for _, p in pairs(self.pathers) do
		p:draw()
	end

	love.graphics.print(tostring(#self.bullets), 20, 20)
end

return BulletManager