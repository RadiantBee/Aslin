local anim8 = require("libs/anim8")
local push = require("libs/push")
local Map = require("src/map")
local Player = require("src/player")

-- Some data to initialize window
local spriteSize = 8
local windowFactorWidth = 0.6
local windowFactorHeight = 0.8
local spriteCapacityWidth, spriteCapacityHeight = 16, 16

local screenWidth, screenHeight = love.window.getDesktopDimensions()
local windowWidth, windowHeight = screenWidth * windowFactorWidth, screenHeight * windowFactorHeight
local virtualWidth, virtualHeight = spriteSize * spriteCapacityWidth, spriteSize * spriteCapacityHeight

-- Game objects
local player
local map

function love.load()
	push:setupScreen(virtualWidth, virtualHeight, windowWidth, windowHeight, { vsync = 0, resizable = false })
	love.graphics.setDefaultFilter("nearest", "nearest")

	player = Player(anim8)
	map = Map()
	map:loadID()
	--map:print()
	player:setPos(map:getPlayerPos(spriteSize))
end

function love.keypressed(key)
	player:keypressed(key)
end

function love.keyreleased(key)
	if key == "escape" then
		love.event.quit()
	end
	player:keyreleased(key)
end

function love.update(dt)
	player:update(dt)
	map:resolveCollisions(player, spriteSize)
	map:update(player.x, player.y, spriteSize)
end

function love.draw()
	-- force resolution while drawing objects inside push
	push:start()
	map:draw(spriteSize)
	player:draw()
	--print("Memory used: " .. math.ceil(collectgarbage("count")) .. " kB")
	--print("Current FPS: " .. tostring(love.timer.getFPS()))
	push:finish()
end
