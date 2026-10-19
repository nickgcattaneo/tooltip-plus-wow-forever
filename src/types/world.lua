local ADDON_NAME, ns = ...

-- 3D world mouseover. Owner is usually UIParent or WorldFrame.
-- Unit frames and action bars match first, so those keep their types.
ns.Classify.Register({
    id = ns.TYPE.WORLD,
    label = ns.TYPE_LABELS[ns.TYPE.WORLD],
    priority = 80,
    detect = function(_, parent)
        if parent == WorldFrame or parent == UIParent then
            return true
        end
        return ns.Classify.NameMatches(parent, {
            "^WorldFrame",
        })
    end,
})
