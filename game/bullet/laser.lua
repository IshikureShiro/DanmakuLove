local bullet = require "game.bullet"
local bdata  = require "game.bullet.data"
local invis  = require "data.bullet.invis"
local pather = require "game.bullet.pather"

---@class Laser.Data : BulletData
local LaserData = setmetatable({
	patherdata = nil,	---@type PatherData
	onCollide = function (_, _)
		
	end
}, { __index = bdata })

---@param b Laser
function LaserData:apply(b)
	bdata.apply(self, b)
	self.patherdata:apply(b.pather)
end

---@class Laser : Bullet
---@field data? Laser.Data
local Laser = setmetatable({
	length		= 100.0,
	point_a 	= nil,	---@type Bullet
	point_b 	= nil,	---@type Bullet
	pather		= nil,	---@type Pather
}, { __index = bullet })

function LaserData:makeBullet(id)
	local ins = Laser:new{
		id = id
	}
	ins.pather.id = id
	self:apply(ins)
	return ins
end

---@param d Laser.Data
---@return Laser.Data
function Laser:newData(d)
	return setmetatable(d or {}, { __index = LaserData })
end

function Laser:new(b)
	b = bullet.new(self, b)--[[@as Laser]]
	b.point_a = bullet:new{}
	invis:apply(b.point_a)
	b.point_b = bullet:new{}
	invis:apply(b.point_b)

	b.pather = pather:create()
	table.insert(b.pather.bullets, b.point_a)
	table.insert(b.pather.bullets, b.point_b)
	return b
end

function Laser:getGrazeType()
	return 2
end

function Laser:setLength(l)
	self.length = l
	self:recreateCollider()
end

function Laser:setScale(s)
	self.scale = s
	self:recreateCollider()
end

function Laser:recreateCollider()
	if self.collider then
		Game.colWorld:remove(self.collider)
	end
	self:makeCollider()
end

function Laser:makeCollider()
	self.collider = Game.colWorld:rectangle(self.x, self.y, self.length, self.size * self.scale)
	self.collider:setRotation(self.direction, self.x, self.y)
	self.collider.bullet = self
end

function Laser:rotate(r)
	bullet.rotate(self, r)
	self.collider:setRotation(self.direction, self.x, self.y)
end

function Laser:moveTo(x, y)
	self.x, self.y = x, y
	self.point_a.x, self.point_a.y = x, y
	local rot = math.pi * 2 * math.deg(self.direction) / 360
	local tx = math.cos(rot) * self.length
	local ty = math.sin(rot) * self.length
	self.point_b.x, self.point_b.y = x +tx, y + ty

	self.collider:setRotation(0, x, y)
	self.collider:moveTo(x + (self.length * .5), y)
	self.collider:setRotation(self.direction, self.x, self.y)
end

function Laser:update(dt)
	bullet.update(self, dt)
	self.pather.bezier.width = self.data.patherdata.vis.width * self.scale
	self.pather:updateMesh()
end

function Laser:draw()
	self.pather:updateMesh()
	if self.scale > 0 then
		self.pather:draw()
	end
	love.graphics.circle("line", self.x, self.y, 2)
	self.collider:draw("line")
end

return Laser