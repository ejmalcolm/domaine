#*MINIMUM VIABLE GAME:

# ! CRASHES ! #
  # the fool will crash the game if it tries to copy a unit without a specRef
  # if the client lags, the same client instance can connect many times to one lobby

# ! DOES NOT FUNCTION ! #
  # the Sleeper does not evolve if a unit dies in a way other than being attacked
  # the savant victory condition does not function
  # the hunter does not work
 

# ! DOES NOT FUNCTION AS INTENDED ! #
  # units with long names, when selected, display under the control bar
  # ascendant incarnates do not cause game loss on death
  # units that can't move can take the Imperator's bridge
  # you can delay spawning the sleeper or selecting your victory turn as the savant
  # the berserker's second attack target "sticks" across a turn ending

# ! FUNCTIONS AS INTENDED WITH UNEXPECTED RESULTS # !
  # the parallel instantly wins the game, as all units have the same stats

# ! DIFFICULT TO UNDERSTAND ! #
  # there's no confirmation of many abilities, particularly targeted/time-delayed ones, worked
  # there's no indication of who's turn it is
  # there's no indication if you're actively searching for a target once the alert times out
  # there's no indication of Madness or Warden status effects









# ! VERSION 0.5: FIX ALERTS
  # make new alerts write over old reworks
  # make alerts different colors
  # make some alerts go to both players
  # have a way to view old alerts


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