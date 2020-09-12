local chooseAscendant = {}

function chooseAscendant.load()
  -- Ascendant names
  AscendantNames = {{name='The Sacrament',
                     major='Resurrect any Unit that has died this game and place them on a chosen Tile.',
                     minor='Select a unit to designate as your Chosen. When the Chosen kills an enemy unit, they gain +1ATK/+1HP. There can only be one Chosen at a time.',
                     victory='If the Chosen has killed three units.',
                     incarnate='The Sacrament \n 3ATK||3HP'},
                    {name='The Imperator',
                     major='Select two Tiles in different Lanes; for example, the top Tile of the Red and Yellow Lanes. Units can now move between these two tiles as a Secondary Action.',
                     minor='Select a Tile with only friendly units and no Imperial Outposts. Place an Imperial Outpost there. Imperial Outposts are Units that cannot move, with 1 ATK and 5 HP.',
                     victory='If at least four tiles have Imperial Outposts.',
                     incarnate='coming soon'},
                    {name='The Parallel',
                     major='Pick three pairs of tiles. Swap their contents.',
                     minor='Swap the ATK and HP of a chosen unit.',
                     victory='If every surviving unit has the same Attack OR the same Health.',
                     incarnate='coming soon'},
                    {name='The Sleeper',
                     major='coming soon',
                     minor='coming soon',
                     victory='coming soon',
                     incarnate='coming soon'},
                    {name='The Savant',
                     major='Select three Tiles in order. Next turn, move all units in the first to another Tile. Two turns from now, remove the abilities of all units in the second. Three turns from now, destroy all units in the third.',
                     minor='Remove a chosen Unit from the game. In two turns, that Unit returns to the game exactly as it left.',
                     victory='At the start of the game, pick a turn number greater than 5. On that turn, if you have more Units than your opponent, you win. Otherwise, you lose.',
                     incarnate='coming soon'}
                   }
  -- default
  SelectedIndex = 1

  -- load in the splash of each ascendant
  -- TODO: these are placeholders!!! i dont own them!! :()
  AscendantSplashes = {}
  -- 252x230
  AscendantSplashes['The Sacrament'] = love.graphics.newImage('images/ascendantSacrament.png')
  AscendantSplashes['The Imperator'] = love.graphics.newImage('images/ascendantImperator.png')
  AscendantSplashes['The Parallel'] = love.graphics.newImage('images/ascendantParallel.png')
  AscendantSplashes['The Sleeper'] = love.graphics.newImage('images/ascendantSleeper.png')
  AscendantSplashes['The Savant'] = love.graphics.newImage('images/ascendantSavant.png')

  -- Ascendant color themes
  AscendantTheme = {
    normal   = {bg = { 0.25, 0.25, 0.25}, fg = {0.73,0.73,0.73}},
    hovered  = {bg = { 0.19,0.6,0.73}, fg = {1,1,1}},
    active   = {bg = {1,0.6,  0}, fg = {1,1,1}}
  }
  AscendantColors = {} -- {0/255,165/255,229/255}
  AscendantColors['The Sacrament'] = {
                                      {normal  = {bg = {249/255,178/255,90/255}, fg = {0/255,104/255,167/255}},
                                      hovered = {bg = {50,153,187}, fg = {255,255,255}},
                                      active  = {bg = {255,153,0}, fg = {225,225,225}}},
                                      {141/255,182/255,199/255}
                                     }

  AscendantSounds = {}
  local sacramentBGM = love.audio.newSource('sounds/cupidsRevenge.mp3', 'stream')
  sacramentBGM:setVolume(.1)
  AscendantSounds['The Sacrament'] = {bgm=sacramentBGM}

end

function chooseAscendant.update(dt)

  local selectAscendant = AscendantNames[SelectedIndex]

  -- ! SPLASH MANAGEMENT

  -- draw the splash image
  local selectedSplash = AscendantSplashes[selectAscendant.name]
  local splashX = selectedSplash:getDimensions()
  local startX = centerX-(Round(splashX/2))
  suit.layout:reset(startX, centerY-250)
  suit.ImageButton(selectedSplash, suit.layout:row(252,230))

  -- * managing ascendant buttons
  suit.layout:reset(centerX-100,centerY)
  suit.layout:padding(5)
  -- previous Ascendant button
  local prevAscendant = suit.Button('<', suit.layout:col(20,20))
  if prevAscendant.hit then
    SelectedIndex = ((SelectedIndex-1) % #AscendantNames)
    if SelectedIndex == 0 then SelectedIndex=5 end
  end
  -- button to select an Ascendant
  local selectButton = suit.Button(selectAscendant.name, suit.layout:col(150,20))
  if selectButton.hit then
    AscendantTheme = AscendantColors[selectAscendant.name][1]
    love.graphics.setBackgroundColor(AscendantColors[selectAscendant.name][2])
    love.audio.stop()
    love.audio.play(AscendantSounds[selectAscendant.name]['bgm'])
  end
  -- next Ascendant button
  local nextAscendant = suit.Button('>', suit.layout:col(20,20))
  if nextAscendant.hit then
    SelectedIndex = (SelectedIndex + 1) % #AscendantNames+1
  end

  -- ! DISPLAY ABILITIES

  suit.layout:reset(Round(x/7.5), centerY+30)
  suit.Label('MAJOR ABILITY', suit.layout:row(100,20))

  suit.layout:reset(Round(x/7.5)-100, centerY+50)
  suit.Label(selectAscendant.major, suit.layout:row(300, 20))

  suit.layout:reset(x-Round(x/3.75), centerY+30)
  suit.Label('MINOR ABILITY', suit.layout:row(100, 20))

  suit.layout:reset(x-Round(x/3.75)-100, centerY+50)
  suit.Label(selectAscendant.minor, suit.layout:row(300, 20))

  suit.layout:reset(Round(x/7.5)-5, centerY+160)
  suit.Label('VICTORY', suit.layout:row(100, 20))

  suit.layout:reset(Round(x/7.5)-100, centerY+180)
  suit.Label(selectAscendant.victory, suit.layout:row(300, 20))

  suit.layout:reset(x-Round(x/3.75), centerY+160)
  suit.Label('INCARNATE', suit.layout:row(100, 20))

  suit.layout:reset(x-Round(x/3.75)-100, centerY+180)
  suit.Label(selectAscendant.incarnate, suit.layout:row(300, 20))

  -- ! go to buildarmy

  suit.layout:reset(centerX-75,y-40)
  suit.layout:padding(5)
  if suit.Button('Finalize Selection', suit.layout:row(150,20)).hit then
    changeScreen(buildArmy)
  end

end

function chooseAscendant.draw()
  suit.draw()
end

return chooseAscendant
