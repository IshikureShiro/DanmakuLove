local bullet = require "game.bullet"
local bdata  = require "game.bullet.data"

---@class Pickup.Data : BulletData
local Data = setmetatable({
	layer 		= -1,
	damage 		= 0,
	onPickup	= function ()
	end,
	playerOwned = true
}, { __index = bdata })
---@param self Pickup
---@param other Bullet
function Data.onCollide(self, other)
	if other == Player.body then
		self.data.onPickup()
		return true
	end
end

---@class Pickup : Bullet
---@field data? Pickup.Data
local Pickup = setmetatable({
	
}, { __index = bullet })

---@param d Pickup.Data
---@return Pickup.Data
function Pickup:newData(d)
	d = d or {}
	return setmetatable(d, { __index = Data })
end

return Pickup