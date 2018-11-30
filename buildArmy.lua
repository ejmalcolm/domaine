buildArmy = {}

local suit = require("suit")

local armyList = {}
local nameTable = {'Blood Mage', 'Zangief', 'Rand', 'Lancer', 'Knight',
                    'Reaper', 'Brawler', 'Chuck', 'Big Boy', 'Hunter',
                    'Archer', 'Flagbearer', 'Tunneler', 'Kidnapper', 'Sapper',
                    'Yorick', 'Clone', 'Witch Doctor', 'Signaller', 'Jester',
                    'The Stupid', 'Warden', 'Heathen', 'Necromancer', 'Catapult'}

function buildArmy.draw()
    --draw the armyList at the moment
    for k, v in pairs(armyList) do
        love.graphics.print(v, 0, 400)
        print('test')
    end

    suit.draw()
end

function buildArmy.update(dt)
    --make all the buttons
    local iteration = 1
    for i=1,5 do
        for z=1,5 do
            suit.Button(nameTable[iteration], {id=iteration}, 0+(163*(i-1)), 0+(50*(z-1)), 100, 20)
            iteration = iteration + 1
        end
    end
    --add units to armyList when button is hit
    for i=1,25 do
        if suit.isHit(i) then
            table.insert(armyList, nameTable[i])
        end
    end
end

return buildArmy
