local ascendantList = {}

local function sacramentMajor()
  -- * first, we create a popup window with the names of each unit that has died this game
  local DeadUnits = Gamestate['DeadUnits'] or {}
  local DeadNames = {}
  -- get a table of all the names of the dead units
  for k,v in pairs(DeadUnits) do table.insert(DeadNames, v.name) end
  -- create the popup window with the DeadNames table as options
  CreatePopup('Choose a unit to resurrect.', DeadNames, 20, 'UnitSelected')
  -- * this is done by storing the rest of the function in WaitFor()
  -- * so it only triggers once a unit is picked
  WaitFor('UnitSelected', function(selectedUnit)
    -- then, user has to pick a tile
    AskingForTile = true
    -- we wait for the tile selection and nest another layer deep! :)
    WaitFor("tileSelected", function(selectedTile)
      -- finally, we cast createUnitOnTile using the arguments in MajorPowerData
      client:send("createUnitOnTile", {selectedUnit, selectedTile})
      -- we use our power
      Gamestate['HasMajorPower'] = false
    end, {'triggerArgs'}) -- * end of the function that is called when a tile is selected
  end, {'triggerArgs'}) -- * end of the function that is called when a unit is selected
end

local function sacramentMinor()
  -- first, we ask for a friendly unit select
  CreateAlert('Select a unit as your Chosen.', 10)
  -- standard nested WaitFor to make the selected unit Chosen
  WaitFor("targetAlly", function(selectedUnit)
    -- we change the units name to '**[name]**'
    client:send("modifyUnitTable", {selectedUnit, 'name', '**'..selectedUnit.name..'**'})
    -- we store what unit is the Chosen and update the server on it!
    Gamestate['Chosen'..playerNumber] = {currentChosen=selectedUnit.uid, unitsKilled=(0 or Gamestate['Chosen'..playerNumber]['unitsKilled']) }
    client:send("updateVar", {'Chosen'..playerNumber, Gamestate['Chosen'..playerNumber]})
    -- we use our power
    Gamestate['HasMinorPower'] = false
  end, {'triggerArgs'})
end

local function sacramentVictory()
  return Gamestate['Chosen'..playerNumber]['unitsKilled'] >= 3
end

ascendantList[1] = {
  name='The Sacrament',
  splash = love.graphics.newImage('images/ascendantSacrament.png'),
  majorText='Resurrect any Unit that has died this game and place them on any Tile.',
  majorFunc=sacramentMajor,
  minorText='Select a unit to designate as your Chosen. When the Chosen kills an enemy unit, they gain +1ATK/+1HP. There can only be one Chosen at a time.',
  minorFunc=sacramentMinor,
  incarnateText='coming soon',
  incarnateFunc=nil,
  victoryText='If a Chosen has killed three units.',
  victoryFunc=sacramentVictory
}

ascendantList[2] = {
  name='The Imperator',
  splash = love.graphics.newImage('images/ascendantImperator.png'),
  majorText='Select two Tiles in different Lanes; for example, the top Tile of the Red and Yellow Lanes. Units can now move between these two tiles as a Secondary Action.',
  majorFunc=sacramentMajor,
  minorText='Select a Tile with only friendly units and no Imperial Outposts. Place an Imperial Outpost there. Imperial Outposts are Units that cannot move, with 1 ATK and 5 HP.',
  minorFunc=nil,
  incarnateText='coming soon',
  incarnateFunc=nil,
  victoryText='If at least four tiles have Imperial Outposts.',
  victoryFunc=nil
}

ascendantList[3] = {
  name='The Parallel',
  splash = love.graphics.newImage('images/ascendantParallel.png'),
  majorText='Pick three pairs of tiles. Swap their contents.',
  majorFunc=sacramentMajor,
  minorText='Swap the ATK and HP of a chosen unit.',
  minorFunc=nil,
  incarnateText='coming soon',
  incarnateFunc=nil,
  victoryText='If every surviving unit has the same Attack OR the same Health.',
  victoryFunc=nil
}

ascendantList[4] = {
  name='The Sleeper',
  splash = love.graphics.newImage('images/ascendantSleeper.png'),
  majorText='coming soon',
  majorFunc=sacramentMajor,
  minorText='coming soon',
  minorFunc=nil,
  incarnateText='coming soon',
  incarnateFunc=nil,
  victoryText='coming soon',
  victoryFunc=nil
}

ascendantList[5] = {
  name='The Savant',
  splash = love.graphics.newImage('images/ascendantSavant.png'),
  majorText='Select three Tiles in order. Next turn, move all units in the first to another Tile. Two turns from now, remove the abilities of all units in the second. Three turns from now, destroy all units in the third.',
  majorFunc=sacramentMajor,
  minorText='Remove a chosen Unit from the game. In two turns, that Unit returns to the game exactly as it left.',
  minorFunc=nil,
  incarnateText='coming soon',
  incarnateFunc=nil,
  victoryText='At the start of the game, pick a turn number greater than 5. On that turn, if you have more Units than your opponent, you win. Otherwise, you lose.',
  victoryFunc=nil
}

return ascendantList
