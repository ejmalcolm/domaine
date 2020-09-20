local menu = {}

function menu.update(dt)
  -- button to launch into unitPlacement
  -- center the button
  local x, y = love.graphics.getDimensions()
  suit.layout:reset(Round(x/2-150), Round(y/2-15))
  local startButton = suit.Button("Start Game", suit.layout:row(300, 30))
  if startButton.hit then
    chooseAscendant.load()
    changeScreen(chooseAscendant)
  end
end

function menu.draw()
  local x = love.graphics.getDimensions()
  local center = x/2
  local logo = love.graphics.newImage('images/logo.png')
  love.graphics.draw(logo, (x/2)-250, 10)
  suit.draw()
end

return menu
