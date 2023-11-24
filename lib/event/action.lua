---@type Action[]
local GlobalActions = {}

local log = Logger:spec("action")

---@class Action
local Action = {
    ---@type thread?
    routine = nil,
    ---@type fun(act: Action)?
    onFinish = nil,
    ---@type fun(act: Action)?
    onCancel = nil,
	---@type fun(self:self):...
	getArgs = nil,
	runtime = 0.0,
	delta = 1,
	start = 0.0, -- time at the start of current update
}

---@param ... any
---@return Action
function Action:withArgs(...)
	local args = {...}
	self.getArgs = function(s)
		return s, unpack(args)
	end
	return self
end

---@param f any|fun():boolean
function Action:delayUnitl(f)
	if type(f) ~= "function" then
		f = function ()
			return f
		end
	end
    while not f() do
        coroutine.yield()
    end
end

function Action:delay(time)
	time = time or 1
    while time > 0 do
        time = time - self.delta
		self.delta = self.delta + time
		if time >= 0 then
			coroutine.yield()
		end
    end
end

---@param dt number
---@return boolean
---@return any
function Action:update(dt)
	self.start = love.timer.getTime()
    self.delta = dt
	self.runtime = self.runtime + dt
    if not self:isValid() then
        return false
    end

    local ok, err = coroutine.resume(self.routine, self:getArgs())
	if not ok then
		log:warning("error in routine: ", err, debug.traceback())
	end
    return self:isValid(), err
end

---@return boolean
function Action:isValid()
    return self.routine ~= nil and coroutine.status(self.routine) ~= "dead"
end

---@return Action
function Action:run()
    table.insert(GlobalActions, self)
	return self
end

---@param actionTable table?
function Action:cancel(actionTable)
    if not self:isValid() then
        log:warning("action", "attempted to cancel invalid action")
        return
    end

    table.removeItem(actionTable or GlobalActions, self)
	self.routine = nil

    if self.onCancel then
        self:onCancel()
    end
end

---@param f fun(act: Action)
---@param run boolean?
---@return Action
function Action:fromFunc(f, run)
    local o = setmetatable({}, { __index = Action })
	o.getArgs = function(s) return s end
    o.routine = coroutine.create(f)
    if run then

        o:run()
    end
    return o
end


---@param f fun(act: Action)
---@return Action
function Action:withFinish(f)
    if self.onFinish then
		local of = self.onFinish
		self.onFinish = function (act)
---@diagnostic disable-next-line: need-check-nil
			of(act)
			f(act)
		end
	else
		self.onFinish = f
	end
    return self
end

---@param f fun(act: Action)
---@return Action
function Action:withCancel(f)
    if self.onCancel then
		local oc = self.onCancel
		self.onCancel = function (act)
---@diagnostic disable-next-line: need-check-nil
			oc(act)
			f(act)
		end
	else
		self.onCancel = f
	end
    return self
end

---@param f fun(act: Action)
---@return Action
function Action:withEnd(f)
	self:withFinish(f)
	self:withCancel(f)
	return self
end

function Action.globalUpdate(dt)
    for i, value in ipairs(GlobalActions) do

        if not value:update(dt) then
            table.remove(GlobalActions, i)
            if value.onFinish then
                value:onFinish()
            end
        end
    end
end

---comment
---@param f fun()
---@param u fun():boolean
function Action:delayed(f, u)
	Action:fromFunc(function (act)
		act:delayUnitl(u)
		f()
	end):run()
end

return Action