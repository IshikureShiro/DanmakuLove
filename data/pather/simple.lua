local pather = require "game.bullet.pather"

return pather:newData{
	vis = pather:newVis{
		images = {
			love.graphics.newImage("res/pathertip.png"),
			love.graphics.newImage("res/road2.png"),
			love.graphics.newImage("res/pathertip2.png")
		},
		startlen = 1,
		taillen = 1,
		width = 16
	}
}