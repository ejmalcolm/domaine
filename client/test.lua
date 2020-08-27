tileRef = 'y1'
print(not (tonumber(tileRef:sub(2,2)) == nil))


if not tonumber(tileRef:sub(2,2)) == nil then
    print(tileRef..'is a number!')
    local laneCode = tileRef:sub(1,1)
    local tileCode = tonumber(tileRef:sub(2,2))
    local tile = MasterLanes[laneCode][tileCode]
    return tile
end