local action	= require "lib.event.action"
local bman 		= require "game.bulletManager"
local text		= require "game.textManager"
local boss		= require "game.boss"

local en_s		= require "data.enemy.simple"
local bu_c		= require "data.bullet.circle"

local pi_p		= require "data.pickup.point"

local enemytl = bman:makeTLData(en_s, function (timeline, b)
	bman:addDrops(b, pi_p, 40)
	local done = bman:followCurve(b, -100, 100, -100, 100, -200, 100)

	timeline:delay(1)

	bman:fan(b.x, b.y, 3, nil, bman:makeTLData(bu_c, function (_timeline, _b)
	end), 50, 16)

	return true
end)

--- the actual level timeline
return action:fromFunc(function (leveltl)
	text:addText("ayooo what is uuup", {
		x = 50,
		y = 50,
		font = text.fonts.eb_garamond_ita[30],
		game = true
	}):move(20, 0)

	leveltl:delay(.1)
	-- leveltl:delay(1)

	-- for i = 1, 3 do
	-- 	bman:runTL(enemytl, Game.width + 50, -50 + (30 * i))
	-- 	leveltl:delay(.5)
	-- end

	-- leveltl:delay(1)

	local e = boss:spawn(require "data.timeline.stage.01.midboss", function (b)
		b:moveInstant(-50, 100)
		b:moveToLerp(Game.width * .5, 100)
	end)
	local hb = require "game.bossHealthBar"
	local hbi = hb.bar(e)
	local reg = {}
	e.bullet.events.draw:register(reg, function (...)
		local ok, err = pcall(function (...)
			hbi:draw()
		end)
		if not ok then
			print("err:", err)
		end
	end)
	e:start()

end)