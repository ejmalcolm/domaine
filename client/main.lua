-- * screens
menu = require("menu")
board = require("board")
buildArmy = require("buildArmy")
unitPlacement = require("unitPlacement")
connectScreen = require("ConnectScreen")
chooseAscendant = require("chooseAscendant")
victoryScreen = require("victoryScreen")
defeatScreen = require("defeatScreen")
WaitingScreen = require("WaitingScreen")
BrowseLobbies = require("BrowseLobbies")

-- * references
unitList = require("references/unitList")
unitSpecs = require("references/unitSpecs")
ascendantList = require("references/ascendantList")

-- * modules
suit = require("modules/suit")
inspect = require("modules/inspect")
bitser = require("modules/bitser")
sock = require("modules/sock")

-- * helpful variables and global functions
local currentScreen

-- TODO: optimization-- only call love.getDimensions() once in main.lua love.update, else we're being expensive for no reason

function Round(n)
  return math.floor(n+.5)
end

-- * sleeps for t seconds
function Sleep(t)
  local sec = tonumber(os.clock() + t);
  while (os.clock() < sec) do end
end

-- * temporary solution to adjust coordinates from the default res to different reses
-- * does not fix for phones! need a diff solution
function AdjustCenter(coord, XorY)
  local x,y = love.graphics.getDimensions()
  local Centers = {centerX=Round(x/2),centerY=Round(y/2)}
  local center = Centers['center'..XorY]
  local defaultCenter
  if XorY=="X" then defaultCenter=375 else defaultCenter=250 end
  local distanceFromCenter = defaultCenter-coord
  return center-distanceFromCenter
end

function CreateAlert(alertText, duration)
  -- * creates an alert and plays the alert sound
  -- add the Alert to the list of active alerts
  ActiveAlerts[alertText] = duration
  love.audio.play(AudioSources["alertSound"])
end

function UpdateAlerts(dt)
  local x,y = love.graphics.getDimensions()
  local center = Round(x/2)
  for alertText, timeRemaining in pairs(ActiveAlerts) do
    ActiveAlerts[alertText] = timeRemaining-dt
    if ActiveAlerts[alertText] > 0 then
      local alert = AlertSuit:Button(alertText, center-150, 10, 300, 20)
      if alert.hit then
        ActiveAlerts[alertText] = nil
      end
    else
      -- if duration is 0, delete the button
      ActiveAlerts[alertText] = nil
    end
  end
end

function CreatePopup(title, choicesTable, duration, event)
  -- * creates a popup menu, that triggers the given Event when an option is clicked
  PopupMenus[title] = {duration, choicesTable, event}
end

function UpdatePopups(dt)
  -- * updates a popup menu over the center of the screen with a bunch of options
  for title, data in pairs(PopupMenus) do
    -- decrement duration
    PopupMenus[title][1] = PopupMenus[title][1] - dt
    -- if duration is above zero, create the popup
    if PopupMenus[title][1] > 0 then
      ActivePopup = true
      -- draw the title
      PopupSuit.layout:reset(centerX-100, centerY-100)
      PopupSuit:Label(title, PopupSuit.layout:col(200,20))
      -- take in account the border
      PopupSuit.layout:reset(centerX-150, centerY-59)
      PopupSuit.layout:padding(1)
      -- cancel button in the top right
      PopupSuit.layout:reset(centerX+177, centerY-98)
      local cancelButton = PopupSuit:Button('X', PopupSuit.layout:row(20,20))
      if cancelButton.hit then PopupMenus[title][1] = 0 end
      -- option buttons
      for k,v in pairs(PopupMenus[title][2]) do
        if k % 3 == 1 then
          PopupSuit.layout:reset(centerX-150, (centerY-59)+(40*(k/3)) )
        end
        local choiceButton = PopupSuit:Button(v, PopupSuit.layout:col(100,40))
        -- when clicked, trigger the given event and then end
        if choiceButton.hit then
          TriggerEvent(PopupMenus[title][3], v)
          -- delete the menu by setting duration to 0
          PopupMenus[title][1] = 0
        end
      end
    else
      -- if duration is zero or below, delete the popup
      ActivePopup = false
      PopupMenus[title] = nil
      -- alert player
      CreateAlert('Menu dismissed.', 5)
    end
  end
end

function CreatePopupDisplay(title, subtitles, text)
  -- * creates a info menu, with headings {subtitles}, each with text underneath them in the {text}
  -- the first "1" is the starting index, aka which subtitle/text pair to start at
  -- the final true value is just used to control whether the display is active or not
  PopupDisplays = {}
  PopupDisplays[title] = {1, subtitles, text, true}
end

function UpdatePopupDisplays(dt)
  -- * updates a popup menu over the center of the screen with a bunch of options
  for title, data in pairs(PopupDisplays) do

    -- draw the title
    PopupDisplaySuit.layout:reset(centerX-100, centerY-100)
    PopupDisplaySuit:Label(title, PopupDisplaySuit.layout:col(200,20))
    -- take in account the border
    PopupDisplaySuit.layout:reset(centerX-150, centerY-59)
    PopupDisplaySuit.layout:padding(1)


    -- ! cancel button in the top right

    PopupDisplaySuit.layout:reset(centerX+179, centerY-95)
    local cancelButton = PopupDisplaySuit:Button('X', PopupDisplaySuit.layout:row(20,20))

    if cancelButton.hit then
      PopupDisplays[title] = nil
      return
    end

    -- ! display information
    local activeIndex = data[1]
    local subtitlesTable = data[2]
    local textTable = data[3]
    local subtitle = subtitlesTable[activeIndex]
    local text = textTable[activeIndex]
    -- first, the title and the "change selection" buttons
    PopupDisplaySuit.layout:reset(centerX-65, centerY-60)
    local backButton = PopupDisplaySuit:Button('<', PopupDisplaySuit.layout:col(20,20))
    PopupDisplaySuit:Label(subtitle, PopupDisplaySuit.layout:col(90, 20))
    local nextButton = PopupDisplaySuit:Button('>', PopupDisplaySuit.layout:col(20,20))
    if backButton.hit then data[1] = math.max((data[1]-1),1) end
    if nextButton.hit then data[1] = math.min(data[1]+1, #subtitlesTable) end
    -- then, the info
    PopupDisplaySuit.layout:reset(centerX-200, centerY-75)
    PopupDisplaySuit:Label(text, PopupDisplaySuit.layout:row(400, 170))
  end
end

function CreateSliderPopup(title)
  SliderPopupStorage = {value = 5, min=5, max=50, step=1}
  SliderPopups[title] = {true}
end

function UpdateSliderPopups(dt)
  -- * updates a popup menu over the center of the screen with a bunch of options
  for title, active in pairs(SliderPopups) do
    if active then
      ActiveSliderPopup = true
      -- draw the title
      SliderPopupSuit.layout:reset(centerX-100, centerY-100)
      SliderPopupSuit:Label(title, SliderPopupSuit.layout:col(200,20))
      -- take in account the border
      SliderPopupSuit.layout:reset(centerX-150, centerY-59)
      SliderPopupSuit.layout:padding(1)
      -- ! cancel button in the top right
      SliderPopupSuit.layout:reset(centerX+179, centerY-95)
      local cancelButton = SliderPopupSuit:Button('X', SliderPopupSuit.layout:row(20,20))
      if cancelButton.hit then SliderPopups[title] = false return end
      -- ! display the Slider
      SliderPopupSuit.layout:reset(centerX-100, centerY-40)
      SliderPopupSuit:Slider(SliderPopupStorage, SliderPopupSuit.layout:row(200,20))
      -- ! above the slider, display the current value
      local roundedValue = Round(SliderPopupStorage.value)
      SliderPopupSuit:Label('Current Value: '..roundedValue, SliderPopupSuit.layout:up())
      -- ! below the slider, button to submit the current value
      SliderPopupSuit.layout:reset(centerX-25, centerY-15)
      local submitButton = SliderPopupSuit:Button('Submit', SliderPopupSuit.layout:row(50,20))
      if submitButton.hit then
        TriggerEvent("sliderInput", roundedValue)
        SliderPopups[title] = false
        return
      end
    else
      ActiveSliderPopup = false
      PopupMenus[title] = nil
    end
end
end

function WaitFor(event, func, args)
  -- this is essentially a client-side queueing function
  -- takes an event, a certain string e.g. "targetEnemy", and a function object
  -- fills the WaitingFor table with that info
  -- it can later be used by TriggerEvent()
  WaitingFor[event] = {func, args}
end

function TriggerEvent(event, triggerArgs)
  -- takes an event, a certain string e.g. "targetEnemy" --
  -- takes a table triggerArgs, which, if requested in the initial WaitFor, is passed into args
  -- triggerArgs is passed into the function as a table if in the "main" arg string
  -- else, if its part of a subtable, its unpacked and passed into it
  if WaitingFor[event] then
    -- trigger only if the event is being Awaited
    -- call the function
    local func = WaitingFor[event][1]
    local args = WaitingFor[event][2] or {}
    -- loop through args and sub-tables in args
    -- replace any "triggerArgs" string with the triggerArgs table
    for k, v in pairs(args) do
      if v == 'triggerArgs' then
        args[k] = triggerArgs
      end
      -- loop through any sub-tables that exist
      if type(v) == 'table' then
        for k2, v2 in pairs(v) do
          if v2 == 'triggerArgs' then
            -- clear the triggerArgs string and reset the table
            args[k][k2] = nil
            -- this resets the indices of the table
            -- which stops the "empty" spot where the 'triggerArgs' was
            -- from messing things up
            -- * basically, what happens here is:
            -- * {1, 'triggerArgs', 3} goes to {1, nil, 3}
            -- * then, if we insert any new arguments, that nil stays there
            -- * this gets rid of the nil
            local newArgs = {}
            for _,p in pairs(args[k]) do table.insert(newArgs, p) end
            args[k] = newArgs
            -- if its a subtable, then we unpack it and add it to overtable
            -- * unless its the lone argument, and that argument is a table
            -- * for example: if only a unit is sent
            -- * a unit is a table, but we dont want to cycle through it
            -- we filter those cases out by making sure the keys are ints
            -- ? this might be a bad way of doing it, but eh
            if triggerArgs[1] then
              for k3, triggerArg in pairs(triggerArgs) do
                -- the (k3-1) ensures that arguments are added in their proper order
                table.insert(args[k], k2+(k3-1), triggerArg)
              end
            else
              -- sole argument that happens to be a table
              table.insert(args[k], triggerArgs)
            end
          end
        end
      end
    end
    -- clear the WaitingFor event
    WaitingFor[event] = nil
    func(unpack(args))
  end
end

function changeScreen(screen)
  if currentScreen then LastScreen = currentScreen print(LastScreen) end
  if screen.load then screen.load() end
  currentScreen = screen
end

function connectToHost(ip)
  -- create the client
  tickRate = 1/60
  tick = 0
  client = sock.newClient(ip, 22122)

  -- ! SETUP CLIENT

  -- on connection
  client:on("connect", function(data)
    print('Successfully connected!')
  end)

  -- for getting the player index (p1 or p2)
  client:on("setUpGame", function(num)
    playerNumber = num
    print('Client player number: '..playerNumber)
    -- send over the pregame data
    PreMatchData['HasMajorPower'] = true
    PreMatchData['HasMinorPower'] = true
    PreMatchData['HasIncarnatePower'] = true
    PreMatchData['ActionTable'] = {1, 1, 1}
    client:send("transferPreMatchData", PreMatchData)
    -- send to waiting screen
    changeScreen(WaitingScreen)
  end)

  -- * launches the actual match, switches to board
  client:on("startMatch", function(data)
    -- one at a time, add each unit from unitPlacement into the matching starting Tile
    for _, tile in pairs({'r', 'y', 'b'}) do
      for _, unit in pairs(unitPlacement.pRects[tile].content) do
          client:send("createUnitOnTile", {unit, tile..'A'})
      end
    end

    -- initialize the MatchState
    MatchState = data

    -- set screen to board once everything's ready
    changeScreen(board)

    -- call any onMatchStart functions
    local ascIndex = GetPlayerVar('AscendantIndex')
    local asc = ascendantList[ascIndex]
    if asc.onMatchStartFunc then asc.onMatchStartFunc() end
  end)

  -- ! SERVER-TO-CLIENT COMMUNICATION

  -- * allows the server to create client-side alerts
  client:on("createAlert", function(data)
    local alertText, duration = data[1], data[2]
    CreateAlert(alertText, duration)
  end)

  -- * allows the server to trigger events
  client:on("triggerEvent", function(data)
    local event, triggerArgs = unpack(data)
    print('Event triggered by server:', event)
    TriggerEvent(event, triggerArgs)
  end)

  -- * used to update the MatchState table
  client:on("updateVar", function(data)
    local scope, field, value = unpack(data)
    print('Updated MatchState:', scope, field, value)
    if scope == 'global' then
      MatchState[field] = value
    elseif scope == 'player' then
      MatchState['Player'..playerNumber] = value
    end
  end)

  client:on("youWin", function(data)
    CreateAlert('You win!!!!', 3)
    CreateAlert('Unfortunately, you have to close the game now!', 7)
    CreateAlert('WORKING ON IT I PROMISE', 20)
    changeScreen(victoryScreen)
  end)

  client:on("youLose", function(data)
    CreateAlert('You lose :( :( :(', 3)
    CreateAlert('Unfortunately, you have to close the game now!', 7)
    CreateAlert('WORKING ON IT I PROMISE', 20)
    changeScreen(defeatScreen)
  end)

  client:on("callSpecFunc", function(data)
    local specRef, args = unpack(data)
    args = args or {}
    print('Special called by server:', specRef)
    unitSpecs[specRef](unpack(args))
  end)

  -- ! BOARD FUNCTIONS

  -- * when called, the client updates its copy of the Lanes to match the server's
  client:on("updateLanes", function(UpdatedLanes)
    board.lanes = UpdatedLanes
  end)

  -- ! TURN SYSTEM

  -- * used to manage turn timer and amount of actions
  client:on("actionUsed", function(actionType)
    print(actionType.. ' action used.')
    ActionsRemaining[actionType] = ActionsRemaining[actionType] - 1
  end)

  -- * used to set who's turn it is
  client:on("setPlayerTurn", function(playerN)
    print('Player '..CurrentTurnTaker..'\'s turn ended.')
    print('It is now Player'..playerN..'\'s turn')
    -- reset available actions for both players
    ActionsRemaining.primary, ActionsRemaining.secondary = 1,2
    CurrentTurnTaker = playerN
  end)

  -- ! CONNECTION TO SERVER
  local function dummyConnect()
    client:connect()
  end

  -- if connection works (pcall stops any errors from crashing)
  if pcall(dummyConnect) then
    Connected = true
  else
    print('Connection failed')
  end
end

function ChangePlayerVar(field, value)
  (MatchState['Player'..playerNumber])[field] = value
  client:send("updatePlayerVar", {field, value})
end


-- ! LOVE loops and game events

function love.load()
  -- used as a queueing system for WaitFor() events
  WaitingFor = {}
  -- used to draw temporary alerts
  AlertSuit = suit.new()
  ActiveAlerts = {}
  -- used for popup menus
  PopUpBG = love.graphics.newImage('images/PopUpBG.png')
  PopupSuit = suit.new()
  PopupMenus = {}
  -- used for infopanels
  PopupDisplaySuit = suit.new()
  PopupDisplays = {}
  -- used for Slider popups
  SliderPopupSuit = suit.new()
  SliderPopups = {}
  -- basic settings
  love.keyboard.setKeyRepeat(true)
  love.window.setTitle('Domaine')
  love.window.setMode(1280, 720, {resizable=false})
  -- audio assets (expensive to create many times)
  AudioSources = {}
  AudioSources["alertSound"] = love.audio.newSource('sounds/alertSoundDown.wav', 'static')
  AudioSources["alertSound"]:setVolume(.25)
  AudioSources["walkingAlong"] = love.audio.newSource('sounds/walkingAlong.mp3', 'stream')
  AudioSources["walkingAlong"]:setVolume(.25)
  love.audio.play(AudioSources["walkingAlong"])
  -- used for the turn system
  CurrentTurnTaker = 1
  -- set up the color theme
  AscendantTheme = {
    normal   = {bg = { 0.25, 0.25, 0.25}, fg = {0.73,0.73,0.73}},
    hovered  = {bg = { 0.19,0.6,0.73}, fg = {1,1,1}},
    active   = {bg = {1,0.6,  0}, fg = {1,1,1}}
  }
  -- initialize by setting the currentScreen to the menu
  menu.load()
  currentScreen = menu
end


function love.update(dt)
  -- * quit the game with escape!
  if love.keyboard.isDown('escape') then love.event.quit() end

  -- control the multiplayer stuff
  if Connected then
    client:update()
  end

  -- create and increment duration of Popup menus
  UpdatePopups(dt)

  -- create and increment duration of Alert buttons
  UpdateAlerts(dt)

  -- create and increment duration of Info panels
  UpdatePopupDisplays(dt)

  -- create SliderPopups
  UpdateSliderPopups()

  -- if we're not on the board, draw a back button in the top left
  if LastScreen then
    local backButton = suit.Button('<-', 0,0,20,20)
    if backButton.hit then changeScreen(LastScreen) end
  end

  -- get coordinates
  x, y = love.graphics.getDimensions()
  centerX = Round(x/2)
  centerY = Round(y/2)

  -- update the current screen
  currentScreen.update(dt)
end


function love.draw()

  -- reset default theme
  suit.theme.color = {
    normal   = {bg = { 0.25, 0.25, 0.25}, fg = {0.73,0.73,0.73}},
    hovered  = {bg = { 0.19,0.6,0.73}, fg = {1,1,1}},
    active   = {bg = {1,0.6,  0}, fg = {1,1,1}}
  }

  -- draw the current screen
  suit.theme.color = AscendantTheme
  currentScreen.draw()

  -- draw alerts
  suit.theme.color = {
    normal   = {bg = { 1, 1, 1}, fg = {0,0,0}},
    hovered  = {bg = { 0.19,0.6,0.73}, fg = {1,1,1}},
    active   = {bg = {1,0.6,  0}, fg = {1,1,1}}
  }
  AlertSuit:draw()

  -- draw popup menus
  if ActivePopup then
    -- background of popup
    love.graphics.rectangle('fill', centerX-200, centerY-100, 400, 200)
    love.graphics.draw(PopUpBG, centerX-200, centerY-100)
    -- suit theme
    suit.theme.color = {
      normal   = {bg = { 1, 1, 1}, fg = {0,0,0}},
      hovered  = {bg = { 0.19,0.6,0.73}, fg = {1,1,1}},
      active   = {bg = {1,0.6,  0}, fg = {1,1,1}}
    }
    PopupSuit:draw()
    -- reset color
    love.graphics.setColor(255,255,255)
  end

  local popupDisplayLen = 0
  for _, _ in pairs(PopupDisplays) do
    popupDisplayLen = popupDisplayLen + 1
  end
  if popupDisplayLen > 0 then
    -- border and bg of popup
    love.graphics.rectangle('fill', centerX-200, centerY-100, 400, 200)
    love.graphics.draw(PopUpBG, centerX-200, centerY-100)
    -- suit theme
    suit.theme.color = {
      normal   = {bg = {.9,.9,.9}, fg = {0,0,0}},
      hovered  = {bg = { 0.19,0.6,0.73}, fg = {1,1,1}},
      active   = {bg = {1,0.6,0}, fg = {1,1,1}}
    }
    PopupDisplaySuit:draw()
    -- reset color
    love.graphics.setColor(255,255,255)
  end

  if ActiveSliderPopup then
    -- background of popup
    love.graphics.rectangle('fill', centerX-200, centerY-100, 400, 200)
    love.graphics.draw(PopUpBG, centerX-200, centerY-100)
    -- suit theme
    suit.theme.color = {
      normal   = {bg = {.9,.9,.9}, fg = {0,0,0}},
      hovered  = {bg = { 0.19,0.6,0.73}, fg = {1,1,1}},
      active   = {bg = {1,0.6,0}, fg = {1,1,1}}
    }
    SliderPopupSuit:draw()
    -- reset color
    love.graphics.setColor(255,255,255)
  end

end
