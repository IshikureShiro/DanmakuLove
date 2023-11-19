---@class BulletData
local BulletData = {
	layer = 2,
	---@type BulletVis
	vis = nil,
	r = 1,
	g = 0,
	b = 0,
	a = 1,
	rotate = true,
	spawnPulse = true,
	health = -1,
	size = 2,
	scale = 1,
	damage = 1,
	playerOwned = false,
	---@type fun(self:Bullet,other:Bullet):boolean
	onCollide = function (self, other)
		return other.health > 0
			and self:isActive()
			and other:isActive()
			and self.damage > 0
			and other.playerOwned ~= self.playerOwned
	end
}

---@param data BulletData
---@return BulletData
function BulletData:new(data)
	return setmetatable(data or {}, { __index = self })
end

---@param b Bullet
function BulletData:apply(b)
	b.data = self
	b.layer = self.layer
	b.r = self.r
	b.g = self.g
	b.b = self.b
	b.a = self.a
	b.health = self.health
	b.size = self.size
	b.scale = self.scale
	b.damage = self.damage
	b.playerOwned = self.playerOwned

	b.events.collide:register({}, self.onCollide)
end

function BulletData:makeBullet(id)
	local ins = require("game.bullet"):new{
		id = id
	}
	self:apply(ins)
	return ins
end

return BulletData