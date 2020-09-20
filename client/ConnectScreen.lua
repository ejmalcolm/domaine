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
  ipInputText = {text = ""}
end

function ConnectScreen.update(dt)
  local x,y = love.graphics.getDimensions()
  local centerX = Round(x/2)
  local centerY = Round(y/2)

  -- input for entering IP
  local ipInput = suit.Input(ipInputText, centerX-150, centerY-50, 300, 30)

  -- label above ipInput
  suit.Label('Enter the host IP here.', centerX-150, centerY-80, 300, 30)

  -- check if the server is Ready
  -- this has to be outside the connectButton logic because else changeScreen happens
  -- before the server and client are acutally revved up/ready to go
  if Ready then
      -- one at a time, add each unit from unitPlacement into the matching starting Tile
      for _, tile in pairs({'r', 'y', 'g'}) do
          for _, unit in pairs(unitPlacement.pRects[tile].content) do
              client:send("createUnitOnTile", {unit, tile..'A'})
          end
      end
      -- set screen to board once everything's ready
      changeScreen(board)
  end

  -- button to connect
  local connectButton = suit.Button('Connect', centerX-50, centerY-10, 100, 20)
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