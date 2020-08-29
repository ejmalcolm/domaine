local buildArmy = {}

local suit = require("suit")

local armyList = {}
local unitList = require('unitList')
--init currentArmyCost so it can be used in the armyList
local currentArmyCost = 0

function buildArmy.update(dt)
    --make all the unitselect buttons
    local iteration = 0
    for k,v in pairs(unitList) do
        --complicated math to get the coords for each button
        --x coord is just mod 5 so that it repeats every 5th time
        --y coord is rounded to the nearest int
        suit.Button(k, (iteration % 5)*163, math.floor(iteration*2 / 10)*25, 100, 20)
        iteration = iteration + 1
    end

    --add units to armyList when their button is hit
    for k,v in pairs(unitList) do
        if suit.isHit(k) then
            -- make sure there's room in the budgest
            if currentArmyCost + v[1] <= 7 then
                table.insert(armyList, k)
            end
        end
    end

    --create the armyList buttons
    -- x, y = love.graphics.getDimensions()
    suit.layout:reset(324, 300)
    for k, v in pairs(armyList) do
        suit.Button(v, {id = v..tostring(k)}, suit.layout:row(100, 20))
    end

    --remove the unit from the armyList when clicked
    for k, v in pairs(armyList) do
        if suit.isHit(v..tostring(k)) then
            table.remove(armyList, k)
        end
    end

    --calculate currentArmyCost from armyList
    currentArmyCost = 0
    for k,v in pairs(armyList) do
        currentArmyCost = currentArmyCost + unitList[v][1]
    end

    --make a button to launch into the matchmaking screen
    suit.Button('Army Complete', 326, 450, 100, 20)
    if suit.isHit('Army Complete') then
        changeScreen(unitPlacement)
        unitPlacement.setArmy(armyList)
    end

end

function buildArmy.draw()

    --make the top label
    love.graphics.print({{255, 0, 0}, 'Your Army'}, 345, 280)

    --print the current current cost
    love.graphics.print({{255, 0, 0}, string.format('Budget: %d/7', currentArmyCost)}, 450, 280)

    suit.draw()

end

return buildArmy
