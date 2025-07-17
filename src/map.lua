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
	-- useCurrent is 1 or 0, it can exclude dirrection from formula
	map.checkBottomAdjacent = function(player, targetY, spriteSize, useCurrent)
		return player.y + player.topOffset + player.yDir * useCurrent < targetY * spriteSize
	end

	map.checkTopAdjacent = function(player, targetY, spriteSize, useCurrent)
		return player.y + spriteSize + player.yDir * useCurrent > (targetY - 1) * spriteSize
	end
	map.checkYAdjacent = function(self, player, targetY, spriteSize, useCurrent)
		return self.checkBottomAdjacent(player, targetY, spriteSize, useCurrent)
			and self.checkTopAdjacent(player, targetY, spriteSize, useCurrent)
	end
	map.checkLeftAdjacent = function(player, targetX, spriteSize, useCurrent)
		return player.x + spriteSize + player.xDir * useCurrent - player.collisionOffset > (targetX - 1) * spriteSize
	end

	map.checkRightAdjacent = function(player, targetX, spriteSize, useCurrent)
		return player.x + player.collisionOffset + player.xDir * useCurrent < targetX * spriteSize
	end
	map.checkXAdjacent = function(self, player, targetX, spriteSize, useCurrent)
		return self.checkLeftAdjacent(player, targetX, spriteSize, useCurrent)
			and self.checkRightAdjacent(player, targetX, spriteSize, useCurrent)
	end
	-- resolves target collision
	map.collisionResolveX = function(self, player, target, spriteSize)
		if target == "1" then
			if player.xDir > 0 then
				player.x = (self.playerX - 1) * spriteSize + player.collisionOffset
			elseif player.xDir < 0 then
				player.x = (self.playerX - 1) * spriteSize - player.collisionOffset
			end
			player.xDir = 0
		end
	end
	map.collisionResolveY = function(self, player, target, spriteSize)
		if target == "1" then
			if player.yDir > 0 then
				player.y = (self.playerY - 1) * spriteSize
				player.yAcc = player.gravityMax
			elseif player.yDir < 0 then
				player.y = (self.playerY - 1) * spriteSize - player.topOffset
				player.yAcc = 0
			end
			player.yDir = 0
		end
	end
	-- for every collision
	map.resolveCollisions = function(self, player, spriteSize)
		-- depending on dirrection of movement, we'll check the objects on collisions
		-- for x axis
		if player.xDir > 0 then
			if self.checkLeftAdjacent(player, self.playerX + 1, spriteSize, 1) then
				if self.checkBottomAdjacent(player, self.playerY - 1, spriteSize, 0) then
					self:collisionResolveX(player, self.data[self.playerY - 1][self.playerX + 1], spriteSize)
				end
				if self:checkYAdjacent(player, self.playerY, spriteSize, 0) then
					self:collisionResolveX(player, self.data[self.playerY][self.playerX + 1], spriteSize)
				end
				if self.checkTopAdjacent(player, self.playerY + 1, spriteSize, 0) then
					self:collisionResolveX(player, self.data[self.playerY + 1][self.playerX + 1], spriteSize)
				end
			end
		-- moving left
		elseif player.xDir < 0 then
			if self.checkRightAdjacent(player, self.playerX - 1, spriteSize, 1) then
				if self.checkBottomAdjacent(player, self.playerY - 1, spriteSize, 0) then
					self:collisionResolveX(player, self.data[self.playerY - 1][self.playerX - 1], spriteSize)
				end
				if self:checkYAdjacent(player, self.playerY, spriteSize, 0) then
					self:collisionResolveX(player, self.data[self.playerY][self.playerX - 1], spriteSize)
				end
				if self.checkTopAdjacent(player, self.playerY + 1, spriteSize, 0) then
					self:collisionResolveX(player, self.data[self.playerY + 1][self.playerX - 1], spriteSize)
				end
			end
		end
		player.x = player.x + player.xDir
		-- now looking at y axis
		if player.yDir > 0 then
			if self.checkTopAdjacent(player, self.playerY + 1, spriteSize, 1) then
				if self.checkRightAdjacent(player, self.playerX - 1, spriteSize, 0) then
					self:collisionResolveY(player, self.data[self.playerY + 1][self.playerX - 1], spriteSize)
				end
				if self:checkXAdjacent(player, self.playerX, spriteSize, 0) then
					self:collisionResolveY(player, self.data[self.playerY + 1][self.playerX], spriteSize)
				end
				if self.checkLeftAdjacent(player, self.playerX + 1, spriteSize, 0) then
					self:collisionResolveY(player, self.data[self.playerY + 1][self.playerX + 1], spriteSize)
				end
			end
		elseif player.yDir < 0 then
			if self.checkBottomAdjacent(player, self.playerY - 1, spriteSize, 1) then
				if self.checkRightAdjacent(player, self.playerX - 1, spriteSize, 0) then
					self:collisionResolveY(player, self.data[self.playerY - 1][self.playerX - 1], spriteSize)
				end
				if self:checkXAdjacent(player, self.playerX, spriteSize, 0) then
					self:collisionResolveY(player, self.data[self.playerY - 1][self.playerX], spriteSize)
				end
				if self.checkLeftAdjacent(player, self.playerX + 1, spriteSize, 0) then
					self:collisionResolveY(player, self.data[self.playerY - 1][self.playerX + 1], spriteSize)
				end
			end
		end
		player.y = player.y + player.yDir
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
