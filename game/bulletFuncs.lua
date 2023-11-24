local action	= require "lib.event.action"
local bman		= require "game.bulletManager"

local bu_inc	= require "data.bullet.invisiblenocollide"
_B = {}

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

---@class FanArgs
---@field x number
---@field y number
---@field count integer
---@field tldata BulletTimelineData
---@field offset? number
---@field dir? number
---@field spread? number
---@field player? boolean

---@class BulletTimeline : Bullet, Action

---@type string|BulletData|nil
local bullet = nil
local actionstack = {}

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

---@param args FanArgs
---@return Bullet[]
local function _fan(args)
	return bman:fan(args.x, args.y, args.count, args.dir, args.tldata, args.spread, args.offset, args.player)
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

---@param f fun(tl:BulletTimeline):boolean?
---@return BulletTimelineData
local function _makecomplextl(f, ...)
	local args = {...}
	return bman:makeTLData(_getbullet(), function (timeline, b)
		local tl = _multiherit(timeline, b)
---@diagnostic disable-next-line: redundant-parameter
		local contfunc = action:fromFunc(function (_, ...)
			f(...)
		end):withArgs(tl, unpack(args))
		repeat
			local item = {timeline, b, tl, false}
			table.insert(actionstack, item)
			local d, e = contfunc:update(1)
			table.remove(actionstack, #actionstack)
			if item[4] then
				break
			end
			coroutine.yield()
		until not d
		return true
	end)
end

---@param n integer
---@param dist number
---@param delay number
---@param f fun(tl:BulletTimeline, i:integer):boolean?
---@return fun(tl:BulletTimeline):boolean?
function Stack(n, dist, delay, f, ...)
	-- lots of ugly hack
	-- sorry future me
	local pr_b = _getbullet()
	SetBullet(bu_inc)
	local varargs = {...}
	return function (tl)
		_peekstack()[2] = nil
		local ax, ay, dir = tl.x, tl.y, tl.direction
		for i in Loop(0, n - 1) do
			local x, y = 0, 0
			if i == 0 then
				x, y = ax, ay
			end
			SetBullet(pr_b)
			local b = Spawn(x, y, dir, f, {i}, unpack(varargs))
			b:moveForward(dist * i)

			if delay > 0 then
				Delay(delay)
			end
		end
		Done()
	end
end

---@param x number
---@param y number
---@param dir number
---@param n integer
---@param offset integer
---@param f fun(tl:BulletTimeline):boolean?
---@param ... any
---@return Bullet[]
function Cirlce(x, y, dir, n, offset, f, ...)
	local stacke = #actionstack > 0 and actionstack[#actionstack]
	local relbul = stacke and stacke[2]
	--- relative
	if relbul then
		if not dir then
			dir = relbul.direction
		end
		x = x + relbul.x
		y = y + relbul.y
	--- absolute
	else
		
	end

	return bman:fan(x, y, n, dir, _makecomplextl(f), nil, offset, ...)
end

---@param x number
---@param y number
---@param dir? number
---@param f fun(tl:BulletTimeline):boolean?
---@param tlargs? table
---@param ... any
---@return Bullet
function Spawn(x, y, dir, f, tlargs, ...)
	local stacke = #actionstack > 0 and actionstack[#actionstack]
	local relbul = stacke and stacke[2]
	tlargs = tlargs or {}
	--- relative
	if relbul then
		if not dir then
			dir = relbul.direction
		end
		x = x + relbul.x
		y = y + relbul.y
	--- absolute
	else
		
	end

	local b = bman:spawn(_getbullet(), x, y, _makecomplextl(f, unpack(tlargs)).timeline, ...)
	b.direction = dir or Player:getDirection(x, y)
	return b
end

---@overload fun(x:number, y:number, n:integer, direction?:number, spread:number, act:fun(tl:BulletTimeline):boolean?, args:FanArgs?)
---@overload fun(n:integer, direction?:number, spread:number, act:fun(tl:BulletTimeline):boolean?, args:FanArgs?)
---@overload fun(args:FanArgs)
function Fan(...)
	local args = {...}
	---@type number, number, integer, number, number, fun(tl:BulletTimeline):boolean?, FanArgs?
	local x, y, n, dir, spread, f, argstable
	local stacke = #actionstack > 0 and actionstack[#actionstack]

	--- first argument is args
	if args[1] and type(args[1]) == "table" then
		return _fan(args[1])
	--- relative fan
	elseif stacke and stacke[2] then
		n, dir, spread, f, argstable = ...
		if not dir then
			dir = stacke[2].direction
		end
	--- absolute fan
	else
		x, y, n, dir, spread, f, argstable = ...
	end
---@diagnostic disable-next-line: missing-fields
	argstable = argstable or _makeargs {}

	argstable.x			= x			or argstable.x		or 0
	argstable.y			= y			or argstable.y		or 0
	argstable.count		= n			or argstable.count	or 1
	argstable.dir		= dir		or argstable.dir
	argstable.spread	= spread	or argstable.spread

	if stacke and stacke[2] then
		argstable.x = argstable.x + stacke[2].x
		argstable.y = argstable.y + stacke[2].y
	end

	argstable.tldata = _makecomplextl(f)
	return _fan(argstable)
end

function Done()
	local stacke = #actionstack > 0 and actionstack[#actionstack]
	if stacke and stacke[2] then
		stacke[4] = true
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
	stacke[1]:delay(frames)
end

---@param secs number
function DelaySecs(secs)
	Delay(Game:secsToFrames(secs))
end