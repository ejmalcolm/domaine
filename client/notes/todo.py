
# TODO: we need to rework action management lol its ass

# TODO: rework the Chosen (sacrament's minor power) to use the tag system
  # currently it uses gamestate in a strange way

#TODO: add to unitPlacement:
  # something that explains what is happening
  # another unit display panel that tells you what each unit is when you hover it

# TODO: change unitPlacement to be multiplayer, each player takes a turn at a time

# TODO: need a way to cancel powers once you activate them
  # basically have a way to cancel any WaitFor
  # this stops weird stuff like trying to attack something a long way away from happening
  # or that once you hit minor power you can't not do it

# !? BUG: the Nullity doesn't trigger the unitKilled server event, meaning that units cant be resurrected, will die when they're not supposed to
# ! BUG: all attack abilities use a primary action when they shouldn't
  # this is because using an action is called in server:on(unitAttack)
# ! BUG: some unit names don't fit, like The Envoy, when **Chosen**

#! -- game balance -- !#

# KNIGHT: make it gain even more damage when you switch lanes
  # the fantasy of the knight is to do sick movement combos and 1shot things