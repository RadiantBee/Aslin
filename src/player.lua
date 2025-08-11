local function Player(anim8)
	local player = {}
	player.x = nil
	player.y = nil
	player.startX = nil
	player.startY = nil
	player.collisionOffset = 2
	player.topOffset = 1
	player.speed = 10
	player.gravityMax = 20
	player.jumpForce = -20
	player.gravitySpeed = 20
	player.onGround = false
	player.yAcc = 16
	player.xDir = 0
	player.yDir = 0
	player.direction = "right"
	player.exploding = false

	player.setPos = function(self, x, y)
		self.x, self.y = x, y
	end

	player.setStartPos = function(self, x, y)
		self.startX, self.startY = x, y
		self.x, self.y = x, y
	end

	player.sptireSheet = love.graphics.newImage("img/characterSpriteSheet.png")
	player.grid = anim8.newGrid(8, 8, player.sptireSheet:getWidth(), player.sptireSheet:getHeight())

	player.sptireSheetExplosion = love.graphics.newImage("img/explosion.png")
	player.gridExplosion =
		anim8.newGrid(71, 98, player.sptireSheetExplosion:getWidth(), player.sptireSheetExplosion:getHeight())

	player.animation = {}

	player.animation.idleRight = anim8.newAnimation(player.grid("1-2", 1), 0.5)
	player.animation.idleLeft = anim8.newAnimation(player.grid("3-4", 1), 0.5)

	player.animation.current = player.animation.idleRight

	local function toIdleLeft()
		player.animation.current = player.animation.idleLeft
	end

	local function toIdleRight()
		player.animation.current = player.animation.idleRight
	end

	local function reset()
		player.animation.current = player.animation.idleRight
		player.x, player.y = player.startX, player.startY
		player.exploding = false
	end

	player.animation.explode = anim8.newAnimation(player.gridExplosion("1-17", 1), 0.05, reset)

	player.explode = function(self)
		self.exploding = true
		self.animation.current = self.animation.explode
	end

	player.animation.walkRight = anim8.newAnimation(player.grid("1-2", 2), 0.2)
	player.animation.walkLeft = anim8.newAnimation(player.grid("3-4", 2), 0.2)

	player.animation.turnLeft = anim8.newAnimation(player.grid("1-5", 3), 0.05, toIdleLeft)
	player.animation.turnRight = anim8.newAnimation(player.grid("1-5", 4), 0.05, toIdleRight)

	player.keypressed = function(self, key)
		-- turning animation logic
		if not player.exploding then
			if key == "left" and self.direction == "right" then
				self.direction = "left"
				-- if we cancel turning to the right
				if self.animation.current == self.animation.turnRight then
					local frame = self.animation.current.position -- we save the current frame of the cancelled animation

					self.animation.current:gotoFrame(1) -- reset cancelled animation
					self.animation.current = self.animation.turnLeft -- set our new turning animation
					self.animation.current:gotoFrame(6 - frame) -- go to mirrored frame of new animation
				else
					self.animation.current = self.animation.turnLeft
				end
			-- same logic but for cancelling turning to the left
			elseif key == "right" and self.direction == "left" then
				self.direction = "right"
				if self.animation.current == self.animation.turnLeft then
					local frame = self.animation.current.position
					self.animation.current:gotoFrame(1)
					self.animation.current = self.animation.turnRight
					self.animation.current:gotoFrame(6 - frame)
				else
					self.animation.current = self.animation.turnRight
				end
			end
			-- jumping
			if key == "space" or key == "up" then
				if self.onGround then
					self.yAcc = self.jumpForce
					self.onGround = false
				end
			end
		end
	end

	player.keyreleased = function(self, key)
		-- if we stopped walking in some direction, we go into idle animation
		if not player.exploding then
			if key == "left" and self.animation.current == self.animation.walkLeft then
				self.animation.current = self.animation.idleLeft
			elseif key == "right" and self.animation.current == self.animation.walkRight then
				self.animation.current = self.animation.idleRight
			end
		end
	end

	player.update = function(self, dt)
		self.xDir = 0
		self.yDir = 0

		if not player.exploding then
			if love.keyboard.isDown("right") then
				-- we play walking animation only if we were idle before
				if self.animation.current == self.animation.idleRight then
					self.animation.current = self.animation.walkRight
				end
				self.xDir = self.xDir + self.speed * dt
			elseif love.keyboard.isDown("left") then
				if self.animation.current == self.animation.idleLeft then
					self.animation.current = self.animation.walkLeft
				end
				self.xDir = self.xDir - self.speed * dt
			end

			if self.yAcc < self.gravityMax then
				self.yAcc = self.yAcc + self.gravitySpeed * dt
			else
				self.yAcc = self.gravityMax
			end
			self.yDir = self.yAcc * dt
		end

		self.animation.current:update(dt)
	end

	player.draw = function(self)
		if not self.exploding then
			self.animation.current:draw(self.sptireSheet, self.x, self.y)
		else
			self.animation.current:draw(self.sptireSheetExplosion, self.x - 25, self.y - 25)
		end
	end
	return player
end
return Player
