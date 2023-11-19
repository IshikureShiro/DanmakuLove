local bulletData 	= require "game.bullet.data"
local dualvis 		= require "game.bullet.dualVis"

return bulletData:new{
	vis = dualvis:new(
		love.graphics.newImage("res/bullet/circle_c.png"),
		love.graphics.newImage("res/bullet/circle_w.png")
	),
	damage = 30,
	size = 15,
	scale = .2
}