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

  }

end


function BrowseLobbies.update()

  suit.layout:reset(centerX-75, 100)
  suit.Label('Available Lobbies', suit.layout:row(150,20))


  -- create a listing on the browser
  for _, lobby in pairs(ActiveLobbies) do

    BGSuit.layout:reset(centerX-345, centerY-220)
    BGSuit.layout:padding(1)

    local bgButton = BGSuit:Button('', BGSuit.layout:col(690, 40))
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

end

function BrowseLobbies.draw()

  -- background of browser
  love.graphics.setColor(2/10,2/10,2/10)
  love.graphics.rectangle('fill', centerX-350, centerY-230, 700, 400, 5, 5)

  love.graphics.setColor(1,1,1)
  BGSuit:draw()
  suit.draw()

end

return BrowseLobbies