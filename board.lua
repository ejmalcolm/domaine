local board = {}

function board.load()
	board.redLane = {}
	board.yellowLane = {}
	board.greenLane = {}

	board.redLane.r1 = {10, 75, 100, 100}
	board.redLane.r2 = {10, 180, 100, 100}
	board.redLane.r3 = {10, 285, 100, 100}

	board.yellowLane.y1 = {325, 75, 100, 100}
	board.yellowLane.y2 = {325, 180, 100, 100}
	board.yellowLane.y3 = {325, 285, 100, 100}

	board.greenLane.b1 = {640, 75, 100, 100}
	board.greenLane.b2 = {640, 180, 100, 100}
	board.greenLane.b3 = {640, 285, 100, 100}
end

function board.draw()
	for k,v in pairs(board.redLane) do
		love.graphics.setColor(1,0,0)
		love.graphics.rectangle('line', unpack(v))
	end
	for k,v in pairs(board.yellowLane) do
		love.graphics.setColor(1,1,0)
		love.graphics.rectangle('line', unpack(v))
	end
	for k,v in pairs(board.greenLane) do
		love.graphics.setColor(0,.5,0)
		love.graphics.rectangle('line', unpack(v))
	end
end

return board