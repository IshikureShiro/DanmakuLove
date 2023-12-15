local action	= require "lib.event.action"
local bman		= require "game.bulletManager"

local bu_inc	= require "data.bullet.invisiblenocollide"
_B = {}

Pi		= math.pi
Pi_2	= math.pi * 2
Pi_05	= math.pi * .5

---@alias SpawnType
---|"Rel"
---|"Abs"
---|"RelPos_AbsAngle"
---|"AbsPos_RelAngle"

local function _multiherit(...)
	local parents = {...}
	return setmetatable({}, {
		__index = function (t, k)
			for _, value in pairs(parents) do
				local r = value[k]
				if r then
					return r
				end
			end
		end,
		__newindex = function (t, k, v)
			for _, value in pairs(parents) do
				local r = value[k]
				if r then
					value[k] = v
				end
			end
		end
	})
end

---@class ActionStackElement
---@field [1] Action
---@field [2] Bullet|nil
---@field [4] boolean

---@class SpawnArgs
---@field spawnType? SpawnType

---@class StackArgs
---@field ftb? boolean
---@field spawntype? SpawnType

---@class FanArgs
---@field x? number
---@field y? number
---@field count? integer
---@field tldata? BulletTimelineData
---@field offset? number
---@field dir? number
---@field spread? number
---@field player? boolean
---@field ccw? boolean
---@field delay? integer|fun(i:integer):integer
---@field spawntype? SpawnType

---@class BulletTimeline : Bullet, Action

---@type string|BulletData|nil
local bullet = nil
---@type ActionStackElement[]
local actionstack = {} --- [1] = Action, [2?] = Bullet

local function _peekstack()
	return #actionstack > 0 and actionstack[#actionstack]
end

---@param t FanArgs
---@return FanArgs
local function _makeargs(t)
	return t or {
		x = 0,
		y = 0,
		count = 0,
---@diagnostic disable-next-line: assign-type-mismatch
		tldata = nil
	}--[[@as FanArgs]]
end

function Loop(s, e)
	local c = s - 1

	---@return integer
	return function ()
		c = c + 1
		if c > e then
---@diagnostic disable-next-line: return-type-mismatch
			return nil
		end
		local stacke = #actionstack > 0 and actionstack[#actionstack]
		if stacke then
			stacke[1].delta = stacke[1].delta - 1
		end
		return c
	end
end

---@param b string|BulletData
function SetBullet(b)
	bullet = b
end

---@return BulletData
local function _getbullet()
	if type(bullet) == "string" then
		bullet = require(bullet)--[[@as BulletData]]
	end
	if not bullet then
		error("bullet not set")
	end
	return bullet
end


---@param b BulletData
---@param f fun(tl:BulletTimeline):boolean?
---@param ... any
---@return BulletTimelineData
local function _makecomplextlB(b, f, ...)
	local args = {...}
	return bman:makeTLData(b, function (timeline, bu)
		local tl = _multiherit(timeline, bu)
---@diagnostic disable-next-line: redundant-parameter
		local contfunc = action:fromFunc(function (_, ...)
			f(...)
		end):withArgs(tl, unpack(args))
		repeat
			local item = {timeline, bu, tl, false}
			table.insert(actionstack, item)
			local running, e = contfunc:update(1)
			table.remove(actionstack, #actionstack)
			if item[4] then
				break
			end
			coroutine.yield()
		until not running
		-- return true  -- (true = repeat)
	end)
end

---@param f fun(tl:BulletTimeline):boolean?
---@param ... any
---@return BulletTimelineData
local function _makecomplextl(f, ...)
	return _makecomplextlB(_getbullet(), f, ...)
end


---@param d nil|integer|fun(i:integer):integer
---@return fun(i:integer)
local function _makeDelay(d)
	if type(d) == "function" then
		return function (i)
			Delay(d(i))
		end
	elseif type(d) == "number" then
		return function (_)
			return Delay(d)
		end
	else
		return function (_) end
	end
end

---@param dir number
---@param mod number|Player|Bullet
---@param x? number
---@param y? number
---@param st? SpawnType
---@return unknown
local function _modDir(dir, mod, x, y, st)
	st = st or "Rel"
	if type(mod) == "number" then
		if st == "Rel" or st == "AbsPos_RelAngle" then
			return dir + mod
		else
			return mod
		end
	elseif mod == Player then
		if not x or not y then
			error("x and y pos needed in _modDir")
		end
		return Player.body:getDirectionFrom(x, y)
	elseif type(mod) == "table" then
		if not x or not y then
			error("x and y pos needed in _modDir")
		end
		---@cast mod Bullet
		return mod:getDirectionFrom(x, y)
	else
		error("invalid arg for _modDir")
	end
end

---@param x number
---@param y number
---@param rx number
---@param ry number
---@param st? SpawnType
---@return number x
---@return number y
local function _modPos(x, y, rx, ry, st)
	st = st or "Rel"
	if st == "Rel" or st == "RelPos_AbsAngle" then
		x = x + rx
		y = y + ry
	end
	return x, y
end


---@overload fun(bullet:BulletData, args:SpawnArgs?):Bullet
---@overload fun(bullet:BulletData, tl:(fun(tl:BulletTimeline):boolean?), args:SpawnArgs?):Bullet
---@overload fun(bullet:BulletData, x:number, y:number, dir:(number|Player|Bullet), tl:(fun(tl:BulletTimeline):boolean?), args:SpawnArgs?)
function Spawn(...)
	local params = {...}
	local stacke = _peekstack()
	local stackebul = stacke and stacke[2]

	local dir = .0
	local x, y = 0, 0

	local args	---@type SpawnArgs
	local f		---@type fun(tl:BulletTimeline):boolean?
	local bu	---@type BulletData

	if type(params[2]) == "function" then
		bu		= params[1]
		f		= params[2]
		args	= params[3] or {} ---@type SpawnArgs
	elseif type(params[5]) == "function" then
		bu		= params[1]
		x		= params[2]
		y		= params[3]
		dir		= params[4]
		f		= params[5]
		args	= params[6] or {} ---@type SpawnArgs

		if stackebul then
			x, y	= _modPos(x, y, stackebul.x, stackebul.y, args.spawnType)
			dir		= _modDir(stackebul.direction, dir, x, y, args.spawnType)
		end
	elseif stackebul then
		dir		= stackebul.direction
		x, y	= stackebul.x, stackebul.y
		bu		= params[1]
		args	= params[2] or {} ---@type SpawnArgs
		f		= function (tl) end
	else
		error("spawn called with invalid arguments/context")
	end

	local btl = _makecomplextlB(bu, f)
	local b = bman:spawn(bu, x, y, btl.timeline)
	b.direction = dir
	return b
end

---@overload fun(n:integer, dist:number, delay:(integer|fun(i:integer):integer), f:fun(tl:BulletTimeline, tl_i:integer), args:StackArgs?)
---@overload fun(n:integer, dist:number, delay:(integer|fun(i:integer):integer), dir:(number|Player|Bullet), f:fun(tl:BulletTimeline, tl_i:integer), args:StackArgs?)
---@overload fun(x:number, y:number, dir:(number|Player|Bullet), n:integer, dist:number, delay:(integer|fun(i:integer):integer), f:fun(tl:BulletTimeline, tl_i:integer), args:StackArgs?)
function Stack(...)
	local params = {...}
	local args = {} ---@type StackArgs
	---@type integer, number
	local n, dist
	local delay ---@type integer|fun(i:integer):integer
	local f		---@type fun(tl:BulletTimeline, tl_i:integer)

	local x, y	= .0, .0
	local dir	= .0

	local stacke = _peekstack()
	local stackebul = stacke and stacke[2]

	if stackebul and type(params[4]) == "function" then
		f		= params[4]
		args	= params[5] or {} ---@type StackArgs
		n		= params[1]
		dist	= params[2]
		delay	= params[3]
		x		= stackebul.x
		y		= stackebul.y
		dir		= stackebul.direction
	elseif stackebul and type(params[5]) == "function" then
		f		= params[5]
		args	= params[6] or {} ---@type StackArgs
		n		= params[1]
		dist	= params[2]
		delay	= params[3]
		x		= stackebul.x
		y		= stackebul.y
		dir		= _modDir(stackebul.direction, params[4], x, y, args.spawntype)
	elseif type(params[7]) == "function" then
		f		= params[7]
		args	= params[8] or {} ---@type StackArgs
		x		= params[1]
		y		= params[2]
		n		= params[4]
		dist	= params[5]
		delay	= params[6]

		if stackebul then
			x, y	= _modPos(x, y, stackebul.x, stackebul.y, args.spawntype)
			dir		= _modDir(stackebul.direction, params[3], x, y, args.spawntype)
		else
			dir	= _modDir(0, params[3], x, y, args.spawntype)
		end
	else
		error("Stack called with invalid arguments/invalid context")
	end

	local step = args.ftb and -dist or dist

	local _delay = _makeDelay(delay)
	local target_b = bman:spawn(bu_inc, x, y, function (timeline, b) end)
	target_b.velocity = 0
	target_b.direction = dir
	if args.ftb then
		target_b:moveForward(dist * n)
	end
	for i in Loop(1, n) do
		local btl = _makecomplextlB(bu_inc, f, i)
		local i_b = bman:spawn(bu_inc, x, y, btl.timeline)
		i_b.direction = target_b.direction
		i_b.x = target_b.x
		i_b.y = target_b.y
		i_b.velocity = 0
		i_b.events.timelineDone:register({}, function (...)
			i_b:destroy()
		end)

		_delay(i)
		target_b:moveForward(step)
	end
	target_b:destroy()
end

---@overload fun(x:number, y:number, dir:(number|Player|Bullet), n:integer, f:fun(tl:BulletTimeline, tl_i:integer), args:FanArgs?)
function Cirlce(...)
	local params = {...}
	table.insert(params, 5, 360)
	return Fan(unpack(params))
end

---@overload fun(n:integer, spread:number, f:fun(tl:BulletTimeline, tl_i:integer), args:FanArgs?)
---@overload fun(x:number, y:number, dir:(number|Player|Bullet), n:integer, spread:number, f:fun(tl:BulletTimeline, tl_i:integer), args:FanArgs?)
function Fan(...)
	local args = {} ---@type FanArgs
	local dir = 0
	local f ---@type fun(tl:BulletTimeline, tl_i:integer)

	local params = {...}
	local stacke = _peekstack()
	local stackebul = stacke and stacke[2]

	if type(params[3]) == "function" then
		if not stackebul then
			error("relative fan called in absolute context?")
		end
		for i = 1, 3 do
			table.insert(params, 0, 0)
		end
	end

	if #params >= 6
		and type(params[1]) == "number"
		and type(params[2]) == "number"
		and type(params[6]) == "function"
	then
		args	= params[7] or {} ---@type FanArgs
		args.x	= params[1]
		args.y	= params[2]
		args.count	= params[4]
		args.spread	= math.rad(params[5])

		f = params[6]
		if stackebul then
			args.x, args.y	= _modPos(args.x, args.y, stackebul.x, stackebul.y, args.spawntype)
			dir				= _modDir(stackebul.direction, params[3], args.x, args.y, args.spawntype)
		else
			dir				= _modDir(0, params[3], args.x, args.y, args.spawntype)
		end
	end

	local step = args.spread / args.count
	if args.ccw then
		step = step * -1
	end

	local c_dir = args.spread * -.5
	c_dir = c_dir - (step * .5)
	if args.ccw then
		c_dir = c_dir * -1
	end

	local _delay = _makeDelay(args.delay)

	for i in Loop(1, args.count) do
		local btl = _makecomplextlB(bu_inc, f, i)
		local i_bul = bman:spawn(bu_inc, args.x, args.y, btl.timeline)
		i_bul.direction = dir + c_dir
		i_bul.velocity = 0
		i_bul.events.timelineDone:register({}, function (...)
			i_bul:destroy()
		end)

		c_dir = c_dir + step

		_delay(i)
	end
end


---@param f fun(act:Action)
function Action(f)
	return action:fromFunc(function (act)
		table.insert(actionstack, {act})
		f(act)
		table.remove(actionstack, #actionstack)
	end)
end

---@param frames integer
function Delay(frames)
	if #actionstack == 0 then
		error("no action on stack, make sure you are calling this from a timeline or Action()")
	end
	local stacke = actionstack[#actionstack]
	if not stacke or not stacke[1] then
		error("no action on stack, make sure you are calling this from a timeline or Action()")
	end
	stacke[1]:delay(math.ceil(frames))
end

---@param secs number
function DelaySecs(secs)
	Delay(Game:secsToFrames(secs))
end

function Done()
	local stacke = #actionstack > 0 and actionstack[#actionstack]
	if stacke and stacke[2] then
		stacke[4] = true
	end
end
