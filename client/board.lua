local board = {}

function isMyTurn()
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
      local selectButton = suit.Button(laneKey..tileKey, tileX+40, tileY+40, 20, 20)
      
      if selectButton.hit then
        AskingForTile = false
        TriggerEvent(event, laneKey..tileKey)
      end
      ::next::
    end
  end
end

function board.load()

  -- ! create the tile objects
	board.lanes = {}
	-- the structure is board.lanes.LANENAME.[TILE#]
	-- where LANENAME = r, y, g
	-- TILE# = 1, 2, 3
	for k1, lane in pairs({'r', 'y', 'g'}) do
		board.lanes[lane] = {}
		for k2, _ in pairs( {'_', '_', '_'} ) do
			-- define the tile
			board.lanes[lane][k2] = {}
			-- fancy coordinate mathematics not really fancy
			board.lanes[lane][k2].rect = {10+(315*(k1-1)), 75+(105*(k2-1)), 100, 100}
			board.lanes[lane][k2].content = {}
			-- set the color
			if lane == 'r' then
				board.lanes[lane][k2].color = {1, 0, 0}
			elseif lane == 'y' then
				board.lanes[lane][k2].color = {1, 1, 0}
			elseif lane == 'g' then
				board.lanes[lane][k2].color = {0,.5,0}
			end
		end
	end

	-- ! construct suit themes
	AlliedSuit = suit.new()
	EnemySuit = suit.new()
	CPanelSuit = suit.new()
	InfoPanelSuit = suit.new()
  TurnCounterSuit = suit.new()
  APanelSuit = suit.new()

  -- ! image assets
  Border = love.graphics.newImage('images/gameBorder.png')
	UpArrow = love.graphics.newImage('images/UpArrow.png')
	UpArrowHovered = love.graphics.newImage('images/UpArrowHovered.png')
	DownArrow = love.graphics.newImage('images/DownArrow.png')
	DownArrowHovered = love.graphics.newImage('images/DownArrowHovered.png')
	AttackIcon = love.graphics.newImage('images/AttackIcon.png')
	AttackIconHovered = love.graphics.newImage('images/AttackIconHovered.png')

  -- ! used to manage the turn system
  ActionsRemaining = {primary=1, secondary=2}

  -- ! set the ascendant of this player in the server
  Gamestate['Ascendant'..playerNumber] = Gamestate['myAscendant']
  Gamestate['HasMajorPower'] = true
  Gamestate['HasMinorPower'] = true
  Gamestate['Chosen1UnitsKilled'] = 0
  client:send('updateVar', {'Ascendant'..playerNumber, AscendantIndex})

end

function board.update(dt)

  -- * if we're currently asking for a tile, draw the TileSelection screen
  if AskingForTile then
    TileSelection()
  end

	-- ! everything that is done in each tile is managed in this loop
	for laneKey, lane in pairs(board.lanes) do
	-- for each tile in the lane
		for tileKey, tile in pairs(lane) do
			-- create a Button for each unit inside
			suit.layout:reset(AdjustCenter(tile.rect[1]+5, 'X'), AdjustCenter(tile.rect[2]+5, 'Y'))
			for unitKey, unit in pairs(tile.content) do
				local uid = unit.uid
				-- create the button representing this unit, w/ attached logic
				if unit.player == playerNumber then
					-- if they're friendly units, use friendly theme
					local allyButton = AlliedSuit:Button(unit.name, {id = uid}, suit.layout:row(90,17))
					-- * logic for selecting allied units
					-- when you click an allied unit
					if allyButton.hit then
						-- set it to the ActiveUnit
            ActiveUnit = unit
            TriggerEvent("targetAlly", unit)
            TriggerEvent("targetUnit", unit)
					end
				else
					-- enemy units, use enemy theme
					local enemyButton = EnemySuit:Button(unit.name, {id = uid}, suit.layout:row(90,17))
					-- * logic for targeting enemy units
          if enemyButton.hit then
            ActiveUnit = unit
            TriggerEvent("targetEnemy", unit)
            TriggerEvent("targetUnit", unit)
					end
        end
        
				-- ! ACTIVE UNIT CONTROLS
				if unit == ActiveUnit then
          CPanelSuit.layout:padding(2)
					-- if the tile is in the red or yellow lanes (left or middle), make the cpanel and ipanel to the right
					if laneKey == 'r' or laneKey == 'y' then
						CPanelSuit.layout:reset(AdjustCenter(tile.rect[1]+110, 'X'), AdjustCenter(tile.rect[2]+5, 'Y'))
						InfoPanelSuit.layout:reset(AdjustCenter(tile.rect[1]+140, 'X'), AdjustCenter(tile.rect[2], 'Y'))
					elseif laneKey == 'g' then
						-- else, if it's in green, make the cpanel/ipanel to the left
						CPanelSuit.layout:reset(AdjustCenter(tile.rect[1]-30, 'X'), AdjustCenter(tile.rect[2]+5, 'Y'))
						InfoPanelSuit.layout:reset(AdjustCenter(tile.rect[1]-140, 'X'), AdjustCenter(tile.rect[2],'Y'))
					end
          -- * we only create the parts of the panel that can be used

          -- ! CONTROL PANEL
          -- * overall, we only create the control panel if its our turn and if the activeUnit is allied
          if isMyTurn() and (ActiveUnit.player == playerNumber) then
            -- ! MOVE BUTTONS
            if (ActionsRemaining.secondary >= 1) and ActiveUnit.canMove then
              -- ? repeated code here, could possibly be optimized
              
              if tileKey ~= 1 then
                -- if not in the "upmost" tile, have a down arrow
                local moveUp = CPanelSuit:ImageButton(UpArrow, {hovered=UpArrowHovered}, CPanelSuit.layout:row(20,20))
                if moveUp.hit then
                  -- first, get the current tile
                  local tileRef = laneKey..tileKey
                  -- then, figure out what tile is below
                  local newTileKey = tileKey-1
                  local newTileRef = laneKey..newTileKey
                  -- then, send the move message to the server
                  client:send("unitMove", {unit, tileRef, newTileRef})
                  -- TODO: action
                end
              end
              if tileKey ~= 3 then
                -- if not in the "downmost" tile, have a down arrow
                local moveDown = CPanelSuit:ImageButton(DownArrow, {hovered=DownArrowHovered}, CPanelSuit.layout:row(20,20))
                if moveDown.hit then
                  -- first, get the current tile
                  local tileRef = laneKey..tileKey
                  -- then, figure out what tile is below
                  local newTileKey = tileKey+1
                  local newTileRef = laneKey..newTileKey
                  -- then, send the move message to the server
                  client:send("unitMove", {unit, tileRef, newTileRef})
                  -- TODO: action
                end
              end

              -- empty label for spacing
              CPanelSuit:Label('', CPanelSuit.layout:row(3,3))
            end


            -- ! ABILITY BUTTON
            if ((ActionsRemaining.secondary >= 1) and (ActiveUnit.canSpecial) and (ActiveUnit.specTable['specRef'] ~= nil)) then
              -- use ability button
              local useAbilityButton = CPanelSuit:Button('A', CPanelSuit.layout:row(20,20))
              if useAbilityButton.hit then
                local specFunc = unitSpecs[unit.specTable.specRef]
                specFunc(unit)
              end
              -- empty label for spacing
              CPanelSuit:Label('', CPanelSuit.layout:row(3,3))
            end

            -- ! ATTACK BUTTON
            if (ActionsRemaining.primary >= 1) and ActiveUnit.canAttack then
              -- attack Button with logic
              local attackButton = CPanelSuit:ImageButton(AttackIcon, {hovered=AttackIconHovered}, CPanelSuit.layout:row(20,20))
              if attackButton.hit then
                -- create an alert asking for an attack target
                CreateAlert('Select an attack target.', 5)
                -- queue up an attack  on a enemyTarget
                WaitFor("targetEnemy", client.send, {client, "unitAttack", {unit, 'triggerArgs'} })
              end
            end

            -- ! IMPERATOR BRIDGE
            if (ActionsRemaining.secondary >= 1) and ActiveUnit.canMove and ActiveImperatorBridge then
              local tileRef = laneKey..tileKey
              if (ActiveImperatorBridge[1] == tileRef) or (ActiveImperatorBridge[2] == tileRef) then
                -- spacer
                CPanelSuit:Label('', CPanelSuit.layout:row(3,3))
                -- draw the bridge icon
                local bridgeButton = CPanelSuit:Button('Br', CPanelSuit.layout:row(20,20))
                if bridgeButton.hit then
                  local tileToTravelTo
                  if ActiveImperatorBridge[1] == tileRef then tileToTravelTo = ActiveImperatorBridge[2]
                  elseif ActiveImperatorBridge[2] == tileRef then tileToTravelTo = ActiveImperatorBridge[1] end
                  client:send("unitMove", {unit, tileRef, tileToTravelTo})
                end
              end
            end
          end

          -- ! INFOPANEL
          -- * we always draw the info panel for the selected unit
					-- name of selected unit
					InfoPanelSuit:Label(unit.name, InfoPanelSuit.layout:row(100,20))
					-- atk and hp
					local statString = string.format('%sATK | %sHP', unit.attack, unit.health)
					InfoPanelSuit:Label(statString, InfoPanelSuit.layout:row(100,20))
					-- description of special
					local shortSpecialDesc = unit.specTable.shortDesc
          InfoPanelSuit:Label(shortSpecialDesc, InfoPanelSuit.layout:row(100,20))
				end
			end
		end
  end
  
	-- ! TURN COUNTER
	TurnCounterSuit.layout:reset(0,0)
  TurnCounterSuit.layout:padding(1)
  local currentTurn = Gamestate.turnNumber
  TurnCounterSuit:Button('Turn '..currentTurn, TurnCounterSuit.layout:row(130,20))
  if isMyTurn() then
    local endTurnButton = TurnCounterSuit:Button('End your turn', TurnCounterSuit.layout:row())
    if endTurnButton.hit then client:send("endMyTurn", {}) end
  else
    TurnCounterSuit:Button('Enemy turn', TurnCounterSuit.layout:row())
  end

  -- counter for amount of secondary actions
  local secondaryText = string.format('%s Secondary Action', ActionsRemaining.secondary)
  -- pluralize
  if ActionsRemaining.secondary ~= 1 then secondaryText = secondaryText..'s' end
  TurnCounterSuit:Button(secondaryText, TurnCounterSuit.layout:col())

  -- counter for amount of primary actions
  local primaryText = string.format('%s Primary Action', ActionsRemaining.primary)
  -- pluralize
  if ActionsRemaining.primary ~= 1 then primaryText = primaryText..'s' end
  TurnCounterSuit:Button(primaryText, TurnCounterSuit.layout:up())

  -- ! ASCENDANT ACTIONS
  if isMyTurn() then
    APanelSuit.layout:reset(centerX-150, centerY+230)
    -- major action
    local majorPower = {}
    if Gamestate['HasMajorPower'] then
      majorPower = APanelSuit:Button('Major Power', APanelSuit.layout:col(100,20))
    end
    if majorPower.hit then
      local ascIndex = Gamestate['Ascendant'..playerNumber]
      local asc = ascendantList[ascIndex]
      asc.majorFunc()
    end
    -- minor power
    local minorPower = {}
    if Gamestate['HasMinorPower'] then
      minorPower = APanelSuit:Button('Minor Power', APanelSuit.layout:col(100,20))
    end
      if minorPower.hit then
      local ascIndex = Gamestate['Ascendant'..playerNumber]
      local asc = ascendantList[ascIndex]
      asc.minorFunc()
    end
    -- incarnate
    local incarnate = APanelSuit:Button('Incarnate', APanelSuit.layout:col(100,20))
    if incarnate.hit then
      local ascIndex = Gamestate['Ascendant'..playerNumber]
      local asc = ascendantList[ascIndex]
      asc.incarnateFunc()
    end
    -- info button
    local infoButton = APanelSuit:Button('?', APanelSuit.layout:col(20,20))
    if infoButton.hit then
      local ascIndex = Gamestate['Ascendant'..playerNumber]
      local asc = ascendantList[ascIndex]
      CreatePopupDisplay('Ascendant Powers', {'Victory Condition', 'Major', 'Minor', 'Incarnate'}, {asc.victoryText, asc.majorText, asc.minorText, 'coming soon! doesn\'t work right now'})
    end
  end

  -- * check if out of actions (end turn)
  -- only check if it's your turn to begin with
  if isMyTurn() then
    if (ActionsRemaining.primary == 0) and (ActionsRemaining.secondary == 0) then
      print('Player out of actions')
      client:send("endMyTurn", {})
    end
  end

end

function board.draw()
  -- draw the game border
  love.graphics.draw(Border,centerX-480,centerY-270)
  -- draw the textured background
  love.graphics.setBackgroundColor(10/255,10/255,10/255)

  -- ! draw each individual tile
	-- first, get each lane
	for k, lane in pairs(board.lanes) do
		-- then, get each tile in that lane
		for _, tile in pairs(lane) do
      love.graphics.setColor(tile.color)
      local x, y, w, h = unpack(tile.rect)
      -- draw each tile
      love.graphics.rectangle('line', AdjustCenter(x, 'X'), AdjustCenter(y, 'Y'),w,h)
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
  TurnCounterSuit.theme.color.normal.fg = {186/255,186/255,186/255}
  InfoPanelSuit:draw()
  
	-- draw the turn counter
	TurnCounterSuit.theme.color.normal.bg = {186/255,186/255,186/255}
	TurnCounterSuit.theme.color.normal.fg = {0,0,0}
  TurnCounterSuit:draw()

  -- draw the ascendant panel
  APanelSuit:draw()

  -- draw selection options, if present
  suit.draw()
end

return board
