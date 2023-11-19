local pickup = require "game.pickup"
local imvis = require "game.bullet.imageVis"

return pickup:newData{
	vis = imvis:new{
		image = love.graphics.newImage("res/wallclingph.png")
	},
	size = 5,
	onPickup = function ()
		Player.points = Player.points + 1
	end
}