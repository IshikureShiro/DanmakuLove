local laser		= require "game.bullet.laser"
local pather	= require "game.bullet.pather"

return laser:newData{
	patherdata = pather:newData{
		vis = pather:newVis{
			images = {
				love.graphics.newImage("res/road2.png"),
			},
			width = 16
		}
	}
}