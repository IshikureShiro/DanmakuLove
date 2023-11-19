local chdata = require "game.character"
local bulletData = require "game.bullet.data"
local bulletImage = require "game.bullet.imageVis"
local circleVis = require "game.bullet.circleVis"

return chdata:create{
	bullet = bulletData:new{
		layer = 0,
		health = 1,
		vis = circleVis,
		damage = 0,
		onCollide = function (self, other)
			return false
		end,
		playerOwned = true,
	},
	speed = 200,
	focusedSpeed = 100
}