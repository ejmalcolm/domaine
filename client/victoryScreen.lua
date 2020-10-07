local victoryScreen = {}

function victoryScreen.load()
  client:disconnect(1) -- code 1 is victory
end

function victoryScreen.update()

end

function victoryScreen.draw()
  local victory = love.graphics.newImage('images/victory.png')
  love.graphics.draw(victory, (centerX-200), 10)
end

return victoryScreen