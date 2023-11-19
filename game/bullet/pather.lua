local bezierMesh = require "game.bezier"

local log = Logger:spec("pather")

---@class PatherVis
local Vis = {
	images = nil,		---@type love.Image[]
	stretch = false,
	width = 32,
	res = 0,
	startlen = 1,
	taillen = 1
}

---@class PatherData
local Data = {
	vis = nil,			---@type PatherVis
	r = 1.,
	g = 1.,
	b = 1.,
	a = 1.,
}

---@param p Pather
function Data:apply(p)
	p.data = self
	p.bezier.res = self.vis.res
	p.bezier.width = self.vis.width
	p.r = self.r
	p.g = self.g
	p.b = self.b
	p.a = self.a
end

---@class Pather
local Pather = {
	id = -1,
	data = nil,			---@type PatherData
	bullets = nil,		---@type Bullet[]
	bezier = nil,		---@type BezierMesh
	meshes = nil,		---@type love.Mesh[]
	r = 1.,
	g = 1.,
	b = 1.,
	a = 1.,
}

function Pather:create()
	local bullets = {}
	local b = bezierMesh:create()
	b.points = bullets
	return setmetatable({
		bezier = b,
		bullets = bullets,
		meshes = {}
	}, { __index = self })
end

function Pather:update(dt)
	self:updateMesh()
	self:checkCollisions()
end

function Pather:checkCollisions()
	local w = self.data.vis.width
	for i = 1, #self.bullets - 1, 1 do
		local curr = self.bullets[i    ]
		local next = self.bullets[i + 1]
		local dist = vmath.distance(curr, next)

		local rect = Game.colWorld:rectangle(curr.x - (w * .5), curr.y - dist, w, dist)
		rect:setRotation(math.atan2(curr.y - next.y, curr.x - next.x) + (-.5 * math.pi), curr.x, curr.y)
		Game.colWorld:remove(curr.collider)
		curr.collider = rect
		curr:checkCollisions()
	end
end

function Pather:updateMesh()
	if #self.bullets < 2 then
		-- log:warning("not enough points to make mesh for pather")
		return
	end
	local olen = self.bezier.verts and #self.bezier.verts or 0
	self.bezier:updateCurve()
	local totalverts = self.bezier.verts
	local nlen = #totalverts

	local slen = self.data.vis.startlen
	local tlen = self.data.vis.taillen
	if (nlen * .5) < slen + tlen then
		slen = 1
		tlen = 1
	end

	do --start
		local verts = {unpack(totalverts, 1, slen * 2)}
		for i = 0, #verts - 1, 2 do
			local u = (i) * (1 / (slen - 1)) * .5
			verts[i + 1][3] = u
			verts[i + 2][3] = u
		end
		local mesh = love.graphics.newMesh(verts, "strip")
		local tex = self.data.vis.images[1]
		mesh:setTexture(tex)
		self.meshes[1] = mesh
	end

	do -- middle
		local s = (slen * 2) - 1
		local e = #totalverts - (tlen * 2) + 2
		local verts = {unpack(totalverts, s, e)}
		-- print(s, e, unpack(verts))
		local len = #verts * .5
		for i = 0, #verts - 1, 2 do
			local u = i * (1 / len)
			verts[i + 1][3] = u
			verts[i + 2][3] = u
		end
		local mesh = love.graphics.newMesh(verts, "strip")
		local tex = self.data.vis.images[2]
		mesh:setTexture(tex)
		self.meshes[2] = mesh
	end

	do --tail
		local e = #totalverts - (tlen * 2) + 1
		local verts = {unpack(totalverts, e, #totalverts)}
		for i = 0, #verts - 1, 2 do
			local u = i * (1 / (tlen - 1)) * .5
			verts[i + 1][3] = u
			verts[i + 2][3] = u
		end
		local mesh = love.graphics.newMesh(verts, "strip")
		local tex = self.data.vis.images[3]
		mesh:setTexture(tex)
		self.meshes[3] = mesh
	end
end

function Pather:draw()
	DEEP.queue(self.id, function ()
		-- love.graphics.setWireframe(true)
		for _, mesh in pairs(self.meshes) do
			love.graphics.draw(mesh)
		end
		love.graphics.setWireframe(false)
	end)
end

---@param d PatherData
---@return PatherData
function Pather:newData(d)
	return setmetatable(d or {}, { __index = Data })
end

---@param v PatherVis
---@return PatherVis
function Pather:newVis(v)
	v = v or {}
	assert(v.images, "pather vis needs images")
	if v.images[1] and not v.images[2] then
		v.images[2] = v.images[1]
		v.images[3] = v.images[1]
	end
	return setmetatable(v, { __index = Vis })
end

return Pather