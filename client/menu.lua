menu = {}

local suit = require("suit")

function menu.update(dt)
    -- button to launch into unitPlacement
    -- center the button
    local x, y = love.graphics.getDimensions()
    suit.layout:reset(x/2-150, y/2-15)
    local startButton = suit.Button("Start Game", suit.layout:row(300, 30))
    if startButton.hit then
        unitPlacement.load()
        changeScreen(buildArmy)
    end

end

function menu.draw()
    local logo = love.graphics.newImage('logo.png')
    love.graphics.draw(logo, 125, 10)
    suit.draw()
end

return menu
