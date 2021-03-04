
# * work on direct connection
  # we have a nice lobby UI setup
  # change the server-side infrastructure to have a "game management" section
  # channel mangament based off the host lobby screen

# change the "hover over" info (name/stats) to be easier to read

# ! VERSION 0.5: FIX ALERTS
  # make new alerts write over old reworks
  # make alerts different colors
  # make some alerts go to both players
  # have a way to view old alerts

# ! VERSION 0.6: UNIT PLACEMENT
  # * add to unitPlacement:
  # something that explains what is happening
  # * change unitPlacement to be multiplayer, players take turns at it

# ! VERSION 0.7: GAME

# TODO: UPDATE 1) ACTION MANGAEMENT

# TODO: UPDATE 2) UNIT SPRITES

# TODO: QOL Programming Changes
  # addTag/removeTag commands

# TODO: need a way to cancel powers once you activate them
  # basically have a way to cancel any WaitFor
  # this stops weird stuff like trying to attack something a long way away from happening
  # or that once you hit minor power you can't not do it

#! -- BUGS -- !#

# !? BUG: the Nullity doesn't trigger the unitKilled server event, meaning that units cant be resurrected, will die when they're not supposed to
# ! BUG: all attack abilities use a primary action when they shouldn't
  # this is because using an action is called in server:on(unitAttack)
# ! BUG: some unit names don't fit, like The Envoy, when **Chosen**
# ! BUG: units that canMove=false can still move with the control panel
  # the if statement checks are not there yet

#! -- GAME BALANCE -- !#