local bulletData = require "game.bullet.data"
local bulletImage = require "game.bullet.imageVis"

return bulletData:new{
	vis = bulletImage:new{
		image = love.graphics.newImage("res/empty.png")
	},
	damage = 30
}