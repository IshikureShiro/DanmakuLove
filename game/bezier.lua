---@class BezierPoint
---@field x number
---@field y number

local curve_res = 1

---@class BezierMesh
local BezierMesh = {
	width = 32,
	imageWidth = 32,
	res = curve_res,
	curve = nil,	---@type love.BezierCurve
	points = nil,	---@type BezierPoint[]
	tpoints = nil,
	verts = nil,	---@type table
}

function BezierMesh:create()
	return setmetatable({
		meshes = {}
	}, { __index = self })
end

function BezierMesh:updateCurve()
	local samelength = false
	if not self.curve or #self.points ~= self.curve:getControlPointCount() then
		local vs = {}
		for _, value in pairs(self.points) do
			table.insert(vs, value.x)
			table.insert(vs, value.y)
		end
		self.curve = love.math.newBezierCurve(vs)
	else
		samelength = true
		for i, value in pairs(self.points) do
			self.curve:setControlPoint(i, value.x, value.y)
		end
	end

	self.tpoints = self.curve:render(self.res)
	self:makeMesh(samelength)
end

function BezierMesh:createStripMesh(points, width)
    local vertices = {}

    -- Ensure there are enough points to create a strip mesh
    if #points < 2 then
        error("need at least 2 points to make strip mesh")
    end

	local function _make_verts(x1, y1, x2, y2, cdist)
		cdist = cdist or .0
		local dist = vmath.distance(x1, y1, x2, y2) / self.imageWidth
		cdist = cdist + dist
		local dx, dy = x2 - x1, y2 - y1
        local length = math.sqrt(dx * dx + dy * dy)

        if length > 0 then
            dx, dy = dx / length, dy / length
        end

        local normalX, normalY = -dy, dx
        local halfWidth = width / 2

        local vertex1 = {
            x1 + halfWidth * normalX,
            y1 + halfWidth * normalY,
			cdist,
			0.,
			-- dist = dist
        }

        local vertex2 = {
            x1 - halfWidth * normalX,
            y1 - halfWidth * normalY,
			cdist,
			1.,
			-- dist = dist
        }

        table.insert(vertices, vertex1)
        table.insert(vertices, vertex2)

		return dx, dy, dist
	end

	local totalDist = .0
	local dist = .0
	local dx, dy
    for i = 1, #points - 2, 2 do
        local x1, y1 = points[i    ], points[i + 1]
        local x2, y2 = points[i + 2], points[i + 3]

        dx, dy, dist = _make_verts(x1, y1, x2, y2, totalDist)
		totalDist = totalDist + dist
    end
	local lx, ly = points[#points - 1], points[#points]
	_make_verts(lx, ly, lx + dx, ly + dy, totalDist + dist)

    return vertices
end

function BezierMesh:makeMesh(reuse)
	self.verts = self:createStripMesh(self.tpoints, self.width)
end

function BezierMesh:draw()
	if self.tpoints then
		for i = 1, #self.tpoints - 1, 2 do
			love.graphics.circle("line", self.tpoints[i], self.tpoints[i + 1], 5)
		end
	end
	
	love.graphics.setColor(1, 0, 0)
	for _, p in pairs(self.points) do
		love.graphics.circle("line", p.x, p.y, 1)
	end
	love.graphics.setColor(1, 1, 1)
end

return BezierMesh