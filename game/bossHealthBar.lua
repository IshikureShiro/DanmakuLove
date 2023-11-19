local bar_height = 5

---@class Boss.Health.Bar
---@field last Boss.Stage
local BossHealthBar = {
	boss = nil,		---@type Boss
	x = 0.0,
	y = 0.0,
	width = 100.0,
	total = 0.0,
}

local function _getHealthWeight(ht)
	if ht == 1 then
		return .2
	end
	return 1.0
end

function BossHealthBar:draw()
	love.graphics.rectangle("fill", self.x, self.y, self.width, bar_height + 1)
	local stage = self.boss:getCurrentStage()
	if not stage then
		return
	end
	if stage ~= self.last then
		self.last = stage
		self.total = 0.0
		for _, part in pairs(stage.parts) do
			self.total = self.total + part.health * _getHealthWeight(part.type)
		end
	end
	local cwidth = 0
	local widthpercent = self.width / self.total
	for i = #stage.parts, 1, -1 do
		local part = stage.parts[i]
		local partwidth = part.currentHealth * widthpercent * _getHealthWeight(part.type)
		local flooredwidth = math.floor(partwidth)
		local pwidth = cwidth
		cwidth = cwidth + flooredwidth

		if part.type == 0 then
			love.graphics.setColor(1, 0, 0)
		else
			love.graphics.setColor(.5, .5, .5)
		end
		love.graphics.rectangle("fill", self.x + pwidth, self.y, flooredwidth, bar_height)

		love.graphics.setColor(1, 1, 1)
	end
end

return {
	---@param b Boss
	---@param x? number
	---@param y? number
	---@param width? number
	---@return Boss.Health.Bar
	bar = function(b, x, y, width)
		return setmetatable({
			boss = b,
			x = x or 0.0,
			y = y or 0.0,
			width = width or 100.0
		}, { __index = BossHealthBar })
	end
}