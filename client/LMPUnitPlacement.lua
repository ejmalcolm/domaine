local unitPlacement = {}

function unitPlacement.setArmyFromLobby(lobby)
  if client.connectId == lobby.hostCID then
    unitPlacement.ownArmy = lobby['hostPreMatch']['ArmyList'] or {}
    unitPlacement.otherArmy = lobby['guestPreMatch']['ArmyList'] or {}
  else
    unitPlacement.ownArmy = lobby['guestPreMatch']['ArmyList'] or {}
    unitPlacement.otherArmy = lobby['hostPreMatch']['ArmyList'] or {}
  end
end

function unitPlacement.load()

  DefineMatchEvents()

  UnitPlacementInfoSuit = suit.new()
  unitPlacement.pRects = {}
  InsideLobby.placerID = InsideLobby.hostCID

  -- other person (top)
  do
    unitPlacement.pRects.r1 = {}
    unitPlacement.pRects.r1.color = {1,0,0}
    unitPlacement.pRects.r1.rect = {centerX-500, 125, 100, 100}
    unitPlacement.pRects.r1.content = {}

    unitPlacement.pRects.y1 = {}
    unitPlacement.pRects.y1.color = {1,1,0}
    unitPlacement.pRects.y1.rect = {centerX-50, 125, 100, 100}
    unitPlacement.pRects.y1.content = {}

    unitPlacement.pRects.b1 = {}
    unitPlacement.pRects.b1.color = {0,0,1}
    unitPlacement.pRects.b1.rect = {centerX+400, 125, 100, 100}
    unitPlacement.pRects.b1.content = {}
  end

  -- this person (bottom)
  do
    unitPlacement.pRects.r3 = {}
    unitPlacement.pRects.r3.color = {1,0,0}
    unitPlacement.pRects.r3.rect = {centerX-500, y-250, 100, 100}
    unitPlacement.pRects.r3.content = {}

    unitPlacement.pRects.y3 = {}
    unitPlacement.pRects.y3.color = {1,1,0}
    unitPlacement.pRects.y3.rect = {centerX-50, y-250, 100, 100}
    unitPlacement.pRects.y3.content = {}

    unitPlacement.pRects.b3 = {}
    unitPlacement.pRects.b3.color = {0,0,1}
    unitPlacement.pRects.b3.rect = {centerX+400, y-250, 100, 100}
    unitPlacement.pRects.b3.content = {}
  end

  -- set up LMP client commands
  client:on("updateArmyLists", function()
    unitPlacement.setArmyFromLobby(InsideLobby)
  end)

  client:on("addToPRect", function(data)
    local pRectKey, ownerID, unitName = unpack(data)
    local pRect
    if ownerID == client.connectId then
      pRectKey = pRectKey:sub(1,1)..'3'
      pRect = unitPlacement.pRects[pRectKey]
    else
      pRectKey = pRectKey:sub(1,1)..'1'
      pRect = unitPlacement.pRects[pRectKey]
    end
    table.insert(pRect.content, unitName)
  end)

  client:on("removeFromPRect", function(data)
  local pRectKey, ownerID, unitKey = unpack(data)
  local pRect
  if ownerID == client.connectId then
    pRectKey = pRectKey:sub(1,1)..'3'
    pRect = unitPlacement.pRects[pRectKey]
  else
    pRectKey = pRectKey:sub(1,1)..'1'
    pRect = unitPlacement.pRects[pRectKey]
  end
  table.remove(pRect.content, unitKey)
  end)

  client:on("setPlacer", function(placerID)
    InsideLobby.placerID = placerID
  end)

end

function unitPlacement.update(dt)

  -- check who's turn it is
  local isMyTurn
  if InsideLobby.placerID == client.connectId then isMyTurn = true else isMyTurn = false end

  for pRectKey, pRect in pairs(unitPlacement.pRects) do

    local armyList
    local displacement
    local button_owner
    -- * define the armyList needed
    -- * displacement defines whether the buttons go on top or beneath the pRect
    if pRectKey == 'r3' or pRectKey == 'y3' or pRectKey == 'b3' then
      armyList = unitPlacement.ownArmy
      displacement = 110
      button_owner = 'self'
    else
      armyList = unitPlacement.otherArmy
      displacement = -30
      button_owner = 'other'
    end
    -- * create armyList buttons beneath/above each pRect
    suit.layout:reset(pRect.rect[1], pRect.rect[2]+displacement)
    for unitKey, unitName in pairs(armyList) do
        local UID = pRectKey..unitName..tostring(unitKey)
        local armyListButton
        if button_owner == 'self' then
          armyListButton = suit.Button(unitName, {id = UID}, suit.layout:down(100,20))
          if armyListButton.hit and isMyTurn then
            client:send("armyListToPRect", {InsideLobby, unitKey, unitName, pRectKey})
          end
        else
          armyListButton = suit.Button(unitName, {id = UID}, suit.layout:up(100,20))
        end

        -- * display an info panel when hovered
        if armyListButton.hovered then
          local v = unitList[unitName]
          -- to the right of pRect if first two, else to the left
          if pRect.rect[1] > centerX then
            UnitPlacementInfoSuit.layout:reset(pRect.rect[1]-210, pRect.rect[2])
          else
            UnitPlacementInfoSuit.layout:reset(pRect.rect[1]+110, pRect.rect[2])
          end
            -- name
          UnitPlacementInfoSuit:Label(unitName, UnitPlacementInfoSuit.layout:row(200,20))
          -- stats
          local cst, atk, hp = v[1], v[2], v[3]
          local statstring = string.format('Cost: %i | ATK: %i | HP: %i', cst, atk, hp)
          UnitPlacementInfoSuit:Label(statstring, UnitPlacementInfoSuit.layout:row(200,20))
          -- special
          UnitPlacementInfoSuit:Label(v.special['fullDesc'], UnitPlacementInfoSuit.layout:row(200,20))
        end
    end

    -- * inside each pRect, draw a button for each unit in it
    suit.layout:reset(pRect.rect[1], pRect.rect[2])
    for unitKey, unitName in pairs(pRect.content) do
      -- the ID is: pRect#+unitName+index
      -- where pRect# is 1=r, 2=y, 3=g

      -- * we add the 'PRC' because we need to distinguish the P Rect Content
      -- * buttons from the armyList buttons, else they trigger each other
      local UID = 'PRC'..pRectKey..unitName..tostring(unitKey)
      local inRectButton = suit.Button(unitName, {id = UID}, suit.layout:down(100, 20))

      -- * when hit, remove from "inside" tile and put beneath it
      -- if button_owner == 'self' then
      --   if inRectButton.hit and isMyTurn then
      --     client:send("pRectToArmyList", {InsideLobby, unitKey, pRectKey, unitName})
      --   end
      -- end
      -- * when hovered, draw an info panel
      if inRectButton.hovered then
        if pRect.rect[1] > centerX then
          UnitPlacementInfoSuit.layout:reset(pRect.rect[1]-210, pRect.rect[2])
        else
          UnitPlacementInfoSuit.layout:reset(pRect.rect[1]+110, pRect.rect[2])
        end
        local v = unitList[unitName]
        -- name
        UnitPlacementInfoSuit:Label(unitName, UnitPlacementInfoSuit.layout:row(200,20))
        -- stats
        local cst, atk, hp = v[1], v[2], v[3]
        local statstring = string.format('Cost: %i | ATK: %i | HP: %i', cst, atk, hp)
        UnitPlacementInfoSuit:Label(statstring, UnitPlacementInfoSuit.layout:row(200,20))
        -- special
        UnitPlacementInfoSuit:Label(v.special['fullDesc'], UnitPlacementInfoSuit.layout:row(200,20))
      end

    end

  end

  -- in the center of the screen, display who's turn it is to place a unit
  suit.layout:reset(centerX-50, centerY-10)
  if isMyTurn then
    suit.Label('YOUR TURN', suit.layout:row(100, 20))
  else
    suit.Label('THEIR TURN', suit.layout:row(100, 20))
  end

  -- if both armyLists are empty, then we advance to the board screen
  -- only the host sends this signal
  suit.layout:reset(centerX-75,y-40)
  if InsideLobby.hostCID == client.connectId then
    if #(unitPlacement.ownArmy) == 0 and #(unitPlacement.otherArmy) == 0 and (not unitPlacement.matchStarted) then
      unitPlacement.matchStarted = true
      InsideLobby.pRects = unitPlacement.pRects
      client:send("startMatchFromLobby", InsideLobby)
    end
  end

end

function unitPlacement.draw()
  -- draw the three placement rectangles
  for k,v in pairs(unitPlacement.pRects) do
      love.graphics.setColor(v.color)
      local x, y, w, h = unpack(v.rect)
      love.graphics.rectangle('line', x, y, w, h)
  end

  UnitPlacementInfoSuit:draw()
  suit.draw()

end

return unitPlacement