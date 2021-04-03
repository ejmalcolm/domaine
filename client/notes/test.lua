local x = {red='red', blue='blue', green='green'}

for k,v in pairs(x) do
  print(k, v)
end

table.sort(x)

for k,v in pairs(x) do
  print(k, v)
end