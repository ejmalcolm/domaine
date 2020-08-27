menu = require("menu")
board = require("board")
buildArmy = require("buildArmy")
unitPlacement = require('unitPlacement')
connectScreen = require('ConnectScreen')

suit = require("suit")
local sock = require("sock")
local currentScreen

function sleep(n)
    -- only works in windows
    if n > 0 then os.execute("ping -n " .. tonumber(n+1) .. " localhost > NUL") end
end

function love.load()
    love.keyboard.setKeyRepeat(true)
	currentScreen = menu
    love.window.setMode(750, 500)
    love.window.setTitle('Domaine')
end

function changeScreen(screen)
    currentScreen = screen
end

function connectToHost(ip)
    -- create the client
    tickRate = 1/60
    tick = 0
    client = sock.newClient(ip, 22122)

    -- on connection
    client:on("connect", function(data)
        print('Successfully connected!')
    end)

    --for getting the player index (p1 or p2)
    client:on("setUpGame", function(num)
        playerNumber = num
        print('Client number: '..playerNumber)
        -- once the client knows what number it is, it's ready to go
        Ready = true
    end)

    -- * BOARD FUNCTIONS

    -- when called, the client updates its copy of the Lanes to match the server's
    client:on("updateLanes", function(UpdatedLanes)
        board.lanes = UpdatedLanes
    end)

    -- actually connect
    local function dummyConnect()
        client:connect()
    end

    -- if connection works (pcall stops any errors from crashing)
    if pcall(dummyConnect) then
        Connected = true
    else
        print('Connection failed')
    end
end

function love.update(dt)
    -- control the multiplayer stuff
    if Connected then
        client:update()
    end
    currentScreen.update(dt)
end

function love.draw()
	currentScreen.draw()
end
