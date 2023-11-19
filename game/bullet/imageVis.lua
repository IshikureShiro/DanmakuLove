local vis = require "game.bullet.vis"

---@class BulletImage : BulletVis
local BulletImage = setmetatable({
	---@type love.Image
	image = nil,
}, { __index = vis })

---@param b Bullet
function BulletImage:draw(b)
	love.graphics.setColor(b.r, b.g, b.b, b.a)
	local hw, hh = self.image:getWidth() * .5, self.image:getHeight() * .5
	love.graphics.draw(
		self.image,
		b.x,
		b.y,
		b.data.rotate and b.direction or 0,
		b.scale,
		b.scale,
		hw,
		hh
	)
	love.graphics.setColor(1, 1, 1)
end

---@param i BulletImage
---@return BulletImage
function BulletImage:new(i)
	i = i or {}
	i.image = i.image or error("bullet image needs image")
	return setmetatable(i, { __index = self })
end

return BulletImage