local unitList = {}

-- ! TRAVELLERS

unitList["Envoy"] = {1, 1, 2,
canMove=true, canAttack=true, canSpecial = true,
special={shortDesc='ACTIVE: This Unit moves to any Tile.',
         fullDesc='ACTIVE: Target any tile. This Unit moves to that Tile.',
         specRef='envoySpec',
         tags={} } }

unitList["Siren"] = {1, 1, 2,
canMove=true, canAttack=true, canSpecial = true,
special={shortDesc='ACTIVE: Move an enemy Unit in an adjacent Tile to this tile.',
         fullDesc='ACTIVE: Target an enemy Unit in an adjacent tile. Move that unit to the Siren’s Tile.',
         specRef = 'sirenSpec',
         tags={} } }

unitList["Router"] = {1, 1, 2,
canMove=true, canAttack=true, canSpecial = true,
special={shortDesc='ACTIVE: Move a friendly Unit in this Tile to any Tile.',
        fullDesc='ACTIVE: Target a friendly Unit in the same tile. Move that Unit to any Tile.',
        specRef ='routerSpec',
        tags = {} } }

unitList["Chain"] = {1, 1, 2,
canMove=true, canAttack=true, canSpecial = true,
special={shortDesc='ACTIVE: Attach to target Unit. This Unit moves with the attached Unit.',
         fullDesc='ACTIVE: Target a Unit in the same tile. Whenever that Unit moves, this Unit moves with it. This effect can only be active on one unit at a time.',
         specRef = 'chainSpec',
         tags = {} } }

unitList['Shifter'] = {1, 1, 2,
canMove=true, canAttack=true, canSpecial = true,
special={shortDesc='ACTIVE: Switch positions with a target Unit.',
         fullDesc='ACTIVE: Target a Unit. Switch the position of this Unit and that Unit.',
         specRef ='shifterSpec',
         tags = {} } }

-- ! STRIKERS

unitList["Berserker"] = {1, 1, 2,
canMove=true, canAttack=true, canSpecial = true,
special={shortDesc='When this Unit kills a Unit, they can immediately attack again at no Action cost.',
         fullDesc='When this Unit kills a Unit, they can immediately attack again without using an Attack action.',
         specRef=nil,
         tags={} } }
unitList["Berserker"]["special"]["tags"]['unitKill|berserkerPassive'] = true

unitList["Hunter"] = {1, 1, 2,
canMove=true, canAttack=true, canSpecial = true,
special={shortDesc='Mark a Unit in this Tile. This Unit can always attack that Unit.',
         fullDesc='ACTIVE: Mark a Unit in this Tile. This Unit can always attack that Unit.',
         specRef='hunterSpec',
         tags={} } }

unitList["Sniper"] = {1, 1, 2,
canMove=true, canAttack=true, canSpecial = true,
special={shortDesc='ACTIVE: Attack a Unit in a horizontally adjacent Tile.',
         fullDesc='ACTIVE: Attack a Unit in a horizontally adjacent Tile.',
         specRef='sniperSpec',
         tags={} } }

unitList["Knight"] = {1, 1, 2,
canMove=true, canAttack=true, canSpecial = true,
special={shortDesc='This Unit gains +1ATK each time it changes tiles this turn, and +2 ATK each time it changes lanes this turn.',
         fullDesc='This Unit gains +1ATK each time it changes tiles this turn, and +2 ATK each time it changes lanes this turn.',
         specRef=nil,
         tags={} } }
unitList["Knight"]["special"]["tags"]['unitMove|knightPassive'] = true
unitList["Knight"]["special"]["tags"]['storage|OriginalAttack'] = 1

unitList["Nullity"] = {1, 1, 2,
canMove=true, canAttack=true, canSpecial = true,
special={shortDesc='ACTIVE: Kill a Unit in this Tile, then remove this Unit from the game for turns equal to the HP of that Unit.',
         fullDesc='ACTIVE: Kill a Unit in this Tile. This Unit is removed from the game for X turns, where X is the amount of HP target Unit has.',
         specRef='nullitySpec',
         tags={} } }

-- ! SHAKERS

unitList["Fleet Admiral"] = {1, 1, 2,
canMove=true, canAttack=true, canSpecial = true,
special={shortDesc='ACTIVE: Select a Tile. In two turns, each Unit in that Tile takes 3 damage.',
         fullDesc='ACTIVE: Select a Tile. In two turns, each Unit in that Tile takes 3 damage.',
         specRef='fleetAdmiralSpec',
         tags={} } }

unitList["Plaguebearer"] = {1, 0, 2,
canMove=false, canAttack=true, canSpecial = true,
special={shortDesc='This Unit cannot move. When they leave a tile, all Units in that Tile die.',
        fullDesc='This Unit cannot move. When they are removed from a Tile, all Units in that Tile die.',
        specRef=nil,
        tags={} } }
unitList["Plaguebearer"]["special"]["tags"]['unitMove|plaguebearerPassive1'] = true
unitList["Plaguebearer"]["special"]["tags"]['unitDeath|plaguebearerPassive2'] = true

unitList["Architect"] = {1, 1, 2,
canMove=true, canAttack=true, canSpecial = true,
special={shortDesc='ACTIVE: Create either a Wall or a Road in this Tile. Walls prevent units from moving in or out. Roads make movement in not consume an Action.',
         fullDesc='ACTIVE: Create one of the following in this Tile: The Wall - 0/3 - Units cannot move into or out of the Wall’s tile. The Road - 0/3 - Basic moves into the Road’s tile do not consume an Action.',
         specRef='architectSpec',
         tags={} } }

  -- * architect buildings
  unitList["Wall"] = {0, 0, 3,
  canMove=false, canAttack=false, canSpecial = false,
  special={shortDesc='Units cannot move in or out of this tile.',
          fullDesc='Units cannot move in or out of this tile.',
          specRef=nil,
          tags={} } }
  unitList["Wall"]["special"]["tags"]['unitMoveIn|wallPassive'] = true
  unitList["Wall"]["special"]["tags"]['unitMoveOut|wallPassive'] = true


  unitList["Road"] = {0, 0, 3,
  canMove=false, canAttack=false, canSpecial = false,
  special={shortDesc='Moving into this Tile does not take an Action.',
          fullDesc='Moving into this Tile does not take an Action',
          specRef=nil,
          tags={} } }
  unitList["Road"]["special"]["tags"]['unitMoveIn|roadPassive'] = true
  -- * architect buildings


unitList["Inferno"] = {1, 1, 2,
canMove=true, canAttack=true, canSpecial = true,
special={shortDesc='ACTIVE: Select a Tile in this Lane. For the next three turns, every Unit in that Tile takes 1 damage. Only one Tile can be Ablaze.',
        fullDesc='ACTIVE: Select a Tile in this Lane. At the start of the next three turns, every Unit in that Tile takes 1 damage. Only one Tile can be Ablaze per Inferno.',
        specRef='infernoSpec',
        tags={} } }

unitList["Overgrowth"] = {1, 1, 2,
canMove=true, canAttack=true, canSpecial = true,
special={shortDesc='ACTIVE: This Unit becomes a 0|5 Sacred Tree. Units that end their turn in the Sacred Tree\'s tile become 1|1 Beasts under your control.',
         fullDesc='ACTIVE: This Unit becomes a 0|5 Sacred Tree. Units that end their turn in the Sacred Tree\'s tile become 1|1 Beasts under your control.',
         specRef='overgrowthSpec',
         tags={} } }

-- ! TRANSMUTERS

unitList["Demagogue"] = {1, 1, 2,
canMove=true, canAttack=true, canSpecial = true,
special={shortDesc='ACTIVE: Target an enemy Unit in this Tile. Take control of that Unit until the beginning of next turn.',
         fullDesc='ACTIVE: Target an enemy Unit in this Tile. Take control of that Unit until the beginning of next turn.',
         specRef='demagogueSpec',
         tags={} } }

unitList["Animator"] = {1, 1, 2,
canMove=true, canAttack=true, canSpecial = true,
special={shortDesc='ACTIVE: Target a Unit. That Unit can now move and attack, and if they had no active special, their Special becomes the Animator\'s Special.',
          fullDesc='ACTIVE: Target a Unit. That Unit can now move and attack, and if they had no active special, their Special becomes the Animator\'s Special.',
          specRef='animatorSpec',
          tags={} } }

unitList["Chronomage"] = {1, 1, 2,
canMove=true, canAttack=true, canSpecial = true,
special={shortDesc='ACTIVE: Target a Unit in this Tile. Reset that Unit to their starting state.',
         fullDesc='ACTIVE: Target a Unit in this Tile. Reset that Unit to their starting state. (All statistics, changed specials, and effects are reset.)',
         specRef='chronomageSpec',
         tags={} } }

unitList["Blank"] = {1, 1, 2,
canMove=true, canAttack=true, canSpecial = true,
special={shortDesc='ACTIVE: Target a Unit in this Tile. Permanently remove that Unit\'s Special.',
         fullDesc='ACTIVE: Target a Unit in this Tile. Permanently remove that Unit\'s Special, as well as any Special effects that are currently applied to them. This does not effect time-delayed effects.',
         specRef='blankSpec',
         tags={} } }

unitList["Warden"] = {1, 1, 2,
canMove=true, canAttack=true, canSpecial = true,
special={shortDesc='ACTIVE: Target a Unit in this Tile. That Unit cannot act next turn.',
         fullDesc='ACTIVE: Target a Unit in this Tile. That Unit cannot act next turn. Passive and timed effects will still take place.',
         specRef='wardenSpec',
         tags={} } }

-- ! CONDUITS ! --

unitList["Oppressed"] = {1, 1, 2,
canMove=false, canAttack=false, canSpecial = true,
special={shortDesc='When targeted by a Special, this Unit gains 1 Anger. When this Unit has three Anger, destroy all Units in their Tile and create 3 allied 3|3 Revolutionaries. This Unit cannot move or attack.',
         fullDesc='When targeted by a Special, this Unit gains 1 Anger. When this Unit has three Anger, destroy all Units in their Tile and create 3 allied 3|3 Revolutionaries. This Unit cannot move or attack.',
         specRef=nil,
         tags={} } }
unitList["Oppressed"]["special"]["tags"]['unitTargeted|oppressedPassive'] = true
unitList["Oppressed"]["special"]["tags"]['oppressedStorage|anger'] = 0

  unitList["Revolutionary"] = {0, 3, 3,
  canMove=true, canAttack=true, canSpecial=true,
  special={shortDesc='This Unit was created by the Oppressed.',
           fullDesc='This Unit was created by the Oppressed.',
           specRef=nil,
           tags={} } }

unitList["Beacon"] = {1, 1, 2,
canMove=true, canAttack=true, canSpecial = true,
special={shortDesc='Any allied Special can target Units in this Tile.',
         fullDesc='Any allied Special can target Units in this Tile.',
         specRef=nil,
         tags={} } }
unitList["Beacon"]["special"]["tags"]['unitTargetedInTile|beaconPassive'] = true

unitList["Bargain"] = {1, 1, 2,
canMove=true, canAttack=true, canSpecial = true,
special={shortDesc='ACTIVE: Target an allied Unit in this Tile. Kill this Unit and target Unit. Choose any Unit and create that Unit in this Tile.',
         fullDesc='ACTIVE: Target an allied Unit in this Tile. Kill this Unit and target Unit. Choose any Unit and create that Unit in this Tile.',
         specRef='bargainSpec',
         tags={} } }

unitList["Martyr"] = {1, 1, 2,
canMove=true, canAttack=true, canSpecial = true,
special={shortDesc='ACTIVE: Kill this Unit. Gain 2 Actions of a chosen type.',
         fullDesc='ACTIVE: Kill this Unit. Gain 2 Actions of a chosen type.',
         specRef='martyrSpec',
         tags={} } }

unitList["Fool"] = {1, 1, 2,
canMove=true, canAttack=true, canSpecial = true,
special={shortDesc='ACTIVE: Target a Unit with an activated Special. Immediately activate that special with this Unit as the caster. At the start of the next turn, the Fool\'s special is blanked..',
         fullDesc='ACTIVE: Target a Unit with an activated Special. Immediately activate that special with this Unit as the caster. At the start of the next turn, the Fool\'s special is blanked.',
         specRef='foolSpec',
         tags={} } }

-- ! INCARNATES ! --

unitList["Imperial Outpost"] = {0, 1, 2,
canMove=false, canAttack=true, canSpecial = true,
special={shortDesc = 'This Unit cannot move.',
         fullDesc = 'This Unit cannot move.',
         specRef = nil,
         tags={} } }

unitList["Legion"] = {0, 1, 1,
canMove=true, canAttack=true, canSpecial = true,
special={shortDesc = '',
        fullDesc = '',
        specRef = nil,
        tags={} } }

unitList["IMPERATOR"] = {0, 5, 5,
canMove=true, canAttack=true, canSpecial = true,
special={shortDesc = 'ACTIVE: Create a 1|1 Legion in this Tile.\nACTIVE: All Legions become X|X, where X is the number of Legions you control.',
        fullDesc = 'ACTIVE: Create a 1|1 Legion in this Tile.\nACTIVE: All Legions become X|X, where X is the number of Legions you control.',
        specRef = 'imperatorSpec',
        tags={} } }

unitList["FIRST PARALLEL"] = {0, 1, 6,
canMove=true, canAttack=true, canSpecial = true,
special={shortDesc = 'ACTIVE: Kill all Units with the same HP as the First Parallel, including itself.',
        fullDesc = 'ACTIVE: Kill all Units with the same HP as the First Parallel, including itself.',
        specRef = 'firstParallelSpec',
        tags={} } }

unitList["SECOND PARALLEL"] = {0, 6, 1,
canMove=true, canAttack=true, canSpecial = true,
special={shortDesc = 'ACTIVE: Swap the ATK and HP of all Units in this Tile.',
        fullDesc = 'ACTIVE: Swap the ATK and HP of all Units in this Tile.',
        specRef = 'secondParallelSpec',
        tags={} } }

unitList["SACRAMENT"] = {0, 5, 5,
canMove=true, canAttack=true, canSpecial = true,
special={shortDesc = [[This Unit counts as the Chosen.
ACTIVE: Move to a horizontally adjacent tile.
ACTIVE: Kill an allied Unit in this Tile. This Unit's stats increase by that Unit's stats.]],
        fullDesc = [[This Unit counts as the Chosen.
ACTIVE: Move to a horizontally adjacent tile.
ACTIVE: Kill an allied Unit in this Tile. This Unit's ATK and HP are increased by that Unit's ATK and HP.]],
        specRef = 'sacramentSpec',
        tags={} } }


return unitList
