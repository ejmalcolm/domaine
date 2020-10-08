local WaitingScreen = {}

function WaitingScreen.load()
end

function WaitingScreen.update()
end

function WaitingScreen.draw()
  love.graphics.print('Waiting for other player...', (centerX-30), centerY)
end

return WaitingScreen