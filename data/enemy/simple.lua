local bulletData = require "game.bullet.data"
local bulletImage = require "game.bullet.imageVis"

return bulletData:new{
	health = 1,
	size = 8,
	scale = 2,
	rotate = false,
	spawnPulse = false,
	vis = bulletImage:new{
		image = love.graphics.newImage("res/enemyplaceholder.png")
	},
	onCollide = function (self, other)
		return false
	end
}