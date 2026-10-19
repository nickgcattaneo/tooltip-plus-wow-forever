local ADDON_NAME, ns = ...

ns.ADDON_NAME = ADDON_NAME
ns.IS_DEV = ADDON_NAME:sub(-3) == "Dev"
ns.DB_NAME = ADDON_NAME .. "DB"
ns.SLASH = "/tt+"
ns.SLASH_KEY = "TOOLTIPPLUS"
ns.PREFIX = ns.IS_DEV and "|cffd4a85aTooltip+ (dev)|r" or "|cffd4a85aTooltip+|r"
ns.DEFAULT_PROFILE_NAME = "Default"

ns.TYPE = {
    TOOLBAR = "toolbar",
    PLAYER = "player",
    WORLD = "world",
}

ns.TYPE_ORDER = {
    ns.TYPE.TOOLBAR,
    ns.TYPE.WORLD,
    ns.TYPE.PLAYER,
}

ns.TYPE_LABELS = {
    [ns.TYPE.TOOLBAR] = "Action Bar",
    [ns.TYPE.PLAYER] = "Unit Frame",
    [ns.TYPE.WORLD] = "World Object / NPCs",
}

ns.MODES = { "cursor", "point" }
ns.MODE_LABELS = {
    cursor = "Cursor",
    point = "X, Y",
}

ns.CORNER_ORDER = { "BOTTOMRIGHT", "BOTTOMLEFT", "TOPRIGHT", "TOPLEFT" }
ns.CORNER_LABELS = {
    BOTTOMRIGHT = "Bottom right",
    BOTTOMLEFT = "Bottom left",
    TOPRIGHT = "Top right",
    TOPLEFT = "Top left",
}
ns.CORNERS = {
    BOTTOMRIGHT = true,
    BOTTOMLEFT = true,
    TOPRIGHT = true,
    TOPLEFT = true,
}

function ns.IsConfiguredType(typeId)
    for i = 1, #ns.TYPE_ORDER do
        if ns.TYPE_ORDER[i] == typeId then
            return true
        end
    end
    return false
end

local UNIT_CONTENT = {
    [ns.TYPE.PLAYER] = true,
    [ns.TYPE.WORLD] = true,
}

ns.CONTENT_KEYS = {
    { key = "classColorName", label = "Class-colored names", types = UNIT_CONTENT },
    { key = "showHealthBar", label = "Health bar", types = UNIT_CONTENT },
    { key = "showGuild", label = "Guild name", types = UNIT_CONTENT },
    { key = "showTarget", label = "Target of target", types = UNIT_CONTENT },
    { key = "hideInCombat", label = "Hide in combat" },
}

function ns.ContentKeyApplies(spec, scope)
    if not spec.types then
        return true
    end
    local function matchesLive()
        for i = 1, #ns.TYPE_ORDER do
            if spec.types[ns.TYPE_ORDER[i]] then
                return true
            end
        end
        return false
    end
    if not scope or scope == "global" then
        return matchesLive()
    end
    return spec.types[scope] and true or false
end

function ns.IsUnitContentType(typeId)
    return typeId and UNIT_CONTENT[typeId] and true or false
end

ns.DEFAULT_POSITION = {
    mode = "cursor",
    offsetX = 12,
    offsetY = -12,
    corner = "BOTTOMRIGHT",
    pointX = 400,
    pointY = 300,
}

ns.DEFAULT_CONTENT = {
    scale = 1,
    classColorName = true,
    showHealthBar = true,
    showGuild = true,
    showTarget = false,
    hideInCombat = false,
}

-- Seconds. 1 leaves the client fade alone. 0 hides immediately.
ns.DEFAULT_FADE = 1
ns.FADE_MIN = 0
ns.FADE_MAX = 10
ns.FADE_STEP = 0.1

ns.DEFAULT_TYPE = {
    enabled = true,
    overridePosition = false,
    overrideContent = false,
    overrideFade = false,
}

-- Account-level minimap ring button. Not stored per profile.
ns.DEFAULT_MINIMAP = {
    shown = true,
    angle = 210,
}

-- Legacy flat defaults, used only to migrate older SavedVariables.
ns.DEFAULTS = {
    enabled = true,
    mode = "cursor",
    offsetX = 12,
    offsetY = -12,
    corner = "BOTTOMRIGHT",
    types = {
        [ns.TYPE.TOOLBAR] = { enabled = true },
        [ns.TYPE.PLAYER] = { enabled = true },
        [ns.TYPE.WORLD] = { enabled = true },
    },
}
