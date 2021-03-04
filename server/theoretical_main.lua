-- The starting place for the server.
-- Lobby hosting, channel management, and shunting into match hosting.

local sock = require("sock")
local inspect = require("inspect")

function getPeer(client)
  -- * returns the enet peer object associated with the given client
  -- ? i have 0 idea why this isn't in the base package
  return LobbyServer:getPeerByIndex(client:getIndex())
end

function love.load()
  ActiveLobbies = {}
  ConnectedClients = {}

  tickRate = 1/120
  tick = 0
  LobbyServer = sock.newServer("*", 22122, 64, 32)


  LobbyServer:on("connect", function(data, client)
    print('Connection received from client.')
    ConnectedClients[client.connectId] = client
  end)

  LobbyServer:on("createLobby", function(lobbyData, client)
    lobbyData.ID = #ActiveLobbies+1
    table.insert(ActiveLobbies, lobbyData)
  end)

  LobbyServer:on("joinLobby", function(lobby, client)

    local host = ConnectedClients[lobby.hostName]
    local hostPeer, clientPeer = getPeer(host), getPeer(client)
    LobbyServer:sendToPeer(hostPeer, "linkToEnemy", client.connectId)
    LobbyServer:sendToPeer(clientPeer, "linkToEnemy", host.connectId)

  end)

  LobbyServer:on("requestActiveLobbies", function(data, client)
    local peer = getPeer(client)
    LobbyServer:sendToPeer(peer, "updateActiveLobbies", ActiveLobbies)
  end)

end

function love.update(dt)
  LobbyServer:update()
end

function love.draw()

end