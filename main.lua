Logger = require "lib.log"
local bullet = require "game.bullet"
local bulletManager = require "game.bulletManager"

local action 	= require "lib.event.action"
local hc 		= require "lib.hardoncollider"

Funcs = {}
---@diagnostic disable-next-line: lowercase-global
vmath = {}
do
	-- https://love2d.org/wiki/General_math
	-- Returns 'n' rounded to the nearest 'deci'th (defaulting whole numbers).
	function math.round(n, deci)
		deci = 10^(deci or 0)
		return math.floor(n*deci+.5)/deci
	end
	
	function table.getIndex(col, item)
		local fun = type(item) == "function"
		for index, value in pairs(col) do
			if fun and item(value) or item == value then
				return index
			end
		end
		return -1
	end
	
	function table.removeItem(col, item)
		local i = table.getIndex(col, item)
		if i then
			table.remove(col, i)
		end
	end
	
	function Funcs.wrap(t, fun)
		return function (...)
			return fun(t, ...)
		end
	end
	
	---@diagnostic disable-next-line: lowercase-global
	wraptfunc = function(t, fun)
		return t, Funcs.wrap(t, fun)
	end

	---@overload fun(v1:table, v2:table):number
	---@param v1 number|table
	---@param v2 number|table
	---@param xb number
	---@param yb number
	---@return number
	function vmath.distance(v1, v2, xb, yb)
		local dx
		local dy
		if type(v1) == "table" then
			dx = (v2.x or v2[1]) - (v1.x or v1[1])
			dy = (v2.y or v2[2]) - (v1.y or v1[2])
		else
			dx = xb - v1
			dy = yb - v2
		end
		return math.sqrt(dx*dx + dy*dy)
	end

	--[[Imprecise method, which does not guarantee v = v1 when t = 1, due to floating-point arithmetic error. 
	This method is monotonic. This form may be used when the hardware has a native fused multiply-add instruction.]]
	---@param v0 number
	---@param v1 number
	---@param t number
	---@return number
	function math.lerp(v0, v1, t)
		return v0 + t * (v1 - v0);
	end
end
local text = require "game.textManager"
local deep = require "lib.deep"
local deepplayer  		= deep.new()
local deeppickups		= deep.new()
local deeplowBullets	= deep.new()
local deepbullets 		= deep.new()
---@type table<integer, Deep.instance>
DEEP = {
	[-1] = deeppickups,
	[ 0] = deepplayer,
	[ 1] = deeplowBullets,
	[ 2] = deepbullets,
}

local fpsGraph
local memGraph
local dtGraph

Game = {
	scale = 1.,
	screenWidth = 0,
	screenHeight = 0,

	margins = {
		up = 16,
		left = 32,
		bottom = 16
	},

	colWorld = hc.new(50),
	width  = 0,
	height = 0,
	canvas = nil,	---@type love.Canvas
	bounds = {}
}

function Game:setGameSize(w, h)
	self.width = w
	self.height = h
	self.canvas = love.graphics.newCanvas(w, h)

	table.insert(self.bounds, self.colWorld:rectangle(-w, -h * 2, w * 3, h))
	table.insert(self.bounds, self.colWorld:rectangle(-w,  h * 2, w * 3, h))

	table.insert(self.bounds, self.colWorld:rectangle(-w * 2, -h, w, h * 3))
	table.insert(self.bounds, self.colWorld:rectangle( w * 2, -h, w, h * 3))
end

function Game:setGameScale()
	self.screenWidth, self.screenHeight = love.window.getMode()
	self.scale = self.screenHeight / 480.0
end

function Game:update(dt)
	Player:update(dt)
	action.globalUpdate(dt)
	bulletManager:update(dt)
	text:update(dt)

	for _, bound in pairs(self.bounds) do
		for shape, _ in pairs(self.colWorld:collisions(bound)) do
			if shape.bullet ~= Player.body then
				shape.bullet:destroy(true)
			end
		end
	end
end

function Game:draw()
	love.graphics.setCanvas(self.canvas)
	love.graphics.clear()
	love.graphics.push()
	-- love.graphics.translate(450, 450)

	love.graphics.rectangle("line", 0, 0, self.width, self.height)

	love.graphics.setColor(1, 0, 0)
	love.graphics.rectangle("line", -self.width, -self.height, self.width * 3, self.height * 3)
	love.graphics.setColor(1, 1, 1)

	bulletManager:draw()
	Player:draw()

	for i = -1, 2 do
		DEEP[i]:execute()
	end
	text:drawGame()

	love.graphics.pop()
	love.graphics.setCanvas()
end

require "game.player"

---@param x number
---@param y number
---@return number angle angle in radians
function Player:getDirection(x, y)
	return math.atan2(y - self.body.y, x - self.body.x) + math.rad(180)
end


function love.load()
	local debugGraph = require "lib.debugGraph"
	local grh = 400
	fpsGraph = debugGraph:new('fps', 0, grh)
	memGraph = debugGraph:new('mem', 0, grh + 30)
	dtGraph = debugGraph:new('custom', 0, grh + 60)

	Game:setGameSize(385, 448)
	Game:setGameScale()

	local test_level = require "data.timeline.stage.01.timeline"
	test_level:run()

	Player:init()
	Player:spawn()
end

function love.update(dt)
	Game:update(dt)

	-- Update the graphs
	fpsGraph:update(dt)
	memGraph:update(dt)

	-- Update our custom graph
	dtGraph:update(dt, math.floor(dt * 1000))
	dtGraph.label = 'DT: ' ..  math.round(dt, 4)
end

function love.draw()
	Game:draw()

	love.graphics.push()

	love.graphics.translate(Game.margins.left * Game.scale, Game.margins.up * Game.scale)
	love.graphics.draw(Game.canvas, 0, 0, nil, Game.scale, Game.scale)

	love.graphics.pop()
	text:draw()

	fpsGraph:draw()
	memGraph:draw()
	dtGraph:draw()
end