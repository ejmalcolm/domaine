local unitSpecs = {}

-- * All specials are called with the Unit calling them as the first arg

local function distanceBetweenRefs(ref1, ref2)
  -- * used to get the distance between two tileRefs
  local l1, t1 = ref1:sub(1,1), ref1:sub(2,2)
  local l2, t2 = ref2:sub(1,1), ref2:sub(2,2)
  -- ? are they in the same lane?
  if l1 ~= l2 then
    return false
  end
  local distance = math.abs(t1-t2)
  return distance
end

local function adjacentLanes(lane1, lane2)
  -- * note: lanes are not adjacent to themselves
  if lane1 == 'r' then
    if lane2 ~= 'y' then return false end
  elseif lane1 == 'g' then
    if lane2 ~= 'y' then return false end
  elseif lane1 == 'y' then
    -- only lane not adjacent to yellow is itself
    if lane2 == 'y' then return false end
  end
  return true
end

-- !

local function envoySpecial(caster)
  AskingForTile = true
  CreateAlert('Select a Tile to move to.', 5)
  WaitFor("tileSelected", function(newTileRef)
    -- * we nest on tile selection
    client:send("unitMove", {caster, caster.tile, newTileRef})
    -- use a secondary action
    client:send("useAction", {'secondary', caster, 'unitSpecial'})
  end, {'triggerArgs'})
end

unitSpecs["envoySpec"] = envoySpecial

-- !

local function sirenSpecial(caster)
  CreateAlert('Target an enemy unit in an adjacent Tile.', 3)
  WaitFor("targetEnemy", function(enemyUnit)
    -- first, we check if target is valid
    if distanceBetweenRefs(caster.tile, enemyUnit.tile) ~= 1 then
      CreateAlert('Invalid target; not adjacent tiles!', 3)
      return
    end
    -- if all's well, we move the target to the caster's tile
    client:send("unitMove", {enemyUnit, enemyUnit.tile, caster.tile})
    -- use a secondary action
    client:send("useAction", {'secondary', caster, 'unitSpecial'})
  end, {'triggerArgs'})
end

unitSpecs["sirenSpec"] = sirenSpecial

-- !

local function routerSpecial(caster)
  CreateAlert('Target a friendly Unit in the same Tile.', 3)
  WaitFor("targetAlly", function(allyUnit)
    -- check they're in the same tile
    if allyUnit.tile ~= caster.tile then
      CreateAlert('Invalid target', 3)
      return
    end
    -- then, select a different tile to move that unit to
    AskingForTile = true
    CreateAlert('Select a Tile to move to.', 5)
    WaitFor("tileSelected", function(newTileRef)
      -- move the ally unit
      client:send("unitMove", {allyUnit, allyUnit.tile, newTileRef})
    -- use a secondary action
    client:send("useAction", {'secondary', caster, 'unitSpecial'})
    end, {'triggerArgs'}) -- * end of tileSelected block
  end, {'triggerArgs'}) -- * end of targetAlly block
end

unitSpecs["routerSpec"] = routerSpecial

-- !

local function shifterSpec(caster)
  CreateAlert('Select a unit to swap with.', 3)
  WaitFor("targetUnit", function(targetUnit)
    -- move the caster to the target's tile
    client:send("unitMove", {caster, caster.tile, targetUnit.tile})
    -- move the target to the caster's tile
    client:send("unitMove", {targetUnit, targetUnit.tile, caster.tile})
    -- use a secondary action
    client:send("useAction", {'secondary', caster, 'unitSpecial'})
  end, {'triggerArgs'})
end

unitSpecs["shifterSpec"] = shifterSpec

-- !

local function chainSpec(caster)
  -- first, we get a target
  CreateAlert('Select a Unit to attach to.', 3)
  WaitFor("targetUnit", function(targetUnit)
    -- we verify the target is in the same tile
    if distanceBetweenRefs(caster.tile, targetUnit.tile) ~= 0 then
      CreateAlert('Invalid target.', 3)
      return false
    end
    -- TODO: we remove any other units that this chain is attached to
    -- we attach a tag to the target's specTable, "chain|AttachedTarget"
    local newTargetSpec = targetUnit.specTable
    newTargetSpec.tags["chain|AttachedTo"] = caster.uid
    client:send("modifyUnitTable", {targetUnit, 'specTable', newTargetSpec})
    -- use a secondary action
    client:send("useAction", {'secondary', caster, 'unitSpecial'})
    -- the rest is handled by the server handleEvent()
  end, {'triggerArgs'})
end

unitSpecs["chainSpec"] = chainSpec

-- ! STRIKERS

local function sniperSpec(caster)
  -- first, get a targetEnemy
  CreateAlert('Select an enemy to attack.', 5)
  WaitFor("targetEnemy", function(targetEnemy)
    -- check if they're a valid target
    local ref1, ref2 = caster.tile, targetEnemy.tile
    local l1, t1 = ref1:sub(1,1), ref1:sub(2,2)
    local l2, t2 = ref2:sub(1,1), ref2:sub(2,2)
    -- ? are they not in same tile
    if t1 ~= t2 then CreateAlert('Invalid target, not adjacent', 3) return false end
    -- ? are they in adjacent lanes
    if not adjacentLanes(l1, l2) then CreateAlert('Invalid target, not adjacent', 3) return false end
    -- if all is well, make an attack
    client:send("unitAttack", {caster, targetEnemy, doNotCheckRange=true})
    -- use a secondary action
    client:send("useAction", {'secondary', caster, 'unitSpecial'})
  end, {'triggerArgs'})
end

unitSpecs["sniperSpec"] = sniperSpec

-- !

local function hunterSpec(caster)
  -- first, we get an enemy
  CreateAlert('Select a Unit to Mark.', 3)
  WaitFor("targetEnemy", function(targetEnemy)
    -- we tag the target as "hunter|Marked"
    print(inspect(targetEnemy))
    local newTargetSpec = targetEnemy.specTable
    newTargetSpec.tags["hunter|MarkedBy"] = caster.uid
    client:send("modifyUnitTable", {targetEnemy, 'specTable', newTargetSpec})
    -- use a secondary action
    client:send("useAction", {'secondary', caster, 'unitSpecial'})
  end, {'triggerArgs'})

end

unitSpecs["hunterSpec"] = hunterSpec

-- !

local function nullitySpec(caster) end

unitSpecs["nullitySpec"] = nullitySpec

-- !

-- * knight, berserker are passives


return unitSpecs
