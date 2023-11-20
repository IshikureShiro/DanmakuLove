---@class CharacterData
local CharacterData = {
	bullet = nil,		---@type BulletData
	speed = 2,
	focusedSpeed = 1,
	size = 3,
	grazeSize = 15,
	magnetSize = 40
}

---@param c CharacterData
---@return CharacterData
function CharacterData:create(c)
	c = c or {}
	return setmetatable(c, { __index = self })
end

return CharacterData