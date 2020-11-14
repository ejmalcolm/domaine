ConnectScreen = {}

-- forward keyboard events for the ipInput field
function love.textinput(t)
    suit.textinput(t)
end

function love.keypressed(key)
    suit.keypressed(key)
end

-- lOve logic

function ConnectScreen.load()
  ipInputText = {text = "localhost"}
end

function ConnectScreen.update(dt)
  local x,y = love.graphics.getDimensions()
  local centerX = Round(x/2)
  local centerY = Round(y/2)

  -- input for entering IP
  local ipInput = suit.Input(ipInputText, centerX-150, centerY-50, 300, 30)

  -- label above ipInput
  suit.Label('Enter the host IP here.', centerX-150, centerY-80, 300, 30)
  
  -- button to connect
  suit.layout:reset(centerX-75,y-40)
  local connectButton = suit.Button('Connect', suit.layout:row(150,20))
  -- logic for hitting the button
  if connectButton.hit then
      print('Connecting to: '..ipInputText.text)
      connectToHost(ipInputText.text)
      if Connected == false then
          -- if connection failed, tell the user
          ConnectionFailed = true
      end
  end

  -- helps tell the user if connection failed
  if ConnectionFailed then
      suit.Label('Connection failed! :(', centerX-150, centerY-110, 300, 30)
  end
end

function ConnectScreen.draw()
    suit.draw()
end

return ConnectScreen