local sock = require "sock"
inspect = require("inspect")

UnitList = require("unitList")
AscendantVictories = require("AscendantVictories")

function CreateMasterLanes(matchID)
	MatchStateIndex[matchID].MasterLanes = {}

  for k1, lane in pairs({'r', 'y', 'b'}) do
		MatchStateIndex[matchID].MasterLanes[lane] = {}

    for k2, _ in pairs( {'_', '_', '_'} ) do

			-- define the tile
      MatchStateIndex[matchID].MasterLanes[lane][k2] = {}
      MatchStateIndex[matchID].MasterLanes[lane][k2].l = lane
      MatchStateIndex[matchID].MasterLanes[lane][k2].t = k2

      -- {x, y, w, h}
      MatchStateIndex[matchID].MasterLanes[lane][k2].rect = {135+(340*(k1-1)), 45+(213*(k2-1)), 330, 200}
      MatchStateIndex[matchID].MasterLanes[lane][k2].content = {}

			-- set the color
			if lane == 'r' then
				MatchStateIndex[matchID].MasterLanes[lane][k2].color = {1, 0, 0}
			elseif lane == 'y' then
				MatchStateIndex[matchID].MasterLanes[lane][k2].color = {1, 1, 0}
			elseif lane == 'b' then
				MatchStateIndex[matchID].MasterLanes[lane][k2].color = {0,0,1}
      end
		end
	end
end

function SendToMatch(matchID, event, data_to_send)
  for _, CID in pairs(MatchStateIndex[matchID]['ClientIndex']) do
    local peer = GetPeerByCID(CID)
    server:sendToPeer(peer, event, data_to_send)
  end
end

-- ! UTILITY FUNCTIONS

function GetPNumAndMatchID(client)
  -- we look at MatchStateIndex
  for matchID, matchState in pairs(MatchStateIndex) do

    if not matchState['ClientIndex'] then goto skip end
    for pNum, saved_client in pairs(matchState['ClientIndex']) do
      if client.connectId == saved_client then return pNum, matchID end
    end
    ::skip::

  end
  return false
end

function GetPeerByCID(CID)
  -- * returns the enet peer object associated with a connectId
  local client = CIDTranslator[CID]
  return server:getPeerByIndex(client:getIndex())
end

function GetPeerByClient(client)
  -- * returns the enet peer object associated with the given client
  -- ? i have 0 idea why this isn't in the base package
  return server:getPeerByIndex(client:getIndex())
end

function TileRefToTile(client, tileRef)
  -- translates a tileRef (rA or r1) to an actual tile (MasterLanes.r[1])

  local _, matchID = GetPNumAndMatchID(client)
  local masterLanes = MatchStateIndex[matchID].MasterLanes
  local clientIndex = MatchStateIndex[matchID].ClientIndex

  -- first, handle the r1 case
  -- we check if the second character is a number through tonumber
  -- returns nil if its a string
  if not (tonumber(tileRef:sub(2,2)) == nil) then
    local laneCode = tileRef:sub(1,1)
    local tileCode = tonumber(tileRef:sub(2,2))
    local tile = masterLanes[laneCode][tileCode]
    return tile, tileRef
  end
  -- then, handle the rA case
  local translator
  if clientIndex[1] == client.connectId then
    translator = {A=3, B=2, C=1}
  elseif clientIndex[2] == client.connectId then
    translator = {A=1, B=2, C=3}
  else
    error('Error determining player in tileRefToActual')
  end
  local laneCode = tileRef:sub(1,1)
  local tileCode = translator[tileRef:sub(2,2)]
  local tile = masterLanes[laneCode][tileCode]
  return tile, laneCode..tileCode
end

function DistanceBetweenTiles(tile1, tile2)
  -- * returns the distance between two tiles in the same lane
  -- first, check they're in the same lane
  if tile1.l ~= tile2.l then
    return false
  else
    return math.abs(tile1.t - tile2.t)
  end
end

function AdjacentLanes(lane1, lane2)
  -- * note: lanes are not adjacent to themselves
  if lane1 == 'r' then
    if lane2 ~= 'y' then return false end
  elseif lane1 == 'b' then
    if lane2 ~= 'y' then return false end
  elseif lane1 == 'y' then
    -- only lane not adjacent to yellow is itself
    if lane2 == 'y' then return false end
  end
  return true
end

function FindUnitIndex(unitToFind, tileToSearch)
  for index, unitTable in pairs(tileToSearch.content) do
    -- find the thing in the content table
    if unitTable.uid == unitToFind.uid then
      -- once we've found it, return the index
      return index
    end
  end
end

function FindUnitByID(client, uidToFind)
  local pNum, matchID = GetPNumAndMatchID(client)
  local matchState = MatchStateIndex[matchID]

  for laneKey, lane in pairs(matchState.MasterLanes) do
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
-- * e.g. GetSpecRef(knight, "onAttack") -> onAttack|knightPassive -> "knightPassive"
function GetSpecRefs(unit, event)
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

function HandleEvent(client, eventName, unitsInvolved, data)
  -- * handles various events that occur in the game
  local pNum, matchID = GetPNumAndMatchID(client)
  local matchState = MatchStateIndex[matchID]


  if eventName == 'unitDeath' then
    for _, unit in pairs(unitsInvolved) do
      table.insert(matchState.DeadUnits, unit)
    end
    SendToMatch(matchID, "updateVar", {'global', 'DeadUnits', matchState.DeadUnits})
  end

  for _, unit in pairs(unitsInvolved) do
    -- get the specRef associated with the event being handled
    -- returns false if the unit has no tag for this event
    local specRefs = GetSpecRefs(unit, eventName)
    if specRefs then
      for _, specRef in pairs(specRefs) do
        local owner_peer = GetPeerByCID(matchState.ClientIndex[unit.player])
        server:sendToPeer(getPeer(owner_peer), "callSpecFunc", {specRef, data})
      end
    end
  end

end


-- ! LOVE FUNCTIONS

function love.load()
  -- server GUI
  love.graphics.setFont(love.graphics.newFont(10))
  love.window.setMode(1000,1000)

  -- set up server
  tickRate = 1/120
  tick = 0
  server = sock.newServer("*", 22122)

  -- set up empty MatchStateIndex
  MatchStateIndex = {}
  -- set up CIDTranslator
  CIDTranslator = {}
  
  server:on("connect", function(_, client)
    print('Connection received from client with ID:', client.connectId)
    CIDTranslator[client.connectId] = client
  end)

  -- define everything related to running the lobby system
  DefineLobbyFunctions()

  -- define everything related to running a match
  DefineMatchFunctions()


end

function DefineLobbyFunctions()

  ActiveLobbies = {}

  server:on("createLobby", function(lobbyData, client)
    lobbyData.ID = #ActiveLobbies+1
    table.insert(ActiveLobbies, lobbyData)
  end)

  server:on("joinLobby", function(lobby, client)
    local host = CIDTranslator[lobby.hostCID]
    local hostPeer, clientPeer = GetPeerByClient(host), GetPeerByClient(client)
    server:sendToPeer(hostPeer, "linkToEnemy", client.connectId)
    server:sendToPeer(clientPeer, "linkToEnemy", host.connectId)
  end)

  server:on("requestActiveLobbies", function(_, client)
    local peer = GetPeerByClient(client)
    server:sendToPeer(peer, "updateActiveLobbies", ActiveLobbies)
  end)

end

function DefineMatchFunctions()

  server:on("joinMatch", function(matchID, client)

    -- first, we check if a match with that ID exists
    if MatchStateIndex[matchID] and #(MatchStateIndex[matchID]['ClientIndex']) == 1 then
      -- if it does, add self to ClientIndex as P2
      MatchStateIndex[matchID]['ClientIndex'][2] = client.connectId
      -- then tell to set up for game
      server:sendToPeer(getPeer(client), "setUpGame", {2, matchID})

    elseif not MatchStateIndex[matchID] then
      -- if it doesn't, initialize starting values
      MatchStateIndex[matchID] = {CurrentTurnTaker=1, TurnNumber=0, TimedEventQueue={}, TimedFuncQueue={}, UnitCount=0, DeadUnits={}, Phase='waiting'}
      CreateMasterLanes(matchID)
      -- then, add client as P1
      MatchStateIndex[matchID]['ClientIndex'] = {}
      MatchStateIndex[matchID]['ClientIndex'][1] = client.connectId
      -- ! TESTING FORK: FAKE PLAYER
      MatchStateIndex[1]['Player2'] = {ActionTable={1,0,1},AscendantIndex=2,HasIncarnatePower=true,HasMajorPower=true,HasMinorPower=true}
      -- then tell to set up for game
      server:sendToPeer(GetPeerByClient(client), "setUpGame", {1, matchID})

    elseif #(MatchStateIndex[matchID]['ClientIndex']) == 2 then
      print('Match is full!')
      return false
    end

    end)

  server:on("transferPreMatchData", function(data, client)
    local matchID, preMatchData = unpack(data)
    local pNum = GetPNumAndMatchID(client)

    MatchStateIndex[matchID]['Player'..pNum] = preMatchData
  end)

  -- ! MANAGING THE BOARD ! --

  server:on("createUnitOnTile", function(data, client)
    -- used to create a unit from just a unit name, assigning it a UnitCount and its default stats
    local pNum, matchID = GetPNumAndMatchID(client)

    -- * tileRef is in form 'rA'
    -- * we need to convert it before setting the units stored reference
    local unitName, tileRef = data[1], data[2]
    local spawnTile, newRef = TileRefToTile(client, tileRef)
    MatchStateIndex[matchID].UnitCount = MatchStateIndex[matchID].UnitCount + 1

    -- calculate the statistics of the unit by referencing unitList
    local unitRef = UnitList[unitName]
    local cst, atk, hp, cM, cA, cS, special = unitRef[1], unitRef[2], unitRef[3], unitRef.canMove, unitRef.canAttack, unitRef.canSpecial, unitRef.special
    local unit = {uid=unitName..MatchStateIndex[matchID].UnitCount,name=unitName,player=pNum,cost=cst,
                  attack=atk,health=hp,tile=newRef,canMove=cM,canAttack=cA,canSpecial=cS,
                  specTable=special}
    table.insert(spawnTile.content, unit)

    -- trigger a unitCreated event
    server:sendToPeer(GetPeerByClient(client), "triggerEvent", {'unitCreated', unit } )

    -- send out the updated board
    SendToMatch(matchID, "updateLanes", MatchStateIndex[matchID].MasterLanes)
  end)

  server:on("addUnitToTile", function(data, client)
    -- add the unit
    local unit, newRef = unpack(data)
    AddUnitToTile(client, unit, newRef)
    -- update the board
    local pNum, matchID = GetPNumAndMatchID(client)
    SendToMatch(matchID, "updateLanes", MatchStateIndex[matchID].MasterLanes)
  end)

  server:on("removeUnitFromTile", function(data, client)
    -- remove the unit
    local unit = data[1]
    local tileRef = (data[2] or unit.tile)
    RemoveUnitFromTile(client, unit, tileRef)
    -- update the board
    local pNum, matchID = GetPNumAndMatchID(client)
    SendToMatch(matchID, "updateLanes", MatchStateIndex[matchID].MasterLanes)
  end)

  function AddUnitToTile(client, unit, tileRef)
    -- * used to add an already-existing unit table to a tile
    local tile = TileRefToTile(client, tileRef)
    -- update the stored tileRef
    unit.tile = tileRef
    -- insert the unit
    table.insert(tile.content, unit)
  end

  function RemoveUnitFromTile(client, unit, tileRef)
    local tileRef = tileRef or unit.tile
    local tile = TileRefToTile(client, tileRef)
    local index = FindUnitIndex(unit, tile)
    table.remove(tile.content, index)
  end

  -- ! BASIC UNIT ACTIONS ! --

  server:on("unitAttack", function(data, client)
    -- * used for one unit to attack another
    -- define variables
    local attacker, defender, doNotCheckRange = unpack(data)
    local attackerTileRef, defenderTileRef = attacker.tile, defender.tile
    local newDefenderHP = defender.health - attacker.attack
    local attTile = TileRefToTile(client, attackerTileRef)
    local defTile = TileRefToTile(client, defenderTileRef)
    local dIndex = FindUnitIndex(defender, defTile)

    -- hunter special
    -- ? do we really want to have this here?
    -- ? if we have to do another case like this, switch to having a TargetPicked() event
    -- ? otherwise, i guess it's okay for now
    if defender.specTable['tags']['hunter|MarkedBy'] == attacker.uid then goto skipRange end
    -- generic checking for doNotCheckRange
    if doNotCheckRange then goto skipRange end
    -- check range
    if DistanceBetweenTiles(attTile, defTile) ~= 0 then
      server:sendToPeer(getPeer(client), "createAlert", {'Target out of range', 5})
      return false
    end
    ::skipRange::

    -- unit damaged by event
    HandleEvent(client, "unitDamaged", {defender, attacker}, {'attack', defender, attacker})

    if newDefenderHP <= 0 then
      -- * if the HP is zero or below, kill them
      -- remove the unit
      RemoveUnitFromTile(client, defender)
      -- call the events
      HandleEvent(client, "unitKill", {attacker}, {attacker})
      HandleEvent(client, "unitDeath", {defender}, {defender})
      local contentHardCopy = defTile.content
      for _, unit in pairs(contentHardCopy) do
        -- don't call this event for the actual unit dying
        if unit.uid ~= defender.uid then
          HandleEvent(client, "unitDeathInTile", {unit}, {unit, defender, attacker})
        end
      end
    else
      -- * if the HP is above zero, change the HP stat
      -- find the unit in place, set the new HP
      defTile.content[dIndex]['health'] = newDefenderHP
      server:sendToPeer(GetPeerByClient(client), "createAlert",
            {defender.name..' now has '..newDefenderHP..' HP', 5})
    end
    -- update the board
    local pNum, matchID = GetPNumAndMatchID(client)
    SendToMatch(matchID, "updateLanes", MatchStateIndex[matchID].MasterLanes)
  end)

  server:on("unitMove", function(data, client)
    local unit, oldTileRef, newTileRef, isBasicMove = data[1], data[2], data[3], data[4]

    -- first, we check unitMoveIn and unitMoveOut for all units in the old and new tile
    local oldTile, newTile = TileRefToTile(client, oldTileRef), TileRefToTile(client, newTileRef)
    local outUnits = {}

    for _, oldUnit in pairs(oldTile.content) do
      -- note that outUnits contains the moving unit self
      table.insert(outUnits, oldUnit)
    end

    for _, newUnit in pairs(newTile.content) do
      HandleEvent(client, "unitMoveIn", {newUnit}, {unit, oldTileRef, newTileRef, newUnit, isBasicMove})
    end

    HandleEvent(client, "unitMoveOut", outUnits, {unit, oldTileRef, newTileRef})

    -- ! actual movement
    -- remove from old tile
    RemoveUnitFromTile(client, unit, oldTileRef)
    -- add to new tile
    AddUnitToTile(client, unit, newTileRef)


    -- handle the unit movement event
    HandleEvent(client, "unitMove", {unit}, {unit, oldTileRef, newTileRef, isBasicMove})
    -- update the board
    local pNum, matchID = GetPNumAndMatchID(client)
    SendToMatch(matchID, "updateLanes", MatchStateIndex[matchID].MasterLanes)
  end)

  -- * server-side version of below
  function ModifyUnitTable(client, unit, field, newValue)
    -- find the unit in place, set the new value
    local tile = TileRefToTile(client, unit.tile)
    local index = FindUnitIndex(unit, tile)
    tile.content[index][field] = newValue

    local pNum, matchID = GetPNumAndMatchID(client)
    SendToMatch(matchID, "updateLanes", MatchStateIndex[matchID].MasterLanes)
  end

  -- * used to modify a field of a unit, e.g. health, atk, name, spectable
  server:on("modifyUnitTable", function(data, client)
    local pNum, matchID = GetPNumAndMatchID(client)
    local unit, field, newValue = unpack(data)
    assert(unit, 'Unit missing in a client modifyUnitTable call.')

    -- find the unit in place, set the new value
    local tile = TileRefToTile(client, unit.tile)
    local index = FindUnitIndex(unit, tile)

    -- first we check that the unit exists. if it doesn't and we try to change, it'll crash
    if not tile.content[index] then print('modifyunittable error') return false end
    tile.content[index][field] = newValue

    -- if health, we have to check for death
    if (field == 'health') and newValue <= 0 then
      SendToMatch(matchID, "createAlert", {unit.name..' was killed.', 5})
      RemoveUnitFromTile(client, unit, unit.tile)
    end

    SendToMatch(matchID, "updateLanes", MatchStateIndex[matchID].MasterLanes)
  end)

  -- * finds a unit by ID, then modifies that unit's table
  -- * useful when a unit may have moved in between the event call and this function
  server:on("modifyUnitTableByID", function(data, client)
    local pNum, matchID = GetPNumAndMatchID(client)
    local UID, field, newValue = unpack(data)
    assert(UID, 'UID missing in a client modifyUnitTable call.')

    -- find the unit in place, set the new value
    local unit = FindUnitByID(client, UID)
    local tile = TileRefToTile(client, unit.tile)
    local index = FindUnitIndex(unit, tile)
    
    -- first we check that the unit exists. if it doesn't and we try to change, it'll crash
    if not tile.content[index] then print('modifyunittable error') return false end
    tile.content[index][field] = newValue

    -- if health, we have to check for death
    if (field == 'health') and newValue <= 0 then
      SendToMatch(matchID, "createAlert", {unit.name..' was killed.', 5})
      RemoveUnitFromTile(client, unit, unit.tile)
    end

    SendToMatch(matchID, "updateLanes", MatchStateIndex[matchID].MasterLanes)
  end)

  -- * used to examine whether a given unit is a valid target for a certain set of conditions
  server:on("unitTargetCheck", function(data, client)
    -- * unit is a unit table.
    -- * conditions is a table containing fields that specify what conditions need to be met
    local unit, origin, conditions, data2 = unpack(data)
    -- * we go through all the various conditions

    -- * before checking conditions, we check all neighbours
    -- then, we call the UnitTargetedInTile event on every unit in the target's tile
    local tile = TileRefToTile(client, unit.tile)
    for _, neighbour in pairs(tile.content) do
      HandleEvent(client, "unitTargetedInTile", {neighbour}, {neighbour, unit, data2})
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
      local t1, t2 = TileRefToTile(client, unit.tile), TileRefToTile(client, origin.tile)
      if DistanceBetweenTiles(t1, t2) ~= distance then
        server:sendToPeer(getPeer(client), "createAlert", {'Target out of range', 3})
        return false
      end
    end

    -- ! horizontal distance between
    if conditions.horizontallyAdjacent ~= nil then
      local t1, t2 = TileRefToTile(client, unit.tile), TileRefToTile(client, origin.tile)
      -- check if in same tile
      if t1.t ~= t2.t then server:sendToPeer(getPeer(client), "createAlert", {'Not in adjacent tiles.', 3}) return false end
      -- check if in the same lane
      if not AdjacentLanes(t1.l, t2.l) then server:sendToPeer(getPeer(client), "createAlert", {'Not in adjacent tiles.', 3}) return false end
    end

    -- ! self-targeting
    if conditions.canTargetSelf ~= nil then
      if unit.uid == origin.uid then server:sendToPeer(getPeer(client), "createAlert", {'Cannot target self.', 3}) return false end
    end

    -- if all is well, we echo back a unique target event
    server:sendToPeer(getPeer(client), "triggerEvent", {unit.uid..'TargetSucceed', {}})

    -- before ending, we call the unitTargeted event
    HandleEvent(client, "unitTargeted", {unit}, {unit, origin, data2})
  end)

  -- ! ACTIONS, TURN SYSTEM & QUEUEING EVENTS ! --

  server:on("useAction", function (data, client)
    local actionType, actionUser, reason = unpack(data)
    server:sendToPeer(getPeer(client), "actionUsed", actionType)
  end)

  function AdvanceTurnTimer(matchID)
    local matchState = MatchStateIndex[matchID]
    -- advance the turn number
    matchState.TurnNumber = matchState.TurnNumber + 1
    SendToMatch(matchID, "updateVar", {'global', 'turnNumber', matchState.TurnNumber})

    -- check if there's anything in the EventQueue for this turn
    if not matchState.TimedEventQueue[matchState.TurnNumber] then goto noEvents end
    -- if there is, call those events
    for _, eventsTable in pairs(matchState.TimedEventQueue[matchState.TurnNumber]) do
      local event, args = unpack(eventsTable)
      SendToMatch(matchID, "triggerEvent", {event, args})
    end
    ::noEvents::

    -- check if there's anything for the FuncQueue for this turn
    if not matchState.TimedFuncQueue[matchState.TurnNumber] then return end
    -- if there is, call those funcs
    for _, funcTable in pairs(matchState.TimedFuncQueue[matchState.TurnNumber]) do
      local func, args = unpack(funcTable)
      func(unpack(args))
    end
  end

  -- * server-side version of below. triggers a server function instead of an event
  function QueueTimedFunc(client, func, turnsFromNow, args)
    local pNum, matchID = GetPNumAndMatchID(client)
    local matchState = MatchStateIndex[matchID]

    local triggerTurn = matchState.TurnNumber + turnsFromNow
    if matchState.TimedFuncQueue[triggerTurn] then
      -- if there's already an func(s) queued for that turn, add to that table
      table.insert(matchState.TimedFuncQueue[triggerTurn], {func, args})
    elseif not matchState.TimedFuncQueue[triggerTurn] then
      -- if no funcs are queued, create a new table entirely
      matchState.TimedFuncQueue[triggerTurn] = {{func, args}}
    end
  end

  -- * causes the server to trigger a client Event some turns from now
  server:on("queueTimedEvent", function(data, client)
    local pNum, matchID = GetPNumAndMatchID(client)
    local matchState = MatchStateIndex[matchID]
    local event, turnsFromNow, args = unpack(data)
    local triggerTurn = matchState.TurnNumber + turnsFromNow

    if matchState.TimedEventQueue[triggerTurn] then
      -- if there's already an event(s) queued for that turn, add to that table
      table.insert(matchState.TimedEventQueue[triggerTurn], {event, args})
    elseif not matchState.TimedEventQueue[triggerTurn] then
      -- if no events are queued, create a new table entirely
      matchState.TimedEventQueue[triggerTurn] = {{event, args}}
    end
  end)

  -- * the signal that the client has completed their turn
  -- * also manages victory/defeat checks
  server:on("endMyTurn", function(_, client)
    local _, matchID = GetPNumAndMatchID(client)
    local matchState = MatchStateIndex[matchID]

    -- check if victory condition is achieved
    for pNum, _ in pairs(MatchStateIndex[matchID].ClientIndex) do
      local ascIndex = MatchStateIndex[matchID]['Player'..pNum]['AscendantIndex']
      local asc = AscendantVictories[ascIndex]
      if asc.victoryFunc(pNum, MatchStateIndex[matchID]) then
        local winnerCID = matchState.ClientIndex[pNum]
        local winnerPeer = GetPeerByCID(winnerCID)
        local loser
        for _, playerCID in pairs(matchState.ClientIndex) do
          if playerCID ~= winnerCID then
            -- ! TESTING FORK: NO LOSER (IF FAKE PLAYER)
            print('TESTING FORK: No message to loser')
            -- ! loser = getPeer(Players[player])
          end
        end
        server:sendToPeer(winnerPeer, "youWin", {})
        -- ! TESTING FORK: NO LOSER (FAKE PLAYER)
        print('TESTING FORK: No message to loser.')
        -- ! server:sendToPeer(loser, "youLose", {})
      end
    end
    -- increment the turn timer and activate any queued events
    AdvanceTurnTimer(matchID)
    -- the second argument is the player ID (numbers for now)
    local newTurnTaker
    if client:getIndex() == 1 then newTurnTaker = 2
    elseif client:getIndex() == 2 then newTurnTaker = 1 end
    MatchStateIndex[matchID].CurrentTurnTaker = newTurnTaker
    -- ! TESTING FORK - ONE PLAYER TURN CONTROLS
    -- SendToMatch(matchID, "setPlayerTurn", 1)
    SendToMatch(matchID, "setPlayerTurn", newTurnTaker)
  end)

  -- ! MATCHSTATE EDITING ! --

  server:on("updatePlayerVar", function(data, client)
    local field, value = unpack(data)
    local pNum, matchID = GetPNumAndMatchID(client)
    local PlayerState = MatchStateIndex[pNum]['Player'..pNum]
    PlayerState[field] = value
    end)

  -- ! OTHER ! --

  server:on("sleeperMajor3", function(sleeperLane, client)
    local _, matchID = GetPNumAndMatchID(client)
    local matchState = MatchStateIndex[matchID]


    for laneKey, lane in pairs(matchState.MasterLanes) do
      if sleeperLane ~= laneKey then
        for _, tile in pairs(lane) do
          for _, unit in pairs(tile.content) do
            HandleEvent(client, "unitDeath", {unit}, {unit})
          end
        end
        matchState.MasterLanes[laneKey] = nil
      end
    end

    SendToMatch(matchID, "updateLanes", MatchStateIndex[matchID].MasterLanes)
  end)

end

function love.update(dt)

  for matchID, matchState in pairs(MatchStateIndex) do
    if matchState['Player1'] and matchState['Player2'] and matchState['Phase'] == 'waiting' then
      SendToMatch(matchID, "startMatch", matchState)
      matchState.Phase = 'inProgress'
      AdvanceTurnTimer(matchID)
    end
  end

  server:update()
end

function love.draw()
  love.graphics.setBackgroundColor(1,1,1)
  love.graphics.setColor(0,0,0)
  if MatchStateIndex then
    love.graphics.print(inspect(MatchStateIndex), 0, 0)
  end
end