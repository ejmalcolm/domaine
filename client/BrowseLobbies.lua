local BrowseLobbies = {}

function BrowseLobbies.load()

  BGSuit = suit.new()

  TestAvatar = love.graphics.newImage('images/avatar.png')

  ActiveLobbies = {

    {hostAvatar=TestAvatar,
    hostName='[username]',
    privacy='Open',
    timeSince='<1h',
    gameType='Standard'},

    {hostAvatar=TestAvatar,
    hostName='[username]',
    privacy='Open',
    timeSince='<1h',
    gameType='Standard'},

  }

  -- a list of all server channels currently being used (games in progress)
  ActiveServerChannels = {0}

end


function BrowseLobbies.update(dt)

  suit.layout:reset(centerX-75, 100)
  suit.Label('Available Lobbies', suit.layout:row(150,20))


  -- create listings on the browser
  BGSuit.layout:reset(centerX-345, centerY-220)
  BGSuit.layout:padding(3)
  for k, lobby in pairs(ActiveLobbies) do


    local bgButton = BGSuit:Button('', {id='lobby'..k}, BGSuit.layout:row(690, 40))
    local x, y = bgButton.x, bgButton.y

    suit.layout:reset(x+7, y+4)
    local avatar = suit.ImageButton(lobby.hostAvatar, suit.layout:col(32,32))

    suit.layout:reset(x+45, y+10)
    local username = suit.Label(lobby.hostName, suit.layout:col(100,20))
    local privacy = suit.Label(lobby.privacy, suit.layout:col(100,20))

    suit.layout:reset(centerX+245, y+10)
    local timeSinceCreation = suit.Label(lobby.timeSince, suit.layout:col(100,20))
    local gameType = suit.Label(lobby.gameType, suit.layout:left(100,20))

  end

  -- create "host lobby" button
  suit.layout:reset(centerX+225, centerY+175)
  local hostButton = suit.Button('Host Lobby', suit.layout:row(125,25))
  if hostButton.hit then
    client:setSendChannel(#ActiveServerChannels+1)
  end


end

function BrowseLobbies.draw()

  -- background of browser
  love.graphics.setColor(1/10,1/10,1/10)
  love.graphics.rectangle('fill', centerX-350, centerY-230, 700, 400, 5, 5)

  love.graphics.setColor(1,1,1)
  BGSuit:draw()
  suit.draw()

end

return BrowseLobbies