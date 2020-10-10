local menu = {}

function menu.load()
  ButtonTexture = love.graphics.newImage('images/newButton.png')
end

function menu.update(dt)
  -- basic menu layout:
    -- matchmaking, direct connect, Domainepedia, Options, Exit
  -- set up layout
  suit.layout:reset(centerX-150, 200)
  suit.layout:padding(25)

  -- buttons
  local matchmakingButton = suit.Button("Matchmaking", suit.layout:row(300, 30))

  local directButton = suit.Button("Direct Connect", suit.layout:row())
  if directButton.hit then
    chooseAscendant.load()
    changeScreen(chooseAscendant)
  end

  local sandboxButton = suit.Button("Sandbox", suit.layout:row(300,30))

  local wikiButton = suit.Button("Domainopedia", suit.layout:row(300, 30))

  local optionsButton = suit.Button("Options", suit.layout:row(300, 30))

  local quitButton = suit.Button("Quit", suit.layout:row(300, 30))


end

function menu.draw()
  local logo = love.graphics.newImage('images/logo.png')
  love.graphics.draw(logo, centerX-250, 10)

  suit.draw()
end

return menu
