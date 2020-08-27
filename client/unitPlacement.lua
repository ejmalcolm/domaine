local unitPlacement = {}

local suit = require("suit")


-- ! later, we're going to need to adapt this for multiplayer

function unitPlacement.setArmy(armyList)
    -- sets the army of the player to be the given armyList
	unitPlacement.armyList = armyList
end

function unitPlacement.load()
    -- define the three placement rectangles
    -- the first sublist is color, second is rectangle coords
    -- third is "contents"
    unitPlacement.pRects = {}

    unitPlacement.pRects.r = {}
    unitPlacement.pRects.r.color = {1,0,0}
    unitPlacement.pRects.r.rect = {10, 180, 100, 100}
    unitPlacement.pRects.r.content = {}

    unitPlacement.pRects.y = {}
    unitPlacement.pRects.y.color = {1,1,0}
    unitPlacement.pRects.y.rect = {325, 180, 100, 100}
    unitPlacement.pRects.y.content = {}

    unitPlacement.pRects.g = {}
    unitPlacement.pRects.g.color = {0,.5,0}
    unitPlacement.pRects.g.rect = {640, 180, 100, 100}
    unitPlacement.pRects.g.content = {}

end

function unitPlacement.update(dt)

    for k, pRect in pairs(unitPlacement.pRects) do
        
        -- create armyList buttons underneath each pRect
        -- each of these lists is "tagged" with the pRect its 
        
        -- use the x-coord of the pRect to place the button
        suit.layout:reset(pRect.rect[1], pRect.rect[2]+110)
        for unitKey, unitName in pairs(unitPlacement.armyList) do
            -- the ID is: pRect#+unitName+index
            -- where pRect# is 1=r, 2=y, 3=g
            suit.Button(unitName, {id = k..unitName..tostring(unitKey)}, suit.layout:row(100,20))
        end
        
        -- when an armyList button is clicked,
        -- 1) remove from "active" armyList
        -- 2) place that button "into" the square
        for unitKey, unitName in pairs(unitPlacement.armyList) do
            -- using the above defined (line 33) pRect-based ID
            if suit.isHit(k..unitName..tostring(unitKey)) then
                table.remove(unitPlacement.armyList, unitKey)
                table.insert(pRect.content, unitName)
            end
        end

        -- above each pRect, draw a button for each unit in it

        suit.layout:reset(pRect.rect[1], pRect.rect[2]-30)
        for unitKey, unitName in pairs(pRect.content) do
            -- the ID is: pRect#+unitName+index
            -- where pRect# is 1=r, 2=y, 3=g
            -- * we add the 'PRC' because we need to distinguish the P Rect Content
            -- * buttons from the armyList buttons, else they trigger each other
            suit.Button(unitName, {id = 'PRC'..k..unitName..tostring(unitKey)}, suit.layout:up(100, 20))
        end
    
        -- when a pRect content button is clicked,
        -- remove that unit from the content

        for unitKey, unitName in pairs(pRect.content) do
            -- using the above defined (line 33) pRect-based ID
            if suit.isHit('PRC'..k..unitName..tostring(unitKey)) then
                table.remove(pRect.content, unitKey)
                table.insert(unitPlacement.armyList, unitName)
            end
        end
    
    
    end

    -- if the armyList is empty, draw the "Enter Game" Button
    if next(unitPlacement.armyList) == nil then
        suit.Button('Connect to Server', 320, 450, 120, 20)
    end
    if suit.isHit('Connect to Server') then
        -- go to connect screen
        ConnectScreen.load()
        changeScreen(ConnectScreen)
    end


end

function unitPlacement.draw()
    -- draw the three placement rectangles
    for k,v in pairs(unitPlacement.pRects) do
        love.graphics.setColor(v.color)
        love.graphics.rectangle('line', unpack(v.rect))
    end

    suit.draw()

end

return unitPlacement