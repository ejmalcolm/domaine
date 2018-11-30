menu = require("menu")
board = require("board")
buildArmy = require("buildArmy")

local currentScreen

function love.load()
	currentScreen = menu
	love.window.setMode(750, 500)
    love.window.setTitle('Domaine')
    --this has to be moved eventually
	board.load()
end

function changeScreen(screen)
    currentScreen = screen
end

function love.update(dt)
    currentScreen.update(dt)
end

function love.draw()
	currentScreen.draw()
end
