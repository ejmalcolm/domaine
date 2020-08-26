sock = require "sock"

function CreateMasterLanes()
	MasterLanes = {}


	-- the structures is MasterLanes.LANENAME.[TILE#]
	-- where LANENAME = r, y, g
	-- TILE# = 1, 2, 3
	for k1, lane in pairs({'r', 'y', 'g'}) do
		MasterLanes[lane] = {}
		for k2, _ in pairs( {'_', '_', '_'} ) do
			-- define the tile
			MasterLanes[lane][k2] = {}
			-- fancy coordinate mathematics not really fancy
			MasterLanes[lane][k2].rect = {10+(315*(k1-1)), 75+(105*(k2-1)), 100, 100}
			MasterLanes[lane][k2].content = {}
			-- set the color
			if lane == 'r' then
				MasterLanes[lane][k2].color = {1, 0, 0}
			elseif lane == 'y' then
				MasterLanes[lane][k2].color = {1, 1, 0}
			elseif lane == 'g' then
				MasterLanes[lane][k2].color = {0,.5,0}
			end
		end
	end

end

function love.load()
    -- how often an update is sent out
    tickRate = 1/120
    tick = 0

    server = sock.newServer("*", 22122, 2)

    server:on("connect", function(data, client)
        print('Client connected')
        -- Assigns an index (player 1 or player 2) and send it to client
        -- Sets "Ready" to true (making the game start)
        client:send("setUpGame", client:getIndex())
    end)

    server:on("disconnect", function(data)
        print('Client disconnected from server.')
        client:send("disconnect", data)
    end)

    -- * board functions

    -- create the master copy of the lanes
    CreateMasterLanes()
 
    server:on("addUnitToTile", function(data)
        --used to add a unit to a new tile
        print('Received addUnitToTile')
        local unitName, tileRef = data[1], data[2]
        print('Adding '..unitName..' to tile '..tileRef)
        -- ! translate the alphabetic tileRef to the actual tile using client index
        local tile = MasterLanes.r[1]
        table.insert(tile.content, unitName)
        -- send out the updated board
        server:sendToAll("updateLanes", MasterLanes)
    end)

end

function love.update(dt)
    server:update()
end

function love.draw()
    love.graphics.print('Server running...',10,20)
end