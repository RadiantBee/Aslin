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
	-- approximate player coordinates
	map.playerX = nil
	map.playerY = nil
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

	map.update = function(self, playerX, playerY, spriteSize)
		-- We take the center of playerSprite to evaluate grid position
		local gridX = math.floor((playerX + (spriteSize / 2)) / spriteSize) + 1
		local gridY = math.floor((playerY + (spriteSize / 2)) / spriteSize) + 1
		-- If the "grid-ified" position of player changed, we update it
		if gridX ~= self.playerX or gridY ~= self.playerY then
			self.data[self.playerY][self.playerX] = 0
			self.data[gridY][gridX] = 2
			self.playerX = gridX
			self.playerY = gridY
		end
	end

	map.resolveCollisions = function(self, player, spriteSize)
		-- depending on dirrection of movement, we'll check the objects on collisions
		local collisionDetected = false
		-- for x axis
		if player.xDir > 0 then
			if self.data[self.playerY - 1][self.playerX + 1] == "1" then
				if player.x + spriteSize + player.xDir - player.collisionOffset >= self.playerX * spriteSize then
					if player.y + 1 < (self.playerY - 1) * spriteSize then
						collisionDetected = true
					end
				end
			end
			if self.data[self.playerY][self.playerX + 1] == "1" and not collisionDetected then
				if player.x + spriteSize + player.xDir - player.collisionOffset >= self.playerX * spriteSize then
					if
						player.y + 1 < self.playerY * spriteSize
						and player.y + spriteSize > self.playerY * spriteSize
					then
						collisionDetected = true
					end
				end
			end
			if self.data[self.playerY + 1][self.playerX + 1] == "1" and not collisionDetected then
				if player.x + spriteSize + player.xDir - player.collisionOffset >= self.playerX * spriteSize then
					if player.y + spriteSize > (self.playerY + 1) * spriteSize then
						collisionDetected = true
					end
				end
			end
			if not collisionDetected then
				player.x = player.x + player.xDir
			else
				player.x = (self.playerX - 1) * spriteSize + player.collisionOffset
			end
		-- moving left
		elseif player.xDir < 0 then
			if self.data[self.playerY - 1][self.playerX - 1] == "1" then
				if player.x + player.xDir + player.collisionOffset <= (self.playerX - 1) * spriteSize then
					if player.y + 1 < (self.playerY - 1) * spriteSize then
						collisionDetected = true
					end
				end
			end
			if self.data[self.playerY][self.playerX - 1] == "1" and not collisionDetected then
				if player.x + player.xDir + player.collisionOffset <= (self.playerX - 1) * spriteSize then
					if
						player.y + 1 < (self.playerY + 1) * spriteSize
						and player.y + spriteSize > self.playerY * spriteSize
					then
						collisionDetected = true
					end
				end
			end
			if self.data[self.playerY + 1][self.playerX - 1] == "1" and not collisionDetected then
				if player.x + player.xDir + player.collisionOffset <= (self.playerX - 1) * spriteSize then
					if player.y + spriteSize > self.playerY * spriteSize then
						collisionDetected = true
					end
				end
			end
			if not collisionDetected then
				player.x = player.x + player.xDir
			else
				player.x = (self.playerX - 1) * spriteSize - player.collisionOffset
			end
		end
		-- now looking at y axis
		collisionDetected = false
		if player.yDir > 0 then
			if self.data[self.playerY + 1][self.playerX - 1] == "1" then
				if player.y + player.yDir + spriteSize >= self.playerY * spriteSize then
					if player.x + player.collisionOffset < (self.playerX - 1) * spriteSize then
						collisionDetected = true
					end
				end
			end
			if self.data[self.playerY + 1][self.playerX] == "1" and not collisionDetected then
				if player.y + player.yDir + spriteSize >= self.playerY * spriteSize then
					if
						player.x + player.collisionOffset <= self.playerX * spriteSize
						and player.x + spriteSize - player.collisionOffset >= (self.playerX - 1) * spriteSize
					then
						collisionDetected = true
					end
				end
			end
			if self.data[self.playerY + 1][self.playerX + 1] == "1" and not collisionDetected then
				if player.y + player.yDir + spriteSize >= self.playerY * spriteSize then
					if player.x + spriteSize - player.collisionOffset >= (self.playerX - 1) * spriteSize then
						collisionDetected = true
					end
				end
			end
			if not collisionDetected then
				player.y = player.y + player.yDir
			else
				player.y = (self.playerY - 1) * spriteSize
				player.yAcc = player.gravityMax
			end
		elseif player.yDir < 0 then
			if not collisionDetected then
				player.y = player.y + player.yDir
			else
				player.y = (self.playerY - 1) * spriteSize
			end
		end
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
					self.playerX = x
					self.playerY = y
					return (x - 1) * spriteSize, (y - 1) * spriteSize
				end
			end
		end
		error("Map does not contain a player!")
	end

	map.draw = function(self, spriteSize)
		for y, row in ipairs(self.data) do
			for x, obj in ipairs(row) do
				if obj == "1" then
					love.graphics.draw(self.sprite.wall, (x - 1) * spriteSize, (y - 1) * spriteSize)
				end
			end
		end
	end
	return map
end

return Map
