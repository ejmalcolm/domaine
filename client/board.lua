local board = {}

function IsMyTurn()
  return CurrentTurnTaker == playerNumber
end

function TileSelection()
  -- * creates a tile selection interface, with a button over each tile of the board
  -- * when a button is clicked, a "tileSelected" event is sent
  local event
  -- used if we want to change what event results from picking a tile
  if AskingForTile == true then event = "tileSelected" else event = AskingForTile end
  -- we generate a button in each tile
  local lanes = board.lanes
  for laneKey, lane in pairs(lanes) do
    for tileKey, tile in pairs(lane) do

      -- we check if horizontalAdjacent
      if (type(event) == 'table') and (event[1] == 'adjacentHorizontal') then
        local casterTile = (event[2]).tile
        local checkTile = laneKey..tileKey
        local l1, t1 = casterTile:sub(1,1), casterTile:sub(2,2)
        local l2, t2 = checkTile:sub(1,1), checkTile:sub(2,2)
        local lanesAreAdjacent = adjacentLanes(l1, l2)
        if (not lanesAreAdjacent) or (t1 ~= t2) then
          goto next
        end
      end

      local tileX, tileY = AdjustCenter(tile.rect[1], 'X'), AdjustCenter(tile.rect[2], 'Y')
      local selectButton = suit.Button(laneKey..tileKey, tileX+40, tileY+65, 20, 20)
      
      if selectButton.hit then
        AskingForTile = false
        TriggerEvent(event, laneKey..tileKey)
      end
      ::next::
    end
  end
end

function GetPlayerVar(name)
  return (MatchState['Player'..playerNumber])[name]
end

function GetActionAmount(type)
  local translator = {move=1,attack=2,special=3}
  return GetPlayerVar('ActionTable')[translator[type]]
end

function ChangeActionAmount(type, new_amount)
  local newActionTable = GetPlayerVar('ActionTable')
  local translator = {move=1,attack=2,special=3}
  newActionTable[translator[type]] = new_amount
  ChangePlayerVar('ActionTable', newActionTable)
end

function board.load()

  -- ! create the tile objects
	board.lanes = {}
	-- the structure is board.lanes.LANENAME.[TILE#]
	-- where LANENAME = r, y, g
	-- TILE# = 1, 2, 3
	for k1, lane in pairs({'r', 'y', 'b'}) do
		board.lanes[lane] = {}
		for k2, _ in pairs( {'_', '_', '_'} ) do
			-- define the tile
			board.lanes[lane][k2] = {}
			-- fancy coordinate mathematics not really fancy
      board.lanes[lane][k2].rect = {195+(340*(k1-1)), 100+(187*(k2-1)), 200, 150}
      board.lanes[lane][k2].content = {}
			-- set the color
			if lane == 'r' then
				board.lanes[lane][k2].color = {1, 0, 0}
			elseif lane == 'y' then
				board.lanes[lane][k2].color = {1, 1, 0}
			elseif lane == 'b' then
				board.lanes[lane][k2].color = {0,0,1}
			end
		end
	end

	-- ! construct suit themes
	AlliedSuit = suit.new()
  EnemySuit = suit.new()

  CPanelSuit = suit.new()
  CBarSuit = suit.new()
  CBarOrbsSuit = suit.new()

  CtrlSuit = suit.new()
	InfoPanelSuit = suit.new()
  TurnCounterSuit = suit.new()

  APanelSuit = suit.new()

  ActionCounterSuit = suit.new()
  ActionCounterLabelsSuit = suit.new()

  -- ! image assets

  Background = love.graphics.newImage('images/BoardUI/UIBackground.png')

  TurnOrb = love.graphics.newImage('images/BoardUI/TurnCounter.png')

  ActionCounter = love.graphics.newImage('images/BoardUI/ActionCounter.png')

  ControlBar = love.graphics.newImage('images/BoardUI/ControlBar.png')
  MoveUpOrb = love.graphics.newImage('images/BoardUI/MoveUpOrb.png')
  MoveDownOrb = love.graphics.newImage('images/BoardUI/MoveDownOrb.png')
  AttackOrb = love.graphics.newImage('images/BoardUI/AttackOrb.png')
  SpecialOrb = love.graphics.newImage('images/BoardUI/SpecialOrb.png')
  InspectOrb = love.graphics.newImage('images/BoardUI/InspectOrb.png')
  BridgeOrb = love.graphics.newImage('images/BoardUI/BridgeOrb.png')

  MajorPowerButton = love.graphics.newImage('images/BoardUI/MajorButton.png')
  MinorPowerButton = love.graphics.newImage('images/BoardUI/MinorButton.png')
  IncarnatePowerButton = love.graphics.newImage('images/BoardUI/IncarnateButton.png')

end

function board.update(dt)

  -- * if we're currently asking for a tile, draw the TileSelection screen
  if AskingForTile then
    TileSelection()
  end

	-- ! UNITS IN TILES
	for laneKey, lane in pairs(board.lanes) do
    for tileKey, tile in pairs(lane) do

      -- ! ALIGN LAYOUTS TO THE TILE
      AlliedSuit.layout:reset(tile.rect[1]+27, tile.rect[2]+(tile.rect[4]-69))
      AlliedSuit.layout:padding(5)
      -- allies start from bottom right 
      EnemySuit.layout:reset(tile.rect[1]+27, tile.rect[2]+5)
      EnemySuit.layout:padding(5)
      local alliesInTile, enemiesInTile = 0, 0

			for unitKey, unit in pairs(tile.content) do
        local uid = unit.uid
        local unitButton

        -- ! CREATE UNITS
        if unit.player == playerNumber then

          alliesInTile = alliesInTile + 1

          if alliesInTile ~= 5 then
            unitButton = AlliedSuit:Button(unit.name, {id = uid}, AlliedSuit.layout:col(64,64))
          else
            -- the fifth unit takes point position
            AlliedSuit.layout:reset(tile.rect[1]+130, tile.rect[2]+(tile.rect[4]-138))
            unitButton = AlliedSuit:Button(unit.name, {id = uid}, AlliedSuit.layout:down(64,64))
          end

					-- * logic for selecting allied units
					-- when you click an allied unit
          if unitButton.hit then
            ActiveUnit = unit
            -- if shift is down: inspect special
            if love.keyboard.isDown('lshift') then
              local unitDesc = unit.attack..' ATK | '..unit.health..' HP \n'..(unit.specTable.fullDesc)
              CreatePopupDisplay(unit.name, {'Special'}, {unitDesc})
            else
              -- otherwise: targeting mode
              TriggerEvent("targetAlly", unit)
              TriggerEvent("targetUnit", unit)
            end
          end

      -- ! CREATE ENEMY UNITS
        else
          enemiesInTile = enemiesInTile + 1
          -- for the first two units, we go bottom right, bottom left
          if enemiesInTile ~= 5 then
            unitButton = EnemySuit:Button(unit.name, {id = uid}, EnemySuit.layout:col(64,64))
          else
            unitButton = EnemySuit:Button(unit.name, {id = uid}, EnemySuit.layout:up(64,64))
          end

					-- * logic for targeting enemy units
          if unitButton.hit then
            ActiveUnit = unit
            -- if shift is down: inspect special
            if love.keyboard.isDown('lshift') then
              local unitDesc = unit.attack..'|'..unit.health..'\n'..(unit.specTable.fullDesc)
              CreatePopupDisplay(unit.name, {'Description'}, {unitDesc})
            else
              -- otherwise: targeting mode
              TriggerEvent("targetEnemy", unit)
              TriggerEvent("targetUnit", unit)
            end
          end
        end

				-- ! ACTIVE UNIT CONTROLS
				if unit == ActiveUnit then
          CPanelSuit.layout:padding(2)
          CPanelSuit.layout:reset(tile.rect[1]+5+(84*(alliesInTile-1)), tile.rect[2]+69)
          CPanelSuit.layout:reset(unitButton.x-20, unitButton.y)
          -- * we only create the parts of the panel that can be used

          -- ! UNIT QUICK CONTROLS
          if IsMyTurn() and (ActiveUnit.player == playerNumber) and (love.keyboard.isDown('lctrl')) then


            -- -- ! MOVE BUTTONS
            -- if (ActionsRemaining.secondary >= 1) and ActiveUnit.canMove then
            --   -- ? repeated code here, could possibly be optimized

            --   if tileKey ~= 1 then
            --     -- if not in the "upmost" tile, have a down arrow
            --     local moveUp = CPanelSuit:ImageButton(UpArrow, {hovered=UpArrowHovered}, CPanelSuit.layout:row(20,20))
            --     if moveUp.hit then
            --       -- first, get the current tile
            --       local tileRef = laneKey..tileKey
            --       -- then, figure out what tile is below
            --       local newTileKey = tileKey-1
            --       local newTileRef = laneKey..newTileKey
            --       -- then, send the move message to the server
            --       client:send("unitMove", {unit, tileRef, newTileRef})
            --       -- TODO: action
            --     end
            --   end
            --   if tileKey ~= 3 then
            --     -- if not in the "downmost" tile, have a down arrow
            --     local moveDown = CPanelSuit:ImageButton(DownArrow, {hovered=DownArrowHovered}, CPanelSuit.layout:row(20,20))
            --     if moveDown.hit then
            --       -- first, get the current tile
            --       local tileRef = laneKey..tileKey
            --       -- then, figure out what tile is below
            --       local newTileKey = tileKey+1
            --       local newTileRef = laneKey..newTileKey
            --       -- then, send the move message to the server
            --       client:send("unitMove", {unit, tileRef, newTileRef})
            --       -- TODO: action
            --     end
            --   end

            --   -- empty label for spacing
            --   CPanelSuit:Label('', CPanelSuit.layout:row(3,3))
            -- end
            -- -- ! ABILITY BUTTON
            -- if ((ActionsRemaining.secondary >= 1) and (ActiveUnit.canSpecial) and (ActiveUnit.specTable['specRef'] ~= nil)) then
            --   -- use ability button
            --   local useAbilityButton = CPanelSuit:Button('A', CPanelSuit.layout:row(20,20))
            --   if useAbilityButton.hit then
            --     local specFunc = unitSpecs[unit.specTable.specRef]
            --     specFunc(unit)
            --   end
            --   -- empty label for spacing
            --   CPanelSuit:Label('', CPanelSuit.layout:row(3,3))
            -- end
            -- -- ! ATTACK BUTTON
            -- if (ActionsRemaining.primary >= 1) and ActiveUnit.canAttack then
            --   -- attack Button with logic
            --   local attackButton = CPanelSuit:ImageButton(AttackIcon, {hovered=AttackIconHovered}, CPanelSuit.layout:row(20,20))
            --   if attackButton.hit then
            --     -- create an alert asking for an attack target
            --     CreateAlert('Select an attack target.', 5)
            --     -- queue up an attack  on a enemyTarget
            --     WaitFor("targetEnemy", function(targetEnemy)
                  
            --       client:send("unitTargetCheck", {targetEnemy, unit, {canBeAttacked=true}, {} })
            --       WaitFor(targetEnemy.uid.."TargetSucceed", function()
            --         client:send("unitAttack", {unit, targetEnemy})
            --       end, {'triggerArgs'})

            --     end, {'triggerArgs'})
            --   end
            -- end
            -- -- ! IMPERATOR BRIDGE
            -- if (ActionsRemaining.secondary >= 1) and ActiveUnit.canMove and ActiveImperatorBridge then
            --   local tileRef = laneKey..tileKey
            --   if (ActiveImperatorBridge[1] == tileRef) or (ActiveImperatorBridge[2] == tileRef) then
            --     -- spacer
            --     CPanelSuit:Label('', CPanelSuit.layout:row(3,3))
            --     -- draw the bridge icon
            --     local bridgeButton = CPanelSuit:Button('Br', CPanelSuit.layout:row(20,20))
            --     if bridgeButton.hit then
            --       local tileToTravelTo
            --       if ActiveImperatorBridge[1] == tileRef then tileToTravelTo = ActiveImperatorBridge[2]
            --       elseif ActiveImperatorBridge[2] == tileRef then tileToTravelTo = ActiveImperatorBridge[1] end
            --       client:send("unitMove", {unit, tileRef, tileToTravelTo})
            --     end
            --   end
            -- end
          end

        end

        -- ! INFOPANEL
        if unitButton.hovered then

          InfoPanelSuit.layout:reset(unitButton.x-10, unitButton.y-30)
          InfoPanelSuit.layout:padding(0)

          -- name of selected unit
          InfoPanelSuit:Label(unit.name, InfoPanelSuit.layout:row(85,15))

          -- atk and hp
          local statString = string.format('%s|%s', unit.attack, unit.health)
          InfoPanelSuit:Label(statString, InfoPanelSuit.layout:row())

        end

			end
		end
  end

	-- ! TURN COUNTER
	TurnCounterSuit.layout:reset(33,11)
  local currentTurn = MatchState.turnNumber

  -- * create turn orb/counter

  local turnButton = TurnCounterSuit:ImageButton(TurnOrb, TurnCounterSuit.layout:row(71,69))

  TurnCounterSuit.layout:reset(47,25)

  local font = love.graphics.newFont(20) -- the number denotes the font size
  love.graphics.setFont(font)

  TurnCounterSuit:Label(currentTurn, TurnCounterSuit.layout:row(40, 40))

  local font = love.graphics.newFont(12) -- the number denotes the font size
  love.graphics.setFont(font)

  -- * press orb to end turn

  if IsMyTurn() then
    if turnButton.hit then client:send("endMyTurn", {}) end
  end

  -- ! ACTION COUNTER

  ActionCounterSuit.layout:reset(1147, 5)

  ActionCounterSuit:ImageButton(ActionCounter, ActionCounterSuit.layout:row(126, 38))

  local font = love.graphics.newFont(16) -- the number denotes the font size
  love.graphics.setFont(font)

  -- get the current turn taker's action count
  local currentActionTable = MatchState['Player'..CurrentTurnTaker]['ActionTable']

  -- attack actions
  ActionCounterLabelsSuit.layout:reset(1150, 15)
  ActionCounterLabelsSuit:Label(currentActionTable[1], ActionCounterLabelsSuit.layout:row(20, 20))

  -- move actions
  ActionCounterLabelsSuit.layout:reset(1190, 15)
  ActionCounterLabelsSuit:Label(currentActionTable[2], ActionCounterLabelsSuit.layout:row(20, 20))

  -- special actions
  ActionCounterLabelsSuit.layout:reset(1230, 15)
  ActionCounterLabelsSuit:Label(currentActionTable[3], ActionCounterLabelsSuit.layout:row(20, 20))

  local font = love.graphics.newFont(12) -- the number denotes the font size
  love.graphics.setFont(font)


  -- ! CONTROL BAR

  -- create actual bar
  CBarSuit.layout:reset(43, 188)
  CBarSuit:ImageButton(ControlBar, CBarSuit.layout:row(55, 343))

  if ActiveUnit then
    local tileRef = ActiveUnit.tile
    local laneKey, tileKey = tileRef:sub(1,1), tonumber(tileRef:sub(2,2))

    -- at the top of the control bar, write the name of the unit
    InfoPanelSuit.layout:reset(18, 168)
    InfoPanelSuit:Label(ActiveUnit.name, InfoPanelSuit.layout:row(100,20))

    if ActiveUnit.player == playerNumber and IsMyTurn() then


      if GetActionAmount('move') == 0 then goto skipMoves end
      if ActiveUnit then
        if not ActiveUnit.canMove then goto skipMoves end
      end
        -- MOVE UP
      CBarOrbsSuit.layout:reset(45, 223)
      if tileKey ~= 1 then
        local UpOrbButton = CBarOrbsSuit:ImageButton(MoveUpOrb, CBarOrbsSuit.layout:row(46, 39))
        if UpOrbButton.hit then
          -- then, figure out what tile is below
          local newTileKey = tileKey-1
          local newTileRef = laneKey..newTileKey
          -- use action
          ChangeActionAmount('move', GetActionAmount('move')-1)
          -- then, send the move message to the server
          client:send("unitMove", {ActiveUnit, tileRef, newTileRef, true})
          ActiveUnit = nil
        end
      end
      ::skipUp::

      -- MOVE DOWN
      CBarOrbsSuit.layout:reset(45, 281)
      if tileKey ~= 3 then
        local DownOrbButton = CBarOrbsSuit:ImageButton(MoveDownOrb, CBarOrbsSuit.layout:row(46, 39))
        if DownOrbButton.hit then
          -- then, figure out what tile is below
          local newTileKey = tileKey+1
          local newTileRef = laneKey..newTileKey
          -- use action
          ChangeActionAmount('move', GetActionAmount('move')-1)
          -- then, send the move message to the server
          client:send("unitMove", {ActiveUnit, tileRef, newTileRef, true})
          ActiveUnit = nil
        end
      end
      ::skipDown::
      ::skipMoves::

      if GetActionAmount('attack') == 0 then goto skipAttack end
      if ActiveUnit then -- safeguard in case ActiveUnit gets cleared mid-thing
        if not ActiveUnit.canAttack then goto skipAttack end
      end
      -- ATTACK
      do
        CBarOrbsSuit.layout:reset(45, 339)
        local AttackOrbButton = CBarOrbsSuit:ImageButton(AttackOrb, CBarOrbsSuit.layout:row(46, 39))
        if AttackOrbButton.hit then
          -- create an alert asking for an attack target
          CreateAlert('Select an attack target.', 5)
          -- queue up an attack on a enemyTarget
          local attacker = ActiveUnit
          WaitFor("targetEnemy", function(targetEnemy)
            client:send("unitTargetCheck", {targetEnemy, attacker, {canBeAttacked=true, distanceBetweenIs=0}, {} })

            WaitFor(targetEnemy.uid.."TargetSucceed", function()
              ChangeActionAmount('attack', GetActionAmount('attack')-1)
              client:send("unitAttack", {attacker, targetEnemy})
              ActiveUnit = nil
            end, {'triggerArgs'})

          end, {'triggerArgs'})
          
        end
      end
      ::skipAttack::

      if GetActionAmount('special') == 0 then goto skipSpecial end
      if ActiveUnit then
        if not ActiveUnit.canSpecial then goto skipSpecial end
      end
      -- SPECIAL
      do
        CBarOrbsSuit.layout:reset(45, 396)
        local SpecialOrbButton = CBarOrbsSuit:ImageButton(SpecialOrb, CBarOrbsSuit.layout:row(46, 39))
        if SpecialOrbButton.hit then
          local specFunc = unitSpecs[ActiveUnit.specTable.specRef]
          specFunc(ActiveUnit)
          ActiveUnit = nil
        end
      end
      ::skipSpecial::

    end

    -- INSPECT * note that it is NOT in the previous if block (you don't need to control it)
    CBarOrbsSuit.layout:reset(45, 454)
    local InspectOrbButton = CBarOrbsSuit:ImageButton(InspectOrb, CBarOrbsSuit.layout:row(46, 39))
    if InspectOrbButton.hit then
      local unitDesc = ActiveUnit.attack..'|'..ActiveUnit.health..'\n'..(ActiveUnit.specTable.fullDesc)
      CreatePopupDisplay(ActiveUnit.name, {'Description'}, {unitDesc})
    end

    -- ! imperator bridge
    CBarOrbsSuit.layout:reset(45, 540)
    if ActiveImperatorBridge and GetActionAmount('move') ~= 0 then

      -- if unit is in the tile with the bridge
      if (ActiveImperatorBridge[1] == tileRef) or (ActiveImperatorBridge[2] == tileRef) then

        local BridgeOrbButton = CBarOrbsSuit:ImageButton(BridgeOrb, CBarOrbsSuit.layout:row(46, 39))
        if BridgeOrbButton.hit then
          local tileToTravelTo
          if ActiveImperatorBridge[1] == tileRef then tileToTravelTo = ActiveImperatorBridge[2]
          elseif ActiveImperatorBridge[2] == tileRef then tileToTravelTo = ActiveImperatorBridge[1] end
          client:send("unitMove", {ActiveUnit, tileRef, tileToTravelTo, true})
          ActiveUnit = nil
          ChangeActionAmount('move', GetActionAmount('move')-1)
        end

      end

    end

  end -- end of control panel buttons

  -- ! ASCENDANT ACTIONS
  if IsMyTurn() then
    APanelSuit.layout:reset(433, 683)

    -- major action
    if GetPlayerVar('HasMajorPower') then
      local majorPower = APanelSuit:ImageButton(MajorPowerButton, APanelSuit.layout:row(126,27))
      if majorPower.hit then
        local ascIndex = GetPlayerVar('AscendantIndex')
        local asc = ascendantList[ascIndex]
        asc.majorFunc()
        ChangePlayerVar('HasMajorPower', false)
      end
    end

    APanelSuit.layout:reset(575, 683)
    -- minor power
    if GetPlayerVar('HasMinorPower') then
      local minorPower = APanelSuit:ImageButton(MinorPowerButton, APanelSuit.layout:row(126,27))

      if minorPower.hit then
        local ascIndex = GetPlayerVar('AscendantIndex')
        local asc = ascendantList[ascIndex]
        asc.minorFunc()

        ChangePlayerVar('HasMinorPower', false)
        local uniqueEvent = playerNumber..'RegainMinorPower'
        client:send("queueTimedEvent", {uniqueEvent, 3, {}})
        WaitFor(uniqueEvent, function()
          ChangePlayerVar('HasMinorPower', true)
        end, {})

      end
    end

    APanelSuit.layout:reset(716, 683)
    -- incarnate
    if GetPlayerVar('HasIncarnatePower') then
      local incarnate = APanelSuit:ImageButton(IncarnatePowerButton, APanelSuit.layout:row(126,27))
      if incarnate.hit then
        local ascIndex = GetPlayerVar('AscendantIndex')
        local asc = ascendantList[ascIndex]
        asc.incarnateFunc()
        ChangePlayerVar('HasIncarnatePower', false)
      end
    end

    -- info button
    APanelSuit.layout:padding(10)
    local infoButton = APanelSuit:Button('?', APanelSuit.layout:col(20,20))
    if infoButton.hit then
      local ascIndex = GetPlayerVar('AscendantIndex')
      local asc = ascendantList[ascIndex]
      CreatePopupDisplay('Ascendant Powers', {'Victory Condition', 'Major', 'Minor', 'Incarnate'}, {asc.victoryText, asc.majorText, asc.minorText, asc.incarnateText})
    end
  end

  -- * check if out of actions (end turn)
  -- only check if it's your turn to begin with
  if IsMyTurn() then
    -- if (ActionsRemaining.primary == 0) and (ActionsRemaining.secondary == 0) then
    --   print('Player out of actions')
    --   client:send("endMyTurn", {})
    -- end
  end

end

function board.draw()
  -- draw the game border
  love.graphics.draw(Background,0,0)
  -- draw the textured background
  love.graphics.setBackgroundColor(10/255,10/255,10/255)

  -- ! draw each individual tile
	-- first, get each lane
	for _, lane in pairs(board.lanes) do
		-- then, get each tile in that lane
		for _, tile in pairs(lane) do
      love.graphics.setColor(tile.color)
      local x, y, w, h = unpack(tile.rect)
      -- draw each tile
      love.graphics.rectangle('line', x, y,w,h)
		end
  end

	-- set the allied theme, then draw allied units
	AlliedSuit.theme.color.normal.bg = {8/255,63/255,33/255}
  AlliedSuit:draw()

	-- set the enemy theme, then draw enemy 
	EnemySuit.theme.color.normal.bg = {128/255,0/255,0/255}
  EnemySuit:draw()

	-- draw the control panel
  -- this is the default gray/silver color
	love.graphics.setColor({186,186,186})
	CPanelSuit.theme.color.normal.bg = {0.25, 0.25, 0.25}
	CPanelSuit.theme.color.hovered.bg = {231/255, 95/255, 98/255}
  CPanelSuit:draw()

	-- draw the info panel
  love.graphics.setColor({255,255,255})
  InfoPanelSuit.theme.color.normal.fg = {255,255,255}
  InfoPanelSuit:draw()

	-- draw the turn counter
	TurnCounterSuit.theme.color.normal.bg = {186/255,186/255,186/255}
	TurnCounterSuit.theme.color.normal.fg = {255,255,255}
  TurnCounterSuit:draw()

  -- draw action turn counter
  ActionCounterSuit:draw()
  ActionCounterLabelsSuit.theme.color.normal.fg = {0,0,0}
  ActionCounterLabelsSuit:draw()

  -- draw the ascendant panel
  APanelSuit.theme.color.normal.fg = {0,0,0}
  APanelSuit:draw()

  -- draw control bar
  CBarSuit:draw()
  -- draw control orbs
  CBarOrbsSuit:draw()

  -- draw selection options, if present
  suit.draw()
end

return board
