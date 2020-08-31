local board = {}

local suit = require("suit")

function isMyTurn()
  return CurrentTurnTaker == playerNumber
end

function board.load()
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

	-- construct suit themes
	AlliedSuit = suit.new()
	EnemySuit = suit.new()
	CPanelSuit = suit.new()
	InfoPanelSuit = suit.new()
	TurnCounterSuit = suit.new()

	-- image assets
	UpArrow = love.graphics.newImage('UpArrow.png')
	UpArrowHovered = love.graphics.newImage('UpArrowHovered.png')
	DownArrow = love.graphics.newImage('DownArrow.png')
	DownArrowHovered = love.graphics.newImage('DownArrowHovered.png')
	AttackIcon = love.graphics.newImage('AttackIcon.png')
	AttackIconHovered = love.graphics.newImage('AttackIconHovered.png')

  -- used to manage the turn system
  ActionsRemaining = {primary=1, secondary=1}

end

function board.update(dt)
	-- ! everything that is done in each tile is managed in this loop
	for laneKey, lane in pairs(board.lanes) do
	-- for each tile in the lane
		for tileKey, tile in pairs(lane) do
			-- create a Button for each unit inside
			suit.layout:reset(tile.rect[1]+5, tile.rect[2]+5)
			for unitKey, unit in pairs(tile.content) do
				-- each unit has the following format:
				-- {uid= 'Rand0', name='Rand', player=1, cost=2, attack=3, health=6}
				local uid = unit.uid
				-- create the button representing this unit, w/ attached logic
				if unit.player == playerNumber then
					-- if they're friendly units, use friendly theme
					local friendButton = AlliedSuit:Button(unit.name, {id = uid}, suit.layout:row(90,17))
					-- * logic for selecting allied units
					-- when you click an allied unit
					if friendButton.hit then
						-- set it to the ActiveUnit
						print('The active unit is: '.. uid)
						ActiveUnit = unit
					end
				else
					-- enemy units, use enemy theme
					local enemyButton = EnemySuit:Button(unit.name, {id = uid}, suit.layout:row(90,17))
					-- * logic for targeting enemy units
					if enemyButton.hit then
						local tileRef = laneKey..tileKey
						TriggerEvent('targetEnemy', {unit, tileRef})
					end
				end
				-- if this unit is the active unit, activate the control panel and the info panel
				if unit == ActiveUnit then
          CPanelSuit.layout:padding(2)
					-- if the tile is in the red or yellow lanes (left or middle), make the cpanel and ipanel to the right
					if laneKey == 'r' or laneKey == 'y' then
						CPanelSuit.layout:reset(tile.rect[1]+110, tile.rect[2]+5)
						InfoPanelSuit.layout:reset(tile.rect[1]+140, tile.rect[2])
					elseif laneKey == 'g' then
						-- else, if it's in green, make the cpanel/ipanel to the left
						CPanelSuit.layout:reset(tile.rect[1]-30, tile.rect[2]+5)
						InfoPanelSuit.layout:reset(tile.rect[1]-140, tile.rect[2])
					end
          -- * control panel creation
          -- * we only create the parts of the panel that can be used
          -- overall, we only create the control panel if its our turn
          if isMyTurn() then
          -- move buttons if we have secondary actions
            if ActionsRemaining.secondary >= 1 then
              -- ! repeated code here, could possibly be optimized
              -- move up/down arrows
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
                end
              end
            end
            -- attack/ability button if we have primary actions
            if ActionsRemaining.primary >= 1 then
              -- attack Button with logic
              local attackButton = CPanelSuit:ImageButton(AttackIcon, {hovered=AttackIconHovered}, CPanelSuit.layout:row(20,20))
              if attackButton.hit then
                -- create an alert asking for an attack target
                CreateAlert('Select an attack target.', 5)
                -- queue up an attack  on a enemyTarget
                local tileRef = laneKey..tileKey
                WaitFor('targetEnemy', client.send, {client, "unitAttack", {unit, tileRef, 'triggerArgs'} })
              end
              -- empty label for spacing
              CPanelSuit:Label('', CPanelSuit.layout:row(3,3))
              -- use ability button
              local useAbilityButton = CPanelSuit:Button('A', CPanelSuit.layout:row(20,20))
            end
          end
          -- * infopanel creation
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
  
	-- * create the turn counter
	TurnCounterSuit.layout:reset(0,0)
  TurnCounterSuit.layout:padding(1)
  TurnCounterSuit:Button('Turn X', TurnCounterSuit.layout:row(130,20))
  if isMyTurn() then
    local endTurnButton = TurnCounterSuit:Button('End your turn', TurnCounterSuit.layout:row())
    if endTurnButton.hit then client:send("endMyTurn") end
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

  -- * check if out of actions (end turn)
  -- only check if it's your turn to begin with
  if isMyTurn() then
    local outOfActions = true
    for k, v in pairs(ActionsRemaining) do 
      if v >= 1 then
        -- if there are any actions not at 0, keep going
        outOfActions = false
      end
    end
    if outOfActions then client:send("endMyTurn") end
    if outOfActions then print(playerNumber..' out of actions') end
  end
end

function board.draw()
	-- first, get each lane
	for k, lane in pairs(board.lanes) do
		-- then, get each tile in that lane
		for _, tile in pairs(lane) do
			love.graphics.setColor(tile.color)
			love.graphics.rectangle('line', unpack(tile.rect))
		end
	end
	-- draw board tiles
	suit.draw()
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
	love.graphics.setColor({186,186,186})
	InfoPanelSuit:draw()
	-- draw the turn counter
	CPanelSuit.theme.color.normal.bg = {186/255,186/255,186/255}
	CPanelSuit.theme.color.normal.fg = {0,0,0}
	TurnCounterSuit:draw()
	-- after all the theme fuckery everywhere else its good to reset the theme back to default
	suit.theme.color = {
		normal   = {bg = { 0.25, 0.25, 0.25}, fg = {0.73,0.73,0.73}},
		hovered  = {bg = { 0.19,0.6,0.73}, fg = {1,1,1}},
		active   = {bg = {1,0.6,  0}, fg = {1,1,1}}
	}
end

return board
