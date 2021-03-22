local LobbyWait = {}
-- the lobby that we are in is stored in the var InsideLobby
-- {hostAvatarStr='TestAvatar', hostCID=client.connectId,
-- privacy='Open', gameType='Standard',
-- ID=nil}



function LobbyWait.load()
  LobbyWaitSuit = suit.new()
  LobbyWait.AmHost = (InsideLobby.hostCID == client.connectId)
  client:send("updateMyPreMatch", {InsideLobby, PreMatchData})
end

function LobbyWait.update(dt)

  LobbyWaitSuit.layout:reset(centerX-75, 50)
  LobbyWaitSuit:Label("Lobby ID "..InsideLobby.ID, LobbyWaitSuit.layout:row(150,20))

  -- if you're the host, then we reset to the left, else, we reset to the right
  if LobbyWait.AmHost then
    LobbyWaitSuit.layout:reset(centerX-400, 250)
  else
    LobbyWaitSuit.layout:reset(centerX+250, 250)
  end

  do -- this block is all of YOUR information
    LobbyWaitSuit.layout:padding(10)
    LobbyWaitSuit:Label("Player ID: "..InsideLobby.hostCID, LobbyWaitSuit.layout:row(150,20))
    LobbyWaitSuit:Label("Rating: N/A", LobbyWaitSuit.layout:row(150,20))


    -- if we haven't yet selected an ascendant, display "Choose Ascendant"
    local CAlabel = "Choose Ascendant"
    -- else, display the name of the ascendant we picked
    if PreMatchData["AscendantIndex"] then
      CAlabel = ascendantList[PreMatchData["AscendantIndex"]].name
    end
    local CAbutton = LobbyWaitSuit:Button(CAlabel, LobbyWaitSuit.layout:row(150,20))
    if CAbutton.hit then
      changeScreen(LMPChooseAscendant)
    end

    -- if we haven't picked an army, display "Build Army"
    local BAlabel = PreMatchData['CurrentArmyCost'] or "Build Army"
    -- if we have, display the current army cost used
    if PreMatchData['CurrentArmyCost'] then
      BAlabel = PreMatchData['CurrentArmyCost']..'/5 Points Used'
    end
    local BAbutton = LobbyWaitSuit:Button(BAlabel, LobbyWaitSuit.layout:row(150,20))
    if BAbutton.hit then
      changeScreen(LMPBuildArmy)
    end

    LobbyWaitSuit:Button("Ready Up", LobbyWaitSuit.layout:row(150,20))
  end

  -- for the "guest" display, we reset to the opposite of where the host is
  if LobbyWait.AmHost then
    LobbyWaitSuit.layout:reset(centerX+250, 250)
  else
    LobbyWaitSuit.layout:reset(centerX-400, 250)
  end

  do -- this block is all of THEIR information
    LobbyWaitSuit.layout:padding(10)
    -- if you're the only member, just display "Waiting..."
    if #InsideLobby.members == 1 then
      LobbyWaitSuit:Label("Waiting for player...", LobbyWaitSuit.layout:row(150,20))
    else
      -- if there's another player, get their PreMatchData
      local otherPreMatchData, otherCID
      if LobbyWait.AmHost then
        otherPreMatchData = InsideLobby.guestPreMatch
        otherCID = InsideLobby.members[2]
      else
        otherPreMatchData = InsideLobby.hostPreMatch
        otherCID = InsideLobby.members[1]
      end
      -- then, display their info
      LobbyWaitSuit:Label("Player ID: "..otherCID, LobbyWaitSuit.layout:row(150,20))
      LobbyWaitSuit:Label("Rating: N/A", LobbyWaitSuit.layout:row(150,20))
      if otherPreMatchData.AscendantIndex then
        LobbyWaitSuit:Label('Ascendant Selected', LobbyWaitSuit.layout:row(150, 20))
      else
        LobbyWaitSuit:Label('Waiting for Ascendant...', LobbyWaitSuit.layout:row(150, 20))
      end
      if otherPreMatchData.ArmyList then
        LobbyWaitSuit:Label('Army Selected', LobbyWaitSuit.layout:row(150, 20))
      else
        LobbyWaitSuit:Label('Waiting for Army...', LobbyWaitSuit.layout:row(150, 20))
      end
      if otherPreMatchData.Ready then
        LobbyWaitSuit:Label('Ready', LobbyWaitSuit.layout:row(150, 20))
      else
        LobbyWaitSuit:Label('Not Ready', LobbyWaitSuit.layout:row(150, 20))
      end


    end
  end

  -- start game button
  LobbyWaitSuit.layout:reset(centerX-75, 600)
  LobbyWaitSuit:Button("Go to Unit Placement", LobbyWaitSuit.layout:row(150,20))


end

function LobbyWait.draw()
  -- p1 background
  love.graphics.setColor(1/10,1/10,1/10)
  love.graphics.rectangle('fill', centerX-400, 250, 150, 150, 5, 5)
  -- p2 background
  love.graphics.rectangle('fill', centerX+250, 250, 150, 150, 5, 5)

  love.graphics.setColor(1,1,1)
  LobbyWaitSuit:draw()
end

return LobbyWait