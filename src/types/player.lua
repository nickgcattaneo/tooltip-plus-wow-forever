local ADDON_NAME, ns = ...

-- Portrait / party / raid unit frames. World mouseover uses UIParent
-- and stays World Object / NPCs.
ns.Classify.Register({
    id = ns.TYPE.PLAYER,
    label = ns.TYPE_LABELS[ns.TYPE.PLAYER],
    priority = 40,
    detect = function(_, parent)
        return ns.Classify.NameMatches(parent, {
            "^PlayerFrame",
            "^TargetFrame",
            "^FocusFrame",
            "^PetFrame",
            "^PartyFrame",
            "^PartyMemberFrame",
            "^TargetofTarget",
            "^CompactParty",
            "^CompactRaid",
            "^CompactUnitFrame",
            "^Boss%d",
            "^ArenaEnemy",
        })
    end,
})
