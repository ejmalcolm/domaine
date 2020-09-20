local sock = require "sock"
local inspect = require("inspect")

UnitList = require("unitList")
AscendantList = require("ascendantList")

Gamestate = {}

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
  return tile, laneCode..tileCode
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

function FindUnitByID(uidToFind)
  -- TODO: optimize, only run tiles that have units in them?
  for laneKey, lane in pairs(MasterLanes) do
    for tileKey, tile in pairs(lane) do
      -- optimization: if a tile has nothing in it, skip it
      if not tile.content then goto nextTile end

      for unitKey, unit in pairs(tile.content) do
        if unit.uid == uidToFind then return unit end
      end

      ::nextTile::
    end
  end
  -- if no unit is found, return false
  return false
end

-- ! EVENT HANDLER

Gamestate['DeadUnits'] = {}

function handleEvent(eventName, data)
  -- * handles various events that occur in the game

  if eventName == 'unitDeath' then
    local client, killer, kTile, victim, vTile = unpack(data)

    -- ! killer side-effects
    -- SACRAMENT'S CHOSEN
    if not Gamestate['Chosen'..killer.player] then
      -- check if there actually is a chosen
      goto noChosen
    end
    if killer.uid == Gamestate['Chosen'..killer.player]['currentChosen'] then
      -- increment atk and hp
      killer.attack = killer.attack + 1
      killer.health = killer.health + 1
      -- increment the # of unitsKilled by the Chosen by 1 for victory con
      local newKilled = Gamestate['Chosen'..killer.player]['unitsKilled'] + 1
      Gamestate['Chosen'..killer.player]['unitsKilled'] = newKilled
      -- * note that when we update, we have to send the entire table over, not just the field we're editing
      -- * this is because we can only update the whole 'Chosen' field, not a specific attribute of it
      -- * coding limitations, but nbd
      server:sendToAll("updateVar", {'Chosen'..killer.player, {currentChosen=killer.uid, unitsKilled=newKilled} })
      -- "replace" the old killer with the new upgraded one
      kTile.content[findUnitIndex(killer, kTile)] = killer
    end
    ::noChosen::

    -- ! actually kill the victim
    -- add to the list of dead units and update that for everyone
    table.insert(Gamestate['DeadUnits'], victim)
    server:sendToAll("updateVar", {'DeadUnits', Gamestate['DeadUnits']})
    -- remove victim from tile
    table.remove(vTile.content, findUnitIndex(victim, vTile))
    -- alert the player
    server:sendToPeer(getPeer(client), "createAlert",
                      {killer.name..' killed '..victim.name, 5})
  end

  if eventName == 'unitMove' then
    local mover, oldTileRef, newTileRef = unpack(data)

    -- ! special side effects
    -- * the Chain's side effect
    -- if the mover has a Chain attached
    if mover.specTable.tags["chain|AttachedTo"] then
      -- first, we find the Chain unit
      local chainUnit = FindUnitByID(mover.specTable.tags["chain|AttachedTo"])
      -- then, we move the Chain unit to the newTileRef
      removeUnitFromTile(chainUnit, oldTileRef)
      addUnitToTile(chainUnit, newTileRef)
    end
  
  end

end


-- ! LOVE FUNCTIONS

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

  -- ! MANAGING THE BOARD

  -- create the master copy of the lanes
  CreateMasterLanes()
   -- TODO: remove
  -- MasterLanes['y'][3].content = {
  --   {uid='1', name='1', player=2, cost=1, attack=2, health=4, tile='y3', specTable={shortDesc=2, fullDesc=1, tags={} } },
  --   {uid='2', name='2', player=2, cost=1, attack=2, health=4, tile='y3', specTable={shortDesc=2, fullDesc=1, tags={} } },
  --   {uid='3', name='3', player=2, cost=1, attack=2, health=4, tile='y3', specTable={shortDesc=2, fullDesc=1, tags={} } }
  --                               }
  -- TODO: remove

  -- {uid=unitName..UnitCount,name=unitName,
  -- player=getPlayer(client),cost=cst,attack=atk,
  -- health=hp,tile=tileRef,specTable=special}


  server:on("createUnitOnTile", function(data, client)
    --used to create a unit from just a unit name, assigning it a UnitCount and its default stats
    print('Received createUnitOnTile')
    local unitName, tileRef = data[1], data[2]
    print('Creating '..unitName..' on tile '..tileRef)
    -- * tileRef is in form 'rA'
    -- * we need to convert it before setting the units stored reference
    local spawnTile, newRef = tileRefToTile(tileRef, client)
    UnitCount = UnitCount + 1
    -- calculate the statistics of the unit by referencing unitList
    local unitRef = UnitList[unitName]
    local cst, atk, hp, special = unitRef[1], unitRef[2], unitRef[3], unitRef.special
    local unit = {uid=unitName..UnitCount,name=unitName,player=getPlayer(client),cost=cst,attack=atk,health=hp,tile=newRef,specTable=special}
    table.insert(spawnTile.content, unit)
    -- send out the updated board
    server:sendToAll("updateLanes", MasterLanes)
  end)

  function addUnitToTile(unit, tileRef)
    -- * used to add an already-existing unit table to a tile
    local tile = tileRefToTile(tileRef)
    -- update the stored tileRef
    unit.tile = tileRef
    -- insert the unit
    table.insert(tile.content, unit)
  end

  function removeUnitFromTile(unit, tileRef)
    print('Received removeUnitFromTile')
    local tile = tileRefToTile(tileRef)
    local index = findUnitIndex(unit, tile)
    table.remove(tile.content, index)
  end

  server:on("printReceivedArgs", function(data, client)
    -- just used to check different args
    for k,v in pairs(data) do
      print(v)
    end
  end)

  -- ! BASIC UNIT ACTIONS

  server:on("unitAttack", function(data, client)
    -- * used for one unit to attack another
    print('Received unitAttack')
    -- define variables
    local attacker, defender, doNotCheckRange = unpack(data)
    local attackerTileRef, defenderTileRef = attacker.tile, defender.tile
    local newDefenderHP = defender.health - attacker.attack
    local attTile = tileRefToTile(attackerTileRef, client)
    local defTile = tileRefToTile(defenderTileRef, client)
    local dIndex = findUnitIndex(defender, defTile)

    -- hunter special
    -- ? do we really want to have this here?
    -- ? if we have to do another case like this, switch to having a TargetPicked() event
    -- ? otherwise, i guess it's okay for now
    if defender.specTable['tags']['hunter|MarkedBy'] == attacker.uid then goto skipRange end
    -- generic checking for doNotCheckRange
    if not doNotCheckRange then goto skipRange end
    -- check range
    if distanceBetweenTiles(attTile, defTile) ~= 0 then
      -- if not, print an error here and send an alert over to client
      print('Attack target was out of range')
      server:sendToPeer(getPeer(client), "createAlert", {'Target out of range', 5})
      return false
    end
    ::skipRange::


    if newDefenderHP <= 0 then
      -- * if the HP is zero or below, call the Death event
      handleEvent('unitDeath', {client, attacker, attTile, defender, defTile})
    else
      -- * if the HP is above zero, change the HP stat
      print(defender.uid.. ' now has '..newDefenderHP..' health')
      -- find the unit in place, set the new HP
      defTile.content[dIndex]['health'] = newDefenderHP
      server:sendToPeer(getPeer(client), "createAlert",
            {defender.name..' now has '..newDefenderHP..' HP', 5})
    end
    -- use a primary action
    server:sendToPeer(getPeer(client), "actionUsed", 'primary')
    -- update the board
    server:sendToAll("updateLanes", MasterLanes)
  end)

  server:on("unitMove", function(data, client)
    print('Received unitMove')
    local unit, oldTileRef, newTileRef = data[1], data[2], data[3]
    -- remove from old tile
    removeUnitFromTile(unit, oldTileRef)
    -- add to new tile
    addUnitToTile(unit, newTileRef)
    -- handle the unit movement event
    handleEvent("unitMove", {unit, oldTileRef, newTileRef})
    -- update the board
    server:sendToAll("updateLanes", MasterLanes)
  end)

  server:on("modifyUnitTable", function(data, client)
    print('Received modifyUnitTable')
    -- * used to modify a field of a unit, e.g. health, atk, name, spectable
    local unit, field, newValue = unpack(data)
    -- find the unit in place, set the new value
    local tile = tileRefToTile(unit.tile)
    local index = findUnitIndex(unit, tile)
    tile.content[index][field] = newValue
    server:sendToAll("updateLanes", MasterLanes)
  end)

  -- ! TURN SYSTEM

  server:on("useAction", function (data, client)
    local actionType, actionUser, reason = unpack(data)
    server:sendToPeer(getPeer(client), "actionUsed", actionType)
  end)

  CurrentTurnTaker = 1

  server:on("endMyTurn", function(data, client)
    print('Received endMyTurn')
    -- * the signal that the client has completed their turn
    -- * also manages victory/defeat checks
    -- check if victory condition is achieved
    for player,_ in pairs(Players) do
      local playerAscendant = Gamestate['Ascendant'..player]
      local asc = AscendantList[playerAscendant]
      if asc.victoryFunc(player) then
        local winner = getPeer(Players[player])
        server:sendToPeer(winner, "youWin", {})
      end
    end
    -- TODO: some internal turn management
    -- the second argument is the player ID (numbers for now)
    local newTurnTaker
    if client:getIndex() == 1 then newTurnTaker = 2
    elseif client:getIndex() == 2 then newTurnTaker = 1 end
    CurrentTurnTaker = newTurnTaker
    print('It is now '..newTurnTaker.."'s turn.")
    server:sendToAll("setPlayerTurn", newTurnTaker)
  end)

  -- ! COMMUNICATE WITH CLIENT

  server:on("updateVar", function(data)
    local varName, varValue = data[1], data[2]
    Gamestate[varName] = varValue
    end)

end

function love.update(dt)
  server:update()
end

function love.draw()
  love.graphics.print('Server running...',10,20)
end