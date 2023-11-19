local bman 		= require "game.bulletManager"
local boss		= require "game.boss"

local en_s		= require "data.enemy.simple"
local bu_c		= require "data.bullet.circle"

local attack_1 = boss:makeTimeline(function (bo, timeline)
	print("attack")
	timeline:delay(.1)
end)

local spell_1 =  boss:makeTimeline(function (bo, timeline)
	print("spell")
	timeline:delay(.1)
end)

return boss:define(en_s, {
	{
		{ id = "a1", health = 400, type = 0, timeline = attack_1 },
		{ id = "s1", health = 600, type = 1, timeline = spell_1, }
	}
})