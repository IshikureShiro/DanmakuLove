local fadein_speed = 1.0
local fadeout_speed = 1.0

local min_fontsize = 5
local max_fontsize = 30

local font_paths = {
	cinzel_reg = "res/font/Cinzel-Regular.ttf",
	eb_garamond_ita = "res/font/EBGaramond-Italic.ttf",
	eb_garamond_reg = "res/font/EBGaramond-Regular.ttf",
	l_baskerville_ita = "res/font/LibreBaskerville-Italic.ttf",
	l_baskerville_reg = "res/font/LibreBaskerville-Regular.ttf",
	lora_reg 	= "res/font/Lora-Regular.ttf",
	jotione_reg = "res/font/JotiOne-Regular.ttf",
}

---@type table<string, table<integer, love.Font>>
local fonts = {
	cinzel_reg = {},
	eb_garamond_ita = {},
	eb_garamond_reg = {},
	l_baskerville_ita = {},
	l_baskerville_reg = {},
	lora_reg 	= {},
	jotione_reg = {},
}

for key, value in pairs(font_paths) do
	for i = min_fontsize, max_fontsize do
		fonts[key][i] = love.graphics.newFont(value, i)
	end
end

---@class TextManager.text
---@field x_t number?
---@field y_t number?
---@field move_speed number?
local Text = {
	content = "",
	game = false,
	r = 1.0,
	g = 1.0,
	b = 1.0,
	a = 1.0,
	size = 11,
	fadein_speed = fadein_speed,
	fadeout_speed = fadeout_speed,
	transform = nil,	---@type love.Transform
	font = fonts.cinzel_reg[11],
	fadeTimer = 3,
}

---@class TextManager.image : TextManager.text
---@field content love.Texture
local Image = setmetatable({
}, { __index = Text })

function Image:draw()
	love.graphics.setColor(self.r, self.g, self.b, self.a)
	love.graphics.draw(self.content, self.transform)
	love.graphics.setColor(1, 1, 1)
end

---@class TextManager.text.data
---@field x number?
---@field y number?
---@field size number?
---@field transform love.Transform?
---@field x_t number?
---@field y_t number?
---@field move_speed number?
---@field font love.Font?
---@field game boolean?
---@field r number?
---@field g number?
---@field b number?
---@field a number?
---@field time number?
---@field fadein_speed number?
---@field fadeout_speed number?

function Text:draw()
	love.graphics.setColor(self.r, self.g, self.b, self.a)
	love.graphics.print(self.content, self.font, self.transform)
	love.graphics.setColor(1, 1, 1)
end

function Text:update(dt)
	if self.fadeTimer > 0 then
		self.fadeTimer = self.fadeTimer - dt
		if self.a < 1 then
			self.a = math.min(1, self.a + (dt * self.fadein_speed))
		end
	else
		self.a = math.max(0, self.a - (dt * self.fadeout_speed))
		if self.a <= 0 then
			self:remove()
		end
	end

	if self.x_t or self.y_t then
		local x, y = self.transform:transformPoint(0, 0)
		local t = math.min(1, self.move_speed * dt)
		self.transform:translate(
			math.lerp(0, self.x_t - x, t),
			math.lerp(0, self.y_t - y, t)
		)
	end
end

---@class TextManager
local TextManager = {
	fonts = fonts,
	texts 		= {}, ---@type table<TextManager.text, TextManager.text>
	gameTexts 	= {}, ---@type table<TextManager.text, TextManager.text>
}

function Text:remove()
	(self.game and TextManager.gameTexts or TextManager.texts)[self] = nil
end

---@param dx number
---@param dy number
---@param speed? number
function Text:move(dx, dy, speed)
	local x, y = self.transform:transformPoint(0, 0)

	self.x_t = x + dx
	self.y_t = y + dy
	self.move_speed = speed or self.move_speed or 1.0
end

---@param content string
---@param data TextManager.text.data
---@return TextManager.text
function TextManager:addText(content, data)
	return self:add(content, data, Text)
end

---@param content love.Texture
---@param data TextManager.text.data
---@return TextManager.text
function TextManager:addImage(content, data)
	return self:add(content, data, Image)
end

---@param content string|love.Texture
---@param data TextManager.text.data
---@param t TextManager.text
---@return TextManager.text
function TextManager:add(content, data, t)
	local target = data.game and self.gameTexts or self.texts
	local size = data.size or 11
	local text = setmetatable({
		content = content,
		size = size,
		transform = data.transform or love.math.newTransform(data.x, data.y),
		game = data.game or false,
		r = data.r or 1,
		g = data.g or 1,
		b = data.b or 1,
		a = data.a or 1,
		fadeTimer = data.time or 4,
		fadein_speed = data.fadein_speed or fadein_speed,
		fadeout_speed = data.fadeout_speed or fadeout_speed,
		font = data.font or fonts.cinzel_reg[size],
	}, { __index = t })

	local x, y = text.transform:transformPoint(0, 0)
	text.x_t = data.x_t or x
	text.y_t = data.y_t or y
	text.move_speed = data.move_speed or 1.0
	target[text] = text
	return text
end

function TextManager:draw()
	for _, t in pairs(self.texts) do
		t:draw()
	end
end

function TextManager:drawGame()
	for _, t in pairs(self.gameTexts) do
		t:draw()
	end
end

function TextManager:update(dt)
	for _, t in pairs(self.gameTexts) do
		t:update(dt)
	end
	for _, t in pairs(self.texts) do
		t:update(dt)
	end
end

return TextManager