ConnectScreen = {}

local suit = require("suit")

-- forward keyboard events for the ipInput field
function love.textinput(t)
    suit.textinput(t)
end

function love.keypressed(key)
    suit.keypressed(key)
end

-- lOve logic

function ConnectScreen.load()
    ipInputText = {text = ""}
end

function ConnectScreen.update(dt)
    -- input for entering IP
    local ipInput = suit.Input(ipInputText, 225, 200, 300, 30)
    -- label above ipInput
    suit.Label('Enter the host IP here.', 225, 170, 300, 30)
    -- button to connect
    local connectButton = suit.Button('Connect', 325, 240, 100, 20)
    if connectButton.hit then
        print(ipInputText.text)
    end
end

function ConnectScreen.draw()
    local logo = love.graphics.newImage('logo.png')
    love.graphics.draw(logo, 125, 10)
    suit.draw()
end

return ConnectScreen