local Object = require("classic")
--declare the Unit class
Unit = Object:extend()

function Unit.new(self, name, cost, attack, health)
    self.name = name
    self.cost = cost
    self.attack = attack
    self.health = health
end

--define the base Rand
Rand = Unit:extend()

function Rand:new()
    Rand.super.new(self, "Rand", 2, 3, 6)
