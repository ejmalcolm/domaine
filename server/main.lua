local sock = require "sock"
inspect = require("inspect")

UnitList = require("unitList")
AscendantVictories = require("AscendantVictories")

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
    return tile, tileRef
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

local function adjacentLanes(lane1, lane2)
  -- * note: lanes are not adjacent to themselves
  if lane1 == 'r' then
    if lane2 ~= 'y' then return false end
  elseif lane1 == 'g' then
    if lane2 ~= 'y' then return false end
  elseif lane1 == 'y' then
    -- only lane not adjacent to yellow is itself
    if lane2 == 'y' then return false end
  end
  return true
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

-- * obtains the specRefs of the unit associated with the given event
-- * e.g. getSpecRef(knight, "onAttack") -> onAttack|knightPassive -> "knightPassive"
local function getSpecRefs(unit, event)
  local tags = unit.specTable['tags']
  local specRefs = {}
  for tag, _ in pairs(tags) do
    -- oh god, regex. just splits on | basically
    local tagEvent = string.gmatch(tag, '[^%|]*')()
    local specRef = string.gmatch(tag, '%|(.*)')()
    if event == tagEvent then table.insert(specRefs, specRef) end
  end
  -- check if there are any specRefs that matched
  -- if not, return false, else, return the specRefs table
  if #specRefs==0 then return false else return specRefs end
end

function handleEvent(eventName, unitsInvolved, data)
  -- * handles various events that occur in the game

  if eventName == 'unitDeath' then
    for _, unit in pairs(unitsInvolved) do
      table.insert(MatchState.DeadUnits, unit)
    end
    server:sendToAll("updateVar", {'global', 'DeadUnits', MatchState.DeadUnits})
  end

  for _, unit in pairs(unitsInvolved) do
    -- get the specRef associated with the event being handled
    -- returns false if the unit has no tag for this event
    local specRefs = getSpecRefs(unit, eventName)
    if specRefs then
      for _, specRef in pairs(specRefs) do
        local client = Players[unit.player]
        server:sendToPeer(getPeer(client), "callSpecFunc", {specRef, data})
      end
    end
  end

end


-- ! LOVE FUNCTIONS

function love.load()
  -- how often an update is sent out
  tickRate = 1/120
  tick = 0

  server = sock.newServer("*", 22122, 2, 10)

  Players = {}

  MatchState = {}
  MatchState.DeadUnits = {}
  MatchState.Player1 = {}
  MatchState.Player2 = {}

  server:on("connect", function(data, client)
    print('Connection received from client.')
    -- Decide if the client is Player 1 or Player 2
    -- Set "Ready" to true (starts the game)
    local index
    if Players[1] then
      index = 2
    else
      index = 1
    end
    -- Tell client to what player it is, sets client Ready to true
    Players[index] = client
    client:send("setUpGame", index)
  end)

  server:on("transferPreMatchData", function(PreMatchData, client)
    print('Receieved transferPreMatchData')
    local pNum = getPlayer(client)
    MatchState['Player'..pNum] = PreMatchData
    -- !FOR TESTING ONLY
    Players[2] = true
    MatchState['Player2'] = {ActionTable={1,1,1},AscendantIndex=2,HasIncarnatePower=true,HasMajorPower=true,HasMinorPower=true}
  end)

  -- used to keep track of how many unit there are
  UnitCount = 0

  -- ! MANAGING THE BOARD

  -- create the master copy of the lanes
  CreateMasterLanes()
   -- TODO: remove
  MasterLanes['y'][3].content = {
    {uid='1', name='Siren', player=2, cost=1, attack=2, health=1, tile='y3', specTable={shortDesc=2, fullDesc=1, tags={} } },
    {uid='2', name='2', player=2, cost=1, attack=2, health=1, tile='y3', specTable={shortDesc=2, fullDesc=1, tags={} } },
    {uid='3', name='3', player=2, cost=1, attack=2, health=1, tile='y3', specTable={shortDesc=2, fullDesc=1, tags={} } }
                                }
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
    local cst, atk, hp, cM, cA, cS, special = unitRef[1], unitRef[2], unitRef[3], unitRef.canMove, unitRef.canAttack, unitRef.canSpecial, unitRef.special
    local unit = {uid=unitName..UnitCount,name=unitName,player=getPlayer(client),cost=cst,
                  attack=atk,health=hp,tile=newRef,canMove=cM,canAttack=cA,canSpecial=cS,
                  specTable=special}
    table.insert(spawnTile.content, unit)

    -- trigger a unitCreated event
    server:sendToPeer(getPeer(client), "TriggerEvent", {'unitCreated', unit} )

    -- send out the updated board
    server:sendToAll("updateLanes", MasterLanes)
  end)

  server:on("addUnitToTile", function(data, client)
    print('Received addUnitToTile')
    -- add the unit
    local unit, newRef = unpack(data)
    addUnitToTile(unit, newRef)
    -- update the board
    server:sendToAll("updateLanes", MasterLanes)
  end)

  server:on("removeUnitFromTile", function(data, client)
    print('Received removeUnitFromTile')
    -- remove the unit
    local unit = data[1]
    local tileRef = (data[2] or unit.tile)
    removeUnitFromTile(unit, tileRef)
    -- update the board
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
    print('Server removeUnitFromTile')
    local tileRef = tileRef or unit.tile
    local tile = tileRefToTile(tileRef)
    local index = findUnitIndex(unit, tile)
    table.remove(tile.content, index)
  end



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

    -- unit damaged by event
    handleEvent("unitDamaged", {defender, attacker}, {'attack', defender, attacker})

    if newDefenderHP <= 0 then
      -- * if the HP is zero or below, kill them
      -- remove the unit
      removeUnitFromTile(defender)
      -- call the events
      handleEvent("unitKill", {attacker}, {attacker})
      handleEvent("unitDeath", {defender}, {defender})
      local contentHardCopy = defTile.content
      for _, unit in pairs(contentHardCopy) do
        print(unit.name)
        -- don't call this event for the actual unit dying
        if unit.uid ~= defender.uid then
          handleEvent("unitDeathInTile", {unit}, {unit, defender, attacker})
        end
      end
    else
      -- * if the HP is above zero, change the HP stat
      print(defender.uid.. ' now has '..newDefenderHP..' health')
      -- find the unit in place, set the new HP
      defTile.content[dIndex]['health'] = newDefenderHP
      server:sendToPeer(getPeer(client), "createAlert",
            {defender.name..' now has '..newDefenderHP..' HP', 5})
    end
    -- update the board
    server:sendToAll("updateLanes", MasterLanes)
  end)

  server:on("unitMove", function(data, client)
    print('Received unitMove')
    local unit, oldTileRef, newTileRef = data[1], data[2], data[3]

    -- first, we check unitMoveIn and unitMoveOut for all units in the old and new tile
    local oldTile, newTile = tileRefToTile(oldTileRef), tileRefToTile(newTileRef)
    local outUnits = {}

    for _, oldUnit in pairs(oldTile.content) do
      -- note that outUnits contains the moving unit self
      table.insert(outUnits, oldUnit)
    end

    for _, newUnit in pairs(newTile.content) do
      handleEvent("unitMoveIn", {newUnit}, {unit, oldTileRef, newTileRef, newUnit})
    end

    handleEvent("unitMoveOut", outUnits, {unit, oldTileRef, newTileRef})

    -- ! actual movement
    -- remove from old tile
    removeUnitFromTile(unit, oldTileRef)
    -- add to new tile
    addUnitToTile(unit, newTileRef)


    -- handle the unit movement event
    handleEvent("unitMove", {unit}, {unit, oldTileRef, newTileRef})
    -- update the board
    server:sendToAll("updateLanes", MasterLanes)
  end)

  -- * server-side version of below
  function modifyUnitTable(unit, field, newValue)
    -- find the unit in place, set the new value
    local tile = tileRefToTile(unit.tile)
    local index = findUnitIndex(unit, tile)
    tile.content[index][field] = newValue
    server:sendToAll("updateLanes", MasterLanes)
  end

  -- * used to modify a field of a unit, e.g. health, atk, name, spectable
  server:on("modifyUnitTable", function(data, client)
    print('Received modifyUnitTable')
    local unit, field, newValue = unpack(data)
    assert(unit, 'Unit missing in a client modifyUnitTable call.')
    -- find the unit in place, set the new value
    local tile = tileRefToTile(unit.tile)
    local index = findUnitIndex(unit, tile)
    -- first we check that the unit exists. if it doesn't and we try to change, it'll crash
    if not tile.content[index] then print('modifyunittable error') return false end
    tile.content[index][field] = newValue
    -- if health, we have to check for death
    if (field == 'health') and newValue <= 0 then
      server:sendToAll("createAlert", {unit.name..' was killed.', 5})
      removeUnitFromTile(unit, unit.tile)
    end
    server:sendToAll("updateLanes", MasterLanes)
  end)

  -- * finds a unit by ID, then modifies that unit's table
  -- * useful when a unit may have moved in between the event call and this function
  server:on("modifyUnitTableByID", function(data, client)
    print('Received modifyUnitTableByID')
    local UID, field, newValue = unpack(data)
    assert(UID, 'UID missing in a client modifyUnitTable call.')
    -- find the unit in place, set the new value
    local unit = FindUnitByID(UID)
    local tile = tileRefToTile(unit.tile)
    local index = findUnitIndex(unit, tile)
    -- first we check that the unit exists. if it doesn't and we try to change, it'll crash
    if not tile.content[index] then print('modifyunittable error') return false end
    tile.content[index][field] = newValue
    -- if health, we have to check for death
    if (field == 'health') and newValue <= 0 then
      server:sendToAll("createAlert", {unit.name..' was killed.', 5})
      removeUnitFromTile(unit, unit.tile)
    end
    server:sendToAll("updateLanes", MasterLanes)
  end)

  -- * used to examine whether a given unit is a valid target for a certain set of conditions
  server:on("unitTargetCheck", function(data, client)
    -- * unit is a unit table.
    -- * conditions is a table containing fields that specify what conditions need to be met
    local unit, origin, conditions, data2 = unpack(data)
    -- * we go through all the various conditions

    -- * before checking conditions, we check all neighbours
    -- then, we call the UnitTargetedInTile event on every unit in the target's tile
    local tile = tileRefToTile(unit.tile)
    for _, neighbour in pairs(tile.content) do
      handleEvent("unitTargetedInTile", {neighbour}, {neighbour, unit, data2})
    end

    -- ! attack check
    if conditions.canBeAttacked ~= nil then
      local specTable = unit.specTable
      local tags = specTable.tags
      if tags.cannotBeAttacked == true then
        server:sendToPeer(getPeer(client), "createAlert", {'Target cannot be attacked', 3})
        return false
      end
    end

    -- ! vertical distance between
    if conditions.distanceBetweenIs ~= nil then
      local distance = conditions.distanceBetweenIs
      local t1, t2 = tileRefToTile(unit.tile), tileRefToTile(origin.tile)
      if distanceBetweenTiles(t1, t2) ~= distance then
        server:sendToPeer(getPeer(client), "createAlert", {'Target out of range', 3})
        return false
      end
    end

    -- ! horizontal distance between
    if conditions.horizontallyAdjacent ~= nil then
      local t1, t2 = tileRefToTile(unit.tile), tileRefToTile(origin.tile)
      -- check if in same tile
      if t1.t ~= t2.t then server:sendToPeer(getPeer(client), "createAlert", {'Not in adjacent tiles.', 3}) return false end
      -- check if in the same lane
      if not adjacentLanes(t1.l, t2.l) then server:sendToPeer(getPeer(client), "createAlert", {'Not in adjacent tiles.', 3}) return false end
    end

    -- ! self-targeting
    if conditions.canTargetSelf ~= nil then
      if unit.uid == origin.uid then server:sendToPeer(getPeer(client), "createAlert", {'Cannot target self.', 3}) return false end
    end

    
    -- if all is well, we echo back a unique target event
    server:sendToPeer(getPeer(client), "triggerEvent", {unit.uid..'TargetSucceed', {}})
    
    -- before ending, we call the unitTargeted event
    handleEvent("unitTargeted", {unit}, {unit, origin, data2})
  end)

  -- * same as above, but for tiles instead of units
  server:on("tileTargetcheck", function(data, client) end)

  -- ! TURN SYSTEM & QUEUEING ACTIONS

  CurrentTurnTaker = 1 -- what player number starts the game
  MatchState.turnNumber = 0
  TimedEventQueue = {}
  TimedFuncQueue = {}

  server:on("useAction", function (data, client)
    local actionType, actionUser, reason = unpack(data)
    server:sendToPeer(getPeer(client), "actionUsed", actionType)
  end)

  function advanceTurnTimer()
    -- advance the turn number
    MatchState.turnNumber = MatchState.turnNumber + 1
    server:sendToAll("updateVar", {'global', 'turnNumber', MatchState.turnNumber})
    print('Turn Number:', MatchState.turnNumber)

    -- check if there's anything in the EventQueue for this turn
    if not TimedEventQueue[MatchState.turnNumber] then goto noEvents end
    -- if there is, call those events
    for _, eventsTable in pairs(TimedEventQueue[MatchState.turnNumber]) do
      local event, args = unpack(eventsTable)
      server:sendToAll("triggerEvent", {event, args})
    end
    ::noEvents::

    -- check if there's anything for the FuncQueue for this turn
    if not TimedFuncQueue[MatchState.turnNumber] then return end
    -- if there is, call those funcs
    for _, funcTable in pairs(TimedFuncQueue[MatchState.turnNumber]) do
      local func, args = unpack(funcTable)
      func(unpack(args))
    end
  end

  -- * server-side version of below. triggers a server function instead of an event
  function queueTimedFunc(func, turnsFromNow, args)
    local triggerTurn = MatchState.turnNumber + turnsFromNow
    if TimedFuncQueue[triggerTurn] then
      -- if there's already an func(s) queued for that turn, add to that table
      table.insert(TimedFuncQueue[triggerTurn], {func, args})
    elseif not TimedFuncQueue[triggerTurn] then
      -- if no funcs are queued, create a new table entirely
      TimedFuncQueue[triggerTurn] = {{func, args}}
    end
  end

  -- * causes the server to trigger a client Event some turns from now
  server:on("queueTimedEvent", function(data, client)
    print('Received queueTimedEvent')
    local event, turnsFromNow, args = unpack(data)
    local triggerTurn = MatchState.turnNumber + turnsFromNow
    if TimedEventQueue[triggerTurn] then
      -- if there's already an event(s) queued for that turn, add to that table
      table.insert(TimedEventQueue[triggerTurn], {event, args})
    elseif not TimedEventQueue[triggerTurn] then
      -- if no events are queued, create a new table entirely
      TimedEventQueue[triggerTurn] = {{event, args}}
    end
  end)
  
  -- * the signal that the client has completed their turn
  -- * also manages victory/defeat checks
  server:on("endMyTurn", function(data, client)
    print('Received endMyTurn')
    -- check if victory condition is achieved
    for player,_ in pairs(Players) do
      local ascIndex = MatchState['Player'..player]['AscendantIndex']
      local asc = AscendantVictories[ascIndex]
      if asc.victoryFunc(player) then
        local winner = getPeer(Players[player])
        local loser
        for _, player in pairs(Players) do
          if player ~= winner then
            -- ! TESTING
            goto TESTINGONLY
            loser = getPeer(Players[player])
            ::TESTINGONLY::
          end
        end
        server:sendToPeer(winner, "youWin", {})
        -- ! TESTING server:sendToPeer(loser, "youLose", {})
      end
    end
    -- increment the turn timer and activate any queued events
    advanceTurnTimer(client)
    -- the second argument is the player ID (numbers for now)
    local newTurnTaker
    if client:getIndex() == 1 then newTurnTaker = 2
    elseif client:getIndex() == 2 then newTurnTaker = 1 end
    CurrentTurnTaker = newTurnTaker
    print('It is now '..newTurnTaker.."'s turn.")
    -- ! TESTING PURPOSES ONLY
    -- ! CHANGE TO ("setPlayerTurn", newTurnTaker)
    server:sendToAll("setPlayerTurn", 1)
  end)
 
  -- ! COMMUNICATE WITH CLIENT

  server:on("updatePlayerVar", function(data, client)
    print('Received updatePlayerVar')
    local field, value = unpack(data)
    local player = getPlayer(client)
    local PlayerState = MatchState['Player'..player]
    PlayerState[field] = value
    end)

end

function love.update(dt)

  if Players[1] and Players[2] and not MatchStarted then
    server:sendToAll("startMatch", MatchState)
    MatchStarted = true
    advanceTurnTimer()
  end

  server:update()
end

function love.draw()
  love.graphics.print('Server running...',10,20)
end