local ascendantList = {}

local function sacramentMajor()
  -- * first, we create a popup window with the names of each unit that has died this game
  local DeadUnits = MatchState['DeadUnits'] or {}
  local DeadNames = {}

  -- get a table of all the names of the dead units
  -- TODO: this should probably go off matched UIDS, not names
  for _,v in pairs(DeadUnits) do table.insert(DeadNames, v.name) end

  -- create the popup window with the DeadNames table as options
  CreatePopup('Choose a unit to resurrect.', DeadNames, 20, 'UnitSelected')

  WaitFor('UnitSelected', function(selectedUnit)
    AskingForTile = true

    WaitFor("tileSelected", function(selectedTile)

      client:send("createUnitOnTile", {selectedUnit, selectedTile})
      -- TODO: toggle
    end, {'triggerArgs'}) -- * end of the function that is called when a tile is selected
  end, {'triggerArgs'}) -- * end of the function that is called when a unit is selected
end

local function sacramentMinor()
  -- first, we ask for a friendly unit select
  CreateAlert('Select a unit as your Chosen.', 10)
  -- standard nested WaitFor to make the selected unit Chosen
  WaitFor("targetAlly", function(targetAlly)
    client:send("modifyUnitTable", {targetAlly, 'name', 'Chosen '..targetAlly.name})
    local newSpecTable = targetAlly.specTable
    newSpecTable.tags["unitKill|chosenPassive"] = true
    client:send("modifyUnitTable", {targetAlly, 'specTable', newSpecTable})
  end, {'triggerArgs'})
end

local function sacramentIncarnate()
  CreateAlert('Select a Tile to Incarnate at.', 3)
  AskingForTile = true
  WaitFor("tileSelected", function(tileRef)
    client:send("createUnitOnTile", {"SACRAMENT", tileRef})
  end, {'triggerArgs'})
end

local function sacramentVictory()
  -- if Gamestate['Chosen'..playerNumber] then
  --   return Gamestate['Chosen'..playerNumber]['unitsKilled'] >= 3
  -- end
end

ascendantList[1] = {
  name='The Sacrament',
  splash = love.graphics.newImage('images/ascendantSacrament.png'),
  majorText=[[Resurrect any Unit that has died this game and place them on any Tile.]],
  majorFunc=sacramentMajor,
  minorText=[[MINOR: Select a unit to designate as your Chosen. When the Chosen kills an enemy unit, choose one of the following and they gain that ability:
  - +1 ATK | +1 HP
  - ACTIVE: Move to a horizontally adjacent Tile.
  - Heal to full health.
  There can only be one Chosen at a time. 
  ]],
  minorFunc=sacramentMinor,
  incarnateText=[[SACRAMENT
  5|5
  This Unit counts as the Chosen.
  ACTIVE: Move to a horizontally adjacent tile.
  ACTIVE: Kill an allied Unit in this Tile. This Unit's stats increase by that Unit's stats.]],
  incarnateFunc=sacramentIncarnate,
  victoryText='If a Chosen has killed three units.',
  victoryFunc=sacramentVictory
}

local function imperatorMajor()
  CreateAlert('Select the first Tile.', 3)
  AskingForTile = true
  WaitFor("tileSelected", function(tileRef1)
    CreateAlert('Select the second Tile.', 3)
    AskingForTile = "tileSelected2"
    WaitFor("tileSelected2", function(tileRef2)
      -- the Imperator Bridge is then drawn on every unit's control panel in the given tile
      -- managed in board.lua
      CreateAlert('Bridge created between '..tileRef1..' and '..tileRef2..'.', 3)
      ActiveImperatorBridge = {tileRef1, tileRef2}
      -- TODO: toggle off
    end, {'triggerArgs'}) -- * end of second tile selection
  end, {'triggerArgs'}) -- * end of first tile selection
end

local function imperatorMinor()
  CreateAlert('Select a tile.', 3)
  AskingForTile = true
  WaitFor("tileSelected", function(tileRef)
    -- check if the tile is valid
    -- no enemies or other imperial bastions
    local tile = tileRefToTile(tileRef)
    local hasFriendlyUnit = false
    for _, unit in pairs(tile.content) do
      if unit.player ~= playerNumber then CreateAlert('Tile has enemy units.', 3) return false end
      if unit.name == 'Imperial Outpost' then CreateAlert('Tile already has an Outpost.', 3) return false end
      if unit.player == playerNumber then hasFriendlyUnit = true end
    end
    if not hasFriendlyUnit then
      CreateAlert('Tile has no friendly Unit.', 3)
      return false 
    end
    -- if everything's okay, we create an Outpost
    client:send("createUnitOnTile", {"Imperial Outpost", tileRef})
    -- TODO: toggle power on/off

  end, {'triggerArgs'})
end

local function imperatorIncarnate()
  CreateAlert('Select a Tile to Incarnate at.', 3)
  AskingForTile = true
  WaitFor("tileSelected", function(tileRef)
    client:send("createUnitOnTile", {"IMPERATOR", tileRef})
  end, {'triggerArgs'})
  -- TODO: can't incarnate more than once

end

local function imperatorVictory()
  -- count how many Outposts there are
  local outpostCount = 0
  for _, lane in pairs(MasterLanes) do
    for _, tile in pairs(lane) do
      local hasOutpost = false
        for _, unit in pairs(tile.content) do
          if unit.name == 'Imperial Outpost' then hasOutpost = true end
        end
      if hasOutpost then outpostCount = outpostCount + 1 end
    end
  end
  print('outpost count', outpostCount)
  return outpostCount >= 3
end


ascendantList[2] = {
  name='The Imperator',
  splash = love.graphics.newImage('images/ascendantImperator.png'),
  majorText='Select two Tiles in different Lanes; for example, the top Tile of the Red and Yellow Lanes. Units can now move between these two tiles as a Secondary Action.',
  majorFunc=imperatorMajor,
  minorText='Select a Tile with only friendly units and no Imperial Outposts. Place an Imperial Outpost there. Imperial Outposts are Units that cannot move, with 1 ATK and 5 HP.',
  minorFunc=imperatorMinor,
  incarnateText='IMPERATOR\n5|5\nACTIVE: Create a 1|1 Legion in this Tile.\nACTIVE: Set the ATK and HP of all Legions to the total amount of Legions on the board.',
  incarnateFunc=imperatorIncarnate,
  victoryText='If at least four tiles have Imperial Outposts.',
  victoryFunc=imperatorVictory
}


local function parallelMajor()
  CreateAlert('Target a Unit.', 3)
  WaitFor("targetUnit", function(targetUnit)
    local unitLane = string.sub(targetUnit.tile, 1, 1)
    local lane = board.lanes[unitLane]
    local i = 0
    for _, tile in pairs(lane) do
      for _, unit in pairs(tile.content) do
        local shallowCopy = targetUnit
        shallowCopy.uid = targetUnit.name..'ParallelCopy'..tostring(i)
        client:send("removeUnitFromTile", {unit})
        client:send("addUnitToTile", {targetUnit, unit.tile})
        i = i+1
      end
    end
    -- TODO: toggle
  end, {'triggerArgs'})
end

local function parallelMinor()
  CreatePopup('Select one.', {'Swap ATK/HP', 'Swap ATK of 2', 'Swap HP of 2'}, 120, 'optionSelected')
  WaitFor("optionSelected", function(option)

    if option == 'Swap ATK/HP' then

      CreateAlert('Target a Unit', 3)
      WaitFor("targetUnit", function(targetUnit)
        local newHP = targetUnit.attack
        local newATK = targetUnit.health
        client:send("modifyUnitTable", {targetUnit, 'attack', newATK})
        client:send("modifyUnitTable", {targetUnit, 'health', newHP})
        CreateAlert('Swapped ATK/HP.', 3)
      end, {'triggerArgs'})

    elseif option == 'Swap ATK of 2' then

      CreateAlert('Select the first Unit.', 3)
      WaitFor("targetUnit", function(targetUnit1)
        CreateAlert('Select the second Unit.', 3)
        WaitFor("targetUnit", function(targetUnit2)
          local new2atk = targetUnit1.attack
          local new1atk = targetUnit2.attack
          client:send("modifyUnitTable", {targetUnit1, 'attack', new1atk})
          client:send("modifyUnitTable", {targetUnit2, 'attack', new2atk})
          CreateAlert('Swapped attacks.', 3)
        end, {'triggerArgs'}) -- * end of second unit selection
      end, {'triggerArgs'}) -- * end of first unit selection

    elseif option == 'Swap HP of 2' then

      CreateAlert('Select the first Unit.', 3)
      WaitFor("targetUnit", function(targetUnit1)
        CreateAlert('Select the second Unit.', 3)
        WaitFor("targetUnit", function(targetUnit2)
          local new2hp = targetUnit1.health
          local new1hp = targetUnit2.health
          client:send("modifyUnitTable", {targetUnit1, 'health', new1hp})
          client:send("modifyUnitTable", {targetUnit2, 'health', new2hp})
          CreateAlert('Swapped healths.', 3)
        end, {'triggerArgs'}) -- * end of second unit selection
      end, {'triggerArgs'}) -- * end of first unit selection
    end

  end, {'triggerArgs'})
end

local function parallelIncarnate()
  CreateAlert('Select a Tile for the First Parallel.', 3)

  AskingForTile = true
  WaitFor("tileSelected", function(tileRef1)

    client:send("createUnitOnTile", {'FIRST PARALLEL', tileRef1})

    CreateAlert('Select a Tile for the Second Parallel.', 3)

    AskingForTile = true
    WaitFor("tileSelected", function(tileRef2)
      client:send("createUnitOnTile", {'SECOND PARALLEL', tileRef2})
    end, {'triggerArgs'})

  end, {'triggerArgs'})

end

local function parallelVictory()
  local allSameATK = true
  local allSameHP = true
  local ATKcheck, HPcheck

  for _, lane in pairs(MasterLanes) do
    for _, tile in pairs(lane) do
      for _, unit in pairs(tile.content) do
        if not ATKcheck then ATKcheck = unit.attack end
        if not HPcheck then HPcheck = unit.health end
        if unit.attack ~= ATKcheck then allSameATK = false end
        if unit.health ~= HPcheck then allSameHP = false end
      end
    end
  end

  return (allSameATK or allSameHP)

end

ascendantList[3] = {
  name='The Parallel',
  splash = love.graphics.newImage('images/ascendantParallel.png'),
  majorText='Target one Unit. All other Units in that Lane become copies of the targeted Unit.',
  majorFunc=parallelMajor,
  minorText='Choose one:\nSwap the ATK and HP of target Unit.\nSwap the ATK of two target Units.\nSwap the HP of two target Units.',
  minorFunc=parallelMinor,
  incarnateText='FIRST PARALLEL\n1|6\nACTIVE: Kill all Units with the same HP as the First Parallel.\nSECOND PARALLEL\n6|1\nACTIVE: Swap the ATK and HP of all Units in this Tile.',
  incarnateFunc=parallelIncarnate,
  victoryText='If every surviving unit has the same Attack OR the same Health.',
  victoryFunc=parallelVictory
}

local function sleeperMajor()
  local state = GetPlayerVar('SleeperState')

  if state == 1 then
    CreateAlert('No effect.', 3)
    return false
  elseif state == 2 then
    local sleeperUID = GetPlayerVar('AscendantUID')
    client:send("modifyUnitTableByID", {sleeperUID, 'health', 10})
  elseif state == 3 then
    local sleeperUID = GetPlayerVar('AscendantUID')
    local sleeper = findUnitByID(sleeperUID)
    local lane = string.sub(sleeper.tile, 1, 1)
    client:send("sleeperMajor3", lane)
  end

end

local function sleeperMinor()
  local state = GetPlayerVar('SleeperState')
 
  local function inflictMadness(targetUnit)
    client:send("modifyUnitTable", {targetUnit, 'canMove', false})
    client:send("modifyUnitTable", {targetUnit, 'canAttack', false})
    client:send("modifyUnitTable", {targetUnit, 'canSpecial', false})
    local specTable = targetUnit.specTable
    local tags = specTable.tags
    tags["unitMoveIn|madnessPassive"] = true
    client:send("modifyUnitTable", {targetUnit, 'specTable', specTable})
  end

  local function reverseMadness(targetUnit, ogMove, ogAtk, ogSpec)
    client:send("modifyUnitTable", {targetUnit, 'canMove', ogMove})
    client:send("modifyUnitTable", {targetUnit, 'canAttack', ogAtk})
    client:send("modifyUnitTable", {targetUnit, 'canSpecial', ogSpec})
    local specTable = targetUnit.specTable
    local tags = specTable.tags
    tags["unitMoveIn|madnessPassive"] = nil
    client:send("modifyUnitTable", {targetUnit, 'specTable', specTable})
  end

  if state == 1 then
    -- one-turn madness
    CreateAlert('Target a Unit.', 3)
    WaitFor("targetUnit", function(targetUnit)

      local ogMove, ogAtk, ogSpec = targetUnit.canMove, targetUnit.canAttack, targetUnit.canSpecial
      inflictMadness(targetUnit)

      local uniqueEvent = playerNumber..'sleeperMadnessReversion'
      client:send("queueTimedEvent", {uniqueEvent, 1, {} })

      WaitFor(uniqueEvent, function(unit, omove, oatk, ospec)
        reverseMadness(unit, omove, oatk, ospec)
      end, {targetUnit, ogMove, ogAtk, ogSpec})

    end, {'triggerArgs'})
  
  elseif state == 2 then
    
    CreateAlert('Target a Unit.', 3)
    WaitFor("targetUnit", function(targetUnit)
      inflictMadness(targetUnit)
    end, {'triggerArgs'})


  elseif state == 3 then
    
    CreateAlert('Select a Tile.', 3)
    AskingForTile = true
    WaitFor("tileSelected", function(selectedTile)
      
      local tile = tileRefToTile(selectedTile)
      
      for _, unit in pairs(tile.content) do
        inflictMadness(unit)
      end

    end, {'triggerArgs'})

  end

end

local function sleeperIncarnate()
  CreateAlert('How did you get here???', 5)
  return true
end

local function sleeperVictory()
end

local function sleeperOnMatchStart()
  ChangePlayerVar('SleeperState', 3)
  ChangePlayerVar('HasIncarnatePower', false)

  -- create Incarnate
  CreateAlert('Select a Tile for the SLEEPER.', 5)
  AskingForTile = true
  WaitFor("tileSelected", function(selectedTile)
    client:send("createUnitOnTile", {"SLEEPER, DREAMING", selectedTile})
    
    WaitFor("unitCreated", function(unit)
      ChangePlayerVar('AscendantUID', unit.uid)
    end, {'triggerArgs'})

  end, {'triggerArgs'})
end

ascendantList[4] = {
  name='The Sleeper',
  splash = love.graphics.newImage('images/ascendantSleeper.png'),
  majorText=[[The Sleeper's power depends on their state.
  DREAMING: No effect.
  DISTURBED: Heal the Sleeper to 10HP.
  AWOKEN: Remove Lanes other than the Sleeper's Lane from the game.]],
  majorFunc=sleeperMajor,
  minorText=[[The Sleeper's power depends on their state.
Mad Units cannot Act, and automatically attack any Unit that moves into their tile.
DREAMING: Target a Unit. Inflict Madness on them for the next Turn.
DISTURBED: Target a Unit. Inflict permanent Madness on them.
AWOKEN: Target a Tile. Inflict permanent Madness on each Unit in that Tile.]],
  minorFunc=sleeperMinor,
  incarnateText=[[THE SLEEPER, DREAMING
  0|5
  When a Unit dies in the same Tile as the Sleeper, it becomes the Sleeper, Disturbed.
  The Sleeper, Dreaming cannot move or attack.
  
  THE SLEEPER, DISTURBED
  0|10
  When a Unit dies in the same Tile as the Sleeper, it becomes the Sleeper, Awoken.
  The Sleeper, Disturbed cannot move or attack.
  
  THE SLEEPER, AWOKEN
  10|10
  ACTIVE: Kill all other Units in the Sleeper’s Tile.
  If the Sleeper, Awoken is the only Unit remaining, or if all other Units have Madness, you win the game.
  ]],
  incarnateFunc=sleeperIncarnate,
  victoryText='The Sleeper\'s Incarnate must be placed on the board at the start of the game. Refer to the Incarnate for more information.',
  victoryFunc=sleeperVictory,
  onMatchStartFunc=sleeperOnMatchStart
}

local function savantMajor()
  CreateAlert('Select the blank Tile.', 5)
  AskingForTile = true
  WaitFor("tileSelected", function(tileRef1)
    
    client:send("queueTimedEvent", {'savant'..playerNumber..'Major1', 1, {} })
    WaitFor('savant'..playerNumber..'Major1', function(ref)
      local tile = tileRefToTile(ref)
      local emptySpecTable = {shortDesc='Special has been blanked.', fullDesc='Special has been blanked.', specRef=nil, tags={}}
      for _, unit in pairs(tile.content) do
        client:send("modifyUnitTable", {unit, 'specTable', emptySpecTable})
      end
    end, {tileRef1}) -- * blank function

    CreateAlert('Select the move Tile.', 5)
    AskingForTile = true
    WaitFor("tileSelected", function(tileRef2)

      client:send("queueTimedEvent", {'savant'..playerNumber..'Major2', 2, {tileRef2} })
      WaitFor('savant'..playerNumber..'Major2', function(refA)
        CreateAlert('SAVANT: Select a Tile to move '..refA..' to.', 5)
        AskingForTile = true
        WaitFor("tileSelected", function(refB)
          local tile1 = tileRefToTile(refA)
          for _, unit in pairs(tile1.content) do
            client:send("removeUnitFromTile", {unit})
            client:send("addUnitToTile", {unit, refB})
          end
        end, {'triggerArgs'})
      end, {tileRef2}) -- * move function


      CreateAlert('Select the kill Tile.', 5)
      AskingForTile = true
      WaitFor("tileSelected", function(tileRef3)

        client:send("queueTimedEvent", {'savant'..playerNumber..'Major3', 3, {tileRef3} })
        WaitFor('savant'..playerNumber..'Major3', function(ref)
          local tile = tileRefToTile(ref)
          for _, unit in pairs(tile.content) do
            -- TODO: death event
            client:send("removeUnitFromTile", {unit})
          end
        end, {tileRef3}) -- * kill function

      end, {'triggerArgs'}) -- * select tile to kill

    end, {'triggerArgs'}) -- * select tile to blank

  end, {'triggerArgs'}) -- * select tile to move
end

local function savantMinor()
  CreateAlert('Target a Unit to phase out.', 3)
  WaitFor("targetUnit", function(targetUnit)
    -- first, we just remove target
    client:send("removeUnitFromTile", {targetUnit})
    -- then, we queue up adding that unit back in 2 turns
    local uniqueEvent = 'savant'..playerNumber..'MinorReturn'
    client:send("queueTimedEvent", {uniqueEvent, 2, {}})
    -- then we await that event
    WaitFor(uniqueEvent, function(unit)
      CreateAlert(unit.name..' has returned!', 3)
      client:send("addUnitToTile", {unit, unit.tile})
    end, {targetUnit})
  end, {'triggerArgs'})
end

local function savantIncarnate()
  CreateAlert('Select a Tile to Incarnate at.', 3)

  AskingForTile = true
  WaitFor("tileSelected", function(tileRef1)
    client:send("createUnitOnTile", {'SAVANT', tileRef1})
  end, {'triggerArgs'})
end

local function savantVictory(player)
  if MatchState.turnNumber == MatchState['Savant'..player..'VictoryTurn'] then
    local alliedUnits, enemyUnits = 0, 0
    for _, lane in pairs(MasterLanes) do
      for _, tile in pairs(lane) do
        for _, unit in pairs(tile.content) do
          if unit.player == player then
            alliedUnits = alliedUnits + 1
          elseif unit.player ~= player then
            enemyUnits = enemyUnits + 1
          end
        end
      end
    end
    return alliedUnits > enemyUnits
  else
    return false
  end
end

local function savantOnMatchStart()
  CreateSliderPopup('Choose which turn you wish to declare victory.')
end

ascendantList[5] = {
  name='The Savant',
  splash = love.graphics.newImage('images/ascendantSavant.png'),
  majorText='Select three Tiles in order. Next turn, blank the Special of all units in the first Tile. Two turns from now, move all Units in the second Tile to another Tile. Three turns from now, destroy all units in the third.',
  majorFunc=savantMajor,
  minorText='Remove a chosen Unit from the game. In two turns, that Unit returns to the game exactly as it left.',
  minorFunc=savantMinor,
  incarnateText=[[SAVANT
3|2
ACTIVE: Create one of the following in this Tile:
  Tripwire: 0|1 When a Unit enters this Tile, they take 1 damage.
  Hologram: 0|1 This Unit cannot be damaged by attacks.
  Railgun: 0|1 ACTIVE: Kill this Unit. Target ally in this Tile gains +2 ATK.
ACTIVE: Remove this Unit from the board and restore your Incarnate ability.]],
  incarnateFunc=savantIncarnate,
  victoryText='At the start of the game, pick a turn number greater than 5. On that turn, if you have more Units than your opponent, you win. Otherwise, you lose.',
  victoryFunc=savantVictory,
  onMatchStartFunc=savantOnMatchStart
}

return ascendantList
