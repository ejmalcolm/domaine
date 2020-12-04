-- The starting place for the server.
-- Lobby hosting, channel management, and shunting into match hosting.

local sock = require("sock")

function love.load()
  tickRate = 1/120
  tick = 0
  Server = sock.newServer("*", 22122, 64, 32)
end

function love.update(dt)

end

function love.draw()

end