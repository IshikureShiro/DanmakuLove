local bvis = require "game.bullet.vis"

---@class CircleVis : BulletVis
local CircleVis = setmetatable({
}, { __index = bvis })

---@param b Bullet
function CircleVis:draw(b)
	love.graphics.setColor(b.r, b.g, b.b, b.a)
	love.graphics.circle("line", b.x, b.y, b.size * b.scale)
	love.graphics.setColor(1, 1, 1)
end

return CircleVis