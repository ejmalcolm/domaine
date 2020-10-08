local chooseAscendant = {}

function chooseAscendant.load()
  -- start "saving" pregame data
  PreMatchData = {}

  -- default ascendant
  AscendantIndex = 1

  AscendantSplashes = {}
  for _,v in pairs(ascendantList) do
    AscendantSplashes[v.name] = v.splash
  end

  AscendantSounds = {}
  local sacramentBGM = love.audio.newSource('sounds/cupidsRevenge.mp3', 'stream')
  sacramentBGM:setVolume(.1)
  AscendantSounds['The Sacrament'] = {bgm=sacramentBGM}

end

function chooseAscendant.update(dt)

  ChosenAscendant = ascendantList[AscendantIndex]

  -- ! SPLASH MANAGEMENT

  -- draw the splash image
  local selectedSplash = AscendantSplashes[ChosenAscendant.name]
  local splashX = selectedSplash:getDimensions()
  local startX = centerX-(Round(splashX/2))
  suit.layout:reset(startX, centerY-250)
  suit.ImageButton(selectedSplash, suit.layout:row(252,230))

  -- ! CHANGING AND SELECTING ASCENDANT
  suit.layout:reset(centerX-100,centerY)
  suit.layout:padding(5)
  -- previous Ascendant button
  local prevAscendant = suit.Button('<', suit.layout:col(20,20))
  if prevAscendant.hit then
    AscendantIndex = AscendantIndex-1
    if AscendantIndex == 0 then AscendantIndex=5 end
  end

  -- button to select an Ascendant
  local selectButton = suit.Button(ChosenAscendant.name, suit.layout:col(150,20))
  if selectButton.hit then
    PreMatchData['AscendantIndex'] = AscendantIndex
  end

  -- next Ascendant button
  local nextAscendant = suit.Button('>', suit.layout:col(20,20))
  if nextAscendant.hit then
    AscendantIndex = (AscendantIndex + 1)
    if AscendantIndex == (#ascendantList+1) then AscendantIndex = 1 end
  end

  -- -- ! DISPLAY ABILITIES

  suit.layout:reset(Round(x/7.5), centerY+30)
  suit.Label('MAJOR ABILITY', suit.layout:row(100,20))

  suit.layout:reset(Round(x/7.5)-100, centerY+50)
  suit.Label(ChosenAscendant.majorText, suit.layout:row(300, 20))

  suit.layout:reset(x-Round(x/3.75), centerY+30)
  suit.Label('MINOR ABILITY', suit.layout:row(100, 20))

  suit.layout:reset(x-Round(x/3.75)-100, centerY+50)
  suit.Label(ChosenAscendant.minorText, suit.layout:row(300, 20))

  suit.layout:reset(Round(x/7.5)-5, centerY+160)
  suit.Label('VICTORY', suit.layout:row(100, 20))

  suit.layout:reset(Round(x/7.5)-100, centerY+180)
  suit.Label(ChosenAscendant.victoryText, suit.layout:row(300, 20))

  suit.layout:reset(x-Round(x/3.75), centerY+160)
  suit.Label('INCARNATE', suit.layout:row(100, 20))

  suit.layout:reset(x-Round(x/3.75)-100, centerY+180)
  suit.Label(ChosenAscendant.incarnateText, suit.layout:row(300, 20))

  -- ! go to buildarmy

  suit.layout:reset(centerX-75,y-40)
  suit.layout:padding(5)
  if PreMatchData['AscendantIndex'] then
    if suit.Button('Finalize Selection', suit.layout:row(150,20)).hit then
      changeScreen(buildArmy)
    end
  end

end

function chooseAscendant.draw()
  suit.draw()
end

return chooseAscendant
