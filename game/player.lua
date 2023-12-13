local bman = require "game.bulletManager"
local action = require "lib.event.action"

local chara = require "data.character.simple"


---@class Player
Player = {
	data = chara,
	body		= bman:makeBullet(chara.bullet),
	grazeZone	= bman:makeBullet(chara.bullet),
	magnetZone	= bman:makeBullet(chara.bullet),
	---@param self Player
	attack = function (self)
	end,
	---@param self Player
	bombF = function (self)
		self.attackData.bombCD = 1
	end,
	attackData = {
		lastShot = 0.0,
		bombCD = 0.0,
	},
	focused = false,
	lives 	= 3,
	bombs 	= 3,
	power 	= 0,
	points 	= 0,
	graze 	= 0,
	grazeCD = {}		---@type table<integer, number>
}

local function _getStartPos()
	return Game.width * .5, Game.height + 50
end

local function _die()
	action:fromFunc(function (act)
		Player.body:activate(false)
		Player.body.velocity = 0
		Player.lives = Player.lives - 1

		-- TODO: check for bomb input
		act:delay(.2)

		Player:spawn()
		Player.body:activate(true)
	end):run()
end

---@param data? CharacterData
function Player:init(data)
	data = data or chara
	self:setData(data)

	self.grazeZone.g = 1
	self.magnetZone.b = 1
	self:setScale(1)
end

function Player:setScale(s)
	self.body:setScale(s)
	self.grazeZone:setScale(s)
	self.magnetZone:setScale(s)
end

function Player:bomb()
	if self.bombs > 0 and self.attackData.bombCD <= 0 then
		self.bombs = self.bombs - 1
		self:bombF()
	end
end

function Player:spawn()
	Player:setScale(1)
	self.body.health = 1 --TODO: uuh yeah
	self.body:moveTo(_getStartPos())
	self.body.velocity = .6
	self.body:activate(false)

	action:fromFunc(function (act)
		local done = bman:followCurve(self.body, 0, -50, 0, -90)
		repeat
			act:delay(Game.ticktime)
		until done()
		self.body.velocity = 1
		act:delay(.5)
		self.body:activate(true)
	end):run()
end

function Player:draw()
	love.graphics.print(("lives:  %s"):format(self.lives),  310, 10)
	love.graphics.print(("bombs:  %s"):format(self.bombs),  310, 30)
	love.graphics.print(("points: %s"):format(self.points), 310, 50)
	love.graphics.print(("graze:  %s"):format(self.graze),  310, 70)

	self.body:draw()
	self.grazeZone:draw()
	self.magnetZone:draw()
end

function Player:move(dx, dy)
	local x, y = self.body.x + dx, self.body.y + dy
	self.body:moveTo(x, y)
end

---@param d CharacterData
function Player:setData(d)
	self.data = d
	if self.body then
		Game.colWorld:remove(self.body.collider)
	end
	self.body = bman:makeBullet(d.bullet)
	self.body.speed = d.speed
	self.body.size = d.size
	self.grazeZone.size = d.grazeSize
	self.magnetZone.size = d.magnetSize

	Player.body.events.damage:register({}, function (...)
	end)
	Player.body.events.destroy:unregister(Player.body)
	Player.body.events.update:unregister(Player.body)
	Player.body.events.destroy:register({}, _die)

	Player.grazeZone.health = -1
	Player.grazeZone.damage = 0
	if Player.grazeZone.events.destroy:isRegistered(Player.grazeZone) then
		Player.grazeZone.events.destroy:unregister(Player.grazeZone)
	end

	Player.magnetZone.health = -1
	Player.magnetZone.damage = 0
	if Player.magnetZone.events.destroy:isRegistered(Player.magnetZone) then
		Player.magnetZone.events.destroy:unregister(Player.magnetZone)
	end
end

function Player:update(dt)
	self.attackData.lastShot 	= self.attackData.lastShot + dt
	self.attackData.bombCD		= self.attackData.bombCD - dt

	if love.keyboard.isDown("q") then
	end

	self.focused = love.keyboard.isDown("lshift")

	local mspd = self.focused and self.data.focusedSpeed or self.data.speed
	mspd = mspd * self.body.velocity * dt

	if love.keyboard.isDown("left") then
		Player:move(-mspd, 0)
	elseif love.keyboard.isDown("right") then
		Player:move( mspd, 0)
	end

	if love.keyboard.isDown("down") then
		Player:move(0,  mspd)
	elseif love.keyboard.isDown("up") then
		Player:move(0, -mspd)
	end

	if love.keyboard.isDown("y") then
		Player:attack()
	end
	if love.keyboard.isDown("x") then
		Player:bomb()
	end

	local x, y = self.body.x, self.body.y
	self.grazeZone:moveTo(x, y)
	self.magnetZone:moveTo(x, y)
	self.body.events.update(dt)

	local picks = Game.colWorld:collisions(self.magnetZone.collider)
	for shape, _ in pairs(picks) do
---@diagnostic disable-next-line: undefined-field
		if shape.bullet and shape.bullet.velocity > 0 and shape.bullet.data.onPickup then
			bman:abosrb(shape.bullet)
		end
	end

	local l_graze_cd = .2
	local graze = Game.colWorld:collisions(self.grazeZone.collider)
	for shape, _ in pairs(graze) do
		if shape.bullet
		and not shape.bullet.playerOwned
		and not self.grazeCD[shape.bullet.id] then
			self.graze = self.graze + 1
			self.grazeCD[shape.bullet.id] = (shape.bullet:getGrazeType() == 1) and -1 or l_graze_cd
		end
	end
	for key, value in pairs(self.grazeCD) do
		if value ~= -1 then
			local nval = value - dt
			if nval <= 0 then
				self.grazeCD[key] = nil
			else
				self.grazeCD[key] = nval
			end
		end
	end
end

local sb = require "data.bullet.simple"
local se = require "data.enemy.simple"
local invis = require "data.bullet.invis"
Player.attack = function(_)
	if Player.attackData.lastShot <= .1 then
		return
	end

	Player.attackData.lastShot = 0
	bman:fan(Player.body.x, Player.body.y, 3, (-.5 * math.pi), bman:makeTLData(sb, function (timeline, b)
		b.velocity = 4
	end), 10, 0, true)
end