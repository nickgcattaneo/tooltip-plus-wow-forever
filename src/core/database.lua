local ADDON_NAME, ns = ...

function ns.DeepCopy(src)
    if type(src) ~= "table" then
        return src
    end
    local out = {}
    for key, value in pairs(src) do
        out[key] = ns.DeepCopy(value)
    end
    return out
end

function ns.DeepEqual(a, b)
    if a == b then
        return true
    end
    if type(a) ~= "table" or type(b) ~= "table" then
        return false
    end
    for key, value in pairs(a) do
        if not ns.DeepEqual(value, b[key]) then
            return false
        end
    end
    for key in pairs(b) do
        if a[key] == nil then
            return false
        end
    end
    return true
end

local function Merge(base, overlay)
    local out = ns.DeepCopy(base)
    if type(overlay) ~= "table" then
        return out
    end
    for key, value in pairs(overlay) do
        if type(value) == "table" and type(out[key]) == "table" then
            out[key] = Merge(out[key], value)
        else
            out[key] = value
        end
    end
    return out
end

function ns.CreateProfileData()
    local profile = {
        enabled = true,
        position = ns.DeepCopy(ns.DEFAULT_POSITION),
        content = ns.DeepCopy(ns.DEFAULT_CONTENT),
        fade = ns.DEFAULT_FADE,
        types = {},
    }
    for i = 1, #ns.TYPE_ORDER do
        local typeId = ns.TYPE_ORDER[i]
        profile.types[typeId] = ns.DeepCopy(ns.DEFAULT_TYPE)
    end
    return profile
end

local function MigrateFlatDB(db)
    if type(db.profiles) == "table" then
        return
    end
    local profile = ns.CreateProfileData()
    if db.enabled ~= nil then
        profile.enabled = db.enabled and true or false
    end
    if db.mode then
        profile.position.mode = db.mode
    end
    if db.offsetX then
        profile.position.offsetX = db.offsetX
    end
    if db.offsetY then
        profile.position.offsetY = db.offsetY
    end
    if db.corner then
        profile.position.corner = db.corner
    end
    if type(db.types) == "table" then
        for typeId, settings in pairs(db.types) do
            if type(settings) == "table" then
                profile.types[typeId] = profile.types[typeId] or ns.DeepCopy(ns.DEFAULT_TYPE)
                if settings.enabled ~= nil then
                    profile.types[typeId].enabled = settings.enabled and true or false
                end
            end
        end
    end
    db.profiles = { [ns.DEFAULT_PROFILE_NAME] = profile }
    db.activeProfile = ns.DEFAULT_PROFILE_NAME
    db.enabled = nil
    db.mode = nil
    db.offsetX = nil
    db.offsetY = nil
    db.corner = nil
    db.types = nil
end

function ns.GetDB()
    local db = _G[ns.DB_NAME]
    if type(db) ~= "table" then
        return nil
    end
    return db
end

function ns.EnsureDB()
    if type(_G[ns.DB_NAME]) ~= "table" then
        _G[ns.DB_NAME] = {}
    end
    local db = _G[ns.DB_NAME]
    MigrateFlatDB(db)
    if type(db.profiles) ~= "table" then
        db.profiles = {}
    end
    if not db.profiles[ns.DEFAULT_PROFILE_NAME] then
        db.profiles[ns.DEFAULT_PROFILE_NAME] = ns.CreateProfileData()
    end
    if not db.activeProfile or not db.profiles[db.activeProfile] then
        db.activeProfile = ns.DEFAULT_PROFILE_NAME
    end
    if type(db.minimap) ~= "table" then
        db.minimap = ns.DeepCopy(ns.DEFAULT_MINIMAP)
    end
    if db.minimap.shown == nil then
        db.minimap.shown = true
    end
    if type(db.minimap.angle) ~= "number" then
        db.minimap.angle = ns.DEFAULT_MINIMAP.angle
    end
    if db.enabled == nil then
        db.enabled = true
    end
    ns.db = db
    return db
end

function ns.GetAddonEnabled()
    return ns.EnsureDB().enabled ~= false
end

function ns.SetAddonEnabled(enabled)
    ns.EnsureDB().enabled = enabled and true or false
    if ns.MinimapButton and ns.MinimapButton.Refresh then
        ns.MinimapButton.Refresh()
    end
end

function ns.GetMinimapShown()
    return ns.EnsureDB().minimap.shown ~= false
end

function ns.SetMinimapShown(shown)
    ns.EnsureDB().minimap.shown = shown and true or false
    if ns.MinimapButton and ns.MinimapButton.Refresh then
        ns.MinimapButton.Refresh()
    end
end

function ns.GetMinimapAngle()
    return ns.EnsureDB().minimap.angle or ns.DEFAULT_MINIMAP.angle
end

function ns.SetMinimapAngle(angle)
    ns.EnsureDB().minimap.angle = tonumber(angle) or ns.DEFAULT_MINIMAP.angle
end

function ns.ProfileNames()
    local db = ns.EnsureDB()
    local names = {}
    for name in pairs(db.profiles) do
        names[#names + 1] = name
    end
    table.sort(names)
    return names
end

function ns.GetActiveProfileName()
    return ns.EnsureDB().activeProfile
end

local function SafeUnitText(value)
    if type(value) ~= "string" or value == "" then
        return nil
    end
    if type(issecretvalue) == "function" and issecretvalue(value) then
        return nil
    end
    return value
end

function ns.SuggestedProfileName()
    local player = UnitName and SafeUnitText(UnitName("player"))
    local last
    if C_PlayerInfo then
        if type(C_PlayerInfo.GetLastName) == "function" then
            last = SafeUnitText(C_PlayerInfo.GetLastName())
        end
        if not last and type(C_PlayerInfo.GetFullName) == "function" then
            local full = SafeUnitText(C_PlayerInfo.GetFullName())
            if full and (not player or full ~= player) then
                player = full
                last = nil
            end
        end
    end
    if player and last then
        player = player .. " " .. last
    end
    local className
    if UnitClass then
        className = SafeUnitText(UnitClass("player"))
    end
    local base
    if player and className then
        base = player .. " - " .. className
    else
        base = player or className or "New profile"
    end
    local profiles = ns.EnsureDB().profiles
    if not profiles[base] then
        return base
    end
    local index = 2
    while profiles[base .. " " .. index] do
        index = index + 1
    end
    return base .. " " .. index
end

function ns.ClampFade(seconds)
    seconds = tonumber(seconds)
    if not seconds then
        return ns.DEFAULT_FADE
    end
    if seconds < ns.FADE_MIN then
        seconds = ns.FADE_MIN
    elseif seconds > ns.FADE_MAX then
        seconds = ns.FADE_MAX
    end
    return math.floor(seconds * 10 + 0.5) / 10
end

function ns.FormatFade(seconds)
    return string.format("%.1f", ns.ClampFade(seconds))
end

local function NormalizeProfile(profile)
    if type(profile.position) ~= "table" then
        profile.position = ns.DeepCopy(ns.DEFAULT_POSITION)
    elseif profile.position.mode == "default" or profile.position.mode == "corner" then
        profile.position.mode = "cursor"
    end
    if type(profile.content) ~= "table" then
        profile.content = ns.DeepCopy(ns.DEFAULT_CONTENT)
    end
    profile.fade = ns.ClampFade(profile.fade)
    if type(profile.types) ~= "table" then
        profile.types = {}
    end
    for i = 1, #ns.TYPE_ORDER do
        local typeId = ns.TYPE_ORDER[i]
        if type(profile.types[typeId]) ~= "table" then
            profile.types[typeId] = ns.DeepCopy(ns.DEFAULT_TYPE)
        end
        local typeCfg = profile.types[typeId]
        if typeCfg.overrideContent and type(typeCfg.content) ~= "table" then
            typeCfg.content = ns.DeepCopy(profile.content)
        end
        if typeCfg.overrideFade and type(typeCfg.fade) ~= "number" then
            typeCfg.fade = profile.fade
        elseif type(typeCfg.fade) == "number" then
            typeCfg.fade = ns.ClampFade(typeCfg.fade)
        end
        if typeCfg.mode == "default" or typeCfg.mode == "corner" then
            typeCfg.mode = "cursor"
        end
    end
    local stale = {}
    for typeId in pairs(profile.types) do
        if not ns.IsConfiguredType(typeId) then
            stale[#stale + 1] = typeId
        end
    end
    for i = 1, #stale do
        profile.types[stale[i]] = nil
    end
    return profile
end

function ns.GetCommittedProfile()
    local db = ns.EnsureDB()
    local profile = db.profiles[db.activeProfile]
    if type(profile) ~= "table" then
        profile = ns.CreateProfileData()
        db.profiles[db.activeProfile] = profile
    end
    return NormalizeProfile(profile)
end

function ns.EnsureDraft()
    local name = ns.GetActiveProfileName()
    if ns.draft and ns.draftName == name then
        return ns.draft
    end
    ns.draftName = name
    ns.draft = ns.DeepCopy(ns.GetCommittedProfile())
    return ns.draft
end

function ns.GetActiveProfile()
    return ns.EnsureDraft()
end

function ns.IsProfileDirty()
    if ns.EditMode and ns.EditMode.dirty then
        return true
    end
    return not ns.DeepEqual(ns.EnsureDraft(), ns.GetCommittedProfile())
end

function ns.SaveDraft()
    local db = ns.EnsureDB()
    local name = db.activeProfile
    db.profiles[name] = ns.DeepCopy(ns.EnsureDraft())
    ns.draftName = name
    ns.draft = ns.DeepCopy(db.profiles[name])
    return true
end

function ns.DiscardDraft()
    ns.draft = nil
    ns.draftName = nil
    return ns.EnsureDraft()
end

function ns.SetActiveProfile(name)
    local db = ns.EnsureDB()
    if not db.profiles[name] then
        return false
    end
    db.activeProfile = name
    ns.draft = nil
    ns.draftName = nil
    ns.EnsureDraft()
    return true
end

function ns.SaveProfileAs(name)
    name = strtrim(name or "")
    if name == "" then
        return false
    end
    local db = ns.EnsureDB()
    if db.profiles[name] then
        return false
    end
    db.profiles[name] = ns.DeepCopy(ns.GetActiveProfile())
    db.activeProfile = name
    ns.draftName = name
    ns.draft = ns.DeepCopy(db.profiles[name])
    return true
end

function ns.ResetActiveProfile()
    local db = ns.EnsureDB()
    local name = db.activeProfile
    db.profiles[name] = ns.CreateProfileData()
    ns.draft = nil
    ns.draftName = nil
    ns.EnsureDraft()
    if ns.EditMode then
        ns.EditMode.dirty = false
    end
    return true
end

function ns.DeleteActiveProfile()
    local db = ns.EnsureDB()
    local name = db.activeProfile
    if name == ns.DEFAULT_PROFILE_NAME then
        db.profiles[name] = ns.CreateProfileData()
        ns.draft = nil
        ns.draftName = nil
        ns.EnsureDraft()
        return true, "reset"
    end
    db.profiles[name] = nil
    db.activeProfile = ns.DEFAULT_PROFILE_NAME
    ns.draft = nil
    ns.draftName = nil
    ns.EnsureDraft()
    return true, "deleted"
end

function ns.GetTypeConfig(typeId)
    local profile = ns.GetActiveProfile()
    if type(profile.types[typeId]) ~= "table" then
        profile.types[typeId] = ns.DeepCopy(ns.DEFAULT_TYPE)
    end
    return profile.types[typeId]
end

function ns.GetPositionSource(typeId)
    local profile = ns.GetActiveProfile()
    if typeId and ns.GetTypeConfig(typeId).overridePosition then
        return ns.GetTypeConfig(typeId)
    end
    return profile.position
end

function ns.GetContentSource(typeId)
    local profile = ns.GetActiveProfile()
    if typeId and ns.GetTypeConfig(typeId).overrideContent then
        local typeCfg = ns.GetTypeConfig(typeId)
        if type(typeCfg.content) ~= "table" then
            typeCfg.content = ns.DeepCopy(profile.content)
        end
        return typeCfg.content
    end
    return profile.content
end

function ns.GetFadeSource(typeId)
    local profile = ns.GetActiveProfile()
    if typeId and ns.GetTypeConfig(typeId).overrideFade then
        local typeCfg = ns.GetTypeConfig(typeId)
        if type(typeCfg.fade) ~= "number" then
            typeCfg.fade = profile.fade
        end
        return typeCfg
    end
    return profile
end

function ns.Resolve(typeId)
    local profile = ns.GetCommittedProfile()
    local fade = ns.ClampFade(profile.fade)
    if not typeId then
        return {
            enabled = false,
            position = profile.position,
            content = profile.content,
            fade = fade,
        }
    end
    if typeId == "global" then
        return {
            enabled = ns.GetAddonEnabled(),
            position = profile.position,
            content = profile.content,
            fade = fade,
        }
    end
    local typeCfg = profile.types[typeId]
    if type(typeCfg) ~= "table" then
        typeCfg = ns.DEFAULT_TYPE
    end
    local position = profile.position
    if typeCfg.overridePosition then
        position = Merge(profile.position, {
            mode = typeCfg.mode,
            offsetX = typeCfg.offsetX,
            offsetY = typeCfg.offsetY,
            corner = typeCfg.corner,
            pointX = typeCfg.pointX,
            pointY = typeCfg.pointY,
        })
    end
    local content = profile.content
    if typeCfg.overrideContent then
        content = Merge(profile.content, typeCfg.content)
    end
    if typeCfg.overrideFade then
        fade = ns.ClampFade(typeCfg.fade)
    end
    return {
        enabled = ns.GetAddonEnabled() and typeCfg.enabled ~= false,
        position = position,
        content = content,
        fade = fade,
    }
end

function ns.BeginPositionOverride(typeId)
    local profile = ns.GetActiveProfile()
    local typeCfg = ns.GetTypeConfig(typeId)
    typeCfg.overridePosition = true
    typeCfg.mode = typeCfg.mode or profile.position.mode
    typeCfg.offsetX = typeCfg.offsetX or profile.position.offsetX
    typeCfg.offsetY = typeCfg.offsetY or profile.position.offsetY
    typeCfg.corner = typeCfg.corner or profile.position.corner
    typeCfg.pointX = typeCfg.pointX or profile.position.pointX
    typeCfg.pointY = typeCfg.pointY or profile.position.pointY
end

function ns.BeginContentOverride(typeId)
    local profile = ns.GetActiveProfile()
    local typeCfg = ns.GetTypeConfig(typeId)
    typeCfg.overrideContent = true
    if type(typeCfg.content) ~= "table" then
        typeCfg.content = ns.DeepCopy(profile.content)
    end
end

function ns.BeginFadeOverride(typeId)
    local profile = ns.GetActiveProfile()
    local typeCfg = ns.GetTypeConfig(typeId)
    typeCfg.overrideFade = true
    if type(typeCfg.fade) ~= "number" then
        typeCfg.fade = profile.fade
    end
end

function ns.SetFade(scope, value)
    value = ns.ClampFade(value)
    if scope == "global" then
        ns.GetActiveProfile().fade = value
        return
    end
    ns.BeginFadeOverride(scope)
    ns.GetTypeConfig(scope).fade = value
end

function ns.SetPositionField(scope, key, value)
    if scope == "global" then
        ns.GetActiveProfile().position[key] = value
        return
    end
    ns.BeginPositionOverride(scope)
    ns.GetTypeConfig(scope)[key] = value
end

function ns.SetContentField(scope, key, value)
    if scope == "global" then
        ns.GetActiveProfile().content[key] = value
        return
    end
    ns.BeginContentOverride(scope)
    local content = ns.GetContentSource(scope)
    content[key] = value
end

function ns.GetSetting(key)
    local profile = ns.GetActiveProfile()
    if key == "enabled" then
        return ns.GetAddonEnabled()
    end
    if key == "fade" then
        return ns.ClampFade(profile.fade)
    end
    if profile.position[key] ~= nil then
        return profile.position[key]
    end
    if profile.content[key] ~= nil then
        return profile.content[key]
    end
    return ns.DEFAULTS[key]
end

function ns.SetSetting(key, value)
    local profile = ns.GetActiveProfile()
    if key == "enabled" then
        ns.SetAddonEnabled(value)
        return
    end
    if key == "fade" then
        profile.fade = ns.ClampFade(value)
        return
    end
    if ns.DEFAULT_POSITION[key] ~= nil or key == "mode" or key == "corner" then
        profile.position[key] = value
        return
    end
    profile.content[key] = value
end

function ns.GetTypeEnabledFlag(typeId)
    return ns.GetTypeConfig(typeId).enabled ~= false
end

function ns.IsTypeEnabled(typeId)
    return ns.GetAddonEnabled() and ns.GetTypeEnabledFlag(typeId)
end

function ns.SetTypeEnabled(typeId, enabled)
    ns.GetTypeConfig(typeId).enabled = enabled and true or false
end
