menu = {}

local suit = require("suit")

function menu.update(dt)
  -- button to launch into unitPlacement
  -- center the button
  local x, y = love.graphics.getDimensions()
  suit.layout:reset(Round(x/2-150), Round(y/2-15))
  local startButton = suit.Button("Start Game", suit.layout:row(300, 30))
  if startButton.hit then
      unitPlacement.load()
      changeScreen(buildArmy)
  end
end

function menu.draw()
  local x = love.graphics.getDimensions()
  local center = x/2
  local logo = love.graphics.newImage('logo.png')
  -- center 250+125, fin=125
  -- center x/2+125, fin=
  love.graphics.draw(logo, (x/2)-250, 10)
  suit.draw()
end

return menu
