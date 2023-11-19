---@class Event
local Event = {
	---@type table<table, fun(...):any?>
	registrates = {},
	---@type any[]
	results = {}
}

---@param ... any
---@return ...any
function Event:__call(...)
	self.results = {}
	for _, fun in pairs(self.registrates) do
		local ret = fun(...)
		if ret then
			table.insert(self.results, ret)
		end
	end
	return unpack(self.results)
end

---@param t table
---@param fun fun(...)
function Event:register(t, fun)
	self.registrates[t] = fun
end

---@param t table
---@param fun fun(...)
function Event:register_wrapped(t, fun)
	self:register(wraptfunc(t, fun))
end

---@param t table
function Event:unregister(t)
	if not self.registrates[t] then
		Logger:warning("event", "tried to unregister non registered table")
	end

	self.registrates[t] = nil
end

function Event:isRegistered(k)
	return self.registrates[k] ~= nil
end

---@return Event
function Event:new()
	return setmetatable({ registrates = {}, results = {} }, { __index = Event, __call = Event.__call })
end

return Event