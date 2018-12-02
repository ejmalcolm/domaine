buildArmy = {}

local suit = require("suit")

local armyList = {}
local unitList = require('unitList')

function buildArmy.update(dt)
    --make all the buttons
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
            table.insert(armyList, k)
        end
    end

end

function buildArmy.draw()

    --make the top label
    love.graphics.print({{255, 0, 0}, 'Your Army'}, 345, 280)

    --create the armyList buttons
    --they're buttons because they need to be able to be removed
    suit.layout:reset(326, 300)
    local armyID = 1
    for k, v in pairs(armyList) do
        suit.Button(v, {id = armyID}, suit.layout:row(100, 20))
        armyID = armyID + 1
    end
    suit.draw()
end

return buildArmy
