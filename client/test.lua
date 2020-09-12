local inspect = require("inspect")

x = {1, nil, 3}

print(inspect(x))

newX = {}
for _,v in pairs(x) do
  table.insert(newX, v)
end

print(inspect(newX))