
# TODO: MVG) FINISH ASCENDANTS
  # FIX GAMESTATE
  # WORKING ACTION DISPLAY


# ! VERSION 0.5: FIX ALERTS
  # make new alerts write over old reworks
  # make alerts different colors
  # make some alerts go to both players
  # have a way to view old alerts

# ! VERSION 0.6: UNIT PLACEMENT
  # * add to unitPlacement:
  # something that explains what is happening
  # another unit display panel that tells you what each unit is when you hover it
  # * change unitPlacement to be multiplayer, players take turns at it

# ! VERSION 0.7: GAME

# TODO: UPDATE 1) ACTION DISPLAY, USING MANUAL ACTIONS

# TODO: UPDATE 2) ACTION MANGAEMENT

# TODO: UPDATE 3) GRAPHICAL REWORK



# TODO: need a way to cancel powers once you activate them
  # basically have a way to cancel any WaitFor
  # this stops weird stuff like trying to attack something a long way away from happening
  # or that once you hit minor power you can't not do it

#! -- BUGS -- !#

# !? BUG: the Nullity doesn't trigger the unitKilled server event, meaning that units cant be resurrected, will die when they're not supposed to
# ! BUG: all attack abilities use a primary action when they shouldn't
  # this is because using an action is called in server:on(unitAttack)
# ! BUG: some unit names don't fit, like The Envoy, when **Chosen**

#! -- GAME BALANCE -- !#