local board = {}

local suit = require("suit")

function board.setContent(tile, newContent)
	-- set a given tile's content to the given newContent
	tile.content = newContent
end

function board.load()
	board.lanes = {}
	-- the structures is board.lanes.LANENAME.[TILE#]
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

	-- image assets
	UpArrow = love.graphics.newImage('UpArrow.png')
	DownArrow = love.graphics.newImage('DownArrow.png')
	AttackIcon = love.graphics.newImage('AttackIcon.png')

end

function board.update(dt)
	-- for each line
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
					EnemySuit:Button(unit.name, {id = uid}, suit.layout:row(90,17))
					
				end
				-- if this unit is the active unit, activate the control panel and the info panel
				if unit == ActiveUnit then
					-- if the tile is in the red or yellow lanes (left or middle), make the cpanel and ipanel to the right
					if laneKey == 'r' or laneKey == 'y' then
						CPanelSuit.layout:reset(tile.rect[1]+110, tile.rect[2]+5)
						InfoPanelSuit.layout:reset(tile.rect[1]+140, tile.rect[2])
					elseif laneKey == 'g' then
						-- else, if it's in green, make the cpanel/ipanel to the left
						CPanelSuit.layout:reset(tile.rect[1]-30, tile.rect[2])
						InfoPanelSuit.layout:reset(tile.rect[1]-140, tile.rect[2])
					end
					CPanelSuit.layout:padding(2)
					-- * control panel creation
					-- move up/down arrows
					-- ! repeated code here, could possibly be optimized
					if tileKey ~= 1 then
						-- if not in the "upmost" tile, have a down arrow
						local moveUp = CPanelSuit:ImageButton(UpArrow, CPanelSuit.layout:row(20,20))
						if moveUp.hit then
							-- first, remove self from current tile
							local tileRef = laneKey..tileKey
							print(unit.name..' removed from: '..tileRef)
							client:send("removeUnitFromTile", {unit, tileRef})
							-- then, figure out what tile is above
							local newTileKey = tileKey-1
							local newTileRef = laneKey..newTileKey
							-- then, add to the new tile
							print(unit.name..' added to: '..newTileRef)
							client:send("addUnitToTile", {unit, newTileRef})
						end
					end
					if tileKey ~= 3 then
						-- if not in the "downmost" tile, have a down arrow
						local moveDown = CPanelSuit:ImageButton(DownArrow, CPanelSuit.layout:row(20,20))
						if moveDown.hit then
							-- first, remove self from current tile
							local tileRef = laneKey..tileKey
							print(unit.name..' removed from: '..tileRef)
							client:send("removeUnitFromTile", {unit, tileRef})
							-- then, figure out what tile is below
							local newTileKey = tileKey+1
							local newTileRef = laneKey..newTileKey
							-- then, add to the new tile
							print(unit.name..' added to: '..newTileRef)
							client:send("addUnitToTile", {unit, newTileRef})
						end
					end
					-- attack Button
					local attackButton = CPanelSuit:ImageButton(AttackIcon, CPanelSuit.layout:row(20,20))
					-- empty label for spacing
					local spacer = CPanelSuit:Label('', CPanelSuit.layout:row(3,3))
					-- use ability button
					local useAbilityButton = CPanelSuit:Button('A', CPanelSuit.layout:row(20,20))
					-- * infopanel creation
					-- name of selected unit
					InfoPanelSuit:Label(unit.name, InfoPanelSuit.layout:row(100,20))
					-- atk and hp
					local statString = string.format('%sATK | %sHP', unit.attack, unit.health)
					InfoPanelSuit:Label(statString, InfoPanelSuit.layout:row(100,20))
					-- description of special
					local shortSpecialDesc = 'Rand is immune to all other Specials.'
					InfoPanelSuit:Label(shortSpecialDesc, InfoPanelSuit.layout:row(100,20))
				end
			end
		end
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
	CPanelSuit:draw()
	-- draw the info panel
	love.graphics.setColor({186,186,186})
	InfoPanelSuit:draw()
end

return board
