sock = require "sock"

UnitList = require("unitList")

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

    Players = {}

    server:on("connect", function(data, client)
        print('Client connected')
        -- Decide if the client is Player 1 or Player 2
        -- Set "Ready" to true (starts the game)
        if Players[1] then
            print('Player 2 assigned.')
            Players[2] = client
            client:send("setUpGame", 2)
        else
            print('Player 1 assigned.')
            Players[1] = client
            client:send("setUpGame", 1)
        end
    end)

    -- used to keep track of how many unit there are
	UnitCount = 0

    -- * utility functions

    function getPlayer(client)
        if Players[1] == client then
            return 1
        elseif Players[2] == client then
            return 2
        else
            print('Error determining player')
            error()
        end
    end

    function tileRefToTile(tileRef, client)
        -- translates a tileRef (rA or r1) to an actual tile (MasterLanes.r[1])
        -- first, handle the r1 case
        -- we check if the second character is a number through tonumber
        -- returns nil if its a string
        if not (tonumber(tileRef:sub(2,2)) == nil) then
            local laneCode = tileRef:sub(1,1)
            local tileCode = tonumber(tileRef:sub(2,2))
            local tile = MasterLanes[laneCode][tileCode]
            return tile
        end
        -- then, handle the rA case
        local translator
        if Players[1] == client then
            translator = {A=3, B=2, C=1}
        elseif Players[2] == client then
            translator = {A=1, B=2, C=3}
        else
            print('Error determining player in tileRefToActual')
            error()
        end
        local laneCode = tileRef:sub(1,1)
        local tileCode = translator[tileRef:sub(2,2)]
        local tile = MasterLanes[laneCode][tileCode]
        return tile     
    end

    -- * board functions

    -- create the master copy of the lanes
    CreateMasterLanes()

 	-- {uid= 'Rand0', name='Rand', player=1, cost=2, attack=3, health=6}

    server:on("createUnitOnTile", function(data, client)
        --used to create a unit from just a unit name, assigning it a UnitCount and its default stats
        print('Received createUnitOnTile')
        local unitName, tileRef = data[1], data[2]
        print('Creating '..unitName..' on tile '..tileRef)
        -- tileRef is in form 'rA'
        local tile = tileRefToTile(tileRef, client)
        UnitCount = UnitCount + 1
        -- calculate the statistics of the unit by referencing unitList
        local unitRef = UnitList[unitName]
        print(unitRef)
        local cst, atk, hp = unitRef[1], unitRef[2], unitRef[3]
        table.insert(tile.content, {uid=unitName..UnitCount,name=unitName,player=getPlayer(client),cost=cst,attack=atk,health=hp})
        -- send out the updated board
        server:sendToAll("updateLanes", MasterLanes)
    end)

    server:on("addUnitToTile", function(data, client)
        -- used to add an already-existing unit table to a tile
        print('Received addUnitToTile')
        local unit, tileRef = data[1], data[2]
        local tile = tileRefToTile(tileRef)
        -- we have the unit table already
        table.insert(tile.content, unit)
        -- update the board
        server:sendToAll("updateLanes", MasterLanes)
    end)

    server:on("removeUnitFromTile", function(data, client)
        -- used to remove a unit from a tile
        print('Received removeUnitFromTile')
        local unit, tileRef = data[1], data[2]
        local tile = tileRefToTile(tileRef)
        -- we have the uid, 'Rand0'
        for index, unitTable in pairs(tile.content) do
            -- find the thing in the content table
            if unitTable.uid == unit.uid then
                -- once we've found it, remove the unit
                table.remove(tile.content, index)
            end
            -- update the board
            server:sendToAll("updateLanes", MasterLanes)
        end
    end)


end

function love.update(dt)
    server:update()
end

function love.draw()
    love.graphics.print('Server running...',10,20)
end