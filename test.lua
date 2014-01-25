local band = nil
if jit ~= nil then -- luajit has a different bitops module name
	band = bit.band
else
	band = bit32.band
end

local function lerp(a, b, v)
	return a * (1 - v) + b * v
end

local function smooth(v)
	return v * v * (3 - 2 * v)
end

local function random_gradient()
	local v = math.random() * math.pi * 2.0
	return {x = math.cos(v), y = math.sin(v)}
end

local function gradient(orig, grad, p)
	return grad.x * (p.x - orig.x) + grad.y * (p.y - orig.y)
end

local Noise2D = {}
Noise2D.__index = Noise2D

function Noise2D.new(seed)
	math.randomseed(seed)
	local rgradients = {}
	for i = 1, 256 do
		rgradients[i] = random_gradient()
	end
	local permutations = {}
	for i = 1, 256 do
		local j = math.random(i)
		permutations[i] = permutations[j]
		permutations[j] = i
	end
	return setmetatable({
		rgradients = rgradients,
		permutations = permutations,
		gradients = {},
		origins = {},
	}, Noise2D)
end

function Noise2D:get_gradient(x, y)
	x = band(x, 255)+1
	y = band(y, 255)+1
	local idx = self.permutations[x] + self.permutations[y]
	return self.rgradients[band(idx, 255)+1]
end

function Noise2D:get_gradients_and_origins(x, y)
	local x0 = math.floor(x)
	local y0 = math.floor(y)
	local x1 = x0 + 1
	local y1 = y0 + 1

	self.gradients[1] = self:get_gradient(x0, y0)
	self.gradients[2] = self:get_gradient(x1, y0)
	self.gradients[3] = self:get_gradient(x0, y1)
	self.gradients[4] = self:get_gradient(x1, y1)
	self.origins[1] = {x = x0 + 0, y = y0 + 0}
	self.origins[2] = {x = x0 + 1, y = y0 + 0}
	self.origins[3] = {x = x0 + 0, y = y0 + 1}
	self.origins[4] = {x = x0 + 1, y = y0 + 1}
end

function Noise2D:get(x, y)
	local p = {x = x, y = y}
	self:get_gradients_and_origins(x, y)
	local v1 = gradient(self.origins[1], self.gradients[1], p)
	local v2 = gradient(self.origins[2], self.gradients[2], p)
	local v3 = gradient(self.origins[3], self.gradients[3], p)
	local v4 = gradient(self.origins[4], self.gradients[4], p)
	local fx = smooth(x - self.origins[1].x)
	local vx1 = lerp(v1, v2, fx)
	local vx2 = lerp(v3, v4, fx)
	local fy = smooth(y - self.origins[1].y)
	return lerp(vx1, vx2, fy)
end

local symbols = {' ', '░', '▒', '▓', '█', '█'}
local pixels = {}
for i = 1, 256*256 do
	pixels[i] = ""
end

local n2d = Noise2D.new(os.clock())
for i = 1, 100 do
	for y = 1, 256 do
		y = y - 1
		for x = 1, 256 do
			x = x - 1
			local v = n2d:get(x * 0.1, y * 0.1) * 0.5 + 0.5
			pixels[(y*256+x)+1] = v
		end
	end
end

for y = 1, 256 do
	y = y - 1
	for x = 1, 256 do
		x = x - 1
		local idx = pixels[(y*256+x)+1] / 0.2
		io.write(symbols[math.floor(idx)+1])
	end
	print("")
end
