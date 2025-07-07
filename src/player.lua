local function Player(anim8)
	local player = {}
	player.x = nil
	player.y = nil
	player.speed = 1
	player.direction = "right"
	player.sprite = {}
	player.sprite.current = love.graphics.newImage("img/character-8x8.png")
	-- player.sptireSheet =

	player.draw = function(self)
		love.graphics.draw(self.sprite.current, self.x, self.y)
	end
	return player
end
return Player
