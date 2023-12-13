local action	= require "lib.event.action"
local bman 		= require "game.bulletManager"
local text		= require "game.textManager"
local boss		= require "game.boss"

local en_s		= require "data.enemy.simple"
local bu_c		= require "data.bullet.circle"
local bu_inc	= require "data.bullet.invisiblenocollide"

local pi_p		= require "data.pickup.point"

local enemytl = bman:makeTLData(en_s, function (timeline, b)
	bman:addDrops(b, pi_p, 40)
	local done = bman:followCurve(b, -100, 100, -100, 100, -200, 100)

	timeline:delay(Game:secsToFrames(1))

	bman:fan(b.x, b.y, 8, nil, bman:makeTLData(bu_c, function (_timeline, _b)
	end), nil, 16)

	return true
end)

--- the actual level timeline
return Action(function (leveltl)
	text:addText("ayooo what is uuup", {
		x = 50,
		y = 50,
		font = text.fonts.eb_garamond_ita[30],
		game = true
	}):move(20, 0)

	-- leveltl:delay(.1)
	-- leveltl:delay(Game:secsToFrames(1))

	-- for i = 1, 3 do
	-- 	bman:runTL(enemytl, Game.width + 50, -50 + (30 * i))
	-- 	leveltl:delay(50)
	-- end

	-- leveltl:delay(1)

	-- local e = boss:spawn(require "data.timeline.stage.01.midboss", function (b)
	-- 	b:moveInstant(-50, 100)
	-- 	b:moveToLerp(Game.width * .5, 100)
	-- end)
	-- local hb = require "game.bossHealthBar"
	-- local hbi = hb.bar(e)
	-- local reg = {}
	-- e.bullet.events.draw:register(reg, function (...)
	-- 	local ok, err = pcall(function (...)
	-- 		hbi:draw()
	-- 	end)
	-- 	if not ok then
	-- 		print("err:", err)
	-- 	end
	-- end)
	-- e:start()

	-- local test = bman:makeTLData(bu_c, function (timeline, b)
	-- 	return true
	-- end)
	-- leveltl:delay(1)
	-- while true do
	-- 	bman:fan(200, 200, 8, 0, test)
	-- 	leveltl:delay(.05)
	-- end
	do
		-- return
	end
	

	SetBullet(bu_c)
	while true do
		for i in Loop(1, 1) do
			Cirlce((20 * i) + 70, 70, Player, 13, function (tl, tl_i)
				Stack(5, 40, 20, function (s_tl, s_tl_i)
					Spawn(bu_c)
				end, { ftb = true})
			end, { delay = 2, ccw = false })

			Delay(3)
		end

		DelaySecs(2)
    end
end)