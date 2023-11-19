local event = require "lib.event"
local action = require "lib.event.action"
local bman = require "game.bulletManager"

local log = Logger:spec("boss")

---@class Boss.Stage.Part
---@field id string
---@field type? integer
---@field health number
---@field currentHealth? number
---@field timeline fun(boss:Boss, timeline:Action)
---@field onComplete? fun(boss:Boss, timeline:Action):boolean
local Part = {
}

---@class Boss.Stage
---@field boss Boss
---@field parts Boss.Stage.Part[]
---@field totalHealth? number
local Stage = {
}

---@param parts Boss.Stage.Part[]
---@param boss Boss
---@return Boss.Stage
function Stage:create(parts, boss)
	local ret = setmetatable({ parts = parts, boss = boss }, { __index = self })
	ret.totalHealth = 0.0

	boss.events.stageStarted:register(ret, function (s)
		if s == ret then
			ret:start()
		end
	end)
	for _, part in pairs(parts) do
		boss.events.partStarted:register(part, function (p)
			if p == part then
				bman:setTL(boss.bullet, function (timeline, b)
					part.timeline(boss, timeline)
				end)
			end
		end)
		part.type = part.type or 0
		part.currentHealth = part.health
		ret.totalHealth = ret.totalHealth + part.health
	end

	return ret
end

function Stage:getCurrentPart()
	return self.parts[1]
end

function Stage:start()
	self.boss.events.partStarted(self:getCurrentPart())
end

---@param amt number
---@return boolean complete if the current stage is complete
function Stage:damage(amt)
	local part = self:getCurrentPart()
	part.currentHealth = part.currentHealth - amt
	if part.currentHealth <= 0 then
		table.remove(self.parts, 1)
		self.boss.events.partDone(part)
		if #self.parts > 0 then
			self.boss.events.partStarted(self:getCurrentPart())
		end
	end
	if #self.parts == 0 then
		return true
	end
	return false
end

---@class Boss.Events
---@field partDone		Event
---@field partStarted	Event
---@field stageDone		Event
---@field stageStarted	Event
---@field defeated		Event

---@class Boss
---@field bullet? Bullet
---@field moveReg table
---@field stages Boss.Stage[]
---@field events Boss.Events
local Boss = {
}

---@class Boss.Data
---@field bullet BulletData
---@field parts table<integer, Boss.Stage.Part[]>

---@param b Boss
---@return Boss
function Boss:create(b)
	return setmetatable(b or {}, { __index = self })
end

---@return Boss
function Boss:new()
	return self:create{
		stages = {},
		events = {
			partStarted 	= event:new(),
			partDone		= event:new(),
			stageStarted	= event:new(),
			stageDone		= event:new(),
			defeated		= event:new(),
		},
		moveReg = {}
	}
end

---@param data Boss.Data
---@param onspawn fun(b:Boss)
---@return Boss
function Boss:spawn(data, onspawn)
	local b = self:new()

	b.bullet = bman:spawn(data.bullet, 0, 0, function (_, _) end, false)
	b.bullet.velocity = 0

	for _, sparts in pairs(data.parts) do
		table.insert(b.stages, Stage:create(sparts, b))
	end

	b.bullet.events.destroy:unregister(b.bullet)
	b.bullet.events.damage:unregister(b.bullet)

	b.bullet.events.damage:register(b, function (amt)
		b:damage(amt)
	end)
	b.events.defeated:register(b, function (...)
		bman:setTL(b.bullet, function (_, _) end)
	end)

	onspawn(b)
	return b
end

function Boss:start()
	if #self.stages <= 0 then
		log:warning("tried to start with no stages")
	end

	local cur = self:getCurrentStage()
	local curPart = cur:getCurrentPart()
	if #cur.parts <= 0 or not curPart then
		log:warning("tried to start with no parts in current stage")
	end

	self.events.stageStarted(cur)
end

---@param data BulletData
---@param parts table<integer, Boss.Stage.Part[]>
---@return Boss.Data
function Boss:define(data, parts)
	return {
		bullet = data,
		parts = parts
	}
end

function Boss:isMoving()
	return self.bullet.events.update:isRegistered(self.moveReg)
end

---@param x number
---@param y number
---@param speed? number
---@return fun():boolean isdone
function Boss:moveToLerp(x, y, speed)
	speed = speed or 2.0
	if self:isMoving() then
		self.bullet.events.update:unregister(self.moveReg)
	end
	self.bullet.events.update:register(self.moveReg, function (dt)
		local t = math.min(1, speed * dt)
		self:moveInstant(
			math.lerp(self.bullet.x, x, t),
			math.lerp(self.bullet.y, y, t)
		)

		if vmath.distance(self.bullet, { x, y }) <= 0.01 then
			self.bullet.events.update:unregister(self.moveReg)
		end
	end)
	return function ()
		return not self:isMoving()
	end
end

function Boss:makeSimpleDelay(t)
	
end

function Boss:moveInstant(x, y)
	self.bullet:moveTo(x, y)
end

function Boss:getCurrentStage()
	return self.stages[1]
end

function Boss:damage(amt)
	if #self.stages == 0 then
		return
	end

	local cur = self:getCurrentStage()
	local complete = cur:damage(amt)
	if complete then
		table.remove(self.stages, 1)
		self.events.stageDone(cur)
		if #self.stages > 0 then
			self.events.stageStarted(self:getCurrentStage())
		end
	end
	if #self.stages == 0 then
		self.events.defeated()
	end
end

---@param tl fun(boss:Boss, timeline:Action)
function Boss:makeTimeline(tl)
	return tl
end

return Boss