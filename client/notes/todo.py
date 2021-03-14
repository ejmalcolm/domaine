
# * work on direct connection
  # we have a nice lobby UI setup
  # change the server-side infrastructure to have a "game management" section
  # channel mangament based off the host lobby screen


# !!! THINGS THAT ACTUALLY DON'T WORK !!! #
  # ascendant incarnates do not cause game loss on death
  # the hunter doesn't work at all
  # the fool will crash the game if it tries to copy people without an activated special
  # the new control bar doesn't have canMove/canAttack/canSpecial implemented
  # the parallel instantly wins the game because all units have the same stats


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

# TODO: UNIT SPRITES

# TODO: QOL Programming Changes
  # addTag/removeTag commands
  # unitTargetCheck on everyone

# TODO: need a way to cancel powers once you activate them
  # basically have a way to cancel any WaitFor
  # this stops weird stuff like trying to attack something a long way away from happening
  # or that once you hit minor power you can't not do it

#! -- BUGS -- !#

# !? BUG: the Nullity doesn't trigger the unitKilled server event, meaning that units cant be resurrected, will die when they're not supposed to

#! -- GAME BALANCE -- !#