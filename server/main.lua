local sock = require "sock"
local inspect = require("inspect")

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
            MasterLanes[lane][k2].l = lane
            MasterLanes[lane][k2].t = k2 
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

    -- ! UTILITY FUNCTIONS

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

    function getPeer(client)
        -- * returns the enet peer object associated with the given client
        -- ? i have 0 idea why this isn't in the base package
        return server:getPeerByIndex(client:getIndex())
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
            error('Error determining player in tileRefToActual')
        end
        local laneCode = tileRef:sub(1,1)
        local tileCode = translator[tileRef:sub(2,2)]
        local tile = MasterLanes[laneCode][tileCode]
        return tile     
    end

    function distanceBetweenTiles(tile1, tile2)
        -- * returns the distance between two tiles in the same lane
        -- first, check they're in the same lane
        if tile1.l ~= tile2.l then
            print('Tiles are not in the same lane!')
            return false
        else
            return math.abs(tile1.t - tile2.t)
        end
    end

    function findUnitIndex(unitToFind, tileToSearch)
        for index, unitTable in pairs(tileToSearch.content) do
            -- find the thing in the content table
            if unitTable.uid == unitToFind.uid then
                -- once we've found it, return the index
                return index
            end
        end
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
        local cst, atk, hp, special = unitRef[1], unitRef[2], unitRef[3], unitRef.special
        local unit = {uid=unitName..UnitCount,name=unitName,player=getPlayer(client),cost=cst,attack=atk,health=hp,specTable=special}
        table.insert(tile.content, unit)
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
        local index = findUnitIndex(unit, tile)
        table.remove(tile.content, index)
        -- update the board
        server:sendToAll("updateLanes", MasterLanes)
    end)

    server:on("printReceivedArgs", function(data, client)
        -- just used to check different args
        for k,v in pairs(data) do
            print(v)
        end
    end)

    server:on("unitAttack", function(data, client)
        -- * used for one unit to attack another
        print('Received unitAttack')
        -- define variables
        local attacker, attackerTileRef, defender, defenderTileRef = data[1], data[2], data[3], data[4]
        local newDefenderHP = defender.health - attacker.attack
        local attTile = tileRefToTile(attackerTileRef, client)
        local defTile = tileRefToTile(defenderTileRef, client)
        local dIndex = findUnitIndex(defender, defTile)

        -- make sure they're in the same tile
        if distanceBetweenTiles(attTile, defTile) ~= 0 then
            -- if not, print an error here and send an alert over to client
            print('Attack target was out of range')
            server:sendToPeer(getPeer(client), "createAlert", {'Target out of range', 5})
            return false
        end

        print(defender.uid.. ' now has '..newDefenderHP..' health')
        if newDefenderHP <= 0 then
            -- if the HP is zero or below, delete the unit
            table.remove(defTile.content, dIndex)
            server:sendToPeer(getPeer(client), "createAlert",
                            {attacker.name..' killed '..defender.name, 5})
        else
            -- if the HP is above zero, change the HP stat
            -- find the unit in place, set the new HP
            defTile.content[dIndex]['health'] = newDefenderHP
            server:sendToPeer(getPeer(client), "createAlert",
                        {defender.name..' now has '..newDefenderHP..' HP', 5})
        end
        server:sendToAll("updateLanes", MasterLanes)
    end)


end

function love.update(dt)
    server:update()
end

function love.draw()
    love.graphics.print('Server running...',10,20)
end