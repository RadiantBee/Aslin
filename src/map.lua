--[[
-- Main matrix:
-- 0 - empty space
-- 1 - wall
-- 2 - player
--
-- idea:
-- add another matrix for non-essential map objects like
-- grass and other visual elements
--]]

local function split(s, delimiter)
	local result = {}
	for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
		table.insert(result, match)
	end
	return result
end

local function Map(startMapID)
	local map = {}
	map.id = startMapID or 0
	map.sprite = {}
	map.sprite.wall = love.graphics.newImage("img/square.png")

	map.data = {}
	map.loadID = function(self)
		local mapFile = io.open("maps/map_" .. self.id .. ".MP", "r")
		if not mapFile then
			error('Cannot acces the "maps/map_' .. self.id .. '.MP" file!')
		end
		local i = 1
		for line in mapFile:lines("l") do
			self.data[i] = split(line, " ")
			i = i + 1
		end
		mapFile:close()
	end
	map.print = function(self)
		for y, row in ipairs(self.data) do
			for x, obj in ipairs(row) do
				io.write(obj .. " ")
			end
			print()
		end
	end

	map.getPlayerPos = function(self, spriteSize)
		for y, row in ipairs(self.data) do
			for x, obj in ipairs(row) do
				if obj == "2" then
					return (x - 1) * spriteSize, (y - 1) * spriteSize
				end
			end
		end
		error("Map does not contain a player!")
	end

	map.draw = function(self, spriteSize)
		for y, row in ipairs(self.data) do
			for x, obj in ipairs(row) do
				if obj == "0" then
				elseif obj == "1" then
					love.graphics.draw(self.sprite.wall, (x - 1) * spriteSize, (y - 1) * spriteSize)
				end
			end
		end
	end
	return map
end

return Map
