local buildArmy = {}


--init currentArmyCost so it can be used in the armyList
local currentArmyCost = 0
function buildArmy.load()
  if not PreMatchData['ArmyList'] then PreMatchData['ArmyList'] = {} end 
end

function buildArmy.update(dt)
  -- * make all the unitselect buttons
  local x,y = love.graphics.getDimensions()
  local centerX = Round(x/2)
  local centerY = Round(y/2)
  local startX, endX = math.max(0,centerX-430), math.min(centerX+375,x)

  local unitNames = {}
  for unitName,unit in pairs(unitList) do
    -- only add units with costs (not architect buildings)
    if unit[1] ~= 0 then table.insert(unitNames, unitName) end
  end
  table.sort(unitNames)

  local numOfRows = 5
  for rowNum=1,numOfRows do
    -- 1 = 1:5
    -- 2: 6:10
    -- 3: 11:15

    local row = {unpack(unitNames, 1+(numOfRows*(rowNum-1)), (numOfRows*rowNum))}

    suit.layout:reset(startX, (25*(rowNum-1))+20 )
    suit.layout:padding(30)
    -- every button is effectively buttonWidth + 10px wide, because of the padding on each side
    local buttonWidth = Round(endX/10)
    for _, unitName in pairs(row) do
      suit.Button(unitName, suit.layout:col(150,20))
    end

  end

  -- * when a button is hovered, display an info panel
  for k,v in pairs(unitList) do
    if suit.isHovered(k) then
      suit.layout:reset(centerX+200, centerY+10)
      -- name
      suit.Label(k, suit.layout:row(200,20))
      -- stats
      local cst, atk, hp = v[1], v[2], v[3]
      local statstring = string.format('Cost: %i | ATK: %i | HP: %i', cst, atk, hp)
      suit.Label(statstring, suit.layout:row(200,20))
      -- special
      suit.Label(v.special['fullDesc'], suit.layout:row(200,20))
   end
  end

  -- * add units to PreMatchData['ArmyList'] when their button is hit
  for k,v in pairs(unitList) do
    if suit.isHit(k) then
        -- make sure there's room in the budget
        if currentArmyCost + v[1] <= 5 then
            table.insert(PreMatchData['ArmyList'], k)
        end
    end
  end

  -- create the armyList labels and buttons
  suit.layout:reset(centerX-75, centerY+10)
  suit.Label('YOUR ARMY', suit.layout:row(150, 20))
  local budgetText = string.format('Budget: %d/5', currentArmyCost)
  suit.Label(budgetText, suit.layout:row(150,20))
  for k, v in pairs(PreMatchData['ArmyList']) do
      suit.Button(v, {id = v..tostring(k)}, suit.layout:row(150, 20))
  end

  -- remove the unit from the armyList when clicked
  for k, v in pairs(PreMatchData['ArmyList']) do
      if suit.isHit(v..tostring(k)) then
          table.remove(PreMatchData['ArmyList'], k)
      end
  end

  --calculate currentArmyCost from armyList
  currentArmyCost = 0
  for k,v in pairs(PreMatchData['ArmyList']) do
      currentArmyCost = currentArmyCost + unitList[v][1]
  end

  --make a button to launch into the matchmaking screen
  suit.layout:reset(centerX-75,y-40)
  suit.Button('Army Complete', suit.layout:row(150,20))
  if suit.isHit('Army Complete') then
      PreMatchData['CurrentArmyCost'] = currentArmyCost
      changeScreen(LobbyWait)
  end

end

function buildArmy.draw()
  suit.draw()
end

return buildArmy
