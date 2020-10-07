local defeatScreen = {}

function defeatScreen.load()
  client:disconnect(2) -- code 2 is defeat
end

function defeatScreen.update()

end

function defeatScreen.draw()
  local defeat = love.graphics.newImage('images/defeat.png')
  love.graphics.draw(defeat, (centerX-145), 10)
end

return defeatScreen