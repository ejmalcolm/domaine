local AscendantVictories = {}

local function sacramentVictory(player)
  local ChosenKillCount = MatchState['Player'..player]['ChosenKillCount'] or 0
  return ChosenKillCount >= 3
end

AscendantVictories[1] = {
  name='The Sacrament',
  victoryFunc=sacramentVictory
}

local function imperatorVictory(player)
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
  return outpostCount >= 3
end


AscendantVictories[2] = {
  name='The Imperator',
  victoryFunc=imperatorVictory
}

AscendantVictories[3] = {
  name='The Parallel',
  victoryText='If every surviving unit has the same Attack OR the same Health.',
  victoryFunc=parallelVictory
}

local function sleeperVictory(player) return false end

AscendantVictories[4] = {
  victoryText='The Sleeper\'s Incarnate must be placed on the board during Unit Placement. Refer to the Incarnate for more information.',
  victoryFunc=sleeperVictory
}

local function savantVictory(player)
  if MatchState.turnNumber == MatchState['Player'..player]['SavantVictoryTurn'] then
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

AscendantVictories[5] = {
  name='The Savant',
  victoryText='At the start of the game, pick a turn number greater than 5. On that turn, if you have more Units than your opponent, you win. Otherwise, you lose.',
  victoryFunc=savantVictory
}

return AscendantVictories
