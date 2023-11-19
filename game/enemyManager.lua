local bmanager = require "game.bulletManager"

---@class EnemyManager : BulletManager
local EnemyManager = setmetatable({
	---@type Bullet[]
	bullets = {}
}, { __index = bmanager })


return EnemyManager