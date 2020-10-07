local function miserablePassive(caster, origin, data)
  -- replicates a special targeting the Miserable to every other unit in the same Tile
  local specRef, neededEvent, secondEvent = unpack(data)
  local spec = unitSpecs[specRef]
  -- first, we get all units in the Miserable's tile
  local tile = tileRefToTile(caster.tile)
  local content = tile.content
  -- we need this to be a hardcopy, because else, if the triggered function removes units from the tile
  -- we'll have a problem


  local storedSecondEvents = {}
  local function dummyFunc(iteration)
    local target = content[iteration]
    -- TODO: change this to check for the passive tag
    if target.name == "Miserable" then goto pass end

    spec(caster)
    -- at this point, the client is WaitingFor neededEvent -- a target
    -- we hijack that function
    -- then we clear the current waitingfor and create a new one
    -- the end result is that we create a sequence of WaitFors, miserableTrigger1, 2, 3, 4, etc.
    -- this stops any of them from "overwriting" each other

    do
      local hijackTable = WaitingFor[neededEvent]
      WaitingFor[neededEvent] = nil
      WaitingFor["miserableTrigger"..tostring(iteration)] = hijackTable
      TriggerEvent("miserableTrigger"..tostring(iteration), target)
      -- at this point, we're waiting for target.uid.."TargetSucceed"
      -- ? this does not go through unitTargetCheck. could cause weird interactions
      TriggerEvent(target.uid.."TargetSucceed", {})
      -- now, we're waiting for secondEvent if it exists
      if secondEvent ~= nil then
        hijackTable = WaitingFor[secondEvent]
        WaitingFor[secondEvent] = nil
        WaitingFor["miserableSecondTrigger"..tostring(iteration)] = hijackTable
        table.insert(storedSecondEvents, "miserableSecondTrigger"..tostring(iteration))
      end
    end
    
    ::pass::
    iteration = iteration + 1
    -- if we've looped through every unit, end
    if iteration > #(content) then return end
    -- else, we loop
    dummyFunc(iteration)
  end

  dummyFunc(1)

  -- we get here after we've looped through every unit
  -- at this point, we're waiting for caster.uid..TargetSucceed and any events in storedSecondEvents
  local hijackTable = WaitingFor[caster.uid.."TargetSucceed"]
  local hFunc, hArgs = unpack(hijackTable)
  WaitingFor[caster.uid.."TargetSucceed"] = nil

  -- * to future me: i'm sorry if you have to figure this out
  local function shell(...)
    -- this is what happens when MiserableTargetSucceed is called
    hFunc(...)
    if secondEvent ~= nil then
      local hijackTable = WaitingFor[secondEvent]
      local h2Func, h2Args = unpack(hijackTable)
      WaitingFor[secondEvent] = nil

      local function shell2(...)
        h2Func(...)
        for _, event in pairs(storedSecondEvents) do
          TriggerEvent(event, ...)
        end
      end
    WaitingFor[secondEvent] = {shell2, h2Args}

    -- if there are no secondEvents
    else end
  end

  WaitingFor[caster.uid.."TargetSucceed"] = {shell, hArgs}

end

unitSpecs["miserablePassive"] = miserablePassive


The Invoker






Each time the Invoker is targeted by a special, they gain a Color Charge depending on the lane the Special originated from.
