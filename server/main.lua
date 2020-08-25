sock = require "sock"

function love.load()
    -- how often an update is sent out
    tickRate = 1/60
    tick = 0

    server = sock.newServer("*", 22122, 2)

    server:on("connect", function(data, client)
        -- Send a message back to the connected client
        local msg = "Hello from the server!"
        client:send("hello", msg)
    end)
end

function love.update(dt)
    server:update()
end

function love.draw()
end