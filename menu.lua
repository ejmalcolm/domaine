menu = {}

local suit = require('suit')

function menu.update(dt)
    startButton = suit.Button("Start Game", 225, 200, 300, 30)
    if startButton.hit then
        changeScreen(buildArmy)
    end
end

function menu.draw()
    logo = love.graphics.newImage('logo.png')
    love.graphics.draw(logo, 125, 10)
    suit.draw()
end

return menu
