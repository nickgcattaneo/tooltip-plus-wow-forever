local ADDON_NAME, ns = ...

-- Action bars, stance/pet bars, extra action button.
-- A bar button that shows a spell is still toolbar: the owner is the bar.
ns.Classify.Register({
    id = ns.TYPE.TOOLBAR,
    label = ns.TYPE_LABELS[ns.TYPE.TOOLBAR],
    priority = 20,
    detect = function(_, parent)
        return ns.Classify.NameMatches(parent, {
            "^ActionButton",
            "^MultiBar",
            "^StanceButton",
            "^PetActionButton",
            "^PossessButton",
            "^OverrideActionBarButton",
            "^ExtraActionButton",
            "^BonusActionButton",
            "^ZoneAbility",
            "^MainMenuBar",
        })
    end,
})
