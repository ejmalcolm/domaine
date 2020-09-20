local unitList = {}

-- * All specials are called with the Unit calling them as the first arg

-- ! TRAVELLERS

unitList["The Envoy"] = {1, 1, 2,
special={shortDesc='The Envoy moves to any Tile.',
         fullDesc='ACTIVE: Target any tile. The Envoy moves to that Tile.',
         specRef='envoySpec',
         tags={} } }

unitList["The Siren"] = {1, 1, 2,
special={shortDesc='Move an enemy Unit in an adjacent Tile to this tile.',
         fullDesc='ACTIVE: Target an enemy Unit in an adjacent tile. Move that unit to the Siren’s Tile.',
         specRef = 'sirenSpec',
         tags={} } }

unitList["The Router"] = {1, 1, 2,
special={shortDesc='Move a friendly Unit in this Tile to any Tile.',
        fullDesc='ACTIVE: Target a friendly Unit in the same tile. Move that Unit to any Tile.',
        specRef = 'routerSpec',
        tags = {} } }

unitList["The Chain"] = {1, 1, 2,
special={shortDesc='Attach to target Unit. The Chain moves with the attached Unit.',
         fullDesc='ACTIVE: Target a Unit in the same tile. Whenever that Unit moves, the Chain moves with it. This effect can only be active on one unit at a time.',
         specRef = 'chainSpec',
         tags = {} } }

unitList['The Shifter'] = {1, 1, 2,
special={shortDesc= 'Switch positions with a target Unit.',
         fullDesc= 'ACTIVE: Target a Unit. Switch the position of the Shifter and that Unit.',
         specRef = 'shifterSpec',
         tags = {} } }

-- ! STRIKERS

unitList["The Berserker"] = {1, 1, 2,
special={shortDesc='When the Berserker kills a Unit, it can immediately attack again.',
         fullDesc='When the Berserker kills a Unit, it can immediately attack again.',
         specRef='berserkerSpec',
         tags={} } }
unitList["The Berserker"]["special"]["tags"]['berserker|RepeatAttack'] = true

unitList["The Hunter"] = {1, 1, 2,
special={shortDesc='Mark a Unit in the same Tile. The Hunter can always attack that Unit.',
         fullDesc='ACTIVE: Mark a Unit in the same Tile. The Hunter can always attack that Unit',
         specRef='hunterSpec',
         tags={} } }

unitList["The Sniper"] = {1, 1, 2,
special={shortDesc='Attack a Unit in a horizontally adjacent Tile.',
         fullDesc='ACTIVE: Attack a Unit in a horizontally adjacent Tile.',
         specRef='sniperSpec',
         tags={} } }

unitList["The Knight"] = {1, 1, 2,
special={shortDesc='The Knight deals one extra damage for each time it has moved this turn.',
         fullDesc='The Knight deals one extra damage for each time it has moved this turn.',
         specRef='knightSpec',
         tags={} } }
unitList["The Knight"]["special"]["tags"]['knight|MomentumGain'] = true

unitList["The Nullity"] = {1, 1, 2,
special={shortDesc='Kill a Unit in the same Tile, then remove the Nullity from the game for turns equal to the HP of that Unit.',
         fullDesc='ACTIVE: Kill a Unit in the same Tile. The Nullity is removed from the game for X turns, where X is the amount of HP target Unit has.',
         specRef='nullitySpec',
         tags={} } }


return unitList