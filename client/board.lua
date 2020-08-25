local board = {}

local suit = require("suit")

function board.setContent(tile, newContent)
	-- set a given tile's content to the given newContent
	tile.content = newContent
end

function board.load()
	board.lanes = {}


	-- the structures is board.lanes.LANENAME.[TILE#]
	-- where LANENAME = r, y, g
	-- TILE# = 1, 2, 3
	for k1, lane in pairs({'r', 'y', 'g'}) do
		board.lanes[lane] = {}
		for k2, _ in pairs( {'_', '_', '_'} ) do
			-- define the tile
			board.lanes[lane][k2] = {}
			-- fancy coordinate mathematics not really fancy
			board.lanes[lane][k2].rect = {10+(315*(k1-1)), 75+(105*(k2-1)), 100, 100}
			board.lanes[lane][k2].content = {}
			-- set the color
			if lane == 'r' then
				board.lanes[lane][k2].color = {1, 0, 0}
			elseif lane == 'y' then
				board.lanes[lane][k2].color = {1, 1, 0}
			elseif lane == 'g' then
				board.lanes[lane][k2].color = {0,.5,0}
			end
		end
	end

end

function board.update(dt)
	-- for each line
	for _, lane in pairs(board.lanes) do
	-- for each tile in the lane
		for _, tile in pairs(lane) do
			-- create a Button for each unit inside
			suit.layout:reset(tile.rect[1]+5, tile.rect[2]+5)
			for unitKey, unitName in pairs(tile.content) do
				suit.Button(unitName, {id = unitKey..unitName}, suit.layout:row(90,15))
			end
		end
	end
end

function board.draw()
	-- first, get each lane
	for k, lane in pairs(board.lanes) do
		-- then, get each tile in that lane
		for _, tile in pairs(lane) do
			love.graphics.setColor(tile.color)
			love.graphics.rectangle('line', unpack(tile.rect))
		end
	end

	suit.draw()
end

return board
