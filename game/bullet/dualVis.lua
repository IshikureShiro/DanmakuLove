local bvis = require "game.bullet.vis"

local pulse_scale = 3.0
local pulse_max = .2

local scale_curve = love.math.newBezierCurve(
	 0, .5,
	.1,  1,
	 1,  0
)
local alpha_curve = love.math.newBezierCurve(
	0,   .7,
	.01, .8,
	1,   1
)

---@class DualVis : BulletVis
local DualVis = setmetatable({
	colorImage = nil,	---@type love.Image
	whiteImage = nil,	---@type love.Image
	width  = 0.0,
	height = 0.0,
}, { __index = bvis })

---@param color love.Image
---@param white love.Image
---@return DualVis
function DualVis:new(color, white)
	return setmetatable({
		colorImage = color,
		whiteImage = white,
		width  = color:getWidth(),
		height = color:getHeight()
	}, { __index = self })
end

---@param b Bullet
function DualVis:draw(b)
	local extra_scale = 0
	local alpha = b.a
	if b.pulseTime > pulse_max then
		b.pulseTime = -1
	elseif b.pulseTime >= 0 then
		local t = math.min(1, (b.pulseTime / pulse_max))
		local t_r = (1 - t)
		extra_scale = scale_curve:evaluate(t_r) * pulse_scale
		alpha = alpha * alpha_curve:evaluate(t)
	end

	local tr = love.math.newTransform(
		b.x,
		b.y,
		b.data.rotate and b.direction or 0,
		b.scale + extra_scale,
		b.scale + extra_scale,
		self.width  * .5,
		self.height * .5
	)

	love.graphics.setColor(b.r, b.g, b.b, alpha)
	love.graphics.draw(self.colorImage, tr)
	love.graphics.setColor(1, 1, 1, alpha)
	love.graphics.draw(self.whiteImage, tr)

	love.graphics.setColor(1, 1, 1)
end

return DualVis